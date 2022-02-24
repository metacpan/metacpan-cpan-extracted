# NAME

App::perlvars - CLI tool to detect unused variables in Perl modules

# VERSION

version 0.000004

# DESCRIPTION

You probably don't want to use this class directly. See [perlvars](https://metacpan.org/pod/perlvars) for
documentation on how to use the command line interface.

## ignore\_file

The path to a file containing a list of variables to ignore on a per-package
basis. The pattern is `Module::Name = $variable` or `Module::Name = qr/some
regex/`. For example:

    Local::Unused = $unused
    Local::Unused = $one
    Local::Unused = $two
    Local::Unused = qr/^\$.*hree$/

## validate\_file

Path to a file which will be validated. Returns an exit code, an error message
and a list of unused variables.

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
