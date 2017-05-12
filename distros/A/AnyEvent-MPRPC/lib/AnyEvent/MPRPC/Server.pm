package AnyEvent::MPRPC::Server;
use strict;
use warnings;
use Any::Moose;

use Carp;
use Scalar::Util 'weaken';

use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::MPRPC::CondVar;
use AnyEvent::MessagePack;

use AnyEvent::MPRPC::Constant;

has address => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => undef,
);

has port => (
    is       => 'ro',
    isa      => 'Int|Str',
    required => 1,
);

has server => (
    is => 'rw',
    isa => 'Object',
);

has on_error => (
    is      => 'rw',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        return sub {
            my ($handle, $fatal, $message) = @_;
            carp sprintf "Server got error: %s", $message;
        };
    },
);

has on_eof => (
    is      => 'rw',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        return sub { };
    },
);

has on_accept => (
    is      => 'rw',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        return sub { };
    },
);

has on_dispatch => (
    is      => 'rw',
    isa     => 'CodeRef',
    lazy    => 1,
    default => sub {
        return sub { };
    },
);

has handler_options => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has _handlers => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has _callbacks => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);

no Any::Moose;

sub BUILD {
    my $self = shift;

    $self->server(tcp_server $self->address, $self->port, sub {
        $self->on_accept->(@_);

        my ($fh, $host, $port) = @_;
        my $indicator = "$host:$port";

        my $handle = AnyEvent::Handle->new(
            on_error => sub {
                my ($h, $fatal, $msg) = @_;
                $self->on_error->(@_);
                $h->destroy;
            },
            on_eof => sub {
                my ($h) = @_;
                # client disconnected
                $self->on_eof->(@_);
                $h->destroy;
            },
            %{ $self->handler_options },
            fh => $fh,
        );

        $handle->unshift_read(msgpack => $self->_dispatch_cb($indicator));

        $self->_handlers->[ fileno($fh) ] = $handle;
    }) unless defined $self->server;
    weaken $self;

    $self;
}

sub reg_cb {
    my ($self, %callbacks) = @_;

    while (my ($method, $callback) = each %callbacks) {
        $self->_callbacks->{ $method } = $callback;
    }
}

sub _dispatch_cb {
    my ($self, $indicator) = @_;

    weaken $self;

    return sub {
        $self || return;

        my ($handle, $request) = @_;
        $self->on_dispatch->($indicator, $handle, $request);
        return if $handle->destroyed;

        $handle->unshift_read(msgpack => $self->_dispatch_cb($indicator));

        return unless $request and ref $request eq 'ARRAY';

        my $target = $self->_callbacks->{ $request->[MP_REQ_METHOD] };

        my $id = $request->[MP_REQ_MSGID];
        $indicator = "$indicator:$id";

        my $res_cb = sub {
            my $type   = shift;
            my $result = @_ > 1 ? \@_ : $_[0];

            $handle->push_write( msgpack => [
                MP_TYPE_RESPONSE,
                int($id), # should be IV.
                $type eq 'error'  ? $result : undef,
                $type eq 'result' ? $result : undef,
            ]) if $handle;
        };
        weaken $handle;

        my $cv = AnyEvent::MPRPC::CondVar->new;
        $cv->_cb(
            sub { $res_cb->( result => $_[0]->recv ) },
            sub { $res_cb->( error  => $_[0]->recv ) },
        );

        $target ||= sub { shift->error(qq/No such method "@{[ $request->[MP_REQ_METHOD] ]}" found/) };
        $target->( $cv, $request->[MP_REQ_PARAMS] );
    };
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

AnyEvent::MPRPC::Server - Simple TCP-based MessagePack RPC server

=head1 SYNOPSIS

    use AnyEvent::MPRPC::Server;
    
    my $server = AnyEvent::MPRPC::Server->new( port => 4423 );
    $server->reg_cb(
        echo => sub {
            my ($res_cv, @params) = @_;
            $res_cv->result(@params);
        },
        sum => sub {
            my ($res_cv, @params) = @_;
            $res_cv->result( $params[0] + $params[1] );
        },
    );

=head1 DESCRIPTION

This module is server part of L<AnyEvent::MPRPC>.

=head1 METHOD

=head1 new (%options)

Create server object, start listening socket, and return object.

    my $server = AnyEvent::MPRPC::Server->new(
        port => 4423,
    );

Available C<%options> are:

=over 4

=item port => 'Int | Str'

Listening port or path to unix socket (Required)

=item address => 'Str'

Bind address. Default to undef: This means server binds all interfaces by default.

If you want to use unix socket, this option should be set to "unix/"

=item on_error => $cb->($handle, $fatal, $message)

Error callback which is called when some errors occured.
This is actually L<AnyEvent::Handle>'s on_error.

=item on_eof => $cb->($handle)

EOF callback. same as L<AnyEvent::Handle>'s on_eof callback.

=item on_accept => $cb->($fh, $host, $port)

=item on_dispatch => $cb->($indicator, $handle, $request);

=item handler_options => 'HashRef'

Hashref options of L<AnyEvent::Handle> that is used to handle client connections.

=back

=head2 reg_cb (%callbacks)

Register MessagePack RPC methods.

    $server->reg_cb(
        echo => sub {
            my ($res_cv, @params) = @_;
            $res_cv->result(@params);
        },
        sum => sub {
            my ($res_cv, @params) = @_;
            $res_cv->result( $params[0] + $params[1] );
        },
    );

=head3 callback arguments

MessagePack RPC callback arguments consists of C<$result_cv>, and request C<@params>.

    my ($result_cv, @params) = @_;

C<$result_cv> is L<AnyEvent::MPRPC::CondVar> object.
Callback must be call C<<$result_cv->result>> to return result or C<<$result_cv->error>> to return error.

If C<$result_cv> is not defined, it is notify request, so you don't have to return response. See L<AnyEvent::MPRPC::Client> notify method.

C<@params> is same as request parameter.

=head1 AUTHOR

Tokuhiro Matsuno <tokuhirom@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by tokuhirom.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

