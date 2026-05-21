# NAME

Apache::Session::Generate::Random - use system randomness for generating session ids

# SYNOPSIS

```perl
use Apache::Session::Flex;

tie %sessions, 'Apache::Session::Flex', $id, {
    Store     => 'Postgres',
    Lock      => 'Null',
    Generate  => 'Random',
    Serialize => 'Base64',
};
```

# DESCRIPTION

This module extends [Apache::Session](https://metacpan.org/pod/Apache%3A%3ASession) to create secure random session ids using the system's source of randomness.

# RECENT CHANGES

Changes for version 0.002002 (2026-05-02)

- Documentation
    - Updated author email address.
- Other
    - Added DOAP metadata to the distribution.
    - Updated distribution metadata.
- Toolchain
    - Stopped signing distributions, because Module::Signature is deprecated.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Crypt::SysRandom](https://metacpan.org/pod/Crypt%3A%3ASysRandom) version 0.007 or later
- [perl](https://metacpan.org/pod/perl) version 5.006 or later
- [strict](https://metacpan.org/pod/strict)
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Apache::Session::Generate::Random
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SUPPORT

Only the latest version of this module will be supported.

This module should work on very old Perl versions, such as v5.6.0.
However, only Perl versions released in the last ten years will be supported.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Apache-Session-Generate-Random/issues](https://github.com/robrwo/perl-Apache-Session-Generate-Random/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Apache-Session-Generate-Random](https://github.com/robrwo/perl-Apache-Session-Generate-Random)
and may be cloned from [https://github.com/robrwo/perl-Apache-Session-Generate-Random.git](https://github.com/robrwo/perl-Apache-Session-Generate-Random.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

[Apache::Session](https://metacpan.org/pod/Apache%3A%3ASession)

[Crypt::SysRandom](https://metacpan.org/pod/Crypt%3A%3ASysRandom)
