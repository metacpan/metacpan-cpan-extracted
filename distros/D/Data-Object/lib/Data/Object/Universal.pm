# ABSTRACT: Universal Object for Perl 5
package Data::Object::Universal;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Class;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

with 'Data::Object::Role::Universal';

our $VERSION = '0.61'; # VERSION

method new ($class: @args) {

  my $arg  = $args[0];
  my $role = 'Data::Object::Role::Type';

  $arg = $arg->data
    if Scalar::Util::blessed($arg)
    and $arg->can('does')
    and $arg->does($role);

  if (Scalar::Util::blessed($arg) && $arg->isa('Regexp') && $^V <= v5.12.0) {
    $arg = do { \(my $q = qr/$arg/) };
  }

  return bless ref($arg) ? $arg : \$arg, $class;

}

our @METHODS = @{__PACKAGE__->methods};

my $exclude = qr/^data|detract|new$/;

around [grep { !/$exclude/ } @METHODS] => fun($orig, $self, @args) {

  my $results = $self->$orig(@args);

  return Data::Object::deduce_deep($results);

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Universal - Universal Object for Perl 5

=head1 VERSION

version 0.61

=head1 SYNOPSIS

  use Data::Object::Universal;

  my $object = Data::Object::Universal->new($scalar);

=head1 DESCRIPTION

Data::Object::Universal provides routines for operating on any Perl 5 data type.

=head1 METHODS

=head2 data

  # given $object

  $object->data; # original value

The data method returns the original and underlying value contained by the
object. This method is an alias to the detract method.

=head2 defined

  # given $object

  $object->defined; # 1

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=head2 detract

  # given $object

  $object->detract; # original value

The detract method returns the original and underlying value contained by the
object.

=head2 dump

  # given 0

  $object->dump; # 0

The dump method returns returns a string representation of the object.
This method returns a L<Data::Object::String> object.

=head2 eq

  # given $object

  $object->eq; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 ge

  # given $object

  $object->ge; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 gt

  # given $object

  $object->gt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 le

  # given $object

  $object->le; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 lt

  # given $object

  $object->lt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 methods

  # given $object

  $object->methods;

The methods method returns the list of methods attached to object. This method
returns a L<Data::Object::Array> object.

=head2 ne

  # given $object

  $object->ne; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 new

  # given $scalar

  my $object = Data::Object::Universal->new($scalar);

The new method expects a scalar reference and returns a new class instance.

=head2 print

  # given 0

  $object->print; # 0

The print method outputs the value represented by the object to STDOUT and
returns true. This method returns a L<Data::Object::Number> object.

=head2 roles

  # given $object

  $object->roles;

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=head2 say

  # given 0

  $object->say; # '0\n'

The say method outputs the value represented by the object appended with a
newline to STDOUT and returns true. This method returns a L<Data::Object::Number>
object.

=head2 throw

  # given $object

  $object->throw;

The throw method terminates the program using the core die keyword, passing the
object to the L<Data::Object::Exception> class as the named parameter C<object>.
If captured this method returns a L<Data::Object::Exception> object.

=head2 type

  # given $object

  $object->type; # UNIVERSAL

The type method returns a string representing the internal data type object name.
This method returns a L<Data::Object::String> object.

=head1 COMPOSITION

This package inherits all functionality from the L<Data::Object::Role::Universal>
role and implements proxy methods as documented herewith.

=head1 ROLES

This package is comprised of the following roles.

=over 4

=item *

L<Data::Object::Role::Comparison>

=item *

L<Data::Object::Role::Defined>

=item *

L<Data::Object::Role::Detract>

=item *

L<Data::Object::Role::Dumper>

=item *

L<Data::Object::Role::Item>

=item *

L<Data::Object::Role::Output>

=item *

L<Data::Object::Role::Throwable>

=item *

L<Data::Object::Role::Type>

=item *

L<Data::Object::Role::Value>

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

Al Newkirk <al@iamalnewkirk.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
