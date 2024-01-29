##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Constraint/Foreign.pm
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
package DB::Object::Constraint::Foreign;
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
    $self->{expr}       = undef;
    $self->{fields}     = undef;
    $self->{match}      = undef;
    $self->{on_delete}  = undef;
    $self->{on_update}  = undef;
    $self->{name}       = undef;
    $self->{table}      = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub expr { return( shift->_set_get_scalar_as_object( 'expr', @_ ) ); }

sub fields { return( shift->_set_get_array_as_object( 'fields', @_ ) ); }

sub match { return( shift->_set_get_scalar_as_object( 'match', @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub on_delete { return( shift->_set_get_scalar_as_object( 'on_delete', @_ ) ); }

sub on_update { return( shift->_set_get_scalar_as_object( 'on_update', @_ ) ); }

sub table { return( shift->_set_get_scalar_as_object( 'table', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Constraint::Foreign - Table Foreign Key Constraint Class

=head1 SYNOPSIS

    use DB::Object::Constraint::Foreign;
    my $foreign = DB::Object::Constraint::Foreign->new(
        expr => q{FOREIGN KEY (lang) REFERENCES language(lang) ON DELETE RESTRICT},
        fields => [qw( lang )],
        match => 'simple',
        on_delete => 'restrict',
        on_update => 'nothing',
        name => 'fk_user_info_lang',
        table => 'language',
    ) || die( DB::Object::Constraint::Foreign->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a table foreign key constraint. It is instantiated by the L<structure|DB::Object::Tables/structure> method when retrieving the table structure details.

=head1 CONSTRUCTOR

=head2 new

To instantiate new object, you can pass an hash or hash reference of properties matching the method names available below.

=head1 METHODS

=head2 expr

Sets or gets the foreign key constraint expression.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 fields

Sets or gets an array reference of table field names associated with this constraint.

It returns a L<array object|Module::Generic::Array>

=head2 match

Sets or gets the method a foreign key constraint matches.

For example: C<full>, C<partial> and C<simple>

It returns a L<scalar object|Module::Generic::Scalar>

=head2 name

Sets or gets the foreign key constraint name.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 on_delete

Sets or gets the action taken by the database upon deletion of this foreign key.

For example: C<nothing>, C<restrict>, C<cascade>, C<null> or C<default>

It returns a L<scalar object|Module::Generic::Scalar>

=head2 on_update

Sets or gets the action taken by the database upon update of this foreign key.

For example: C<nothing>, C<restrict>, C<cascade>, C<null> or C<default>

It returns a L<scalar object|Module::Generic::Scalar>

=head2 table

Sets or gets the table name for this foreign key.

It returns a L<scalar object|Module::Generic::Scalar>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://www.postgresql.org/docs/current/tutorial-fk.html>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
