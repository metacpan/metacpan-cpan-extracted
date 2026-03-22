##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Fields/Unknown.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/12/21
## Modified 2026/03/22
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Fields::Unknown;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    use overload (
        # '""' => \&as_string,
        'bool'  => sub{$_[0]},
        '+'     => sub{ $_[0] },
        '-'     => sub{ $_[0] },
        '*'     => sub{ $_[0] },
        '/'     => sub{ $_[0] },
        '%'     => sub{ $_[0] },
        '<'     => sub{ $_[0] },
        '>'     => sub{ $_[0] },
        '<='    => sub{ $_[0] },
        '>='    => sub{ $_[0] },
        '!='    => sub{ $_[0] },
        '<<'    => sub{ $_[0] },
        '>>'    => sub{ $_[0] },
        '&'     => sub{ $_[0] },
        '^'     => sub{ $_[0] },
        '|'     => sub{ $_[0] },
        '=='    => sub{ $_[0] },
        fallback => 1,
    );
    our $EXCEPTION_CLASS = $DB::Object::EXCEPTION_CLASS;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{error} = undef;
    $self->{field} = undef;
    $self->{table} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class}     = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string { return( shift->error->scalar ); }

sub error { return( shift->_set_get_scalar_as_object( 'error', @_ ) ); }

sub field { return( shift->_set_get_scalar_as_object( 'field', @_ ) ); }

sub table { return( shift->_set_get_scalar_as_object( 'table', @_ ) ); }

# NOTE: For CBOR and Sereal
sub FREEZE
{
    my $self       = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class      = CORE::ref( $self );

    # We keep a strict allow-list to avoid accidentally freezing DBI handles or other
    # process-local state.
    # 2026-01-29: I removed 'query_object' in an effort to reduce memory consumption. Let's see...
    my @props = qw(
        field table
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

DB::Object::Fields::Unknown - Unknown Field Class

=head1 SYNOPSIS

    use DB::Object::Fields::Unknown;
    my $f = DB::Object::Fields::Unknown->new(
        table => 'some_table',
        error => 'Table some_table has no such field \"some_field\".',
    ) || die( DB::Object::Fields::Unknown->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class represents an unknown field. This happens when L<DB::Object::Fields> cannot find a given field used in a SQL query. Instead of returning an error (undef), it returns this object, which is then ignored when he query is formulated.

A warning is issued by L<DB::Object::Fields> when a field is unknown, so make sure to check your error output or your error log.

=head1 METHODS

=head2 as_string

Returns the error message as a regular string.

=head2 error

Sets or gets the error that triggered this new object.

This returns the error as a L<string object|Module::Generic::Scalar>

=head2 field

Sets or gets the name of the unknown field.

This returns the field name as a L<string object|Module::Generic::Scalar>

=head2 table

Sets or gets the name of the table associated with this unknown field

This returns the table name as a L<string object|Module::Generic::Scalar>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DB::Object::Fields>, L<DB::Object::Fields::Field>, L<DB::Object::Query>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
