package Tests::Mqtt;

use strict;
use warnings;

use base 'Tests::Service::Base';
use Tests::Service::Config;
use Beekeeper::MQTT;

use Test::More;
use Time::HiRes 'sleep';
use Data::Dumper;

my $DEBUG = 1;

my $bus_config;

sub read_bus_config : Test(startup => 1) {
    my $self = shift;

    $bus_config = Beekeeper::Config->get_bus_config( bus_id => 'test' );

    ok( $bus_config->{host}, "Read bus config, connecting to " . $bus_config->{host});
}

sub async_wait {
    my ($self, $time) = @_;
    $time *= 10 if $self->automated_testing;
    my $cv = AnyEvent->condvar; 
    my $tmr = AnyEvent->timer( after => 1, cb => $cv ); 
    $cv->recv;
}

sub test_01_topic : Test(3) {
    my $self = shift;

    my $bus1 = Beekeeper::MQTT->new( %$bus_config );
    my $bus2 = Beekeeper::MQTT->new( %$bus_config );

    $bus1->connect( blocking => 1 );
    $bus2->connect( blocking => 1 );

    my ($cv, $tmr);
    my @received;

    $bus1->subscribe(
        topic => 'msg/bar',
        on_publish => sub {
            my ($payload, $properties) = @_;
            push @received, {
                bus        => 1,
                properties => { %$properties },
                payload    => $$payload,
            };
        },
    );

    $bus2->subscribe(
        topic => 'msg/bar',
        on_publish => sub {
            my ($payload, $properties) = @_;
            push @received, {
                bus        => 2,
                properties => { %$properties },
                payload    => $$payload,
            };
        },
    );

    $self->async_wait( 0.2 );

    $bus1->publish(
        topic   => 'msg/bar',
        payload => 'Hello 1',
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 2, "Received 2 messages from topic");
    is( $received[0]->{payload}, 'Hello 1', "got message");
    is( $received[1]->{payload}, 'Hello 1', "got message");

    # $DEBUG && diag Dumper \@received;

    $bus1->disconnect;
    $bus2->disconnect;
}

sub test_02_topic_wildcard : Test(7) {
    my $self = shift;

    my $bus1 = Beekeeper::MQTT->new( %$bus_config );
    my $bus2 = Beekeeper::MQTT->new( %$bus_config );

    $bus1->connect( blocking => 1 );
    $bus2->connect( blocking => 1 );

    my ($cv, $tmr);
    my @received;

    $bus1->subscribe(
        topic => 'msg/+',
        on_publish => sub {
            my ($payload, $properties) = @_;
            push @received, {
                bus     => 1,
                headers => { %$properties },
                payload => $$payload,
            };
        },
    );

    $bus2->subscribe(
        topic => 'msg/#',
        on_publish => sub {
            my ($payload, $properties) = @_;
            push @received, {
                bus        => 2,
                properties => { %$properties },
                payload    => $$payload,
            };
        },
    );

    $self->async_wait( 0.2 );

    $bus1->publish(
        topic   => 'msg/bar',
        payload => 'Hello 2',
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 2, "Received 2 messages from topic");
    is( $received[0]->{payload}, 'Hello 2', "got message");
    is( $received[1]->{payload}, 'Hello 2', "got message");

    # $DEBUG && diag Dumper \@received;

    @received = ();


    $bus1->publish(
        topic   => 'foobar',
        payload => 'Hello 3',
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 0, "Received no messages from topic");

    # $DEBUG && diag Dumper \@received;

    @received = ();


    $bus1->publish(
        topic   => 'msg/bar/baz',
        payload => 'Hello 4',
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 1, "Received 1 message from topic");
    is( $received[0]->{payload}, 'Hello 4', "got message");
    is( $received[0]->{bus}, 2, "Got message");

    # $DEBUG && diag Dumper \@received;

    $bus1->disconnect;
    $bus2->disconnect;
}

sub test_03_shared_topic : Test(4) {
    my $self = shift;

    my $bus1 = Beekeeper::MQTT->new( %$bus_config );
    my $bus2 = Beekeeper::MQTT->new( %$bus_config );

    $bus1->connect( blocking => 1 );
    $bus2->connect( blocking => 1 );

    my ($cv, $tmr);
    my @received;

    $bus1->subscribe(
        topic => '$share/GROUPID/req/msg/bar',
        on_publish => sub {
            my ($payload, $properties) = @_;
            push @received, {
                bus        => 1,
                properties => { %$properties },
                payload    => $$payload,
            };
        },
    );

    $bus2->subscribe(
        topic => '$share/GROUPID/req/msg/bar',
        on_publish => sub {
            my ($payload, $properties) = @_;
            push @received, {
                bus        => 2,
                properties => { %$properties },
                payload    => $$payload,
            };
        },
    );

    $self->async_wait( 0.2 );

    $bus1->publish(
        topic   => 'req/msg/bar',
        payload => 'Hello 5',
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 1, "Received 1 message from shared topic");
    is( $received[0]->{payload}, 'Hello 5', "got message");

    # $DEBUG && diag Dumper \@received;

    @received = ();


    $bus1->publish(
        topic   => 'req/msg/bar',
        payload => 'Hello 6',
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 1, "Received 1 message from shared topic");
    is( $received[0]->{payload}, 'Hello 6', "got message");

    # $DEBUG && diag Dumper \@received;

    $bus1->disconnect;
    $bus2->disconnect;
}

sub test_04_private_topic : Test(6) {
    my $self = shift;

    my $bus1 = Beekeeper::MQTT->new( %$bus_config );
    my $bus2 = Beekeeper::MQTT->new( %$bus_config );
    my $bus3 = Beekeeper::MQTT->new( %$bus_config );

    $bus1->connect( blocking => 1 );
    $bus2->connect( blocking => 1 );
    $bus3->connect( blocking => 1 );

    my ($cv, $tmr);
    my (@received_1, @received_2, @received_3);

    my $bus1_private = "priv/" . $bus1->{client_id};

    $bus1->subscribe(
        topic => $bus1_private,
        on_publish => sub {
            my ($payload, $properties) = @_;
            push @received_1, {
                bus        => 1,
                properties => { %$properties },
                payload    => $$payload,
            };
        },
    );

    $bus2->subscribe(
        topic => '$share/GROUPID/msg/bar',
        on_publish => sub {
            my ($payload, $properties) = @_;
            push @received_2, {
                bus        => 2,
                properties => { %$properties },
                payload    => $$payload,
            };
        },
    );

    $self->async_wait( 0.2 );

    $bus1->publish(
        topic          => 'msg/bar',
        response_topic => $bus1_private,
        payload        => 'Hello 7',
    );

    $self->async_wait( 0.2 );

    is( scalar(@received_2), 1, "Received 1 message from private topic");
    is( $received_2[0]->{payload}, 'Hello 7', "got message");

    my $reply_to = $received_2[0]->{properties}->{'response_topic'};
    ok( $reply_to, "Got response_topic header");

    # $DEBUG && diag Dumper \@received_2;

    $bus2->publish(
        topic   => $reply_to,
        payload => 'Hello 8',
    );

    $self->async_wait( 0.2 );

    is( scalar(@received_1), 1, "Received 1 message from private topic");
    is( $received_1[0]->{payload}, 'Hello 8', "got message");

    # $DEBUG && diag Dumper \@received_1;


    eval {
        # Try to subscribe to another connection private topic
        $bus3->subscribe(
            topic => $reply_to,
            on_publish => sub {
                my ($payload, $properties) = @_;
                push @received_3, {
                    bus        => 2,
                    properties => { %$properties },
                    payload    => $$payload,
                };
            },
        );

        $self->async_wait( 0.2 );
    };

    if ($@) {
        # Either subscribe fail...
        ok(1, "Can't subscribe to another connection private topic");
    }
    else {
        # Or can't receive messages
        $bus2->publish(
            topic   => $bus1_private,
            payload => 'Hello 9',
        );

        $self->async_wait( 0.2 );

        TODO: {
            local $TODO = "ToyBroker does not restrict topics priv/{client_id}";
            is( scalar(@received_3), 0, "No message received from private topic of another connection");
        }
    }

    $bus1->disconnect;
    $bus2->disconnect;
    $bus3->disconnect if $bus3->{is_connected};
}

sub test_05_shared_topic_queuing : Test(7) {
    my $self = shift;

    my $bus1 = Beekeeper::MQTT->new( %$bus_config, 'receive_maximum' => 1 );
    my $bus2 = Beekeeper::MQTT->new( %$bus_config, 'receive_maximum' => 1 );

    $bus1->connect( blocking => 1 );
    $bus2->connect( blocking => 1 );

    my ($cv, $tmr);
    my @received;

    $bus1->subscribe(
        topic       => '$share/GROUP_ID/req/msg/bar',
        maximum_qos => 1,
        on_publish  => sub {
            my ($payload, $properties) = @_;
            push @received, {
                bus        => 1,
                properties => $properties,
                payload    => $$payload,
            };
        },
    );

    $bus2->subscribe(
        topic       => '$share/GROUP_ID/req/msg/bar',
        maximum_qos => 1,
        on_publish  => sub {
            my ($payload, $properties) = @_;
            push @received, {
                bus        => 2,
                properties => $properties,
                payload    => $$payload,
            };
        },
    );

    $self->async_wait( 0.2 );


    $bus1->publish(
        topic   => 'req/msg/bar',
        payload => 'Hello 21',
        qos     =>  1,
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 1, "Received 1 message from shared topic");
    is( $received[0]->{payload}, 'Hello 21', "got message");

    # $DEBUG && diag Dumper \@received;


    $bus1->publish(
        topic   => 'req/msg/bar',
        payload => 'Hello 22',
        qos     =>  1,
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 2, "Received 1 more message from shared topic");
    is( $received[1]->{payload}, 'Hello 22', "got message");

    # $DEBUG && diag Dumper \@received;


    # This one must be queued
    $bus1->publish(
        topic   => 'req/msg/bar',
        payload => 'Hello 23',
        qos     =>  1,
    );

    $self->async_wait( 0.2 );

    TODO: {
        local $TODO = "Broker MQTT does not honor 'receive_maximum' CONNECT property";
        is( scalar(@received), 2, "Received no more messages until PUBACK");
    }

    for my $n (0..1) {

        my $packet_id = $received[$n]->{properties}->{'packet_id'};

        if ($received[$n]->{bus} == 1) {
            $bus1->puback( packet_id => $packet_id );
        }
        else {
            $bus2->puback( packet_id => $packet_id );
        }
    }

    $self->async_wait( 0.2 );

    is( scalar(@received), 3, "Received the queued message after PUBACK");
    is( $received[2]->{payload}, 'Hello 23', "got message");

    # $DEBUG && diag Dumper \@received;

    for my $n (2..2) {

        my $packet_id = $received[$n]->{properties}->{'packet_id'};

        if ($received[$n]->{bus} == 1) {
            $bus1->puback( packet_id => $packet_id );
        }
        else {
            $bus2->puback( packet_id => $packet_id );
        }
    }

    $bus1->disconnect;
    $bus2->disconnect;
}

sub test_06_utf8 : Test(11) {
    my $self = shift;

    my $bus = Beekeeper::MQTT->new( %$bus_config );

    $bus->connect( blocking => 1 );

    my @received;

    $bus->subscribe(
        topic => 'msg/bar',
        on_publish => sub {
            my ($payload, $properties) = @_;
            push @received, {
                properties => { %$properties },
                payload    => $$payload,
            };
        },
    );

    $self->async_wait( 0.2 );

    my $utf8_string = "\x{263A}";

    my $binary_blob = $utf8_string;
    utf8::encode($binary_blob);

    ok( utf8::is_utf8($utf8_string), 'String is utf8' );
    ok(!utf8::is_utf8($binary_blob), 'Blob is not utf8' );

    is( length($utf8_string), 1, 'String length is 1 char' );
    is( length($binary_blob), 3, 'Blob length is 3 bytes' );

    $bus->publish(
        topic   => 'msg/bar',
        payload => $utf8_string,
    );

    $bus->publish(
        topic   => 'msg/bar',
        payload => $binary_blob,
    );

    $bus->publish(
        topic      => 'msg/bar',
        payload    => '',
        utf8_value => $utf8_string,
    );

    $bus->publish(
        topic        => 'msg/bar',
        payload      => '',
        $utf8_string => 'utf8_key',
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 4, "Received 4 messages from topic");

    ok( utf8::is_utf8($received[0]->{payload}), 'Received string is utf8' );
    ok(!utf8::is_utf8($received[1]->{payload}), 'Received blob is not utf8' );

    is( $received[0]->{payload}, $utf8_string, "Got utf8 string");
    is( $received[1]->{payload}, $binary_blob, "Got binary blob");

    is( $received[2]->{properties}->{'utf8_value'}, $utf8_string, "Got utf8 property value");
    is( $received[3]->{properties}->{$utf8_string}, 'utf8_key',   "Got utf8 property key");

    # $DEBUG && diag Dumper \@received;

    $bus->disconnect;
}

sub test_07_big_message : Test(4) {
    my $self = shift;

    my $bus = Beekeeper::MQTT->new( %$bus_config );

    $bus->connect( blocking => 1 );

    my @received;

    $bus->subscribe(
        topic => 'msg/bar',
        on_publish => sub {
            my ($payload, $properties) = @_;
            push @received, {
                properties => { %$properties },
                payload    => $$payload,
            };
        },
    );

    my $data = 'X' x 1048576;

    $bus->publish(
        topic      => 'msg/bar',
        payload    => \$data,
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 1, "Received 1 message from topic");
    is( length( $received[0]->{payload} ), 1048576, "Got a 1 MiB message");

    $data = 'X' x 10485760;

    $bus->publish(
        topic      => 'msg/bar',
        payload    => \$data,
    );

    $self->async_wait( 0.2 );

    is( scalar(@received), 2, "Received 1 message from topic");
    is( length( $received[1]->{payload} ), 10485760, "Got a 10 MiB message");

    $bus->disconnect;
}

1;
