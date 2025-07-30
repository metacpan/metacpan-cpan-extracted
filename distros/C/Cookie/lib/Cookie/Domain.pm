##----------------------------------------------------------------------------
## Cookies API for Server & Client - ~/lib/Cookie/Domain.pm
## Version v0.1.6
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/05/06
## Modified 2024/02/13
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Cookie::Domain;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $DOMAIN_RE $PUBLIC_SUFFIX_DATA $VERSION );
    use DateTime;
    use DateTime::Format::Strptime;
    use Module::Generic::File qw( tempfile );
    use JSON;
    use Net::IDN::Encode ();
    use Wanted;
    use constant URL => 'https://publicsuffix.org/list/effective_tld_names.dat';
    # Properly formed domain name according to rfc1123
    our $DOMAIN_RE = qr/^
        (?:
            [[:alnum:]]
            (?:
                (?:[[:alnum:]-]){0,61}
                [[:alnum:]]
            )?
            (?:
                \.[[:alnum:]]
                (?:
                    (?:[[:alnum:]-]){0,61}
                    [[:alnum:]]
                )?
            )*
        )
    $/x;
    our $VERSION = 'v0.1.6';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $base = Module::Generic::File::file( __FILE__ )->parent;
    $self->{file} = $base->child( 'public_suffix_list.txt' );
    $self->{json_file} = Module::Generic::File->sys_tmpdir->child( 'public_suffix.json' );
    $self->{meta} = {};
    $self->{min_suffix} = 0;
    $self->{suffixes} = {};
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    unless( $self->{no_load} )
    {
        $self->load || return( $self->pass_error );
    }
    return( $self );
}

sub cron_fetch
{
    # Cookie::Domain->cron_fetch
    # $obj->cron_fetch
    # Cookie::Domain->cron_fetch( $hash_ref );
    # $obj->cron_fetch( $hash_ref );
    # Cookie::Domain->cron_fetch( %options );
    # $obj->cron_fetch( %options );
    my( $this, $self );
    my $opts = {};
    if( scalar( @_ ) && ( ref( $_[0] ) eq __PACKAGE__ || $_[0] eq __PACKAGE__ ) )
    {
        $this = shift( @_ );
    }
    if( @_ == 1 && ref( $_[0] ) eq 'HASH' )
    {
        $opts = shift( @_ );
    }
    elsif( !( scalar( @_ ) % 2 ) )
    {
        $opts = { @_ };
    }
    
    if( ref( $this ) )
    {
        $self = $this;
    }
    else
    {
        $this //= __PACKAGE__;
        $self = $this->new( $opts );
    }
    $opts->{file} //= '';
    my $file = $opts->{file} || $self->file;
    $file = $self->_is_a( $file, 'Module::Generic::File' ) ? $file : Module::Generic::File::file( $file );
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new(
        agent => "Cookie::Domain/" . $VERSION,
    );
    my $meta = $self->meta;
    my $req_headers = {};
    my $dont_have_etag = 0;
    my $mtime = $meta->{db_last_modified}
        ? $meta->{db_last_modified}
        : ( $file->exists && !$file->is_empty )
            ? $file->mtime
            : undef;
    # If we have already a local file and it is not empty, let's use the etag when making the request
    if( $meta->{etag} && $file->exists && !$file->is_empty )
    {
        $meta->{etag} =~ s/^\"([^"]+)\"$/$1/;
        $req_headers->{'If-None-Match'} = qq{"$meta->{etag}"};
    }
    elsif( !$meta->{etag} )
    {
        $dont_have_etag = 1;
        # <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since>
        if( defined( $mtime ) && $mtime )
        {
            my $dt = $self->_parse_timestamp( $mtime );
            if( $dt )
            {
                # HTTP Date format
                my $dt_fmt = DateTime::Format::Strptime->new(
                    pattern => '%a, %d %b %Y %H:%M:%S GMT',
                    locale => 'en_GB',
                    time_zone => 'GMT',
                );
                $dt->set_formatter( $dt_fmt );
                $req_headers->{ 'If-Modified-Since' } = $dt;
            }
        }
    }
    
    # try-catch
    local $@;
    my $resp = eval
    {
        $ua->get( URL, %$req_headers );
    };
    if( $@ )
    {
        return( $self->error( "Error trying to perform an HTTP GET request to ", URL, ": $@" ) );
    }
    my $code = $resp->code;
    # try-catch
    my $data = eval
    {
        $resp->decoded_content( default_charset => 'utf-8', alt_charset => 'utf-8' );
    };
    if( $@ )
    {
        return( $self->error( "Error decoding response content: $@" ) );
    }
    my $last_mod = $resp->header( 'Last-Modified' );

    my $tz;
    # DateTime::TimeZone::Local will die ungracefully if the local timezeon is not set with the error:
    # "Cannot determine local time zone"
    # try-catch
    $tz = eval
    {
        DateTime::TimeZone->new( name => 'local' );
    };
    if( $@ )
    {
        $tz = DateTime::TimeZone->new( name => 'UTC' );
    }
    
    if( $last_mod )
    {
        $last_mod = $self->_parse_timestamp( $last_mod )->set_time_zone( $tz );
    }
    else
    {
        $last_mod = DateTime->now( time_zone => $tz );
    }
    my $epoch = $last_mod->epoch;
    if( $resp->header( 'etag' ) )
    {
        $dont_have_etag = $resp->header( 'etag' ) eq ( $meta->{etag} // '' ) ? 0 : 1;
        $meta->{etag} = $resp->header( 'etag' );
        $meta->{etag} =~ s/^\"([^"]+)\"$/$1/;
    }
    
    if( $code == 304 || 
        ( !$file->is_empty && $mtime && $mtime == $epoch ) )
    {
        if( !$self->suffixes->length )
        {
            $self->load_public_suffix || return( $self->pass_error );
        }
        # Did not have an etag, but I do have one now
        if( $dont_have_etag && $meta->{etag} )
        {
            $self->save_as_json || return( $self->pass_error );
        }
        return( $self );
    }
    elsif( $code ne 200 )
    {
        return( $self->error( "Failed to get the remote public domain list. Server responded with code '$code': ", $resp->as_string ) );
    }
    elsif( !length( $data ) )
    {
        return( $self->error( "Remote server returned no data." ) );
    }
    $file->unload_utf8( $data, { lock => 1 } ) || return( $self->error( "Unable to open public suffix data file \"$file\" in write mode: ", $file->error ) );
    $file->unlock;
    $file->utime( $epoch, $epoch );
    $self->load_public_suffix || return( $self->pass_error );
    $self->save_as_json || return( $self->pass_error );

    return( $self );
}

sub decode
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    return( '' ) if( !length( $name ) );
    # try-catch
    local $@;
    my $rv = eval
    {
        return( Net::IDN::Encode::domain_to_ascii( $name ) );
    };
    if( $@ )
    {
        return( $self->error( "An unexpected error occurred while decoding a domain name: $@" ) );
    }
    return( $rv );
}

sub encode
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    return( '' ) if( !length( $name ) );
    # try-catch
    local $@;
    my $rv = eval
    {
        return( Net::IDN::Encode::domain_to_unicode( $name ) );
    };
    if( $@ )
    {
        return( $self->error( "An unexpected error occurred while encoding a domain name: $@" ) );
    }
    return( $rv );
}

sub file { return( shift->_set_get_object_without_init( 'file', 'Module::Generic::File', @_ ) ); }

sub json_file { return( shift->_set_get_object_without_init( 'json_file', 'Module::Generic::File', @_ ) ); }

sub load
{
    my $self = shift( @_ );
    my $f = $self->file;
    my $json_file = $self->json_file;
    if( defined( $PUBLIC_SUFFIX_DATA ) && ref( $PUBLIC_SUFFIX_DATA ) eq 'HASH' )
    {
        $self->suffixes( $PUBLIC_SUFFIX_DATA );
        $self->meta( {} );
    }
    elsif( $json_file && $json_file->exists )
    {
        $self->load_json( $json_file ) || return( $self->pass_error );
        my $meta = $self->meta;
        if( $f && $f->exists )
        {
            if( defined( $meta->{db_last_modified} ) && $meta->{db_last_modified} =~ /^\d{10}$/ )
            {
                my $mtime = $f->mtime;
                if( $mtime > $meta->{db_last_modified} )
                {
                    $self->load_public_suffix( $f ) || return( $self->pass_error );
                    $self->save_as_json( $json_file ) || return( $self->pass_error );
                }
            }
            else
            {
                $self->load_public_suffix( $f ) || return( $self->pass_error );
                $self->save_as_json( $json_file ) || return( $self->pass_error );
            }
        }
    }
    else
    {
        return( $self->error( "No public suffix data file or json cache data file was specified." ) ) if( !$json_file && !$f );
        $self->load_public_suffix( $f ) || return( $self->pass_error );
        $self->save_as_json( $json_file ) || return( $self->pass_error );
    }
    return( $self );
}

sub load_json
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || $self->json_file || return( $self->error( "No json file was specified." ) );
    $file = $self->_is_a( $file, 'Module::Generic::File' ) ? $file : Module::Generic::File::file( "$file" );
    # Basic error checking
    if( !$file->exists )
    {
        return( $self->error( "Json data file provided \"$file\" does not exist." ) );
    }
    elsif( !$file->can_read )
    {
        return( $self->error( "Json data file provided \"$file\" lacks enough permission to read." ) );
    }
    elsif( $file->is_empty )
    {
        return( $self->error( "Json data file provided \"$file\" is empty." ) );
    }
    my $json = $file->load_utf8;
    return( $self->error( "Unable to open the public suffix json data file in read mode: $!" ) ) if( !defined( $json ) );
    return( $self->error( "No data found from public domain json file \"$file\"." ) ) if( !CORE::length( $json ) );
    # try-catch
    local $@;
    my $ref = eval
    {
        my $j = JSON->new->relaxed;
        return( $j->decode( $json ) );
    };
    if( $@ )
    {
        return( $self->error( "An unexpected error occurred while trying to load json data of public suffixes: $@" ) );
    }
    if( ref( $ref->{suffixes} ) eq 'HASH' )
    {
        $PUBLIC_SUFFIX_DATA = $ref->{suffixes};
        $self->suffixes( $ref->{suffixes} );
    }
    $ref->{meta} = {} if( ref( $ref->{meta} ) ne 'HASH' );
    $self->meta( $ref->{metadata} );
    return( $self );
}

sub load_public_suffix
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || $self->file || return( $self->error( "No public suffix data file was provided." ) );
    $file = $self->_is_a( $file, 'Module::Generic::File' ) ? $file : Module::Generic::File::file( "$file" );
    # Basic error checking
    if( !$file->exists )
    {
        return( $self->error( "Public suffix data file provided \"$file\" does not exist." ) );
    }
    elsif( !$file->can_read )
    {
        return( $self->error( "Public suffix data file provided \"$file\" lacks enough permission to read." ) );
    }
    elsif( $file->is_empty )
    {
        return( $self->error( "Public suffix data file provided \"$file\" is empty." ) );
    }
    $file->open( '<', { binmode => 'utf-8' }) || return( $self->error( "Unable to open the public suffix data file in read mode: ", $file->error ) );
    my $ref = {};
    $file->line(sub
    {
        my $l = shift( @_ );
        chomp( $l );
        $l =~ s,//.*$,,;
        $l =~ s,[[:blank:]\h]+$,,g;
        return(1) if( !CORE::length( $l ) );
        my $orig;
        if( $l !~ /^[\x00-\x7f]*$/ )
        {
            $orig = $l;
            # try-catch
            local $@;
            $l = eval
            {
                Net::IDN::Encode::domain_to_ascii( $l );
            };
            if( $@ )
            {
                return( $self->error( "An unexpected error occurred while parsing the public suffix data file content: $@" ) );
            }
        }
        my $is_neg = $l =~ s,^\!,,;
        my @labels = split( /\./, $l );
        my $h = $ref;
        foreach my $label ( reverse( @labels ) )
        {
            $h = $h->{ $label } ||= {};
        }
        $h->{_is_neg} = $is_neg if( $is_neg );
        $h->{_original} = $orig if( defined( $orig ) );
    });

    $file->close;
    # Although this is a private extension, it is still valid nevertheless, and is missing as of 2024-02-02
    if( !CORE::exists( $ref->{test} ) )
    {
        $ref->{test} = {};
    }
    $self->suffixes( $ref );
    $PUBLIC_SUFFIX_DATA = $ref;
    return( $self );
}

sub meta { return( shift->_set_get_hash_as_mix_object( 'meta', @_ ) ); }

sub min_suffix { return( shift->_set_get_number( 'min_suffix', @_ ) ); }

sub no_load { return( shift->_set_get_boolean( 'no_load', @_ ) ); }

sub save_as_json
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || $self->json_file || return( $self->error( "No json file was specified." ) );
    $file = $self->_is_a( $file, 'Module::Generic::File' ) ? $file : Module::Generic::File::file( "$file" );
    my $data = $self->suffixes;
    my $tz;
    # DateTime::TimeZone::Local will die ungracefully if the local timezeon is not set with the error:
    # "Cannot determine local time zone"
    # try-catch
    local $@;
    $tz = eval
    {
        DateTime::TimeZone->new( name => 'local' );
    };
    if( $@ )
    {
        $tz = DateTime::TimeZone->new( name => 'UTC' );
    }
    my $dt_fmt = DateTime::Format::Strptime->new(
        pattern => '%FT%T%z',
        locale => 'en_GB',
        time_zone => $tz->name,
    );
    my $today = DateTime->now( time_zone => $tz, formatter => $dt_fmt );
    my $meta  = $self->meta;
    my $ref =
    {
        metadata =>
        {
            created => $today->stringify,
            module  => 'Cookie::Domain',
            ( $self->file && $self->file->exists ? ( db_last_modified => $self->file->mtime ) : () ),
            ( $meta->{etag} ? ( etag => $meta->{etag} ) : () ),
        },
        suffixes => $data
    };
    my $j = JSON->new->canonical->pretty->convert_blessed;
    # try-catch
    my $json = eval
    {
        $j->encode( $ref );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to save data to json file \"$file\": $@" ) );
    }
    $file->unload_utf8( $json ) || 
        return( $self->error( "Unable to write json data to file \"$file\": ", $file->error ) );
    return( $self );
}

sub stat
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No host name was provided" ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{min_suffix} = $self->min_suffix if( !exists( $opts->{min_suffix} ) );
    my $idn;
    # Punnycode
    if( $name !~ /^[\x00-\x7f]*$/ )
    {
        $idn = $name;
        $name = Net::IDN::Encode::domain_to_ascii( $name );
        $name = lc( $name );
        $name =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
        $name =~s/\.$//;
    }
    else
    {
        $name =~ s/^\.|\.$//g;
        $name = lc( $name );
    }
    return( $self->error( "Malformed domain name \"$name\"" ) ) if( $name !~ /$DOMAIN_RE/ );
    my $labels = $self->new_array( [split( /\./, $name )] );
    my $any  = {};
    my $host = {};
    my $expt = {};
    my $ref  = $self->suffixes;
    my $def  = $ref;
    my $stack = [];
    # The following algorithm is borrowed from IO-Socket-SSL
    # for( my $i = 0; $i < scalar( @$labels ); $i++ )
    # $labels->reverse->for(sub
    my $reverse = $labels->reverse;
    for( my $i = 0; $i < scalar( @$reverse ); $i++ )
    {
        my $label = $reverse->[$i];
        # my( $i, $label ) = @_;
        my $buff = [];
        if( my $public_label_def = $def->{ $label } )
        {
            # name match, continue with next path element
            push( @$buff, $public_label_def );
            if( exists( $public_label_def->{_is_neg} ) && $public_label_def->{_is_neg} )
            {
                $expt->{ $i + 1 }->{ $i + 1 } = -1;
            }
            else
            {
                $host->{ $i + 1 }->{ $i + 1 } = 1;
            }
        }
        elsif( exists( $def->{ '*' } ) )
        {
            my $public_label_def = $def->{ '*' };
            push( @$buff, $public_label_def );
            if( exists( $public_label_def->{_is_neg} ) && $public_label_def->{_is_neg} )
            {
                $expt->{ $i + 1 }->{ $i + 1 } = -1;
            }
            else
            {
                $any->{ $i + 1 }->{ $i + 1 } = 1;
            }
        }
        
        no warnings 'exiting';
        LABEL:
        # We found something
        if( @$buff )
        {
            # take out the one we just added
            $def = shift( @$buff );
            # if we are circling within the next_choice loop, add the previous step to $stack
            push( @$stack, [ $buff, $i ] ) if( @$buff );
            # go deeper
            next;
            # The following works too by the way, but let's keep it traditional
            # return(1);
        }

        # We did not find anything, so we backtrack
        last if( !scalar( @$stack ) );
        # The following works too by the way, but let's keep it traditional
        # return if( !scalar( @$stack ) );
        # Recall our last entry
        ( $buff, $_[0] ) = @{ pop( @$stack ) };
        goto LABEL;
    # });
    }
    
    # remove all exceptions from wildcards
    delete( @$any{ keys( %$expt ) } ) if( scalar( keys( %$expt ) ) );
    # get longest match
    my( $len ) = sort{ $b <=> $a } (
        keys( %$any ), keys( %$host ), map{ $_-1 } keys( %$expt )
    );
    $len = $opts->{min_suffix} if( !defined( $len ) );
    $len += int( $opts->{add} ) if( $opts->{add} );
    my $suffix;
    my $sub;
    if( $len < $labels->length )
    {
        $suffix = $self->new_array( [ $labels->splice( -$len, $len ) ] );
    }
    elsif( $len > 0 )
    {
        $suffix = $labels;
        $labels = $self->new_array;
    }
    else
    {
        $suffix = $self->new_array;
    }
    if( !$suffix->length )
    {
        if( want( 'OBJECT' ) )
        {
            rreturn( Module::Generic::Null->new );
        }
        else
        {
            return( '' );
        }
    }
    $suffix = $suffix->join( '.' );
    $name = $labels->pop;
    $sub  = $labels->join( '.' ) if( $labels->length );
    if( defined( $idn ) )
    {
        $suffix = Net::IDN::Encode::domain_to_unicode( $suffix );
        $name   = Net::IDN::Encode::domain_to_unicode( $name ) if( defined( $name ) );
        $sub    = Net::IDN::Encode::domain_to_unicode( $sub ) if( defined( $sub ) );
    }
    return(Cookie::Domain::Result->new({ name => $name, sub => $sub, suffix => $suffix }));
}

sub suffixes { return( shift->_set_get_hash_as_mix_object( 'suffixes', @_ ) ); }

# NOTE: Cookie::Domain::Result class
{
    package
        Cookie::Domain::Result;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic::Hash );
        use Want;
        our $VERSION = 'v0.1.0';
    };
    
    sub domain
    {
        my $self = shift( @_ );
        if( !$self->name->length && !$self->suffix->length )
        {
            return( Module::Generic::Scalar->new( '' ) );
        }
        return( $self->name->join( '.', $self->suffix ) );
    }
    
    sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

    sub sub { return( shift->_set_get_scalar_as_object( 'sub', @_ ) ); }

    sub suffix { return( shift->_set_get_scalar_as_object( 'suffix', @_ ) ); }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Cookie::Domain - Domain Name Public Suffix Query Interface

=head1 SYNOPSIS

    use Cookie::Domain;
    my $dom = Cookie::Domain->new( min_suffix => 1, debug => 3 ) ||
        die( Cookie::Domain->error, "\n" );
    my $res = $dom->stat( 'www.example.or.uk' ) || die( $dom->error, "\n" );
    # Check for potential errors;
    die( $dom->error ) if( !defined( $res ) );
    # stat() returns an empty string if nothing was found and undef upon error
    print( "Nothing found\n" ), exit(0) if( !$res );
    print( $res->domain, "\n" ); # example.co.uk
    print( $res->name, "\n" ); # example
    print( $res->sub, "\n" ); # www
    print( $res->suffix, "\n" ); # co.uk

    # Load the public suffix. This is done automatically, so no need to do it
    $dom->load_public_suffix( '/some/path/on/the/filesystem/data.txt' ) || 
        die( $dom->error );
    # Then, save it as json data for next time
    $dom->save_as_json( '/var/domain/public_suffix.json' ) || 
        die( $dom->error, "\n" );
    say $dom->suffixes->length, " suffixes data loaded.";

=head1 VERSION

    v0.1.6

=head1 DESCRIPTION

This is an interface to query the C<Public Suffix> list courtesy of the mozilla project.

This list contains all the top level domains, a.k.a. zones and is used to determine what part of a domain name constitute the top level domain, what part is the domain, a.k.a. C<label> and what part (the rest) constitute the subdomain.

Consider C<www.example.org>. In this example, C<org> is the top level domain, C<example> is the name, C<example.org> is the domain, and C<www> is the subdomain.

This is easy enough, but there are cases where it is tricky to know which label (or part) is the domain part or the top level domain part. For example, C<www.example.com.sg>, C<com.sg> is the top level domain, C<example> the name, C<example.com.sg> is the domain, and C<www> the subdomain.

This module will use a json cache data file to speed up the loading of the suffixes, a.k.a, top level domains, data.

By default the location of this json file will be C<public_suffix.json> under your system temporary directory, but you can override this by specifying your own location upon object instantiation:

    my $dom = Cookie::Domain->new( json_file => '/home/joe/var/public_suffix.json' );

=head1 METHODS

=head2 new

This initiates the package and take the following parameters either as an hash or hash reference:

=over 4

=item * C<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=item * C<file>

Specify the location of the Public Suffix data file. The default one is under the same directory as this module with the file name C<public_suffix_list.txt>

You can download a different (new) version and specify with this parameter where it will be found.

=item * C<json_file>

Specify the location of the json cache data file. The default location is set using L<Module::Generic::File> to get the system temporary directory and the file name C<public_suffix.json>.

This json file is created once upon initiating an object and if it does not already exist. See the L</json_file> method for more information.

=item * C<min_suffix>

Sets the minimum suffix length required. Default to 0.

=item * C<no_load>

If this is set to true, this will prevent the object instantiation method from loading the public suffix file upon object instantiation. Normally you would not want to do that, unless you want to control when the file is loaded before you call L</stat>. This is primarily used by L</cron_fetch>

=back

=head2 cron_fetch

You need to have installed the package L<LWP::UserAgent> to use this method.

This method can also be called as a package subroutine, such as C<Cookie::Domain::cron_fetch>
    
Its purpose is to perform a remote connection to L<https://publicsuffix.org/list/effective_tld_names.dat> and check for an updated copy of the public suffix data file.

It checks if the remote file has changed by using the http header field C<Last-Modified> in the server response, or if there is already an C<etag> stored in the cache, it performs a conditional http query using C<If-None-Matched>. See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag> for more information on those types of query.

This is important to save bandwidth and useless processing.

If the file has indeed changed, L</save_as_json> is invoked to refresh the cache.

It returns the object it was called with for chaining.

=head2 decode

Takes a domain name, or rather called a host name, such as C<www.東京.jp> or C<今何年.jp> and this will return its punycode ascii representation prefixed with a so-called ASCII Compatible Encoding, a.k.a. C<ACE>. Thus, using our previous examples, this would produce respectively C<www.xn--1lqs71d.jp> and C<xn--wmq0m700b.jp>

Even if the host name contains non-ascii dots, they will be recognised. For example C<www。東京。jp> would still be successfully decoded to C<www.xn--1lqs71d.jp>

If the host name provided is not an international domain name (a.k.a. IDN), it is simply returned as is. Thus, if C<www.example.org> is provided, it would return C<www.example.org>

If an error occurred, it sets an error object and returns L<perlfunc/undef>. The error can then be retrieved using L<Module::Generic/error> inherited by this module.

It uses L<Net::IDN::Encode/domain_to_ascii> to perform the actual decoding.

=head2 encode

This does the reverse operation from L</decode>.

It takes a domain name, or rather called a host name, already decoded, and with its so called ASCII Compatible Encoding a.k.a. C<ACE> prefix C<xn--> such as C<xn--wmq0m700b.jp> and returns its encoded version in perl internal utf8 encoding. Using the previous example, and this would return C<今何年.jp>. The C<ACE> prefix is required to tell apart international domain name (a.k.a. IDN) from other pure ascii domain names.

Just like in L</decode>, if a non-international domain name is provided, it is returned as is. Thus, if C<www.example.org> is provided, it would return C<www.example.org>

Note that this returns the name in perl's internal utf8 encoding, so if you need to save it to an utf8 file or print it out as utf8 string, you still need to encode it in utf8 before. For example:

    use Cookie::Domain;
    use open ':std' => ':utf8';
    my $d = Cookie::Domain->new;
    say $d->encode( "xn--wmq0m700b.jp" );

Or

    use Cookie::Domain;
    use Encode;
    my $d = Cookie::Domain->new;
    my $encoded = $d->encode( "xn--wmq0m700b.jp" );
    say Encode::encode_utf8( $encoded );

If an error occurred, it sets an error object and returns L<perlfunc/undef>. The error can then be retrieved using L<Module::Generic/error> inherited by this module.

It uses L<Net::IDN::Encode/domain_to_unicode> to perform the actual encoding.

=head2 file

Sets the file path to the Public Suffix file. This file is a public domain file at the initiative of Mozilla Foundation and its latest version can be accessed here: L<https://publicsuffix.org/list/>

=head2 json_file

Sets the file path of the json cache data file. THe purpose of this file is to contain a json representation of the parsed data from the Public Suffix data file. This is to avoid re-parsing it each time and instead load the json file using the XS module L<JSON>

=head2 load

This method takes no parameter and relies on the properties set with L</file> and L</json_file>.

If the hash data is already accessibly in a module-wide variable, the data is taken from it.

Otherwise, if json_file is set and accessible, this will load the data from it, otherwise, it will load the data from the file specified with L</file> and save it as json.

If the json file meta data enclosed, specifically the property I<db_last_modified> has a unix timestamp value lower than the last modification timestamp of the public suffix data file, then, L</load> will reload that data file and save it as json again.

That way, all you need to do is set up a crontab to fetch the latest version of that public suffix data file.

For example, to fetch it every day at 1:00 in the morning:

    0 1 * * * perl -MCookie::Domain -e 'Cookie::Domain::cron_fetch' >/dev/null 2>&1

But if you want to store the public suffix data file somewhere other than the default location:

    0 1 * * * perl -MCookie::Domain -e 'my $d=Cookie::Domain->new(file=>"/some/system/file.txt"); $d->cron_fetch' >/dev/null 2>&1

See your machine manpage for C<crontab> for more detail.

The data read are loaded into L</suffixes>.

It returns the current object for chaining.

=head2 load_json

This takes a file path to the json cache data as the only argument, and attempt to read its content and set it onto the data accessible with L</suffixes>.

If an error occurs, it set an error object using L<Module::Generic/error> and returns L<perlfunc/undef>

It returns its current object for chaining.

=head2 load_public_suffix

This is similar to the method L</load_json> above.

This takes a file path to the Public Suffix data as the only argument, read its content, parse it using the algorithm described at L<https://publicsuffix.org/list/> and set it onto the data accessible with L</suffixes> and also onto the package-wide global variable to make the data available across object instantiations.

If an error occurs, it set an error object using L<Module::Generic/error> and returns L<perlfunc/undef>

It returns its current object for chaining.

=head2 meta

Returns an L<hash object|Module::Generic::Hash> of meta information pertaining to the public suffix file. This is used primarily by L</cron_fetch>

=head2 min_suffix

Sets or gets the minimum suffix required as an integer value.

It returns the current value as a L<Module::Generic::Number> object.

=head2 no_load

If this is set to true, this will prevent the object instantiation method from loading the public suffix file upon object instantiation. Normally you would not want to do that, unless you want to control when the file is loaded before you call L</stat>. This is primarily used by L</cron_fetch>

=head2 save_as_json

This takes as sole argument the file path where to save the json cache data and save the data accessible with L</suffixes>.

It returns the current object for chaining.

If an error occurs, it set an error object using L<Module::Generic/error> and returns L<perlfunc/undef>

=head2 stat

This takes a domain name, such as C<www.example.org> and optionally an hash reference of options and returns:

=over 4

=item C<undef()>

If an error occurred.

    my $rv = $d->stat( 'www.example.org' );
    die( "Error: ", $d->error ) if( !defined( $rv ) );

=item empty string

If there is no data available such as when querying a non existing top level domain.

=item A C<Cookie::Domain::Result> object

An object with the following properties and methods, although not all are necessarily defined, depending on the results.

Accessed as an hash property and this return a regular string, but accessed as a method and they will return a L<Module::Generic::Scalar> object.

=over 8

=item I<name>

The label that immediately follows the suffix (i.e. on its lefthand side).

For example, in C<www.example.org>, the I<name> would be C<example>

    my $res = $dom->stat( 'www.example.org' ) || die( $dom->error );
    say $res->{name}; # example
    # or alternatively
    say $res->name; # example

=item I<sub>

The sub domain or sub domains that follows the domain on its lefthand side.

For example, in C<www.paris.example.fr>, C<www.paris> is the I<sub> and C<example> the I<name>

    my $res = $dom->stat( 'www.paris.example.fr' ) || die( $dom->error );
    say $res->{sub}; # www.paris
    # or alternatively
    say $res->sub; # www.paris

=item I<suffix>

The top level domain or I<suffix>. For example, in C<example.com.sg>, C<com.sg> is the suffix and C<example> the I<name>

    my $res = $dom->stat( 'example.com.sg' ) || die( $dom->error );
    say $res->{suffix}; # com.sg
    # or alternatively
    say $res->suffix; # com.sg

What constitute a suffix varies from zone to zone or country to country, hence the necessity of this public domain suffix data file.

=back

C<Cookie::Domain::Result> objects inherit from L<Module::Generic::Hash>, thus you can do:

    my $res = $dom->stat( 'www.example.org' ) || die( $dom->error );
    say $res->length, " properties set.";
    # which should say 3 since we alway return suffix, name and sub

The following additional method is also available as a convenience:

=over 8

=item I<domain>

This is a read only method which returns and empty L<Module::Generic::Scalar> object if the I<name> property is empty, or the properties I<name> and I<suffix> join by a dot '.' and returned as a new L<Module::Generic::Scalar> object.

    my $res = $dom->stat( 'www.example.com.sg' ) || die( $dom->error );
    say $res->domain; # example.com.sg
    say $res->domain->length; # 14

=back

=back

The options accepted are:

=over 4

=item I<add>

This is an integer, and represent the additional length to be added, for the domain name.

=item I<min_suffix>

This is an integer, and if provided, will override the default value set with L</min_suffix>

=back

=head2 suffixes

This method is used to access the hash repository of all the public suffix data.

It is actually an L<Module::Generic::Hash> object. So you could do:

    say "There are ", $dom->suffixes->length, " rules.";

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Cookie>, L<Cookie::Jar>, L<Mozilla::PublicSuffix>, L<Domain::PublicSuffix>, L<Net::PublicSuffixList>

L<https://publicsuffix.org/list/>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
