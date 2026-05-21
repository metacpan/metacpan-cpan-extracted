# Alien::ckdl

`Alien::ckdl` downloads, builds, and installs
[ckdl](https://github.com/tjol/ckdl), a small C11 library for reading and
writing [KDL](https://kdl.dev) documents, and exposes it to Perl XS modules
through the standard [Alien::Base](https://metacpan.org/pod/Alien::Base)
interface.

You only need this distribution if you are building a Perl module that
links against `libkdl` from C (the main consumer is
[Text::KDL::XS](https://metacpan.org/pod/Text::KDL::XS)). For pure-Perl
KDL access, install `Text::KDL::XS` and let the dependency chain do its
job.

## What you get

- A statically linked `libkdl.a` (no runtime shared-library dependency).
- The `kdl/*.h` headers under the share directory.
- `cflags` and `libs` strings suitable for a C compiler and linker.
- The upstream `COPYING`, `README.md`, and `CHANGELOG.md` installed
  alongside the library for license compliance.

## Requirements

- Perl 5.12 or newer.
- A working C11 compiler (whatever `perl -V` was built with is fine).
- `ar` (or whatever `$Config{ar}` reports) for archiving the static lib.
- Network access during build to fetch the ckdl source tarball from
  GitHub.

No system-installed `ckdl` is used or detected; the build always compiles
from source. CMake, Python, and Cython are *not* required: the upstream
CMake build is intentionally bypassed and only the seven C source files
that make up `libkdl` are compiled directly with `ExtUtils::CBuilder`.

## Installation

```sh
perl Makefile.PL
make
make test
make install
```

The build fetches
`https://github.com/tjol/ckdl/archive/<SHA>.tar.gz`, extracts it, and
compiles the static library into the Alien share directory. The pinned
commit is set via `$CKDL_COMMIT` in `alienfile`, so builds are
reproducible: the source is pinned, not floating. Each fetch is stamped
with a synthetic version of the form `0.0.0-<first-12-chars-of-sha>`.
To roll forward, edit `$CKDL_COMMIT` in `alienfile`.

## Using it from Perl

```perl
use Alien::ckdl;

print Alien::ckdl->cflags, "\n";  # -I/.../include
print Alien::ckdl->libs,   "\n";  # -L/.../lib -lkdl
```

## Using it from a consumer's `Makefile.PL`

```perl
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME          => 'Text::KDL::XS',
    VERSION_FROM  => 'lib/Text/KDL/XS.pm',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.52',
        'Alien::Build::MM'    => '0.32',
        'Alien::ckdl'         => '0',
    },
    PREREQ_PM => {
        'Alien::ckdl' => '0',
    },
));

sub MY::postamble { $abmm->mm_postamble }
```

`Alien::Build::MM` injects `Alien::ckdl`'s `cflags` and `libs` into the
generated Makefile so that your XS code can `#include <kdl/kdl.h>` and
link against `libkdl` without further configuration.

A minimal XS smoke test is shipped in `t/01-xs-link.t` and is a good
template if you need to verify the Alien works on a target platform.

## Versioning

This Alien pins a specific upstream commit of `tjol/ckdl` rather than
tracking a branch or a tagged release. The Perl distribution version
(in `lib/Alien/ckdl.pm`) identifies the Alien itself; the C library
version it produces is recorded as `0.0.0-<first-12-chars-of-sha>`,
where the SHA is the value of `$CKDL_COMMIT` in `alienfile`.

To move to a different upstream commit, edit `$CKDL_COMMIT` in
`alienfile` and reinstall.

## Troubleshooting

**Build fails with "could not locate extracted ckdl source tree"**
The fetched tarball did not extract into the expected `ckdl-*` directory.
Re-run with `ALIEN_BUILD_PRELOAD=Prefer::FetchAny` or inspect the
contents of `_alien/` to see what was downloaded.

**`make test` fails with linker errors**
Confirm that `make install` of `Alien::ckdl` actually populated the
share directory. `Alien::ckdl->libs` should print a `-L` path that
contains `libkdl.a` (or your platform's equivalent).

**Need a debug build**
Edit `alienfile` and change `-O2` in `extra_compiler_flags` to `-O0 -g`.
A user-facing knob for this is not exposed by design; the Alien is
meant to produce one canonical static library.

## License

This Perl distribution is licensed under the same terms as Perl itself.

The bundled `ckdl` library is distributed under the MIT license. Its
`COPYING` file is installed into the Alien share directory under
`share/doc/ckdl/` for license compliance.

## See also

- [ckdl upstream](https://github.com/tjol/ckdl) - the C library this
  Alien wraps
- [KDL specification](https://github.com/kdl-org/kdl)
- [Alien::Base](https://metacpan.org/pod/Alien::Base) - the framework
  that provides `cflags`, `libs`, and friends
- [Alien::Build](https://metacpan.org/pod/Alien::Build) - the build-time
  half of the same framework
- [Text::KDL::XS](https://github.com/davenonymous/perl-text-kdl-xs) - the Perl XS
  module that consumes this Alien
