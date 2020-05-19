# NAME

Data::Object::Args - Args Class

# ABSTRACT

Args Class for Perl 5

# SYNOPSIS

    package main;

    use Data::Object::Args;

    local @ARGV = qw(--help execute);

    my $args = Data::Object::Args->new(
      named => { flag => 0, command => 1 }
    );

    # $args->flag; # $ARGV[0]
    # $args->get(0); # $ARGV[0]
    # $args->get(1); # $ARGV[1]
    # $args->action; # $ARGV[1]
    # $args->exists(0); # exists $ARGV[0]
    # $args->exists('flag'); # exists $ARGV[0]
    # $args->get('flag'); # $ARGV[0]

# DESCRIPTION

This package provides methods for accessing `@ARGS` items.

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

        $args->exists(0); # truthy

- exists example #2

        # given: synopsis

        $args->exists('flag'); # truthy

- exists example #3

        # given: synopsis

        $args->exists(2); # falsy

## get

    get(Str $key) : Any

The get method takes a name or index and returns the associated value.

- get example #1

        # given: synopsis

        $args->get(0); # --help

- get example #2

        # given: synopsis

        $args->get('flag'); # --help

- get example #3

        # given: synopsis

        $args->get(2); # undef

## name

    name(Str $key) : Any

The name method takes a name or index and returns index if the the associated
value exists.

- name example #1

        # given: synopsis

        $args->name('flag'); # 0

## set

    set(Str $key, Maybe[Any] $value) : Any

The set method takes a name or index and sets the value provided if the
associated argument exists.

- set example #1

        # given: synopsis

        $args->set(0, '-?'); # -?

- set example #2

        # given: synopsis

        $args->set('flag', '-?'); # -?

- set example #3

        # given: synopsis

        $args->set('verbose', 1); # undef

        # is not set

## stashed

    stashed() : HashRef

The stashed method returns the stashed data associated with the object.

- stashed example #1

        # given: synopsis

        $args->stashed

## unnamed

    unnamed() : ArrayRef

The unnamed method returns an arrayref of values which have not been named
using the `named` attribute.

- unnamed example #1

        package main;

        use Data::Object::Args;

        local @ARGV = qw(--help execute --format markdown);

        my $args = Data::Object::Args->new(
          named => { flag => 0, command => 1 }
        );

        $args->unnamed # ['--format', 'markdown']

- unnamed example #2

        package main;

        use Data::Object::Args;

        local @ARGV = qw(execute phase-1 --format markdown);

        my $args = Data::Object::Args->new(
          named => { command => 1 }
        );

        $args->unnamed # ['execute', '--format', 'markdown']

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-args/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-args/wiki)

[Project](https://github.com/iamalnewkirk/data-object-args)

[Initiatives](https://github.com/iamalnewkirk/data-object-args/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-args/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-args/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-args/issues)
