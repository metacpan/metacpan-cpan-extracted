package AnyEvent::JSONRPC::TCP::Server;
use Moose;

extends 'AnyEvent::JSONRPC::Server';

use Carp;
use Scalar::Util 'weaken';

use AnyEvent::Handle;
use AnyEvent::Socket;

use AnyEvent::JSONRPC::InternalHandle;
use AnyEvent::JSONRPC::CondVar;
use JSON::RPC::Common::Procedure::Call;

has address => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => undef,
);

has port => (
    is      => 'ro',
    isa     => 'Int|Str',
    default => 4423,
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

has methods => (
    isa     => 'HashRef[CodeRef]',
    lazy    => 1,
    traits  => ['Hash'],
    handles => {
        reg_cb => 'set',
        method => 'get',
    },
    default => sub { {} },
);

no Moose;

sub BUILD {
    my $self = shift;

    tcp_server $self->address, $self->port, sub {
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
            json => $self->json,
            %{ $self->handler_options },
            fh => $fh,
        );
        $handle->on_read(sub {
            shift->unshift_read( json => sub {
                $self->_dispatch($indicator, @_);
            }),
        });

        $self->_handlers->[ fileno($fh) ] = $handle;
    };
    weaken $self;

    $self;
}

sub _dispatch {
    my ($self, $indicator, $handle, $request) = @_;

    return $self->_batch($handle, @$request) if ref $request eq "ARRAY";
    return unless $request and ref $request eq "HASH";

    my $call   = JSON::RPC::Common::Procedure::Call->inflate($request);
    my $target = $self->method( $call->method );

    my $cv = AnyEvent::JSONRPC::CondVar->new( call => $call );
    $cv->cb( sub {
        my $response = $cv->recv;

        $handle->push_write( json => $response->deflate ) if not $cv->is_notification;
    });

    $target ||= sub { shift->error(qq/No such method "$request->{method}" found/) };
    $target->( $cv, $call->params_list );
}

sub _batch {
    my ($self, $handle, @request) = @_;

    my @response;
    for my $request (@request) {
        my $internal = AnyEvent::JSONRPC::InternalHandle->new;

        $self->_dispatch(undef, $internal, $request);

        push @response, $internal;
    }
    
    $handle->push_write( json => [ map { $_->recv } @response ] );
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords JSONRPC TCP TCP-based unix Str

=head1 NAME

AnyEvent::JSONRPC::TCP::Server - Simple TCP-based JSONRPC server

=head1 SYNOPSIS

    use AnyEvent::JSONRPC::TCP::Server;
    
    my $server = AnyEvent::JSONRPC::TCP::Server->new( port => 4423 );
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

This module is server part of L<AnyEvent::JSONRPC>.

=head1 METHOD

=head1 new (%options)

Create server object, start listening socket, and return object.

    my $server = AnyEvent::JSONRPC::TCP::Server->new(
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

Error callback which is called when some errors occurred.
This is actually L<AnyEvent::Handle>'s on_error.

=item on_eof => $cb->($handle)

EOF callback. same as L<AnyEvent::Handle>'s on_eof callback.

=item handler_options => 'HashRef'

Hashref options of L<AnyEvent::Handle> that is used to handle client connections.

=back

=head2 reg_cb (%callbacks)

Register JSONRPC methods.

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

JSONRPC callback arguments consists of C<$result_cv>, and request C<@params>.

    my ($result_cv, @params) = @_;

C<$result_cv> is L<AnyEvent::JSONRPC::CondVar> object.
Callback must be call C<< $result_cv->result >> to return result or C<< $result_cv->error >> to return error.

If C<$result_cv-E<gt>is_notification()> returns true, this is a notify request
and the result will not be send to the client.

C<@params> is same as request parameter.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
