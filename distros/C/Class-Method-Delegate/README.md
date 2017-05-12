Class-Method-Delegate
=====================

Class::Method::Delegate - Perl extension to help you add delegation to your classes

Synopsis
--------

    use Class::Method::Delegate;
    use Package::To::Delegate::To;
    delegate methods => [ 'hello', 'goodbye' ], to => sub { Package::To::Delegate::To->new() };
    delegate methods => [ 'wave' ], to => sub { shift->{gestures} };
    delegate methods => [ 'walk', 'run' ], to => sub { shift->{movements} ||= Package::To::Delegate::To->new() };

    delegate methods => [ 'walk', 'run' ], to => \&some_subroutine, handlers => [ 'slow', 'fast' ];

Description
-----------

Creates methods on the current class which delegate to an object.

delegate takes a hash or hashref with the following keys.

### methods

Takes an array ref of strings that represent the name of the method to be delegated.

### to

a sub block that returns an object, which the method calls will be sent to.

Accessing the parent from inside the delegated class.
-----------------------------------------------------

If the object you are delegating to has a method called delegated_by, then this will be called when delegating.
The $self of the package doing the delegating will be passed in, so you can then store it.

