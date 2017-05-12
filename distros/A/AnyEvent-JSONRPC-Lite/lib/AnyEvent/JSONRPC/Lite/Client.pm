package AnyEvent::JSONRPC::Lite::Client;
use Any::Moose;

use Carp;
use Scalar::Util 'weaken';

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

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
    default => sub { {} },
);

has _connection_guard => (
    is  => 'rw',
    isa => 'Object',
);

no Any::Moose;

sub BUILD {
    my $self = shift;

    my $guard = tcp_connect $self->host, $self->port, sub {
        my ($fh) = @_
            or return
                $self->on_error->(
                    undef, 1,
                    "Failed to connect $self->{host}:$self->{port}: $!",
                );

        my $handle = AnyEvent::Handle->new(
            on_error => sub {
                my ($h, $fatal, $msg) = @_;
                $self->on_error->(@_);
                $h->destroy;
            },
            %{ $self->handler_options },
            fh => $fh,
        );

        $handle->on_read(sub {
            shift->unshift_read(json => sub {
                $self->_handle_response( $_[1] );
            });
        });

        while (my $pooled = shift @{ $self->_request_pool }) {
            $handle->push_write( json => $pooled );
        }

        $self->handler( $handle );
    };
    weaken $self;

    $self->_connection_guard($guard);
}

sub call {
    my ($self, $method, @params) = @_;

    my $request = {
        id     => $self->_next_id->(),
        method => $method,
        params => \@params,
    };

    if ($self->handler) {
        $self->handler->push_write( json => $request );
    }
    else {
        push @{ $self->_request_pool }, $request;
    }

    $self->_callbacks->{ $request->{id} } = AnyEvent->condvar;
}

sub _handle_response {
    my ($self, $res) = @_;

    my $d = delete $self->_callbacks->{ $res->{id} };
    unless ($d) {
        warn q/Invalid response from server/;
        return;
    }

    if (my $error = $res->{error}) {
        $d->croak($error);
    }
    else {
        $d->send($res->{result});
    }
}

sub notify {
    my ($self, $method, @params) = @_;

    my $request = {
        method => $method,
        params => \@params,
    };

    if ($self->handler) {
        $self->handler->push_write( json => $request );
    }
    else {
        push @{ $self->_request_pool }, $request;
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=begin stopwords

AnyEvent Coro JSONRPC Hostname Str TCP TCP-based
blockingly condvar condvars coroutine unix

=end stopwords

=head1 NAME

AnyEvent::JSONRPC::Lite::Client - Simple TCP-based JSONRPC client

=head1 SYNOPSIS

    use AnyEvent::JSONRPC::Lite::Client;
    
    my $client = AnyEvent::JSONRPC::Lite::Client->new(
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

This module is client part of L<AnyEvent::JSONRPC::Lite>.

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

    my $client = AnyEvent::JSONRPC::Lite::Client->new(
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

Error callback code reference, which is called when some error occurred.
This has same arguments as L<AnyEvent::Handle>, and also act as handler's on_error callback.

Default is just croak.

If you want to set other options to handle object, use handler_options option showed below.

=item handler_options => 'HashRef'

This is passed to constructor of L<AnyEvent::Handle> that is used manage connection.

Default is empty.

=back

=head2 call ($method, @params)

Call remote method named C<$method> with parameters C<@params>. And return condvar object for response.

    my $cv = $client->call( echo => 'Hello!' );
    my $res = $cv->recv;

If server returns an error, C<< $cv->recv >> causes croak by using C<< $cv->croak >>. So you can handle this like following:

    my $res;
    eval { $res = $cv->recv };
    
    if (my $error = $@) {
        # ...
    }

=head2 notify ($method, @params)

Same as call method, but not handle response. This method just notify to server.

    $client->notify( echo => 'Hello' );

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
