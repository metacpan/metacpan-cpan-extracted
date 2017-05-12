# ABSTRACT: Scalar Object for Perl 5
package Data::Object::Scalar;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Class;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

with 'Data::Object::Role::Scalar';

our $VERSION = '0.59'; # VERSION

method new ($class: @args) {

    my $arg  = $args[0];
    my $role = 'Data::Object::Role::Type';

    $arg = $arg->data if Scalar::Util::blessed($arg)
        and $arg->can('does')
        and $arg->does($role);

    if (Scalar::Util::blessed($arg) && $arg->isa('Regexp') && $^V <= v5.12.0) {
        $arg = do {\(my $q = qr/$arg/)};
    }

    return bless ref($arg) ? $arg : \$arg, $class;

}

our @METHODS = @{ __PACKAGE__->methods };

my  $exclude = qr/^data|detract|new$/;

around [ grep { !/$exclude/ } @METHODS ] => fun ($orig, $self, @args) {

    my $results = $self->$orig(@args);

    return Data::Object::deduce_deep($results);

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Scalar - Scalar Object for Perl 5

=head1 VERSION

version 0.59

=head1 SYNOPSIS

    use Data::Object::Scalar;

    my $scalar = Data::Object::Scalar->new(\12345);

=head1 DESCRIPTION

Data::Object::Scalar provides routines for operating on Perl 5 scalar
objects. Scalar methods work on data that meets the criteria for being a scalar.

=head1 COMPOSITION

This package inherits all functionality from the L<Data::Object::Role::Scalar>
role and implements proxy methods as documented herewith.

=head1 METHODS

=head2 data

    # given $scalar

    $scalar->data; # original value

The data method returns the original and underlying value contained by the
object. This method is an alias to the detract method.

=head2 defined

    # given $scalar

    $scalar->defined; # 1

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=head2 detract

    # given $scalar

    $scalar->detract; # original value

The detract method returns the original and underlying value contained by the
object.

=head2 dump

    # given $scalar

    $scalar->dump;

The dump method returns returns a string representation of the object.
This method returns a L<Data::Object::String> object.

=head2 eq

    # given $scalar

    $scalar->eq; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 ge

    # given $scalar

    $scalar->ge; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 gt

    # given $scalar

    $scalar->gt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 le

    # given $scalar

    $scalar->le; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 lt

    # given $scalar

    $scalar->lt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 methods

    # given $scalar

    $scalar->methods;

The methods method returns the list of methods attached to object. This method
returns a L<Data::Object::Array> object.

=head2 ne

    # given $scalar

    $scalar->ne; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 new

    # given \12345

    my $scalar = Data::Object::Scalar->new(\12345);

The new method expects a scalar reference and returns a new class instance.

=head2 print

    # given $scalar

    $scalar->print;

The print method outputs the value represented by the object to STDOUT and
returns true. This method returns a L<Data::Object::Number> object.

=head2 roles

    # given $scalar

    $scalar->roles;

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=head2 say

    # given $scalar

    $scalar->say;

The say method outputs the value represented by the object appended with a
newline to STDOUT and returns true. This method returns a L<Data::Object::Number>
object.

=head2 throw

    # given $scalar

    $scalar->throw;

The throw method terminates the program using the core die keyword, passing the
object to the L<Data::Object::Exception> class as the named parameter C<object>.
If captured this method returns a L<Data::Object::Exception> object.

=head2 type

    # given $scalar

    $scalar->type; # SCALAR

The type method returns a string representing the internal data type object name.
This method returns a L<Data::Object::String> object.

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

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
