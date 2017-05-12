package App::TLSMe::Connection;

use strict;
use warnings;

use AnyEvent::Handle;
use AnyEvent::Socket;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{handle} = $self->_build_listen_handle($self->{fh});

    $self->{on_eof}           ||= sub { };
    $self->{on_error}         ||= sub { };
    $self->{on_backend_error} ||= sub { };

    return $self;
}

sub write {
    my $self = shift;

    $self->{handle}->push_write(@_);
}

sub _drop {
    my $self = shift;
    my ($error) = @_;

    if (defined $error) {
        $self->{on_error}->($self, $error);
    }
    else {
        $self->{on_eof}->($self);
    }

    my $handle = delete $self->{handle};

    $self->_close_handle($handle);

    undef $handle;

    return $self;
}

sub _on_starttls_handler {
    my $self = shift;

    sub {
        my $handle = shift;
        my ($is_success, $message) = @_;

        if (!$is_success) {
            return $self->_drop($message);
        }

        $self->_connect_to_backend;
    };
}

sub _connect_to_backend {
    my $self = shift;

    $self->{backend_handle} = $self->_build_backend_handle(
        connect => [$self->{backend_host}, $self->{backend_port}]);
}

sub _build_listen_handle {
    my $self = shift;
    my ($fh) = @_;

    return $self->_build_handle(
        fh      => $fh,
        tls     => 'accept',
        tls_ctx => $self->{tls_ctx},
        timeout => 8,
        on_eof  => sub {
            my $handle = shift;

            if (my $backend_handle = delete $self->{backend_handle}) {
                $self->{on_backend_eof}->($self);
                $self->_close_handle($backend_handle);
            }

            $self->_drop;
        },
        on_error => sub {
            my $handle = shift;
            my ($is_fatal, $message) = @_;

            if (my $backend_handle = delete $self->{backend_handle}) {
                $self->{on_backend_error}->($self, $message || $!);
                $self->_close_handle($backend_handle);
            }

            $self->_drop($message);
        },
        on_starttls => $self->_on_starttls_handler
    );
}

sub _build_backend_handle {
    my $self = shift;

    $self->_build_handle(
        on_connect => sub {
            $self->{on_backend_connected}->($self);

            $self->{handle}->on_read($self->_on_send_handler);

            $self->{backend_handle}->on_read($self->_on_read_handler);
        },
        on_connect_error => sub {
            my $backend_handle = shift;
            my ($message) = @_;

            $self->{on_backend_error}->($self, $message);

            $self->_drop;
        },
        on_eof => sub {
            my $backend_handle = shift;

            $self->{on_backend_eof}->($self);

            $self->_close_handle($backend_handle);
            delete $self->{backend_handle};

            $self->_drop;
        },
        on_error => sub {
            my $backend_handle = shift;
            my ($is_fatal, $message) = @_;

            $self->{on_backend_error}->($self, $message);

            $self->_close_handle($backend_handle);
            delete $self->{backend_handle};

            $self->_drop;
        },
        @_
    );
}

sub _build_handle {
    my $self = shift;

    return AnyEvent::Handle->new(no_delay => 1, @_);
}

sub _on_send_handler {
    my $self = shift;

    return sub {
        my $handle = shift;

        $self->{backend_handle}->push_write($handle->rbuf);
        $handle->{rbuf} = '';
      }
}

sub _on_read_handler {
    my $self = shift;

    return sub {
        my ($backend_handle) = @_ or return;

        $self->{handle}->push_write($backend_handle->rbuf);
        $backend_handle->{rbuf} = '';
      }
}

sub _close_handle {
    my $self = shift;
    my ($handle) = @_;

    $handle->wtimeout(0);

    $handle->on_drain;
    $handle->on_error;

    $handle->on_drain(
        sub {
            $_[0]->destroy;
            undef $handle;
        }
    );

    undef $handle;
}

1;
__END__

=head1 NAME

App::TLSMe::Connection - Connection class

=head1 SYNOPSIS

    App::TLSMe::Connection->new(
        fh => $fh,
        backend_host => 'localhost',
        backend_port => 8080,
        ...
    );

=head1 DESCRIPTION

Object-Value that holds handles, callbacks and other information associated with
proxy-backend connection.

=head1 METHODS

=head2 C<new>

    my $connection = App::TLSMe::Connection->new;

=head2 C<write>

    $connection->write(...);

=cut
