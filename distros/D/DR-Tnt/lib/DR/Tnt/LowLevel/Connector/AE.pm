use utf8;
use strict;
use warnings;

package DR::Tnt::LowLevel::Connector::AE;

use Mouse;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

extends 'DR::Tnt::LowLevel::Connector';


has _fileno     => is => 'rw', isa => 'Maybe[Int]';
has _handle     => is => 'rw', isa => 'Maybe[Object]';

sub _connect {
    my ($self, $cb) = @_;

    my $h = tcp_connect
        $self->host,
        $self->port,
        sub {
            my ($fh) = @_;
            unless ($fh) {
                $cb->(ER_CONNECT => $!);
                return;
            }
            $self->_fileno(fileno $fh);
            $self->_set_fh(new AnyEvent::Handle
                fh          => $fh,
                on_read     => $self->_on_read,
                on_error    => $self->_on_error,
            );

            $cb->(OK => 'Connected');
        }
    ;
    $self->_handle($h);
    return;
}

before _clean_fh => sub {
    my ($self) = @_;
    $self->fh->destroy      if $self->fh;
    $self->_handle(undef);
};

after _set_fh => sub {
    my ($self) = @_;
    if ($self->fh) {
        $self->_fileno(fileno $self->fh->fh);
    } else {
        $self->_fileno(undef);
        $self->_handle(undef);
    }
};

sub _on_read {
    my ($self) = @_;
    sub {
        my ($handle) = @_;
        return unless $handle;

        # reconnect artefacts
        return unless $self->_fileno;
        return unless $self->_fileno == fileno $self->fh->fh;

        $self->rbuf($self->rbuf . $handle->rbuf);
        $handle->{rbuf} = '';
        $self->check_rbuf;
    };
}

sub _on_error {
    my ($self) = @_;

    sub {
        my ($handle, $fatal, $message) = @_;
        return unless $fatal;
     
        # reconnect artefacts
        return unless $self->_fileno;
        return unless $self->_fileno == fileno $self->fh->fh;

        $self->socket_error($message);
    }
}

sub send_pkt {
    my ($self, $pkt, $cb) = @_;

    $self->fh->push_write($pkt);
    $cb->(OK => 'packet was queued to send');
    return;
}


__PACKAGE__->meta->make_immutable;
