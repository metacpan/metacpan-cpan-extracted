# NAME

Alien::Brotli - Download and install Brotli compressor

# DESCRIPTION

This distribution installs `brotli`, so that it can be used by other
distributions.

It does this by first trying to detect an existing installation.  If
found, it will use that.  Otherwise, the source will be downloaded
from the official git repository, and it will be installed in a
private share location for the use of other modules.

# RECENT CHANGES

Changes for version v0.2.3 (2026-10-24)

- Security
    - Bumped minimum version of libbrotli to 1.2.1 (CVE-2026-111497)
- Bug Fixes
    - Updated build prerequisites.
    - Build now works with the latest versions of libbrotli.
- Documentation
    - Updated maintainer email addresses.
    - Updated copyright year.
    - README generated from the UsefulReadme dzil plugin.
- Tests
    - Add exe() method to diagnostics (mspacek).
    - Updated author tests, which are now in xt.
- Toolchain
    - Switched from Module::Signature to sigstore.
    - Updated Dist::Zilla configuration.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Alien::Base](https://metacpan.org/pod/Alien%3A%3ABase)
- [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny)
- [base](https://metacpan.org/pod/base)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.14.0 or later
- [strict](https://metacpan.org/pod/strict)
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Alien::Brotli
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

For more information, see the `INSTALL` file included with this distribution.

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Alien-Brotli/issues](https://github.com/robrwo/perl-Alien-Brotli/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Alien-Brotli](https://github.com/robrwo/perl-Alien-Brotli)
and may be cloned from [https://github.com/robrwo/perl-Alien-Brotli.git](https://github.com/robrwo/perl-Alien-Brotli.git)

# AUTHORS

- Robert Rothenberg <perl@rhizomnic.com>
- Michal Josef Špaček <michal.josef.spacek@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022, 2026 by Robert Rothenberg.

This is free software, licensed under:

```
The MIT (X11) License
```

# SEE ALSO

[https://github.com/google/brotli](https://github.com/google/brotli)
