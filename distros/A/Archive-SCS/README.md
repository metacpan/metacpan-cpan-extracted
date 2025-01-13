[![build](https://github.com/nautofon/Archive-SCS/actions/workflows/build.yml/badge.svg)](https://github.com/nautofon/Archive-SCS/actions/workflows/build.yml)
[![coverage](https://coveralls.io/repos/github/nautofon/Archive-SCS/badge.svg?branch=main)](https://coveralls.io/github/nautofon/Archive-SCS?branch=main)
[![kwalitee](https://cpants.cpanauthors.org/dist/Archive-SCS.svg)](https://cpants.cpanauthors.org/release/NAUTOFON/Archive-SCS)
[![cpan](https://badge.fury.io/pl/Archive-SCS.svg)](https://metacpan.org/dist/Archive-SCS)
[![perl 5.34](https://img.shields.io/badge/perl-v5.34+-blue.svg)](https://www.perl.org)
[![license](https://img.shields.io/cpan/l/Archive-SCS)](https://raw.githubusercontent.com/nautofon/Archive-SCS/main/LICENSE)
[![discussion](https://img.shields.io/badge/discussion-SCS_forum-e8d78a)](https://forum.scssoft.com/viewtopic.php?t=330746)

## Archive::SCS

This software is a set of Perl modules to read and write the contents
of .scs compressed archive files. It includes the command-line tool
`scs_archive`, which is designed to easily extract files or directories
from SCS archives.
Such archives are primarily used with the
[ATS](https://americantrucksimulator.com/) and
[ETS2](https://eurotrucksimulator2.com/) truck simulator games.

**Decompression and extraction of texture objects in HashFS version 2
archives (1.50+) is currently unimplemented.**

This software is designed for Unix-y systems, i.e. Linux / Mac.
(Users of Windows may be better served with the
[official packer](https://modding.scssoft.com/wiki/Documentation/Tools/Game_Archive_Packer).)

### More information

CPAN distribution:
<https://metacpan.org/dist/Archive-SCS>

Source repository:
<https://github.com/nautofon/Archive-SCS>

Discussion thread on the SCS forum:
<https://forum.scssoft.com/viewtopic.php?t=330746>

### Installation

#### Installing Perl

Archive::SCS requires Perl v5.34 or later.

Your operating system probably comes with Perl pre-installed. Even so,
the general advice these days is to *not* use system Perl, but rather
install Perl yourself into userland. That way you'll not only get the
latest version, but you'll also avoid interfering with the operating
system's own use of Perl.

Building and switching to your own local copy of Perl is quite simple,
for example using [Perlbrew](https://perlbrew.pl/) like this:

```sh
\curl -L https://install.perlbrew.pl | bash
perlbrew install-cpanm
perlbrew install --64int --switch stable
```

You'll also need C and C++ compilers. On a Mac, they're included
in the Command Line Tools for Xcode. The system should prompt you
for installation automatically, or you can do it yourself with
`xcode-select --install`.

For other ways to install Perl, see <https://www.perl.org>.

#### Installing Archive::SCS

The recommended way to install Perl modules is from CPAN by using a
management tool like [cpanminus](https://metacpan.org/pod/App::cpanminus).
Among other things, it will install all dependencies automatically.

```sh
cpanm Archive::SCS

scs_archive --version
```

A good way to test your installation is to do a version check.
That should automatically locate your Steam library and report the
version of the game currently installed on your system.
If your Steam library is in a non-standard location, you may need
to set the `STEAM_LIBRARY` environment variable accordingly.

See the [`scs_archive` man page](https://metacpan.org/dist/Archive-SCS/view/script/scs_archive)
for further usage instructions.

#### Manual install

As an alternative to using an installation tool like `cpanm`, you
can perform a manual install. This should be considered slightly
advanced, in part because you'll need to handle all prerequisites
yourself.

```sh
perl Makefile.PL
make
make test
make install
```

For general information on installing Perl modules, see
<https://www.cpan.org/modules/INSTALL.html>.

### Contributing

Thank you for considering to contribute! Patches and issue reports
are welcome.

For non-trivial patches, I suggest you get in touch with me first,
for example by posting in the
[SCS forum thread](https://forum.scssoft.com/viewtopic.php?t=330746)
(or send a PM to `nautofon`, if you prefer).

### License

Copyright © 2025 [nautofon](https://github.com/nautofon)

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Includes [CityHash](https://github.com/google/cityhash) 1.0.3,
Copyright © 2011 Google, Inc. (MIT license)
