# NAME

Class::ErrorHandler - Base class for error handling

# SYNOPSIS

    package Foo;
    use base qw( Class::ErrorHandler );

    sub class_method {
        my $class = shift;
        ...
        return $class->error("Help!")
            unless $continue;
    }

    sub object_method {
        my $obj = shift;
        ...
        return $obj->error("I am no more")
            unless $continue;
    }

    package main;
    use Foo;

    Foo->class_method or die Foo->errstr;

    my $foo = Foo->new;
    $foo->object_method or die $foo->errstr;

# DESCRIPTION

_Class::ErrorHandler_ provides an error-handling mechanism that's generic
enough to be used as the base class for a variety of OO classes. Subclasses
inherit its two error-handling methods, _error_ and _errstr_, to
communicate error messages back to the calling program.

On failure (for whatever reason), a subclass should call _error_ and return
to the caller; _error_ itself sets the error message internally, then
returns `undef`. This has the effect of the method that failed returning
`undef` to the caller. The caller should check for errors by checking for a
return value of `undef`, and calling _errstr_ to get the value of the
error message on an error.

As demonstrated in the [SYNOPSIS](https://metacpan.org/pod/SYNOPSIS), _error_ and _errstr_ work as both class
methods and object methods.

# USAGE

## Class->error($message)

## $object->error($message)

Sets the error message for either the class _Class_ or the object
_$object_ to the message _$message_. Returns `undef`.

## Class->errstr

## $object->errstr

Accesses the last error message set in the class _Class_ or the
object _$object_, respectively, and returns that error message.

# LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHOR & COPYRIGHT

Except where otherwise noted, _Class::ErrorHandler_ is Copyright 2004
Benjamin Trott, cpan@stupidfool.org. All rights reserved.
