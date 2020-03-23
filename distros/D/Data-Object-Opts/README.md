# NAME

Data::Object::Opts

# ABSTRACT

Opts Class for Perl 5

# SYNOPSIS

    package main;

    use Data::Object::Opts;

    my $opts = Data::Object::Opts->new(
      args => ['--resource', 'users', '--help'],
      spec => ['resource|r=s', 'help|h'],
      named => { method => 'resource' } # optional
    );

    # $opts->method; # $resource
    # $opts->get('resource'); # $resource

    # $opts->help; # $help
    # $opts->get('help'); # $help

# DESCRIPTION

This package provides methods for accessing command-line arguments.

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

## args

    args(ArrayRef[Str])

This attribute is read-only, accepts `(ArrayRef[Str])` values, and is optional.

## named

    named(HashRef)

This attribute is read-only, accepts `(HashRef)` values, and is optional.

## spec

    spec(ArrayRef[Str])

This attribute is read-only, accepts `(ArrayRef[Str])` values, and is optional.

# METHODS

This package implements the following methods:

## exists

    exists(Str $key) : Any

The exists method takes a name or index and returns truthy if an associated
value exists.

- exists example #1

        # given: synopsis

        $opts->exists('resource'); # truthy

- exists example #2

        # given: synopsis

        $opts->exists('method'); # truthy

- exists example #3

        # given: synopsis

        $opts->exists('resources'); # falsy

## get

    get(Str $key) : Any

The get method takes a name or index and returns the associated value.

- get example #1

        # given: synopsis

        $opts->get('resource'); # users

- get example #2

        # given: synopsis

        $opts->get('method'); # users

- get example #3

        # given: synopsis

        $opts->get('resources'); # undef

## name

    name(Str $key) : Any

The name method takes a name or index and returns index if the the associated
value exists.

- name example #1

        # given: synopsis

        $opts->name('resource'); # resource

- name example #2

        # given: synopsis

        $opts->name('method'); # resource

- name example #3

        # given: synopsis

        $opts->name('resources'); # undef

## parse

    parse(Maybe[ArrayRef] $config) : HashRef

The parse method optionally takes additional [Getopt::Long](https://metacpan.org/pod/Getopt::Long) parser
configuration options and retuns the options found based on the object `args`
and `spec` values.

- parse example #1

        # given: synopsis

        $opts->parse;

- parse example #2

        # given: synopsis

        $opts->parse(['bundling']);

## set

    set(Str $key, Maybe[Any] $value) : Any

The set method takes a name or index and sets the value provided if the
associated argument exists.

- set example #1

        # given: synopsis

        $opts->set('method', 'people'); # people

- set example #2

        # given: synopsis

        $opts->set('resource', 'people'); # people

- set example #3

        # given: synopsis

        $opts->set('resources', 'people'); # undef

        # is not set

## stashed

    stashed() : HashRef

The stashed method returns the stashed data associated with the object.

- stashed example #1

        # given: synopsis

        $opts->stashed;

## warned

    warned() : Num

The warned method returns the number of warnings emitted during option parsing.

- warned example #1

        package main;

        use Data::Object::Opts;

        my $opts = Data::Object::Opts->new(
          args => ['-vh'],
          spec => ['verbose|v', 'help|h']
        );

        $opts->warned;

## warnings

    warnings() : ArrayRef[ArrayRef[Str]]

The warnings method returns the set of warnings emitted during option parsing.

- warnings example #1

        package main;

        use Data::Object::Opts;

        my $opts = Data::Object::Opts->new(
          args => ['-vh'],
          spec => ['verbose|v', 'help|h']
        );

        $opts->warnings;

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-opts/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-opts/wiki)

[Project](https://github.com/iamalnewkirk/data-object-opts)

[Initiatives](https://github.com/iamalnewkirk/data-object-opts/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-opts/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-opts/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-opts/issues)
