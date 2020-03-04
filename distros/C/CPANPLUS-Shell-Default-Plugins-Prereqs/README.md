# NAME

CPANPLUS::Shell::Default::Plugins::Prereqs - Plugin for CPANPLUS to automate the installation of prerequisites without installing the module

# VERSION

version 0.12

# SYNOPSIS

    use CPANPLUS::Shell::Default::Plugin::Prereqs;

    $ cpanp /prereqs <show|list|install> [Module|URL|dir]

# DESCRIPTION

A plugin for CPANPLUS's default shell which will display and/or install any
missing prerequisites for a module. The module can be specified by name, as a
URL or path to the directory of an unpacked module. The plugin assumes the
current directory if no module is specified.

# EXAMPLE COMMAND LINES

The following would list any reprequsites found in the Build.PL or Makefile.PL
for the `MyModule` module:

    $ cd MyModule
    $ cpanp /prereqs show .

Or you could just have given the module name, and `cpanp` will find the the
module on CPAN:

    $ cpanp /prereqs show YAML

And of course you can install the prereqs:

    $ cd MyModule
    $ cpanp /prereqs install .

# SUBROUTINES

The module subroutines are primarily expected to be utilized by the
`CPANPLUS` plugin infrasctructure.

## plugins

Reports the plugin routines provided by this module.

## install\_prereqs

Performs the reqrequsite listing or installation. Conforms to the
`CPANPLUS::Shell::Default::Plugins::HOWTO` API.

## install\_prereqs\_help

Returns the short version documentation for the plugin.

# SEE ALSO

`CPANPLUS`, `CPANPLUS::Shell::Default::Plugins::HOWTO`

# THANKS

Thanks to Jos Boumans for his excellent suggestions to improve both the plugin
functionality and the quality of the code.

# TODO

Add test for MakeMaker and Module::Install based modules. Add test for
/prereq install. Split `install_prereqs` into multiple subroutines.

# AUTHOR

Mark Grimes, <mgrimes@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Mark Grimes, <mgrimes@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
