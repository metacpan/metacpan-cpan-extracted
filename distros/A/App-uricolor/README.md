uricolor - Colorize URIs with ANSI colors.
==========================================

SYNOPSIS
--------

    $ uricolor [-hVds] [file ...]

    -h, --help      help
    -V, --version   version
    -d              debug
    -s              schemeless

DESCRIPTION
-----------

uricolor is a Perl script to colorize URIs with ANSI colors.
It reads files sequentially, and writes them to STDOUT,
with all URIs colored (underline blue). If file is a dash "-"
or if no file is given, uricolor reads from STDIN.

INSTALLATION
------------

To install this module automatically from CPAN :

    cpan App::uricolor

To install this module automatically from Git repository :

    cpanm https://github.com/kal247/App-uricolor.git

To install this module manually, run the following commands :

    perl Makefile.PL
    make     
    make test
    make install

PREREQUISITES
-------------

URI::Find, URI::Find::Schemeless, Term::ANSIColor

SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command :

    perldoc uricolor

You can also look for information at :

- CPAN

    [https://metacpan.org/release/App-uricolor](https://metacpan.org/release/App-uricolor)

- GITHUB

    [https://github.com/kal247/App-uricolor](https://github.com/kal247/App-uricolor)

LICENSE AND COPYRIGHT
---------------------

This software is Copyright (c) 2019 by jul.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)