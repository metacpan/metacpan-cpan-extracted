# NAME

Data::Object::Role::Errable

# ABSTRACT

Errable Role for Perl 5

# SYNOPSIS

    package Example;

    use Moo;

    with 'Data::Object::Role::Errable';

    package main;

    my $example = Example->new;

    # $example->error('Oops!')

# DESCRIPTION

This package provides a mechanism for handling errors (exceptions). It's a more
structured approach to being ["throwable"](https://metacpan.org/pod/Data::Object::Role::Throwable). The
idea is that any object that consumes this role can set an error which
automatically throws an exception which if trapped includes the state (object
as thrown) in the exception context.

# INTEGRATES

This package integrates behaviors from:

[Data::Object::Role::Tryable](https://metacpan.org/pod/Data::Object::Role::Tryable)

# LIBRARIES

This package uses type constraints from:

[Data::Object::Types](https://metacpan.org/pod/Data::Object::Types)

# ATTRIBUTES

This package has the following attributes:

## error

    error(ExceptionObject)

This attribute is read-write, accepts `(ExceptionObject)` values, and is optional.

# METHODS

This package implements the following methods:

## error

    error(ExceptionObject $exception | HashRef $options | Str $message) : ExceptionObject

The error method takes an error message (string) or hashref of exception object
constructor attributes and throws an ["exception"](https://metacpan.org/pod/Data::Object::Exception). If
the exception is trapped the exception object will contain the object as the
exception context. The original object will also have the exception set as the
error attribute. The error attribute can be cleared using the `error_reset`
method.

- error example #1

        package main;

        my $example = Example->new;

        $example->error('Oops!');

        # throws exception

- error example #2

        package main;

        my $example = Example->new;

        $example->error({ message => 'Oops!'});

        # throws exception

- error example #3

        package main;

        my $example = Example->new;
        my $exception = Data::Object::Exception->new('Oops!');

        $example->error($exception);

        # throws exception

## error\_reset

    error_reset() : Any

The error\_reset method clears any exception object set on the object.

- error\_reset example #1

        package main;

        my $example = Example->new;

        eval { $example->error('Oops!') };

        $example->error_reset

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-role-errable/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-role-errable/wiki)

[Project](https://github.com/iamalnewkirk/data-object-role-errable)

[Initiatives](https://github.com/iamalnewkirk/data-object-role-errable/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-role-errable/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-role-errable/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-role-errable/issues)
