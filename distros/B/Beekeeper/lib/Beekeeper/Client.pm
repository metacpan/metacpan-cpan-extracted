package Beekeeper::Client;

use strict;
use warnings;

our $VERSION = '0.06';

use Beekeeper::MQTT;
use Beekeeper::JSONRPC;
use Beekeeper::Config;

use JSON::XS;
use Sys::Hostname;
use Time::HiRes;
use Digest::SHA 'sha256_hex';
use Carp;

# Prefer AnyEvent perl backend as it is fast enough and it
# does not ignore exceptions thrown from within callbacks
$ENV{'PERL_ANYEVENT_MODEL'} ||= 'Perl' unless $AnyEvent::MODEL;

use constant QUEUE_LANES => 2;
use constant REQ_TIMEOUT => 60;

use Exporter 'import';

our @EXPORT_OK = qw(
    send_notification
    call_remote
    call_remote_async
    fire_remote
    wait_async_calls
    get_authentication_data
    set_authentication_data

    __do_rpc_request
    __create_response_topic
    __use_authorization_token
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
        forward_to     => undef,
        response_topic => undef,
        in_progress    => undef,
        curr_request   => undef,
        caller_id      => undef,
        caller_addr    => undef,
        auth_data      => undef,
        auth_salt      => undef,
        async_cv       => undef,
        correlation_id => 1,
        callbacks      => {},
    };

    unless (exists $args{'host'} && exists $args{'username'} && exists $args{'password'}) {

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
                $bus_id = $config->{$default}->{'bus_id'};
                %args = ( %{$config->{$default}}, bus_id => $bus_id, %args );
            }
        }
    }

    $self->{_CLIENT}->{forward_to} = delete $args{'forward_to'};
    $self->{_CLIENT}->{auth_salt}  = delete $args{'auth_salt'};

    # Start a fresh new MQTT session on connect
    $args{'clean_start'} = 1;

    # Make the MQTT session ends when the connection is closed
    $args{'session_expiry_interval'} = 0;

    # Keep only 1 unacked message (of QoS 1) in flight
    $args{'receive_maximum'} = 1;

    # Do not use topic aliases
    $args{'topic_alias_maximum'} = 0;


    $self->{_BUS} = Beekeeper::MQTT->new( %args );

    # Connect to MQTT broker
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


sub send_notification {
    my ($self, %args) = @_;

    my $fq_meth = $args{'method'} or croak "Method was not specified";

    $fq_meth .= '@' . $args{'address'} if (defined $args{'address'});

    $fq_meth =~ m/^     ( [\w-]+ (?:\.[\w-]+)* )
                     \. ( [\w-]+ ) 
                 (?: \@ ( [\w-]+ ) (\.[\w-]+)* )? $/x or croak "Invalid method '$fq_meth'";

    my ($service, $method, $remote_bus, $addr) = ($1, $2, $3, $4);

    my $json = encode_json({
        jsonrpc => '2.0',
        method  => "$service.$method",
        params  => $args{'params'},
    });

    my %send_args;

    my $local_bus = $self->{_BUS}->{bus_role};

    $remote_bus = $self->{_CLIENT}->{forward_to} unless (defined $remote_bus);

    if (defined $remote_bus) {

        $send_args{'topic'}  = "msg/$remote_bus-" . int( rand(QUEUE_LANES) + 1 );
        $send_args{'topic'} =~ tr|.|/|;

        $send_args{'fwd_to'} = "msg/$remote_bus/$service/$method";
        $send_args{'fwd_to'} .= "\@$addr" if (defined $addr && $addr =~ s/^\.//);
        $send_args{'fwd_to'} =~ tr|.|/|;
    }
    else {
        $send_args{'topic'} = "msg/$local_bus/$service/$method";
        $send_args{'topic'} =~ tr|.|/|;
    }

    $send_args{'auth'} = $self->{_CLIENT}->{auth_data} if defined $self->{_CLIENT}->{auth_data};
    $send_args{'clid'} = $self->{_CLIENT}->{caller_id} if defined $self->{_CLIENT}->{caller_id};

    if (exists $args{'buffer_id'}) {
        $send_args{'buffer_id'} = $args{'buffer_id'};
    }

    $self->{_BUS}->publish( payload => \$json, %send_args );
}


sub accept_notifications {
    my ($self, %args) = @_;

    my ($file, $line) = (caller)[1,2];
    my $at = "at $file line $line\n";

    my $callbacks = $self->{_CLIENT}->{callbacks};

    foreach my $fq_meth (keys %args) {

        $fq_meth =~ m/^  ( [\w-]+ (?: \.[\w-]+ )* ) 
                      \. ( [\w-]+ | \* ) $/x or croak "Invalid notification method '$fq_meth'";

        my ($service, $method) = ($1, $2);

        my $callback = $args{$fq_meth};

        unless (ref $callback eq 'CODE') {
            croak "Invalid callback for '$fq_meth'";
        }

        croak "Already accepting notifications '$fq_meth'" if exists $callbacks->{"msg.$fq_meth"};
        $callbacks->{"msg.$fq_meth"} = $callback;

        #TODO: Allow to accept private notifications without subscribing

        my $local_bus = $self->{_BUS}->{bus_role};

        my $topic = "msg/$local_bus/$service/$method";
        $topic =~ tr|.*|/#|;

        $self->{_BUS}->subscribe(
            topic      => $topic,
            on_publish => sub {
                my ($payload_ref, $mqtt_properties) = @_;

                local $@;
                my $request = eval { decode_json($$payload_ref) };

                unless (ref $request eq 'HASH' && $request->{jsonrpc} eq '2.0') {
                    warn "Received invalid JSON-RPC 2.0 notification $at";
                    return;
                }

                bless $request, 'Beekeeper::JSONRPC::Notification';
                $request->{_mqtt_prop} = $mqtt_properties;

                my $method = $request->{method};

                unless (defined $method && $method =~ m/^([\.\w-]+)\.([\w-]+)$/) {
                    warn "Received notification with invalid method '$method' $at";
                    return;
                }

                my $cb = $callbacks->{"msg.$1.$2"} || 
                         $callbacks->{"msg.$1.*"};

                unless ($cb) {
                    warn "No callback found for received notification '$method' $at";
                    return;
                }

                $cb->($request->{params}, $request);
            },
            on_suback => sub {
                my ($success, $prop) = @_;
                die "Could not subscribe to topic '$topic' $at" unless $success;
            }
        );
    }
}


sub stop_accepting_notifications {
    my ($self, @methods) = @_;

    my ($file, $line) = (caller)[1,2];
    my $at = "at $file line $line\n";

    croak "No method specified" unless @methods;

    foreach my $fq_meth (@methods) {

        $fq_meth =~ m/^  ( [\w-]+ (?: \.[\w-]+ )* ) 
                      \. ( [\w-]+ | \* ) $/x or croak "Invalid method '$fq_meth'";

        my ($service, $method) = ($1, $2);

        unless (defined $self->{_CLIENT}->{callbacks}->{"msg.$fq_meth"}) {
            carp "Not previously accepting notifications '$fq_meth'";
            next;
        }

        my $local_bus = $self->{_BUS}->{bus_role};

        my $topic = "msg/$local_bus/$service/$method";
        $topic =~ tr|.*|/#|;

        $self->{_BUS}->unsubscribe(
            topic       => $topic,
            on_unsuback => sub {
                my ($success, $prop) = @_;

                die "Could not unsubscribe from topic '$topic' $at" unless $success; 

                delete $self->{_CLIENT}->{callbacks}->{"msg.$fq_meth"};
            },
        );
    }
}


our $AE_WAITING;

sub call_remote {
    my $self = shift;

    my $req = $self->__do_rpc_request( @_, req_type => 'SYNCHRONOUS' );

    # Make AnyEvent allow one level of recursive condvar blocking, as we may
    # block both in $worker->__work_forever and in $client->__do_rpc_request
    $AE_WAITING && Carp::confess "Recursive condvar blocking wait attempted";
    local $AE_WAITING = 1;
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

sub call_remote_async {
    my $self = shift;

    my $req = $self->__do_rpc_request( @_, req_type => 'ASYNCHRONOUS' );
    
    return $req;
}

sub fire_remote {
    my $self = shift;

    # Send request to a worker, but do not wait for response
    $self->__do_rpc_request( @_, req_type => 'FIRE_FORGET' );

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
                 (?: \@ ( [\w-]+ ) (\.[\w-]+)* )? $/x or croak "Invalid method '$fq_meth'";

    my ($service, $method, $remote_bus, $addr) = ($1, $2, $3, $4);

    my %send_args;

    my $local_bus = $self->{_BUS}->{bus_role};

    $remote_bus = $client->{forward_to} unless (defined $remote_bus);

    # Local bus request sent to:  req/{local_bus}/{service_class}
    # Remote bus request sent to: req/{remote_bus}

    if (defined $remote_bus) {

        $send_args{'topic'} = "req/$remote_bus-" . int( rand(QUEUE_LANES) + 1 );
        $send_args{'topic'} =~ tr|.|/|;

        $send_args{'fwd_to'} = "req/$remote_bus/$service";
        $send_args{'fwd_to'} .= "\@$addr" if (defined $addr && $addr =~ s/^\.//);
        $send_args{'fwd_to'} =~ tr|.|/|;
    }
    else {
        $send_args{'topic'} = "req/$local_bus/$service";
        $send_args{'topic'} =~ tr|.|/|;
    }

    $send_args{'auth'} = $client->{auth_data} if defined $client->{auth_data};
    $send_args{'clid'} = $client->{caller_id} if defined $client->{caller_id};

    my $FIRE_FORGET = $args{req_type} eq 'FIRE_FORGET';
    my $SYNCHRONOUS = $args{req_type} eq 'SYNCHRONOUS';
    my $raise_error = $args{'raise_error'};
    my $req_id;

    # JSON-RPC call
    my $req = {
        jsonrpc => '2.0',
        method  => "$service.$method",
        params  => $args{'params'},
    };

    # Reuse or create a private topic which will receive responses
    $send_args{'response_topic'} = $client->{response_topic} ||
                                   $self->__create_response_topic;

    unless ($FIRE_FORGET) {
        # Assign an unique request id (unique only for this client)
        $req_id = $client->{correlation_id}++;
        $req->{'id'} = $req_id;
    }

    my $json = encode_json($req);

    if (exists $args{'buffer_id'}) {
        $send_args{'buffer_id'} = $args{'buffer_id'};
    }

    # Send request
    $self->{_BUS}->publish( 
        payload => \$json,
        qos     => 1,
        %send_args,
    );

    if ($FIRE_FORGET) {
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
    my $timeout = $args{'timeout'} || REQ_TIMEOUT;
    $req->{_timeout} = AnyEvent->timer( after => $timeout, cb => sub {
        my $req = delete $client->{in_progress}->{$req_id};
        $req->{_response} = Beekeeper::JSONRPC::Error->request_timeout;
        $req->{_on_error_cb}->($req->{_response}) if $req->{_on_error_cb};
        $req->{_waiting_response}->end;
    });

    bless $req, 'Beekeeper::JSONRPC::Request';
    return $req;
}

sub __create_response_topic {
    my $self = shift;
    my $client = $self->{_CLIENT};

    my ($file, $line) = (caller(2))[1,2];
    my $at = "at $file line $line\n";

    # Subscribe to an exclusive topic for receiving RPC responses

    my $response_topic = 'priv/' . $self->{_BUS}->{client_id};
    $client->{response_topic} = $response_topic;

    $self->{_BUS}->subscribe(
        topic       => $response_topic,
        maximum_qos => 0,
        on_publish  => sub {
            my ($payload_ref, $mqtt_properties) = @_;

            local $@;
            my $resp = eval { decode_json($$payload_ref) };

            unless (ref $resp eq 'HASH' && $resp->{jsonrpc} eq '2.0') {
                warn "Received invalid JSON-RPC 2.0 message $at";
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
                $resp->{_headers} = $mqtt_properties;

                my $method = $resp->{method};

                unless (defined $method && $method =~ m/^([\.\w-]+)\.([\w-]+)$/) {
                    warn "Received notification with invalid method '$method' $at";
                    return;
                }

                my $cb = $client->{callbacks}->{"msg.$1.$2"} || 
                         $client->{callbacks}->{"msg.$1.*"};

                unless ($cb) {
                    warn "No callback found for received notification '$method' $at";
                    return;
                }

                $cb->($resp->{params}, $resp);
            }
        },
        on_suback => sub {
            my ($success, $prop) = @_;
            die "Could not subscribe to response topic '$response_topic' $at" unless $success;
        }
    );

    return $response_topic;
}

sub wait_async_calls {
    my ($self) = @_;

    # Wait for all pending async requests
    my $cv = delete $self->{_CLIENT}->{async_cv};
    return unless defined $cv;

    # Make AnyEvent to allow one level of recursive condvar blocking, as we may
    # block both in $worker->__work_forever and here
    $AE_WAITING && Carp::confess "Recursive condvar blocking wait attempted";
    local $AE_WAITING = 1;
    local $AnyEvent::CondVar::Base::WAITING = 0;

    $cv->recv;
}


sub get_authentication_data {
    my ($self) = @_;

    $self->{_CLIENT}->{auth_data};
}

sub set_authentication_data {
    my ($self, $data) = @_;

    $self->{_CLIENT}->{auth_data} = $data;
}

sub __use_authorization_token {
    my ($self, $token) = @_;

    # Using a hashing function makes harder to access the wrong worker pool by mistake,
    # but it is not an effective access restriction: anyone with access to the backend
    # bus credentials can easily inspect and clone auth data tokens

    my $salt = $self->{_CLIENT}->{auth_salt} || '';

    my $adata_ref = \$self->{_CLIENT}->{auth_data};

    my $guard = Beekeeper::Client::Guard->new( $adata_ref );

    $$adata_ref = sha256_hex($token . $salt);

    return $guard;
}

1;

package
    Beekeeper::Client::Guard;   # hide from PAUSE

sub new {
    my ($class, $ref) = @_;

    bless [$ref, $$ref], $class;
}

sub DESTROY {

    ${$_[0]->[0]} = $_[0]->[1];
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::Client - Make RPC calls through message bus

=head1 VERSION
 
Version 0.06

=head1 SYNOPSIS

  my $client = Beekeeper::Client->instance;
  
  $client->send_notification(
      method => "my.service.foo",
      params => { foo => $foo },
  );
  
  my $resp = $client->call_remote(
      method => "my.service.bar",
      params => { %args },
  );
  
  die uneless $resp->success;
  
  print $resp->result;
  
  my $req = $client->call_remote_async(
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
  
  $client->wait_async_calls;

=head1 DESCRIPTION

This module connects to the message broker and makes RPC calls through message bus.

There are four different methods to do so:

  ┌───────────────────┬──────────────┬────────┬────────┬────────┐
  │ method            │ sent to      │ queued │ result │ blocks │
  ├───────────────────┼──────────────┼────────┼────────┼────────┤
  │ call_remote       │ 1 worker     │ yes    │ yes    │ yes    │
  │ call_remote_async │ 1 worker     │ yes    │ yes    │ no     │
  │ fire_remote       │ 1 worker     │ yes    │ no     │ no     │
  │ send_notification │ many workers │ no     │ no     │ no     │
  └───────────────────┴──────────────┴────────┴────────┴────────┘

All methods in this module are exported by default to C<Beekeeper::Worker>.

=head1 CONSTRUCTOR

=head3 instance( %args )

Connects to the message broker and returns a singleton instance.

Unless explicit connection parameters to the broker are provided it tries 
to connect using the parameters defined in config file C<bus.config.json>.

=head1 METHODS

=head3 send_notification ( %args )

Broadcast a notification to the message bus.

All clients and workers listening for given method will receive it. 

If no one is listening for it the notification will be discarded.

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

=head3 accept_notifications ( $method => $callback, ... )

Make this client start accepting specified notifications from message bus.

C<$method> is a string with the format "{service_class}.{method}". A default
or fallback handler can be specified using a wildcard as "{service_class}.*".

C<$callback> is a coderef that will be called when a notification is received.
When executed, the callback will receive a parameter C<$params> which contains
the notification value or data structure sent.

Please note that callbacks will not be executed timely if AnyEvent loop is not running.

=head3 stop_accepting_notifications ( $method, ... )

Make this client stop accepting specified notifications from message bus.

C<$method> must be one of the strings used previously in C<accept_notifications>.

=head3 stop_accepting_notifications ( $method, ... )

Make this client stop accepting specified notifications from message bus.

C<$method> must be one of the strings used previously in C<accept_notifications>.

=head3 call_remote ( %args )

Makes a synchronous RPC call to a service worker through the message bus.

It will wait (in the event loop) until a response is received, wich will be either
a L<Beekeeper::JSONRPC::Response> object or a L<Beekeeper::JSONRPC::Error>.

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
an error response. If set to false returns a L<Beekeeper::JSONRPC::Error> instead.

=back

=head3 call_remote_async ( %args )

Makes an asynchronous RPC call to a service worker through the message bus.

It returns immediately a L<Beekeeper::JSONRPC::Request> object which, once completed,
will have a defined C<response>.

This method  accepts parameters C<method>, C<params>, C<address> and C<timeout> 
the same as C<call_remote>. Additionally two callbacks can be specified:

=over 4

=item on_success

Callback which will be executed after receiving a successful response with a
L<Beekeeper::JSONRPC::Response> object as parameter. Must be a coderef.

=item on_error

Callback which will be executed after receiving an error response with a
L<Beekeeper::JSONRPC::Error> object as parameter. Must be a coderef.

=back

=head3 fire_remote ( %args )

Fire and forget an RPC call to a service worker through the message bus.

It returns undef immediately. The worker receiving the call will not send back a response.

This method accepts parameters C<method>, C<params> and C<address> the same as C<call_remote>.

=head3 wait_async_calls

Wait (running the event loop) until all calls made by C<call_remote_async> are completed
either by success, error or timeout.

=head3 set_authentication_data ( $data )

Add an arbitrary authentication data blob to subsequent calls or notifications sent.

This data persists for client lifetime in standalone clients. Within worker context
it persists until the end of current request only, and will be piggybacked on
calls made to another workers within the scope of current request.

The meaning of this data is application specific, this framework doesn't give 
any special one to it.

=head3 get_authentication_data

Gets the current authentication data blob.

=head1 SEE ALSO
 
L<Beekeeper::Worker>, L<Beekeeper::MQTT>.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
