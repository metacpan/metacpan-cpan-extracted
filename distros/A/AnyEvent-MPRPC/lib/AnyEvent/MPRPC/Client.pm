package AnyEvent::MPRPC::Client;
use strict;
use warnings;
use Any::Moose;

use Carp;
use Scalar::Util 'weaken';

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::MessagePack;
use AnyEvent::MPRPC::Constant;

has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has port => (
    is       => 'ro',
    isa      => 'Int|Str',
    required => 1,
);

has connect_timeout => (
    is       => 'ro',
    isa      => 'Int|Str',
);

has handler => (
    is  => 'rw',
    isa => 'AnyEvent::Handle',
);

has on_error => (
    is      => 'rw',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        return sub {
            my ($handle, $fatal, $message) = @_;
            croak sprintf "Client got error: %s", $message;
        };
    },
);

has handler_options => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has _request_pool => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has _next_id => (
    is      => 'ro',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        my $id = 0;
        sub { ++$id };
    },
);

has _callbacks => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

has _connection_guard => (
    is  => 'rw',
    isa => 'Object',
);

has 'before_connect' => (
    is  => 'ro',
    isa => 'CodeRef',
);

has 'after_connect' => (
    is  => 'ro',
    isa => 'CodeRef',
);

# depreciated!
has 'on_connect' => (
    is  => 'ro',
    isa => 'CodeRef',
);

no Any::Moose;

sub BUILD {
    my $self = shift;

    my $after_connect = $self->after_connect ? sub { $self->after_connect->($self, @_) } : undef;
    my $guard = tcp_connect $self->host, $self->port, sub {
        my $fh = shift
            or return
                $self->on_error->(
                    undef, 1,
                    "Failed to connect $self->{host}:$self->{port}: $!",
                );
        my($host, $port, $retry) = @_;
        $self->after_connect
            and $self->after_connect->($self, $fh, $host, $port, $retry);

        my $handle = AnyEvent::Handle->new(
            on_error => sub {
                my ($h, $fatal, $msg) = @_;
                $self->on_error->(@_);
                $h->destroy;
            },
            %{ $self->handler_options },
            fh => $fh,
        );

        $handle->unshift_read(msgpack => $self->_handle_response_cb);

        while (my $pooled = shift @{ $self->_request_pool }) {
            $handle->push_write( msgpack => $pooled );
        }

        $self->handler( $handle );
    }, sub {
        my $connect_timeout;

        $self->before_connect
            and $self->before_connect->($self, @_);

        # on_conect is depreciated!
        $self->on_connect
            and $connect_timeout = $self->on_connect->($self, @_);

        # For backward compatibility, if connect_timeout option isn't specifed
        # use return value of on_connect callback as connect timeout seconds.
        $self->connect_timeout
            and $connect_timeout = $self->connect_timeout;

        return $connect_timeout;
    };
    weaken $self;

    $self->_connection_guard($guard);
}

sub call {
    my ($self, $method) = (shift, shift);
    my $param = (@_ == 1 && ref $_[0] eq "ARRAY") ? $_[0] : [@_];

    my $msgid = $self->_next_id->();

    my $request = [
        MP_TYPE_REQUEST,
        int($msgid), # should be IV
        $method,
        $param,
    ];

    if ($self->handler) {
        $self->handler->push_write( msgpack => $request );
    }
    else {
        push @{ $self->_request_pool }, $request;
    }

    # $msgid is stringified, but $request->{MP_RES_MSGID] is still IV
    $self->_callbacks->{ $msgid } = AnyEvent->condvar;
}

sub _handle_response_cb {
    my $self = shift;

    weaken $self;

    return sub {
        $self || return;

        my ($handle, $res) = @_;

        my $d = delete $self->_callbacks->{ $res->[MP_RES_MSGID] };

        if (my $error = $res->[MP_RES_ERROR]) {
            if ($d) {
                $d->croak($error);
            } else {
                Carp::croak($error);
            }
        }

        $handle->unshift_read(msgpack => $self->_handle_response_cb);

        if ($d) {
            $d->send($res->[MP_RES_RESULT]);
        } else {
            warn q/Invalid response from server/;
            return;
        }
    };
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

AnyEvent::MPRPC::Client - Simple TCP-based MessagePack RPC client

=head1 SYNOPSIS

    use AnyEvent::MPRPC::Client;

    my $client = AnyEvent::MPRPC::Client->new(
        host => '127.0.0.1',
        port => 4423,
    );

    # blocking interface
    my $res = $client->call( echo => 'foo bar' )->recv; # => 'foo bar';

    # non-blocking interface
    $client->call( echo => 'foo bar' )->cb(sub {
        my $res = $_[0]->recv;  # => 'foo bar';
    });

=head1 DESCRIPTION

This module is client part of L<AnyEvent::MPRPC>.

=head2 AnyEvent condvars

The main thing you have to remember is that all the data retrieval methods
return an AnyEvent condvar, C<$cv>.  If you want the actual data from the
request, there are a few things you can do.

You may have noticed that many of the examples in the SYNOPSIS call C<recv>
on the condvar.  You're allowed to do this under 2 circumstances:

=over 4

=item Either you're in a main program,

Main programs are "allowed to call C<recv> blockingly", according to the
author of L<AnyEvent>.

=item or you're in a Coro + AnyEvent environment.

When you call C<recv> inside a coroutine, only that coroutine is blocked
while other coroutines remain active.  Thus, the program as a whole is
still responsive.

=back

If you're not using Coro, and you don't want your whole program to block,
what you should do is call C<cb> on the condvar, and give it a coderef to
execute when the results come back.  The coderef will be given a condvar
as a parameter, and it can call C<recv> on it to get the data.  The final
example in the SYNOPSIS gives a brief example of this.

Also note that C<recv> will throw an exception if the request fails, so be
prepared to catch exceptions where appropriate.

Please read the L<AnyEvent> documentation for more information on the proper
use of condvars.

=head1 METHODS

=head2 new (%options)

Create new client object and return it.

    my $client = AnyEvent::MRPPC::Client->new(
        host => '127.0.0.1',
        port => 4423,
        %options,
    );

Available options are:

=over 4

=item host => 'Str'

Hostname to connect. (Required)

You should set this option to "unix/" if you will set unix socket to port option.

=item port => 'Int | Str'

Port number or unix socket path to connect. (Required)

=item on_error => $cb->($handle, $fatal, $message)

Error callback code reference, which is called when some error occured.
This has same arguments as L<AnyEvent::Handle>, and also act as handler's on_error callback.

Default is just croak.

=item before_connect => $cb->($self, $filehandle)

It will be called with the file handle in not-yet-connected state as only argument.

=item after_connect => $cb->($self, $filehandle, $host, $port, $retry)

After the connection is established, then this callback will be invoked.

If the connect is unsuccessful, then the on_error callback will be invoked.

=item on_connect => $cb->($self, $filehandle)

It will be called with the file handle in not-yet-connected state as only argument.

    *******************************************************************
     The on_connect callback is deprecated! Please use before_connect
     (same as $prepare_cb of AnyEvent::Socket#tcp_connect) or
     after_connect (which call in $connect_cb of
     AnyEvent::Socket#tcp_connect).
    *******************************************************************

=item handler_options => 'HashRef'

This is passed to constructor of L<AnyEvent::Handle> that is used manage connection.

Default is empty.

=back

=head2 call ($method, (@params | \@params))

Call remote method named C<$method> with parameters C<@params>. And return condvar object for response.

    my $cv = $client->call( echo => 'Hello!' );
    my $res = $cv->recv;

If server returns an error, C<<$cv->recv>> causes croak by using C<<$cv->croak>>. So you can handle this like following:

    my $res;
    eval { $res = $cv->recv };

    if (my $error = $@) {
        # ...
    }

=head1 AUTHOR

Tokuhiro Matsuno <tokuhirom@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by tokuhirom.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
