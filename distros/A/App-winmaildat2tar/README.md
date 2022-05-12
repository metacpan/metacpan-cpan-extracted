[![Actions Status](https://github.com/kaz-utashiro/winmaildat2tar/workflows/test/badge.svg)](https://github.com/kaz-utashiro/winmaildat2tar/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-winmaildat2tar.svg)](https://metacpan.org/release/App-winmaildat2tar)
# NAME

winmaildat2tar - Convert winmail.dat (TNEF data) to tentative archive

# VERSION

Version 0.99

# SYNOPSIS

$ winmaildat2tar winmail.dat > winmail.tar

# DESCRIPTION

This command read `winmail.dat` file in TNEF format and produce
another tentative archive formatted data (tar by default).

- **--format** _format_, **-f** ...

    Specify archive format from **tar**, **ar** or **zip**.
    Default is **tar**.

# INSTALL

## CPANMINUS

To get the latest code, use this:

    cpanm App-winmaildat2tar

or

    cpanm https://github.com/kaz-utashiro/winmaildat2tar.git

# SEE ALSO

[https://github.com/kaz-utashiro/winmaildat2tar](https://github.com/kaz-utashiro/winmaildat2tar)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2020-2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
