package Browsermob::Server;
$Browsermob::Server::VERSION = '0.17';
# ABSTRACT: Perl client to control the Browsermob Proxy server
use strict;
use warnings;
use Moo;
use Carp;
use JSON;
use LWP::UserAgent;
use IO::Socket::INET;
use Browsermob::Proxy;


has path => (
    is => 'rw',
);


has server_addr => (
    is => 'rw',
    default => sub { 'localhost' }
);


has server_port => (
    is => 'rw',
    init_arg => 'port',
    default => sub { 8080 }
);

has _pid => (
    is => 'rw',
    init_arg => undef,
    default => sub { '' }
);

has ua => (
    is => 'rw',
    lazy => 1,
    default => sub {
        return LWP::UserAgent->new;
    }
);


sub start {
    my $self = shift;
    die '"' . $self->path . '" is an invalid path' unless -f $self->path;

    defined ($self->_pid(fork)) or die "Error starting server: $!";
    if ($self->_pid) {
        # The parent knows about the child pid
        die "Error starting server: $!" unless $self->_is_listening;
    }
    else {
        # If I don't know the pid, then I'm the child and we should
        # exec to replace ourselves with the proxy
        my $cmd = 'sh ' . $self->path . ' -port ' . $self->server_port . ' 2>&1 > /dev/null';
        exec($cmd);
    }
}


sub stop {
    my $self = shift;
    kill('SIGKILL', $self->_pid) and waitpid($self->_pid, 0);
}


sub create_proxy {
    my ($self, %args) = @_;

    my $proxy = Browsermob::Proxy->new(
        server_addr => $self->server_addr,
        server_port => $self->server_port,
        %args
    );

    return $proxy;
}


sub get_proxies {
    my $self = shift;
    my $ua = $self->ua;

    my $res = $ua->get('http://' . $self->server_addr . ':' . $self->server_port . '/proxy');
    if ($res->is_success) {
        my $list = from_json($res->decoded_content)->{proxyList};

        my @proxies = map {
            $_->{port};
        } @$list;

        return \@proxies;
    }

}


sub find_open_port {
    my ($self, @range) = @_;
    my $proxies = $self->get_proxies;

    my $count;
    foreach (@range, @$proxies) {
        $count->{$_}++;
    }

    foreach (sort @range) {
        if ($count->{$_} == 1) {
            return $_;
        }
    }
}


sub _is_listening {
    my ($self, $timeout) = @_;
    $timeout //= 30;

    my $sock = IO::Socket::INET->new(
        PeerAddr => $self->server_addr,
        PeerPort => $self->server_port,
        Timeout => $timeout
    );

    return $sock;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Browsermob::Server - Perl client to control the Browsermob Proxy server

=head1 VERSION

version 0.17

=head1 SYNOPSIS

    my $server = Browsermob::Server->new(
        path => '/opt/browsermob-proxy-2.0-beta-9/bin/browsermob-proxy'
    );
    $server->start;             # ignore if your server is already started

    my $proxy = $server->create_proxy;
    my $port = $proxy->port;

    $proxy->new_har;

    # generate traffic across your port
    `curl -x http://localhost:$port http://www.google.com > /dev/null 2>&1`;

    print Dumper $proxy->har;

=head1 DESCRIPTION

This class provides a way to control the Browsermob Proxy server
within Perl. There are only a few public methods for starting and
stopping the server. You also have the option of instantiating a
server object and pointing it towards an existing BMP server on
localhost, and just using it to avoid having to pass the server_port
arg when instantiating new proxies.

=head1 ATTRIBUTES

=head2 path

The path to the browsermob_proxy binary. If you aren't planning to
call C<start>, this is optional.

=head2 server_addr

The address of the remote server where the Browsermob Proxy server is
running. This defaults to localhost.

=head2 port

The port on which the proxy server should run. This is not the port
that you should have other clients connect.

=head1 METHODS

=head2 start

Start a browsermob proxy on C<port>. Starting the server does not create
any proxies.

=head2 stop

Stop the forked browsermob-proxy server. This does not work all the
time, although the server seems to get GC'd all on its own, even after
ignoring a C<SIGTERM>.

=head2 create_proxy

After starting the server, or connecting to an existing one, use
C<create_proxy> to get a proxy that you can use with your tests. No
proxies actually exist until you call create_proxy; starting the
server does not create a proxy.

    my $proxy = $bmp->create_proxy; # returns a Browsermob::Proxy object
    my $proxy = $bmp->create_proxy(port => 1337);

=head2 get_proxies

Get a list of currently registered proxies.

    my $proxy_aref = $bmp->get_proxies->{proxyList};
    print scalar @$proxy_aref;

=head2 find_open_port

Given a range of valid ports, finds the lowest unused port by
searching the proxyList.

    my $unused_port = $bmp->find_open_port;
    my $proxy = $bmp->create_proxy(port => $unused_port);

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Browsermob::Proxy|Browsermob::Proxy>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/gempesaw/Browsermob-Proxy/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
