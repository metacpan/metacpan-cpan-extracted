##----------------------------------------------------------------------------
## Changes file management - ~/lib/Changes/Release.pm
## Version v0.2.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/11/23
## Modified 2022/12/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Changes::Release;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $VERSION_CLASS $DEFAULT_DATETIME_FORMAT );
    use Changes::Group;
    use Changes::Version;
    use DateTime;
    use Nice::Try;
    use Want;
    our $VERSION_CLASS = 'Changes::Version';
    our $DEFAULT_DATETIME_FORMAT = '%FT%T%z';
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{changes}        = [];
    $self->{container}      = undef;
    $self->{datetime}       = undef;
    $self->{datetime_formatter} = undef;
    $self->{defaults}       = undef;
    $self->{elements}       = [];
    # DateTime format
    $self->{format}         = undef;
    $self->{line}           = undef;
    $self->{nl}             = "\n";
    $self->{note}           = undef;
    $self->{raw}            = undef;
    $self->{spacer}         = undef;
    $self->{time_zone}      = undef;
    $self->{version}        = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_reset} = 1;
    return( $self );
}

sub add_change
{
    my $self = shift( @_ );
    my( $change, $opts );
    my $elements = $self->elements;
    if( scalar( @_ ) == 1 && $self->_is_a( $_[0] => 'Changes::Change' ) )
    {
        $change = shift( @_ );
        if( $elements->exists( $change ) )
        {
            $self->_load_class( 'overload' );
            return( $self->error( "A very same change object (", overload::StrVal( $change ), ") is already registered." ) );
        }
    }
    else
    {
        $opts = $self->_get_args_as_hash( @_ );
        $change = $self->new_change( %$opts ) || return( $self->pass_error );
    }
    $elements->push( $change );
    return( $change );
}

sub add_group
{
    my $self = shift( @_ );
    my( $group, $opts );
    my $elements = $self->elements;
    if( scalar( @_ ) == 1 && $self->_is_a( $_[0] => 'Changes::Group' ) )
    {
        $group = shift( @_ );
        if( $elements->exists( $group ) )
        {
            $self->_load_class( 'overload' );
            return( $self->error( "A very same group object (", overload::StrVal( $group ), ") is already registered." ) );
        }
        my $name = $group->name;
        if( !defined( $name ) || !length( "$name" ) )
        {
            return( $self->error( "Group object provided has empty name." ) );
        }
        my $same = $elements->grep(sub{ $self->_is_a( $_ => 'Changes::Group' ) && ( ( $_->name // '' ) eq "$name" ) });
        return( $self->error( "A similar group with name '$name' is already registered." ) ) if( !$same->is_empty );
    }
    else
    {
        $opts = $self->_get_args_as_hash( @_ );
        $group = $self->new_group( %$opts ) || return( $self->pass_error );
        return( $self->add_group( $group ) );
    }
    my $last = $elements->last;
    # If we are not the first element of this release, and the last element is not a blank new line, we add one to separate this new group from the preceding rest
    if( $elements->length && !$self->_is_a( $last => 'Changes::NewLine' ) )
    {
        $elements->push( $self->new_line( nl => ( $self->nl // "\n" ) ) );
    }
    $elements->push( $group );
    return( $group );
}

sub as_string
{
    my $self = shift( @_ );
    $self->message( 5, "Is reset set ? ", ( exists( $self->{_reset} ) ? 'yes' : 'no' ), " and what is cache value '", ( $self->{_cache_value} // '' ), "' and raw cache '", ( $self->{raw} // '' ), "'" );
    if( !exists( $self->{_reset} ) || 
        !defined( $self->{_reset} ) ||
        !CORE::length( $self->{_reset} ) )
    {
        my $cache;
        if( exists( $self->{_cache_value} ) &&
            defined( $self->{_cache_value} ) &&
            length( $self->{_cache_value} ) )
        {
            $cache = $self->{_cache_value};
        }
        elsif( defined( $self->{raw} ) && length( "$self->{raw}" ) )
        {
            $cache = $self->{raw};
        }
        
        my $lines = $self->new_array( $cache->scalar );
        $self->elements->foreach(sub
        {
            $self->message( 4, "Calling as_string on $_" );
            my $this = $_->as_string;
            if( defined( $this ) )
            {
                $self->message( 4, "Adding string '$this' to new lines" );
                $lines->push( $this->scalar );
            }
        });
        # my $str = $lines->join( "\n" );
        my $str = $lines->join( '' );
        return( $str );
    }
    my $v = $self->version;
    return( $self->error( "No version set yet. Set a version before calling as_string()" ) ) if( !defined( $v ) || !length( "$v" ) );
    my $dt = $self->datetime;
    my $code = $self->datetime_formatter;
    if( defined( $code ) && ref( $code ) eq 'CODE' )
    {
        try
        {
            $dt = $code->( defined( $dt ) ? $dt : () );
        }
        catch( $e )
        {
            warn( "Warning only: error with datetime formatter calback: $e\n" ) if( $self->_warnings_is_enabled( 'Changes' ) );
        }
    }
    if( !defined( $dt ) || !length( "$dt" ) )
    {
        $dt = DateTime->now;
    }
    
    my $fmt_pattern = $self->format;
    $fmt_pattern = $DEFAULT_DATETIME_FORMAT if( defined( $fmt_pattern ) && $fmt_pattern eq 'default' );
    my $tz = $self->time_zone;
    if( ( !defined( $fmt_pattern ) || !length( "$fmt_pattern" ) ) &&
        !$dt->formatter &&
        defined( $DEFAULT_DATETIME_FORMAT ) &&
        length( "$DEFAULT_DATETIME_FORMAT" ) )
    {
        $fmt_pattern = $DEFAULT_DATETIME_FORMAT;
    }
    if( defined( $tz ) )
    {
        try
        {
            $dt->set_time_zone( $tz );
        }
        catch( $e )
        {
            warn( "Warning only: error trying to set the time zone '", $tz->name, "' (", overload::StrVal( $tz ), ") to DateTime object: $e\n" ) if( $self->_warnings_is_enabled( 'Changes' ) );
        }
    }
    if( defined( $fmt_pattern ) && 
        length( "$fmt_pattern" ) )
    {
        try
        {
            require DateTime::Format::Strptime;
            my $dt_fmt = DateTime::Format::Strptime->new(
                pattern => $fmt_pattern,
                locale => 'en_GB',
            );
            $dt->set_formatter( $dt_fmt );
        }
        catch( $e )
        {
            return( $self->error( "Error trying to set formatter for format '${fmt_pattern}': $e" ) );
        }
    }
    my $nl = $self->nl;
    my $lines = $self->new_array;
    my $rel_str = $self->new_scalar( $v . ( $self->spacer // ' ' ) . "$dt" . ( $self->note->length ? ( ' ' . $self->note->scalar ) : '' ) . ( $nl // '' ) );
    $self->message( 4, "Adding release string '$rel_str' to new lines." );
    $lines->push( $rel_str->scalar );
    $self->elements->foreach(sub
    {
        $self->message( 4, "Calling as_string on $_" );
        # XXX
        $_->debug( $self->debug );
        my $this = $_->as_string;
        if( defined( $this ) )
        {
            $self->message( 4, "Adding string '$this' (", overload::StrVal( $this ), ") to new lines" );
            $lines->push( $this->scalar );
        }
    });
    # my $str = $lines->join( "$nl" );
    my $str = $lines->join( '' );
    $self->{_cache_value} = $str;
    CORE::delete( $self->{_reset} );
    return( $str );
}

sub changes
{
    my $self = shift( @_ );
    # my $a = $self->elements->grep(sub{ $self->_is_a( $_ => 'Changes::Change' ) });
    # We account for both Changes::Change objects registered directly under this release object, and
    # and Changes::Change objects registered under any Changes::Group objects
    my $a = $self->new_array;
    $self->elements->foreach(sub
    {
        if( $self->_is_a( $_ => 'Changes::Change' ) )
        {
            $a->push( $_ );
        }
        elsif( $self->_is_a( $_ => 'Changes::Group' ) )
        {
            my $changes = $_->elements->grep(sub{ $self->_is_a( $_ => 'Changes::Change' ) });
            $a->push( $changes->list ) if( defined( $changes ) );
        }
    });
    return( $a );
}

sub container { return( shift->_set_get_object_without_init( 'container', 'Changes', @_ ) ); }

sub datetime { return( shift->reset(@_)->_set_get_datetime( 'datetime', @_ ) ); }

sub datetime_formatter { return( shift->reset(@_)->_set_get_code( { field => 'datetime_formatter', undef_ok => 1 }, @_ ) ); }

sub defaults { return( shift->_set_get_hash_as_mix_object( { field => 'defaults', undef_ok => 1 }, @_ ) ); }

sub delete_change
{
    my $self = shift( @_ );
    my $elements = $self->elements;
    my $removed = $self->new_array;
    $self->_load_class( 'overload' );
    foreach my $change ( @_ )
    {
        if( $self->_is_a( $change => 'Changes::Change' ) )
        {
            my $pos = $elements->pos( $change );
            if( !defined( $pos ) )
            {
                $self->message( 4, "No change object found for object $change (", overload::StrVal( $change ), ")" ) if( !defined( $pos ) );
                next;
            }
            my $deleted = $elements->delete( $pos, 1 );
            $removed->push( $deleted->list ) if( !$deleted->is_empty );
        }
        else
        {
            warn( "I was expecting a Changes::Change object, but instead got '", ( $_[0] // '' ), "' (", ( defined( $_[0] ) ? overload::StrVal( $_[0] ) : 'undef' ), ").\n" ) if( $self->_warnings_is_enabled );
        }
    }
    return( $removed );
}

sub delete_group
{
    my $self = shift( @_ );
    my $elements = $self->elements;
    my $removed = $self->new_array;
    $self->_load_class( 'overload' );
    foreach my $group ( @_ )
    {
        if( $self->_is_a( $group => 'Changes::Group' ) )
        {
            my $pos = $elements->pos( $group );
            if( !defined( $pos ) )
            {
                $self->message( 4, "No group object found for object $group (", overload::StrVal( $group ), ")" );
                next;
            }
            my $deleted = $elements->delete( $pos, 1 );
            $removed->push( $deleted->list ) if( !$deleted->is_empty );
        }
        else
        {
            my $name = $group;
            if( !defined( $name ) || !length( "$name" ) )
            {
                warn( "No group name provided to remove its corresponding group object.\n" ) if( $self->_warnings_is_enabled );
                next;
            }
            my $found = $elements->grep(sub{ $self->_is_a( $_ => 'Changes::Group' ) && $_->name eq "$name" });
            if( $found->is_empty )
            {
                next;
            }
            $found->foreach(sub
            {
                my $deleted = $self->delete_group( $_ );
                $removed->push( $deleted->list ) if( !$deleted->is_empty );
            });
        }
    }
    return( $removed );
}

sub elements { return( shift->_set_get_array_as_object( 'elements', @_ ) ); }

sub format { return( shift->reset(@_)->_set_get_scalar_as_object( 'format', @_ ) ); }

sub freeze
{
    my $self = shift( @_ );
    $self->message( 5, "Removing the reset marker -> '", ( $self->{_reset} // '' ), "'" );
    CORE::delete( @$self{qw( _reset )} );
    $self->elements->foreach(sub
    {
        if( $self->_can( $_ => 'freeze' ) )
        {
            $_->freeze;
        }
    });
    return( $self );
}

sub groups
{
    my $self = shift( @_ );
    my $a = $self->elements->grep(sub{ $self->_is_a( $_ => 'Changes::Group' ) });
    return( $a );
}

sub line { return( shift->reset(@_)->_set_get_number( 'line', @_ ) ); }

sub new_change
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $self->_load_class( 'Changes::Change' ) || return( $self->pass_error );
    my $defaults = $self->defaults;
    if( defined( $defaults ) )
    {
        foreach my $opt ( qw( spacer1 marker spacer2 max_width wrapper ) )
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
    $self->_load_class( 'Changes::Group' ) || return( $self->pass_error );
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

sub new_version
{
    my $self = shift( @_ );
    $self->_load_class( 'Changes::Version' ) || return( $self->pass_error );
    my $v = Changes::Version->new( @_ ) ||
        return( $self->pass_error( Changes::Version->error ) );
    return( $v );
}

sub nl { return( shift->reset(@_)->_set_get_scalar_as_object( 'nl', @_ ) ); }

sub note { return( shift->reset(@_)->_set_get_scalar_as_object( 'note', @_ ) ); }

sub raw { return( shift->_set_get_scalar_as_object( 'raw', @_ ) ); }

sub remove_change { return( shift->delete_change( @_ ) ); }

sub remove_group { return( shift->delete_group( @_ ) ); }

sub reset
{
    my $self = shift( @_ );
    if( (
            !exists( $self->{_reset} ) ||
            !defined( $self->{_reset} ) ||
            !CORE::length( $self->{_reset} ) 
        ) && scalar( @_ ) )
    {
        $self->message( 4, "Reset called from -> ", sub{ $self->_get_stack_trace } );
        $self->{_reset} = scalar( @_ );
        # Cascade down the need for reset
        $self->changes->foreach(sub
        {
            if( $self->_can( $_ => 'reset' ) )
            {
                $_->reset(1);
            }
        });
    }
    return( $self );
}

sub set_default_format { return( shift->format( $DEFAULT_DATETIME_FORMAT ) ); }

sub spacer { return( shift->reset(@_)->_set_get_scalar_as_object( 'spacer', @_ ) ); }

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
        $self->reset(1);
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

sub version { return( shift->reset(@_)->_set_get_version( { field => 'version', class => $VERSION_CLASS }, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Changes::Release - Release object class

=head1 SYNOPSIS

    use Changes::Release;
    my $rel = Changes::Release->new(
        # A Changes object
        container => $changes_object,
        datetime => '2022-11-17T08:12:42+0900',
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
        format => '%FT%T%z',
        line => 12,
        note => 'Initial release',
        spacer => "\t",
        time_zone => 'Asia/Tokyo',
        version => 'v0.1.0',
    ) || die( Changes::Release->error, "\n" );
    my $change = $rel->add_change( $change_object );
    # or
    my $change = $rel->add_change( text => 'Some comments' );
    my $group = $rel->add_group( $group_object );
    # or
    my $group = $rel->add_group( name => 'Some group' );
    my $change = $rel->delete_change( $change_object );
    my $group = $rel->delete_group( $group_object );
    say $rel->as_string;

=head1 VERSION

    v0.2.1

=head1 DESCRIPTION

This class implements a C<Changes> file release line. Such information usually comprise of a C<version> number, a C<release datetime> and an optional note

Each release section can contain L<group|Changes::Group> and L<changes|Changes::Change> that are all stored and accessible in L</changes>

If an error occurred, it returns an L<error|Module::Generic/error>

The result of this method is cached so that the second time it is called, the cache is used unless there has been any change.

=head1 METHODS

=head2 add_change

Provided with a L<Changes::Change> object, or an hash or hash reference of options passed to the constructor of L<Changes::Change>, and this will add the change object to the list of elements for this release object.

It returns the L<Changes::Change> object, or an L<error|Module::Generic/error> if an error occurred.

=head2 add_group

Provided with a L<Changes::Group> object, or an hash or hash reference of options passed to the constructor of L<Changes::Group>, and this will add the change object to the list of elements.

It returns the L<Changes::Group> object, or an L<error|Module::Generic/error> if an error occurred.

=head2 as_string

Returns a L<string object|Module::Generic::Scalar> representing the release. It does so by calling C<as_string> on each element stored in L</elements>. Those elements can be L<Changes::Group> and L<Changes::Change> objects.

If an error occurred, it returns an L<error|Module::Generic/error>

The result of this method is cached so that the second time it is called, the cache is used unless there has been any change.

=head2 changes

Read only. This returns an L<array object|Module::Generic::Array> containing all the L<change objects|Changes::Change> within this release object.

=head2 container

Sets or gets the L<container object|Changes> for this release object. A container is the object representing the C<Changes> file: a L<Changes> object.

Note that if you instantiate a release object directly, this value will obviously be C<undef>. This value is set by L<Changes> upon parsing the C<Changes> file.

=head2 datetime

Sets or gets the release datetime information. This uses L<Module::Generic/_parse_datetime> to parse the string, so please check that documentation for supported formats.

However, most format are supported including ISO8601 format and L<W3CDTF format|http://www.w3.org/TR/NOTE-datetime> (e.g. C<2022-07-17T12:10:03+09:00>)

Note that if you use a relative datetime format such as C<-2D> for 2 days ago, the datetime format will be set to a unix timestamp, and in that case you need to also specify the C<format> option with the desired datetime format.

You can alternatively directly set a L<DateTime> object.

It returns a L<DateTime> object whose L<date formatter|DateTime::Format::Strptime> object is set to the same format as provided. This ensures that any stringification of the L<DateTime> object reverts back to the string as found in the C<Changes> file or as provided by the user.

=head2 datetime_formatter

Sets or gets a code reference callback to be used when formatting the release datetime. This allows you to use alternative formatter and greater control over the formatting of the release datetime.

This code is called with a L<DateTime> object, and it must return a L<DateTime> object. Any other value will be discarded and it will fallback on setting up a L<DateTime> with current date and time using UTC as time zone and C<$DEFAULT_DATETIME_FORMAT> as default datetime format.

The code executed may die if needed and any exception will be caught and a warning will be issued if L<warnings> are enabled for L<Changes>.

=head2 defaults

Sets or gets an hash of default values for the L<Changes::Change> object when it is instantiated by the C<new_change> method.

Default is C<undef>, which means no default value is set.

    my $ch = Changes->new(
        file => '/some/where/Changes',
        defaults => {
            # For Changes::Change
            spacer1 => "\t",
            spacer2 => ' ',
            marker => '-',
            max_width => 72,
            wrapper => $code_reference,
            # For Changes::Group
            group_spacer => "\t",
            group_type => 'bracket', # [Some group]
        }
    );

=head2 delete_change

This takes a list of change to remove and returns an L<array object|Module::Generic::Array> of those changes thus removed.

A change provided can only be a L<Changes::Change> object.

If an error occurred, this will return an L<error|Module::Generic/error>

=head2 delete_group

This takes a list of group to remove and returns an L<array object|Module::Generic::Array> of those groups thus removed.

A group provided can either be a L<Changes::Group> object, or a group name as a string.

If an error occurred, this will return an L<error|Module::Generic/error>

=head2 elements

Sets or gets an L<array object|Module::Generic::Array> of all the elements within this release object. Those elements can be L<Changes::Group>, L<Changes::Change> and C<Changes::NewLine> objects.

=head2 format

Sets or gets a L<DateTime> format to be used with L<DateTime::Format::Strptime>. See L<DateTime::Format::Strptime/"STRPTIME PATTERN TOKENS"> for details on possible patterns.

You can also specify an alternative formatter with L</datetime_formatter>

If you specify the special value C<default>, it will use default value set in the global variable C<$DEFAULT_DATETIME_FORMAT>, which is C<%FT%T%z> (for example: C<2022-12-08T20:13:09+0900>)

It returns a L<scalar object|Module::Generic::Scalar>

=for Pod::Coverage freeze

=head2 groups

Read only. This returns an L<array object|Module::Generic::Array> containing all the L<group objects|Changes::Group> within this release object.

=head2 line

Sets or gets an integer representing the line number where this release line was found in the original C<Changes> file. If this object was instantiated separately, then obviously this value will be C<undef>

=head2 new_change

Instantiates and returns a new L<Changes::Change>, passing its constructor any argument provided.

    my $change = $rel->new_change( text => 'Some change' ) ||
        die( $rel->error );

=head2 new_group

Instantiates and returns a new L<Changes::Group>, passing its constructor any argument provided.

    my $change = $rel->new_group( name => 'Some group' ) ||
        die( $rel->error );

=head2 new_line

Returns a new C<Changes::NewLine> object, passing it any parameters provided.

If an error occurred, it returns an L<error object|Module::Generic/error>

=head2 new_version

Returns a new C<Changes::Version> object, passing it any parameters provided.

If an error occurred, it returns an L<error object|Module::Generic/error>

=head2 nl

Sets or gets the new line character, which defaults to C<\n>

It returns a L<number object|Module::Generic::Number>

=head2 note

Sets or gets an optional note that is set after the release datetime.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 raw

Sets or gets the raw line as found in the C<Changes> file for this release. If nothing is change, and a raw version exists, then it is returned instead of computing the formatting of the line.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 remove_change

This is an alias for L</delete_change>

=head2 remove_group

This is an alias for L</delete_group>

=for Pod::Coverage reset

=head2 set_default_format

Sets the default L<DateTime> format pattern used by L<DateTime::Format::Strptime>. This default value used is C<$DEFAULT_DATETIME_FORMAT>, which, by default is: C<%FT%T%z>, i.e. something that would look like C<2022-12-06T20:13:09+0900>

=head2 spacer

Sets or gets the space that can be found between the version information and the datetime. Normally this would be just one space, but since it can be other space, this is used to capture it and ensure the result is identical to what was parsed.

This defaults to a single space if it is not set.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 time_zone

Sets or gets a time zone to use for the release date. A valid time zone can either be an olson time zone string such as C<Asia/Tokyo>, or an L<DateTime::TimeZone> object.

It returns a L<DateTime::TimeZone> object upon success, or an L<error|Module::Generic/error> if an error occurred.

=head2 version

Sets or gets the version information for this release. This returns a L<version> object. If you prefer to use a different class, such as L<Perl::Version>, then you can set the global variable C<$VERSION_CLASS> accordingly.

It returns a L<version object|version>, or an object of whatever class you have set with C<$VERSION_CLASS>

=head2 changes

Sets or gets the L<array object|Module::Generic::Array> containing all the object representing the changes for that release. Those changes can be L<Changes::Group>, L<Changes::Change> or C<Changes::Line>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Changes>, L<Changes::Group>, L<Changes::Change>, L<Changes::Version>, L<Changes::NewLine>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
