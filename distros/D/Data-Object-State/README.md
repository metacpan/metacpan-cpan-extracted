# NAME

Data::Object::State

# ABSTRACT

Singleton Builder for Perl 5

# SYNOPSIS

    package Example;

    use Data::Object::State;

    has data => (
      is => 'ro'
    );

    package main;

    my $example = Example->new;

# DESCRIPTION

This package provides an abstract base class for creating singleton classes.
This package is derived from [Moo](https://metacpan.org/pod/Moo) and makes consumers Moo classes (with all
that that entails). This package also injects a `BUILD` method which is
responsible for hooking into the build process and returning the appropriate
state.

# METHODS

This package implements the following methods:

## new

    renew() : Object

The new method sets the internal state and returns a new class instance.
Subsequent calls to `new` will return the same instance as was previously
returned.

- new example #1

        package Example::New;

        use Data::Object::State;

        has data => (
          is => 'ro'
        );

        my $example1 = Example::New->new(data => 'a');
        my $example2 = Example::New->new(data => 'b');

        [$example1, $example2]

## renew

    renew() : Object

The renew method resets the internal state and returns a new class instance.
Each call to `renew` will discard the previous state, then reconstruct and
stash the new state as requested.

- renew example #1

        package Example::Renew;

        use Data::Object::State;

        has data => (
          is => 'ro'
        );

        my $example1 = Example::Renew->new(data => 'a');
        my $example2 = $example1->renew(data => 'b');
        my $example3 = Example::Renew->new(data => 'c');

        [$example1, $example2, $example3]

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-state/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-state/wiki)

[Project](https://github.com/iamalnewkirk/data-object-state)

[Initiatives](https://github.com/iamalnewkirk/data-object-state/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-state/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-state/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-state/issues)
