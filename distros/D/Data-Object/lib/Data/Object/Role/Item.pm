# ABSTRACT: Item Object Role for Perl 5
package Data::Object::Role::Item;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Role;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

map with($_), our @ROLES = qw(
  Data::Object::Role::Defined
  Data::Object::Role::Detract
  Data::Object::Role::Throwable
  Data::Object::Role::Type
);

our $VERSION = '0.60'; # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Role::Item - Item Object Role for Perl 5

=head1 VERSION

version 0.60

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Item';

=head1 DESCRIPTION

Data::Object::Role::Item provides routines for operating on Perl 5 data
which meet the criteria for being considered items.

=head1 METHODS

=head2 data

  # given $item

  $item->data; # original value

The data method returns the original and underlying value contained by the
object. This method is an alias to the detract method.

=head2 detract

  # given $item

  $item->detract; # original value

The detract method returns the original and underlying value contained by the
object.

=head2 methods

  # given $item

  $item->methods;

The methods method returns the list of methods attached to object. This method
returns an array value.

=head2 roles

  # given $item

  $item->roles;

The roles method returns the list of roles attached to object. This method
returns an array value.

=head2 throw

  # given $item

  $item->throw;

The throw method terminates the program using the core die keyword, passing the
object to the L<Data::Object::Exception> class as the named parameter C<object>.
If captured this method returns an exception value.

=head2 type

  # given $item

  $item->type; # ITEM

The type method returns a string representing the internal data type object name.
This method returns a string value.

=head1 ROLES

This package is comprised of the following roles.

=over 4

=item *

L<Data::Object::Role::Defined>

=item *

L<Data::Object::Role::Detract>

=item *

L<Data::Object::Role::Throwable>

=item *

L<Data::Object::Role::Type>

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

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
