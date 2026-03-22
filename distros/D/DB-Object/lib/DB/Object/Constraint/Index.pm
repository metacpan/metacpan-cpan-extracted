##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Constraint/Index.pm
## Version v0.2.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/11/20
## Modified 2026/03/22
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Constraint::Index;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    our $EXCEPTION_CLASS = $DB::Object::EXCEPTION_CLASS;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{fields}     = undef;
    $self->{is_primary} = undef;
    $self->{is_unique}  = undef;
    $self->{name}       = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class}     = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub fields { return( shift->_set_get_array_as_object( 'fields', @_ ) ); }

sub is_primary { return( shift->_set_get_boolean( 'is_primary', @_ ) ); }

sub is_unique { return( shift->_set_get_boolean( 'is_unique', @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

# NOTE: For CBOR and Sereal
sub FREEZE
{
    my $self       = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class      = CORE::ref( $self );

    my @props = qw(
        fields is_primary is_unique name
    );

    my $hash = {};
    foreach my $prop ( @props )
    {
        if( CORE::exists( $self->{ $prop } ) &&
            defined( $self->{ $prop } ) &&
            CORE::ref( $self->{ $prop } ) ne 'CODE' )
        {
            $hash->{ $prop } = $self->{ $prop };
        }
    }

    # Return an array reference rather than a list so this works with Sereal and CBOR.
    # Before Sereal version 4.023, Sereal did not support multiple values returned.
    if( $serialiser eq 'Sereal' )
    {
        require Sereal::Encoder;
        require version;

        if( version->parse( Sereal::Encoder->VERSION ) < version->parse( '4.023' ) )
        {
            CORE::return( [$class, $hash] );
        }
    }

    # But Storable wants a list with the first element being the serialised element
    CORE::return( $class, $hash );
}

sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

sub STORABLE_thaw_post_processing
{
    my $obj   = shift( @_ );
    my @keys  = %$obj;
    my $class = ref( $obj );
    my $hash  = {};
    @$hash{ @keys } = @$obj{ @keys };
    my $self = bless( $hash => $class );
    return( $self );
}

sub THAW
{
    # STORABLE_thaw would issue $cloning as the 2nd argument, while CBOR would issue
    # 'CBOR' as the second value.
    my( $self, undef, @args ) = @_;
    my $ref   = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Constraint::Index - Table Index Constraint Class

=head1 SYNOPSIS

    use DB::Object::Constraint::Index;
    my $idx = DB::Object::Constraint::Index->new(
        fields => [qw( id )],
        is_primary => 1,
        is_unique => 1,
        name => 'pk_some_table',
    ) || die( DB::Object::Constraint::Index->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class represents a table index constraint. It is instantiated by the L<structure|DB::Object::Tables/structure> method when retrieving the table structure details.

=head1 CONSTRUCTOR

=head2 new

To instantiate new object, you can pass an hash or hash reference of properties matching the method names available below.

=head1 METHODS

=head2 fields

Sets or gets an array reference of table field names associated with this constraint.

It returns a L<array object|Module::Generic::Array>

=head2 is_primary

Sets or gets a boolean value whether this constraint is a primary index, or not.

Returns a L<boolean object|Module::Generic::Boolean>

=head2 is_unique

Sets or gets a boolean value whether this constraint is a unique constraint, or not.

Returns a L<boolean object|Module::Generic::Boolean>

=head2 name

Sets or gets the index constraint name.

It returns a L<scalar object|Module::Generic::Scalar>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
