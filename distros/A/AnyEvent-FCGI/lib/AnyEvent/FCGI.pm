package AnyEvent::FCGI;

=head1 NAME

AnyEvent::FCGI - non-blocking FastCGI server

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::FCGI;

    my $fcgi = new AnyEvent::FCGI(
        port => 9000,
        on_request => sub {
            my $request = shift;
            $request->respond(
                'OH HAI! QUERY_STRING is ' . $request->param('QUERY_STRING'),
                'Content-Type' => 'text/plain',
            );
        }
    );

    my $timer = AnyEvent->timer(
        after => 10,
        interval => 0,
        cb => sub {
            # shut down server after 10 seconds
            $fcgi = undef;
        }
    );

    AnyEvent->loop;

=head1 DESCRIPTION

This module implements non-blocking FastCGI server for event based applications.

=cut

use strict;
use warnings;

our $VERSION = '0.04';

use Scalar::Util qw/weaken refaddr/;

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::FCGI::Connection;

use constant FCGI_VERSION_1 => 1;

use constant FCGI_BEGIN_REQUEST => 1;
use constant FCGI_ABORT_REQUEST => 2;
use constant FCGI_END_REQUEST => 3;
use constant FCGI_PARAMS => 4;
use constant FCGI_STDIN => 5;
use constant FCGI_STDOUT => 6;
use constant FCGI_STDERR => 7;

use constant FCGI_RESPONDER => 1;

use constant FCGI_KEEP_CONN => 1;

use constant FCGI_REQUEST_COMPLETE => 0;
use constant FCGI_OVERLOADED => 2;
use constant FCGI_UNKNOWN_ROLE => 3;

=head1 METHODS

=head2 new

This function creates a new FastCGI server and returns a new instance of a C<AnyEvent::FCGI> object.
To shut down the server just remove all references to this object.

=head3 PARAMETERS

=over 4

=item port => $port

The TCP port the FastCGI server will listen on.

=item host => $host

The TCP address of the FastCGI server will listen on.
If undefined 0.0.0.0 will be used.

=item socket => $path

Path to UNIX domain socket to listen. If specified, C<host> and C<port> parameters ignored.

=item on_request => sub { }

Reference to a handler to call when a new FastCGI request is received.
It will be invoked as

    $on_request->($request)

where C<$request> will be a new L<AnyEvent::FCGI::Request> object.

=item backlog => $backlog

Optional. Integer number of socket backlog (listen queue)

=back

=cut

sub new {
    my ($class, %params) = @_;

    my $self = bless {
        connections => {},
        on_request_cb => $params{on_request},
    }, $class;

    my $fcgi = $self;
    weaken($fcgi);

    $params{socket} ||= $params{unix};

    $self->{server} = tcp_server(
        $params{socket} ? 'unix/' : $params{host},
        $params{socket} || $params{port},
        sub {$fcgi->_on_accept(shift)},
        $params{backlog} ? sub {$params{backlog}} : undef
    );

    return $self;
}

sub _on_accept {
    my ($self, $fh) = @_;

    if ($fh) {
        my $connection = new AnyEvent::FCGI::Connection(fcgi => $self, fh => $fh);

        $self->{connections}->{refaddr($connection)} = $connection;
    }
}

sub _request_ready {
    my ($self, $request) = @_;

    $self->{on_request_cb}->($request);
}

sub DESTROY {
    my ($self) = @_;

    if ($self) {
        $self->{connections} = {};
    }
}

=head1 SEE ALSO

L<AnyEvent>, L<AnyEvent::FCGI::Request>

This module based on L<FCGI::Async> and L<FCGI::EV>.

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 AUTHOR

Vitaly Kramskikh, E<lt>vkramskih@cpan.orgE<gt>

=cut

1;
