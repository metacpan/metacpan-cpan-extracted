[![Build Status](https://travis-ci.org/dex4er/PureProxy.png?branch=master)](https://travis-ci.org/dex4er/PureProxy)

# NAME

pureproxy - a Pure Perl HTTP proxy server

# SYNOPSIS

    pureproxy --host=0.0.0.0 --port=5000 --workers=10 --server Starlight

    pureproxy --traffic-log=traffic.log --traffic-log-body-eol='|'

    pureproxy --access-log=access.log

    pureproxy --other-plackup-options

    pureproxy -v

    http_proxy=http://localhost:5000/ lwp-request http://www.perl.org/

    https_proxy=http://localhost:5000/ lwp-request https://metacpan.org/

# DESCRIPTION

This is pure-Perl HTTP proxy server which can be run on almost every Perl
installation.

It supports SSL and TLS if [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL) is installed and IPv6 if
[IO::Socket::IP](https://metacpan.org/pod/IO::Socket::IP) is installed.

It can be fat-packed and then run with any system with standard Perl
interpreter without installing other packages. See `examples` directory
for fat-packed version of PureProxy script.

# ENVIRONMENT

## PUREPROXY\_SERVER

Changes the default PSGI server. This is [Thrall](https://metacpan.org/pod/Thrall) for `MSWin32` and `cygwin`
and [Starlight](https://metacpan.org/pod/Starlight) otherwise.

# INSTALLATION

## With cpanm(1)

    $ cpanm App::PureProxy

## Directly

    $ lwp-request http://git.io/jEE6 | sh

or

    $ curl -kL http://git.io/jEE6 | sh

or

    $ wget --quiet -O- http://git.io/jEE6 | sh

# SEE ALSO

[http://github.com/dex4er/PureProxy](http://github.com/dex4er/PureProxy).

# BUGS

This tool has unstable features and can change in future.

# AUTHOR

Piotr Roszatycki <dexter@cpan.org>

# LICENSE

Copyright (c) 2014-2015 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
