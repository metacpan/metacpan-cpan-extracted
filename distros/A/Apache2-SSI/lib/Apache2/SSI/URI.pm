##----------------------------------------------------------------------------
## Apache2 Server Side Include Parser - ~/lib/Apache2/SSI/URI.pm
## Version v0.1.2
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/12/18
## Modified 2022/10/21
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::SSI::URI;
BEGIN
{
    use strict;
    use warnings::register;
    use parent qw( Apache2::SSI::Common );
    use vars qw( $VERSION $DEBUG $DIR_SEP );
    use Apache2::SSI::Finfo;
    use Cwd;
    use File::Spec ();
    # Used for debugging
    # use Devel::Confess;
    use Nice::Try;
    use Scalar::Util ();
    require constant;
    use URI;
    use constant URI_CLASS => 'URI';
    use URI::file;
    if( $ENV{MOD_PERL} )
    {
        require Apache2::RequestRec;
        require Apache2::RequestUtil;
        require Apache2::SubRequest;
        require Apache2::Access;
        require Apache2::Const;
        Apache2::Const->import( compile => qw( :common :http OK DECLINED ) );
    }
    # use Devel::Confess;
    our( $DEBUG );
    use overload (
        q{""}    => sub    { $_[0]->document_uri->as_string },
        bool     => sub () { 1 },
        fallback => 1,
    );
    our $VERSION = 'v0.1.2';
    our $DIR_SEP = $Apache2::SSI::Common::DIR_SEP;
};

use strict;
use warnings;

# document_root = /home/joe/www
# base_uri      = /my/uri/file.html/some/path/info?q=something&l=ja_JP
# base_uri is the current reference document
# document_uri  = ./about.html
# document_uri is the uri which is the purpose of this object. It will be made absolute and its dots flattened
# Example: ../about.html?q=hello would become /my/about.html?q=hello
sub init
{
    my $self = shift( @_ );
    $self->{apache_request} = '';
    $self->{base_uri}       = '/' unless( length( $self->{base_uri} ) );
    # By default
    $self->{code}           = 200;
    $self->{document_path}  = '';
    $self->{document_root}  = '';
    # Reference document for the main request
    $self->{document_uri}   = '';
    $self->{filepath}       = '';
    $self->{finfo}          = '';
    $self->{_init_params_order} = [qw( apache_request document_root base_uri document_uri document_path filepath )];
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return;
    $self->{_env}            = {};
    $self->{_path_info_processed} = 0;
    $self->{_uri_reset}      = 0;
    $self->{document_root} ||= $self->env( 'DOCUMENT_ROOT' );
    $self->{base_uri}      ||= $self->env( 'DOCUMENT_URI' );
    return( $self->error( "No document root was provided." ) ) if( !length( $self->{document_root} ) );
    return( $self->error( "No base uri was provided." ) ) if( !length( $self->{base_uri} ) );
    return( $self->error( "No document uri was provided." ) ) if( !length( $self->{document_uri} ) );
    # Small correction if necessary. If the base uri is a directory, it needs to have a trailing "/", so URI knows this is a directory and not a file.
    # URI->new( "./file.pl" )->abs( "/ssi/plop" ) becomes "/ssi/file.pl" whereas it should be /ssi/plop/file.pl
    # $self->{base_uri} .= '/' if( length( $self->{base_uri} ) && -d( "$self->{document_root}$self->{base_uri}" ) && substr( $self->{base_uri}, -1, 1 ) ne '/' );
    return( $self );
}

sub apache_request { return( shift->_set_get_object_without_init( 'apache_request', 'Apache2::RequestRec', @_ ) ); }

sub base_dir
{
    my $self = shift( @_ );
    return( $self->{base_dir} ) if( length( $self->{base_dir} ) );
    # Just in case
    return( $self->root ) if( !length( $self->{base_uri} ) );
    my $base = $self->base_uri;
    return( $self->error( "No base uri defined." ) ) if( !length( $base ) );
    my $path = $base->document_path;
    my @segments = split( '/', $path, -1 );
    pop( @segments );
    return( $base ) if( !scalar( @segments ) );
    my $r = $self->apache_request;
    my $dir_path = join( '/', @segments );
    
    my $hash = {};
    if( $r )
    {
        my $rr = $self->lookup_uri( $dir_path );
        if( !defined( $rr ) )
        {
            return;
        }
        elsif( $rr->status != &Apache2::Const::HTTP_OK )
        {
            return( $self->error( "Could not look up base directory \"$dir_path\". Returned code is: ", $rr->status ) );
        }
        elsif( $rr->finfo->filetype == &APR::Const::FILETYPE_NOFILE )
        {
            return( $self->error( "Could not find base directory \"$dir_path\"." ) );
        }
        # Remove trailing slash
        my $u = $self->_trim_trailing_slash( $rr->uri );
        
        $hash =
        {
        apache_request => $self->apache_request,
        base_dir => $self->root,
        base_uri => $self->root,
        document_path => "$u",
        document_root => $rr->document_root,
        document_uri => "$u",
        filename => $rr->filename,
        path_info => $rr->path_info,
        query_string => scalar( $rr->args ),
        _path_info_processed => 1,
        };
    }
    else
    {
        $hash =
        {
        base_dir => $self->root,
        base_uri => $self->root,
        document_path => $dir_path,
        document_root => $self->document_root,
        document_uri => $dir_path,
        filename => $self->document_root . $dir_path,
        path_info => '',
        query_string => '',
        _path_info_processed => 1,
        };
    }
    $self->{base_dir} = bless( $hash => ref( $self ) );
    return( $self->{base_dir} );
}

sub base_uri
{
    my $self = shift( @_ );
    my $new;
    if( @_ )
    {
        $new = shift( @_ );
    }
    elsif( !ref( $self->{base_uri} ) )
    {
        $new = $self->{base_uri};
    }
    
    unless( length( $new ) )
    {
        return( $self->{base_uri} );
    }
    
    my $r = $self->apache_request;
    # We create an URI object, so we can get the path only
    my $u = $self->new_uri( $new );
    my $path = $u->path;
    if( $r )
    {
        my $rr = $self->lookup_uri( $path );
        if( !defined( $rr ) )
        {
            return;
        }
        elsif( $rr->status != &Apache2::Const::HTTP_OK )
        {
            my $hdrs = $rr->headers_out;
            return( $self->error( "Could not look up uri \"$path\". Returned code is: ", $rr->status ) );
        }
        elsif( $rr->finfo->filetype == &APR::Const::FILETYPE_NOFILE )
        {
            return( $self->error( "Could not find uri \"$path\" (originally $u)." ) );
        }
        
        # Remove trailing slash
        my $u2 = $self->_trim_trailing_slash( $rr->unparsed_uri );
        
        my $hash =
        {
        apache_request => $r,
        base_dir => $self->root,
        base_uri => $self->root,
        document_path => substr( $u2->path, 0, length( $u2->path ) - length( $rr->path_info ) ),
        document_root => $self->document_root,
        document_uri => $u2,
        filename => $rr->filename,
        path_info => $rr->path_info,
        query_string => scalar( $rr->args ),
        _path_info_processed => 1,
        };
        if( $rr->finfo->filetype == &APR::Const::FILETYPE_DIR )
        {
            $self->{base_dir} = bless( $hash => ref( $self ) );
        }
        $self->{base_uri} = bless( $hash => ref( $self ) );
    }
    else
    {
        # We need to ensure the base uri is free of any path info or query string !
        my $ref = $self->_find_path_info( $u->path );
        if( !defined( $ref ) )
        {
            return( $self->error( "Unable to resolve \"$u\"." ) );
        }
        elsif( $ref->{code} != 200 )
        {
            $self->error( "Failed to resolve \"$u\". Resulting code is '$ref->{code}'." );
        }
        my $hash =
        {
        base_dir => $self->root,
        base_uri => $self->root,
        document_path => $ref->{path},
        document_root => $self->document_root,
        filename => $ref->{filepath},
        path_info => $ref->{path_info},
        query_string => $ref->{query_string},
        _path_info_processed => 1,
        };
        my $tmp = $self->new_uri( $ref->{path_info} ? join( '', $ref->{path}, $ref->{path_info} ) : $ref->{path} );
        $tmp->query( $ref->{query_string} ) if( $ref->{query_string} );
        $hash->{document_uri} = $tmp;
        $self->{base_dir} = bless( $hash => ref( $self ) ) if( -d( $ref->{path} ) );
        $self->{base_uri} = bless( $hash => ref( $self ) );
    }
    return( $self->{base_uri} );
}

sub clone
{
    my $self = shift( @_ );
    my $new = {};
    my @fields = grep( !/^(apache_request|finfo)$/, keys( %$self ) );
    @$new{ @fields } = @$self{ @fields };
    $new->{apache_request} = $self->{apache_request};
    my $env = {};
    %$env = %{$self->{_env}};
    $new->{_env} = $env;
    return( bless( $new => ( ref( $self ) || $self ) ) );
}

sub code
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    if( $r )
    {
        $r->status( @_ ) if( @_ );
        return( $r->status );
    }
    else
    {
        $self->{code} = shift( @_ ) if( @_ );
        return( int( $self->{code} ) );
    }
}

sub document_dir { return( shift->document_directory( @_ ) ); }

sub document_directory
{
    my $self = shift( @_ );
    my $doc_path = $self->document_path || return( $self->error( "No document path set." ) );
    my $doc_root = $self->document_root || return( $self->error( "No document root set." ) );
    return( $self->make( document_uri => $doc_path ) ) if( -e( "${doc_root}${doc_path}" ) && -d( _ ) );
    my $parent = $self->parent;
    return( $parent );
}

sub document_filename { return( shift->filename( @_ ) ); }

sub document_path
{
    my $self = shift( @_ );
    my $class = ref( $self );
    my $caller = (caller(1))[3] // '';
    # my $caller = substr( $sub, rindex( $sub, ':' ) + 1 );
    my $r = $self->apache_request;
    if( $r )
    {
        if( @_ )
        {
            my $uri = shift( @_ );
            $r = $r->is_initial_req ? $r : $r->main;
            my $rr = $self->lookup_uri( $uri );
            if( !defined( $rr ) )
            {
                return;
            }
            my $u = APR::URI->parse( $rr->pool, $r->uri );
            # Remove trailing slash
            my $u2 = $self->_trim_trailing_slash( $u->rpath );
            $self->{document_path} = $u2;
            $self->{_uri_reset} = 'document_path' unless( $caller eq "${class}\::document_uri" );
        }
        elsif( !length( $self->{document_path} ) )
        {
            my $u = APR::URI->parse( $r->pool, $r->uri );
            $self->{document_path} = $self->new_uri( $u->rpath );
        }
    }
    else
    {
        if( @_ )
        {
            my $uri = shift( @_ );
            $self->{document_path} = $self->new_uri( $self->collapse_dots( $uri ) );
            $self->{_uri_reset} = 'document_path' unless( $caller eq "${class}\::document_uri" );
        }
    }
    return( $self->{document_path} );
}

sub document_root
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    my $new;
    if( @_ )
    {
        $new = shift( @_ );
        # unless( substr( $new, 0, 1 ) eq '/' )
        unless( File::Spec->file_name_is_absolute( $new ) )
        {
            $new = URI::file->new_abs( $new )->file( $^O );
        }
    }
    
    if( $r )
    {
        $r->document_root( $new ) if( defined( $new ) );
        $r->subprocess_env( DOCUMENT_ROOT => $r->document_root );
        return( $r->document_root );
    }
    else
    {
        if( defined( $new ) )
        {
            $self->{document_root} = $new;
            $self->_set_env( DOCUMENT_ROOT => $self->{document_root} );
        }
        return( $self->{document_root} || $self->env( 'DOCUMENT_ROOT' ) );
    }
}

sub document_uri
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    my $new = '';
    if( @_ )
    {
        $new = shift( @_ );
        local $URI::ABS_REMOTE_LEADING_DOTS = 1;
        unless( substr( "$new", 0, 1 ) eq '/' )
        {
            my $base_uri = $self->base_uri;
            $new = URI->new( $new )->abs( $base_uri->{document_path} );
        }
    }
    
    # return( $self->error( "Document URI needs to be an absolute URL path. Value provided was '$new'." ) ) if( length( $new ) && substr( $new, 0, 1 ) ne '/' );
    
    if( $r )
    {
        # We do a lookup unless we are already in a sub request, and we do not want to end up in an infinite loop
        # $r = $r->is_initial_req ? $r : $r->main;
        if( length( "$new" ) )
        {
            $r = $r->is_initial_req ? $r : $r->main;
            my $rr = $self->lookup_uri( "$new" );
            if( !defined( $rr ) )
            {
                return;
            }
            $self->apache_request( $rr );
            # Remove trailing slash
            my $u = $self->_trim_trailing_slash( $rr->unparsed_uri );
            $self->{document_uri} = $u;
            $self->_set_env( DOCUMENT_URI => $self->{document_uri} );
            $self->_set_env( REQUEST_URI => $self->{document_uri} );
            $self->_set_env( QUERY_STRING => scalar( $rr->args ) ) if( scalar( $rr->args ) );
            $self->_set_env( PATH_INFO => $rr->path_info ) if( $rr->path_info );
        }
        elsif( $self->{_uri_reset} )
        {
            my $u = URI->new( $r->uri . ( $r->path_info // '' ) );
            $u->query( scalar( $r->args ) ) if( length( scalar( $r->args ) ) );
            # Cannot change the value of $r->unparsed_uri
            $r->uri( "$u" );
            $self->{document_uri} = $u;
            $self->{_uri_reset} = 0;
        }
        elsif( !length( $self->{document_uri} ) )
        {
            $self->{document_uri} = $self->new_uri( $r->unparsed_uri );
            $self->_set_env( DOCUMENT_URI => $self->{document_uri} );
            $self->_set_env( REQUEST_URI => $self->{document_uri} );
            $self->_set_env( QUERY_STRING => scalar( $r->args ) ) if( scalar( $r->args ) );
            $self->_set_env( PATH_INFO => $r->path_info ) if( $r->path_info );
        }
        return( $self->{document_uri} );
    }
    else
    {
        if( length( "$new" ) )
        {
            $self->{_path_info_processed} = 0;
        }
        return( '' ) if( !length( $self->{document_uri} ) && $self->{_path_info_processed} );
        my $v = $new || $self->{document_uri};
        if( !$self->{_path_info_processed} )
        {
            $self->{_path_info_processed}++;
            my $res;
            if( defined( $res = $self->_find_path_info( $v ) ) )
            {
                $self->{document_uri} = URI->new( $v );
                $self->document_path( $res->{path} );
                $self->filename( $res->{filepath} );
                $self->path_info( $res->{path_info} ) if( length( $res->{path_info} ) );
                $self->query_string( $res->{query_string} ) if( length( $res->{query_string} ) );
                $self->_set_env( DOCUMENT_URI => $self->{document_uri} );
                $self->_set_env( REQUEST_URI => $self->{document_uri} );
                $self->code( $res->{code} );
            }
            else
            {
            }
        }
        
        if( $self->{_uri_reset} )
        {
            $self->{_uri_reset} = 0;
            my $u = URI->new( $self->document_path . ( $self->path_info // '' ) );
            $u->query( $self->query_string ) if( $self->query_string );
            $self->{document_uri} = $u;
        }
        return( $self->{document_uri} );
    }
}

sub env
{
    my $self = shift( @_ );
    # The user wants the entire hash reference
    unless( @_ )
    {
        my $r = $self->apache_request;
        if( $r )
        {
            # $r = $r->is_initial_req ? $r : $r->main;
            return( $r->subprocess_env )
        }
        else
        {
            unless( scalar( keys( %{$self->{_env}} ) ) )
            {
                $self->{_env} = {%ENV};
            }
            return( $self->{_env} );
        }
    }
    my $name = shift( @_ );
    return( $self->error( "No environment variable name was provided." ) ) if( !length( $name ) );
    my $opts = {};
    no warnings 'uninitialized';
    $opts = pop( @_ ) if( scalar( @_ ) && Scalar::Util::reftype( $_[-1] ) eq 'HASH' );
    # return( $self->error( "Environment variable value provided is a reference data (", overload::StrVal( $val ), ")." ) ) if( ref( $val ) && ( !overload::Overloaded( $val ) || ( overload::Overloaded( $val ) && !overload::Method( $val, '""' ) ) ) );
    my $r = $opts->{apache_request} || $self->apache_request;
    if( $r )
    {
        # $r = $r->is_initial_req ? $r : $r->main;
        $r->subprocess_env( $name => shift( @_ ) ) if( @_ );
        my $v = $r->subprocess_env( $name );
        return( $v );
    }
    else
    {
        my $env = {};
        unless( scalar( keys( %{$self->{_env}} ) ) )
        {
            # Make a copy of the environment variables
            $self->{_env} = {%ENV};
        }
        $env = $self->{_env};
        if( @_ )
        {
            $env->{ $name } = shift( @_ );
            my $meth = lc( $name );
            if( $self->can( $meth ) )
            {
                $self->$meth( $env->{ $name } );
            }
        }
        return( $env->{ $name } );
    }
}

# This is set by document_uri
sub filename
{
    my $self = shift( @_ );
    my $class = ref( $self );
    my $caller = (caller(1))[3] // '';
    # my $caller = substr( $sub, rindex( $sub, ':' ) + 1 );
    my $r = $self->apache_request;
    my $newfile;
    if( @_ )
    {
        $newfile = shift( @_ );
        return( $self->error( "New file provided, but it was an empty string." ) ) if( !defined( $newfile ) || !length( $newfile ) );
    }
    
    if( $r )
    {
        if( defined( $newfile ) )
        {
            $r = $r->is_initial_req ? $r : $r->main;
            my $rr = $r->lookup_file( $newfile );
            if( $rr->status == &Apache2::Const::HTTP_OK )
            {
                $newfile = $rr->filename;
            }
            else
            {
                $r->filename( $self->collapse_dots( $newfile, { separator => $DIR_SEP }) );
                # <https://perl.apache.org/docs/2.0/api/Apache2/RequestRec.html#toc_C_filename_>
                $r->finfo( APR::Finfo::stat( $newfile, &APR::Const::FINFO_NORM, $r->pool ) );
                $self->finfo( $newfile );
            }
            $r->subprocess_env( SCRIPT_FILENAME => $newfile );
            # Force to create new Apache2::SSI::URI object
            $self->{filename} = $newfile;
            $self->{_uri_reset} = 'filename' unless( $caller eq "${class}\::document_uri" );
        }
        elsif( !length( $self->{filename} ) )
        {
            $self->{filename} = $r->filename;
        }
    }
    else
    {
        if( defined( $newfile ) )
        {
            my $try = Cwd::realpath( $newfile );
            # Cwd::realpath would convert
            # Z:\perl\Apache2-SSI\t\htdocs\ssi\include.cgi
            # into 
            # Z:/perl/Apache2-SSI/t/htdocs/ssi/include.cgi
            # amazingly enough, so to make sure this keeps working on windows related platform, we need to call URI::file
            $newfile = URI::file->new( $try )->file( $^O ) if( defined( $try ) );
            unless( File::Spec->file_name_is_absolute( $newfile ) )
            {
                $newfile = URI::file->new_abs( $newfile )->file( $^O );
            }
            $self->env( SCRIPT_FILENAME => $newfile );
            $self->finfo( $newfile );
            # Force to create new Apache2::SSI::URI object
            # Either a URI object or an URI::file object
            $self->{filename} = $self->collapse_dots( $newfile, { separator => $DIR_SEP })->file( $^O );
            # Pass the file as new argument to URI::file which will create an object based on the value of the current OS
            # and transform it into a path à la linux, which is same as web, which is what we want
            # All this is unnecessary for linux type system or those who use / as directory separator,
            # but for windows type systems this is necessary
            if( CORE::index( $self->{filename}, $self->document_root ) != -1 )
            {
                $self->{document_path} = $self->new_uri( URI::file->new( substr( $self->{filename}, length( $self->document_root ) ) )->file( 'linux' ) );
            }
            else
            {
                $self->{document_path} = $self->new_uri( URI::file->new( $self->{filename} )->file( 'linux' ) );
            }
            $self->{_uri_reset} = 'filename' unless( $caller eq "${class}\::document_uri" );
        }
    }
    return( $self->{filename} );
}

# Alias
sub filepath { return( shift->filename( @_ ) ); }

sub finfo
{
    my $self = shift( @_ );
    my $r = $self->apache_request;
    my $newfile;
    if( @_ )
    {
        $newfile = shift( @_ );
        return( $self->error( "New file path specified but is an empty string." ) ) if( !defined( $newfile ) || !length( $newfile ) );
    }
    elsif( !$self->{finfo} )
    {
        $newfile = $self->filename;
        return( $self->error( "No file path set. This should not happen." ) ) if( !$newfile );
    }
    
    if( defined( $newfile ) )
    {
        $self->{finfo} = Apache2::SSI::Finfo->new( $newfile, ( $r ? ( apache_request => $r ) : () ), debug => $self->debug );
        return( $self->pass_error( Apache2::SSI::Finfo->error ) ) if( !$self->{finfo} );
    }
    return( $self->{finfo} );
}

sub lookup_uri
{
    my $self = shift( @_ );
    my $uri  = '';
    $uri = shift( @_ ) if( @_ && !ref( $_[0] ) && ( scalar( @_ ) % 2 ) );
    my $opts = {};
    $opts = Scalar::Util::reftype( $_[0] ) eq 'HASH'
        ? shift( @_ )
        : !( scalar( @_ ) % 2 )
            ? { @_ }
            : {};
    $uri = $opts->{uri} if( !length( $uri ) );
    return( $self->error( "No uri provided." ) ) if( !length( $uri ) );
    my $r = $opts->{apache_request} || $self->apache_request;
    my $max_redirects = $opts->{max_redirect} || 10;
    my $c = 0;
    my $rr = $r->lookup_uri( $uri );
    while( ++$c <= $max_redirects && 
           ( $rr->status == &Apache2::Const::HTTP_MOVED_PERMANENTLY || 
             $rr->status == &Apache2::Const::HTTP_MOVED_TEMPORARILY ) )
    {
        my $next_r = $rr->next;
        if( !defined( $next_r ) )
        {
            last;
        }
        else
        {
            $rr = $next_r;
        }
    }
    if( defined( $rr ) && 
        ( $rr->status == &Apache2::Const::HTTP_MOVED_PERMANENTLY || 
          $rr->status == &Apache2::Const::HTTP_MOVED_TEMPORARILY ) )
    {
        my $hdrs = $rr->headers_out;
        # Weird, should not happen, but just in case
        if( !exists( $hdrs->{Location} ) || !length( $hdrs->{Location} ) )
        {
            return( $rr );
        }
        
        try
        {
            # No, we cannot use $rr->uri. This would give us the initial requested uri, not the redirected uri
            my $u = URI->new( $hdrs->{Location} );
            $uri = $u->path;
            if( ++$self->{_lookup_looping} > 1 )
            {
                return( $rr );
            }
            else
            {
                delete( $self->{_lookup_looping} );
                my $new_r = $self->lookup_uri( $uri );
                return( $new_r );
            }
        }
        catch( $e )
        {
            $self->error( "An error occurred while creating URI object for \"$hdrs->{Location}\": $e" );
            return( $rr );
        }
    }   
    return( $rr );
}

sub make
{
    my $self = shift( @_ );
    return( $self->error( "Must be called with an existing object and not as ", __PACKAGE__, "->make()" ) ) if( !Scalar::Util::blessed( $self ) );
    my $p = {};
    @_ = () if( scalar( @_ ) == 1 && !defined( $_[0] ) );
    if( scalar( @_ ) )
    {
        no warnings 'uninitialized';
        $p = Scalar::Util::reftype( $_[0] ) eq 'HASH'
            ? shift( @_ )
            : !( scalar( @_ ) % 2 )
                ? { @_ }
                : {};
    }
    my $r = $self->apache_request;
    my $d = $self->document_root;
    my $b = $self->base_uri;
    my $f = $self->document_uri;
    $p->{apache_request} = $r if( !$p->{apache_request} && $r );
    $p->{document_root} = "$d" if( !$p->{document_root} && length( $d ) );
    $p->{base_uri} = "$b" if( !$p->{base_uri} && length( $b ) );
    $p->{document_uri} = "$f" if( !$p->{document_uri} );
    $p->{debug} = $self->debug if( !length( $p->{debug} ) );
    return( $self->new( $p ) );
}

sub new_uri
{
    my $self = shift( @_ );
    my $class = URI_CLASS;
    my $uri = shift( @_ );
    try
    {
        return( $class->new( $uri ) );
    }
    catch( $e )
    {
        return( $self->error( "Unable to instantiate an URI object with \"$uri\": $e" ) );
    }
}

sub parent
{
    my $self = shift( @_ );
    my $path = $self->document_path;
    my $r = $self->apache_request;
    # I deliberately did not do split( '/', $path, -1 ) so that if there is a trailing '/', it will not be counted
    my @segments = $self->document_path->path_segments;
    pop( @segments );
    return( $self ) if( !scalar( @segments ) );
    return( $self->make( document_uri => join( '/', @segments ) ) );
}

sub path_info
{
    my $self = shift( @_ );
    my $class = ref( $self );
    my $caller = (caller(1))[3] // '';
    # my $caller = substr( $sub, rindex( $sub, ':' ) + 1 );
    my $r = $self->apache_request;
    if( $r )
    {
        if( @_ )
        {
            $r->path_info( shift( @_ ) );
            $self->_set_env( PATH_INFO => $r->path_info );
            $self->{_uri_reset} = 'path_info' unless( $caller eq "${class}\::document_uri" );
        }
        return( $r->path_info );
    }
    else
    {
        if( @_ )
        {
            $self->{path_info} = shift( @_ );
            $self->_set_env( PATH_INFO => $self->{path_info} );
            $self->{_uri_reset} = 'path_info' unless( $caller eq "${class}\::document_uri" );
        }
        return( $self->{path_info} );
    }
}

sub query_string
{
    my $self = shift( @_ );
    my $class = ref( $self );
    my $caller = (caller(1))[3] // '';
    # my $caller = substr( $sub, rindex( $sub, ':' ) + 1 );
    my $r = $self->apache_request;
    if( $r )
    {
        if( @_ )
        {
            my $qs = shift( @_ );
            $r->args( $qs );
            $self->_set_env( QUERY_STRING => $qs );
            $self->{_uri_reset} = 'query_string' unless( $caller eq "${class}\::document_uri" );
        }
        return( $r->args );
    }
    else
    {
        if( @_ )
        {
            $self->{query_string} = shift( @_ );
            $self->_set_env( QUERY_STRING => $self->{query_string} );
            $self->{_uri_reset} = 'query_string' unless( $caller eq "${class}\::document_uri" );
        }
        return( $self->{query_string} );
    }
}

sub root
{
    my $self = shift( @_ );
    return( $self->{root} ) if( $self->{root} );
    my $hash = 
    {
    code => 200,
    document_uri => $self->new_uri( '/' ),
    document_root => $self->document_root,
    debug => $self->debug,
    path_info => '',
    query_string => '',
    _path_info_processed => 1,
    };
    $hash->{document_path} = $hash->{document_uri};
    $hash->{apache_request} = $self->apache_request if( $self->apache_request );
    my $root = bless( $hash => ref( $self ) );
    # Scalar::Util::weaken( $copy );
    $root->{base_dir} = $root;
    $root->{base_uri} = $root;
    $self->{root} = $root;
    return( $root );
}

# shortcut
sub uri { return( shift->document_uri( @_ ) ); }

# Path info works as a path added to a document uri, such as:
# /my/doc.html/path/info
# But we need to distinguish with missing document hierarchy inside a directory, such as:
# /my/folder/missing_doc.html/path/info
# otherwise we would be treating /missing_doc.html/path/info as a path info
sub _find_path_info
{
    my $self = shift( @_ );
    my( $uri_path, $doc_root ) = @_;
    $doc_root //= $self->document_root;
    my $qs = '';
    my $sep = $DIR_SEP;
    $sep = '/' if( !length( $sep ) );
    if( Scalar::Util::blessed( $uri_path ) && $uri_path->isa( 'URI::file' ) )
    {
        $uri_path = $uri_path->file;
    }
    my $u = $self->collapse_dots( $uri_path );
    $qs = $u->query;
    $uri_path = $u->path;
    # Pass the OS to ensure we get ./ss/include.cgi becomes .\ssi\include.cgi
    my $path = URI::file->new( $uri_path )->file( $^O );
    $doc_root = $doc_root->file( $^O ) if( Scalar::Util::blessed( $doc_root ) && $doc_root->isa( 'URI::file' ) );
    $doc_root = substr( $doc_root, 0, length( $doc_root ) - length( $sep ) ) if( substr( $doc_root, -length( $sep ), length( $sep ) ) eq $sep );
    return( $self->error( "URI path must be an absolute path starting with '/'. Path provided was \"$uri_path\"." ) ) if( substr( $uri_path, 0, 1 ) ne '/' );
    # No need to go further
    if( -e( "${doc_root}${path}" ) )
    {
        return({
            filepath => "${doc_root}${path}",
            path => $uri_path,
            query_string => $qs,
            code => 200,
        });
    }
    elsif( $uri_path eq '/' )
    {
        return({
            filepath => $doc_root,
            path => $uri_path,
            path_info => undef(),
            query_string => $qs,
            code => ( -e( $doc_root ) ? 200 : 404 ),
        });
    }
    my @parts = split( '/', substr( $uri_path, 1 ) );
    my $trypath = '';
    my $trypath_uri = '';
    my $pathinfo = '';
    foreach my $p ( @parts )
    {
        # The last path was a directory, and we cannot find the element within. So, the rest of the path is not path info, but rather a 404 missing document hierarchy
        # We test the $pathinfo string, so we do not bother checking further if it is already set.
        if( !$pathinfo && -d( "${doc_root}${trypath}" ) && !-e( "${doc_root}${trypath}/${p}" ) )
        {
            # We return the original path provided (minus any query string)
            return({
                filepath => $doc_root . ( length( $trypath ) ? $trypath :  $path ),
                path => $uri_path,
                code => 404,
                query_string => $qs,
            });
        }
        elsif( !$pathinfo && -e( "${doc_root}${trypath}/${p}" ) )
        {
            $trypath_uri .= "/${p}";
            $trypath  .= "${sep}${p}";
        }
        else
        {
            $pathinfo .= "/$p";
        }
    }
    return({
        filepath => "${doc_root}${trypath}",
        path => $trypath_uri,
        path_info => $pathinfo,
        code => 200,
        query_string => $qs,
    });
}

# *_set_env = \&Apache2::SSI::_set_env;
# This is different from the env() method. This one is obviously private
# whereas the env() one has triggers that could otherwise create an infinite loop.
sub _set_env
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    return( $self->error( "No environment variable name provided." ) ) if( !length( $name ) );
    $self->{_env} = {} if( !ref( $self->{_env} ) );
    my $env = $self->{_env};
    my $r = $self->apache_request;
    if( @_ )
    {
        my $v = shift( @_ );
        $r->subprocess_env( $name => $v ) if( $r );
        $env->{ $name } = $v;
    }
    return( $self );
}

sub _trim_trailing_slash
{
    my $self = shift( @_ );
    my $uri  = shift( @_ );
    return( $self->error( "No uri provided to trim trailing slash." ) ) if( !length( "$uri" ) );
    unless( Scalar::Util::blessed( $uri ) && $uri->isa( 'URI' ) )
    {
        $uri = $self->new_uri( "$uri" );
    }
    if( substr( $uri->path, -1, 1 ) eq '/' && length( $uri->path ) > 1 )
    {
        # By splitting the string on '/' and without the last argument for split being -1, perl will remove trailing blank entries
        $uri->path( join( '/', split( '/', $uri->path ) ) );
    }
    return( $uri );
}

1;

__END__

=encoding utf-8

=head1 NAME

Apache2::SSI::URI - Apache2 Server Side Include URI Object Class

=head1 SYNOPSIS

    # if the global option PerlOptions +GlobalRequest is set in your VirtualHost
    my $r = Apache2::RequestUtil->request
    my $uri = Apache2::SSI::URI->new(
        apache_request => $r,
        document_uri => '/some/uri/file.html',
        document_root => '/home/john/www',
        base_uri => '/',
    ) || die( "Unable to create an Apache2::SSI::URI object: ", Apache2::SSI::URI->error );

    unless( $uri->code == Apache2::Const::HTTP_OK )
    {
        die( "Sorry, the uri does not exist.\n" );
    }
    print( $uri->slurp_utf8 );

    # Changing the base uri, which is used to resolve relative uri
    $uri->base_uri( '/ssi' );

    my $uri2 = $uri->clone;
    $uri2->filename( '/home/john/some-file.txt' );
    die( "No such file\n" ) if( $uri2->finfo->filetype == Apache2::SSI::Finfo::FILETYPE_NOFILE );

    my $dir = $uri->document_directory;

    # Full path to the filename, e.g. /home/john/www/some/dir/file.html
    # Possible dots are resolved /home/john/www/some/dir/../ssi/../dir/./file.html => /home/john/www/some/dir/file.html
    my $filename = $uri->document_filename;

    # The uri without path info or query string
    my $path = $uri->document_path;

    my $doc_root = $uri->document_root;
    
    # The document uri including path info, and query string if any
    my $u = $uri->document_uri;

    my $req_uri = $uri->env( 'REQUEST_URI' );

    # Access to the Apache2::SSI::Finfo object
    my $finfo = $uri->finfo;

    # A new Apache2::SSI::URI object
    my $uri3 = $uri->new_uri( document_uri => '/some/where/about.html', document_root => '/home/john/www' );

    # Returns /some/uri
    my $parent = $uri->parent;

    # The uri is now /some/uri/file.html/some/path
    $uri->path_info( '/some/path' );

    # The uri is now /some/uri/file.html/some/path?q=something&l=ja_JP
    $uri->query_string( 'q=something&l=ja_JP' );

    my $html = $uri->slurp_utf8;
    my $raw = $uri->slurp({ binmode => ':raw' });

    # Same as $uri->document_uri
    my $uri = $uri->uri;

=head1 VERSION

    v0.1.2

=head1 DESCRIPTION

L<Apache2::SSI::URI> is used to manipulate and query http uri. It is used by L<Apache2::SSI> both for the main query, and also for sub queries like when there is an C<include> directive.

In this case, there would be the main document uri such as C</some/path/file.html> and containing a directive such as:

    <!--#include virtual="../other.html" -->

An L<Apache2::SSI::URI> object would be instantiated to process the uri C<../other.html>, flatten the dots and get its underlying filename.

Even if the uri provided does not exist, am L<Apache2::SSI::URI> object would still be returned, so you need to check if the file exists by doing:

    if( $uri->code == 404 )
    {
        die( "Not there\n" );
    }

Or, this would work too:

    if( $uri->finfo->filetype == Apache2::SSI::Finfo::FILETYPE_NOFILE )
    {
        die( "No such file !\n" );
    }

=head1 METHODS

=head2 new

This instantiate an object that is used to access other key methods. It takes the following parameters:

=over 4

=item I<apache_request>

This is the L<Apache2::RequestRec> object that is provided if running under mod_perl.

it can be retrieved from L<Apache2::RequestUtil/request> or via L<Apache2::Filter/r>

You can get this L<Apache2::RequestRec> object by requiring L<Apache2::RequestUtil> and calling its class method L<Apache2::RequestUtil/request> such as C<Apache2::RequestUtil->request> and assuming you have set C<PerlOptions +GlobalRequest> in your Apache Virtual Host configuration.

Note that there is a main request object and subprocess request object, so to find out which one you are dealing with, use L<Apache2::RequestUtil/is_initial_req>, such as:

    use Apache2::RequestUtil (); # extends Apache2::RequestRec objects
    my $r = $r->is_initial_req ? $r : $r->main;

=item I<base_uri>

This is the base uri which is used to make uri absolute.

For example, if the main document uri is C</some/folder/file.html> containing a directive:

    <!--#include virtual="../other.html" -->

One would instantiate an object using C</some/folder/file.html> as the base_uri like this:

    my $uri = Apache2::SSI::URI->new(
        base_uri => '/some/folder/file.html',
        apache_request => $r,
        document_uri => '../other.html',
        # No need to specify document_root, because it will be derived from 
        # the Apache2::RequestRec provided with the apache_request parameter.
    );

=item I<document_root>

This is only necessary to be provided if this is not running under Apache mod_perl. Without this value, L<Apache2::SSI> has no way to guess the document root and will not be able to function properly and will return an L</error>.

=item I<document_uri>

This is only necessary to be provided if this is not running under Apache mod_perl. This must be the uri of the document being served, such as C</my/path/index.html>. So, if you are using this outside of the rim of Apache mod_perl and your file resides, for example, at C</home/john/www/my/path/index.html> and your document root is C</home/john/www>, then the document uri would be C</my/path/index.html>

=back

=head2 apache_request

Sets or gets the L<Apache2::RequestRec> object. As explained in the L</new> method, you can get this Apache object by requiring the package L<Apache2::RequestUtil> and calling L<Apache2::RequestUtil/request> such as C<Apache2::RequestUtil->request> assuming you have set C<PerlOptions +GlobalRequest> in your Apache Virtual Host configuration.

When running under Apache mod_perl this is set automatically from the special L</handler> method, such as:

    my $r = $f->r; # $f is the Apache2::Filter object provided by Apache

=head2 base_uri

Sets or gets the base reference uri. This is used to render the L</document_uri> provided an absolute uri.

=head2 clone

Create a clone of the object and return it.

=head2 code

Sets or gets the http code for this uri.

    $uri->code( 404 );

=head2 collapse_dots

Provided with an uri, and this will resolve the path and removing the dots, such as C<.> and C<..> and return an L<URI> object.

This is done as per the L<RFC 3986 section 5.2.4 algorithm|https://tools.ietf.org/html/rfc3986#page-33>

    my $uri = $ssi->collapse_dots( '/../a/b/../c/./d.html' );
    # would become /a/c/d.html
    my $uri = $ssi->collapse_dots( '/../a/b/../c/./d.html?foo=../bar' );
    # would become /a/c/d.html?foo=../bar
    $uri->query # foo=../bar

=head2 document_directory

Returns an L<Apache2::SSI::URI> object of the current directory of the L</document_uri> provided.

This can also be called as C<$uri->document_dir>

=head2 document_filename

This is an alias for L<Apache2::SSI::URI/filename>

=head2 document_path

Sets or gets the uri path to the document. This is the same as L</document_uri>, except it is striped from L</query_string> and L</path_info>.

=head2 document_root

Sets or gets the document root.

Wen running under Apache mod_perl, this value will be available automatically, using L<Apache2::RequestRec/document_root> method.

If it runs outside of Apache, this will use the value provided upon instantiating the object and passing the I<document_root> parameter. If this is not set, it will return the value of the environment variable C<DOCUMENT_ROOT>.

=head2 document_uri

Sets or gets the document uri, which is the uri of the document being processed.

For example:

    /index.html

Under Apache, this will get the environment variable C<DOCUMENT_URI> or calls the L<Apache2::RequestRec/uri> method.

Outside of Apache, this will rely on a value being provided upon instantiating an object, or the environment variable C<DOCUMENT_URI> be present.

The value should be an absolute uri.

=head2 env

Sets or gets environment variables that are distinct for this uri.

    $uri->env( REQUEST_URI => '/some/path/file.html' );
    my $loc = $uri->env( 'REQUEST_URI' );

If it is called without any parameters, it returns all the environment variables as a hash reference:

    my $all_env = $uri->env;
    print $all_env->{REQUEST_URI};

Setting an environment variable using L</env> does not actually populate it. So this would not work:

    $uri->env( REQUEST_URI => '/some/path/file.html' );
    print( $ENV{REQUEST_URI};

It is the equivalent of L<Apache2::RequestRec/subprocess_env>. Actually it uses L<Apache2::RequestRec/subprocess_env> if running under Apache/mod_perl, other wise it uses a private hash reference to store the values.

=head2 filename

This returns the system file path to the document uri as a string.

=head2 finfo

Returns a L<Apache2::SSI::Finfo> object. This provides access to L<perlfunc/stat> information as method, taking advantage of L<APR::Finfo> when running under Apache, and an identical interface otherwise. See L<Apache2::SSI::Finfo> for more information.

=head2 new_uri

A short-hand for C<Apache2::SSI::URI->new>

=head2 parent

Returns the parent of the document uri, or if there is no parent, it returns the current object itself.

    my $up = $uri->parent;
    # would return /some/path assuming the document uri was /some/path/file.html

=head2 path_info

Sets or gets the path info for the current uri.

Example:

    my $string = $ssi->path_info;
    $ssi->path_info( '/my/path/info' );

The path info value is also set automatically when L</document_uri> is called, such as:

    $ssi->document_uri( '/some/path/to/file.html/my/path/info?q=something&l=ja_JP' );

This will also set automatically the C<PATH_INFO> environment variable.

=head2 query_string

Set or gets the query string for the current uri.

Example:

    my $string = $ssi->query_string;
    $ssi->query_string( 'q=something&l=ja_JP' );

or, using the L<URI> module:

    $ssi->query_string( $uri->query );

The query string value is set automatically when you provide an L<document_uri> upon instantiation or after:

    $ssi->document_uri( '/some/path/to/file.html?q=something&l=ja_JP' );

This will also set automatically the C<QUERY_STRING> environment variable.

=head2 root

Returns an object representation of the root uri, i.e. C</>

=head2 slurp

It returns the content of the L</filename>

it takes an hash reference of parameters:

=over 4

=item I<binmode>

    my $content = $uri->slurp({ binmode => ':utf-8' });

=back

It will return undef and sets an L<Module::Generic/error> if there is no L</filename> value set or if the file cannot be opened.

=head2 slurp_utf8

It returns the content of the file L</filename> utf-8 decoded.

This is equivalent to:

    my $content = $uri->slurp({ binmode => ':utf8' });

C<:utf8> is slightly a bit more lax than C<:utf-8>, so it you want strict utf8, you can do:

    my $content = $uri->slurp({ binmode => ':utf-8' });

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

L<https://gitlab.com/jackdeguest/Apache2-SSI>

=head1 SEE ALSO

L<Apache2::SSI::File>, L<Apache2::SSI::Finfo>, L<Apache2::SSI>

mod_include, mod_perl(3), L<APR::URI>, L<URI>
L<https://httpd.apache.org/docs/current/en/mod/mod_include.html>,
L<https://httpd.apache.org/docs/current/en/howto/ssi.html>,
L<https://httpd.apache.org/docs/current/en/expr.html>
L<https://perl.apache.org/docs/2.0/user/handlers/filters.html#C_PerlOutputFilterHandler_>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
