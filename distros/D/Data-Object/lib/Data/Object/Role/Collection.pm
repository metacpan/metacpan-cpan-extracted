# ABSTRACT: Collection Object Role for Perl 5
package Data::Object::Role::Collection;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Role;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

map with($_), our @ROLES = qw(
  Data::Object::Role::List
);

requires 'each';
requires 'each_key';
requires 'each_n_values';
requires 'each_value';
requires 'exists';
requires 'invert';
requires 'iterator';
requires 'list';
requires 'keys';
requires 'get';
requires 'set';
requires 'slice';
requires 'values';

our $VERSION = '0.60'; # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Role::Collection - Collection Object Role for Perl 5

=head1 VERSION

version 0.60

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Collection';

=head1 DESCRIPTION

Data::Object::Role::Collection provides routines for operating on Perl 5 data
objects which meet the criteria for being a collection.

=head1 ROLES

This package is comprised of the following roles.

=over 4

=item *

L<Data::Object::Role::List>

=back

=head1 REQUIRES

This package requires the consumer to implement the following methods.

=over 4

=item *

each

=item *

each_key

=item *

each_n_values

=item *

each_value

=item *

exists

=item *

get

=item *

invert

=item *

iterator

=item *

keys

=item *

list

=item *

set

=item *

slice

=item *

values

=back

=head1 SEE ALSO

=over 4

=item *

L<Data::Object::Array>

=item *

L<Data::Object::Class>

=item *

L<Data::Object::Class::Syntax>

=item *

L<Data::Object::Code>

=item *

L<Data::Object::Float>

=item *

L<Data::Object::Hash>

=item *

L<Data::Object::Integer>

=item *

L<Data::Object::Number>

=item *

L<Data::Object::Role>

=item *

L<Data::Object::Role::Syntax>

=item *

L<Data::Object::Regexp>

=item *

L<Data::Object::Scalar>

=item *

L<Data::Object::String>

=item *

L<Data::Object::Undef>

=item *

L<Data::Object::Universal>

=item *

L<Data::Object::Autobox>

=item *

L<Data::Object::Immutable>

=item *

L<Data::Object::Library>

=item *

L<Data::Object::Prototype>

=item *

L<Data::Object::Signatures>

=back

=cut

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
