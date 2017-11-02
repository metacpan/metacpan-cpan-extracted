# NAME

Alien::Build::Plugin::Build::Premake5 - Premake5 build plugin for Alien::Build

# SYNOPSIS

    use alienfile;
    plugin 'Build::Premake5';

# DESCRIPTION

This plugin provides tools to build projects that use premake5. In particular,
it adds the `%{premake5}` helper, which can be used in [alienfile](https://metacpan.org/pod/alienfile) recipes,
and adds a default build stage with the following commands:

    '%{premake} ' . $action,
    '%{make}',
    '%{make} install',

Since premake5 requires gmake, loading this plugin will also load the
[Build::Make](https://metacpan.org/pod/Alien::Build::Plugin::Build::Make)
plugin with its `make_type` option set to "gmake".

# OPTIONS

With the exception of the **action** property, this plugin's options follow
those of the `premake5` client. For more information, consult the client's
documentation.

- **action**

    Specify the action for premake5. This defaults to "gmake", but is only really
    used in the default build phase. If you are providing your own build phase,
    then the value of this property will largely be ignored.

    For a list of valid actions, check the premake5 client's documentation.

## Flags

These flags can only be set to true or false. They will be ignored if false.

- **fatal**

    Treat warnings from project scripts as errors.

- **insecure**

    Forfeit SSH certification checks.

- **verbose**

    Generate extra debug text output.

## Key / value pairs

- **os**

    Generate files for a different operating system. Valid values are
    "aix", "bsd", "haiku", "hurd", "linux", "macosx", "solaris", or "windows".

- **cc**

    Choose a C/C++ compiler set. Valid values are "clang" or "gcc".

- **dc**

    Choose a D compiler. Valid values are "dmd", "gdc", or "ldc".

- **dotnet**

        Choose a .NET compiler set. Valid values are "msnet", "mono", or "pnet".

- **file**

    Read FILE as a premake5 script. The default is `premake5.lua`.

- **scripts**

    Search for additional scripts on the given path.

- **systemscript**

    Override default system script (`premake5-system.lua`).

# METHODS

- **os\_string**

    This method provides a mapping between the `$^O` Perl variable and the
    operating system labels used by premake5. The return values are the same as
    those in the list of valid values for the **os** option.

    If the operating system is not supported, or is impossible to determine, the
    returned value will be the empty string.

# HELPERS

- **premake**
- **premake5**

    The `%{premake5}` is defined by [Alien::premake5](https://metacpan.org/pod/Alien::premake5) to be the executable of
    premake client. This plugin replaces that helper to include any options as
    they were passed to the plugin. It also defines a convenience `%{premake}`
    helper, with the same content.

    Buy default, all options are turned off.

# SEE ALSO

- [https://premake.github.io/](https://premake.github.io/)

# CONTRIBUTIONS AND BUG REPORTS

Contributions of any kind are most welcome!

The main repository for this distribution is on
[Github](https://github.com/jjatria/Alien-Build-Plugin-Build-Premake5), which is
where patches and bug reports are mainly tracked. Bug reports can also be sent
through the CPAN RT system, or by mail directly to the developers at the
addresses below, although these will not be as closely tracked.

# AUTHOR

- José Joaquín Atria <jjatria@cpan.org>

# ACKNOWLEDGEMENTS

Special thanks to Graham Ollis for his help in the preparation of this
distribution.

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
