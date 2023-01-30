##----------------------------------------------------------------------------
## Changes file management - ~/lib/Changes/Group.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/11/23
## Modified 2022/12/09
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Changes::Group;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{defaults}   = undef;
    $self->{elements}   = [];
    $self->{line}   = undef;
    $self->{name}   = undef;
    $self->{nl}     = "\n";
    $self->{raw}    = undef;
    $self->{spacer} = undef;
    $self->{type}   = 'bracket';
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
    my $nl = $self->nl;
    my $lines = $self->new_array;
    # Either bracket or colon
    my $type = $self->type // 'bracket';
    my $grp_str = $self->new_scalar( ( $self->spacer // '' ) . ( $type eq 'bracket' ? '[' : '' ) . ( $self->name // '' ) . ( $type eq 'bracket' ? ']' : ':' ) . ( $nl // '' ) );
    $lines->push( $grp_str->scalar );
    $self->changes->foreach(sub
    {
        $self->message( 4, "Calling as_string on $_" );
        my $this = $_->as_string;
        if( defined( $this ) )
        {
            $self->message( 4, "Adding string '$this' to new lines" );
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
    my $a = $self->elements->grep(sub{ $self->_is_a( $_ => 'Changes::Change' ) });
    return( $a );
}

sub defaults { return( shift->_set_get_hash_as_mix_object( { field => 'defaults', undef_ok => 1 }, @_ ) ); }

sub delete_change
{
    my $self = shift( @_ );
    my $elements = $self->elements;
    if( scalar( @_ ) != 1 )
    {
        return( $self->error( 'Usage: $group->delete_change( $change_object );' ) );
    }
    elsif( $self->_is_a( $_[0] => 'Changes::Change' ) )
    {
        my $change = shift( @_ );
        my $pos = $elements->pos( $change );
        if( !defined( $pos ) )
        {
            $self->_load_class( 'overload' );
            $self->message( 4, "No change object found for object $change (", overload::StrVal( $change ), ")" );
            return( '' );
        }
        $elements->delete( $pos, 1 );
        return( $change );
    }
    else
    {
        $self->_load_class( 'overload' );
        return( $self->error( "I was expecting a Changes::Change object, but instead got '", ( $_[0] // '' ), "' (", ( defined( $_[0] ) ? overload::StrVal( $_[0] ) : 'undef' ), ")." ) );
    }
}

sub elements { return( shift->_set_get_array_as_object( 'elements', @_ ) ); }

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

sub line { return( shift->reset(@_)->_set_get_number( 'line', @_ ) ); }

sub name { return( shift->reset(@_)->_set_get_scalar_as_object( 'name', @_ ) ); }

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

sub new_line
{
    my $self = shift( @_ );
    $self->_load_class( 'Changes::NewLine' ) || return( $self->pass_error );
    my $nl = Changes::NewLine->new( @_ ) ||
        return( $self->pass_error( Changes::NewLine->error ) );
    return( $nl );
}

sub nl { return( shift->reset(@_)->_set_get_scalar_as_object( 'nl', @_ ) ); }

sub raw { return( shift->_set_get_scalar_as_object( 'raw', @_ ) ); }

sub remove_change { return( shift->delete_change( @_ ) ); }

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
    }
    return( $self );
}

sub spacer { return( shift->reset(@_)->_set_get_scalar_as_object( 'spacer', @_ ) ); }

sub type { return( shift->reset(@_)->_set_get_scalar_as_object( 'type', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Changes::Group - Group object class

=head1 SYNOPSIS

    use Changes::Group;
    my $g = Changes::Group->new(
        line => 12,
        name => 'Front-end',
        spacer => "\t",
        debug => 4,
    ) || die( Changes::Group->error, "\n" );
    my $change = $g->add_change( $change_object );
    # or
    my $change = $g->add_change( text => 'Some comment here' );
    $g->delete_change( $change );
    say $g->as_string;

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This object class represents a C<Changes> file group within a release section. It is completely optional.

=head1 METHODS

=head2 add_change

Provided with a L<Changes::Change> object, or an hash or hash reference of options passed to the constructor of L<Changes::Change>, and this will add the change object to the list of elements for this group object.

It returns the L<Changes::Change> object, or an L<error|Module::Generic/error> if an error occurred.

=head2 as_string

Returns a L<scalar object|Module::Generic::Scalar> of the change group. This is a group name enclosed in square brackets:

    [my group]

It returns a L<scalar object|Module::Generic::Scalar>

If an error occurred, it returns an L<error|Module::Generic/error>

The result of this method is cached so that the second time it is called, the cache is used unless there has been any change.

=head2 changes

Read only. This returns an L<array object|Module::Generic::Array> containing all the L<change objects|Changes::Change> within this group object.

=head2 defaults

Sets or gets an hash of default values for the L<Changes::Change> object when it is instantiated by the C<new_change> method.

Default is C<undef>, which means no default value is set.

    my $ch = Changes->new(
        file => '/some/where/Changes',
        defaults => {
            spacer1 => "\t",
            spacer2 => ' ',
            marker => '-',
            max_width => 72,
            wrapper => $code_reference,
        }
    );

=head2 delete_change

This takes a list of change to remove and returns an L<array object|Module::Generic::Array> of those changes thus removed.

A change provided can only be a L<Changes::Change> object.

If an error occurred, this will return an L<error|Module::Generic/error>

=head2 elements

Sets or gets an L<array object|Module::Generic::Array> of all the elements within this group object. Those elements can be L<Changes::Change> and C<Changes::NewLine> objects.

=for Pod::Coverage freeze

=head2 line

Sets or gets an integer representing the line number where this line containing this group information was found in the original C<Changes> file. If this object was instantiated separately, then obviously this value will be C<undef>

=head2 name

Sets or gets the group name as a L<scalar object|Module::Generic::Scalar>

=head2 new_change

Instantiates and returns a new L<Changes::Change>, passing its constructor any argument provided.

    my $change = $rel->new_change( text => 'Some change' ) ||
        die( $rel->error );

=head2 new_line

Returns a new C<Changes::NewLine> object, passing it any parameters provided.

If an error occurred, it returns an L<error object|Module::Generic/error>

=head2 nl

Sets or gets the new line character, which defaults to C<\n>

It returns a L<number object|Module::Generic::Number>

=head2 raw

Sets or gets the raw version of the group as found in the C<Changes> file. If set and nothing has been changed, this will be returned by L</as_string> instead of computing the formatting of the group.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 remove_change

This is an alias for L</delete_change>

=for Pod::Coverage reset

=head2 spacer

Sets or gets the leading space, if any, found before the group.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 type

Sets or gets the type of group for this object. This can either be C<bracket>, which is the default, or C<colon>:

    [My group]
    # or
    My group:

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Changes>, L<Changes::Release>, L<Changes::Change>, L<Changes::Version>, L<Changes::NewLine>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
