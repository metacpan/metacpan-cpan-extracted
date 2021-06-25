package Beekeeper::MQTT;

use strict;
use warnings;

our $VERSION = '0.06';

use AnyEvent;
use AnyEvent::Handle;
use Time::HiRes;
use List::Util 'shuffle';
use Scalar::Util 'weaken';
use Exporter 'import';
use Carp;

our @EXPORT_OK;
our %EXPORT_TAGS;

our $DEBUG = 0;

EXPORT: {
    my (@const, @encode);
    foreach (keys %{Beekeeper::MQTT::}) {
        push @const, $_ if m/^MQTT_/;
        push @encode, $_ if m/^_(en|de)code/;
    }
    @EXPORT_OK = (@const, @encode);
    $EXPORT_TAGS{'const'} = \@const;
    $EXPORT_TAGS{'decode'} = \@encode;
}

# 2.1.2  Control Packet type

use constant MQTT_CONNECT     => 0x01;
use constant MQTT_CONNACK     => 0x02;
use constant MQTT_PUBLISH     => 0x03;
use constant MQTT_PUBACK      => 0x04;
use constant MQTT_PUBREC      => 0x05;
use constant MQTT_PUBREL      => 0x06;
use constant MQTT_PUBCOMP     => 0x07;
use constant MQTT_SUBSCRIBE   => 0x08;
use constant MQTT_SUBACK      => 0x09;
use constant MQTT_UNSUBSCRIBE => 0x0A;
use constant MQTT_UNSUBACK    => 0x0B;
use constant MQTT_PINGREQ     => 0x0C;
use constant MQTT_PINGRESP    => 0x0D;
use constant MQTT_DISCONNECT  => 0x0E;
use constant MQTT_AUTH        => 0x0F;

# 2.2.2.2  Properties

use constant MQTT_PAYLOAD_FORMAT_INDICATOR           => 0x01;  # byte           PUBLISH, Will Properties
use constant MQTT_MESSAGE_EXPIRY_INTERVAL            => 0x02;  # long int       PUBLISH, Will Properties
use constant MQTT_CONTENT_TYPE                       => 0x03;  # utf8 string    PUBLISH, Will Properties
use constant MQTT_RESPONSE_TOPIC                     => 0x08;  # utf8 string    PUBLISH, Will Properties
use constant MQTT_CORRELATION_DATA                   => 0x09;  # binary data    PUBLISH, Will Properties
use constant MQTT_SUBSCRIPTION_IDENTIFIER            => 0x0B;  # variable int   PUBLISH, SUBSCRIBE
use constant MQTT_SESSION_EXPIRY_INTERVAL            => 0x11;  # long int       CONNECT, CONNACK, DISCONNECT
use constant MQTT_ASSIGNED_CLIENT_IDENTIFIER         => 0x12;  # utf8 string    CONNACK
use constant MQTT_SERVER_KEEP_ALIVE                  => 0x13;  # short int      CONNACK
use constant MQTT_AUTHENTICATION_METHOD              => 0x15;  # utf8 string    CONNECT, CONNACK, AUTH
use constant MQTT_AUTHENTICATION_DATA                => 0x16;  # binary data    CONNECT, CONNACK, AUTH
use constant MQTT_REQUEST_PROBLEM_INFORMATION        => 0x17;  # byte           CONNECT
use constant MQTT_WILL_DELAY_INTERVAL                => 0x18;  # long int       Will Properties
use constant MQTT_REQUEST_RESPONSE_INFORMATION       => 0x19;  # byte           CONNECT
use constant MQTT_RESPONSE_INFORMATION               => 0x1A;  # utf8 string    CONNACK
use constant MQTT_SERVER_REFERENCE                   => 0x1C;  # utf8 string    CONNACK, DISCONNECT
use constant MQTT_REASON_STRING                      => 0x1F;  # utf8 string    CONNACK, PUBACK, PUBREC, PUBREL, PUBCOMP, SUBACK, UNSUBACK, DISCONNECT, AUTH
use constant MQTT_RECEIVE_MAXIMUM                    => 0x21;  # short int      CONNECT, CONNACK
use constant MQTT_TOPIC_ALIAS_MAXIMUM                => 0x22;  # short int      CONNECT, CONNACK
use constant MQTT_TOPIC_ALIAS                        => 0x23;  # short int      PUBLISH
use constant MQTT_MAXIMUM_QOS                        => 0x24;  # byte           CONNACK
use constant MQTT_RETAIN_AVAILABLE                   => 0x25;  # byte           CONNACK
use constant MQTT_USER_PROPERTY                      => 0x26;  # utf8 pair      CONNECT, CONNACK, PUBLISH, Will Properties, PUBACK, PUBREC, PUBREL, PUBCOMP, SUBSCRIBE, SUBACK, UNSUBSCRIBE, UNSUBACK, DISCONNECT, AUTH
use constant MQTT_MAXIMUM_PACKET_SIZE                => 0x27;  # long int       CONNECT, CONNACK
use constant MQTT_WILDCARD_SUBSCRIPTION_AVAILABLE    => 0x28;  # byte           CONNACK
use constant MQTT_SUBSCRIPTION_IDENTIFIER_AVAILABLE  => 0x29;  # byte           CONNACK
use constant MQTT_SHARED_SUBSCRIPTION_AVAILABLE      => 0x2A;  # byte           CONNACK   

# 2.4  Reason Code

my %Reason_code = (
    0x00 => 'Success',                                # CONNACK, PUBACK, PUBREC, PUBREL, PUBCOMP, UNSUBACK, AUTH
  # 0x00 => 'Normal disconnection',                   # DISCONNECT
  # 0x00 => 'Granted QoS 0',                          # SUBACK
  # 0x01 => 'Granted QoS 1',                          # SUBACK
  # 0x02 => 'Granted QoS 2',                          # SUBACK
    0x04 => 'Disconnect with Will Message',           # DISCONNECT
    0x10 => 'No matching subscribers',                # PUBACK, PUBREC
    0x11 => 'No subscription existed',                # UNSUBACK
    0x18 => 'Continue authentication',                # AUTH
    0x19 => 'Re-authenticate',                        # AUTH
    0x80 => 'Unspecified error',                      # CONNACK, PUBACK, PUBREC, SUBACK, UNSUBACK, DISCONNECT
    0x81 => 'Malformed Packet',                       # CONNACK, DISCONNECT
    0x82 => 'Protocol Error',                         # CONNACK, DISCONNECT
    0x83 => 'Implementation specific error',          # CONNACK, PUBACK, PUBREC, SUBACK, UNSUBACK, DISCONNECT
    0x84 => 'Unsupported Protocol Version',           # CONNACK
    0x85 => 'Client Identifier not valid',            # CONNACK
    0x86 => 'Bad User Name or Password',              # CONNACK
    0x87 => 'Not authorized',                         # CONNACK, PUBACK, PUBREC, SUBACK, UNSUBACK, DISCONNECT
    0x88 => 'Server unavailable',                     # CONNACK
    0x89 => 'Server busy',                            # CONNACK, DISCONNECT
    0x8A => 'Banned',                                 # CONNACK
    0x8B => 'Server shutting down',                   # DISCONNECT
    0x8C => 'Bad authentication method',              # CONNACK, DISCONNECT
    0x8D => 'Keep Alive timeout',                     # DISCONNECT
    0x8E => 'Session taken over',                     # DISCONNECT
    0x8F => 'Topic Filter invalid',                   # SUBACK, UNSUBACK, DISCONNECT
    0x90 => 'Topic Name invalid',                     # CONNACK, PUBACK, PUBREC, DISCONNECT
    0x91 => 'Packet Identifier in use',               # PUBACK, PUBREC, SUBACK, UNSUBACK
    0x92 => 'Packet Identifier not found',            # PUBREL, PUBCOMP
    0x93 => 'Receive Maximum exceeded',               # DISCONNECT
    0x94 => 'Topic Alias invalid',                    # DISCONNECT
    0x95 => 'Packet too large',                       # CONNACK, DISCONNECT
    0x96 => 'Message rate too high',                  # DISCONNECT
    0x97 => 'Quota exceeded',                         # CONNACK, PUBACK, PUBREC, SUBACK, DISCONNECT
    0x98 => 'Administrative action',                  # DISCONNECT
    0x99 => 'Payload format invalid',                 # CONNACK, PUBACK, PUBREC, DISCONNECT
    0x9A => 'Retain not supported',                   # CONNACK, DISCONNECT
    0x9B => 'QoS not supported',                      # CONNACK, DISCONNECT
    0x9C => 'Use another server',                     # CONNACK, DISCONNECT
    0x9D => 'Server moved',                           # CONNACK, DISCONNECT
    0x9E => 'Shared Subscriptions not supported',     # SUBACK, DISCONNECT
    0x9F => 'Connection rate exceeded',               # CONNACK, DISCONNECT
    0xA0 => 'Maximum connect time',                   # DISCONNECT
    0xA1 => 'Subscription Identifiers not supported', # SUBACK, DISCONNECT
    0xA2 => 'Wildcard Subscriptions not supported',   # SUBACK, DISCONNECT
);

# 3.9.3  Subscribe Reason Codes

my %Subscribe_reason_code = (
    %Reason_code,
    0x00 => 'Granted QoS 0',
    0x01 => 'Granted QoS 1',
    0x02 => 'Granted QoS 2',
);

# 3.14.2.1  Disconnect Reason Code

my %Disconnect_reason_code = (
    %Reason_code,
    0x00 => 'Normal disconnection',
);

sub _decode_byte {
    my ($packet, $offs) = @_;

    my $byte = unpack("C", substr($$packet, $$offs, 1));
    $$offs += 1;

    return $byte;
}

sub _decode_int_16 {
    my ($packet, $offs) = @_;

    my $int = unpack("n", substr($$packet, $$offs, 2));
    $$offs += 2;

    return $int;
}

sub _decode_int_32 {
    my ($packet, $offs) = @_;

    my $int = unpack("N", substr($$packet, $$offs, 4));
    $$offs += 4;

    return $int;
}

sub _decode_utf8_str {
    my ($packet, $offs) = @_;

    my $str = unpack("n/a", substr($$packet, $$offs));
    $$offs += 2 + length($str);
    utf8::decode($str);

    return $str;
}

sub _decode_binary_data {
    my ($packet, $offs) = @_;

    my $data = unpack("n/a", substr($$packet, $$offs));
    $$offs += 2 + length($data);

    return $data;
}

sub _decode_var_int {
    my ($packet, $offs) = @_;

    my $int = 0;
    my $mult = 1;
    my $byte;

    do {
        $byte = unpack("C", substr($$packet, $$offs, 1));
        $int += ($byte & 0x7F) * $mult;
        $mult *= 128;
        $$offs++;
    } while ($byte & 0x80);

    return $int;
}

sub _encode_var_int {
    return pack("C", $_[0]) if ($_[0] < 128);
    my @a = unpack("C*", pack("w", $_[0]));
    $a[0]  &= 0x7F;
    $a[-1] |= 0x80;
    return pack("C*", reverse @a);
}


sub new {
    my ($class, %args) = @_;

    my $self = {
        bus_id          => undef,
        bus_role        => undef,
        handle          => undef,    # the socket
        hosts           => undef,    # list of all hosts in cluster
        is_connected    => undef,    # true once connected
        try_hosts       => undef,    # list of hosts to try to connect
        connect_err     => undef,    # count of connection errors
        timeout_tmr     => undef,    # timer used for connection timeout
        reconnect_tmr   => undef,    # timer used for connection retry
        connack_cb      => undef,    # connack callback
        error_cb        => undef,    # error callback
        client_id       => undef,    # client id
        server_prop     => {},       # server properties
        server_alias    => {},       # server topic aliases
        client_alias    => {},       # client topic aliases
        subscriptions   => {},       # topic subscriptions
        subscr_cb       => {},       # subscription callbacks
        packet_cb       => {},       # packet callbacks 
        buffers         => {},       # raw mqtt buffers
        packet_seq      => 1,        # sequence used for packet ids
        subscr_seq      => 1,        # sequence used for subscription ids
        alias_seq       => 1,        # sequence used for topic alias ids
        use_alias       => 0,        # topic alias enabled
        config          => \%args,
    };

    $self->{bus_id}   = delete $args{'bus_id'};
    $self->{bus_role} = delete $args{'bus_role'} || $self->{bus_id};
    $self->{error_cb} = delete $args{'on_error'};

    bless $self, $class;
    return $self;
}

sub bus_id   { $_[0]->{bus_id}   }
sub bus_role { $_[0]->{bus_role} }

sub _fatal {
    my ($self, $errstr) = @_;
    die "(" . __PACKAGE__ . ") $errstr\n" unless $self->{error_cb};
    $self->{error_cb}->($errstr);
}

our $BUSY_SINCE = undef;
our $BUSY_TIME  = 0;

sub connect {
    my ($self, %args) = @_;

    $self->{connack_cb} = $args{'on_connack'};
    $self->{connect_cv} = AnyEvent->condvar;

    $self->_connect;

    $self->{connect_cv}->recv if $args{'blocking'};
    $self->{connect_cv} = undef;

    return $args{'blocking'} ? $self->{is_connected} : 1;
}

sub _connect {
    my ($self) = @_;
    weaken($self);

    my $config = $self->{config};

    my $timeout = $config->{'timeout'};
    $timeout = 30 unless defined $timeout;

    # Ensure that timeout is set properly when the event loop was blocked
    AnyEvent->now_update;

    # Connection timeout handler
    if ($timeout && !$self->{timeout_tmr}) {
        $self->{timeout_tmr} = AnyEvent->timer( after => $timeout, cb => sub { 
            $self->_reset_connection;
            $self->{connect_cv}->send;
            $self->_fatal("Could not connect to MQTT broker after $timeout seconds");
        });
    }

    unless ($self->{hosts}) {
        # Initialize the list of cluster hosts
        my $hosts = $config->{'host'} || 'localhost';
        my @hosts = (ref $hosts eq 'ARRAY') ? @$hosts : ( $hosts );
        $self->{hosts} = [ shuffle @hosts ];
    }

    # Determine next host of cluster to connect to
    my $try_hosts = $self->{try_hosts} ||= [];
    @$try_hosts = @{$self->{hosts}} unless @$try_hosts;

    # TCP connection args
    my $host = shift @$try_hosts;
    my $tls  = $config->{'tls'}  || 0;
    my $port = $config->{'port'} || ( $tls ? 8883 : 1883 );

    ($host) = ($host =~ m/^([a-zA-Z0-9\-\.]+)$/s); # untaint
    ($port) = ($port =~ m/^([0-9]+)$/s);

    $self->{handle} = AnyEvent::Handle->new(
        connect    => [ $host, $port ],
        tls        => $tls ? 'connect' : undef,
        keepalive  => 1,
        no_delay   => 1,
        on_connect => sub {
            my ($fh, $host, $port) = @_;
            # Send CONNECT packet
            $self->{server_prop}->{host} = $host;
            $self->{server_prop}->{port} = $port;
            $self->_send_connect;
        },
        on_connect_error => sub {
            my ($fh, $errmsg) = @_;
            # Some error occurred while connection, such as an unresolved hostname
            # or connection refused. Try next host of cluster immediately, or retry
            # in few seconds if all hosts of the cluster are unresponsive
            $self->{connect_err}++;
            warn "Could not connect to MQTT broker at $host:$port: $errmsg\n" if ($self->{connect_err} <= @{$self->{hosts}});
            my $delay = @{$self->{try_hosts}} ? 0 : $self->{connect_err} / @{$self->{hosts}};
            $self->{reconnect_tmr} = AnyEvent->timer(
                after => ($delay < 10 ? $delay : 10),
                cb    => sub { $self->_connect },
            );
        },
        on_error => sub {
            my ($fh, $fatal, $errmsg) = @_;
            # Some error occurred, such as a read error
            $self->_reset_connection;
            $self->_fatal("Error on connection to MQTT broker at $host:$port: $errmsg");
        },
        on_eof => sub {
            my ($fh) = @_;
            # The server has closed the connection without sending DISCONNECT
            $self->_reset_connection;
            $self->_fatal("MQTT broker at $host:$port has gone away");
        },
        on_read => sub {
            my ($fh) = @_;

            my $packet_type;
            my $packet_flags;

            my $rbuff_len;
            my $packet_len;

            my $mult;
            my $offs;
            my $byte;

            my $timing_packets;

            unless (defined $BUSY_SINCE) {
                # Measure time elapsed while processing incoming packets
                $BUSY_SINCE = Time::HiRes::time;
                $timing_packets = 1; 
            }

            PARSE_PACKET: {

                $rbuff_len = length $fh->{rbuf};

                last PARSE_PACKET unless $rbuff_len >= 2;

                unless ($packet_type) {

                    $packet_len = 0;
                    $mult = 1;
                    $offs = 1;

                    PARSE_LEN: {
                        $byte = unpack "C", substr( $fh->{rbuf}, $offs++, 1 );
                        $packet_len += ($byte & 0x7f) * $mult;
                        last unless ($byte & 0x80);
                        last PARSE_PACKET if ($offs >= $rbuff_len); # Not enough data
                        $mult *= 128;
                        redo if ($offs < 5);
                    }

                    #TODO: Check max packet size

                    $byte = unpack('C', substr( $fh->{rbuf}, 0, 1 ));
                    $packet_type  = $byte >> 4;
                    $packet_flags = $byte & 0x0F;
                }

                if ($rbuff_len < ($offs + $packet_len)) {
                    # Not enough data
                    last PARSE_PACKET;
                }

                # Consume packet from buffer
                my $packet = substr($fh->{rbuf}, 0, ($offs + $packet_len), '');

                # Trim fixed header from packet
                substr($packet, 0, $offs, '');

                if ($packet_type == MQTT_PUBLISH) {

                    $self->_receive_publish(\$packet, $packet_flags);
                }
                elsif ($packet_type == MQTT_PUBACK) {

                    $self->_receive_puback(\$packet);
                }
                elsif ($packet_type == MQTT_PUBREC) {

                    $self->_receive_pubrec(\$packet);
                }
                elsif ($packet_type == MQTT_PUBREL) {
                    
                    $self->_receive_pubrel(\$packet);
                }
                elsif ($packet_type == MQTT_PUBCOMP) {

                    $self->_receive_pubcomp(\$packet);
                }
                elsif ($packet_type == MQTT_PINGREQ) {

                    $self->pingresp;
                }
                elsif ($packet_type == MQTT_PINGRESP) {

                    # Client takes no action on receiving PINGRESP
                }
                elsif ($packet_type == MQTT_SUBACK) {

                    $self->_receive_suback(\$packet);
                }
                elsif ($packet_type == MQTT_UNSUBACK) {

                    $self->_receive_unsuback(\$packet);
                }
                elsif ($packet_type == MQTT_CONNACK) {

                    $self->_receive_connack(\$packet);
                }
                elsif ($packet_type == MQTT_DISCONNECT) {

                    $self->_receive_disconnect(\$packet);
                }
                elsif ($packet_type == MQTT_AUTH) {

                    $self->_receive_auth(\$packet);
                }
                else {
                    # Protocol error
                    $self->_fatal("Received packet with unknown type $packet_type");
                }

                # Prepare for next frame
                undef $packet_type;

                # Handle could have been destroyed at this point
                redo PARSE_PACKET if defined $fh->{rbuf};
            }

            if (defined $timing_packets) {
                $BUSY_TIME += Time::HiRes::time - $BUSY_SINCE;
                undef $BUSY_SINCE;
            }
        },
    );

    1;
}

sub _send_connect {
    my ($self) = @_;

    my %prop = %{$self->{config}};

    my $username    = delete $prop{'username'};
    my $password    = delete $prop{'password'};
    my $client_id   = delete $prop{'client_id'};
    my $clean_start = delete $prop{'clean_start'};
    my $keep_alive  = delete $prop{'keep_alive'};
    my $will        = delete $prop{'will'};

    unless ($client_id) {
        $client_id = '';
        $client_id .= ('0'..'9','a'..'z','A'..'Z')[rand 62] for (1..22);
    }

    $self->{client_id} = $client_id;


    # 3.1.2.11  Properties

    my $raw_prop = '';

    if (exists $prop{'session_expiry_interval'}) {
        # 3.1.2.11.2  Session Expiry Interval  (long int)
        $raw_prop .= pack("C N", MQTT_SESSION_EXPIRY_INTERVAL, delete $prop{'session_expiry_interval'});
    }

    if (exists $prop{'receive_maximum'}) {
        # 3.1.2.11.3  Receive Maximum  (short int)
        $raw_prop .= pack("C n", MQTT_RECEIVE_MAXIMUM, delete $prop{'receive_maximum'});
    }

    if (exists $prop{'maximum_packet_size'}) {
        # 3.1.2.11.4  Maximum Packet Size  (long int)
        $raw_prop .= pack("C N", MQTT_MAXIMUM_PACKET_SIZE, delete $prop{'maximum_packet_size'});
    }

    if (exists $prop{'topic_alias_maximum'}) {
        # 3.1.2.11.5  Topic Alias Maximum  (short int)
        $raw_prop .= pack("C n", MQTT_TOPIC_ALIAS_MAXIMUM, delete $prop{'topic_alias_maximum'});
    }

    if (exists $prop{'request_response_information'}) {
        # 3.1.2.11.6  Request Response Information  (byte)  
        $raw_prop .= pack("C C", MQTT_REQUEST_RESPONSE_INFORMATION, delete $prop{'request_response_information'});
    }

    if (exists $prop{'request_problem_information'}) {
        # 3.1.2.11.7  Request Problem Information  (byte)
        $raw_prop .= pack("C C", MQTT_REQUEST_PROBLEM_INFORMATION, delete $prop{'request_problem_information'});
    }

    if (exists $prop{'authentication_method'}) {
        # 3.1.2.11.9  Authentication Method  (utf8 string)
        utf8::encode( $prop{'authentication_method'} );
        $raw_prop .= pack("C n/a*", MQTT_AUTHENTICATION_METHOD, delete $prop{'authentication_method'});
    }

    if (exists $prop{'authentication_data'}) {
        # 3.1.2.11.10  Authentication Data  (binary data)
        $raw_prop .= pack("C n", MQTT_AUTHENTICATION_DATA, delete $prop{'authentication_data'});
    }

    foreach my $key (keys %prop) {
        # 3.1.2.11.8  User Property  (utf8 string pair)
        my $val = $prop{$key};
        next unless defined $val;
        utf8::encode( $key );
        utf8::encode( $val );
        $raw_prop .= pack("C n/a* n/a*", MQTT_USER_PROPERTY, $key, $val);
    }


    # 3.1.2  Variable Header

    # 3.1.2.1  Protocol Name  (utf8 string)
    my $raw_mqtt = pack("n/a*", "MQTT");

    # 3.1.2.2  Protocol Version  (byte)
    $raw_mqtt .= pack("C", 5);

    # 3.1.2.3  Connect Flags  (byte)
    my $flags = 0;
    $flags |= 0x02 if $clean_start;           # 3.1.2.4  Clean Start
    $flags |= 0x80 if defined $username;      # 3.1.2.8  User Name Flag
    $flags |= 0x40 if defined $password;      # 3.1.2.9  Password Flag

    if ($will) {
        $flags |= 0x04;                       # 3.1.2.5  Will Flag
        $flags |= $will->{'qos'} << 3;        # 3.1.2.6  Will QoS
        $flags |= 0x20 if $will->{'retain'};  # 3.1.2.7  Will Retain
    }

    $raw_mqtt .= pack("C", $flags);

    # 3.1.2.10  Keep Alive  (short int)
    $raw_mqtt .= pack("n", $keep_alive || 0);   

    # 3.1.2.11  Properties
    $raw_mqtt .= _encode_var_int(length $raw_prop);
    $raw_mqtt .= $raw_prop;


    # 3.1.3  Payload

    # 3.1.3.1  Client Identifier  (utf8 string)
    $raw_mqtt .= pack("n/a*", $client_id);

    if ($will) {

        #TODO: 3.1.3.2  Will Properties
        my $will_prop = '';

        $raw_mqtt .= _encode_var_int(length $will_prop);
        $raw_mqtt .= $will_prop;

        # 3.1.3.3  Will Topic  (utf8 string)
        utf8::encode( $will->{'topic'});
        $raw_mqtt .= pack("n/a*", $will->{'topic'});

        # 3.1.3.4  Will Payload  (binary data)
        $raw_mqtt .= pack("n/a*", $will->{'payload'});
    }

    if (defined $username) {
        # 3.1.3.5  Username  (utf8 string)
        utf8::encode( $username );
        $raw_mqtt .= pack("n/a*", $username);
    }
    
    if (defined $password) {
        # 3.1.3.6  Password  (binary data)
        $raw_mqtt .= pack("n/a*", $password);
    }

    $self->{handle}->push_write( 
        pack("C", MQTT_CONNECT << 4)      .  # 3.1.1  Packet type 
        _encode_var_int(length $raw_mqtt) .  # 3.1.1  Packet length
        $raw_mqtt
    );
}

sub _receive_connack {
    my ($self, $packet) = @_;

    my $prop = $self->{server_prop};
    my $offs = 0;

    # 3.2.2.1  Acknowledge flags  (byte)
    my $ack_flags = _decode_byte($packet, \$offs);
    $prop->{'session_present'} = $ack_flags & 0x01;

    # 3.2.2.2  Reason code  (byte)
    my $reason_code = _decode_byte($packet, \$offs);
    $prop->{'reason_code'} = $reason_code;
    $prop->{'reason'} = $Reason_code{$reason_code};
    
    # 3.2.2.3.1  Properties Length  (variable length int)
    my $prop_len = _decode_var_int($packet, \$offs);
    my $prop_end = $offs + $prop_len;

    while ($offs < $prop_end) {

        my $prop_id = _decode_byte($packet, \$offs);

        if ($prop_id == MQTT_SESSION_EXPIRY_INTERVAL) {
            # 3.2.2.3.2  Session Expiry Interval  (long int)
            $prop->{'session_expiry_interval'} = _decode_int_32($packet, \$offs);
        }
        elsif ($prop_id == MQTT_RECEIVE_MAXIMUM) {
            # 3.2.2.3.3  Receive Maximum  (short int)
            $prop->{'receive_maximum'} = _decode_int_16($packet, \$offs);
        }
        elsif ($prop_id == MQTT_MAXIMUM_QOS) {
            # 3.2.2.3.4  Maximum QoS  (byte)
            $prop->{'maximum_qos'} = _decode_byte($packet, \$offs);
        }
        elsif ($prop_id == MQTT_RETAIN_AVAILABLE) {
            # 3.2.2.3.5  Retain Available  (byte)
            $prop->{'retain_available'} = _decode_byte($packet, \$offs);
        }
        elsif ($prop_id == MQTT_MAXIMUM_PACKET_SIZE) {
            # 3.2.2.3.6  Maximum Packet Size  (long int)
            $prop->{'maximum_packet_size'} = _decode_int_32($packet, \$offs);
        }
        elsif ($prop_id == MQTT_ASSIGNED_CLIENT_IDENTIFIER) {
            # 3.2.2.3.7  Assigned Client Identifier  (utf8 string)
            $prop->{'assigned_client_identifier'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_TOPIC_ALIAS_MAXIMUM) {
            # 3.2.2.3.8  Topic Alias Maximum  (short int)
            $prop->{'topic_alias_maximum'} = _decode_int_16($packet, \$offs);
        }
        elsif ($prop_id == MQTT_REASON_STRING) {
            # 3.2.2.3.9  Reason String  (utf8 string)
            $prop->{'reason_string'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_USER_PROPERTY) {
            # 3.2.2.3.10  User Property  (utf8 string pair)
            my $key = _decode_utf8_str($packet, \$offs);
            my $val = _decode_utf8_str($packet, \$offs);
            $prop->{$key} = $val;
        }
        elsif ($prop_id == MQTT_WILDCARD_SUBSCRIPTION_AVAILABLE) {
            # 3.2.2.3.11  Wildcard Subscription Available  (byte)
            $prop->{'wildcard_subscription_available'} = _decode_byte($packet, \$offs);
        }
        elsif ($prop_id == MQTT_SUBSCRIPTION_IDENTIFIER_AVAILABLE) {
            # 3.2.2.3.12  Subscription Identifiers Available  (byte)
            $prop->{'subscription_identifier_available'} = _decode_byte($packet, \$offs);
        }
        elsif ($prop_id == MQTT_SHARED_SUBSCRIPTION_AVAILABLE) {
            # 3.2.2.3.13  Shared Subscription Available  (byte)
            $prop->{'shared_subscription_available'} = _decode_byte($packet, \$offs);
        }
        elsif ($prop_id == MQTT_SERVER_KEEP_ALIVE) {
            # 3.2.2.3.14  Server Keep Alive  (short int)
            $prop->{'server_keep_alive'} = _decode_int_16($packet, \$offs);
        }
        elsif ($prop_id == MQTT_RESPONSE_INFORMATION) {
            # 3.2.2.3.15  Response Information  (utf8 string)
            $prop->{'response_information'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_SERVER_REFERENCE) {
            # 3.2.2.3.16  Server Reference  (utf8 string)
            $prop->{'server_reference'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_AUTHENTICATION_METHOD) {
            # 3.2.2.3.17  Authentication Method  (utf8 string)
            $prop->{'authentication_method'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_AUTHENTICATION_DATA) {
            # 3.2.2.3.18 Authentication Data  (binary data)
            $prop->{'authentication_data'} = _decode_binary_data($packet, \$offs);
        }
        else {
            # Protocol error
            $self->_fatal("Received CONNACK with unknown property $prop_id"); 
        }
    }

    my $success = ($reason_code == 0x00);

    unless ( $success ) {
        # Server will close the connection
        # warn "Served refused CONNACK: $reason";
        #TODO: handle
    }

    $self->{is_connected}  = 1;
    $self->{timeout_tmr}   = undef;
    $self->{reconnect_tmr} = undef;
    $self->{connect_err}   = undef;

    #TODO: ... blocking connection
    $self->{connect_cv}->send if $self->{connect_cv};

    # Execute CONNACK callback
    my $connack_cb = $self->{connack_cb};
    $connack_cb->($success, $prop) if $connack_cb;
}


sub disconnect {
    my ($self, %args) = @_;

    unless (defined $self->{handle}) {
        carp "Already disconnected from MQTT broker";
        return;
    }

    my $reason_code = delete $args{'reason_code'};

    # 3.14.2.2  Properties

    my $raw_prop = '';

    if (exists $args{'session_expiry_interval'}) {
        # 3.14.2.2.2  Session Expiry Interval  (long int)
        utf8::encode( $args{'session_expiry_interval'} );
        $raw_prop .= pack("C n/a*", MQTT_SESSION_EXPIRY_INTERVAL, delete $args{'session_expiry_interval'});
    }

    if (exists $args{'reason_string'}) {
        # 3.14.2.2.3  Reason String  (utf8 string)
        utf8::encode( $args{'reason_string'} );
        $raw_prop .= pack("C n/a*", MQTT_REASON_STRING, delete $args{'reason_string'});
    }

    if (exists $args{'server_reference'}) {
        # 3.14.2.2.5  Server Reference  (utf8 string)
        utf8::encode( $args{'server_reference'} );
        $raw_prop .= pack("C n/a*", MQTT_SERVER_REFERENCE, delete $args{'server_reference'});
    }

    foreach my $key (keys %args) {
        # 3.14.2.2.4  User Property  (utf8 string pair)
        my $val = $args{$key};
        next unless defined $val;
        utf8::encode( $key );
        utf8::encode( $val );
        $raw_prop .= pack("C n/a* n/a*", MQTT_USER_PROPERTY, $key, $val);
    }

    # 3.14.2  Variable Header

    # 3.14.2.1  Disconnect Reason Code  (byte)
    my $raw_mqtt = pack("C", $reason_code || 0);

    # 3.14.2.2  Properties
    $raw_mqtt .= _encode_var_int(length $raw_prop);
    $raw_mqtt .= $raw_prop;

    $self->{handle}->push_write( 
        pack("C", MQTT_DISCONNECT << 4)   .  # 3.14.1  Packet type 
        _encode_var_int(length $raw_mqtt) .  # 3.14.1  Packet length
        $raw_mqtt
    );

    $self->_reset_connection;
}

sub _reset_connection {
    my ($self) = @_;

    $self->{handle} = undef;

    $self->{is_connected}  = undef;
    $self->{reconnect_tmr} = undef;
    $self->{timeout_tmr}   = undef;
    $self->{connect_err}   = undef;

    $self->{server_prop}   = {};
    $self->{server_alias}  = {};
    $self->{client_alias}  = {};
    $self->{subscriptions} = {};
    $self->{subscr_cb}     = {};
    $self->{packet_cb}     = {};
    $self->{buffers}       = {};
    $self->{packet_seq}    = 1;
    $self->{subscr_seq}    = 1;
    $self->{alias_seq}     = 1;
    $self->{use_alias}     = 0;
}

sub _receive_disconnect {
    my ($self, $packet) = @_;

    # Handle abbreviated packet
    $$packet = "\x00\x00" if (length $$packet == 0);

    # 3.14.2.1  Reason Code  (byte)
    my $offs = 0;
    my $reason_code = _decode_byte($packet, \$offs);
    my $reason = $Disconnect_reason_code{$reason_code};

    # 3.14.2.2.1  Property Length  (variable length int)
    my $prop_len = _decode_var_int($packet, \$offs);
    my $prop_end = $offs + $prop_len;

    my %prop = (
        'reason_code' => $reason_code,
        'reason'      => $reason,
    );

    while ($offs < $prop_end) {

        my $prop_id = _decode_byte($packet, \$offs);

        if ($prop_id == MQTT_SESSION_EXPIRY_INTERVAL) {
            # 3.14.2.2.2  Session Expiry Interval  (long int)
            $prop{'session_expiry_interval'} = _decode_int_32($packet, \$offs);
        }
        elsif ($prop_id == MQTT_REASON_STRING) {
            # 3.14.2.2.3  Reason String  (utf8 string)
            $prop{'reason_string'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_USER_PROPERTY) {
            # 3.14.2.2.4  User Property  (utf8 string pair)
            my $key = _decode_utf8_str($packet, \$offs);
            my $val = _decode_utf8_str($packet, \$offs);
            $prop{$key} = $val;
        }
        elsif ($prop_id == MQTT_SERVER_REFERENCE) {
            # 3.14.2.2.5  Server Reference  (utf8 string)
            $prop{'server_reference'} = _decode_utf8_str($packet, \$offs);
        }
        else {
            # Protocol error
            $self->_fatal("Received DISCONNECT with unknown property $prop_id"); 
        }
    }

    $self->_reset_connection;

    my $disconn_cb = $self->{disconn_cb};

    if ($disconn_cb) {
        $disconn_cb->(\%prop);
    }
    else {
        $self->_fatal("Disconnected from MQTT broker: $prop{reason}");
    }
}


sub pingreq {
    my ($self) = @_;

    $self->{handle}->push_write( 
        pack( "C C",
            MQTT_PINGREQ << 4,  # 3.12.1  Packet type 
            0,                  # 3.12.1  Remaining length
        )
    );
}

sub pingresp {
    my ($self) = @_;

    $self->{handle}->push_write( 
        pack( "C C",
            MQTT_PINGRESP << 4,  # 3.13.1  Packet type 
            0,                   # 3.13.1  Remaining length
        )
    );
}


sub subscribe {
    my ($self, %args) = @_;

    my $topic      = delete $args{'topic'};
    my $topics     = delete $args{'topics'};
    my $subscr_cb  = delete $args{'on_publish'};
    my $suback_cb  = delete $args{'on_suback'};
    my $max_qos    = delete $args{'maximum_qos'};
    my $no_local   = delete $args{'no_local'};
    my $retain_asp = delete $args{'retain_as_published'};
    my $retain_hdl = delete $args{'retain_handling'};

    $topics = [] unless defined $topics;
    push (@$topics, $topic) if defined $topic; 

    croak "Subscription topics were not specified" unless @$topics;
    croak "on_publish callback is required" unless $subscr_cb;

    foreach my $topic (@$topics) {
        croak "Undefined subscription topic" unless defined $topic;
        croak "Empty subscription topic" unless length $topic;
    }

    my $packet_id = $self->{packet_seq}++;
    $self->{packet_seq} = 1 if $packet_id == 0xFFFF;

    # Set callback for incomings PUBLISH
    my $subscr_id = $self->{subscr_seq}++;
    $self->{subscr_cb}->{$subscr_id} = $subscr_cb;

    # Parameters for expected SUBACK
    $self->{packet_cb}->{$packet_id} = {
        topics    => [ @$topics ], # copy
        subscr_id => $subscr_id,
        suback_cb => $suback_cb,
    };

    # 3.8.2.1.2  Subscription Identifier  (variable len int)
    my $raw_prop = pack("C", MQTT_SUBSCRIPTION_IDENTIFIER) . 
                   _encode_var_int($subscr_id);

    # 3.8.2.1.3  User Property  (utf8 string pair)
    foreach my $key (keys %args) {
        my $val = $args{$key};
        next unless defined $val;
        utf8::encode( $key );
        utf8::encode( $val );
        $raw_prop .= pack("C n/a* n/a*", MQTT_USER_PROPERTY, $key, $val);
    }

    my $raw_mqtt = pack("n", $packet_id)             .  # 3.8.2   Packet identifier
                   _encode_var_int(length $raw_prop) .  # 3.8.2.1 Properties Length
                   $raw_prop;                           # 3.8.2.1 Properties

    # 3.8.3.1  Subscription Options
    my $options = 0;
    $options |= ($max_qos & 0x03)         if $max_qos;     # Maximum QoS
    $options |=  0x04                     if $no_local;    # No Local 
    $options |=  0x08                     if $retain_asp;  # Retain As Published
    $options |= ($retain_hdl & 0x03) << 4 if $retain_hdl;  # Retain Handling

    # 3.8.3  Payload
    foreach my $topic (@$topics) {
        utf8::encode( $topic );
        $raw_mqtt .= pack("n/a* C", $topic, $options);
    }

    $self->{handle}->push_write( 
        pack("C", MQTT_SUBSCRIBE << 4 | 0x02) .  # 3.8.1 Packet type 
        _encode_var_int(length $raw_mqtt)     .  # 3.8.1 Packet length
        $raw_mqtt
    );

    1;
}

sub _receive_suback {
    my ($self, $packet) = @_;

    # 3.9.2  Packet id  (short int)
    my $offs = 0;
    my $packet_id = _decode_int_16($packet, \$offs);

    # 3.9.2.1.1  Property Length  (variable length int)
    my $prop_len = _decode_var_int($packet, \$offs);
    my $prop_end = $offs + $prop_len;
    my %prop;

    while ($offs < $prop_end) {

        my $prop_id = _decode_byte($packet, \$offs);

        if ($prop_id == MQTT_REASON_STRING) {
            # 3.9.2.1.2  Reason String  (utf8 string)
            $prop{'reason_string'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_USER_PROPERTY) {
            # 3.9.2.1.3  User Property  (utf8 string pair)
            my $key = _decode_utf8_str($packet, \$offs);
            my $val = _decode_utf8_str($packet, \$offs);
            $prop{$key} = $val;
        }
        else {
            # Protocol error
            $self->_fatal("Received SUBACK with unexpected property $prop_id");
        }
    }

    # 3.9.3  Payload
    my @reason_codes = unpack("C*", substr($$packet, $offs));

    my $packet_cb = delete $self->{packet_cb}->{$packet_id};
    $self->_fatal("Received unexpected SUBACK") unless $packet_cb;

    my $topics    = $packet_cb->{topics};
    my $suback_cb = $packet_cb->{suback_cb};
    my $subscr_id = $packet_cb->{subscr_id};

    my $success = 1;
    my @properties;

    foreach my $code (@reason_codes) {

        my $topic = shift @$topics;
        my $reason = $Subscribe_reason_code{$code};
        my $granted_qos;

        if ($code <= 2) {
            # Success
            $granted_qos = $code;
            $self->{subscriptions}->{$topic} = $subscr_id;
        }
        else {
            # Failure
            $success = 0;
            $granted_qos = undef;
            unless ($suback_cb) {
                $self->_fatal("Subscription to topic '$topic' failed: $reason");
            }
        }

        $DEBUG && warn "Subscribed to: $topic\n";

        push @properties, {
            topic       => $topic,
            reason_code => $code,
            granted_qos => $granted_qos,
            reason      => $reason,
            %prop
        };
    }

    $suback_cb->($success, @properties) if $suback_cb;
}


sub unsubscribe {
    my ($self, %args) = @_;

    my $topic       = delete $args{'topic'};
    my $topics      = delete $args{'topics'};
    my $unsuback_cb = delete $args{'on_unsuback'};

    $topics = [] unless defined $topics;
    push (@$topics, $topic) if defined $topic; 

    croak "Unsubscription topics were not specified" unless @$topics;
    croak "on_unsuback callback is required" unless $unsuback_cb;

    foreach my $topic (@$topics) {
        croak "Undefined unsubscription topic" unless defined $topic;
        croak "Empty unsubscription topic" unless length $topic;
    }

    my $packet_id = $self->{packet_seq}++;
    $self->{packet_seq} = 1 if $packet_id == 0xFFFF;

    # Set callback for UNSUBACK
    $self->{packet_cb}->{$packet_id} = {
        topics      => [ @$topics ], # copy
        unsuback_cb => $unsuback_cb,
    };

    # 3.10.2.1.2  User Property  (utf8 string pair)
    my $raw_prop = '';
    foreach my $key (keys %args) {
        my $val = $args{$key};
        next unless defined $val;
        utf8::encode( $key );
        utf8::encode( $val );
        $raw_prop .= pack("C n/a* n/a*", MQTT_USER_PROPERTY, $key, $val);
    }

    my $raw_mqtt = pack("n", $packet_id)             .  # 3.10.2    Packet identifier
                   _encode_var_int(length $raw_prop) .  # 3.10.2.1  Property Length
                   $raw_prop;                           # 3.10.2.1  Properties

    # 3.10.3  Payload
    foreach my $topic (@$topics) {
        utf8::encode($topic);
        $raw_mqtt .= pack("n/a*", $topic);
    }

    $self->{handle}->push_write( 
        pack("C", MQTT_UNSUBSCRIBE << 4 | 0x02) .  # 3.10.1 Packet type 
        _encode_var_int(length $raw_mqtt)       .  # 3.10.1 Packet length
        $raw_mqtt
    );

    1;
}

sub _receive_unsuback {
    my ($self, $packet) = @_;
    weaken($self);

    # 3.11.2  Packet id  (short int)
    my $offs = 0;
    my $packet_id = _decode_int_16($packet, \$offs);

    # 3.11.2.1.1  Property Length  (variable length int)
    my $prop_len = _decode_var_int($packet, \$offs);
    my $prop_end = $offs + $prop_len;
    my %prop;

    while ($offs < $prop_end) {

        my $prop_id = _decode_byte($packet, \$offs);

        if ($prop_id == MQTT_REASON_STRING) {
            # 3.11.2.1.2  Reason String  (utf8 string)
            $prop{'reason_string'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_USER_PROPERTY) {
            # 3.11.2.1.3  User Property  (utf8 string pair)
            my $key = _decode_utf8_str($packet, \$offs);
            my $val = _decode_utf8_str($packet, \$offs);
            $prop{$key} = $val;
        }
        else {
            # Protocol error
            $self->_fatal("Received UNSUBACK with unexpected property $prop_id");
        }
    }

    # 3.11.3  Payload
    my @reason_codes = unpack("C*", substr($$packet, $offs));

    my $packet_cb = delete $self->{packet_cb}->{$packet_id};
    $self->_fatal("Received unexpected UNSUBACK") unless $packet_cb;

    my $topics = $packet_cb->{topics};
    my $unsuback_cb = $packet_cb->{unsuback_cb};

    my $success = 1;
    my @properties;

    foreach my $code (@reason_codes) {

        my $topic = shift @$topics;
        my $reason = $Reason_code{$code};

        if ($code == 0) {
            # Success
            my $subs = $self->{subscriptions};
            my $subscr_id = delete $subs->{$topic};
            if ($subscr_id) {
                # Free on_publish callback if not used by another subscription
                my @still_used = grep { $subs->{$_} == $subscr_id } keys %$subs;
                unless (@still_used) {
                    # But not right now, as broker may send some messages *after* unsubscription
                    $self->{_timers}->{"unsub-$subscr_id"} = AnyEvent->timer( after => 60, cb => sub {
                        delete $self->{_timers}->{"unsub-$subscr_id"};
                        delete $self->{subscr_cb}->{$subscr_id};
                    });
                }
            }
        }
        else {
            # Failure
            $success = 0;
            unless ($unsuback_cb) {
                $self->_fatal("Unsubscription to topic '$topic' failed: $reason");
            }
        }

        push @properties, {
            topic       => $topic,
            reason_code => $code,
            reason      => $reason,
            %prop
        };
    }

    $unsuback_cb->($success, @properties) if $unsuback_cb;
}

our $AE_WAITING;

sub publish {
    my ($self, %args) = @_;

    my $topic     = delete $args{'topic'};
    my $payload   = delete $args{'payload'};
    my $qos       = delete $args{'qos'};
    my $dup       = delete $args{'duplicate'};
    my $retain    = delete $args{'retain'};
    my $on_puback = delete $args{'on_puback'};
    my $buffer_id = delete $args{'buffer_id'};

    croak "Message topic was not specified" unless defined $topic;

    $DEBUG && warn "Sent message to: $topic\n";

    $payload = '' unless defined $payload;
    my $payload_ref = (ref $payload eq 'SCALAR') ? $payload : \$payload;

    # 3.3.2.3.4  Topic Alias
    my $topic_alias;
    if ($self->{use_alias}) {
        $topic_alias = $self->{client_alias}->{$topic};
        if ($topic_alias) {
            # Send topic alias only
            $topic = '';
        }
        elsif ($self->{server_prop}->{'topic_alias_maximum'}) {
            #TODO: Honor maximum
            $topic_alias = $self->{alias_seq}++;
            $self->{client_alias}->{$topic} = $topic_alias;
        }
    }

    # 3.3.1.2  QoS level
    my $flags = 0;
    $flags |= $qos << 1 if $qos;
    $flags |= 0x04      if $dup;
    $flags |= 0x01      if $retain;

    my $packet_id;
    if ($qos) {
        $packet_id = $self->{packet_seq}++;
        $self->{packet_seq} = 1 if $packet_id == 0xFFFF;
    }

    my $raw_prop = '';

    if (utf8::is_utf8( $$payload_ref )) {
        # 3.3.2.3.2  Payload Format Indicator  (byte)
        $raw_prop .= pack("C C", MQTT_PAYLOAD_FORMAT_INDICATOR, 0x01);
        utf8::encode( $$payload_ref );
    }

    if (exists $args{'message_expiry_interval'}) {
        # 3.3.2.3.3  Message Expiry Interval  (long int)
        $raw_prop .= pack("C N", MQTT_MESSAGE_EXPIRY_INTERVAL, delete $args{'message_expiry_interval'});
    }

    if ($topic_alias) {
        # 3.3.2.3.4  Topic Alias  (short int)
        $raw_prop .= pack("C n", MQTT_TOPIC_ALIAS, $topic_alias);
    }

    if (exists $args{'response_topic'}) {
        # 3.3.2.3.5  Response Topic  (utf8 string)
        utf8::encode( $args{'response_topic'} );
        $raw_prop .= pack("C n/a*", MQTT_RESPONSE_TOPIC, delete $args{'response_topic'});
    }

    if (exists $args{'correlation_data'}) {
        # 3.3.2.3.6  Correlation Data  (binary data)
        $raw_prop .= pack("C n/a*", MQTT_CORRELATION_DATA, delete $args{'correlation_data'});
    }

    # if (exists $args{'subscription_identifier'}) {
    #     # 3.3.2.3.8  Subscription Identifier  (variable int)
    #     my $id = delete $args{'subscription_identifier'};
    #     $raw_prop .= pack("C", MQTT_SUBSCRIPTION_IDENTIFIER) . _encode_var_int($id);
    # }

    if (exists $args{'content_type'}) {
        # 3.3.2.3.9  Content Type  (utf8 string)
        utf8::encode( $args{'content_type'} );
        $raw_prop .= pack("C n/a*", MQTT_CONTENT_TYPE, delete $args{'content_type'});
    }

    foreach my $key (keys %args) {
        # 3.3.2.3.7  User Property  (utf8 string pair)
        my $val = $args{$key};
        next unless defined $val;
        utf8::encode( $key );
        utf8::encode( $val );
        $raw_prop .= pack("C n/a* n/a*", MQTT_USER_PROPERTY, $key, $val);
    }

    # 3.3.2.1  Topic name  (utf8 string)
    utf8::encode( $topic );
    my $raw_mqtt = pack("n/a*", $topic);

    # 3.3.2.2  Packet identifier  (short int)
    $raw_mqtt .= pack("n", $packet_id) if $packet_id;

    # 3.3.2.3  Properties
    $raw_mqtt .= _encode_var_int(length $raw_prop);
    $raw_mqtt .= $raw_prop;

    # 3.3.3  Payload
    $raw_mqtt .= $$payload_ref;

    $raw_mqtt = pack("C", MQTT_PUBLISH << 4 | $flags) .  # 3.3.1  Packet type 
                _encode_var_int(length $raw_mqtt)     .  # 3.3.1  Packet length
                $raw_mqtt;

    if ($qos && $on_puback) {
         # Set PUBACK callback
        $self->{packet_cb}->{$packet_id} = $on_puback;
    }

    if ($buffer_id) {
        # Do not send right now, wait until flush_buffer
        my $buffer = $self->{buffers}->{$buffer_id} ||= {};
        $buffer->{raw_mqtt} .= $raw_mqtt;
        $buffer->{packets}->{$packet_id} = 1 if $packet_id;
        return 1;
    }

    $self->{handle}->push_write( $raw_mqtt );

    if (defined $self->{handle}->{wbuf} && length $self->{handle}->{wbuf} > 0) {
        # push_write could not send all data to the handle because the kernel
        # write buffer is full. The size of kernel write bufer (which can be 
        # queried with 'sysctl net.ipv4.tcp_wmem') is choosed by the kernel
        # based on available memory, and is 4MB in known production servers.
        # This will happen after sending more that 4MB of data very quickly.
        # As client may be syncronous, wait until entire message is sent.

        # Make AnyEvent allow one level of recursive condvar blocking
        $AE_WAITING && Carp::confess "Recursive condvar blocking wait attempted";
        local $AE_WAITING = 1;
        local $AnyEvent::CondVar::Base::WAITING = 0;

        my $flushed = AnyEvent->condvar;
        $self->{handle}->on_drain( $flushed );
        $flushed->recv;
        $self->{handle}->on_drain(); # clear
    }
}

sub _receive_publish {
    my ($self, $packet, $flags) = @_;

    # 3.3.2.1  Topic Name  (utf8 str)
    my $topic = unpack("n/a", $$packet);
    my $offs = 2 + length $topic;
    utf8::decode($topic);

    $DEBUG && warn "Got message from: $topic\n";

    my %prop = (
        'topic' => $topic,
        'qos'   => ($flags & 0x6) >> 1,
        'dup'   => ($flags & 0x8) >> 3,
    );

    # 3.3.2.2  Packet Identifier  (short int)
    if ($prop{'qos'} > 0) {
        $prop{'packet_id'} = unpack("n", substr($$packet, $offs, 2));
        $offs += 2;
    }

    # 3.3.2.3.1  Properties Length  (variable length int)
    my $prop_len = _decode_var_int($packet, \$offs);
    my $prop_end = $offs + $prop_len;

    my @subscr_ids;
    my $prop_id;

    while ($offs < $prop_end) {

        $prop_id = unpack("C", substr($$packet, $offs, 1));
        $offs += 1;

        if ($prop_id == MQTT_PAYLOAD_FORMAT_INDICATOR) {
            # 3.3.2.3.2  Payload Format Indicator  (byte)
            $prop{'payload_format'} = unpack("C", substr($$packet, $offs, 1));
            $offs += 1;
        }
        elsif ($prop_id == MQTT_MESSAGE_EXPIRY_INTERVAL) {
            # 3.3.2.3.3  Message Expiry Interval  (long int)
            $prop{'message_expiry_interval'} = unpack("N", substr($$packet, $offs, 4));
            $offs += 4;
        }
        elsif ($prop_id == MQTT_TOPIC_ALIAS) {
            # 3.3.2.3.4  Topic Alias  (short int)
            my $alias = unpack("n", substr($$packet, $offs, 2));
            $offs += 2;
            if (length $topic) {
                $self->{server_alias}->{$alias} = $topic;
            }
            else {
                $prop{'topic'} = $self->{server_alias}->{$alias};
            }
        }
        elsif ($prop_id == MQTT_RESPONSE_TOPIC) {
            # 3.3.2.3.5  Response Topic  (utf8 string)
            my $resp_topic = unpack("n/a", substr($$packet, $offs));
            $offs += 2 + length $resp_topic;
            utf8::decode( $resp_topic );
            $prop{'response_topic'} = $resp_topic;
        }
        elsif ($prop_id == MQTT_CORRELATION_DATA) {
            # 3.3.2.3.6  Correlation Data  (binary data)
            $prop{'correlation_data'} = unpack("n/a", substr($$packet, $offs));
            $offs += 2 + length $prop{'correlation_data'};
        }
        elsif ($prop_id == MQTT_USER_PROPERTY) {
            # 3.3.2.3.7  User Property  (utf8 string pair)
            my ($key, $val) = unpack("n/a n/a", substr($$packet, $offs));
            $offs += 4 + length($key) + length($val);
            utf8::decode( $key );
            utf8::decode( $val );
            $prop{$key} = $val;
        }
        elsif ($prop_id == MQTT_SUBSCRIPTION_IDENTIFIER) {
            # 3.3.2.3.8  Subscription Identifier  (variable int)
            push @subscr_ids, _decode_var_int($packet, \$offs);
        }
        elsif ($prop_id == MQTT_CONTENT_TYPE) {
            # 3.3.2.3.9  Content Type  (utf8 string)
            my $content_type = unpack("n/a", substr($$packet, $offs));
            $offs += 2 + length $content_type;
            utf8::decode( $content_type );
            $prop{'content_type'} = $content_type;
        }
        else {
            # Protocol error
            $self->_fatal("Received PUBLISH with unknown property $prop_id");
        }
    }

    # Trim variable header from packet, the remaining is the payload
    substr($$packet, 0, $prop_end, '');

    if ($prop{'payload_format'}) {
        # Payload is UTF-8 Encoded Character Data
        utf8::decode( $$packet );
    }

    foreach (@subscr_ids) {
        # Execute subscriptions callbacks

        $self->{subscr_cb}->{$_}->($packet, \%prop);
    }
}


sub puback {
    my ($self, %args) = @_;

    croak "Missing packet_id" unless $args{'packet_id'};

    my $raw_mqtt = pack( 
        "C C n C", 
        MQTT_PUBACK << 4,           # 3.4.1    Packet type 
        3,                          # 3.4.1    Remaining length
        $args{'packet_id'},         # 3.4.2    Packet identifier
        $args{'reason_code'} || 0,  # 3.4.2.1  Reason code
    );

    if ($args{'buffer_id'}) {
        # Do not send right now, wait until flush_buffer
        $self->{buffers}->{$args{'buffer_id'}}->{raw_mqtt} .= $raw_mqtt;
        return 1;
    }

    $self->{handle}->push_write( $raw_mqtt );

    1;
}

sub _receive_puback {
    my ($self, $packet) = @_;

    my ($packet_id, $reason_code) = unpack("n C", $$packet);
    $reason_code = 0 unless defined $reason_code;

    #TODO: 3.5.2.2  Properties

    my $puback_cb = delete $self->{packet_cb}->{$packet_id};
    return unless defined $puback_cb;

    $puback_cb->($reason_code);
}

sub pubrec {
    my ($self, %args) = @_;

    croak "Missing packet_id" unless $args{'packet_id'};

    my $raw_mqtt = pack( 
        "C C n C", 
        MQTT_PUBREC << 4,           # 3.5.1    Packet type 
        3,                          # 3.5.1    Remaining length
        $args{'packet_id'},         # 3.5.2    Packet identifier
        $args{'reason_code'} || 0,  # 3.5.2.1  Reason code
    );

    #TODO: set PUBREL callback

    $self->{handle}->push_write( $raw_mqtt );

    1;
}

sub _receive_pubrec {
    my ($self, $packet) = @_;

    my ($packet_id, $reason_code) = unpack("n C", $$packet);
    $reason_code = 0 unless defined $reason_code;

    #TODO: 3.5.2.2  Properties

    my $pubrec_cb = delete $self->{packet_cb}->{$packet_id};
    return unless defined $pubrec_cb;

    $pubrec_cb->($packet_id, $reason_code);
}

sub pubrel {
    my ($self, %args) = @_;

    croak "Missing packet_id" unless $args{'packet_id'};

    my $raw_mqtt = pack( 
        "C C n C", 
        MQTT_PUBREL << 4,           # 3.6.1    Packet type 
        3,                          # 3.6.1    Remaining length
        $args{'packet_id'},         # 3.6.2    Packet identifier
        $args{'reason_code'} || 0,  # 3.6.2.1  Reason code
    );

    #TODO: set PUBREC callback

    $self->{handle}->push_write( $raw_mqtt );

    1;
}

sub _receive_pubrel {
    my ($self, $packet) = @_;

    my ($packet_id, $reason_code) = unpack("n C", $$packet);
    $reason_code = 0 unless defined $reason_code;

    #TODO: 3.6.2.2  Properties

    my $pubrel_cb = delete $self->{packet_cb}->{$packet_id};
    return unless defined $pubrel_cb;

    $pubrel_cb->($packet_id, $reason_code);
}

sub pubcomp {
    my ($self, %args) = @_;

    croak "Missing packet_id" unless $args{'packet_id'};

    my $raw_mqtt = pack( 
        "C C n C", 
        MQTT_PUBCOMP << 4,          # 3.7.1    Packet type 
        3,                          # 3.7.1    Remaining length
        $args{'packet_id'},         # 3.7.2    Packet identifier
        $args{'reason_code'} || 0,  # 3.7.2.1  Reason code
    );

    $self->{handle}->push_write( $raw_mqtt );

    1;
}

sub _receive_pubcomp {
    my ($self, $packet) = @_;

    my ($packet_id, $reason_code) = unpack("n C", $$packet);
    $reason_code = 0 unless defined $reason_code;

    #TODO: 3.7.2.2  Properties

    my $pubcomp_cb = delete $self->{packet_cb}->{$packet_id};
    return unless defined $pubcomp_cb;

    $pubcomp_cb->($reason_code);
}


sub auth {
    my ($self, %args) = @_;

    my $reason_code = delete $args{'reason_code'};
    my $auth_cb     = delete $args{'on_auth'};

    # Set callback to be executed when the server answers with an AUTH packet
    $self->{packet_cb}->{'auth'} = $auth_cb if $auth_cb;

    my $raw_prop = '';

    if (exists $args{'authentication_method'}) {
        # 3.15.2.2.2  Authentication Method  (utf8 string)
        utf8::encode( $args{'authentication_method'} );
        $raw_prop .= pack("C n/a*", MQTT_AUTHENTICATION_METHOD, delete $args{'authentication_method'});
    }

    if (exists $args{'authentication_data'}) {
        # 3.15.2.2.3  Authentication Data  (binary data)
        $raw_prop .= pack("C n/a*", MQTT_AUTHENTICATION_DATA, delete $args{'authentication_data'});
    }

    if (exists $args{'reason_string'}) {
        # 3.15.2.2.4  Reason String  (utf8 string)
        utf8::encode( $args{'reason_string'} );
        $raw_prop .= pack("C n/a*", MQTT_REASON_STRING, delete $args{'reason_string'});
    }

    foreach my $key (keys %args) {
        # 3.15.2.2.5  User Property  (utf8 string pair)
        my $val = $args{$key};
        next unless defined $val;
        utf8::encode( $key );
        utf8::encode( $val );
        $raw_prop .= pack("C n/a* n/a*", MQTT_USER_PROPERTY, $key, $val);
    }

    # 3.15.2.1  Authenticate Reason Code  (byte)
    my $raw_mqtt = pack("C", $reason_code);

    # 3.15.2.2  Properties
    $raw_mqtt .= _encode_var_int(length $raw_prop);
    $raw_mqtt .= $raw_prop;

    $self->{handle}->push_write( 
        pack("C", MQTT_AUTH << 4)         .  # 3.15.1  Packet type 
        _encode_var_int(length $raw_mqtt) .  # 3.15.1  Packet length
        $raw_mqtt
    );

    1;
}

sub _receive_auth {
    my ($self, $packet) = @_;

    # Handle abbreviated packet
    $$packet = "\x00\x00" if (length $$packet == 0);

    # 3.15.2.1  Authenticate Reason Code  (byte)
    my $offs = 0;
    my $reason_code = _decode_byte($packet, \$offs);
    my $reason = $Reason_code{$reason_code};

    # 3.15.2.2.1  Property Length  (variable length int)
    my $prop_len = _decode_var_int($packet, \$offs);
    my $prop_end = $offs + $prop_len;

    my %prop = (
        reason_code => $reason_code,
        reason      => $reason,
    );

    while ($offs < $prop_end) {

        my $prop_id = _decode_byte($packet, \$offs);

        if ($prop_id == MQTT_AUTHENTICATION_METHOD) {
            # 3.15.2.2.2  Authentication Method  (utf8 string)
            $prop{'authentication_method'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_AUTHENTICATION_DATA) {
            # 3.15.2.2.3  Authentication Data  (binary data)
            $prop{'authentication_data'} = _decode_binary_data($packet, \$offs);
        }
        elsif ($prop_id == MQTT_REASON_STRING) {
            # 3.15.2.2.4  Reason String  (utf8 string)
            $prop{'reason_string'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_USER_PROPERTY) {
            # 3.15.2.2.5  User Property  (utf8 string pair)
            my $key = _decode_utf8_str($packet, \$offs);
            my $val = _decode_utf8_str($packet, \$offs);
            $prop{$key} = $val;
        }
        else {
            # Protocol error
            $self->_fatal("Received AUTH with unexpected property $prop_id");
        }
    }

    my $auth_cb = delete $self->{packet_cb}->{'auth'};

    $auth_cb->(\%prop) if $auth_cb;
}


sub flush_buffer {
    my ($self, %args) = @_;

    my $buffer = delete $self->{buffers}->{$args{'buffer_id'}};

    # Nothing to do if nothing was buffered
    return unless $buffer;

    $self->{handle}->push_write( $buffer->{raw_mqtt} );

    if (defined $self->{handle}->{wbuf} && length $self->{handle}->{wbuf} > 0) {

        # Kernel write buffer is full, see publish() above

        # Make AnyEvent allow one level of recursive condvar blocking
        $AE_WAITING && Carp::confess "Recursive condvar blocking wait attempted";
        local $AE_WAITING = 1;
        local $AnyEvent::CondVar::Base::WAITING = 0;

        my $flushed = AnyEvent->condvar;
        $self->{handle}->on_drain( $flushed );
        $flushed->recv;
        $self->{handle}->on_drain(); # clear
    }

    1;
}

sub discard_buffer {
    my ($self, %args) = @_;

    my $buffer = delete $self->{buffers}->{$args{'buffer_id'}};

    # Nothing to do if nothing was buffered
    return unless $buffer;

    # Remove all pending puback callbacks, as those will never be executed
    foreach my $packet_id (keys %{$buffer->{packet_ids}}) {
        delete $self->{packet_cb}->{$packet_id};
    }

    1;
}


sub DESTROY {
    my $self = shift;
    # Disconnect gracefully from server if already connected
    return unless defined $self->{handle};
    $self->disconnect;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::MQTT - Asynchronous MQTT 5.0 client.
 
=head1 VERSION
 
Version 0.06

=head1 SYNOPSIS

  my $mqtt = Beekeeper::MQTT->new(
      host     => 'localhost',
      username => 'guest',
      password => 'guest',
  );
  
  $mqtt->connect( 
      blocking => 1,
      on_connack => sub {
          my ($success, $properties) = @_;
          die $properties->{reason_string} unless $success;
      },
  );
  
  $mqtt->subscribe(
      topic => 'foo/bar',
      on_publish => sub {
          my ($payload, $properties) = @_;
          print "Got a message: $$payload";
      },
  );
  
  $mqtt->publish(
      topic   => 'foo/bar',
      payload => 'Hello',
  );
  
  $mqtt->unsubscribe(
      topic => 'foo/bar',
  );
  
  $mqtt->disconnect;

Most methods allow to send arbitrary properties as key-value pairs of utf8 strings.

Except for trivial cases, error checking is delegated to the server.

The MQTT specification can be found at L<https://mqtt.org/mqtt-specification>

=head1 TODO

- Keep Alive

=head1 CONSTRUCTOR

=head3 new ( %options )

=over 4

=item host

Hostname or IP address of the MQTT server. It also accepts an array of adresses 
which conforms a cluster, in which case the connection will be stablished against
a randomly choosen node of the cluster.

=item port

Port of the MQTT server. If not specified use the MQTT default of 1883.

=item tls

Enable the use of TLS for MQTT connections.

=item username

Username used to authenticate against the server.

=item password

Password used to authenticate against the server.

=item timeout

Connection timeout in fractional seconds before giving up. Default is 30 seconds.
If set to zero the connection to server it retried forever.

=item on_error => $cb->( $errmsg )

Optional callback which is executed when an error condition occurs. If not specified,
the default is to die with C<$errmsg>. Usually the server has already closed the 
connection when this is called.

=back

=head1 METHODS

=head3 connect ( %options )

Connect to the MQTT server and do handshake. On failure retries until timeout.

=over 4

=item blocking => $bool

When set to true this method acts as a blocking call: it does not return until
a connection has been established and handshake has been completed.

=item on_connack => $cb->( $success, \%properties )

Callback which is executed after the server accepted the connection.

=back

=head3 disconnect ( %args )

Does a graceful disconnection from the server.

=over 4

=item $reason_code

Disconnect Reason Code as stated in the chapter 3.14.2.1 of the specification.
Default is zero, meaning normal disconnection.

=back

=head3 subscribe ( %args )

Create a subscription to a topic (or a list of topics). When a message is received,
it will be passed to given on_publish callback:
  
  $mqtt->subscribe(
      topic       => 'topic/foo',
      maximum_qos => 1,
      on_publish  => sub {
          my ($payload, \%properties) = @_;
          print "Got message from topic/foo : $$payload";
      },
  );

=over 4

=item topics => \@topics

List of topics to which the client wants to subscribe.

=item on_publish => $cb->( \$payload, \%properties )

Required callback which is executed when a message matching any of the subscription
topics is received.

=item on_suback => $cb->( $success, \%properties, ... )

Optional callback which is executed after subscription is acknowledged by the
server with a SUBACK packet.

=item User properties

Any other argument other than C<maximum_qos>, C<no_local>, C<retain_as_published> or
C<retain_handling> is sent as an "User Property" (a key-value pair of utf8 strings).

=back

=head3 unsubscribe ( %params )

Cancel an existing subscription, the client will no longer receive messages 
from that topic. Example:

  $mqtt->unsubscribe( 
      topics => ['topic/foo','topic/bar']
  );

=over 4

=item topics => \@topics

The destination of an existing subscription.

=item on_unsuback => $cb->()

Optional user defined callback which is called after unsubscription is completed.

=back

=head3 publish ( %args )

Sends a message to a topic. Example:

  $mqtt->publish(
      topic     => 'foo/bar',
      payload   => 'Hello!',
      qos       => 1,
      on_puback => sub {
         my ($reason_code) = @_;
         print "Message was sent";
      }
  );

=over 4

=item topic => $str

Utf8 string containing the topic name.

=item payload => \$data

Scalar or scalar reference containing either an utf8 string or a binary blob which 
conforms the payload of the message. It is allowed to publish messages without payload.

=item qos => $bool

Quality of service level (QoS). Only levels 0 and 1 are supported. Default is 0.

=item duplicate => $bool

Must be set to a true value to indicate a message retransmission.

=item retain => $bool

When true sets the message retain flag.

=item message_expiry_interval => $int

Expiration period in seconds. The server will discard retained messages after this
period has ellapsed.

=item response_topic => $str

Utf8 string containing the response topic name.

=item on_puback => $cb->($reason_code)

Optional callback which is executed after the server answers with a PUBACK packet,
acknowledging that it has received it. Allowed only for messages published with QoS 1.

=item User properties

Any aditional argument will be sent as an "User Property", this is as a key-value pair
of utf8 strings.

=back

=head3 puback ( %args )

Used to acknowledge the receipt of a message received from a subscription with QoS 1.
The server should resend the message until it is acknowledged.

=over 4

=item packet_id => $int

=item reason_code => $int

If not specified it will default to zero, signaling success. 

=back

=head3 flush_buffer

Send several packets into a single socket write. This is more efficient
than individual send() calls because Nagle's algorithm is disabled.

=head3 discard_buffer

Discard buffered packets.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
