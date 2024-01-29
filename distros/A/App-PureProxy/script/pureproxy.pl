#!/usr/bin/perl

use strict;
use warnings;

no warnings;

our $VERSION = '0.0200';

BEGIN {
    if ($INC[0] =~ /^FatPacked::/) {
        require Clone::PP;
        $INC{'Clone.pm'} = $INC{'Clone/PP.pm'};
    }
}

INIT {
    if ($^O eq 'darwin' && $ENV{OBJC_DISABLE_INITIALIZE_FORK_SAFETY} ne 'YES') {
        $ENV{OBJC_DISABLE_INITIALIZE_FORK_SAFETY} = 'YES';
        exec $^X, $0, @ARGV;
    }
}

BEGIN {
    *warnings::import = sub { };
}

use Config;

use constant SERVER => $ENV{PUREPROXY_SERVER}
    || $Config{useithreads} ? 'Thrall' : 'Starlight';

BEGIN {
    delete $ENV{http_proxy};
    delete $ENV{https_proxy};
}

use Plack::Builder;
use Plack::App::Proxy;

my $app = builder {
    enable 'Proxy::Connect::IO';
    enable 'Proxy::Requests';
    Plack::App::Proxy->new(backend => 'HTTP::Tiny')->to_app;
};

use Plack;
use Plack::Runner;

my $runner = Plack::Runner->new(server => SERVER, env => 'proxy', loader => 'Plack::Loader', version_cb => \&version,);

sub _version () {
    my $server = $runner->{server};
    my $server_version
        = eval  { Plack::Util::load_class($server);                   $server->VERSION }
        || eval { Plack::Util::load_class("Plack::Handler::$server"); "Plack::Handler::$server"->VERSION }
        || 0;
    return "PureProxy/$VERSION $server/$server_version Plack/" . Plack->VERSION . " Perl/$] ($^O)";
}

sub version {
    my ($class) = @_;
    print _version(), "\n";
}

$runner->parse_options('--max-workers=50', @ARGV);

if ($runner->{help}) {
    require Pod::Usage;
    Pod::Usage::pod2usage(-verbose => 99, -sections => "NAME|SYNOPSIS|DESCRIPTION|OPTIONS", -input => \*DATA);
}

my %options = @{ $runner->{options} };

if ($options{traffic_log}) {
    my $body_eol = $options{traffic_log_body_eol};
    if ($options{traffic_log} ne '1') {
        open my $logfh, ">>", $options{traffic_log} or die "open($options{traffic_log}): $!";
        $logfh->autoflush(1);
        $app = builder {
            enable 'TrafficLog',
                logger    => sub { $logfh->print(@_) },
                body_eol  => $body_eol,
                with_body => !!$body_eol;
            $app;
        };
    } else {
        $app = builder { enable 'TrafficLog', body_eol => $body_eol, with_body => !!$body_eol; $app; };
    }
}

if (not defined $runner->{access_log} or $runner->{access_log} eq '1') {
    $runner->{access_log} = undef;
    $app = builder { enable 'AccessLog'; $app; };
}

push @{ $runner->{options} }, 'server_software', _version();

$runner->run($app);

__DATA__

=head1 NAME

pureproxy - Pure Perl HTTP proxy server

=head1 SYNOPSIS

=for markdown ```sh

    pureproxy --host=0.0.0.0 --port=5000 --workers=10 --server Starlight

    pureproxy --traffic-log=traffic.log --traffic-log-body-eol='|'

    pureproxy --access-log=access.log

    pureproxy --other-plackup-options

    pureproxy -v

    http_proxy=http://localhost:5000/ lwp-request -m get http://www.perl.org/

    https_proxy=http://localhost:5000/ lwp-request -m get https://metacpan.org/

=for markdown ```

=head1 DESCRIPTION

This is pure-Perl HTTP proxy server which can be run on almost every Perl
installation.

It uses L<thrall> pre-threading HTTP server if Perl supports threads or
L<starlight> pre-forking HTTP server otherwise.

It supports SSL and TLS if L<IO::Socket::SSL> is installed and IPv6 if
L<IO::Socket::IP> is installed.

It can be fat-packed and then run with any system with standard Perl
interpreter without installing other packages. See F<examples> directory for
fat-packed version of PureProxy script.

PureProxy is an application that accepts arguments of L<plackup> binary and
HTTP servers like L<thrall> or L<starlight>.

=cut

__END__

=head1 INSTALLATION

=head2 With cpanm(1)

=for markdown ```sh

    cpanm App::PureProxy

=for markdown ```

=head2 Directly

=for markdown ```sh

    lwp-request -m get https://raw.githubusercontent.com/dex4er/PureProxy/master/fatpack/install.sh | sh

=for markdown ```

or

=for markdown ```sh

    curl -qsSL https://raw.githubusercontent.com/dex4er/PureProxy/master/fatpack/install.sh | sh

=for markdown ```

or

=for markdown ```sh

    wget --quiet -O- https://raw.githubusercontent.com/dex4er/PureProxy/master/fatpack/install.sh | sh

=for markdown ```

=head1 OPTIONS

=head2 --access-log

Specifies the pathname of a file where the access log should be
written. By default, in the development environment access logs will
go to STDERR. See L<plackup>. (default: none)

=head2 --daemonize

Makes the process run in the background. It doesn't work (yet) in native
Windows (MSWin32). (default: 0)

=head2 -E, --env

Specifies the environment option. See L<plackup>. (default: "deployment")

=head2 --error-log

Specify the pathname of a file where the error log should be written. This
enables you to still have access to the errors when using C<--daemonize>.
(default: none)

=head2 --group

Changes the group ids or group names that the server should switch to after
binding to the port. The ids or names can be separated with commas or space
characters. (default: none)

=head2 -o, --host

Binds to a TCP interface. Defaults to undef, which lets most server
backends bind to the any (*) interface. This option is only valid
for servers which support TCP sockets.

=head2 -I

Specifies Perl library include paths, like perl's C<-I> option. You
may add multiple paths by using this option multiple times. See L<plackup>.

=head2 --ipv6

Enables IPv6 support. The L<IO::Socket::IP> module is required. (default: 1
if L<IO::Socket::IP> is available or 0 otherwise)

=head2 --keepalive-timeout

Timeout for persistent connections. (default: 2)

=head2 -L, --loader

Starlet changes the default loader to I<Delayed> to make lower consumption
of the children and prevent problems with shared IO handlers. It might be set to
C<Plack::Loader> to restore the default loader.

=head2 -M

Loads the named modules before loading the app's code. You may load
multiple modules by using this option multiple times. See L<plackup>.
(default: none)

=head2 --main-process-delay

The Starlight nor Thrall do not synchronize their processes and require a
small delay in main process so it doesn't consume all CPU. (default: 0.1)

=head2 --max-keepalive-reqs

Max. number of requests allowed per single persistent connection. If set to
one, persistent connections are disabled. (default: 1)

=head2 --max-reqs-per-child

Max. number of requests to be handled before a worker process exits. (default:
1000)

=head2 --max-workers

A number of worker threads. (default: 50)

=head2 --min-reqs-per-child

If set, randomizes the number of requests handled by a single worker process
between the value and that supplied by C<--max-reqs-per-chlid>.
(default: none)

=head2 -p, --port

Binds to a TCP port. Defaults to 5000. This option is only valid for
servers which support TCP sockets.

Note: default port 5000 may conflict with AirPlay server on MacOS 12
(Monterey) or later.

=head2 --pid

Specify the pid file path. Use it with C<-D|--daemonize> option.
(default: none)

=head2 -q, --quiet

Suppress the message about starting a server.

=head2 -r, --reload

Makes plackup restart the server whenever a file in your development
directory changes. See L<plackup>. (default: none)

=head2 -R, --Reload

Makes plackup restart the server whenever a file in any of the given
directories changes. See L<plackup>. (default: none)

=head2 --socket

Enables UNIX socket support. The L<IO::Socket::UNIX> module is required. The
socket file has to be not yet created. The first character C<@> or C<\0> in
the socket file name means that an abstract socket address will be created.
(default: none)

=head2 --spawn-interval

If set, worker processes will not be spawned more than once every given
second. Also, when I<SIGHUP> is being received, no more than one worker
process will be collected every given second. This feature is useful for
doing a "slow restart". (default: none)

=head2 --ssl

Enables SSL support. The L<IO::Socket::SSL> module is required. (default: 0)

=head2 --ssl-ca-file

Specifies the path to the SSL CA certificate file which will be a part of
server's certificate chain. (default: none)

=head2 --ssl-cert-file

Specifies the path to the SSL certificate file. (default: none)

=head2 --ssl-client-ca-file

Specifies the path to the SSL CA certificate file for client verification.
(default: none)

=head2 --ssl-key-file

Specifies the path to the SSL key file. (default: none)

=head2 --ssl-verify-mode

Specifies the verification mode for the client certificate.
See L<IO::Socket::SSL/SSL_verify_mode> for details. (default: 0)

=head2 --timeout

Seconds until timeout. (default: 300)

=head2 --traffic-log

Enables L<Plack::Middleware::TrafficLog> middleware that logs detailed
information about headers and the body.

If the filename is providen then middleware writes to this file. Standard
output is used otherwise.

=head2 --traffic-log-body-eol

Sets the line separator for message's body for log generated by
L<Plack::Middleware::TrafficLog> middleware.

=head2 --umask

Changes file mode creation mask. The L<perlfunc/umask> is an octal number
representing disabled permissions bits for newly created files. It is usually
C<022> when a group shouldn't have permission to write or C<002> when a group
should have permission to write. (default: none)

=head2 --user

Changes the user id or user name that the server process should switch to
after binding to the port. The pid file, error log or unix socket also are
created before changing privileges. This option is usually used if the main
process is started with root privileges because binding to the low-numbered
(E<lt>1024) port. (default: none)

=head1 ENVIRONMENT

=head2 PUREPROXY_SERVER

Changes the default PSGI server. This is L<Thrall> if Perl supports threads
and L<Starlight> otherwise.

=head1 SEE ALSO

L<http://github.com/dex4er/PureProxy>.

=head1 BUGS

This tool has unstable features and can change in future.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2014-2015, 2023-2024 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
