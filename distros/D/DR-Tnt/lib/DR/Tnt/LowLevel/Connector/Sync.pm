use utf8;
use strict;
use warnings;

package DR::Tnt::LowLevel::Connector::Sync;
use Mouse;
use IO::Socket::INET;
use IO::Socket::UNIX;

extends 'DR::Tnt::LowLevel::Connector';

sub _connect {
    my ($self, $cb) = @_;

    my $fh;
    if ($self->host eq 'unix' or $self->host eq 'unix/') {
        $fh = IO::Socket::UNIX->new(
            Type            => SOCK_STREAM,
            Peer            => $self->port,
        );
    } else {
        $fh = IO::Socket::INET->new(
            PeerHost        => $self->host,
            PeerPort        => $self->port,
            Proto           => 'tcp',
        );
    }

    unless ($fh) {
        $cb->(ER_SOCKET => $!);
        return;
    }

    $self->_set_fh($fh);
    $cb->(OK => 'Socket connected');

    return;
}
    
sub _handshake {
    my ($self, $cb) = @_;
    $self->sread(128, sub {
        my ($state, $message, $hs) = @_;
        unless ($state eq 'OK') {
            pop;
            goto \&$cb;
        }
        $cb->(OK => 'handshake was read', $hs);
    });
}

sub send_pkt {
    my ($self, $pkt, $cb) = @_;

    while (1) {
        my $done = syswrite $self->fh, $pkt;
        unless (defined $done) {
            $cb->(ER_SOCKET => $!);
            return;
        }
        if ($done == length $pkt) {
            $cb->(OK => 'swrite done');
            return;
        }
        substr $pkt, 0, $done, '' if $done;
    }
}

sub _wait_something {
    my ($self) = @_;
    return unless $self->fh;

    do {
        my $blob = '';
        my $done = sysread $self->fh, $blob, 4096;

        unless ($done) {
            unless (defined $done) {
                $self->socket_error($! // 'Connection lost');
                return;
            }
            $self->socket_error('Remote host closed connection');
            return;
        }
        $self->rbuf($self->rbuf . $blob);

    } until $self->check_rbuf;
}

after handshake => sub {
    my ($self) = @_;
    $self->_wait_something;
};

after wait_response => sub {
    my ($self) = @_;
    $self->_wait_something;
};

__PACKAGE__->meta->make_immutable;
