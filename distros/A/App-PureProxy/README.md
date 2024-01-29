# PureProxy

[![CI](https://github.com/dex4er/PureProxy/actions/workflows/ci.yaml/badge.svg)](https://github.com/dex4er/PureProxy/actions/workflows/ci.yaml)
[![Trunk Check](https://github.com/dex4er/PureProxy/actions/workflows/trunk.yaml/badge.svg)](https://github.com/dex4er/PureProxy/actions/workflows/trunk.yaml)
[![CPAN](https://img.shields.io/cpan/v/App-PureProxy)](https://metacpan.org/dist/App-PureProxy)

## NAME

pureproxy - Pure Perl HTTP proxy server

## SYNOPSIS

```sh

    pureproxy --host=0.0.0.0 --port=5000 --workers=10 --server Starlight

    pureproxy --traffic-log=traffic.log --traffic-log-body-eol='|'

    pureproxy --access-log=access.log

    pureproxy --other-plackup-options

    pureproxy -v

    http_proxy=http://localhost:5000/ lwp-request -m get http://www.perl.org/

    https_proxy=http://localhost:5000/ lwp-request -m get https://metacpan.org/

```

## DESCRIPTION

This is pure-Perl HTTP proxy server which can be run on almost every Perl
installation.

It uses [thrall](https://metacpan.org/pod/thrall) pre-threading HTTP server if Perl supports threads or
[starlight](https://metacpan.org/pod/starlight) pre-forking HTTP server otherwise.

It supports SSL and TLS if [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL) is installed and IPv6 if
[IO::Socket::IP](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AIP) is installed.

It can be fat-packed and then run with any system with standard Perl
interpreter without installing other packages. See `examples` directory for
fat-packed version of PureProxy script.

PureProxy is an application that accepts arguments of [plackup](https://metacpan.org/pod/plackup) binary and
HTTP servers like [thrall](https://metacpan.org/pod/thrall) or [starlight](https://metacpan.org/pod/starlight).

## INSTALLATION

## With cpanm(1)

```sh

    cpanm App::PureProxy

```

## Directly

```sh

    lwp-request -m get https://raw.githubusercontent.com/dex4er/PureProxy/master/fatpack/install.sh | sh

```

or

```sh

    curl -qsSL https://raw.githubusercontent.com/dex4er/PureProxy/master/fatpack/install.sh | sh

```

or

```sh

    wget --quiet -O- https://raw.githubusercontent.com/dex4er/PureProxy/master/fatpack/install.sh | sh

```

## OPTIONS

## --access-log

Specifies the pathname of a file where the access log should be
written. By default, in the development environment access logs will
go to STDERR. See [plackup](https://metacpan.org/pod/plackup). (default: none)

## --daemonize

Makes the process run in the background. It doesn't work (yet) in native
Windows (MSWin32). (default: 0)

## -E, --env

Specifies the environment option. See [plackup](https://metacpan.org/pod/plackup). (default: "deployment")

## --error-log

Specify the pathname of a file where the error log should be written. This
enables you to still have access to the errors when using `--daemonize`.
(default: none)

## --group

Changes the group ids or group names that the server should switch to after
binding to the port. The ids or names can be separated with commas or space
characters. (default: none)

## -o, --host

Binds to a TCP interface. Defaults to undef, which lets most server
backends bind to the any (\*) interface. This option is only valid
for servers which support TCP sockets.

## -I

Specifies Perl library include paths, like perl's `-I` option. You
may add multiple paths by using this option multiple times. See [plackup](https://metacpan.org/pod/plackup).

## --ipv6

Enables IPv6 support. The [IO::Socket::IP](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AIP) module is required. (default: 1
if [IO::Socket::IP](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AIP) is available or 0 otherwise)

## --keepalive-timeout

Timeout for persistent connections. (default: 2)

## -L, --loader

Starlet changes the default loader to _Delayed_ to make lower consumption
of the children and prevent problems with shared IO handlers. It might be set to
`Plack::Loader` to restore the default loader.

## -M

Loads the named modules before loading the app's code. You may load
multiple modules by using this option multiple times. See [plackup](https://metacpan.org/pod/plackup).
(default: none)

## --main-process-delay

The Starlight nor Thrall do not synchronize their processes and require a
small delay in main process so it doesn't consume all CPU. (default: 0.1)

## --max-keepalive-reqs

Max. number of requests allowed per single persistent connection. If set to
one, persistent connections are disabled. (default: 1)

## --max-reqs-per-child

Max. number of requests to be handled before a worker process exits. (default:
1000)

## --max-workers

A number of worker threads. (default: 50)

## --min-reqs-per-child

If set, randomizes the number of requests handled by a single worker process
between the value and that supplied by `--max-reqs-per-chlid`.
(default: none)

## -p, --port

Binds to a TCP port. Defaults to 5000. This option is only valid for
servers which support TCP sockets.

Note: default port 5000 may conflict with AirPlay server on MacOS 12
(Monterey) or later.

## --pid

Specify the pid file path. Use it with `-D|--daemonize` option.
(default: none)

## -q, --quiet

Suppress the message about starting a server.

## -r, --reload

Makes plackup restart the server whenever a file in your development
directory changes. See [plackup](https://metacpan.org/pod/plackup). (default: none)

## -R, --Reload

Makes plackup restart the server whenever a file in any of the given
directories changes. See [plackup](https://metacpan.org/pod/plackup). (default: none)

## --socket

Enables UNIX socket support. The [IO::Socket::UNIX](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AUNIX) module is required. The
socket file has to be not yet created. The first character `@` or `\0` in
the socket file name means that an abstract socket address will be created.
(default: none)

## --spawn-interval

If set, worker processes will not be spawned more than once every given
second. Also, when _SIGHUP_ is being received, no more than one worker
process will be collected every given second. This feature is useful for
doing a "slow restart". (default: none)

## --ssl

Enables SSL support. The [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL) module is required. (default: 0)

## --ssl-ca-file

Specifies the path to the SSL CA certificate file which will be a part of
server's certificate chain. (default: none)

## --ssl-cert-file

Specifies the path to the SSL certificate file. (default: none)

## --ssl-client-ca-file

Specifies the path to the SSL CA certificate file for client verification.
(default: none)

## --ssl-key-file

Specifies the path to the SSL key file. (default: none)

## --ssl-verify-mode

Specifies the verification mode for the client certificate.
See ["SSL\_verify\_mode" in IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL#SSL_verify_mode) for details. (default: 0)

## --timeout

Seconds until timeout. (default: 300)

## --traffic-log

Enables [Plack::Middleware::TrafficLog](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3ATrafficLog) middleware that logs detailed
information about headers and the body.

If the filename is providen then middleware writes to this file. Standard
output is used otherwise.

## --traffic-log-body-eol

Sets the line separator for message's body for log generated by
[Plack::Middleware::TrafficLog](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3ATrafficLog) middleware.

## --umask

Changes file mode creation mask. The ["umask" in perlfunc](https://metacpan.org/pod/perlfunc#umask) is an octal number
representing disabled permissions bits for newly created files. It is usually
`022` when a group shouldn't have permission to write or `002` when a group
should have permission to write. (default: none)

## --user

Changes the user id or user name that the server process should switch to
after binding to the port. The pid file, error log or unix socket also are
created before changing privileges. This option is usually used if the main
process is started with root privileges because binding to the low-numbered
(<1024) port. (default: none)

## ENVIRONMENT

## PUREPROXY\_SERVER

Changes the default PSGI server. This is [Thrall](https://metacpan.org/pod/Thrall) if Perl supports threads
and [Starlight](https://metacpan.org/pod/Starlight) otherwise.

## SEE ALSO

[http://github.com/dex4er/PureProxy](http://github.com/dex4er/PureProxy).

## BUGS

This tool has unstable features and can change in future.

## AUTHOR

Piotr Roszatycki <dexter@cpan.org>

## LICENSE

Copyright (c) 2014-2015, 2023-2024 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
