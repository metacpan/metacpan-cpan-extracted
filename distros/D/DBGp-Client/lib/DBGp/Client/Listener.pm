package DBGp::Client::Listener;

use strict;
use warnings;

=head1 NAME

DBGp::Client::Listener - wait for incoming DBGp connections

=head1 SYNOPSIS

    $listener = DBGp::Client::Listener->new(
        port    => 9000,
    );
    $listener->listen;

    $connection = $listener->accept;

    # use the methods in the DBGp::Client::Connection object

=head1 DESCRIPTION

The main entry point for L<DBGp::Client>: listens for incoming
debugger connections and returns a L<DBGp::Client::Connection> object.

=head1 METHODS

=cut

use IO::Socket;

use DBGp::Client::Connection;

=head2 new

    my $listener = DBGp::Client::Listener->new(%opts);

Possible options are C<port> to specify a TCP port, and C<path> to
specify the path for an Unix-domain socket.

For Unix-domain socket, passing C<mode> performs an additional
C<chmod> call before starting to listen for connections.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        port    => $args{port},
        path    => $args{path},
        mode    => $args{mode},
        socket  => undef,
    }, $class;

    die "Specify either 'port' or 'path'" unless $self->{port} || $self->{path};

    return $self;
}

=head2 listen

    $listener->listen;

Starts listening on the endpoint specified to the constructor;
C<die()>s if there is an error.

=cut

sub listen {
    my ($self) = @_;

    if ($self->{port}) {
        $self->{socket} = IO::Socket::INET->new(
            Listen    => 1,
            LocalAddr => '127.0.0.1',
            LocalPort => $self->{port},
            Proto     => 'tcp',
            ReuseAddr => 1,
            ReusePort => 1,
        );
    } elsif ($self->{path}) {
        if (-S $self->{path}) {
            unlink $self->{path} or die "Unable to unlink stale socket: $!";
        }

        $self->{socket} = IO::Socket::UNIX->new(
            Local     => $self->{path},
        );
        if ($self->{socket} && defined $self->{mode}) {
            chmod $self->{mode}, $self->{path}
                or $self->{socket} = undef;
        }
        if ($self->{socket}) {
            $self->{socket}->listen(1)
                or $self->{socket} = undef;
        }
    }

    die "Unable to start listening: $!" unless $self->{socket};
}

=head2 accept

    my $connection = $listener->accept;

Waits for an incoming debugger connection and returns a
fully-initialized L<DBGp::Client::Connection> object; it calls
L<DBGp::Client::Connection/parse_init> on the connection object to
read and parse the initialization message.

=cut

sub accept {
    my ($self) = @_;
    my $sock = $self->{socket}->accept;

    return undef if !$sock;

    my $conn = DBGp::Client::Connection->new(socket => $sock);

    $conn->parse_init;

    return $conn;
}

1;

__END__

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2015 Mattia Barbon. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
