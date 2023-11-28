![hack.exe in action](../flair/demo.gif)

# App::Hack::Exe

A script that simulates a "hacking program", as often seen in movies.

To run:

```sh
hack.exe <HOSTNAME>
```

e.g.:

```sh
hack.exe google.com
```

## Installation

The simplest way to install `App::Hack::Exe` is via `cpanm`:

```sh
cpanm App::Hack::Exe
```

One can also install from source by first cloning the repository:

```sh
git clone https://codeberg.org/h3xx/perl-App-Hack-Exe.git
```

then installing the build dependencies:

```sh
cpanm Carp Socket Term::ANSIColor Time::HiRes
```

followed by the usual build and test steps:

```sh
perl Makefile.PL
make
make test
```

If all went well, you can now install the distribution by running:

```sh
make install
```

## Author

- Dan Church (h3xx[attyzatzat]gmx[dottydot]com)

## License and Copyright

Copyright (C) 2023 Dan Church.

This library is free software; you can redistribute it and/or modify it under
the [same terms as Perl itself](https://dev.perl.org/licenses/).

## Thanks

Thanks to janbrennen's [original idea](https://github.com/janbrennen/rice/blob/master/hack.exe.c).
