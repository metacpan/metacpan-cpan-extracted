BusyBird: a multi-level Web-based timeline viewer
=================================================

[![Build Status](https://travis-ci.org/debug-ito/busybird.svg?branch=master)](https://travis-ci.org/debug-ito/busybird)

BusyBird is a personal Web-based timeline viewer application.
You can think of it as a Twitter client, but BusyBird is more generic and focused on viewing.

BusyBird accepts data called **Statuses** from its RESTful Web API.
The received statuses are stored to one or more **Timelines** .
You can view those statuses in a timeline by a Web browser.

For more information, visit https://metacpan.org/pod/BusyBird

SCREENSHOTS
-----------

https://github.com/debug-ito/busybird/wiki/Screenshots

QUICK START
-----------

Example in Ubuntu Linux.

- Install `make` and `curl`

        $ sudo apt-get install build-essential curl

- Install

        $ curl -L http://cpanmin.us/ | perl - -n BusyBird
        $ export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB"
        $ export PATH="$HOME/perl5/bin:$PATH"

- Run

        $ busybird
        Twiggy: Accepting connections at http://127.0.0.1:5000/

- Open timelines

        $ firefox http://localhost:5000/

- Post a status

        $ curl -d '{"text":"hello, world!"}' http://localhost:5000/timelines/home/statuses.json

See https://metacpan.org/pod/BusyBird for detail.


TUTORIAL
--------

See https://metacpan.org/pod/BusyBird::Manual::Tutorial


TRY WITHOUT INSTALLATION
------------------------

You can try BusyBird without installing it. This is recommended if you
try a development version. (You need `cpanm` command. See
[App::cpanminus](https://metacpan.org/pod/App::cpanminus) for detail).

    $ git clone https://github.com/debug-ito/busybird.git
    $ cd busybird
    $ cpanm Module::Build::Prereqs::FromCPANfile
    $ cpanm --installdeps .
    $ perl Build.PL
    $ ./Build
    $ ./Build test

...and to start BusyBird, type

    $ perl -Iblib/lib blib/script/busybird


AUTHOR
------

Toshio Ito

* https://github.com/debug-ito
* debug.ito [at] gmail.com


LICENSE
-------

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
