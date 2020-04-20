# NAME

Data::Object::Kind

# ABSTRACT

Abstract Base Class for Data::Object Value Classes

# SYNOPSIS

    package Data::Object::Hash;

    use base 'Data::Object::Kind';

    sub new {
      bless {};
    }

    package main;

    my $hash = Data::Object::Hash->new;

# DESCRIPTION

This package provides methods common across all [Data::Object](https://metacpan.org/pod/Data::Object) value classes.

# LIBRARIES

This package uses type constraints from:

[Data::Object::Types](https://metacpan.org/pod/Data::Object::Types)

# METHODS

This package implements the following methods:

## class

    class() : Str

The class method returns the class name for the given class or object.

- class example #1

        # given: synopsis

        $hash->class; # Data::Object::Hash

## detract

    detract() : Any

The detract method returns the raw data value for a given object.

- detract example #1

        # given: synopsis

        $hash->detract; # {}

## space

    space() : SpaceObject

The space method returns a [Data::Object::Space](https://metacpan.org/pod/Data::Object::Space) object for the given object.

- space example #1

        # given: synopsis

        $hash->space; # <Data::Object::Space>

## type

    type() : Str

The type method returns object type string.

- type example #1

        # given: synopsis

        $hash->type; # HASH

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/foobar/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/foobar/wiki)

[Project](https://github.com/iamalnewkirk/foobar)

[Initiatives](https://github.com/iamalnewkirk/foobar/projects)

[Milestones](https://github.com/iamalnewkirk/foobar/milestones)

[Contributing](https://github.com/iamalnewkirk/foobar/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/foobar/issues)
