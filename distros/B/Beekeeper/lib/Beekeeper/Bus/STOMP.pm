package Beekeeper::Bus::STOMP;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME
 
Beekeeper::Bus::STOMP - A lightweight asynchronous STOMP 1.1 / 1.2 client.
 
=head1 VERSION
 
Version 0.01

=head1 SYNOPSIS

  my $stomp = Beekeeper::STOMP->new(
      host  => 'localhost',
      user  => 'guest',
      pass  => 'guest',
      vhost => '/',
  );
  
  $stomp->connect( blocking => 1 );
   
  $stomp->send(
      destination => '/topic/foo',
      body        => 'Hello',
  );
  
  $stomp->subscribe(
      destination => '/topic/foo',
      on_receive_msg => sub {
          my ($body, $headers) = @_;
          print "Got message: $$body";
      },
  );
  
  $stomp->disconnect( blocking => 1 );

Most methods allows to send arbitrary headers along with commands.

Except for trivial cases, error checking is delegated to the server.

The STOMP specification can be found at L<http://stomp.github.com/>

=head1 TODO

- Send heartbeats

=head1 CONSTRUCTOR

=head3 new ( %options )

=over 4

=item host

Hostname or IP address of the STOMP server. It also accepts an array of adresses 
which conforms a cluster, in which case the connection will be stablished against
a randomly choosen node of the cluster.

=item port

Port of the STOMP server. If not specified use the STOMP default of 61613.

=item tls

Enable the use of TLS for STOMP connections.

=item vhost

Virtual host of the STOMP server to connect to.

=item user

Username used to authenticate against the server.

=item pass

Password used to authenticate against the server.

=item timeout

Connection timeout in fractional seconds before giving up. Default is 30 seconds.
If set to zero the connection to server it retried forever.

=item on_connect => $cb->( \%headers )

Optional user defined callback which is called after a connection is completed.

=item on_error => $cb->( $errmsg )

Optional user defined callback which is called when an error condition occurs.
If not specified, the deafult is to die with C<$errmsg>. As STOMP protocol doesn't 
allow errors, the connection was already closed when this is called.

=back

=cut

use AnyEvent::Impl::Perl;  # Perl backend is actually faster
use AnyEvent::Handle;
use List::Util 'shuffle';
use Carp;


sub new {
    my ($class, %args) = @_;

    my $self = {
        bus_id          => undef,
        cluster         => undef,
        handle          => undef,    # the socket
        hosts           => undef,    # list of all hosts in cluster
        server          => undef,    # server name and version
        version         => undef,    # stomp protocol version
        is_connected    => undef,    # true once connected
        is_rabbitmq     => undef,    # true if server is RabbitMQ
        is_activemq     => undef,    # true if server is Apache ActiveMQ
        is_artemis      => undef,    # true if server is Apache ActiveMQ Artemis
        connect_cb      => undef,    # user defined on_connect callback
        error_cb        => undef,    # user defined on_error callback
        try_hosts       => undef,    # list of hosts to try to connect
        connect_err     => undef,    # count of connection errors
        timeout_tmr     => undef,    # timer used for connection timeout
        reconnect_tmr   => undef,    # timer used for connection retry
        subscriptions   => {},       # current subscriptions
        subscr_cb       => {},       # subscription callbacks
        subscr_seq      => 0,        # sequence used for subscription ids
        receipt_cb      => {},       # receipt callbacks 
        receipt_seq     => 0,        # sequence used for receipt ids
        buffers         => {},       # raw stomp buffers
        config          => \%args,
    };

    $self->{bus_id}  = delete $args{'bus_id'};
    $self->{cluster} = delete $args{'cluster'} || $self->{bus_id};

    # User defined callbacks
    $self->{connect_cb} = delete $args{'on_connect'};
    $self->{error_cb}   = delete $args{'on_error'};

    bless $self, $class;
    return $self;
}

sub bus_id  { shift->{bus_id}  }
sub cluster { shift->{cluster} }


=head1 METHODS

=head3 connect ( %options )

Connect to the STOMP server and do handshake. On failure retries until timeout.

=over 4

=item blocking

When set to true this method acts as a blocking call: it does not return until
a connection has been established and handshake has been completed.

=back

=cut

sub connect {
    my ($self, %args) = @_;

    $self->{connect_cv} = AnyEvent->condvar;

    $self->_connect;

    $self->{connect_cv}->recv if $args{'blocking'};
    $self->{connect_cv} = undef;

    return $self->{is_connected};
}

sub _connect {
    my $self = shift;

    my $config = $self->{config};

    my $timeout = $config->{'timeout'};
    $timeout = 30 unless defined $timeout;

    # Ensure that timeout is set properly when the event loop was blocked
    AnyEvent->now_update;

    # Connection timeout handler
    if ($timeout && !$self->{timeout_tmr}) {
        $self->{timeout_tmr} = AnyEvent->timer( after => $timeout, cb => sub { 
            my $errmsg = "Could not connect to STOMP broker after $timeout seconds";
            $self->_reset_connection;
            $self->{connect_cv}->send;
            my $cb = $self->{error_cb};
            $cb ? $cb->($errmsg) : die "$errmsg\n";
        });
    }

    unless ($self->{hosts}) {
        # Initialize the list of cluster hosts
        my $hosts = $config->{'host'} || 'localhost';
        my @hosts = (ref $hosts eq 'ARRAY') ? @$hosts : ( $hosts );
        @hosts = map { $_=~ m/^([\w\-\.]+)$/s } @hosts; # untaint
        $self->{hosts} = [ shuffle @hosts ];
    }

    # Determine next host of cluster to connect to
    my $try_hosts = $self->{try_hosts} ||= [];
    @$try_hosts = @{$self->{hosts}} unless @$try_hosts;

    # TCP connection args
    my $host = shift @$try_hosts;
    my $tls  = $config->{'tls'}  || 0;
    my $port = $config->{'port'} || 61613;

    # STOMP connection args
    my %connect_hdr = (
        'login'          => $config->{'user'},
        'passcode'       => $config->{'pass'},
        'host'           => $config->{'vhost'},
        'heart-beat'     => '0,0',
        'accept-version' => '1.1,1.2',
    );

    foreach my $hdr (keys %connect_hdr) {
        # Remove empty headers, as all those are optional
        delete $connect_hdr{$hdr} unless defined $connect_hdr{$hdr};
    }

    my $frame_cmd;
    my %frame_hdr;
    my $body_lenght;

    $self->{handle} = AnyEvent::Handle->new(
        connect    => [ $host, $port ],
        tls        => $tls ? 'connect' : undef,
        keepalive  => 1,
        no_delay   => 1,
        on_connect => sub { 
            my ($fh, $host, $port) = @_;
            # Send CONNECT frame
            $fh->push_write( join "",
                "CONNECT\n",
                 map( "$_:$connect_hdr{$_}\n", keys %connect_hdr),
                "\n\x00",
            );
        },
        on_connect_error => sub {
            my ($fh, $errmsg) = @_;
            # Some error occurred while connection, such as an unresolved hostname
            # or connection refused. Try next host of cluster immediately, or retry
            # in few seconds if all hosts of the cluster are unresponsive
            $self->{connect_err}++;
            warn "Could not connect to STOMP broker at $host:$port: $errmsg\n" if ($self->{connect_err} <= @{$self->{hosts}});
            my $delay = @{$self->{try_hosts}} ? 0 : $self->{connect_err} / @{$self->{hosts}};
            $self->{reconnect_tmr} = AnyEvent->timer(
                after => ($delay < 10 ? $delay : 10),
                cb    => sub { $self->_connect },
            );
        },
        on_error => sub {
            my ($fh, $fatal, $errmsg) = @_;
            # Some IO error occurred, such as a read error
            $self->_reset_connection;
            my $cb = $self->{error_cb};
            $cb ? $cb->($errmsg) : die "$errmsg\n";
        },
        on_eof => sub {
            my ($fh) = @_;
            # The server has closed the connection cleanly
            my $errmsg = ($self->{server} || 'STOMP broker') . " at $host:$port has gone away";
            $self->_reset_connection;
            my $cb = $self->{error_cb};
            $cb ? $cb->($errmsg) : die "$errmsg\n";
        },
        on_read => sub {
            my ($fh) = @_;
            my $raw_headers;
            my ($line, $key, $value);

            PARSE_FRAME: {

                unless ($frame_cmd) {

                    # Parse header
                    $fh->{rbuf} =~ s/ ^.*?          # ignore heading garbage (just in case)
                                      \n*           # ignore server heartbeats
                                      ([A-Z]+)\n    # frame command
                                      (.*?)         # one or more lines of headers
                                      \n\n          # end of headers
                                    //sx or return;

                    $frame_cmd   = $1;
                    $raw_headers = $2;

                    foreach $line (split(/\n/, $raw_headers)) {
                        ($key, $value) = split(/:/, $line, 2);
                        # On duplicated headers only the first one is valid
                        $frame_hdr{$key} = $value unless (exists $frame_hdr{$key});
                    }

                    # content-length may be explicitly specified or not
                    $body_lenght = $frame_hdr{'content-length'};
                    $body_lenght = -1 unless (defined $body_lenght);
                }

                if ($body_lenght >= 0) {
                    # If body lenght is known wait until read enough data
                    return if (length $fh->{rbuf} < $body_lenght + 1);
                }
                else {
                    # If body lenght is unknown wait until read frame separator
                    $body_lenght = index($fh->{rbuf}, "\x00");
                    return if ($body_lenght == -1);
                }

                my $body = substr($fh->{rbuf}, 0, $body_lenght + 1, '');
                chop $body; # remove frame separator

                if ($frame_cmd eq 'MESSAGE') {
                    my $cb = $self->{subscr_cb}->{$frame_hdr{'subscription'}};
                    warn "Unexpected MESSAGE" unless $cb;
                    $cb->(\$body, { %frame_hdr }) if $cb;
                }
                elsif ($frame_cmd eq 'RECEIPT') {
                    my $cb = delete $self->{receipt_cb}->{$frame_hdr{'receipt-id'}};
                    warn "Unexpected RECEIPT" unless $cb;
                    $cb->() if $cb;
                }
                elsif ($frame_cmd eq 'CONNECTED') {
                    # If there was an error condition then log recovery
                    warn "Connected to STOMP broker at $host:$port\n" if $self->{connect_err};
                    $self->{is_connected}  = 1;
                    $self->{timeout_tmr}   = undef;
                    $self->{reconnect_tmr} = undef;
                    $self->{connect_err}   = undef;
                    $self->{connect_cv} && $self->{connect_cv}->send;
                    # Extract server properties
                    $self->{version} = $frame_hdr{'version'};
                    $self->{server}  = $frame_hdr{'server'};
                    $self->{is_rabbitmq} = 1 if ($self->{server} =~ m|RabbitMQ/|i); # "RabbitMQ/3.8.3"
                    $self->{is_activemq} = 1 if ($self->{server} =~ m|ActiveMQ/|i); # "ActiveMQ/5.15.12"
                    $self->{is_artemis}  = 1 if ($self->{server} =~ m|Artemis/|i);  # "ActiveMQ-Artemis/2.12.0 ActiveMQ Artemis Messaging Engine"
                    # Call the user defined callback
                    my $cb = $self->{connect_cb};
                    $cb->(\%frame_hdr) if $cb;
                }
                elsif ($frame_cmd eq 'ERROR') {
                    # Server will close the connection after reporting any error
                    my $errmsg = $frame_hdr{'message'};
                    $errmsg .= ": $body" if ($body && !$self->{is_activemq});
                    $self->_reset_connection;
                    my $cb = $self->{error_cb};
                    $cb ? $cb->($errmsg) : die "$errmsg\n";
                }

                # Prepare for next frame
                undef $frame_cmd;
                undef $body_lenght;
                %frame_hdr = ();

                redo PARSE_FRAME if (defined $fh->{rbuf} && length $fh->{rbuf} > 1);
            }
        },
    );

    1;
}

=head3 disconnect ( %options )

A client can disconnect from the server at anytime by closing the socket but 
there is no guarantee that the previously sent frames have been received by
the server. This method should be called to do a graceful shutdown, where the
client is assured that all previous frames have been received by the server.

=over 4

=item blocking

When set to true this method acts as a blocking call: it does not return until
disconnection has been completed.

=item on_success => $cb->()

Optional user defined callback which is called after disconnection is completed.

=back

=cut

sub disconnect {
    my ($self, %headers) = @_;

    my $blocking = delete $headers{'blocking'};
    my $done = $blocking ? AnyEvent->condvar : undef;

    # Success callback will be executed after disconnection
    my $cb = delete $headers{'on_success'};

    # Ask for a receipt
    my $receipt_id = 'disconnect' . $self->{receipt_seq}++;
    $headers{'receipt'} = $receipt_id;

    # Close socket when receipt it is received
    $self->{receipt_cb}->{$receipt_id} = sub {
        $self->_reset_connection;
        $done->send if $done;
        $cb->() if $cb;
    };

    $self->{handle}->push_write( join "",
        "DISCONNECT\n",
         map( "$_:$headers{$_}\n", keys %headers),
        "\n\x00",
    );

    $done->recv if $done;

    1;
}

sub _reset_connection {
    my $self = shift;

    $self->{handle}->destroy if $self->{handle};
    $self->{handle} = undef;

    $self->{is_connected}  = undef;
    $self->{reconnect_tmr} = undef;
    $self->{timeout_tmr}   = undef;
    $self->{connect_err}   = undef;

    $self->{subscriptions} = {};
    $self->{subscr_cb}     = {};
    $self->{receipt_cb}    = {};
    
    $self->{version}     = undef;
    $self->{server}      = undef;
    $self->{is_rabbitmq} = undef;
    $self->{is_activemq} = undef;
}

=head3 subscribe ( %headers )

Create a subscription to a given destination. When a message is received, it
will be passed to given on_receive_msg callback. Example:
  
  $stomp->subscribe(
      destination => '/topic/foo',
      on_receive_msg => sub {
          my ($body, \$headers) = @_;
          print "Got message from /topic/foo : $$body";
      },
  );
  
Any arbitrary header may be specified, and will be passed to the server.

=over 4

=item destination

The subscription requires the destination to which the client wants to subscribe,
usually in the form of '/topic/name' or '/queue/name'.

=item id

An id is necessary to uniquely identify the subscription within the STOMP session.
Since a single connection can have multiple open subscriptions with a server, 
this id allows the client and server to relate subsequent unsubscribe() or ack().

If not specified, an unique id is automatically generated.

=item ack

The valid values for the ack are 'auto', 'client', or 'client-individual'. 
If not specified the server will default to 'auto', which means that received 
messages doesn't require client acknowledgment.

=item on_success => $cb->()

Optional user defined callback which is called after subscription is completed.

=item on_receive_msg => $cb->( \$msg_body, \%msg_headers )

Required user defined callback which is called when a message is received.

=back

=cut

sub subscribe {
    my ($self, %headers) = @_;

    croak "Subscription destination was not specified" unless $headers{'destination'};
    croak "An on_receive_msg callback is required"     unless $headers{'on_receive_msg'};

    my $destination = $headers{'destination'};

    if ($self->{is_rabbitmq} && $destination =~ m|^/temp-queue/|) {
        # RabbitMQ automagically create temp-queues when used in reply-to headers,
        # and subscribe to it with a subscription id equal to destination
        $headers{'id'} = $destination;
    }

    if ($self->{is_activemq}) {
        # Specific multi level wildcard
        $headers{'destination'} =~ s/#/>/;
        # Specific prefetch header
        my $prefetch = delete $headers{'prefetch-count'};
        $headers{'activemq.prefetchSize'} = $prefetch if (defined $prefetch);
        # Specific exclusive header
        my $exclusive = delete $headers{'exclusive'};
        $headers{'activemq.exclusive'} = 'true' if ($exclusive);
    }

    # Determine subscription id
    my $subscr_id = $headers{'id'} ||= 'sub-' . $self->{subscr_seq}++;
    croak "Already subscribed to $destination" if (exists $self->{subscriptions}->{$destination});
    croak "A subscription with id $subscr_id already exists" if (exists $self->{subscr_cb}->{$subscr_id});

    # Set callback for receiving messages
    my $subscr_cb = delete $headers{'on_receive_msg'};
    $self->{subscr_cb}->{$subscr_id} = $subscr_cb;

    if ($self->{is_rabbitmq} && $destination =~ m|^/temp-queue/|) {
        # RabbitMQ will automagically create temp queues subscriptions server-side
        my $cb = delete $headers{'on_success'};
        AnyEvent::postpone { $cb->() } if ($cb);
        $self->{subscriptions}->{$destination} = $subscr_id;
        return $subscr_id;
    }

    # Handle success callback asking for a receipt
    if (my $cb = delete $headers{'on_success'}) {
        my $receipt_id = 'subscribe' . $self->{receipt_seq}++;
        $self->{receipt_cb}->{$receipt_id} = $cb;
        $headers{'receipt'} = $receipt_id;
    }

    $self->{handle}->push_write( join "",
        "SUBSCRIBE\n",
         map( "$_:$headers{$_}\n", keys %headers),
        "\n\x00",
    );

    # Assume subscribe success (otherwise connection will be closed by broker)
    $self->{subscriptions}->{$destination} = $subscr_id;

    return $subscr_id;
}

=head3 unsubscribe ( %headers )

Cancel an existing subscription, connection will no longer receive messages 
from that destination. Example:

  $stomp->unsubscribe( destination => '/topic/foo' );
  
At least one of destination or a subscription id is required.

=over 4

=item destination

The destination of an existing subscription.

=item id

The id of an existing subscription.

=item on_success => $cb->()

Optional user defined callback which is called after unsubscription is completed.

=back

=cut

sub unsubscribe {
    my ($self, %headers) = @_;

    my $subscr_id   = $headers{'id'};
    my $destination = delete $headers{'destination'};
    my $on_success  = delete $headers{'on_success'};

    unless ($subscr_id || $destination) {
        croak "Either a destination or a subscription id is required to unsubscribe"; 
    }

    if ($destination) {
        # Determine subscription id of given destination
        $subscr_id = $self->{subscriptions}->{$destination};
        croak "Not previously subscribed to $destination" unless ($subscr_id);
    }
    else {
        # Determine destination of given subscription id
        my $subscriptions = $self->{subscriptions};
        ($destination) = grep { $subscriptions->{$_} eq $subscr_id } keys %$subscriptions;
    }

    unless ($self->{subscr_cb}->{$subscr_id}) {
        croak "Not previously subscribed to a subscription with id $subscr_id";
    }

    # Can't remove on_receive_msg subscription callback right now as some messages
    # may be already sent by the broker. So ask for a receipt and remove callbacks
    # when it is received, indicating that unsubscription was actually completed
    my $receipt_id = 'unsubscribe' . $self->{receipt_seq}++;
    $headers{'id'} = $subscr_id;
    $headers{'receipt'} = $receipt_id;
    $self->{receipt_cb}->{$receipt_id} = sub {
        # Remove on_receive_msg callback
        delete $self->{subscr_cb}->{$subscr_id};
        delete $self->{subscriptions}->{$destination};
        # And call on_success callback, if any
        $on_success->() if $on_success;
    };

    $self->{handle}->push_write( join "",
        "UNSUBSCRIBE\n",
         map( "$_:$headers{$_}\n", keys %headers),
        "\n\x00",
    );

    1;
}

=head3 send ( %headers )

Sends a message to a destination in the messaging system. Example:

  $stomp->send(
      destination => '/topic/foo',
      body        => 'Hello!',
  );

Any arbitrary header may be specified, and will be passed to the server.

=over 4

=item destination

Mandatory header which indicates where to send the message.

=item body

Scalar or scalar reference containing a binary blob which conforms the body of
the message. May be omitted.

=item on_success => $cb->()

Optional user defined callback which is called after message was received by the server.

=back

=cut

sub send {
    my ($self, %headers) = @_;

    croak "Message destination was not specified" unless $headers{'destination'};

    # Message body may be passed by reference
    my $body = delete $headers{body};
    my $body_ref = (ref $body eq 'SCALAR') ? $body : \$body;
    $$body_ref = '' unless (defined $$body_ref);

    # Assume that body is an already encoded binary blob
    $headers{'content-length'} = length $$body_ref;

    # Ask receipt and set success callback
    if (my $cb = delete $headers{'on_success'}) {
        my $receipt_id = 'msg' . $self->{receipt_seq}++;
        $self->{receipt_cb}->{$receipt_id} = $cb;
        $headers{'receipt'} = $receipt_id;
    }

    if ($self->{is_activemq} && exists $headers{'expiration'}) {
        # Specific expiration header for ActiveMQ
        my $expiration = delete $headers{'expiration'};
        $headers{'expires'} = $expiration ? int($expiration + AE::now * 1000) : 0;
    }

    my $buffer_id = delete $headers{'buffer_id'};

    my $raw_stomp = join( "",
        "SEND\n",
         map( defined $headers{$_} ? "$_:$headers{$_}\n" : "", keys %headers),
        "\n",
         $$body_ref,
        "\x00",
    );

    if ($buffer_id) {
        # Do not send right now, wait until flush_buffer
        my $buffer = $self->{buffers}->{$buffer_id} ||= {};
        $buffer->{raw_stomp} .= $raw_stomp;
        $buffer->{receipt_ids}->{$headers{'receipt'}} = 1 if $headers{'receipt'};
        return 1;
    }

    $self->{handle}->push_write( $raw_stomp );

    if (defined $self->{handle}->{wbuf} && length $self->{handle}->{wbuf} > 0) {
        # push_write could not send all data to the handle because the kernel
        # write buffer is full. The size of kernel write bufer (which can be 
        # queried with 'sysctl net.ipv4.tcp_wmem') is choosed by the kernel
        # based on available memory, and is 4MB in known production servers.
        # This will happen after sending more that 4MB of data very quickly.
        # As client may be syncronous, wait until entire message is sent.
        my $flushed = AnyEvent->condvar;
        $self->{handle}->on_drain( $flushed );
        $flushed->recv;
        $self->{handle}->on_drain(); # clear
    }
}

=head3 ack ( %headers )

Used to acknowledge consumption of a message from a subscription using 'client'
or 'client-individual' acknowledgment. Any messages received from such a 
subscription will not be considered to have been consumed until the message has
been acknowledged via an ack() or nack().

Any arbitrary header may be specified, and will be passed to the server.

=over 4

=item id

STOMP 1.2 requires this header. It must contain the value of the C<ack> header
of the message being acknowledged.

=item message-id

STOMP 1.1 requires this header. It must contain containing the value of the
C<message-id> header of the message being acknowledged.

=item subscription

STOMP 1.1 requires this header. It must contain containing the value of the
C<subscription> header of the message being acknowledged.

=back

=cut

sub ack {
    my ($self, %headers) = @_;

    if ($self->{version} >= 1.2) {

        # STOMP 1.2 requires only 'id' header
        croak "Missing 'id' header" unless $headers{'id'};

        delete $headers{'message-id'};
        delete $headers{'subscription'};
    }
    else {

        # STOMP 1.1 requires 'subscription' and 'message-id' headers
        croak "Missing 'message-id' header"   unless $headers{'message-id'};
        croak "Missing 'subscription' header" unless $headers{'subscription'};

        delete $headers{'id'};
    }

    my $buffer_id = delete $headers{'buffer_id'};

    my $raw_stomp = join( "",
        "ACK\n",
         map( "$_:$headers{$_}\n", keys %headers),
        "\n\x00",
    );

    if ($buffer_id) {
        # Do not send right now, wait until flush_buffer
        $self->{buffers}->{$buffer_id}->{raw_stomp} .= $raw_stomp;
        return 1;
    }

    $self->{handle}->push_write( $raw_stomp );

    1;
}

=head3 nack ( %headers )

nack() is the opposite of ack(). It is used to tell the server that the client 
did not consume the message. The server can then either send the message to a
different client or discard it. The exact behavior is server specific.

=cut

sub nack {
    my ($self, %headers) = @_;

    croak "Missing 'id' header" unless $headers{'id'};

    if ($self->{version} >= 1.2) {
        # STOMP 1.2 requires only 'id' header
        delete $headers{'subscription'};
    }
    else {
        # STOMP 1.1 requires 'subscription' and 'message-id' headers
        croak "Missing 'subscription' header" unless $headers{'subscription'};
        $headers{'message-id'} = delete $headers{'id'};
    }

    my $buffer_id = delete $headers{'buffer_id'};

    my $raw_stomp = join( "",
        "NACK\n",
         map( "$_:$headers{$_}\n", keys %headers),
        "\n\x00",
    );

    if ($buffer_id) {
        # Do not send right now, wait until flush_buffer
        $self->{buffers}->{$buffer_id}->{raw_stomp} .= $raw_stomp;
        return 1;
    }

    $self->{handle}->push_write( $raw_stomp );

    1;
}

=head3 flush_buffer

Send several messages into a single socket write. This is more efficient
than individual send() calls because nagle's algorithm is disabled.

=cut

sub flush_buffer {
    my ($self, %args) = @_;

    my $buffer = delete $self->{buffers}->{$args{'buffer_id'}};

    # Nothing to do if nothing was buffered
    return unless $buffer;

    $self->{handle}->push_write( $buffer->{raw_stomp} );

    if (defined $self->{handle}->{wbuf} && length $self->{handle}->{wbuf} > 0) {
        # Kernel write buffer is full, see send() above
        my $flushed = AnyEvent->condvar;
        $self->{handle}->on_drain( $flushed );
        $flushed->recv;
        $self->{handle}->on_drain(); # clear
    }

    1;
}

=head3 discard_buffer

=cut

sub discard_buffer {
    my ($self, %args) = @_;

    my $buffer = delete $self->{buffers}->{$args{'buffer_id'}};

    # Nothing to do if nothing was buffered
    return unless $buffer;

    # Remove all receipt callbacks, as those will never be executed
    foreach my $receipt_id (keys %{$buffer->{receipt_ids}}) {
        delete $self->{receipt_cb}->{$receipt_id};
    }

    1;
}

=head3 begin ( %headers )

Used to start a transaction. Transactions in this case apply to sending and 
acknowledging: any messages sent or acknowledged during a transaction will be
handled atomically based on the transaction.

=over 4

=item transaction

Required transaction identifier which will be used for send, commit, abort, ack,
and nack frames to bind them to a given transaction.

=back

=cut

sub begin {
    my ($self, %headers) = @_;

    croak "Missing 'transaction' header" unless $headers{'transaction'};

    $self->{handle}->push_write( join "",
        "BEGIN\n",
         map( "$_:$headers{$_}\n", keys %headers),
        "\n\x00",
    );
}

=head3 commit ( %headers )

Used to commit a transaction in progress.

=over 4

=item transaction

The transaction id is required and identifies the transaction to commit.

=back

=cut

sub commit {
    my ($self, %headers) = @_;

    croak "Missing 'transaction' header" unless $headers{'transaction'};

    $self->{handle}->push_write( join "",
        "COMMIT\n",
         map( "$_:$headers{$_}\n", keys %headers),
        "\n\x00",
    );
}

=head3 abort ( %headers )

Used to roll back a transaction in progress.

=over 4

=item transaction

The transaction id is required and identifies the transaction to abort.

=back

=cut

sub abort {
    my ($self, %headers) = @_;

    croak "Missing 'transaction' header" unless $headers{'transaction'};

    $self->{handle}->push_write( join "",
        "ABORT\n",
         map( "$_:$headers{$_}\n", keys %headers),
        "\n\x00",
    );
}

sub DESTROY {
    my $self = shift;
    # Disconnect gracefully from server if already connected
    return unless ($self->{handle} && $self->{is_connected});
    $self->{handle}->push_write("DISCONNECT\n\n\x00");
}

1;

=encoding utf8

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
