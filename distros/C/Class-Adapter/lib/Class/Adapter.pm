package Class::Adapter; # git description: 1a66420
# ABSTRACT: Perl implementation of the "Adapter" Design Pattern

#pod =pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod The C<Class::Adapter> class is intended as an abstract base class for
#pod creating any sort of class or object that follows the I<Adapter> pattern.
#pod
#pod =head2 What is an Adapter?
#pod
#pod The term I<Adapter> refers to a I<"Design Pattern"> of the same name,
#pod from the famous I<"Gang of Four"> book I<"Design Patterns">. Although
#pod their original implementation was designed for Java and similar
#pod single-inheritance strictly-typed language, the situation for which it
#pod applies is still valid.
#pod
#pod An I<Adapter> in this Perl sense of the term is when a class is created
#pod to achieve by composition (objects containing other object) something that
#pod can't be achieved by inheritance (sub-classing).
#pod
#pod This is similar to the I<Decorator> pattern, but is intended to be
#pod applied on a class-by-class basis, as opposed to being able to be applied
#pod one object at a time, as is the case with the I<Decorator> pattern.
#pod
#pod The C<Class::Adapter> object holds a parent object that it "wraps",
#pod and when a method is called on the C<Class::Adapter>, it manually
#pod calls the same (or different) method with the same (or different)
#pod parameters on the parent object contained within it.
#pod
#pod Instead of these custom methods being hooked in on an object-by-object
#pod basis, they are defined at the class level.
#pod
#pod Basically, a C<Class::Adapter> is one of your fall-back positions
#pod when Perl's inheritance model fails you, or is no longer good enough,
#pod and you need to do something twisty in order to make several APIs play
#pod nicely with each other.
#pod
#pod =head2 What can I do with the actual Class::Adapter class
#pod
#pod Well... nothing really. It exist to provide some extremely low level
#pod fundamental methods, and to provide a common base for inheritance of
#pod Adapter classes.
#pod
#pod The base C<Class::Adapter> class doesn't even implement a way to push
#pod method calls through to the underlying object, since the way in which
#pod B<that> happens is the bit that changes from case to case.
#pod
#pod To actually DO something, you probably want to go take a look at
#pod L<Class::Adapter::Builder>, which makes the creation of I<Adapter>
#pod classes relatively quick and easy.
#pod
#pod =head1 METHODS
#pod
#pod The C<Class::Adapter> class itself supplies only the two most common
#pod methods, a default constructor and a private method to access the
#pod underlying object.
#pod
#pod =cut

use 5.005;
use strict;
use Carp              ();
use Scalar::Util 1.10 ();

our $VERSION = '1.09';





#####################################################################
# Constructor

#pod =pod
#pod
#pod =head2 new $object
#pod
#pod The default C<new> constructor takes a single object as argument and
#pod creates a new object which holds the passed object.
#pod
#pod Returns a new C<Class::Adapter> object, or C<undef> if you do not pass
#pod in an object.
#pod
#pod =cut

sub new {
	my $class  = ref $_[0] ? ref shift : shift;
	my $object = Scalar::Util::blessed($_[0]) ? shift : return undef;
	return bless { OBJECT => $object }, $class;
}





#####################################################################
# Private Methods

#pod =pod
#pod
#pod =head2 _OBJECT_
#pod
#pod The C<_OBJECT_> method is provided primarily as a convenience, and a tool
#pod for people implementing sub-classes, and allows the C<Class::Adapter>
#pod interface to provide a guaranteed correct way of getting to the underlying
#pod object, should you need to do so.
#pod
#pod =cut

sub _OBJECT_ {
	return $_[0]->{OBJECT} if ref $_[0];
	Carp::croak('Class::Adapter::_OBJECT_ called as a static method');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Adapter - Perl implementation of the "Adapter" Design Pattern

=head1 VERSION

version 1.09

=head1 DESCRIPTION

The C<Class::Adapter> class is intended as an abstract base class for
creating any sort of class or object that follows the I<Adapter> pattern.

=head2 What is an Adapter?

The term I<Adapter> refers to a I<"Design Pattern"> of the same name,
from the famous I<"Gang of Four"> book I<"Design Patterns">. Although
their original implementation was designed for Java and similar
single-inheritance strictly-typed language, the situation for which it
applies is still valid.

An I<Adapter> in this Perl sense of the term is when a class is created
to achieve by composition (objects containing other object) something that
can't be achieved by inheritance (sub-classing).

This is similar to the I<Decorator> pattern, but is intended to be
applied on a class-by-class basis, as opposed to being able to be applied
one object at a time, as is the case with the I<Decorator> pattern.

The C<Class::Adapter> object holds a parent object that it "wraps",
and when a method is called on the C<Class::Adapter>, it manually
calls the same (or different) method with the same (or different)
parameters on the parent object contained within it.

Instead of these custom methods being hooked in on an object-by-object
basis, they are defined at the class level.

Basically, a C<Class::Adapter> is one of your fall-back positions
when Perl's inheritance model fails you, or is no longer good enough,
and you need to do something twisty in order to make several APIs play
nicely with each other.

=head2 What can I do with the actual Class::Adapter class

Well... nothing really. It exist to provide some extremely low level
fundamental methods, and to provide a common base for inheritance of
Adapter classes.

The base C<Class::Adapter> class doesn't even implement a way to push
method calls through to the underlying object, since the way in which
B<that> happens is the bit that changes from case to case.

To actually DO something, you probably want to go take a look at
L<Class::Adapter::Builder>, which makes the creation of I<Adapter>
classes relatively quick and easy.

=head1 METHODS

The C<Class::Adapter> class itself supplies only the two most common
methods, a default constructor and a private method to access the
underlying object.

=head2 new $object

The default C<new> constructor takes a single object as argument and
creates a new object which holds the passed object.

Returns a new C<Class::Adapter> object, or C<undef> if you do not pass
in an object.

=head2 _OBJECT_

The C<_OBJECT_> method is provided primarily as a convenience, and a tool
for people implementing sub-classes, and allows the C<Class::Adapter>
interface to provide a guaranteed correct way of getting to the underlying
object, should you need to do so.

=head1 TO DO

- Write more comprehensive tests

=head1 SEE ALSO

L<Class::Adapter::Clear>, L<Class::Adapter::Builder>, L<Class::Decorator>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Adapter>
(or L<bug-Class-Adapter@rt.cpan.org|mailto:bug-Class-Adapter@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Adam Kennedy Karen Etheridge gregor herrmann

=over 4

=item *

Adam Kennedy <adam@ali.as>

=item *

Karen Etheridge <ether@cpan.org>

=item *

gregor herrmann <gregoa@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
