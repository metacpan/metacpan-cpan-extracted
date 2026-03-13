# NAME

App::mailmake - App harness for the mailmake CLI

# SYNOPSIS

Run `mailmake -h` or `perldoc mailmake` for more options.

# VERSION

    v0.1.2

# DESCRIPTION

Tiny distribution wrapper so the `mailmake` CLI can be installed via CPAN.
All functionality is in the `mailmake` script.

# INSTALLATION

## Installing using cpanm

    cpanm App::mailmake

If you do not have `cpanm`, check [App::cpanminus](https://metacpan.org/pod/App%3A%3Acpanminus).

This will install `mailmake` to your bin directory, e.g. `/usr/local/bin`.

## Manual installation

Download from https://metacpan.org/pod/App::mailmake

Extract the archive:

    tar zxvf App-mailmake-v0.1.0.tar.gz

Then build and install:

    cd ./App-mailmake && perl Makefile.PL && make && make test && sudo make install

# DEPENDENCIES

- `v5.16.0`
- `Encode`
- `Getopt::Class`
- `Mail::Make`
- `Module::Generic`
- `Pod::Usage`
- `Term::ANSIColor::Simple`

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[Mail::Make](https://metacpan.org/pod/Mail%3A%3AMake), [Mail::Make::GPG](https://metacpan.org/pod/Mail%3A%3AMake%3A%3AGPG), [Mail::Make::SMIME](https://metacpan.org/pod/Mail%3A%3AMake%3A%3ASMIME)

# COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
