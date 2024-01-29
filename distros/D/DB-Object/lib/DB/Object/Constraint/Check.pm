##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Constraint/Check.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/11/20
## Modified 2023/11/20
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Constraint::Check;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{expr}   = undef;
    $self->{fields} = undef;
    $self->{name}   = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub expr { return( shift->_set_get_scalar_as_object( 'expr', @_ ) ); }

sub fields { return( shift->_set_get_array_as_object( 'fields', @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Constraint::Check - Table Check Constraint Class

=head1 SYNOPSIS

    use DB::Object::Constraint::Check;
    my $check = DB::Object::Constraint::Check->new(
        expr => q{CHECK (status::text ~* '^(active|inactive|locked|pending|protected|removed|suspended)$'::text)},
        fields => [qw( status )],
        name => 'chk_users_status',
    ) || die( DB::Object::Constraint::Check->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a table check constraint. It is instantiated by the L<structure|DB::Object::Tables/structure> method when retrieving the table structure details.

=head1 CONSTRUCTOR

=head2 new

To instantiate new object, you can pass an hash or hash reference of properties matching the method names available below.

=head1 METHODS

=head2 expr

Sets or gets a check constraint expression.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 fields

Sets or gets an array reference of table field names associated with this constraint.

It returns a L<array object|Module::Generic::Array>

=head2 name

Sets or gets the check constraint name.

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
