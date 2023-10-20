##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Fields/Overloaded.pm
## Version v0.1.0
## Copyright(c) 2021-2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/01/01
## Modified 2023/07/08
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DB::Object::Fields::Overloaded;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object::Query::Element );
    use vars qw( $VERSION );
    use overload (
        '""'    => sub{ return( $_[0]->{expression} ) },
        'bool'  => sub{1},
        fallback => 1,
    );
    our $VERSION = 'v0.1.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{expression} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# sub binded { return( shift->{binded} ); }

# For example, if a placeholder was $1 (PostgreSQL), or ?1 (SQLite), the binded_offset value would be 1
# sub binded_offset { return( shift->{binded_offset} ); }

sub expression { return( shift->_set_get_scalar( 'expression', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

DB::Object::Fields::Overloaded - Overloaded Field Class

=head1 SYNOPSIS

    use DB::Object::Fields::Overloaded;
    my $this = DB::Object::Fields::Overloaded->new(
        # like field = $value
        expression => $some_sql_expression,
        field => $some_field,
        type => $type,
        value => $some_value,
    ) || die( DB::Object::Fields::Overloaded->error, "\n" );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

The purpose of this package is to tag overloaded operation so we can handle them properly later such as in a where clause

=head1 METHODS

=head2 expression

Sets or gets the resulting expression from the overloaded field resulting from an operation.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DB::Object::Fields::Field>, L<DB::Object::Fields>, L<DB::Object::Fields::Unknown>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
