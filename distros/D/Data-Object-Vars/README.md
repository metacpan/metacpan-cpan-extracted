# NAME

Data::Object::Vars

# ABSTRACT

Env Vars Class for Perl 5

# SYNOPSIS

    package main;

    use Data::Object::Vars;

    local %ENV = (USER => 'ubuntu', HOME => '/home/ubuntu');

    my $vars = Data::Object::Vars->new(
      named => { iam => 'USER', root => 'HOME' }
    );

    # $vars->root; # $ENV{HOME}
    # $vars->home; # $ENV{HOME}
    # $vars->get('home'); # $ENV{HOME}
    # $vars->get('HOME'); # $ENV{HOME}

    # $vars->iam; # $ENV{USER}
    # $vars->user; # $ENV{USER}
    # $vars->get('user'); # $ENV{USER}
    # $vars->get('USER'); # $ENV{USER}

# DESCRIPTION

This package provides methods for accessing `%ENV` items.

# INTEGRATES

This package integrates behaviors from:

[Data::Object::Role::Buildable](https://metacpan.org/pod/Data::Object::Role::Buildable)

[Data::Object::Role::Proxyable](https://metacpan.org/pod/Data::Object::Role::Proxyable)

[Data::Object::Role::Stashable](https://metacpan.org/pod/Data::Object::Role::Stashable)

# LIBRARIES

This package uses type constraints from:

[Types::Standard](https://metacpan.org/pod/Types::Standard)

# ATTRIBUTES

This package has the following attributes:

## named

    named(HashRef)

This attribute is read-only, accepts `(HashRef)` values, and is optional.

# METHODS

This package implements the following methods:

## exists

    exists(Str $key) : Any

The exists method takes a name or index and returns truthy if an associated
value exists.

- exists example #1

        # given: synopsis

        $vars->exists('iam'); # truthy

- exists example #2

        # given: synopsis

        $vars->exists('USER'); # truthy

- exists example #3

        # given: synopsis

        $vars->exists('PATH'); # falsy

- exists example #4

        # given: synopsis

        $vars->exists('user'); # truthy

## get

    get(Str $key) : Any

The get method takes a name or index and returns the associated value.

- get example #1

        # given: synopsis

        $vars->get('iam'); # ubuntu

- get example #2

        # given: synopsis

        $vars->get('USER'); # ubuntu

- get example #3

        # given: synopsis

        $vars->get('PATH'); # undef

- get example #4

        # given: synopsis

        $vars->get('user'); # ubuntu

## name

    name(Str $key) : Any

The name method takes a name or index and returns index if the the associated
value exists.

- name example #1

        # given: synopsis

        $vars->name('iam'); # USER

- name example #2

        # given: synopsis

        $vars->name('USER'); # USER

- name example #3

        # given: synopsis

        $vars->name('PATH'); # undef

- name example #4

        # given: synopsis

        $vars->name('user'); # USER

## set

    set(Str $key, Maybe[Any] $value) : Any

The set method takes a name or index and sets the value provided if the
associated argument exists.

- set example #1

        # given: synopsis

        $vars->set('iam', 'root'); # root

- set example #2

        # given: synopsis

        $vars->set('USER', 'root'); # root

- set example #3

        # given: synopsis

        $vars->set('PATH', '/tmp'); # undef

        # is not set

- set example #4

        # given: synopsis

        $vars->set('user', 'root'); # root

## stashed

    stashed() : HashRef

The stashed method returns the stashed data associated with the object.

- stashed example #1

        # given: synopsis

        $vars->stashed

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-vars/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-vars/wiki)

[Project](https://github.com/iamalnewkirk/data-object-vars)

[Initiatives](https://github.com/iamalnewkirk/data-object-vars/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-vars/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-vars/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-vars/issues)
