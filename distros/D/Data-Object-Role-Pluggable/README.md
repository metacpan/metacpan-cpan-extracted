# NAME

Data::Object::Role::Pluggable

# ABSTRACT

Pluggable Role for Perl 5

# SYNOPSIS

    package Example;

    use Data::Object::Class;

    with 'Data::Object::Role::Pluggable';

    package main;

    my $example = Example->new;

# DESCRIPTION

This package provides a mechanism for dispatching to plugin classes.

# METHODS

This package implements the following methods:

## plugin

    plugin(Str $name, Any @args) : InstanceOf['Data::Object::Plugin']

The plugin method returns an instantiated plugin class whose namespace is based
on the package name of the calling class and the `$name` argument provided. If
the plugin cannot be loaded this method will cause the program to crash.

- plugin example #1

        # given: synopsis

        package Example::Plugin::Formatter;

        use Data::Object::Class;

        extends 'Data::Object::Plugin';

        has name => (
          is => 'ro'
        );

        package main;

        $example->plugin(formatter => (name => 'lorem'));

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-role-functable/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-role-functable/wiki)

[Project](https://github.com/iamalnewkirk/data-object-role-functable)

[Initiatives](https://github.com/iamalnewkirk/data-object-role-functable/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-role-functable/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-role-functable/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-role-functable/issues)
