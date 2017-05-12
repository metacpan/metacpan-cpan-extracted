# NAME

Code::TidyAll::Plugin::Test::Vars - Provides Test::Vars plugin for Code::TidyAll

# VERSION

version 0.04

# SYNOPSIS

In your `.tidyallrc` file:

    [Test::Vars]
    select = **/*.pm

# DESCRIPTION

This module uses [Test::Vars](https://metacpan.org/pod/Test::Vars) to detect unused variables in Perl modules.

# CONFIGURATION

- ignore\_file

    This file can be used to ignore particular variables in particulate modules.
    The syntax is as follows:

        Dir::Reader    = $pushed_dir

    Each line contains a module name followed by an equal sign and then the
    name of the variable to ignore.

# SUPPORT

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/Code-TidyAll-Plugin-Test-Vars/issues](https://github.com/maxmind/Code-TidyAll-Plugin-Test-Vars/issues).

# AUTHORS

- Dave Rolsky <drolsky@maxmind.com>
- Greg Oschwald <goschwald@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
