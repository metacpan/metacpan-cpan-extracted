# NAME

Code::TidyAll::Plugin::YAPF - Code::TidyAll plugin to tidy Python code via yapf

# VERSION

version 0.000002

# SYNOPSIS

This module requires [Code::TidyAll](https://metacpan.org/pod/Code::TidyAll).

    In the .tidyallrc configuration file add:

    [YAPF]
    select = **/*.py

Then run

    tidyall -a

# DESCRIPTION

Runs `yapf` on Python files.

- argv

    Arguments to pass to `yapf`.

- cmd

    Full path to `yapf`.

# ACKNOWLEDGEMENTS

Much of this code was copied from [Code::TidyAll::Plugin::JSBeautifier](https://metacpan.org/pod/Code::TidyAll::Plugin::JSBeautifier)

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
