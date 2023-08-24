##----------------------------------------------------------------------------
## Changes file management - ~/lib/Changes.pm
## Version v0.3.2
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/12/09
## Modified 2023/08/20
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Changes;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $VERSION_LAX_REGEX $DATE_DISTZILA_RE $DATETIME_RE );
    use Changes::Release;
    use Changes::Group;
    use Changes::Change;
    use Nice::Try;
    # From version::regex
    our $VERSION_LAX_REGEX = qr/(?^x: (?^x:
        (?<has_v>v) (?<ver>(?^:[0-9]+) (?: (?^:\.[0-9]+)+ (?^:_[0-9]+)? )?)
        |
        (?<ver>(?^:[0-9]+)? (?^:\.[0-9]+){2,} (?^:_[0-9]+)?)
    ) | (?^x: (?<ver>(?^:[0-9]+) (?: (?^:\.[0-9]+) | \. )? (?^:_[0-9]+)?)
        |
        (?<ver>(?^:\.[0-9]+) (?^:_[0-9]+)?)
        )
    )/;
    # 2022-12-11 08:07:12 Asia/Tokyo
    our $DATE_DISTZILA_RE = qr/
    (?<r_year>\d{4})
    -
    (?<r_month>\d{1,2})
    -
    (?<r_day>\d{1,2})
    (?<r_dt_space>[[:blank:]\h]+)
    (?<r_hour>\d{1,2})
    :
    (?<r_minute>\d{1,2})
    :
    (?<r_second>\d{1,2})
    (?<r_tz_space>[[:blank:]\h]+)
    (?<r_tz>\S+)
    /x;
    our $VERSION = 'v0.3.2';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{defaults}   = undef;
    $self->{elements}   = [];
    $self->{epilogue}   = undef;
    $self->{file}       = undef;
    $self->{max_width}  = 0;
    $self->{mode}       = '+<';
    $self->{nl}         = "\n";
    $self->{preamble}   = undef;
    $self->{releases}   = [];
    $self->{time_zone}  = undef;
    $self->{type}       = undef;
    $self->{wrapper}    = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->{_init_params_order} = [qw( preset )];
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub add_epilogue
{
    my( $self, $text ) = @_;
    if( !defined( $text ) || !length( "$text" ) )
    {
        return( $self->error( "No text was provided to add an epilogue." ) );
    }
    my $elements = $self->elements;
    my $last = $elements->last;
    if( defined( $last ) && !$self->_is_a( $last => 'Changes::NewLine' ) )
    {
        $elements->push( $self->new_line( nl => ( $self->nl // "\n" ) ) );
    }
    $self->epilogue( $text );
    return( $self );
}

sub add_preamble
{
    my( $self, $text ) = @_;
    if( !defined( $text ) || !length( "$text" ) )
    {
        return( $self->error( "No text was provided to add a premable." ) );
    }
    $self->preamble( $text );
    return( $self );
}

sub add_release
{
    my $self = shift( @_ );
    my( $rel, $opts );
    my $elements = $self->elements;
    if( scalar( @_ ) == 1 && $self->_is_a( $_[0] => 'Changes::Release' ) )
    {
        $rel = shift( @_ );
        if( $elements->exists( $rel ) )
        {
            return( $self->error( "A very same release object with version '", $rel->version, "' is already registered." ) );
        }
        my $vers = $rel->version;
        if( length( "$vers" ) )
        {
            my $same = $elements->grep(sub{ $self->_is_a( $_ => 'Changes::Release' ) && $_->version == "$vers" });
            return( $self->error( "A similar release with version '$vers' is already registered." ) ) if( !$same->is_empty );
        }
    }
    else
    {
        $opts = $self->_get_args_as_hash( @_ );
        if( exists( $opts->{version} ) && defined( $opts->{version} ) && length( "$opts->{version}" ) )
        {
            my $vers = $opts->{version};
            my $same = $elements->grep(sub{ $self->_is_a( $_ => 'Changes::Release' ) && $_->version == "$vers" });
            return( $self->error( "A similar release with version '$vers' is already registered." ) ) if( !$same->is_empty );
        }
        $rel = $self->new_release( %$opts ) || return( $self->pass_error );
        return( $self->add_release( $rel ) );
    }
    $elements->unshift( $self->new_line );
    $elements->unshift( $rel );
    return( $rel );
}

sub as_string
{
    my $self = shift( @_ );
    my $lines = $self->new_array;
    my $preamble = $self->preamble;
    my $epilogue = $self->epilogue;
    if( defined( $preamble ) && !$preamble->is_empty )
    {
        $lines->push( $preamble->scalar );
    }
    
    $self->elements->foreach(sub
    {
        my $str;
        $str = $_->as_string if( $self->_can( $_ => 'as_string' ) );
        if( defined( $str ) )
        {
            $lines->push( $str->scalar );
        }
    });
    if( defined( $epilogue ) && !$epilogue->is_empty )
    {
        $lines->push( $epilogue->scalar );
    }
    return( $lines->join( '' ) );
}

{
    no warnings 'once';
    *serialize = \&as_string;
    *serialise = \&as_string;
}

sub defaults { return( shift->_set_get_hash_as_mix_object( { field => 'defaults', undef_ok => 1 }, @_ ) ); }

sub delete_release
{
    my $self = shift( @_ );
    my $elements = $self->elements;
    my $removed = $self->new_array;
    foreach my $rel ( @_ )
    {
        if( $self->_is_a( $rel => 'Changes::Release' ) )
        {
            my $pos = $elements->pos( $rel );
            my $until = 1;
            while( defined( $elements->[ $pos + $until ] ) && $self->_is_a( $elements->[ $pos + $until ] => 'Changes::NewLine' ) )
            {
                $until++;
            }
            $elements->delete( $pos, $until );
            $removed->push( $rel );
        }
        else
        {
            my $vers = $rel;
            if( !defined( $vers ) || !length( "$vers" ) )
            {
                warn( "No version provided to remove its corresponding release object.\n" ) if( $self->_warnings_is_enabled );
                next;
            }
            my $found = $elements->grep(sub{ $self->_is_a( $_ => 'Changes::Release' ) && $_->version == $vers });
            if( $found->is_empty )
            {
                next;
            }
            $found->foreach(sub
            {
                my $deleted = $self->delete_release( $_ );
                $removed->push( $deleted->list ) if( !$deleted->is_empty );
            });
        }
    }
    return( $removed );
}

sub elements { return( shift->_set_get_array_as_object( 'elements', @_ ) ); }

sub epilogue { return( shift->_set_get_scalar_as_object( 'epilogue', @_ ) ); }

sub file { return( shift->_set_get_file( 'file', @_ ) ); }

sub freeze
{
    my $self = shift( @_ );
    $self->elements->foreach(sub
    {
        if( $self->_can( $_ => 'freeze' ) )
        {
            $_->freeze;
        }
    });
    return( $self );
}

sub history { return( shift->releases( @_ ) ); }

sub load
{
    my $this = shift( @_ );
    my $file = shift( @_ ) ||
        return( $this->error( "No changes file was provided to load." ) );
    my $opts = $this->_get_args_as_hash( @_ );
    my $self = $this->new( %$opts ) ||
        return( $this->pass_error );
    my $f = $self->new_file( $file ) ||
        return( $this->pass_error( $self->error ) );
    my $mode = $self->mode // '+<';
    $f->open( "$mode", { binmode => 'utf-8', autoflush => 1 } ) ||
        return( $this->pass_error( $f->error ) );
    # my $lines = $f->lines( chomp => 1 ) ||
    my $lines = $f->lines ||
        return( $this->pass_error( $f->error ) );
    $self->parse( $lines ) || return( $self->pass_error );
    $self->freeze;
    return( $self );
}

sub load_data
{
    my $this = shift( @_ );
    my $data = shift( @_ );
    my $opts = $this->_get_args_as_hash( @_ );
    my $self = $this->new( %$opts ) ||
        return( $this->pass_error );
    return( $self ) if( !defined( $data ) || !length( "$data" ) );
    my $lines = $self->new_array( [split( /(?<=\n)/, $data )] );
    # $lines->chomp;
    $self->parse( $lines ) || return( $self->pass_error );
    $self->freeze;
    return( $self );
}

sub max_width { return( shift->_set_get_number( 'max_width', @_ ) ); }

sub new_change
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $defaults = $self->defaults;
    if( defined( $defaults ) )
    {
        foreach my $opt ( qw( spacer1 marker spacer2 ) )
        {
            $opts->{ $opt } //= $defaults->{ $opt } if( defined( $defaults->{ $opt } ) );
        }
    }
    my $c = Changes::Change->new( $opts ) ||
        return( $self->pass_error( Changes::Change->error ) );
    return( $c );
}

sub new_group
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $defaults = $self->defaults;
    if( defined( $defaults ) )
    {
        my $def = { %$defaults };
        foreach my $opt ( qw( spacer type ) )
        {
            if( !defined( $opts->{ "group_${opt}" } ) && 
                exists( $def->{ "group_${opt}" } ) && 
                defined( $def->{ "group_${opt}" } ) && 
                length( $def->{ "group_${opt}" } ) )
            {
                $opts->{ $opt } = CORE::delete( $def->{ "group_${opt}" } );
            }
        }
        $opts->{defaults} //= $def;
    }
    my $g = Changes::Group->new( $opts ) ||
        return( $self->pass_error( Changes::Group->error ) );
    return( $g );
}

sub new_line
{
    my $self = shift( @_ );
    $self->_load_class( 'Changes::NewLine' ) || return( $self->pass_error );
    my $nl = Changes::NewLine->new( @_ ) ||
        return( $self->pass_error( Changes::NewLine->error ) );
    return( $nl );
}

sub new_release
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $defaults = $self->defaults;
    if( defined( $defaults ) )
    {
        my $def = { %$defaults };
        foreach my $opt ( qw( datetime_formatter format spacer time_zone ) )
        {
            if( !defined( $opts->{ $opt } ) && 
                exists( $def->{ $opt } ) && 
                defined( $def->{ $opt } ) && 
                length( $def->{ $opt } ) )
            {
                $opts->{ $opt } = CORE::delete( $def->{ $opt } );
            }
        }
        $opts->{defaults} //= $def;
    }
    my $rel = Changes::Release->new( $opts ) ||
        return( $self->pass_error( Changes::Release->error ) );
    return( $rel );
}

sub new_version
{
    my $self = shift( @_ );
    $self->_load_class( 'Changes::Version' ) || return( $self->pass_error );
    my $v = Changes::Version->new( @_ ) ||
        return( $self->pass_error( Changes::Version->error ) );
    return( $v );
}

sub nl { return( shift->_set_get_scalar_as_object( 'nl', @_ ) ); }

sub parse
{
    my $self = shift( @_ );
    my $lines = shift( @_ ) || return( $self->error( "No array reference of lines was provided." ) );
    return( $self->error( "Data provided is not an array reference of lines." ) ) if( !$self->_is_array( $lines ) );
    $lines = $self->new_array( $lines );
    my $preamble = $self->new_scalar;
    my $epilogue;
    my $elements = $self->new_array;
    # Temporary array buffer of new lines found that we store here until we read more of the context in the Changes file and we decide what to do with them.
    my $nls = $self->new_array;
    my $max_width = $self->max_width // 0;
    my $debug = $self->debug;
    my( $group, $release, $change );
    # $type is the Changes file type. It contains the value guessed, otherwise it remains undef
    my $type = $self->type;
    my $wrapper = $self->wrapper;
    my $tz = $self->time_zone;
    my $defaults = $self->defaults;
    # Cache it
    unless( defined( $DATETIME_RE ) )
    {
        $DATETIME_RE = $self->_get_datetime_regexp( 'all' );
    }
    for( my $i = 0; $i < scalar( @$lines ); $i++ )
    {
        my $l = $lines->[$i];
        # DistZilla release line
        # 0.01 2022-12-11 08:07:12 Asia/Tokyo
        if( $l =~ /^
            [[:blank:]\h]*
            (?<r_vers>$VERSION_LAX_REGEX)
            (?<v_space>[[:blank:]\h][[:blank:]\h\W]*)
            (?<r_datetime>$DATE_DISTZILA_RE)
            [[:blank:]\h]*
            (?<r_nl>[\015\012]+)?$
            /msx )
        {
            my $re = { %+ };
            # Create the DateTime object
            $self->_load_class( 'DateTime' ) || return( $self->pass_error );
            $self->_load_class( 'DateTime::TimeZone' ) || return( $self->pass_error );
            $self->_load_class( 'DateTime::Format::Strptime' ) || return( $self->pass_error );
            my( $dt, $tz, $fmt );
            try
            {
                $tz = DateTime::TimeZone->new( name => $re->{r_tz} );
            }
            catch( $e where { /The[[:blank:]\h]+timezone[[:blank:]\h]+'(?:.*?)'[[:blank:]\h]+could[[:blank:]\h]+not[[:blank:]\h]+be[[:blank:]\h]+loaded/i } )
            {
                warn( "Warning only: invalid time zone '$re->{r_tz}' specified in release at line ", ( $i + 1 ), "\n" ) if( $self->_warnings_is_enabled );
                $tz = DateTime::TimeZone->new( name => 'UTC' );
            }
            catch( $e )
            {
                warn( "Warning only: error trying to instantiate a new DateTime::TimeZone object with time zone '$re->{r_tz}': $e\n" ) if( $self->_warnings_is_enabled );
                $tz = DateTime::TimeZone->new( name => 'UTC' );
            }
            
            
            try
            {
                $fmt = DateTime::Format::Strptime->new(
                    pattern => "%F$re->{r_dt_space}%T$re->{r_tz_space}%O",
                );
            }
            catch( $e )
            {
                warn( "Error only: failed to create a DateTime::Format::Strptime with pattern '%F$re->{r_dt_space}%T$re->{r_tz_space}%Z': $e\n" ) if( $self->_warnings_is_enabled );
                $fmt = DateTime::Format::Strptime->new(
                    pattern => "%F %T %O",
                );
            }
            
            try
            {
                $dt = DateTime->new(
                    year => $re->{r_year},
                    month => $re->{r_month},
                    day => $re->{r_day},
                    hour => $re->{r_hour},
                    minute => $re->{r_minute},
                    second => $re->{r_second},
                    time_zone => $tz,
                );
                $dt->set_formatter( $fmt );
            }
            catch( $e )
            {
                warn( "Warning only: error trying to instantiate a DateTime value based on the date and time of the release at line ", ( $i + 1 ), ": $e\n" ) if( $self->_warnings_is_enabled );
                $dt = DateTime->now( time_zone => $tz );
            }
            
            if( !$nls->is_empty )
            {
                $elements->push( $nls->list );
                $nls->reset;
            }
            undef( $group );
            $release = $self->new_release(
                version => $re->{r_vers},
                datetime => $dt,
                spacer => $re->{v_space},
                ( defined( $re->{r_note} ) ? ( note => $re->{r_note} ) : () ),
                raw => $l,
                line => ( $i + 1 ),
                container => $self,
                # Could be undef if this is the last line with no trailing crlf
                nl => $re->{r_nl},
                ( defined( $tz ) ? ( time_zone => $tz ) : () ),
                ( defined( $defaults ) ? ( defaults => $defaults ) : () ),
                debug => $debug,
            );
            $elements->push( $release );
            if( defined( $preamble ) && !$preamble->is_empty )
            {
                $self->preamble( $preamble );
                undef( $preamble );
            }
            unless( defined( $type ) )
            {
                $type = 'distzilla';
                $self->type( $type );
            }
        }
        # Release line
        # v0.1.0 2022-11-17T08:12:31+0900
        # 0.01 - 2022-11-17
        elsif( $l =~ /^
            [[:blank:]\h]*
            (?<r_vers>$VERSION_LAX_REGEX)
            (?<v_space>[[:blank:]\h][[:blank:]\h\W]*)
            (?<r_date>$DATETIME_RE)
            (?:
                (?<d_space>[[:blank:]\h]+)
                (?<r_note>.+?))?(?<r_nl>[\015\012]+)?
            $/msx ) 
        {
            my $re = { %+ };
            my $dt = $self->_parse_timestamp( $re->{r_date} ) ||
                return( $self->pass_error( "Cannot parse datetime timestamp although the regular expression matched: ", $self->error->message ) );
            if( !$nls->is_empty )
            {
                $elements->push( $nls->list );
                $nls->reset;
            }
            undef( $group );
            $release = $self->new_release(
                version => $re->{r_vers},
                # datetime => $re->{r_date},
                datetime => $dt,
                spacer => $re->{v_space},
                ( defined( $re->{r_note} ) ? ( note => $re->{r_note} ) : () ),
                raw => $l,
                line => ( $i + 1 ),
                container => $self,
                # Could be undef if this is the last line with no trailing crlf
                nl => $re->{r_nl},
                ( defined( $tz ) ? ( time_zone => $tz ) : () ),
                ( defined( $defaults ) ? ( defaults => $defaults ) : () ),
                debug => $debug,
            );
            $elements->push( $release );
            if( defined( $preamble ) && !$preamble->is_empty )
            {
                $self->preamble( $preamble );
                undef( $preamble );
            }
        }
        elsif( $l =~ /^
            [[:blank:]\h]*
            (?<r_vers>$VERSION_LAX_REGEX)
            (?:
                (?<v_space>[[:blank:]\h][[:blank:]\h\W]*)
                (?<r_note>[^\015\012]*)
            )?
            (?<r_nl>[\015\012]+)?
            /msx )
        {
            my $re = { %+ };
            if( !$nls->is_empty )
            {
                $elements->push( $nls->list );
                $nls->reset;
            }
            undef( $group );
            $release = $self->new_release(
                version => $re->{r_vers},
                spacer => $re->{v_space},
                ( defined( $re->{r_note} ) ? ( note => $re->{r_note} ) : () ),
                raw => $l,
                line => ( $i + 1 ),
                container => $self,
                # Could be undef if this is the last line with no trailing crlf
                nl => $re->{r_nl},
                ( defined( $tz ) ? ( time_zone => $tz ) : () ),
                ( defined( $defaults ) ? ( defaults => $defaults ) : () ),
                debug => $debug,
            );
            $elements->push( $release );
            if( defined( $preamble ) && !$preamble->is_empty )
            {
                $self->preamble( $preamble );
                undef( $preamble );
            }
        }
        # Group line
        elsif( $l =~ /^(?<g_space>[[:blank:]\h]+)(?<data>(?:\[(?<g_name>[^\]]+)\]|(?<g_name_colon>\w[^\:]+)\:))[[:blank:]\h]*(?<g_nl>[\015\012]+)?$/ms )
        {
            my $re = { %+ };
            # Depending on where we are we treat this either as a group, or as a mere comment of a release change
            # 1) This is a continuity of the previous change line
            #    We assert this by checking if the space before is longer than the prefix of the change, which would imply an indentation that would put it below the change, and thus not a group
            if( defined( $change ) && length( $re->{g_space} // '' ) > $change->prefix->length )
            {
                $change->text->append( $re->{data} );
                # Since this is a wrapped line, we remove any excessive leading spaces and replace them by just one space
                $l =~ s/^[[:blank:]\h]+/ /g;
                $change->raw->push( $l );
            }
            else
            {
                # A group is above a change, so if we already have an ongoing change object, we stop using it
                undef( $change );
                $group = $self->new_group(
                    name => ( $re->{g_name} // $re->{g_name_colon} ),
                    spacer => $re->{g_space},
                    raw => $l,
                    line => ( $i + 1 ),
                    type => ( defined( $re->{g_name_colon} ) ? 'colon' : 'bracket' ),
                    # Could be undef if this is the last line with no trailing crlf
                    nl => $re->{g_nl},
                    ( defined( $defaults ) ? ( defaults => $defaults ) : () ),
                    debug => $debug,
                );
                if( !defined( $release ) )
                {
                    warn( "Found a group token outside of a release information at line ", ( $i + 1 ), "\n" ) if( $self->_warnings_is_enabled );
                    if( !$nls->is_empty )
                    {
                        $elements->push( $nls->list );
                        $nls->reset;
                    }
                    $elements->push( $group );
                }
                else
                {
                    if( !$nls->is_empty )
                    {
                        $release->elements->push( $nls->list );
                        $nls->reset;
                    }
                    $release->elements->push( $group );
                }
            }
        }
        # Change line
        elsif( defined( $release ) && 
               $l =~ /^(?<c_space1>[[:blank:]\h]*)(?<marker>(?:[^\w[:blank:]\h]|[\_\x{30FC}]))(?<c_space2>[[:blank:]\h]+)(?<c_text>.+?)(?<c_nl>[\015\012]+)?$/ms )
        {
            my $re = { %+ };
            $change = $self->new_change(
                ( defined( $re->{c_space1} ) ? ( spacer1 => $re->{c_space1} ) : () ),
                ( defined( $re->{c_space2} ) ? ( spacer2 => $re->{c_space2} ) : () ),
                marker => $re->{marker},
                max_width => $max_width,
                ( defined( $re->{c_text} ) ? ( text => $re->{c_text} ) : () ),
                # Could be undef if this is the last line with no trailing crlf
                nl => $re->{c_nl},
                # raw => "$l\n",
                raw => $l,
                ( defined( $wrapper ) ? ( wrapper => $wrapper ) : () ),
                line => ( $i + 1 ),
                debug => $debug,
            ) || return( $self->pass_error );
            
            if( defined( $group ) )
            {
                if( !$nls->is_empty )
                {
                    $group->elements->push( $nls->list );
                    $nls->reset;
                }
                $group->elements->push( $change );
            }
            elsif( defined( $release ) )
            {
                if( !$nls->is_empty )
                {
                    $release->elements->push( $nls->list );
                    $nls->reset;
                }
                $release->elements->push( $change );
            }
            else
            {
                warn( "Found a change token outside of a release information at line ", ( $i + 1 ), "\n" ) if( $self->_warnings_is_enabled );
                if( !$nls->is_empty )
                {
                    $elements->push( $nls->list );
                    $nls->reset;
                }
                $elements->push( $change );
            }
        }
        # Some previous line continuity
        elsif( $l =~ /^(?<space>[[:blank:]\h]+)(?<data>\S+.*?)(?<c_nl>[\015\012]+)?$/ms )
        {
            my $re = { %+ };
            # We have an ongoing change, so this is likely a wrapped line. We append the text
            if( defined( $change ) )
            {
                $change->text->append( ( $change->nl // $self->nl ) . ( $re->{space} . $re->{data} ) );
                # Which might be undef if, for example, this is the last line and there is no trailing crlf
                $change->nl( $re->{c_nl} );
                $change->raw->append( $l );
            }
            # Ok, then some weirdly formatted change text
            else
            {
                $change = $self->new_change(
                    ( defined( $re->{c_space1} ) ? ( spacer1 => $re->{c_space1} ) : () ),
                    ( defined( $re->{c_space2} ) ? ( spacer2 => $re->{c_space2} ) : () ),
                    marker => $re->{marker},
                    max_width => $max_width,
                    ( defined( $re->{c_text} ) ? ( text => $re->{c_text} ) : () ),
                    nl => $re->{c_nl},
                    # raw => "$l\n",
                    raw => $l,
                    line => ( $i + 1 ),
                    debug => $debug,
                ) || return( $self->pass_error );
                if( defined( $group ) )
                {
                    if( !$nls->is_empty )
                    {
                        $group->elements->push( $nls->list );
                        $nls->reset;
                    }
                    $group->elements->push( $change );
                }
                elsif( defined( $release ) )
                {
                    if( !$nls->is_empty )
                    {
                        $release->elements->push( $nls->list );
                        $nls->reset;
                    }
                    $release->elements->push( $change );
                }
            }
        }
        # Blank line
        elsif( $l =~ /^(?<space>[[:blank:]\h]*)(?<nl>[\015\012]+)?$/ )
        {
            my $re = { %+ };
            # If we are still in the preamble, this might just be a multi lines preamble
            if( $elements->is_empty )
            {
                # $preamble->append( "$l\n" );
                $preamble->append( $l );
            }
            # Otherwise, this is a blank line, which separates elements
            elsif( defined( $release ) )
            {
                undef( $change );
                undef( $group );
                # We do not undef the latest release object, because we could have blank lines inside a release section
                # $release->changes->push( $self->new_line );
                $nls->push( $self->new_line(
                    line => ( $i + 1 ),
                    (
                        ( defined( $re->{nl} ) && defined( $re->{space} ) )
                            ? ( nl => ( $re->{space} // '' ) . ( $re->{nl} // '' ) )
                            : ( nl => undef )
                    ),
                    raw => $l,
                    debug => $debug
                ));
            }
            else
            {
                warn( "I found an empty line outside a release and no release object to associate it to.\n" ) if( $self->_warnings_is_enabled );
                # $releases->push( $self->new_line );
                $nls->push( $self->new_line( raw => $l, debug => $debug ) );
            }
        }
        # Preamble
        elsif( $elements->is_empty )
        {
            $preamble->append( $l );
        }
        # Epilogue
        # We found a line with no leading space with new blank lines before it and no epilogue yet, or maybe no blank lines, but with epilogue already set.
        elsif( $l =~ /^(\S+.*?)(?<nl>[\015\012]+)?$/ms && 
               (
                   ( !$nls->is_empty && !defined( $epilogue ) ) ||
                   ( defined( $epilogue ) && !defined( $release ) && !defined( $group ) && !defined( $change ) )
               ) &&
               # If elements are empty this would rather be part of the preamble
               !$elements->is_empty )
        {
            my $re = { %+ };
            if( !$nls->is_empty )
            {
                $elements->push( $nls->list );
                $nls->reset;
                undef( $release );
                undef( $change );
                undef( $group );
                $epilogue = $self->new_scalar( $l );
                $self->epilogue( $epilogue );
            }
            else
            {
                $epilogue->append( $l );
            }
        }
        else
        {
            chomp( $l );
            warn( "Found an unrecognisable line: '$l'\n" ) if( $self->_warnings_is_enabled );
        }
    }
    $self->elements( $elements );
    return( $self );
}

sub preamble { return( shift->_set_get_scalar_as_object( { field => 'preamble', callbacks => 
{
    set => sub
    {
        my( $self, $text ) = @_;
        if( defined( $text ) && $text->defined )
        {
            unless( $text =~ /[\015\012]$/ms )
            {
                $text->append( $self->nl // "\n" );
            }
            unless( $text =~ /[\015\012]{2,}$/ms )
            {
                $text->append( $self->nl // "\n" );
            }
        }
        return( $text );
   },
} }, @_ ) ); }

sub preset
{
    my $self = shift( @_ );
    my $set  = shift( @_ ) || return( $self->error( "No set name was provided." ) );
    my $sets =
    {
        standard =>
        {
            # for Changes::Release
            datetime_formatter => sub
            {
                my $dt = shift( @_ ) || DateTime->now;
                require DateTime::Format::Strptime;
                my $fmt = DateTime::Format::Strptime->new(
                    pattern => '%FT%T%z',
                    locale => 'en_GB',
                );
                $dt->set_formatter( $fmt );
                my $tz = $self->time_zone;
                $dt->set_time_zone( $tz ) if( $tz );
                return( $dt );
            },
            # No need to provide it if it is just a space though, because it will default to it anyway
            spacer => ' ',
            # for Changes::Change
            spacer1 => "\t",
            spacer2 => ' ',
            marker => '-',
            max_width => 72,
            # wrapper => $code_reference,
            # for Changes::Group
            group_spacer => "\t",
            group_type => 'bracket', # [Some group]
        }
    };
    return( $self->error( "Set requested ($set) is not supported." ) ) if( !exists( $sets->{ $set } ) );
    my $def = $sets->{ $set };
    $self->defaults( $def );
    return( $self );
}

sub releases
{
    my $self = shift( @_ );
    my $a = $self->elements->grep(sub{ $self->_is_a( $_ => 'Changes::Release' ) });
    return( $a );
}

sub remove_release { return( shift->delete_release( @_ ) ); }

sub reset
{
    my $self = shift( @_ );
    if( (
            !exists( $self->{_reset} ) ||
            !defined( $self->{_reset} ) ||
            !CORE::length( $self->{_reset} ) 
        ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
        $self->{_reset_normalise} = 1;
    }
    return( $self );
}

sub time_zone
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        if( $self->_is_a( $v => 'DateTime::TimeZone' ) )
        {
            $self->{time_zone} = $v;
        }
        else
        {
            try
            {
                $self->_load_class( 'DateTime::TimeZone' ) || return( $self->pass_error );
                my $tz = DateTime::TimeZone->new( name => "$v" );
                $self->{time_zone} = $tz;
            }
            catch( $e )
            {
                return( $self->error( "Error setting time zone for '$v': $e" ) );
            }
        }
        # $self->reset(1);
    }
    if( !defined( $self->{time_zone} ) )
    {
        if( Want::want( 'OBJECT' ) )
        {
            require Module::Generic::Null;
            rreturn( Module::Generic::Null->new( wants => 'OBJECT' ) );
        }
        else
        {
            return;
        }
    }
    else
    {
        return( $self->{time_zone} );
    }
}

sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }

sub wrapper { return( shift->_set_get_code( 'wrapper', @_ ) ); }

sub write
{
    my $self = shift( @_ );
    my $f = $self->file ||
        return( $self->error( "No Changes file has been set to write to." ) );
    my $str = $self->as_string;
    return( $self->pass_error ) if( !defined( $str ) );
    if( $str->is_empty )
    {
        warn( "Warning only: nothing to write to change file $f\n" ) if( $self->_warnings_is_enabled );
        return( $self );
    }
    my $fh = $f->open( '>', { binmode => 'utf-8', autoflush => 1 } ) ||
        return( $self->pass_error( $f->error ) );
    $fh->print( $str->scalar ) || return( $self->pass_error( $fh->error ) );
    $fh->close;
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Changes - Changes file management

=head1 SYMOPSIS

    use Changes;
    my $c = Changes->load( '/some/where/Changes',
    {
    file => '/some/where/else/CHANGES',
    max_width => 78,
    type => 'cpan',
    debug => 4,
    }) || die( Changes->error );
    say "Found ", $c->releases->length, " releases.";
    my $rel = $c->add_release(
        version => 'v0.1.1',
        # Accepts relative time
        datetime => '+1D',
        note => 'CPAN update',
    ) || die( $c->error );
    $rel->changes->push( $c->new_change(
        text => 'Minor corrections in unit tests',
    ) ) || die( $rel->error );
    # or
    my $change = $rel->add_change( text => 'Minor corrections in unit tests' );
    $rel->delete_change( $change );
    my $array_object = $c->delete_release( $rel ) ||
        die( $c->error );
    say sprintf( "%d releases removed.", $array_object->length );
    # or $c->remove_release( $rel );
    # Writing to /some/where/else/CHANGES even though we read from /some/where/Changes
    $c->write || die( $c->error );

=head1 VERSION

    v0.3.2

=head1 DESCRIPTION

This module is designed to read and update C<Changes> files that are provided as part of change management in software distribution.

It is not limited to CPAN, and is versatile and flexible giving you a lot of control.

Its distinctive value compared to other modules that handle C<Changes> file is that it does not attempt to reformat release and change information if they have not been modified. This ensure not just speed, but also that existing formatting of C<Changes> file remain unchanged. You can force reformatting of any release section by calling L<Changes::Release/reset>

This module does not L<perlfunc/die> upon error, but instead returns an L<error object|Module::Generic/error>, so you need to check for the return value when you call any methods in this package distribution.

=head1 CONSTRUCTOR

=head2 new

Provided with an optional hash or hash reference of properties-values pairs, and this will instantiate a new L<Changes> object and return it.

Supported properties are the same as the methods listed below.

If an error occurs, this will return an L<error|Module::Generic/error>

=head2 load

Provided with a file path, and an optional hash or hash reference of parameters, and this will parse the C<Changes> file and return a new object. Thus, this method can be called either using an existing object, or as a class function:

    my $c2 = $c->load( '/some/where/Changes' ) ||
        die( $c->error );
    # or
    my $c = Changes->load( '/some/where/Changes' ) ||
        die( Changes->error );

=head2 load_data

Provided with some string and an optional hash or hash reference of parameters and this will parse the C<Changes> file data and return a new object. Thus, this method can be called either using an existing object, or as a class function:

    my $c2 = $c->load_data( $changes_data ) ||
        die( $c->error );
    # or
    my $c = Change->load_data( $changes_data ) ||
        die( Changes->error );

=head1 METHODS

=head2 add_epilogue

Provided with a text and this will set it as the Changes file epilogue, i.e. an optional text that will appear at the end of the Changes file.

If the last element is not a blank line to separate the epilogue from the last release information, then it will be added as necessary.

It returns the current object upon success, or an L<error|Module::Generic/error> upon error.

=head2 add_preamble

Provided with a text and this will set it as the Changes file preamble.

If the text does not have 2 blank new lines at the end, those will be added in order to separate the preamble from the first release line.

It returns the current object upon success, or an L<error|Module::Generic/error> upon error.

=head2 add_release

This takes either an L<Changes::Release> or an hash or hash reference of options required to create one (for that refer to the L<Changes::Release> class), and returns the newly added release object.

The new release object will be added on top of the elements stack with a blank new line separating it from the other releases.

If the same object is found, or an object with the same version number is found, an error is returned, otherwise it returns the release object thus added.

=head2 as_string

Returns a L<string object|Module::Generic::Scalar> representing the entire C<Changes> file. It does so by getting the value set with L<preamble>, and by calling C<as_string> on each element stored in L</elements>. Those elements can be L<Changes::Release> and L<Changes::Group> and possibly L<Changes::Change> object.

If an error occurred, it returns an L<error|Module::Generic/error>

The result of this method is cached so that the second time it is called, the cache is used unless there has been any change.

=head2 defaults

Sets or gets an hash of default values for the L<Changes::Release> or L<Changes::Change> object when it is instantiated upon parsing with L</parse> or by the C<new_release> or C<new_change> method found in L<Changes>, L<Changes::Release> and L<Changes::Group>

Default is C<undef>, which means no default value is set.

    my $ch = Changes->new(
        file => '/some/where/Changes',
        defaults => {
            # for Changes::Release
            datetime_formatter => sub
            {
                my $dt = shift( @_ ) || DateTime->now;
                require DateTime::Format::Strptime;
                my $fmt = DateTime::Format::Strptime->new(
                    pattern => '%FT%T%z',
                    locale => 'en_GB',
                );
                $dt->set_formatter( $fmt );
                $dt->set_time_zone( 'Asia/Tokyo' );
                return( $dt );
            },
            # No need to provide it if it is just a space though, because it will default to it anyway
            spacer => ' ',
            # Not necessary if the custom datetime formatter has already set it
            time_zone => 'Asia/Tokyo',
            # for Changes::Change
            spacer1 => "\t",
            spacer2 => ' ',
            marker => '-',
            max_width => 72,
            wrapper => $code_reference,
            # for Changes::Group
            group_spacer => "\t",
            group_type => 'bracket', # [Some group]
        }
    );

=head2 delete_release

This takes a list of release to remove and returns an L<array object|Module::Generic::Array> of those releases thus removed.

A release provided can either be a L<Changes::Release> object, or a version string.

When removing a release object, it will also take care of removing following blank new lines that typically separate a release from the rest.

If an error occurred, this will return an L<error|Module::Generic/error>

=head2 elements

Sets or gets an L<array object|Module::Generic::Array> of all the elements within the C<Changes> file. Those elements can be L<Changes::Release>, L<Changes::Group>, L<Changes::Change> and C<Changes::NewLine> objects.

=head2 epilogue

Sets or gets the text of the epilogue. An epilogue is a chunk of text, possibly multi line, that appears at the bottom of the Changes file after the last release information, separated by a blank line.

=head2 file

    my $file = $c->file;
    $c->file( '/some/where/Changes' );

Sets or gets the file path of the Changes file. This returns a L<file object|Module::Generic::File>

=for Pod::Coverage freeze

=head2 history

This is an alias for L</releases> and returns an L<array object|Module::Generic::Array> of L<Changes::Release> objects.

=head2 max_width

Sets or gets the maximum line width for a change inside a release. The line width includes an spaces at the beginning of the line and not just the text of the change itself.

For example:

    v0.1.0 2022-11-17T08:12:42+0900
        - Some very long line of change going here, which can be wrapped here at 78 characters

wrapped at 78 characters would become:

    v0.1.0 2022-11-17T08:12:42+0900
        - Some very long line of change going here, which can be wrapped here at 
          78 characters

=head2 new_change

Returns a new L<Changes::Change> object, passing it any parameters provided.

If an error occurred, it returns an L<error object|Module::Generic/error>

=head2 new_group

Returns a new L<Changes::Group> object, passing it any parameters provided.

If an error occurred, it returns an L<error object|Module::Generic/error>

=head2 new_line

Returns a new C<Changes::NewLine> object, passing it any parameters provided.

If an error occurred, it returns an L<error object|Module::Generic/error>

=head2 new_release

Returns a new L<Changes::Release> object, passing it any parameters provided.

If an error occurred, it returns an L<error object|Module::Generic/error>

=head2 new_version

Returns a new C<Changes::Version> object, passing it any parameters provided.

If an error occurred, it returns an L<error object|Module::Generic/error>

=head2 nl

Sets or gets the new line character, which defaults to C<\n>

It returns a L<number object|Module::Generic::Number>

=head2 parse

Provided with an array reference of lines to parse and this will parse each line and create all necessary L<release|Changes::Release>, L<group|Changes::Group> and L<change|Changes::Change> objects.

It returns the current object it was called with upon success, and returns an L<error|Module::Generic/error> upon error.

=head2 preamble

Sets or gets the text of the preamble. A preamble is a chunk of text, possibly multi line, that appears at the top of the Changes file before any release information.

=head2 preset

Provided with a preset name, and this will set all its defaults.

Currently, the only preset supported is C<standard>

Returns the current object upon success, or sets an L<error object|Module::Generic/error> and return C<undef> or empty list, depending on the context, otherwise.

=head2 releases

Read only. This returns an L<array object|Module::Generic::Array> containing all the L<release objects|Changes::Release> within the Changes file.

=head2 remove_release

This is an alias for L</delete_release>

=for Pod::Coverage reset

=head2 serialise

This is an alias for L</as_string>

=head2 serialize

This is an alias for L</as_string>

=head2 time_zone

Sets or gets a time zone to use for the release date. A valid time zone can either be an olson time zone string such as C<Asia/Tokyo>, or an L<DateTime::TimeZone> object.

If set, it will be passed to all new L<Changes::Release> object upon parsing with L</parse>

It returns a L<DateTime::TimeZone> object upon success, or an L<error|Module::Generic/error> if an error occurred.

=head2 type

Sets or get the type of C<Changes> file format this is.

=head2 wrapper

Sets or gets a code reference as a callback mechanism to return a properly wrapped change text. This allows flexibility beyond the default use of L<Text::Wrap> and L<Text::Format> by L<Changes::Change>.

If set, this is passed by L</parse> when creating L<Changes::Change> objects.

See L<Changes::Change/as_string> for more information.

=head2 write

This will open the file set with L</file> in write clobbering mode and print out the result from L</as_string>.

It returns the current object upon success, and an L<error|Module::Generic/error> if an error occurred.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Changes::Release>, L<Changes::Group>, L<Changes::Change>, L<Changes::Version>, L<Changes::NewLine>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
