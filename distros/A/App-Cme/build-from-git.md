# How to build App::Cme from git repository

`App::Cme` is build with [Dist::Zilla](http://dzil.org/). This
pages details how to install the tools and dependencies required to
build this module.

## Install tools and dependencies

### Debian, Ubuntu and derivatives

Run

    $ sudo apt install libdist-zilla-perl libdist-zilla-app-command-authordebs-perl
    $ dzil authordebs --install
    $ sudo apt build-dep cme

### Other systems

Run 

    $ cpamn Dist::Zilla
    $ dzil authordeps -missing | cpanm --notest
    $ dzil listdeps --missing | cpanm --notest

NB: The author would welcome pull requests that explains how to
install these tools and dependencies using native package of other
distributions.

## Build App::Cme

Run

    dzil build 

or 

    dzil test

`dzil` may also return an error like `Cannot determine local time
zone`. In this case, you should specify explicitely your timezone in
a `TZ` environement variable. E.g run `dzil` this way:

    TZ="Europe/Paris" dzil test

The list of possible timezones is provided by
[DateTime::TimeZone::Catalog](https://metacpan.org/pod/DateTime::TimeZone::Catalog)
documentation.

