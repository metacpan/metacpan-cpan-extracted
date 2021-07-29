package Beekeeper::Service::ToyBroker::Worker;

use strict;
use warnings;

our $VERSION = '0.09';

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';

use Beekeeper::MQTT qw(:const :decode);
use Beekeeper::Config;

use AnyEvent::Handle;
use AnyEvent::Socket;
use Scalar::Util 'weaken';
use Carp;

use constant DEBUG => 0;


sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    $self->start_broker;

    # Postponed initialization
    $self->SUPER::__init_client;
    $self->{_LOGGER}->{_BUS} = $self->{_BUS};
    $self->SUPER::__init_auth_tokens;
    $self->SUPER::__init_worker;

    return $self;
}

sub __init_client      { }
sub __init_auth_tokens { }
sub __init_worker      { }
sub   on_startup       { }

sub on_shutdown {
    my $self = shift;

    log_info "Shutting down";

    # Wait for clients to gracefully disconnect
    for (1..60) {
        my $conn_count = scalar keys %{$self->{connections}};
        last if $conn_count <= 1; # our self connection
        my $wait = AnyEvent->condvar;
        my $tmr = AnyEvent->timer( after => 0.5, cb => $wait );
        $wait->recv;
    }

    # Get rid of our self connection
    $self->{_BUS}->disconnect;

    log_info "Stopped";
}

sub authorize_request {
    my ($self, $req) = @_;

    return BKPR_REQUEST_AUTHORIZED;
}

sub start_broker {
    my ($self) = @_;

    $self->{connections} = {};
    $self->{clients}     = {};
    $self->{topics}      = {};
    $self->{users}       = {};

    my $config = Beekeeper::Config->read_config_file( 'toybroker.config.json' );

    # Start a default listener if no config found
    $config = [ {} ] unless defined $config;

    foreach my $listener (@$config) {

        if ($listener->{users}) {
            %{$self->{users}} = ( %{$self->{users}}, %{$listener->{users}} );
        }

        $self->start_listener( $listener );
    }
}

sub start_listener {
    my ($self, $listener) = @_;
    weaken($self);

    my $max_packet_size = $listener->{'max_packet_size'};

    my $addr = $listener->{'listen_addr'} || '127.0.0.1';  # Must be an IPv4 or IPv6 address
    my $port = $listener->{'listen_port'} ||  1883;

    ($addr) = ($addr =~ m/^([\w\.:]+)$/);  # untaint
    ($port) = ($port =~ m/^(\d+)$/);

    log_info "Listening on $addr:$port";

    $self->{"listener-$addr-$port"} = tcp_server ($addr, $port, sub {
        my ($FH, $host, $port) = @_;

        my $packet_type;
        my $packet_flags;

        my $rbuff_len;
        my $packet_len;

        my $mult;
        my $offs;
        my $byte;

        my $fh; $fh = AnyEvent::Handle->new(
            fh => $FH,
            keepalive => 1,
            no_delay => 1,
            on_read => sub {

                PARSE_PACKET: {

                    $rbuff_len = length $fh->{rbuf};

                    return unless $rbuff_len >= 2;

                    unless ($packet_type) {

                        $packet_len = 0;
                        $mult = 1;
                        $offs = 1;

                        PARSE_LEN: {
                            $byte = unpack "C", substr( $fh->{rbuf}, $offs++, 1 );
                            $packet_len += ($byte & 0x7f) * $mult;
                            last unless ($byte & 0x80);
                            return if ($offs >= $rbuff_len); # Not enough data
                            $mult *= 128;
                            redo if ($offs < 5);
                        }

                        if ($max_packet_size && $packet_len > $max_packet_size) {
                            $self->disconnect($fh, reason_code => 0x95);
                            return;
                        }

                        $byte = unpack('C', substr( $fh->{rbuf}, 0, 1 ));
                        $packet_type  = $byte >> 4;
                        $packet_flags = $byte & 0x0F;
                    }

                    if ($rbuff_len < ($offs + $packet_len)) {
                        # Not enough data
                        return;
                    }

                    # Consume packet from buffer
                    my $packet = substr($fh->{rbuf}, 0, ($offs + $packet_len), '');

                    # Trim fixed header from packet
                    substr($packet, 0, $offs, '');

                    if ($packet_type == MQTT_PUBLISH) {

                        $self->_receive_publish($fh, \$packet, $packet_flags);
                    }
                    elsif ($packet_type == MQTT_PUBACK) {

                        $self->_receive_puback($fh, \$packet);
                    }
                    elsif ($packet_type == MQTT_PINGREQ) {

                        $self->pingresp($fh);
                    }
                    elsif ($packet_type == MQTT_PINGRESP) {

                        $self->_receive_pingresp($fh);
                    }
                    elsif ($packet_type == MQTT_SUBSCRIBE) {

                        $self->_receive_subscribe($fh, \$packet);
                    }
                    elsif ($packet_type == MQTT_UNSUBSCRIBE) {

                        $self->_receive_unsubscribe($fh, \$packet);
                    }
                    elsif ($packet_type == MQTT_CONNECT) {

                        $self->_receive_connect($fh, \$packet);
                    }
                    elsif ($packet_type == MQTT_DISCONNECT) {

                        $self->_receive_disconnect($fh, \$packet);
                    }
                    elsif ($packet_type == MQTT_PUBREC) {

                        $self->_receive_pubrec($fh, \$packet);
                    }
                    elsif ($packet_type == MQTT_PUBREL) {
                        
                        $self->_receive_pubrel($fh, \$packet);
                    }
                    elsif ($packet_type == MQTT_PUBCOMP) {

                        $self->_receive_pubcomp($fh, \$packet);
                    }
                    elsif ($packet_type == MQTT_AUTH) {

                        $self->_receive_auth($fh, \$packet);
                    }
                    else {
                        # Protocol error
                        log_warn "Received packet with unknown type $packet_type";
                        $self->disconnect($fh, reason_code => 0x81);
                        return;
                    }

                    # Prepare for next frame
                    undef $packet_type;

                    # Handle could have been destroyed at this point
                    redo PARSE_PACKET if defined $fh->{rbuf};
                }
            },
            on_eof => sub {
                # Clean disconnection, client will not write anymore
                $self->remove_client($fh);
                delete $self->{connections}->{"$fh"};
            },
            on_error => sub {
                log_error "$_[2]\n";
                $self->remove_client($fh);
                delete $self->{connections}->{"$fh"};
            }
        );

        $self->{connections}->{"$fh"} = $fh;

        #TODO: Close connection on login timeout
        # my $login_tmr = AnyEvent->timer( after => 5, cb => sub {
        #     $self->_shutdown($fh) unless $self->get_client($fh);
        # });
    });
}

sub _receive_connect {
    my ($self, $fh, $packet) = @_;

    my %prop;
    my $offs = 0;

    # 3.1.2.1  Protocol Name  (utf8 string)
    $prop{'protocol_name'} = _decode_utf8_str($packet, \$offs);

    # 3.1.2.2  Protocol Version  (byte)
    $prop{'protocol_version'} = _decode_byte($packet, \$offs);

    # 3.1.2.3  Connect Flags  (byte)
    my $flags = _decode_byte($packet, \$offs);
    $prop{'clean_start'} = 1 if $flags & 0x02;   # 3.1.2.4  Clean Start
    $prop{'username'}    = 1 if $flags & 0x80;   # 3.1.2.8  User Name Flag
    $prop{'password'}    = 1 if $flags & 0x40;   # 3.1.2.9  Password Flag
    $prop{'will_flag'}   = 1 if $flags & 0x04;   # 3.1.2.5  Will Flag
    $prop{'will_qos'}    = ($flags & 0x18) >> 3; # 3.1.2.6  Will QoS
    $prop{'will_retain'} = 1 if $flags & 0x20;   # 3.1.2.7  Will Retain

    # 3.1.2.10  Keep Alive  (short int)
    $prop{'keep_alive'} = _decode_int_16($packet, \$offs);

    # 3.1.2.11.1  Properties Length  (variable length int)
    my $prop_len = _decode_var_int($packet, \$offs);
    my $prop_end = $offs + $prop_len;

    while ($offs < $prop_end) {

        my $prop_id = _decode_byte($packet, \$offs);

        if ($prop_id == MQTT_SESSION_EXPIRY_INTERVAL) {
            # 3.1.2.11.2  Session Expiry Interval  (long int)
            $prop{'session_expiry_interval'} = _decode_int_32($packet, \$offs);
        }
        elsif ($prop_id == MQTT_RECEIVE_MAXIMUM) {
            # 3.1.2.11.3  Receive Maximum  (short int)
            $prop{'receive_maximum'} = _decode_int_16($packet, \$offs);
        }
        elsif ($prop_id == MQTT_MAXIMUM_PACKET_SIZE) {
            # 3.1.2.11.4  Maximum Packet Size  (long int)
            $prop{'maximum_packet_size'} = _decode_int_32($packet, \$offs);
        }
        elsif ($prop_id == MQTT_TOPIC_ALIAS_MAXIMUM) {
            # 3.1.2.11.5  Topic Alias Maximum  (short int)
            $prop{'topic_alias_maximum'} = _decode_int_16($packet, \$offs);
        }
        elsif ($prop_id == MQTT_REQUEST_RESPONSE_INFORMATION) {
            # 3.1.2.11.6  Request Response Information  (byte)  
            $prop{'request_response_information'} = _decode_byte($packet, \$offs);
        }
        elsif ($prop_id == MQTT_REQUEST_PROBLEM_INFORMATION) {
            # 3.1.2.11.7  Request Problem Information  (byte)
            $prop{'request_problem_information'} = _decode_byte($packet, \$offs);
        }
        elsif ($prop_id == MQTT_USER_PROPERTY) {
            # 3.1.2.11.8  User Property  (utf8 string pair)
            my $key = _decode_utf8_str($packet, \$offs);
            my $val = _decode_utf8_str($packet, \$offs);
            $prop{$key} = $val;
        }
        elsif ($prop_id == MQTT_AUTHENTICATION_METHOD) {
            # 3.1.2.11.9  Authentication Method  (utf8 string)
            $prop{'authentication_method'} = _decode_utf8_str($packet, \$offs);
        }
        elsif ($prop_id == MQTT_AUTHENTICATION_DATA) {
            # 3.1.2.11.10  Authentication Data  (binary data)
            $prop{'authentication_data'} = _decode_binary_data($packet, \$offs);
        }
        else {
            # Protocol error
            log_warn "Received CONNECT with unknown property $prop_id";
            $self->_shutdown($fh);
            return; 
        }
    }

    # 3.1.3.1  Client Identifier  (utf8 string)
    $prop{'client_identifier'} = _decode_utf8_str($packet, \$offs);

    if ($prop{'will'}) {

        # 3.1.3.2.1  Will Properties Length
        my $prop_len = _decode_var_int($packet, \$offs);

        #TODO: 3.1.3.2  Will Properties
        $offs += $prop_len;

        # 3.1.3.3  Will Topic  (utf8 string)
        $prop{'will_topic'} = _decode_utf8_str($packet, \$offs);

        # 3.1.3.4  Will Payload  (binary data)
        $prop{'will_payload'} = _decode_binary_data($packet, \$offs);
    }

    if ($prop{'username'}) {
        # 3.1.3.5  Username  (utf8 string)
        $prop{'username'} = _decode_utf8_str($packet, \$offs);
    }

    if ($prop{'password'}) {
        # 3.1.3.6  Password  (binary data)
        $prop{'password'} = _decode_utf8_str($packet, \$offs);
    }

    unless ($prop{'protocol_version'} eq '5') {
        log_warn "Received CONNECT with unsupported protocol version";
        $self->_shutdown($fh);
        return;
    }

    $self->add_client($fh, \%prop);
}

sub connack {
    my ($self, $fh, %args) = @_;

    my $reason_code     = delete $args{'reason_code'};
    my $session_present = delete $args{'session_present'};

    # 3.2.2.3  Properties

    my $raw_prop;

    if (exists $args{'session_expiry_interval'}) {
        # 3.2.2.3.2  Session Expiry Interval  (long int)
        $raw_prop .= pack("C N", MQTT_SESSION_EXPIRY_INTERVAL, delete $args{'session_expiry_interval'});
    }

    if (exists $args{'receive_maximum'}) {
        # 3.2.2.3.3  Receive Maximum  (short int)
        $raw_prop .= pack("C n", MQTT_RECEIVE_MAXIMUM, delete $args{'receive_maximum'});
    }

    if (exists $args{'maximum_qos'}) {
        # 3.2.2.3.4  Maximum QoS  (byte)
        $raw_prop .= pack("C C", MQTT_MAXIMUM_QOS, delete $args{'maximum_qos'});
    }

    if (exists $args{'retain_available'}) {
        # 3.2.2.3.5  Retain Available  (byte)
        $raw_prop .= pack("C C", MQTT_RETAIN_AVAILABLE, delete $args{'retain_available'});
    }

    if (exists $args{'maximum_packet_size'}) {
        # 3.2.2.3.6  Maximum Packet Size  (long int)
        $raw_prop .= pack("C N", MQTT_MAXIMUM_PACKET_SIZE, delete $args{'maximum_packet_size'});
    }

    if (exists $args{'assigned_client_identifier'}) {
        # 3.2.2.3.7  Assigned Client Identifier  (utf8 string)
        utf8::encode( $args{'assigned_client_identifier'} );
        $raw_prop .= pack("C n/a*", MQTT_ASSIGNED_CLIENT_IDENTIFIER, delete $args{'assigned_client_identifier'});
    }

    if (exists $args{'topic_alias_maximum'}) {
        # 3.2.2.3.8  Topic Alias Maximum  (short int)
        $raw_prop .= pack("C n", MQTT_TOPIC_ALIAS_MAXIMUM, delete $args{'topic_alias_maximum'});
    }

    if (exists $args{'reason_string'}) {
        # 3.2.2.3.9  Reason String  (utf8 string)
        utf8::encode( $args{'reason_string'} );
        $raw_prop .= pack("C n/a*", MQTT_REASON_STRING, delete $args{'reason_string'});
    }

    if (exists $args{'wildcard_subscription_available'}) {
        # 3.2.2.3.11  Wildcard Subscription Available  (byte)
        $raw_prop .= pack("C C", MQTT_WILDCARD_SUBSCRIPTION_AVAILABLE, delete $args{'wildcard_subscription_available'});
    }

    if (exists $args{'subscription_identifier_available'}) {
        # 3.2.2.3.12  Subscription Identifiers Available  (byte)
        $raw_prop .= pack("C C", MQTT_SUBSCRIPTION_IDENTIFIER_AVAILABLE, delete $args{'subscription_identifier_available'});
    }

    if (exists $args{'shared_subscription_available'}) {
        # 3.2.2.3.13  Shared Subscription Available  (byte)
        $raw_prop .= pack("C C", MQTT_SHARED_SUBSCRIPTION_AVAILABLE, delete $args{'shared_subscription_available'});
    }

    if (exists $args{'server_keep_alive'}) {
        # 3.2.2.3.14  Server Keep Alive  (short int)
        $raw_prop .= pack("C n", MQTT_SERVER_KEEP_ALIVE, delete $args{'server_keep_alive'});
    }

    if (exists $args{'response_information'}) {
        # 3.2.2.3.15  Response Information  (utf8 string)
        utf8::encode( $args{'response_information'} );
        $raw_prop .= pack("C n/a*", MQTT_RESPONSE_INFORMATION, delete $args{'response_information'});
    }

    if (exists $args{'server_reference'}) {
        # 3.2.2.3.16  Server Reference  (utf8 string)
        utf8::encode( $args{'server_reference'} );
        $raw_prop .= pack("C n/a*", MQTT_SERVER_REFERENCE, delete $args{'server_reference'});
    }

    if (exists $args{'authentication_method'}) {
        # 3.2.2.3.17  Authentication Method  (utf8 string)
        utf8::encode( $args{'authentication_method'} );
        $raw_prop .= pack("C n/a*", MQTT_AUTHENTICATION_METHOD, delete $args{'authentication_method'});
    }

    if (exists $args{'authentication_data'}) {
        # 3.2.2.3.18 Authentication Data  (binary data)
        $raw_prop .= pack("C n/a*", MQTT_AUTHENTICATION_DATA, delete $args{'authentication_data'});
    }

    foreach my $key (keys %args) {
        # 3.2.2.3.10  User Property  (utf8 string pair)
        my $val = $args{$key};
        next unless defined $val;
        utf8::encode( $key );
        utf8::encode( $val );
        $raw_prop .= pack("C n/a* n/a*", MQTT_USER_PROPERTY, $key, $val);
    }

    # 3.2.2  Variable Header

    # 3.2.2.1  Acknowledge flags  (byte)
    my $raw_mqtt = pack("C", $reason_code || 0);

    # 3.2.2.2  Reason code  (byte)
    $raw_mqtt .= pack("C", $session_present ? 0x01 : 0);

    # 3.2.2.3  Properties
    $raw_mqtt .= _encode_var_int(length $raw_prop);
    $raw_mqtt .= $raw_prop;

    $fh->push_write( 
        pack("C", MQTT_CONNACK << 4)      .  # 3.2.1  Packet type 
        _encode_var_int(length $raw_mqtt) .  # 3.2.1  Packet length
        $raw_mqtt
    );
}

sub _receive_disconnect {
    my ($self, $fh, $packet) = @_;

    # Handle abbreviated packet
    $$packet = "\x00\x00" if (length $$packet == 0);

    # 3.14.2.1  Reason Code  (byte)
    my $offs = 0;
    my $reason_code = _decode_byte($packet, \$offs);

    # 3.14.2.2.1  Property Length  (variable length int)
    my $prop_len = _decode_var_int($packet, \$offs);
    my $prop_end = $offs + $prop_len;

    my %prop = (
        'reason_code' => $reason_code,
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
            log_warn "Received DISCONNECT with unknown property $prop_id";
            $self->_shutdown($fh);
            return;
        }
    }

    $self->_shutdown($fh);
}

sub disconnect {
    my ($self, $fh, %args) = @_;

    my $reason_code = delete $args{'reason_code'};

    # 3.14.2.2  Properties

    my $raw_prop = '';

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

    $fh->push_write( 
        pack("C", MQTT_DISCONNECT << 4)   .  # 3.14.1  Packet type 
        _encode_var_int(length $raw_mqtt) .  # 3.14.1  Packet length
        $raw_mqtt
    );

    $self->_shutdown($fh);
}

sub _shutdown {
    my ($self, $fh) = @_;

    $self->remove_client($fh);

    delete $self->{connections}->{"$fh"};
}

sub _receive_subscribe {
    my ($self, $fh, $packet) = @_;

    # 3.8.2  Packet identifier  (short int)
    my $offs = 0;
    my $packet_id = _decode_int_16($packet, \$offs);

    # 3.8.2.1  Properties Length  (variable length int)
    my $prop_len = _decode_var_int($packet, \$offs);
    my $prop_end = $offs + $prop_len;
    my %prop;

    while ($offs < $prop_end) {

        my $prop_id = _decode_byte($packet, \$offs);

        if ($prop_id == MQTT_SUBSCRIPTION_IDENTIFIER) {
            # 3.8.2.1.2  Subscription Identifier  (variable len int)
            $prop{'subscription_identifier'} = _decode_var_int($packet, \$offs);
        }
        elsif ($prop_id == MQTT_USER_PROPERTY) {
            # 3.8.2.1.3  User Property  (utf8 string pair)
            my $key = _decode_utf8_str($packet, \$offs);
            my $val = _decode_utf8_str($packet, \$offs);
            $prop{$key} = $val;
        }
        else {
            # Protocol error
            log_warn "Received SUBSCRIBE with unexpected property $prop_id";
            $self->disconnect($fh, reason_code => 0x81);
            return;
        }
    }

    # 3.8.3  Payload

    my @reason_codes;

    while ($offs < length $$packet) {

        # 3.8.3  Topic Filter  (utf8 string)
        $prop{'topic_filter'} = _decode_utf8_str($packet, \$offs);

        # 3.8.3.1  Subscription Options  (byte)
        my $options = _decode_byte($packet, \$offs);

        $prop{'maximum_qos'}         = ($options & 0x03);
        $prop{'no_local'}            = ($options & 0x04) >> 2;
        $prop{'retain_as_published'} = ($options & 0x08) >> 3;
        $prop{'retain_handling'}     = ($options & 0x30) >> 4;

        my $reason_code = $self->subscribe_client($fh, \%prop);

        push @reason_codes, $reason_code;
    }

    $self->suback( $fh, 
        packet_id    => $packet_id,
        reason_codes => \@reason_codes,
    );
}

sub suback {
    my ($self, $fh, %args) = @_;

    my $packet_id    = delete $args{'packet_id'};
    my $reason_codes = delete $args{'reason_codes'};

    # 3.9.2.1  Properties

    my $raw_prop = '';

    if (exists $args{'reason_string'}) {
        # 3.9.2.1.2  Reason String  (utf8 string)
        utf8::encode( $args{'reason_string'} );
        $raw_prop .= pack("C n/a*", MQTT_REASON_STRING, delete $args{'reason_string'});
    }

    foreach my $key (keys %args) {
        # 3.9.2.1.3  User Property  (utf8 string pair)
        my $val = $args{$key};
        next unless defined $val;
        utf8::encode( $key );
        utf8::encode( $val );
        $raw_prop .= pack("C n/a* n/a*", MQTT_USER_PROPERTY, $key, $val);
    }

    # 3.9.2  Variable Header

    # 3.9.2  Packet id  (short int)
    my $raw_mqtt = pack("n", $packet_id);

    # 3.9.2.1  Properties
    $raw_mqtt .= _encode_var_int(length $raw_prop);
    $raw_mqtt .= $raw_prop;

    # 3.9.3  Payload

    foreach my $code (@$reason_codes) {
        # 3.9.3  Reason Codes  (byte)
        $raw_mqtt .= pack("C", $code);
    }

    $fh->push_write( 
        pack("C", MQTT_SUBACK << 4)       .  # 3.9.1  Packet type 
        _encode_var_int(length $raw_mqtt) .  # 3.9.1  Packet length
        $raw_mqtt
    );
}

sub _receive_unsubscribe {
    my ($self, $fh, $packet) = @_;

    # 3.10.2  Packet identifier  (short int)
    my $offs = 0;
    my $packet_id = _decode_int_16($packet, \$offs);

    # 3.10.2.1  Properties Length  (variable length int)
    my $prop_len = _decode_var_int($packet, \$offs);
    my $prop_end = $offs + $prop_len;
    my %prop;

    while ($offs < $prop_end) {

        my $prop_id = _decode_byte($packet, \$offs);

        if ($prop_id == MQTT_USER_PROPERTY) {
            # 3.10.2.1.2  User Property  (utf8 string pair)
            my $key = _decode_utf8_str($packet, \$offs);
            my $val = _decode_utf8_str($packet, \$offs);
            $prop{$key} = $val;
        }
        else {
            # Protocol error
            log_warn "Received UNSUBSCRIBE with unexpected property $prop_id";
            $self->disconnect($fh, reason_code => 0x81);
            return;
        }
    }

    # 3.10.3  Payload

    my @reason_codes;

    while ($offs < length $$packet) {

        # 3.10.3  Topic Filter  (utf8 string)
        $prop{'topic_filter'} = _decode_utf8_str($packet, \$offs);

        my $reason_code = $self->unsubscribe_client($fh, \%prop);

        push @reason_codes, $reason_code;
    }

    $self->unsuback( $fh, 
        packet_id    => $packet_id,
        reason_codes => \@reason_codes,
    );
}

sub unsuback {
    my ($self, $fh, %args) = @_;

    my $packet_id    = delete $args{'packet_id'};
    my $reason_codes = delete $args{'reason_codes'};

    # 3.11.2.1  Properties

    my $raw_prop = '';

    if (exists $args{'reason_string'}) {
        # 3.11.2.1.2  Reason String  (utf8 string)
        utf8::encode( $args{'reason_string'} );
        $raw_prop .= pack("C n/a*", MQTT_REASON_STRING, delete $args{'reason_string'});
    }

    foreach my $key (keys %args) {
        # 3.11.2.1.3  User Property  (utf8 string pair)
        my $val = $args{$key};
        next unless defined $val;
        utf8::encode( $key );
        utf8::encode( $val );
        $raw_prop .= pack("C n/a* n/a*", MQTT_USER_PROPERTY, $key, $val);
    }

    # 3.14.2  Variable Header

    # 3.11.2  Packet id  (short int)
    my $raw_mqtt = pack("n", $packet_id);

    # 3.11.2.1  Properties
    $raw_mqtt .= _encode_var_int(length $raw_prop);
    $raw_mqtt .= $raw_prop;

    # 3.11.3  Payload

    foreach my $code (@$reason_codes) {
        # 3.11.3  Reason Codes  (byte)
        $raw_mqtt .= pack("C", $code);
    }

    $fh->push_write( 
        pack("C", MQTT_UNSUBACK << 4)     .  # 3.11.1  Packet type 
        _encode_var_int(length $raw_mqtt) .  # 3.11.1  Packet length
        $raw_mqtt
    );
}

sub pingreq {
    my ($self, $fh) = @_;

    $fh->push_write( 
        pack( "C C",
            MQTT_PINGREQ << 4,  # 3.12.1  Packet type 
            0,                  # 3.12.1  Remaining length
        )
    );
}

sub pingresp {
    my ($self, $fh) = @_;

    $fh->push_write( 
        pack( "C C",
            MQTT_PINGRESP << 4,  # 3.13.1  Packet type 
            0,                   # 3.13.1  Remaining length
        )
    );
}

sub _receive_pingresp {
    my ($self, $fh) = @_;

    # No action taken
}

sub _receive_publish {
    my ($self, $fh, $packet, $flags) = @_;

    # 3.3.2.1  Topic Name  (utf8 str)
    my $topic = unpack("n/a", $$packet);
    my $offs = 2 + length $topic;
    utf8::decode($topic);

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
                $fh->{topic_alias}->{$alias} = $topic;
            }
            else {
                $prop{'topic'} = $fh->{topic_alias}->{$alias};
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
            log_warn "Received PUBLISH with unknown property $prop_id";
            $self->disconnect($fh, reason_code => 0x81);
            return;
        }
    }

    # Trim variable header from packet, the remaining is the payload
    substr($$packet, 0, $prop_end, '');

    if ($prop{'payload_format'}) {
        # Payload is UTF-8 Encoded Character Data
        utf8::decode( $$packet );
    }

    if ($prop{'qos'} == 1) {
        # Acknowledge received message
        $self->puback( $fh, packet_id => $prop{'packet_id'} );
        delete $prop{'packet_id'};
    }

    $prop{'payload'} = $packet;

    $self->incoming_message($fh, \%prop);
}

sub publish {
    my ($self, $fh, %args) = @_;

    my $topic     = delete $args{'topic'};
    my $payload   = delete $args{'payload'};
    my $qos       = delete $args{'qos'};
    my $dup       = delete $args{'duplicate'};
    my $retain    = delete $args{'retain'};
    my $packet_id = delete $args{'packet_id'};
    my $on_puback = delete $args{'on_puback'};

    croak "Message topic was not specified" unless defined $topic;

    $payload = '' unless defined $payload;
    my $payload_ref = (ref $payload eq 'SCALAR') ? $payload : \$payload;

    #TODO: 3.3.2.3.4  Topic Alias
    my $topic_alias;

    # 3.3.1.2  QoS level
    my $flags = 0;
    $flags |= $qos << 1 if $qos;
    $flags |= 0x04      if $dup;
    $flags |= 0x01      if $retain;

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

    if (exists $args{'subscription_identifier'}) {
        # 3.3.2.3.8  Subscription Identifier  (variable int)
        $raw_prop .= pack("C", MQTT_SUBSCRIPTION_IDENTIFIER) .
                    _encode_var_int( delete $args{'subscription_identifier'} );
    }

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

    $self->{_WORKER}->{notif_count}++;  # track outgoing messages for stats

    $fh->push_write( $raw_mqtt );
}

sub puback {
    my ($self, $fh, %args) = @_;

    croak "Missing packet_id" unless $args{'packet_id'};

    my $raw_mqtt = pack( 
        "C C n C", 
        MQTT_PUBACK << 4,           # 3.4.1    Packet type 
        3,                          # 3.4.1    Remaining length
        $args{'packet_id'},         # 3.4.2    Packet identifier
        $args{'reason_code'} || 0,  # 3.4.2.1  Reason code
    );

    $fh->push_write( $raw_mqtt );
}

sub _receive_puback {
    my ($self, $fh, $packet) = @_;

    my ($packet_id, $reason_code) = unpack("n C", $$packet);
    $reason_code = 0 unless defined $reason_code;

    $self->get_client($fh)->on_puback($packet_id);
}

sub _receive_pubrec {
    my ($self, $fh, $packet) = @_;

    $self->disconnect($fh, reason_code => 0x9B);
}

sub _receive_pubrel {
    my ($self, $fh, $packet) = @_;

    $self->disconnect($fh, reason_code => 0x9B);
}

sub _receive_pubcomp {
    my ($self, $fh, $packet) = @_;

    $self->disconnect($fh, reason_code => 0x9B);
}

sub _receive_pubauth {
    my ($self, $fh, $packet) = @_;

    $self->disconnect($fh, reason_code => 0x9B);
}


#------------------------------------------------------------------------------

sub add_client {
    my ($self, $fh, $prop) = @_;
    weaken($self);

    my $client_id = $prop->{'client_identifier'};
    my $username  = $prop->{'username'};
    my $password  = $prop->{'password'};

    my $users_cfg = $self->{'users'};
    my $authorized;

    AUTH: {

        last unless (length $client_id);
        last unless (length $username);
        last unless (length $password);

        last unless ($users_cfg);
        last unless ($users_cfg->{$username});
        last unless ($users_cfg->{$username}->{'password'} eq $password);

        $authorized = 1;
    }

    unless ($authorized) {
        log_warn('Client not authorized');
        $self->_shutdown($fh);
        return;
    }

    my $client = Beekeeper::Service::ToyBroker::Client->new(
        client_id => $client_id,
        publish   => sub { $self->publish($fh, @_) },
    );

    $self->{clients}->{"$fh"} = $client;

    $self->connack( $fh, maximum_qos => 1 );
}

sub get_client {
    my ($self, $fh) = @_;

    return $self->{clients}->{"$fh"};
}

sub remove_client {
    my ($self, $fh) = @_;

    my $client = $self->{clients}->{"$fh"};

    return unless $client;  # called on eof after DISCONNECT 

    foreach my $topic_filter (keys %{$client->{subscriptions}}) {

        $self->unsubscribe_client($fh, { topic_filter => $topic_filter });
    }

    $client->resend_unacked_messages;

    delete $self->{clients}->{"$fh"};
}

sub incoming_message {
    my ($self, $fh, $message) = @_;

    my @topics = values %{$self->{topics}};

    foreach my $topic (@topics) {

        next unless $message->{'topic'} =~ $topic->{topic_regex};

        foreach my $subscription (values %{$topic->{subscriptions}}) {

            $subscription->send_message( $message );
        }
    }
}

sub _validate_filter {
    my ($self, $topic_filter) = @_;

    return unless defined $topic_filter;

    $topic_filter =~ s|^\$share/([-\w]+)/||;

    my $shared_group = $1;

    return unless $topic_filter =~ m/^ (( [-\w]+ | \+ ) \/)* ( [-\w]+ | \+ | \# ) $/x;

    return ($topic_filter, $shared_group);
}

sub subscribe_client {
    my ($self, $fh, $prop) = @_;

    my ($topic_filter, $shared_group) = $self->_validate_filter( $prop->{'topic_filter'} );

    return 0x8F unless defined $topic_filter;  # "Topic Filter invalid"

    #TODO: Access permissions

    my $topic = $self->{topics}->{$topic_filter};

    unless ($topic) {
        $topic = Beekeeper::Service::ToyBroker::TopicFilter->new( $topic_filter );
        $self->{topics}->{$topic_filter} = $topic;
    }

    my $client = $self->{clients}->{"$fh"};

    my $granted_qos = $prop->{'maximum_qos'} ? 1 : 0;

    my $subscription = Beekeeper::Service::ToyBroker::Subscription->new(
        id       => $prop->{'subscription_identifier'},
        no_local => $prop->{'no_local'},
        max_qos  => $granted_qos,
        client   => $client,
    );

    if ($shared_group) {
        $topic->add_shared_subscription( $subscription, $shared_group );
    }
    else {
        $topic->add_subscription( $subscription, $client->client_id );
    }

    $client->{subscriptions}->{$prop->{topic_filter}} = 1;

    return $granted_qos;
}

sub unsubscribe_client {
    my ($self, $fh, $prop) = @_;

    my ($topic_filter, $shared_group) = $self->_validate_filter( $prop->{'topic_filter'} );

    return 0x8F unless defined $topic_filter;  # "Topic Filter invalid"

    my $topic = $self->{topics}->{$topic_filter};

    return 0x11 unless defined $topic;  # "No subscription existed"

    my $client = $self->{clients}->{"$fh"};
    my $client_id = $client->client_id;
    my $success;

    if ($shared_group) {
        $success = $topic->remove_shared_subscription( $client_id, $shared_group );
    }
    else {
        $success = $topic->remove_subscription( $client_id );
    }

    delete $self->{topics}->{$topic_filter} unless $topic->has_subscriptions;

    delete $client->{subscriptions}->{$prop->{topic_filter}};

    return $success ? 0x00 : 0x11;
}


package
    Beekeeper::Service::ToyBroker::Client;   # hide from PAUSE

sub new {
    my ($class, %args) = @_;

    my $self = {
        client_id     => $args{'client_id'},
        publish       => $args{'publish'},
        subscriptions => {},
        pending_ack   => {},
        packet_seq    => 1,
    };

    bless $self, $class;
}

sub client_id {
    my ($self) = @_;

    $self->{client_id};
}

sub publish {
    my ($self, $message, $sender) = @_;

    my $packet_id;

    if ($message->{'qos'}) {

        $packet_id = $self->{packet_seq}++;
        $self->{packet_seq} = 1 if ($packet_id == 0xFFFF);

        $self->{pending_ack}->{$packet_id} = [ $message, $sender ];
    }

    local $message->{'packet_id'} = $packet_id if $packet_id;

    $self->{publish}->( %$message );
}

sub on_puback {
    my ($self, $packet_id) = @_;

    delete $self->{pending_ack}->{$packet_id};
}

sub resend_unacked_messages {
    my ($self) = @_;

    my $pending_ack = $self->{pending_ack};

    foreach my $packet_id (keys %$pending_ack) {

        my $unacked = delete $pending_ack->{$packet_id};

        my ($message, $sender) = @$unacked;

        next unless $sender->has_subscriptions;

        $message->{'duplicate'} = 1;

        $sender->send_message( $message );
    }
}


package
    Beekeeper::Service::ToyBroker::TopicFilter;   # hide from PAUSE

sub new {
    my ($class, $topic_filter) = @_;

    my $topic_regex = $topic_filter;
    $topic_regex =~ s/\+/[^\/]+/g;
    $topic_regex =~ s/\#/.+/g;

    my $self = {
        subscriptions => {},
        topic_filter  => $topic_filter,
        topic_regex   => qr/^${topic_regex}$/,
    };

    bless $self, $class;
}

sub has_subscriptions {
    my ($self) = @_;

    return (scalar keys %{$self->{subscriptions}}) ? 1 : 0;
}

sub add_subscription {
    my ($self, $subscription, $client_id) = @_;

    $self->{subscriptions}->{"client/$client_id"} = $subscription;
}

sub add_shared_subscription {
    my ($self, $subscription, $shared_group) = @_;

    my $shared = $self->{subscriptions}->{"shared/$shared_group"};

    unless ($shared) {
        $shared = Beekeeper::Service::ToyBroker::SharedSubscription->new;
        $self->{subscriptions}->{"shared/$shared_group"} = $shared;
    }

    $shared->add_subscription( $subscription );
}

sub remove_subscription {
    my ($self, $client_id) = @_;

    my $existed = delete $self->{subscriptions}->{"client/$client_id"};

    return $existed ? 1 : 0;
}

sub remove_shared_subscription {
    my ($self, $client_id, $shared_group) = @_;

    my $shared = $self->{subscriptions}->{"shared/$shared_group"};

    return 0 unless $shared;

    my $success = $shared->remove_subscription( $client_id );

    delete $self->{subscriptions}->{"shared/$shared_group"} unless $shared->has_subscriptions;

    return $success;
}


package
    Beekeeper::Service::ToyBroker::Subscription;   # hide from PAUSE

sub new {
    my $class = shift;

    my $self = {
        id       => undef,
        max_qos  => undef,
        no_local => undef,
        client   => undef,
        @_
    };

    bless $self, $class;
}

sub client {
    my ($self) = @_;

    $self->{client};
}

sub has_subscriptions {
    my ($self) = @_;

    return (scalar keys %{$self->{subscriptions}}) ? 1 : 0;
}

sub send_message {
    my ($self, $message, $sender) = @_;

    local $message->{'subscription_identifier'} = $self->{id} if $self->{id};

    local $message->{'qos'} = 0 if ($self->{max_qos} == 0);

    $self->{client}->publish( $message, $sender || $self );
}


package
    Beekeeper::Service::ToyBroker::SharedSubscription;   # hide from PAUSE

sub new {
    my ($class, %args) = @_;

    my $self = {
        subscriptions => {},
        subscr_keys   => [],
    };

    bless $self, $class;
}

sub add_subscription {
    my ($self, $subscription) = @_;

    my $client_id = $subscription->client->client_id;

    push @{$self->{subscr_keys}}, "client/$client_id";

    $self->{subscriptions}->{"client/$client_id"} = $subscription;
}

sub remove_subscription {
    my ($self, $client_id) = @_;

    my $subscr_keys = $self->{subscr_keys};
    @$subscr_keys = grep { $_ ne "client/$client_id" } @$subscr_keys;

    my $existed = delete $self->{subscriptions}->{"client/$client_id"};

    return $existed ? 1 : 0;
}

sub has_subscriptions {
    my ($self) = @_;

    return (scalar keys %{$self->{subscriptions}}) ? 1 : 0;
}

sub send_message {
    my ($self, $message) = @_;

    # Round robin
    my $subscr_keys = $self->{subscr_keys};
    my $next = shift @$subscr_keys;
    push @$subscr_keys, $next;

    my $subscription = $self->{subscriptions}->{$next};

    #TODO: Prefer idle subscriptions

    $subscription->send_message( $message, $self );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Beekeeper::Service::ToyBroker::Worker - Basic MQTT 5.0 broker

=head1 VERSION

Version 0.09

=head1 DESCRIPTION

ToyBroker implements a small MQTT 5.0 subset needed to run a Beekeeper worker pool.

It is intended to be used for development or running tests only. For production
work a real broker (like Mosquitto, HiveMQ, VerneMQ...) is needed.

A ToyBroker will be started automatically in any pool which has C<use_toybroker> 
option set to a true value in its config file C<pool.config.json>.

ToyBroker is configured from file C<toybroker.config.json>, which is looked for 
in ENV C<BEEKEEPER_CONFIG_DIR>, C<~/.config/beekeeper> and then C</etc/beekeeper>.

Example configuration:

  [
      {
          "listen_addr" : "127.0.0.1",
          "listen_port" : "1883",
  
          "users" : {
              "backend" : { "password" : "def456" },
          },
      },
      {
          "listen_addr" : "127.0.0.1",
          "listen_port" : "11883",
  
          "users" : {
              "frontend" : { "password" : "abc123" },
              "router"   : { "password" : "ghi789" },
          },
      },
  ]

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
