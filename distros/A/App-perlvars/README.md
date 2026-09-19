# NAME

App::perlvars - CLI tool to detect unused variables in Perl modules

# VERSION

version 0.000008

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

## lint\_scripts

A boolean, false by default. When false, a file without a `package`
declaration is not analyzed (`validate_file` returns a success exit code and a
"contains no package" message). Set it to a true value to also lint
package-less files (most `.t` and `.pl` scripts) as described under
["validate\_file"](#validate_file). It is opt-in because wrapping a file executes its
compile-time code and can surface findings on scripts that were never linted
before.

## validate\_file

Path to a file which will be validated. Returns an exit code, an error message
and a list of unused variables.

When ["lint\_scripts"](#lint_scripts) is true, files without a `package` declaration are
wrapped in a synthetic package and subroutine so the lexicals inside their
named and anonymous subroutines can still be analyzed; reported line numbers
are mapped back to the original file. File-scope (top-level) lexicals are not
reported, matching how [Test::Vars](https://metacpan.org/pod/Test%3A%3AVars) treats file-scope lexicals in a file that
declares a package. Findings in these files are reported against the `main`
package, so an `ignore_file` uses `main` as the package name to suppress a
variable in a package-less file.

Wrapping a file for analysis `require`s it, which executes its compile-time
code (`use` statements and `BEGIN` blocks) even though its runtime statements
do not run. A package-less file that cannot be compiled in isolation -- because
it finds a sibling library at runtime (e.g. [FindBin](https://metacpan.org/pod/FindBin)), depends on a module
that is not installed, or contains a `#line` directive that hides its
subroutines from [Test::Vars](https://metacpan.org/pod/Test%3A%3AVars) -- is skipped silently and returns a success
exit code with no notes.

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
