[![Actions Status](https://github.com/kaz-utashiro/winmaildat2tar/workflows/test/badge.svg)](https://github.com/kaz-utashiro/winmaildat2tar/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-winmaildat2tar.svg)](https://metacpan.org/release/App-winmaildat2tar)
# NAME

winmaildat2tar - Convert winmail.dat (TNEF data) to tentative archive

# VERSION

Version 0.9901

# SYNOPSIS

$ winmaildat2tar winmail.dat > winmail.tar

# DESCRIPTION

This command read `winmail.dat` file in TNEF format and produce
another tentative archive formatted data (tar by default).

- **--format** **tar**|**zip**, **-f** ...

    Specify archive format.  Default is **tar**.  Curretly **tar**, **ar**
    and **zip** are supported.

    If the command is executed as a name of _winmaildat2xxx_, _xxx_ part
    is used as a format name.

# INSTALL

## CPANMINUS

Install from CPAN

    cpanm App::winmaildat2tar

or

    cpanm https://github.com/kaz-utashiro/winmaildat2tar.git

# SEE ALSO

[App::winmaildat2tar](https://metacpan.org/pod/App%3A%3Awinmaildat2tar), [https://github.com/kaz-utashiro/winmaildat2tar](https://github.com/kaz-utashiro/winmaildat2tar)

[Convert::TNEF](https://metacpan.org/pod/Convert%3A%3ATNEF), [Archive::Tar](https://metacpan.org/pod/Archive%3A%3ATar), [Archive::Ar](https://metacpan.org/pod/Archive%3A%3AAr), [Archive::Zip](https://metacpan.org/pod/Archive%3A%3AZip)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2020-2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
