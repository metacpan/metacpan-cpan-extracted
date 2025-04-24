# NAME

Crypt::URandom::MonkeyPatch - override core rand function to use system random sources

# VERSION

version v0.1.1

# SYNOPSIS

```perl
use Crypt::URandom::MonkeyPatch;
```

# DESCRIPTION

This module globlly overrides the builtin Perl function `rand` with one based on the operating system's cryptographic
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

# EXPORTS

## rand

This globally overrides the builtin `rand` function using 31-bits of data from the operating system's random source.

# KNOWN ISSUES

This module is not intended for use with new code, or for use in CPAN modules.  If you are writing new code that needs a
secure souce of random bytes, then use [Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom) or see the [CPAN Author's Guide to Random Data for
Security](https://security.metacpan.org/docs/guides/random-data-for-security.html).

This should only be used when the affected code cannot be updated.

Because this updates the builtin function globally, it may affect other parts of your code.

# SEE ALSO

[Crypt::URandom](https://metacpan.org/pod/Crypt%3A%3AURandom)

[CORE](https://metacpan.org/pod/CORE)

[perlfunc](https://metacpan.org/pod/perlfunc)

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Crypt-URandom-MonkeyPatch](https://github.com/robrwo/perl-Crypt-URandom-MonkeyPatch)
and may be cloned from [git://github.com/robrwo/perl-Crypt-URandom-MonkeyPatch.git](git://github.com/robrwo/perl-Crypt-URandom-MonkeyPatch.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Crypt-URandom-MonkeyPatch/issues](https://github.com/robrwo/perl-Crypt-URandom-MonkeyPatch/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see `SECURITY.md` for instructions how to
report security vulnerabilities.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Robert Rothenberg <rrwo@cpan.org>.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
