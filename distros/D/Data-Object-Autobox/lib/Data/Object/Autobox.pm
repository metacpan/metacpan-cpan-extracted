# ABSTRACT: An Autobox Implementation for Perl 5
package Data::Object::Autobox;

use 5.010;

use strict;
use warnings;

use base 'autobox';
use Data::Object 'load';

our $VERSION = '0.14'; # VERSION

sub import {
    my $class = shift;
    my $param = shift;

    my ($default, %options) = ('composite', @_);
    my ($flavor) = $param =~ /^[-:](autoload|composite|custom)$/ if $param;

    $flavor = $default if ! $flavor
        or $flavor eq 'custom' and ! keys %options;

    unless (lc $flavor eq 'custom') {
        %options = (
            ARRAY     => load "${class}::\u${flavor}::Array",
            CODE      => load "${class}::\u${flavor}::Code",
            FLOAT     => load "${class}::\u${flavor}::Float",
            HASH      => load "${class}::\u${flavor}::Hash",
            INTEGER   => load "${class}::\u${flavor}::Integer",
            NUMBER    => load "${class}::\u${flavor}::Number",
            SCALAR    => load "${class}::\u${flavor}::Scalar",
            STRING    => load "${class}::\u${flavor}::String",
            UNDEF     => load "${class}::\u${flavor}::Undef",
            UNIVERSAL => load "${class}::\u${flavor}::Universal",
        );
    }

    $class->SUPER::import(%options);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Autobox - An Autobox Implementation for Perl 5

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    use Data::Object::Autobox;

    my $input  = [1,1,1,1,3,3,2,1,5,6,7,8,9];
    my $output = $input->grep('$a < 5')->unique->sort; # [1,2,3]
    my $object = $output->array;

    $output->join(',')->print; # 1,2,3
    $object->join(',')->print; # 1,2,3

    $object->isa('Data::Object::Array');

=head1 DESCRIPTION

Data::Object::Autobox implements autoboxing via L<autobox> to provide
L<boxing|http://en.wikipedia.org/wiki/Object_type_(object-oriented_programming)>
for native Perl 5 data types. This functionality is provided by L<Data::Object>
which provides a collection of object classes for handling SCALAR, ARRAY, HASH,
CODE, INTEGER, FLOAT, NUMBER, STRING, UNDEF, and UNIVERSAL data type operations.
Data::Object provides its own boxing strategy in that every method call which
would normally return a native data type will return a data type object, but
this functionality requires an initial data type object. Data::Object::Autobox
makes it so that you do not need to explicitly create the initial data type
object, and once the initial autobox method call is made, the Data::Object
boxing takes over.

=head1 FLAVORS

Data::Object::Autobox endeavors to implement autoboxing in various flavors to be
suitable in different environments. Currently, there are two boxing flavors
available, C<autoload> and C<composite>, both of which implement the boxing
architecture but handle dispatching and returning in different ways. The default
boxing flavor is C<composite> because that flavor is the closest, in
implementation, to what most people are already familiar with. The following
example describes how flavors are enacted:

    use Data::Object::Autobox -autoload;  # autoboxing via autoload
    use Data::Object::Autobox -composite; # autoboxing via composite

The differences between the main boxing flavors is in how they react to input,
dispatch, and return data. The C<autoload> flavor uses AUTOLOAD to delegate
autoboxing to the L<Data::Object> framework. It is likely that once the initial
delegation happens, autoboxing is no longer necessary in the chaining of
routines. Additionally, the data returned from autoboxed actions under autoload
will always be Data::Object instances.

Conversely, the C<composite> flavor uses role composition, with the respective
roles which L<Data::Object> objects are comprised of, to provide type-specific
boxing functions only. This implementation uses the typical autoboxing approach,
i.e. the autobox pragma handles the boxing, composition provides the functions,
and the data returned is not a Data::Object instance.

Additionally, this module supports passing user-defined classes to
Data::Object::Autobox. The follow is an example of passing custom user-defined
classes which can be completely custom, or inherit from any of the existing
implementations.

    use Data::Object::Autobox -custom => (
        ARRAY     => "MyApp::Autobox::Array",
        CODE      => "MyApp::Autobox::Code",
        FLOAT     => "MyApp::Autobox::Float",
        HASH      => "MyApp::Autobox::Hash",
        INTEGER   => "MyApp::Autobox::Integer",
        NUMBER    => "MyApp::Autobox::Number",
        SCALAR    => "MyApp::Autobox::Scalar",
        STRING    => "MyApp::Autobox::String",
        UNDEF     => "MyApp::Autobox::Undef",
        UNIVERSAL => "MyApp::Autobox::Universal",
    );

=head2 Array Methods

Array methods are called on array references, for example, using C<<
$array->method(@args) >>, which will act on the C<$array> reference and will
return a new data type object. Many array methods are simply wrappers around
core functions, but there are additional operations and modifications to core
behavior. Array methods are handled via the L<Data::Object::Array> object class
which is provided to the autobox ARRAY option.

=head2 Code Methods

Code methods are called on code references, for example, using C<<
$code->method(@args) >>, which will act on the C<$code> reference and will
return a new data type object. Many code methods are simply wrappers around
core functions, but there are additional operations and modifications to core
behavior. Code methods are handled via the L<Data::Object::Code> object class
which is provided to the autobox CODE option.

=head2 Float Methods

Float methods are called on float values, for example, using C<<
$float->method(@args) >>, which will act on the C<$float> value and will
return a new data type object. Many float methods are simply wrappers around
core functions, but there are additional operations and modifications to core
behavior. Float methods are handled via the L<Data::Object::Float> object class
which is provided to the autobox FLOAT option.

=head2 Hash Methods

Hash methods are called on hash references, for example, using C<<
$hash->method(@args) >>, which will act on the C<$hash> reference and will
return a new data type object. Many hash methods are simply wrappers around
core functions, but there are additional operations and modifications to core
behavior. Hash methods are handled via the L<Data::Object::Hash> object class
which is provided to the autobox HASH option.

=head2 Integer Methods

Integer methods are called on integer values, for example, using C<<
$integer->method(@args) >>, which will act on the C<$integer> value and will
return a new data type object. Many integer methods are simply wrappers around
core functions, but there are additional operations and modifications to core
behavior. Integer methods are handled via the L<Data::Object::Integer> object
class which is provided to the autobox INTEGER option.

=head2 Number Methods

Number methods are called on number values, for example, using C<<
$number->method(@args) >>, which will act on the C<$number> value and will
return a new data type object. Many number methods are simply wrappers around
core functions, but there are additional operations and modifications to core
behavior. Number methods are handled via the L<Data::Object::Number> object
class which is provided to the autobox NUMBER option.

=head2 Scalar Methods

Scalar methods are called on scalar references and values, for example, using
C<< $scalar->method(@args) >>, which will act on the C<$scalar> reference and
will return a new data type object. Many scalar methods are simply wrappers
around core functions, but there are additional operations and modifications to
core behavior. Scalar methods are handled via the L<Data::Object::Scalar> object
class which is provided to the autobox SCALAR option.

=head2 String Methods

String methods are called on string values, for example, using C<<
$string->method(@args) >>, which will act on the C<$string> value and will
return a new data type object. Many string methods are simply wrappers around
core functions, but there are additional operations and modifications to core
behavior. String methods are handled via the L<Data::Object::String> object
class which is provided to the autobox STRING option.

=head2 Undef Methods

Undef methods are called on undef values, for example, using C<<
$undef->method(@args) >>, which will act on the C<$undef> value and will
return a new data type object. Many undef methods are simply wrappers around
core functions, but there are additional operations and modifications to core
behavior. Undef methods are handled via the L<Data::Object::Undef> object
class which is provided to the autobox UNDEF option.

=head2 Universal Methods

Universal methods can be called on any values, for example, using C<<
$universal->method(@args) >>, which will act on the reference or value and will
return a new data type object. Many universal methods are simply wrappers around
core functions, but there are additional operations and modifications to core
behavior. Universal methods are handled via the L<Data::Object::Universal>
object class which is provided to the autobox UNIVERSAL option.

=head1 SEE ALSO

=over 4

=item *

L<Data::Object>

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
