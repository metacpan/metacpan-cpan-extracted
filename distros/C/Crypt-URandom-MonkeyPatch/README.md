# NAME

Crypt::URandom::MonkeyPatch - override core rand function to use system random sources

# SYNOPSIS

```perl
use Crypt::URandom::MonkeyPatch;
```

# DESCRIPTION

This module globally overrides the builtin Perl function `rand` with one based on the operating system's cryptographic
random number source, e.g. `/dev/urandom`.

The purpose of this module is monkey patch legacy code that uses `rand` for security purposes.

You can verify that it is working by running code with the `CRYPT_URANDOM_MONKEYPATCH_DEBUG` environment variable set,
e.g.

```perl
local $ENV{CRYPT_URANDOM_MONKEYPATCH_DEBUG} = 1;

my $salt = random_string("........");
```

Every time the `rand` function is called, it will output a line such as

```perl
Crypt::URandom::MonkeyPatch::urandom used from Some::Package line 123
```

# RECENT CHANGES

Changes for version v0.1.2 (2025-09-13)

- Documentation
    - Fixed typos.
    - Updated the security policy.
    - Generated README using the Dzil UsefulReadme plugin.
    - Removed the redundant INSTALL guide.
    - Renamed BUGS to SUPPORT and documented supported versions.
- Tests
    - Added and updated author tests.
    - Moved author tests into the \`xt\` directory.
    - Added missing development prerequisite.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom)
- [constant](https://metacpan.org/pod/constant)
- [perl](https://metacpan.org/pod/perl) version v5.8.0 or later
- [strict](https://metacpan.org/pod/strict)
- [version](https://metacpan.org/pod/version) version 0.77 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Crypt::URandom::MonkeyPatch
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

Only Perl versions released in the past ten (10) years are supported, even though this module may run on earlier versions.

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Crypt-URandom-MonkeyPatch/issues](https://github.com/robrwo/perl-Crypt-URandom-MonkeyPatch/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see `SECURITY.md` for instructions how to
report security vulnerabilities.

# SOURCE

The development version is on github at ["robrwo/perl-Crypt-URandom-MonkeyPatch" in github.com](https://metacpan.org/pod/github.com#robrwo-perl-Crypt-URandom-MonkeyPatch)
and may be cloned from ["robrwo/perl-Crypt-URandom-MonkeyPatch.git" in github.com](https://metacpan.org/pod/github.com#robrwo-perl-Crypt-URandom-MonkeyPatch.git)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Robert Rothenberg <rrwo@cpan.org>.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

[Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom)

[CORE](https://metacpan.org/pod/CORE)

[perlfunc](https://metacpan.org/pod/perlfunc)
