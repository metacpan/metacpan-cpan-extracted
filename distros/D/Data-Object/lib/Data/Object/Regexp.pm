# ABSTRACT: Regexp Object for Perl 5
package Data::Object::Regexp;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Class;
use Data::Object::Library;
use Data::Object::Regexp::Result;
use Data::Object::Signatures;
use Scalar::Util;

with 'Data::Object::Role::Regexp';

our $VERSION = '0.59'; # VERSION

method new ($class: @args) {

    my $arg  = $args[0];
    my $role = 'Data::Object::Role::Type';

    $arg = $arg->data if Scalar::Util::blessed($arg)
        and $arg->can('does')
        and $arg->does($role);

    Data::Object::throw('Type Instantiation Error: Not a RegexpRef')
        unless defined($arg) && !! re::is_regexp($arg);

    return bless \$arg, $class;

}

our @METHODS = @{ __PACKAGE__->methods };

my  $exclude = qr/^data|detract|new|replace|search$/;

around [ grep { !/$exclude/ } @METHODS ] => fun ($orig, $self, @args) {

    my $results = $self->$orig(@args);

    return Data::Object::deduce_deep($results);

};

around ['search', 'replace'] => fun ($orig, $self, @args) {

    my $results = Data::Object::Regexp::Result->new($self->$orig(@args));

    return $results;

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Regexp - Regexp Object for Perl 5

=head1 VERSION

version 0.59

=head1 SYNOPSIS

    use Data::Object::Regexp;

    my $re = Data::Object::Regexp->new(qr(something to match against));

=head1 DESCRIPTION

Data::Object::Regexp provides routines for operating on Perl 5 regular
expressions. Data::Object::Regexp methods work on data that meets the criteria
for being a regular expression.

=head1 COMPOSITION

This package inherits all functionality from the L<Data::Object::Role::Regexp>
role and implements proxy methods as documented herewith.

=head1 METHODS

=head2 data

    # given $regexp

    $regexp->data; # original value

The data method returns the original and underlying value contained by the
object. This method is an alias to the detract method.

=head2 defined

    # given $regexp

    $regexp->defined; # 1

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=head2 detract

    # given $regexp

    $regexp->detract; # original value

The detract method returns the original and underlying value contained by the
object.

=head2 dump

    # given qr(test)

    $regexp->dump; # qr/(?^u:test)/

The dump method returns returns a string representation of the object.
This method returns a L<Data::Object::String> object.

=head2 eq

    # given qr(test)

    $regexp->eq(qr(test)); # 1

The eq method returns true if the argument provided is equal to the value
represented by the object. This method returns a L<Data::Object::Number> object.

=head2 ge

    # given qr(test)

    $regexp->ge(qr(test)); # 1

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=head2 gt

    # given qr(test)

    $regexp->gt(qr(test)); # 0

The gt method returns true if the argument provided is greater-than the value
represented by the object. This method returns a L<Data::Object::Number> object.

=head2 le

    # given qr(test)

    $regexp->le(qr(test)); # 1

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=head2 lt

    # given qr(test)

    $regexp->lt(qr(test)); # 0

The lt method returns true if the argument provided is less-than the value
represented by the object. This method returns a L<Data::Object::Number> object.

=head2 methods

    # given $regexp

    $regexp->methods;

The methods method returns the list of methods attached to object. This method
returns a L<Data::Object::Array> object.

=head2 ne

    # given qr(test)

    $regexp->ne(qr(test)); # 1

The ne method returns true if the argument provided is not equal to the value
represented by the object. This method returns a L<Data::Object::Number> object.

=head2 new

    # given qr(something to match against)

    my $re = Data::Object::Regexp->new(qr(something to match against));

The new method expects a regular-expression object and returns a new class
instance.

=head2 print

    # given qr(test)

    $regexp->print; # 'qr/(?^u:test)/'

The print method outputs the value represented by the object to STDOUT and
returns true. This method returns a L<Data::Object::Number> object.

=head2 replace

    # given qr(test)

    $re->replace('this is a test', 'drill');
    $re->replace('test 1 test 2 test 3', 'drill', 'gi');

The replace method performs a regular expression substitution on the given
string. The first argument is the string to match against.  The second argument
is the replacement string.  The optional third argument might be a string
representing flags to append to the s///x operator, such as 'g' or 'e'.  This
method will always return a L<Data::Object::Regexp::Result> object which can be
used to introspect the result of the operation.

=head2 roles

    # given $regexp

    $regexp->roles;

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=head2 say

    # given qr(test)

    $regexp->say; # 'qr/(?^u:test)/\n'

The say method outputs the value represented by the object appended with a
newline to STDOUT and returns true. This method returns a L<Data::Object::Number>
object.

=head2 search

    # given qr((test))

    $re->search('this is a test');
    $re->search('this does not match', 'gi');

The search method performs a regular expression match against the given string
This method will always return a L<Data::Object::Regexp::Result> object which
can be used to introspect the result of the operation.

=head2 throw

    # given $regexp

    $regexp->throw;

The throw method terminates the program using the core die keyword, passing the
object to the L<Data::Object::Exception> class as the named parameter C<object>.
If captured this method returns a L<Data::Object::Exception> object.

=head2 type

    # given $regexp

    $regexp->type; # REGEXP

The type method returns a string representing the internal data type object name.
This method returns a L<Data::Object::String> object.

=head1 ROLES

This package is comprised of the following roles.

=over 4

=item *

L<Data::Object::Role::Alphabetic>

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
