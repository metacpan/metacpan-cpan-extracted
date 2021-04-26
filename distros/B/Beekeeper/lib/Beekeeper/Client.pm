package Beekeeper::Client;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME
 
Beekeeper::Client - Make RPC calls through message bus

=head1 VERSION
 
Version 0.01

=head1 SYNOPSIS

  my $client = Beekeeper::Client->instance;
  
  $client->send_notification(
      method => "my.service.foo",
      params => { foo => $foo },
  );
  
  my $resp = $client->do_job(
      method => "my.service.bar",
      params => { %args },
  );
  
  die uneless $resp->success;
  
  print $resp->result;
  
  my $req = $client->do_async_job(
      method     => "my.service.baz",
      params     => { %args },
      on_success => sub {
          my $resp = shift;
          print resp->result;
      },
      on_error => sub {
          my $error = shift;
          die error->message;
      },
  );
  
  $client->wait_all_jobs;

=encoding utf8

=head1 DESCRIPTION

This module connects to the message broker and makes RPC calls through message bus.

There are four different methods to do so:

  ┌───────────────────┬──────────────┬────────┬────────┬────────┐
  │ method            │ sent to      │ queued │ result │ blocks │
  ├───────────────────┼──────────────┼────────┼────────┼────────┤
  │ do_job            │ 1 worker     │ yes    │ yes    │ yes    │
  │ do_async_job      │ 1 worker     │ yes    │ yes    │ no     │
  │ do_background_job │ 1 worker     │ yes    │ no     │ no     │
  │ send_notification │ many workers │ no     │ no     │ no     │
  └───────────────────┴──────────────┴────────┴────────┴────────┘

All methods in this module are exported by default to C<Beekeeper::Worker>.

=head1 CONSTRUCTOR

=head3 instance( %args )

Connects to the message broker and returns a singleton instance.

Unless explicit connection parameters to the broker are provided tries 
to connect using the configuration from config file C<bus.config.json>.

=cut

use Beekeeper::Bus::STOMP;
use Beekeeper::JSONRPC;
use Beekeeper::Config;

use JSON::XS;
use Sys::Hostname;
use Time::HiRes;
use Carp;

use constant TXN_CLIENT_SIDE => 1;
use constant TXN_SERVER_SIDE => 2;
use constant QUEUE_LANES     => 2;
use constant REQ_TIMEOUT     => 60;

use Exporter 'import';

our @EXPORT_OK = qw(
    send_notification
    do_job
    do_async_job
    do_background_job
    wait_all_jobs
    set_auth_tokens
    get_auth_tokens
    __do_rpc_request
    __create_reply_queue
);

our %EXPORT_TAGS = ('worker' => \@EXPORT_OK );

our $singleton;


sub new {
    my ($class, %args) = @_;

    my $self = {
        _CLIENT => undef,
        _BUS    => undef,
    };

    $self->{_CLIENT} = {
        forward_to     => $args{'forward_to'},
        reply_queue    => undef,
        correlation_id => undef,
        in_progress    => undef,
        transaction    => undef,
        transaction_id => undef,
        curr_request   => undef,
        auth_tokens    => undef,
        session_id     => undef,
        async_cv       => undef,
        callbacks      => {},
    };

    unless (exists $args{'host'} && exists $args{'user'} && exists $args{'pass'}) {

        # Get broker connection parameters from config file

        my $bus_id = $args{'bus_id'};

        if (defined $bus_id) {
            # Use parameters for specific bus
            my $config = Beekeeper::Config->get_bus_config( bus_id => $bus_id );
            croak "Bus '$bus_id' is not defined into config file bus.config.json" unless $config;
            %args = ( %$config, %args );
        }
        else {
            my $config = Beekeeper::Config->get_bus_config( bus_id => '*');
            if (scalar(keys %$config) == 1) {
                # Use the only config present
                ($bus_id) = (keys %$config);
                %args = ( %{$config->{$bus_id}}, bus_id => $bus_id, %args );
            }
            else {
                # Use default parameters (if any)
                my ($default) = grep { $config->{$_}->{default} } keys %$config;
                croak "No default bus defined into config file bus.config.json" unless $default;
                $bus_id = $config->{$default}->{'bus-id'};
                %args = ( %{$config->{$default}}, bus_id => $bus_id, %args );
            }
        }
    }

    $self->{_BUS} = Beekeeper::Bus::STOMP->new( %args );

    # Connect to STOMP broker
    $self->{_BUS}->connect( blocking => 1 );

    bless $self, $class;
    return $self;
}

sub instance {
    my $class = shift;

    if ($singleton) {
        # Return existing singleton
        return $singleton;
    }

    # Create a new instance
    my $self = $class->new( @_ );

    # Keep a global reference to $self
    $singleton = $self;

    return $self;
}


=head1 METHODS

=head3 send_notification ( %args )

Broadcast a notification to the message bus.

All clients and workers listening for C<method> will receive it. If no one is listening
the notification is lost.

=over 4

=item method

A string with the name of the notification being sent with format C<"{service_class}.{method}">.

=item params

An arbitrary value or data structure sent with the notification. It could be undefined, 
but it should not contain blessed references that cannot be serialized as JSON.

=item address

A string with the name of the remote bus when sending notifications to another logical 
bus. Notifications to another bus need a router shoveling them.

=back

=cut

sub send_notification {
    my ($self, %args) = @_;

    my $fq_meth = $args{'method'} or croak "Method was not specified";

    $fq_meth .= '@' . $args{'address'} if (defined $args{'address'});

    $fq_meth =~ m/^     ( [\w-]+ (?:\.[\w-]+)* )
                     \. ( [\w-]+ ) 
                 (?: \@ ( [\w-]+ ) (\.[\w-]+)* )? $/x or croak "Invalid method $fq_meth";

    my ($service, $method, $remote_bus, $addr) = ($1, $2, $3, $4);

    my $json = encode_json({
        jsonrpc => '2.0',
        method  => "$service.$method",
        params  => $args{'params'},
    });

    my %send_args;

    my $local_bus = $self->{_BUS}->{cluster};

    $remote_bus = $self->{_CLIENT}->{forward_to} unless (defined $remote_bus);

    if (defined $remote_bus) {
        $send_args{'destination'}  = "/queue/msg.$remote_bus-" . int(rand(QUEUE_LANES)+1);
        $send_args{'x-forward-to'} = "/topic/msg.$remote_bus.$service.$method";
        $send_args{'x-forward-to'} .= "\@$addr" if (defined $addr && $addr =~ s/^\.//);
    }
    else {
        $send_args{'destination'} = "/topic/msg.$local_bus.$service.$method";
    }

    if (exists $args{'__auth'}) {
        $send_args{'x-auth-tokens'} = $args{'__auth'};
    }
    else {
        $send_args{'x-auth-tokens'} = $self->{_CLIENT}->{auth_tokens}  if defined $self->{_CLIENT}->{auth_tokens};
        $send_args{'x-session'}     = $self->{_CLIENT}->{session_id}   if defined $self->{_CLIENT}->{session_id};
    }

    if ($self->{transaction}) {
        my $hdr = $self->{transaction} == TXN_CLIENT_SIDE ? 'buffer_id' : 'transaction';
        $send_args{$hdr} = $self->{transaction_id};
    }

    $self->{_BUS}->send( body => \$json, %send_args );
}

=head3 accept_notifications ( $method => $callback, ... )

Make this client start accepting specified notifications from message bus.

C<$method> is a string with the format "{service_class}.{method}". A default
or fallback handler can be specified using a wildcard as "{service_class}.*".

C<$callback> is a coderef that will be called when a notification is received.
When executed, the callback will receive a parameter C<$params> which contains
the notification value or data structure sent.

Note that callbacks will not be executed timely if AnyEvent loop is not running.

=head3 stop_accepting_notifications ( $method, ... )

Make this client stop accepting specified notifications from message bus.

C<$method> must be one of the strings used previously in C<accept_notifications>.

=cut

sub accept_notifications {
    my ($self, %args) = @_;

    my $callbacks = $self->{_CLIENT}->{callbacks};

    foreach my $fq_meth (keys %args) {

        $fq_meth =~ m/^  ( [\w-]+ (?: \.[\w-]+ )* ) 
                      \. ( [\w-]+ | \* ) $/x or croak "Invalid notification method $fq_meth";

        my ($service, $method) = ($1, $2);

        my $callback = $args{$fq_meth};

        unless (ref $callback eq 'CODE') {
            croak "Invalid callback for '$method'";
        }

        croak "Already accepting notifications $fq_meth" if exists $callbacks->{"msg.$fq_meth"};
        $callbacks->{"msg.$fq_meth"} = $callback;

        #TODO: Allow to accept private notifications without subscribing

        my $local_bus = $self->{_BUS}->{cluster};

        $self->{_BUS}->subscribe(
            destination    => "/topic/msg.$local_bus.$service.$method",
            ack            => 'auto', # means none
            on_receive_msg => sub {
                my ($body_ref, $msg_headers) = @_;

                local $@;
                my $request = eval { decode_json($$body_ref) };

                unless (ref $request eq 'HASH' && $request->{jsonrpc} eq '2.0') {
                    warn "Received invalid JSON-RPC 2.0 notification";
                    return;
                }

                bless $request, 'Beekeeper::JSONRPC::Notification';
                $request->{_headers} = $msg_headers;

                my $method = $request->{method};

                unless (defined $method && $method =~ m/^([\.\w-]+)\.([\w-]+)$/) {
                    warn "Received notification with invalid method $method";
                    return;
                }

                my $cb = $callbacks->{"msg.$1.$2"} || 
                         $callbacks->{"msg.$1.*"};

                unless ($cb) {
                    warn "No callback found for received notification $method";
                    return;
                }

                $cb->($request->{params}, $request);
            }
        );
    }
}

=head3 stop_accepting_notifications ( $method, ... )

Make this client stop accepting specified notifications from message bus.

C<$method> must be one of the strings used previously in C<accept_notifications>.

=cut

sub stop_accepting_notifications {
    my ($self, @methods) = @_;

    croak "No method specified" unless @methods;

    foreach my $fq_meth (@methods) {

        $fq_meth =~ m/^  ( [\w-]+ (?: \.[\w-]+ )* ) 
                      \. ( [\w-]+ | \* ) $/x or croak "Invalid method $fq_meth";

        my ($service, $method) = ($1, $2);

        unless (defined $self->{_CLIENT}->{callbacks}->{"msg.$fq_meth"}) {
            carp "Not previously accepting notifications $fq_meth";
            next;
        }

        my $local_bus = $self->{_BUS}->{cluster};

        $self->{_BUS}->unsubscribe(
            destination => "/topic/msg.$local_bus.$service.$method",
            on_success  => sub {

                delete $self->{_CLIENT}->{callbacks}->{"msg.$fq_meth"};

                # Discard notifications already queued
                my $job_queue = $self->{_WORKER}->{job_queue_high};

                @$job_queue = grep {
                    my $task = $_;
                    my ($body_ref, $msg_headers) = @$task;
                    my $request = decode_json($$body_ref);
                    my $req_method = $request->{method};
                    $req_method =~ m/^([\.\w-]+)\.([\w-]+)$/;
                    not ($service eq $1 && ($method eq '*' || $method eq $2));
                } @$job_queue;
            }
        );
    }
}

=head3 do_job ( %args )

Makes a synchronous RPC call to a service worker through the message bus.

It will wait (in the event loop) until a response is received, wich will be either
an C<Beekeeper::JSONRPC::Response> object or a C<Beekeeper::JSONRPC::Error>.

On error it will die unless C<raise_error> option is set to false.

This method accepts the following parameters:

=over 4

=item method

A string with the name of the method to be invoked with format C<"{service_class}.{method}">.

=item params

An arbitrary value or data structure to be passed as parameters to the defined method. 
It could be undefined, but it should not contain blessed references that cannot be 
serialized as JSON.

=item address

A string with the name of the remote bus when calling methods of workers connected
to another logical bus. Requests to another bus need a router shoveling them.

=item timeout

Time in seconds before cancelling the request and returning an error response. If the
request takes too long but otherwise was executed successfully the response will
eventually arrive but it will be ignored.

=item raise_error
 
If set to true (the default) dies with the received error message when a call returns
an error response. If set to false returns a C<Beekeeper::JSONRPC::Error> instead.

=back

=head3 do_async_job ( %args )

Makes an asynchronous RPC call to a service worker through the message bus.

It returns immediately a C<Beekeeper::JSONRPC::Request> object which, once completed,
will have a defined C<response>.

This method  accepts parameters C<method>, C<params>, C<address> and C<timeout> 
the same as C<do_job>. Additionally two callbacks can be specified:

=over 4

=item on_success

Callback which will be executed after receiving a successful response with a
C<Beekeeper::JSONRPC::Response> object as parameter. Must be a coderef.

=item on_error

Callback which will be executed after receiving an error response with a
C<Beekeeper::JSONRPC::Error> object as parameter. Must be a coderef.

=back

=head3 do_background_job ( %args )

Makes an asynchronous RPC call to a service worker through the message bus but
does not expect to receive any response, it is a fire and forget call.

It returns undef immediately.

This method  accepts parameters C<method>, C<params>, C<address> and C<timeout> 
the same as C<do_job>.

=head3 wait_all_jobs

Wait (in the event loop) until all calls made by C<do_async_job> are completed.

=cut

our $WAITING;

sub do_job {
    my $self = shift;

    my $req = $self->__do_rpc_request( @_, req_type => 'SYNCHRONOUS' );

    # Make AnyEvent allow one level of recursive condvar blocking, as we may
    # block both in $worker->__work_forever and in $client->__do_rpc_request
    $WAITING && croak "Recursive condvar blocking wait attempted";
    local $WAITING = 1;
    local $AnyEvent::CondVar::Base::WAITING = 0;

    # Block until a response is received or request timed out
    $req->{_waiting_response}->recv;

    my $resp = $req->{_response};

    if (!exists $resp->{result} && $req->{_raise_error}) {
        my $errmsg = $resp->code . " " . $resp->message;
        croak "Call to '$req->{method}' failed: $errmsg";
    }

    return $resp;
}

sub do_async_job {
    my $self = shift;

    my $req = $self->__do_rpc_request( @_, req_type => 'ASYNCHRONOUS' );
    
    return $req;
}

sub do_background_job {
    my $self = shift;

    # Send job to a worker, but do not wait for result
    $self->__do_rpc_request( @_, req_type => 'BACKGROUND' );

    return;
}

my $__now = 0;

sub __do_rpc_request {
    my ($self, %args) = @_;
    my $client = $self->{_CLIENT};

    my $fq_meth = $args{'method'} or croak "Method was not specified";

    $fq_meth .= '@' . $args{'address'} if (defined $args{'address'});

    $fq_meth =~ m/^     ( [\w-]+ (?:\.[\w-]+)* )
                     \. ( [\w-]+ ) 
                 (?: \@ ( [\w-]+ ) (\.[\w-]+)* )? $/x or croak "Invalid method $fq_meth";

    my ($service, $method, $remote_bus, $addr) = ($1, $2, $3, $4);

    my %send_args;

    my $local_bus = $self->{_BUS}->{cluster};

    $remote_bus = $client->{forward_to} unless (defined $remote_bus);

    # Local bus request sent to:   /queue/req.{local_bus}.{service_class}
    # Remote bus request sent to:  /queue/req.{remote_bus}

    if (defined $remote_bus) {
        $send_args{'destination'}  = "/queue/req.$remote_bus-" . int(rand(QUEUE_LANES)+1);
        $send_args{'x-forward-to'} = "/queue/req.$remote_bus.$service";
        $send_args{'x-forward-to'} .= "\@$addr" if (defined $addr && $addr =~ s/^\.//);
    }
    else {
        $send_args{'destination'} = "/queue/req.$local_bus.$service";
    }

    if (exists $args{'__auth'}) {
        $send_args{'x-auth-tokens'} = $args{'__auth'};
    }
    else {
        $send_args{'x-auth-tokens'} = $client->{auth_tokens}  if defined $client->{auth_tokens};
        $send_args{'x-session'}     = $client->{session_id}   if defined $client->{session_id};
    }

    my $timeout = $args{'timeout'} || REQ_TIMEOUT;
    $send_args{'expiration'} = int( $timeout * 1000 );


    my $BACKGROUND  = $args{req_type} eq 'BACKGROUND';
    my $SYNCHRONOUS = $args{req_type} eq 'SYNCHRONOUS';
    my $raise_error = $args{'raise_error'};
    my $req_id;

    # JSON-RPC call
    my $req = {
        jsonrpc => '2.0',
        method  => "$service.$method",
        params  => $args{'params'},
    };

    # Reuse or create a private reply queue which will receive the response
    my $reply_queue = $client->{reply_queue} || $self->__create_reply_queue;
    $send_args{'reply-to'} = $reply_queue;

    unless ($BACKGROUND) {
        # Assign an unique request id (unique only for this client)
        $req_id = int(rand(90000000)+10000000) . '-' . $client->{correlation_id}++;
        $req->{'id'} = $req_id;
    }

    my $json = encode_json($req);

    if ($BACKGROUND && $self->{transaction}) {
        my $hdr = $self->{transaction} == TXN_CLIENT_SIDE ? 'buffer_id' : 'transaction';
        $send_args{$hdr} = $self->{transaction_id};
    }

    # Send request
    $self->{_BUS}->send( body => \$json, %send_args );

    if ($BACKGROUND) {
         # Nothing else to do
         return;
    }
    elsif ($SYNCHRONOUS) {

        $req->{_raise_error} = (defined $raise_error) ? $raise_error : 1;

        # Wait until a response is received in the reply queue
        $req->{_waiting_response} = AnyEvent->condvar;
        $req->{_waiting_response}->begin;
    }
    else {

        $req->{_on_success_cb} = $args{'on_success'};
        $req->{_on_error_cb}   = $args{'on_error'};

        if ($raise_error && !$req->{_on_error_cb}) {
            $req->{_on_error_cb} = sub {
                my $errmsg = $_[0]->code . " " . $_[0]->message;
                croak "Call to '$service.$method' failed: $errmsg";
            };
        }

        # Use shared cv for all requests
        if (!$client->{async_cv} || $client->{async_cv}->ready) {
            $client->{async_cv} = AnyEvent->condvar;
        }

        $req->{_waiting_response} = $client->{async_cv};
        $req->{_waiting_response}->begin;
    }

    $client->{in_progress}->{$req_id} = $req;

    # Ensure that timeout is set properly when the event loop was blocked
    if ($__now != time) { $__now = time; AnyEvent->now_update }

    # Request timeout timer
    $req->{_timeout} = AnyEvent->timer( after => $timeout, cb => sub {
        my $req = delete $client->{in_progress}->{$req_id};
        $req->{_response} = Beekeeper::JSONRPC::Error->request_timeout;
        $req->{_on_error_cb}->($req->{_response}) if $req->{_on_error_cb};
        $req->{_waiting_response}->end;
    });

    bless $req, 'Beekeeper::JSONRPC::Request';
    return $req;
}

sub __create_reply_queue {
    my $self = shift;
    my $client = $self->{_CLIENT};

    # Create an exclusive auto-delete queue for receiving RPC responses.

    my $reply_queue = '/temp-queue/tmp.';
    $reply_queue .= ('A'..'Z','a'..'z','0'..'9')[rand 62] for (1..16);
    $client->{reply_queue} = $reply_queue;

    $self->{_BUS}->subscribe(
        destination    => $reply_queue,
        ack            => 'auto',  # means none
        exclusive      => 1,       # implicit in most brokers
        on_receive_msg => sub {
            my ($body_ref, $msg_headers) = @_;

            local $@;
            my $resp = eval { decode_json($$body_ref) };

            unless (ref $resp eq 'HASH' && $resp->{jsonrpc} eq '2.0') {
                warn "Received invalid JSON-RPC 2.0 message";
                return;
            }

            if (exists $resp->{'id'}) {

                # Response of an RPC request

                my $req_id = $resp->{'id'};
                my $req = delete $client->{in_progress}->{$req_id};

                # Ignore unexpected responses
                return unless $req;

                # Cancel request timeout
                delete $req->{_timeout};

                if (exists $resp->{'result'}) {
                    # Success response
                    $req->{_response} = bless $resp, 'Beekeeper::JSONRPC::Response';
                    $req->{_on_success_cb}->($resp) if $req->{_on_success_cb};
                }
                else {
                    # Error response
                    $req->{_response} = bless $resp, 'Beekeeper::JSONRPC::Error';
                    $req->{_on_error_cb}->($resp) if $req->{_on_error_cb};
                }
        
                $req->{_waiting_response}->end;
            }
            else {

                # Unicasted notification

                bless $resp, 'Beekeeper::JSONRPC::Notification';
                $resp->{_headers} = $msg_headers;

                my $method = $resp->{method};

                unless (defined $method && $method =~ m/^([\.\w-]+)\.([\w-]+)$/) {
                    warn "Received notification with invalid method $method";
                    return;
                }

                my $cb = $client->{callbacks}->{"msg.$1.$2"} || 
                         $client->{callbacks}->{"msg.$1.*"};

                unless ($cb) {
                    warn "No callback found for received notification $method";
                    return;
                }

                $cb->($resp->{params}, $resp);
            }
        },
    );

    return $reply_queue;
}

sub wait_all_jobs {
    my $self = shift;

    # Wait for all pending jobs
    my $cv = delete $self->{_CLIENT}->{async_cv};

    # Make AnyEvent to allow one level of recursive condvar blocking, as we may
    # block both in $worker->__work_forever and here
    $WAITING && croak "Recursive condvar blocking wait attempted";
    local $WAITING = 1;
    local $AnyEvent::CondVar::Base::WAITING = 0;

    $cv->recv;
}

=head3 set_auth_tokens ( @tokens )

Add arbitrary auth tokens to subsequent jobs requests or notifications sent.

Workers get the caller tokens already set when executing jobs or notifications 
callbacks, and then these are piggybacked automatically.

This framework doesn't give any special meaning to these tokens.

=head3 get_auth_tokens

Get the list of current auth tokens in use.

=cut

sub set_auth_tokens {
    my ($self, @tokens) = @_;

    foreach my $token (@tokens) {
        croak "Invalid token $token" unless (defined $token && length $token && $token !~ m/[\x00\n\|]/);
    }

    $self->{_CLIENT}->{auth_tokens} = join('|', @tokens);
}

sub get_auth_tokens {
    my $self = shift;

    return split(/\|/, $self->{_CLIENT}->{auth_tokens});
}


# Transactions are currently unsupported as few brokers implements them

sub ___begin_transaction {
    my ($self, %args) = @_;

    croak "Already in a transaction" if $self->{transaction};

    $self->{transaction_id}++;

    if ($args{'client_side'}) {
        # Client side
        $self->{transaction} = TXN_CLIENT_SIDE;
    }
    else {
        # Server side
        $self->{transaction} = TXN_SERVER_SIDE;
        $self->{_BUS}->begin( transaction => $self->{transaction_id} );
    }
}

sub ___commit_transaction {
    my $self = shift;

    croak "No transaction was previously started" unless $self->{transaction};

    if ($self->{transaction} == TXN_CLIENT_SIDE) {
        # Client side
        $self->{_BUS}->flush_buffer( buffer_id => $self->{transaction_id} );
    }
    else {
        # Server side
        $self->{_BUS}->commit( transaction => $self->{transaction_id} );
    }

    $self->{transaction} = undef;
}

sub ___abort_transaction {
    my $self = shift;

    croak "No transaction was previously started" unless $self->{transaction};

    if ($self->{transaction} == TXN_CLIENT_SIDE) {
        # Client side
        $self->{_BUS}->discard_buffer( buffer_id => $self->{transaction_id} );
    }
    else {
        # Server side
        $self->{_BUS}->abort( transaction => $self->{transaction_id} );
    }

    $self->{transaction} = undef;
}

1;

=head1 SEE ALSO
 
L<Beekeeper::Bus::STOMP>, L<Beekeeper::Worker>.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
