package AnyEvent::WebSocket::Server;
use strict;
use warnings;
use Carp;
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Server;
use Try::Tiny;
use AnyEvent::WebSocket::Connection;

our $VERSION = "0.09";

sub new {
    my ($class, %args) = @_;
    my $validator = $args{validator};
    if(defined($validator) && ref($validator) ne "CODE") {
        croak "validator parameter must be a code-ref";
    }
    my $handshake = defined($args{handshake}) ? $args{handshake}
        : defined($validator) ? sub { my ($req, $res) = @_; return ($res, $validator->($req)); }
        : sub { $_[1] };
    if(ref($handshake) ne "CODE") {
        croak "handshake parameter must be a code-ref";
    }
    my $self = bless {
        handshake => $handshake,
        map { ($_ => $args{$_}) } qw(ssl_key_file ssl_cert_file max_payload_size),
    }, $class;
    return $self;
}

sub _create_on_error {
    my ($cv) = @_;
    return sub {
        my ($handle, $fatal, $message) = @_;
        if($fatal) {
            $cv->croak("connection error: $message");
        }else {
            warn $message;
        }
    };
}

sub _handle_args_tls {
    my ($self) = @_;
    if(!defined($self->{ssl_key_file}) && !defined($self->{ssl_cert_file})) {
        return ();
    }
    if(!defined($self->{ssl_cert_file})) {
        croak "Only ssl_key_file is specified. You need to specify ssl_cert_file, too.";
    }
    return (
        tls => "accept",
        tls_ctx => {
            cert_file => $self->{ssl_cert_file},
            defined($self->{ssl_key_file}) ? (key_file => $self->{ssl_key_file}) : ()
        }
    );
}

sub _do_handshake {
    my ($self, $cv_connection, $fh, $handshake) = @_;
    my $handshake_code = $self->{handshake};
    my $handle = AnyEvent::Handle->new(
        $self->_handle_args_tls,
        fh => $fh, on_error => _create_on_error($cv_connection)
    );
    my $read_cb = sub {
        ## We don't receive handle object as an argument here. $handle
        ## is imported in this closure so that $handle becomes
        ## half-immortal.
        try {
            if(!defined($handshake->parse($handle->{rbuf}))) {
                die "handshake error: " . $handshake->error . "\n";
            }
            return if !$handshake->is_done;
            if($handshake->version ne "draft-ietf-hybi-17") {
                die "handshake error: unsupported WebSocket protocol version " . $handshake->version . "\n";
            }
            my ($res, @other_results) = $handshake_code->($handshake->req, $handshake->res);
            if(!defined($res)) {
                croak "handshake response was undef";
            }
            if(ref($res) eq "Protocol::WebSocket::Response") {
                $res = $res->to_string;
            }
            $handle->push_write("$res");
            $cv_connection->send(
                AnyEvent::WebSocket::Connection->new(handle => $handle, max_payload_size => $self->{max_payload_size}),
                @other_results
            );
            undef $handle;
            undef $cv_connection;
        }catch {
            my $e = shift;
            $cv_connection->croak($e);
            undef $handle;
            undef $cv_connection;
        };
    };
    $handle->{rbuf} = "";
    $read_cb->();  ## in case the whole request is already consumed
    $handle->on_read($read_cb) if defined $handle;
}

sub establish {
    my ($self, $fh) = @_;
    my $cv_connection = AnyEvent->condvar;
    if(!defined($fh)) {
        $cv_connection->croak("fh parameter is mandatory for establish() method");
        return $cv_connection;
    }
    my $handshake = Protocol::WebSocket::Handshake::Server->new;
    $self->_do_handshake($cv_connection, $fh, $handshake);
    return $cv_connection;
}

sub establish_psgi {
    my ($self, $env, $fh) = @_;
    my $cv_connection = AnyEvent->condvar;
    if(!defined($env)) {
        $cv_connection->croak("psgi_env parameter is mandatory");
        return $cv_connection;
    }
    $fh = $env->{"psgix.io"} if not defined $fh;
    if(!defined($fh)) {
        $cv_connection->croak("No connection file handle provided. Maybe the PSGI server does not support psgix.io extension.");
        return $cv_connection;
    }
    my $handshake = Protocol::WebSocket::Handshake::Server->new_from_psgi($env);
    $self->_do_handshake($cv_connection, $fh, $handshake);
    return $cv_connection;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::WebSocket::Server - WebSocket server for AnyEvent

=head1 SYNOPSIS

    use AnyEvent::Socket qw(tcp_server);
    use AnyEvent::WebSocket::Server;
    
    my $server = AnyEvent::WebSocket::Server->new();
    
    my $tcp_server;
    $tcp_server = tcp_server undef, 8080, sub {
        my ($fh) = @_;
        $server->establish($fh)->cb(sub {
            my $connection = eval { shift->recv };
            if($@) {
                warn "Invalid connection request: $@\n";
                close($fh);
                return;
            }
            $connection->on(each_message => sub {
                my ($connection, $message) = @_;
                $connection->send($message); ## echo
            });
            $connection->on(finish => sub {
                undef $connection;
            });
        });
    };

=head1 DESCRIPTION

This class is an implementation of the WebSocket server in an L<AnyEvent> context.

=over

=item *

Currently this module supports WebSocket protocol version 13 only. See L<RFC 6455|https://tools.ietf.org/html/rfc6455> for detail.

=back


=head1 CLASS METHODS

=head2 $server = AnyEvent::WebSocket::Server->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<handshake> => CODE (optional)

A subroutine reference to customize the WebSocket handshake process.
You can use this option to validate and preprocess the handshake request and customize the handshake response.

For each request, the handshake code is called like

    ($response, @other_results) = $handshake->($request, $default_response)

where C<$request> is a L<Protocol::WebSocket::Request> object,
and C<$default_response> is a L<Protocol::WebSocket::Response> object.
The C<$handshake> code must return C<$response>. C<@other_results> are optional.

The return value C<$response> is the handshake response returned to the client.
It must be either a L<Protocol::WebSocket::Response> object,
or a string of a valid HTTP response (including the Status-Line, the Headers and the Body).

The argument C<$default_response> is a L<Protocol::WebSocket::Response> valid for the given C<$request>.
If you don't need to manipulate the response, just return C<$default_response>. That is,

    handshake => sub { $_[1] }

is the minimal valid code for C<handshake>.

In addition to C<$response>, you can return C<@other_results> if you want.
Those C<@other_results> can be obtained later from the condition variable of C<establish()> method.

If you throw an exception from C<$handshake> code, we think you reject the C<$request>.
In this case, the condition variable of C<establish()> method croaks.


=item C<validator> => CODE (optional)

B<< This option is only for backward compatibility. Use C<handshake> option instead. If C<handshake> option is specified, this option is ignored. >>

A subroutine reference to validate the incoming WebSocket request.
If omitted, it accepts the request.

The validator is called like

    @other_results = $validator->($request)

where C<$request> is a L<Protocol::WebSocket::Request> object.

If you reject the C<$request>, throw an exception.

If you accept the C<$request>, don't throw any exception.
The return values of the C<$validator> are sent to the condition variable of C<establish()> method.

=item C<ssl_key_file> => FILE_PATH (optional)

A string of the filepath to the SSL/TLS private key file in PEM format.
If you set this option, you have to set C<ssl_cert_file> option, too.

If this option or C<ssl_cert_file> option is set, L<AnyEvent::WebSocket::Server> encrypts the WebSocket streams with SSL/TLS.

=item C<ssl_cert_file> => FILE_PATH (optional)

A string of the filepath to the SSL/TLS certificate file in PEM format.

The file may contain both the certificate and corresponding private key. In that case, C<ssl_key_file> may be omitted.

If this option is set, L<AnyEvent::WebSocket::Server> encrypts the WebSocket streams with SSL/TLS.

=item C<max_payload_size> => INT (optional)

The maximum payload size for received frames. Currently defaults to whatever L<Protocol::WebSocket> defaults to.
Note that payload size for sent frames are not limited.

=back


=head1 OBJECT METHODS

=head2 $conn_cv = $server->establish($fh)

Establish a WebSocket connection to a client via the given connection filehandle.

C<$fh> is a filehandle for a connection socket, which is usually obtained by C<tcp_server()> function in L<AnyEvent::Socket>.

Return value C<$conn_cv> is an L<AnyEvent> condition variable.

In success, C<< $conn_cv->recv >> returns an L<AnyEvent::WebSocket::Connection> object and C<@other_results> returned by the handshake process.
In failure (e.g. the client sent a totally invalid request or your handshake process threw an exception),
C<$conn_cv> will croak an error message.

    ($connection, @other_results) = eval { $conn_cv->recv };
    
    ## or in scalar context, it returns $connection only.
    $connection = eval { $conn_cv->recv };
    
    if($@) {
        my $error = $@;
        ...
        return;
    }
    do_something_with($connection);

You can use C<$connection> to send and receive data through WebSocket. See L<AnyEvent::WebSocket::Connection> for detail.

Note that even if C<$conn_cv> croaks, the connection socket C<$fh> remains intact.
You can communicate with the client via C<$fh> unless the client has already closed it.

=head2 $conn_cv = $server->establish_psgi($psgi_env, [$fh])

The same as C<establish()> method except that the request is in the form of L<PSGI> environment.

C<$psgi_env> is a L<PSGI> environment object obtained from a L<PSGI> server.
C<$fh> is the connection filehandle.
If C<$fh> is omitted, C<< $psgi_env->{"psgix.io"} >> is used for the connection (see L<PSGI::Extensions>).

=head1 EXAMPLES

=head2 handshake option

The following server accepts WebSocket URLs such as C<ws://localhost:8080/2013/10>.

    use AnyEvent::Socket qw(tcp_server);
    use AnyEvent::WebSocket::Server;
    
    my $server = AnyEvent::WebSocket::Server->new(
        handshake => sub {
            my ($req, $res) = @_;
            ## $req is a Protocol::WebSocket::Request
            ## $res is a Protocol::WebSocket::Response
    
            ## validating and parsing request.
            my $path = $req->resource_name;
            die "Invalid format" if $path !~ m{^/(\d{4})/(\d{2})};
            
            my ($year, $month) = ($1, $2);
            die "Invalid month" if $month <= 0 || $month > 12;
    
            ## setting WebSocket subprotocol in response
            $res->subprotocol("mytest");
            
            return ($res, $year, $month);
        }
    );
    
    tcp_server undef, 8080, sub {
        my ($fh) = @_;
        $server->establish($fh)->cb(sub {
            my ($conn, $year, $month) = eval { shift->recv };
            if($@) {
                my $error = $@;
                error_response($fh, $error);
                return;
            }
            $conn->send("You are accessing YEAR = $year, MONTH = $month");
            $conn->on(finish => sub { undef $conn });
        });
    };

=head1 SEE ALSO

=over

=item L<AnyEvent::WebSocket::Client>

L<AnyEvent>-based WebSocket client implementation.

=item L<Net::WebSocket::Server>

Minimalistic stand-alone WebSocket server. It uses its own event loop mechanism.

=item L<Net::Async::WebSocket>

Stand-alone WebSocket server and client implementation using L<IO::Async>


=back

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=head1 CONTRIBUTORS

mephinet (Philipp Gortan)

=head1 REPOSITORY

L<https://github.com/debug-ito/AnyEvent-WebSocket-Server>

=head1 ACKNOWLEDGEMENTS

Graham Ollis (plicease) - author of L<AnyEvent::WebSocket::Client>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

