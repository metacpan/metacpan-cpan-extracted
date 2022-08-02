<div>
    <a href="https://www.perl.org/get.html">
      <img src="https://img.shields.io/badge/perl-5.8.9+-blue.svg"
           alt="Requires Perl 5.8.9+" />
    </a>
    <!-- CPAN -->
    <a href="https://metacpan.org/pod/Alien::libdeflate">
      <img src="https://img.shields.io/cpan/v/Alien-libdeflate.svg"
           alt="CPAN" />
    </a>
    <!-- GitHub Actions -->
    <a href="https://github.com/kiwiroy/alien-libdeflate/actions/workflows/ci.yml">
      <img src="https://github.com/kiwiroy/alien-libdeflate/actions/workflows/ci.yml/badge.svg"
           alt="Build Status" />
    </a>
</div>

# NAME

Alien::libdeflate - Fetch/build/stash the libdeflate headers and libs for
[libdeflate](https://github.com/ebiggers/libdeflate)

# SYNOPSIS

In your `Makefile.PL` with [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils%3A%3AMakeMaker).

    use Alien::libdeflate;
    use ExtUtils::MakeMaker;
    use Alien::Base::Wrapper qw( Alien::libdeflate !export );
    use Config;

    WriteMakefile(
      # ...
      Alien::Base::Wrapper->mm_args,
      # ...
      );

In your script or module.

    use Alien::libdeflate;
    use Env qw( @PATH );

    unshift @PATH, Alien::libdeflate->bin_dir;

# DESCRIPTION

Download, build, and install the libdeflate C headers and libraries into a
well-known location, `Alien::libdeflate->dist_dir`, from whence other
packages can make use of them.

The version installed will be the latest release on the master branch from
the libdeflate GitHub [repository](https://github.com/ebiggers/libdeflate).

## Influential Environment Variables

- ALIEN\_LIBDEFLATE\_PROBE\_CFLAGS

    If _libdeflate_ is installed system wide in an alternate location than the
    default search paths, set this variable to add the **include** directory using
    `-I/path/to/system/libdeflate/include`

- ALIEN\_LIBDEFLATE\_PROBE\_LDFLAGS

    If _libdeflate_ is installed system wide in an alternate location than the
    default search paths, set this variable to add the **lib** directory using
    `-L/path/to/system/libdeflate/lib`

# AUTHORS

Roy Storey (kiwiroy@cpan.org)

Zakariyya Mughal <zmughal@cpan.org>
