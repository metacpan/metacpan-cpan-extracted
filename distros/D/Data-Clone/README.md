[![Actions Status](https://github.com/gfx/p5-Data-Clone/actions/workflows/test.yml/badge.svg)](https://github.com/gfx/p5-Data-Clone/actions)
# NAME

Data::Clone - Polymorphic data cloning

# VERSION

This document describes Data::Clone version 0.006.

# SYNOPSIS

    # as a function
    use Data::Clone;

    my $data   = YAML::Load("foo.yml"); # complex data structure
    my $cloned = clone($data);

    # makes Foo clonable
    package Foo;
    use Data::Clone;
    # ...

    # Foo is clonable
    my $o = Foo->new();
    my $c = clone($o); # $o is deeply copied

    # used for custom clone methods
    package Bar;
    use Data::Clone qw(data_clone);
    sub clone {
        my($proto) = @_;
        my $object = data_clone($proto);
        $object->do_something();
        return $object;
    }
    # ...

    # Bar is also clonable
    $o = Bar->new();
    $c = clone($o); # Bar::clone() is called

# DESCRIPTION

`Data::Clone` does data cloning, i.e. copies things recursively. This is
smart so that it works with not only non-blessed references, but also with
blessed references (i.e. objects). When `clone()` finds an object, it
calls a `clone` method of the object if the object has a `clone`, otherwise
it makes a surface copy of the object. That is, this module does polymorphic
data cloning.

Although there are several modules on CPAN which can clone data,
this module has a different cloning policy from almost all of them.
See ["Cloning policy"](#cloning-policy) and ["Comparison to other cloning modules"](#comparison-to-other-cloning-modules) for
details.

## Cloning policy

A cloning policy is a rule that how a cloning routine copies data. Here is
the cloning policy of `Data::Clone`.

### Non-reference values

Non-reference values are copied normally, which will drop their magics.

### Scalar references

Scalar references including references to other types of references
are **not** copied deeply. They are copied on surface
because it is typically used to refer to something unique, namely
global variables or magical variables.

### Array references

Array references are copied deeply. The cloning policy is applied to each
value recursively.

### Hash references

Hash references are copied deeply. The cloning policy is applied to each
value recursively.

### Glob, IO and Code references

These references are **not** copied deeply. They are copied on surface.

### Blessed references (objects)

Blessed references are **not** copied deeply by default, because objects might
have external resources which `Data::Clone` could not deal with.
They will be copied deeply only if `Data::Clone` knows they are clonable,
i.e. they have a `clone` method.

If you want to make an object clonable, you can use the `clone()` function
as a method:

    package Your::Class;
    use Data::Clone;

    # ...
    my $your_class = Your::Class->new();

    my $c = clone($your_object); # $your_object->clone() will be called

Or you can import `data_clone()` function to define your custom clone method:

    package Your::Class;
    use Data::Clone qw(data_clone);

    sub clone {
        my($proto) = @_;
        my $object = data_clone($proto);
        # anything what you want
        return $object;
    }

Of course, you can use `Clone::clone()`, `Storable::dclone()`, and/or
anything you want as an implementation of `clone` methods.

## Comparison to other cloning modules

There are modules which does data cloning.

`Storable` is a standard module which can clone data with `dclone()`.
It has a different cloning policy from `Data::Clone`. By default it tries
to make a deep copy of all the data including blessed references, but you
can change its behaviour with specific hook methods.

`Clone` is a well-known cloning module, but it does not polymorphic
cloning. This makes a deep copy of data regardless of its types. Moreover, there
is no way to change its behaviour, so this is useful only for data which
link to no external resources.

`Data::Clone` makes a deep copy of data only if it knows that the data are
clonable. You can change its behaviour simply by defining `clone` methods.
It also exceeds `Storable` and `Clone` in performance.

# INTERFACE

## Exported functions

### **clone(Scalar)**

Returns a copy of _Scalar_.

## Exportable functions

### **data\_clone(Scalar)**

Returns a copy of _Scalar_.

The same as `clone()`. Provided for custom clone methods.

### **is\_cloning()**

Returns true inside the `clone()` function, false otherwise.

# DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

# BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

# SEE ALSO

[Storable](https://metacpan.org/pod/Storable)

[Clone](https://metacpan.org/pod/Clone)

# AUTHOR

Goro Fuji (gfx) &lt;gfuji(at)cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
