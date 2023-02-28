##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Fields/Unknown.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/12/21
## Modified 2022/12/21
## All rights reserved
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
    use vars qw( $VERSION );
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
    our $VERSION = 'v0.1.0';
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
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string { return( shift->error->scalar ); }

sub error { return( shift->_set_get_scalar_as_object( 'error', @_ ) ); }

sub field { return( shift->_set_get_scalar_as_object( 'field', @_ ) ); }

sub table { return( shift->_set_get_scalar_as_object( 'table', @_ ) ); }

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

    v0.1.0

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
