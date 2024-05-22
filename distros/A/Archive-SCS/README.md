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
https://metacpan.org/dist/Archive-SCS

Source repository:
https://github.com/nautofon/Archive-SCS

Discussion thread on the SCS forum:
https://forum.scssoft.com/viewtopic.php?t=330746

### Installation

#### Installing Perl

Your operating system probably comes with `perl` pre-installed. Even so,
the general advice these days is to *not* use system `perl`, but rather
install `perl` yourself into userland. That way you'll not only get the
latest version, but you'll also avoid interfering with the operating
system's own use of `perl`.

Installing and switching to your own `perl` is quite simple,
for example using [Perlbrew](https://perlbrew.pl/) like this:

```sh
\curl -L https://install.perlbrew.pl | bash
perlbrew install -j 5 --64int stable
perlbrew switch stable

perlbrew install-cpanm
```

#### Installing Archive::SCS

The recommended way to install Perl modules is from CPAN by using a
management tool like [cpanminus](https://metacpan.org/pod/App::cpanminus).
Among other things, it will install all dependencies automatically.

Currently, Archive::SCS requires a specific version range of the
[String::CityHash](https://metacpan.org/release/ALEXBIO/String-CityHash-0.10/view/lib/String/CityHash.pm)
module, which is only available from BackPAN. Suitable versions
are >= 0.06 and <= 0.10. An easy way to install a version from that
particular range is to point cpanminus directly to one of the tarballs:

```sh
cpanm https://cpan.metacpan.org/authors/id/A/AL/ALEXBIO/String-CityHash-0.10.tar.gz
```

Archive::SCS itself is available on CPAN, so installing it is easy:

```sh
cpanm Archive::SCS

scs_archive --version
scs_archive --extract def/city.sii def/country.sii
scs_archive --help
```

A good way to test your installation is to do a version check.
That should automatically locate your Steam library and report the
version of the game currently installed on your system.

#### Manual install

As an alternative to using an installation tool like `cpanm`, you
can perform a manual install, or use this software directly without
installing it at all. Both options should be considered slightly
advanced, in part because you'll need to handle all prerequisites
yourself.

```sh
# Manual install
perl Makefile.PL
make
make test
make install

# Use the tool without installing
perl -I lib script/scs_archive ...
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

Copyright © 2024 [nautofon](https://github.com/nautofon)

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
