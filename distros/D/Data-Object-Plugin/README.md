# NAME

Data::Object::Plugin

# ABSTRACT

Plugin Class for Perl 5

# SYNOPSIS

    package Plugin;

    use Data::Object::Class;

    extends 'Data::Object::Plugin';

    package main;

    my $plugin = Plugin->new;

# DESCRIPTION

This package provides an abstract base class for defining plugin classes.

# METHODS

This package implements the following methods:

## execute

    execute() : Any

The execute method is the main method and entrypoint for plugin classes.

- execute example #1

        # given: synopsis

        $plugin->execute

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-plugin/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-plugin/wiki)

[Project](https://github.com/iamalnewkirk/data-object-plugin)

[Initiatives](https://github.com/iamalnewkirk/data-object-plugin/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-plugin/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-plugin/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-plugin/issues)
