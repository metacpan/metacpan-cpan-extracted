package Tests::Stomp;

use strict;
use warnings;

use base 'Tests::Service::Base';
use Tests::Service::Config;
use Beekeeper::Bus::STOMP;

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


sub test_01_topic : Test(3) {
    my $self = shift;

    my $bus1 = Beekeeper::Bus::STOMP->new( %$bus_config );
    my $bus2 = Beekeeper::Bus::STOMP->new( %$bus_config );

    $bus1->connect( blocking => 1 );
    $bus2->connect( blocking => 1 );

    my ($cv, $tmr);
    my @received;

    $bus1->subscribe(
        destination => '/topic/foo.bar',
        on_receive_msg => sub {
            my ($body, $headers) = @_;
            push @received, {
                bus     => 1,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

    $bus2->subscribe(
        destination => '/topic/foo.bar',
        on_receive_msg => sub {
            my ($body, $headers) = @_;
            push @received, {
                bus     => 2,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;


    $bus1->send(
        destination => '/topic/foo.bar',
        body        => 'Hello',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received), 2, "received 2 messages from topic");
    is( $received[0]->{body}, 'Hello', "got message");
    is( $received[1]->{body}, 'Hello', "got message");

    # $DEBUG && diag Dumper \@received;

    $bus1->disconnect( blocking => 1 );
    $bus2->disconnect( blocking => 1 );
}

sub test_02_topic_wildcard : Test(7) {
    my $self = shift;

    my $bus1 = Beekeeper::Bus::STOMP->new( %$bus_config );
    my $bus2 = Beekeeper::Bus::STOMP->new( %$bus_config );

    $bus1->connect( blocking => 1 );
    $bus2->connect( blocking => 1 );

    my ($cv, $tmr);
    my @received;

    $bus1->subscribe(
        destination => '/topic/foo.*',
        on_receive_msg => sub {
            my ($body, $headers) = @_;
            push @received, {
                bus     => 1,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

    $bus2->subscribe(
        destination => '/topic/foo.#', # Artemis MQ matchs '/topic/foo'
        on_receive_msg => sub {
            my ($body, $headers) = @_;
            push @received, {
                bus     => 2,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;


    $bus1->send(
        destination => '/topic/foo.bar',
        body        => 'Hello',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received), 2, "received 2 messages from topic");
    is( $received[0]->{body}, 'Hello', "got message");
    is( $received[1]->{body}, 'Hello', "got message");

    # $DEBUG && diag Dumper \@received;

    @received = ();


    $bus1->send(
        destination => '/topic/foobar',
        body        => 'Hello',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received), 0, "received no messages from topic");

    # $DEBUG && diag Dumper \@received;

    @received = ();


    $bus1->send(
        destination => '/topic/foo.bar.baz',
        body        => 'Hello',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received), 1, "received 1 message from topic");
    is( $received[0]->{body}, 'Hello', "got message");
    is( $received[0]->{bus}, 2, "got message");

    # $DEBUG && diag Dumper \@received;

    $bus1->disconnect( blocking => 1 );
    $bus2->disconnect( blocking => 1 );
}

sub test_03_queue : Test(4) {
    my $self = shift;

    my $bus1 = Beekeeper::Bus::STOMP->new( %$bus_config );
    my $bus2 = Beekeeper::Bus::STOMP->new( %$bus_config );

    $bus1->connect( blocking => 1 );
    $bus2->connect( blocking => 1 );

    my ($cv, $tmr);
    my @received;

    $bus1->subscribe(
        destination => '/queue/req.foo.bar',
        on_receive_msg => sub {
            my ($body, $headers) = @_;
            push @received, {
                bus     => 1,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

    $bus2->subscribe(
        destination => '/queue/req.foo.bar',
        on_receive_msg => sub {
            my ($body, $headers) = @_;
            push @received, {
                bus     => 2,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;


    $bus1->send(
        destination => '/queue/req.foo.bar',
        body        => 'Hello',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received), 1, "received 1 message from queue");
    is( $received[0]->{body}, 'Hello', "got message");

    # $DEBUG && diag Dumper \@received;

    @received = ();


    $bus1->send(
        destination => '/queue/req.foo.bar',
        body        => 'Hello',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received), 1, "received 1 message from queue");
    is( $received[0]->{body}, 'Hello', "got message");

    # $DEBUG && diag Dumper \@received;

    $bus1->disconnect( blocking => 1 );
    $bus2->disconnect( blocking => 1 );
}

sub test_04_temp_queue : Test(11) {
    my $self = shift;

    my $bus1 = Beekeeper::Bus::STOMP->new( %$bus_config );
    my $bus2 = Beekeeper::Bus::STOMP->new( %$bus_config );
    my $bus3 = Beekeeper::Bus::STOMP->new( %$bus_config );

    $bus1->connect( blocking => 1 );
    $bus2->connect( blocking => 1 );
    $bus3->connect( blocking => 1 );

    my ($cv, $tmr);
    my (@received_1, @received_2, @received_3);

    $bus1->subscribe(
        destination => '/temp-queue/tmp.12345',
        on_receive_msg => sub {
            my ($body, $headers) = @_;
            push @received_1, {
                bus     => 1,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

   $bus2->subscribe(
        destination => '/queue/foo.bar',
        on_receive_msg => sub {
            my ($body, $headers) = @_;
            push @received_2, {
                bus     => 2,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;


    $bus1->send(
        destination => '/queue/foo.bar',
       'reply-to'   => '/temp-queue/tmp.12345',
        body        => 'Hello',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received_2), 1, "received 1 message from queue");
    is( $received_2[0]->{body}, 'Hello', "got message");

    my $reply_to = $received_2[0]->{headers}->{'reply-to'};
    ok( $reply_to, "got reply-to header");

    # $DEBUG && diag Dumper \@received_2;


    $bus2->send(
        destination => $reply_to,
        body        => 'Hello!',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received_1), 1, "received 1 message from temp-queue");
    is( $received_1[0]->{body}, 'Hello!', "got message");

    # $DEBUG && diag Dumper \@received_1;


    eval {
        # Try to subscribe to another connection temp-queue
        $bus3->subscribe(
            destination => $reply_to,
            on_receive_msg => sub {
                my ($body, $headers) = @_;
                push @received_3, {
                    bus     => 2,
                    headers => { %$headers },
                    body    => $$body,
                };
            },
        );

        $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;
    };

    if ($@) {
        # Either subscribe fail...
        ok(1, "can't subscribe to another connection temp-queue");
        ok(1);
        ok(1);
    }
    else {
        # Or can't receive messages
        $bus2->send(
            destination => '/temp-queue/tmp.12345',
            body        => 'Hello again',
        );

        $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

        is( scalar(@received_1), 1, "did not received message from another temp-queue with same destination");
        is( $received_1[-1]->{body}, 'Hello!', "did not received another message");

        is( scalar(@received_3), 0, "no message received from another connection temp-queue");
    }

    eval {
        # Try to subscribe to another connection reply-to
        $bus3->connect( blocking => 1 ) unless $bus3->{is_connected};

        $bus3->subscribe(
            destination => $reply_to,
            on_receive_msg => sub {
                my ($body, $headers) = @_;
                push @received_3, {
                    bus     => 2,
                    headers => { %$headers },
                    body    => $$body,
                };
            },
        );

        $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;
    };

    if ($@) {
        # Either subscribe fail...
        ok(1, "can't subscribe to another connection reply-to");
        ok(1);
        ok(1);
    }
    else {
        # Or can't receive messages
        $bus2->send(
            destination => $reply_to,
            body        => 'Pff',
        );

        $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

        is( scalar(@received_1), 2, "sent another message to temp-queue");
        is( $received_1[1]->{body}, 'Pff', "sent message");

        is( scalar(@received_3), 0, "no message received from another connection reply-to");
    }


    $bus1->disconnect( blocking => 1 );
    $bus2->disconnect( blocking => 1 );
    $bus3->disconnect( blocking => 1 ) if $bus3->{is_connected};
}

sub test_05_queue_prefetch : Test(6) {
    my $self = shift;

    my $bus1 = Beekeeper::Bus::STOMP->new( %$bus_config );
    my $bus2 = Beekeeper::Bus::STOMP->new( %$bus_config );

    $bus1->connect( blocking => 1 );
    $bus2->connect( blocking => 1 );

    my ($cv, $tmr);
    my @received;

    $bus1->subscribe(
        destination     => '/queue/req.foo.bar',
        ack             => 'client', # manual ack
       'prefetch-count' => '1',
        on_receive_msg  => sub {
            my ($body, $headers) = @_;
            push @received, {
                bus     => 1,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

    $bus2->subscribe(
        destination     => '/queue/req.foo.bar',
        ack             => 'client', # manual ack
       'prefetch-count' => '1',
        on_receive_msg  => sub {
            my ($body, $headers) = @_;
            push @received, {
                bus     => 2,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;


    $bus1->send(
        destination => '/queue/req.foo.bar',
        body        => 'Hello',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received), 1, "received 1 message from queue");
    is( $received[0]->{body}, 'Hello', "got message");

    # $DEBUG && diag Dumper \@received;


    $bus1->send(
        destination => '/queue/req.foo.bar',
        body        => 'Hello',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received), 2, "received 1 more message from queue");
    is( $received[1]->{body}, 'Hello', "got message");

    # $DEBUG && diag Dumper \@received;


    # This one must be queued
    $bus1->send(
        destination => '/queue/req.foo.bar',
        body        => 'Hello',
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received), 2, "received no more messages until ACK");
 

    for my $n (0..1) {

        my %ack_headers = (
            'id'           => $received[$n]->{headers}->{'ack'},
            'message-id'   => $received[$n]->{headers}->{'message-id'},
            'subscription' => $received[$n]->{headers}->{'subscription'},
        );

        if ($received[$n]->{bus} == 1) {
            $bus1->ack(%ack_headers);
        }
        else {
            $bus2->ack(%ack_headers);
        }
    }

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    is( scalar(@received), 3, "received another message");

    # $DEBUG && diag Dumper \@received;

    for my $n (2..2) {

        my %ack_headers = (
            'id'           => $received[$n]->{headers}->{'ack'},
            'message-id'   => $received[$n]->{headers}->{'message-id'},
            'subscription' => $received[$n]->{headers}->{'subscription'},
        );

        if ($received[$n]->{bus} == 1) {
            $bus1->ack(%ack_headers);
        }
        else {
            $bus2->ack(%ack_headers);
        }
    }

    $bus1->disconnect( blocking => 1 );
    $bus2->disconnect( blocking => 1 );
}

sub test_06_queue_timeout : Test(2) {
    my $self = shift;

    return "ToyBroker does not honor expiration yet" if $self->using_toybroker;

    my $bus1 = Beekeeper::Bus::STOMP->new( %$bus_config );

    $bus1->connect( blocking => 1 );

    my ($cv, $tmr);
    my @received;

    $bus1->send(
        destination => '/queue/req.foo.bar',
        body        => 'Message A',
        expiration  => 100,
    );

    $bus1->send(
        destination => '/queue/req.foo.bar',
        body        => 'Message B',
        expiration  => 500,
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.2, cb => $cv); $cv->recv;

    $bus1->subscribe(
        destination     => '/queue/req.foo.bar',
        ack             => 'auto', # means none
        on_receive_msg  => sub {
            my ($body, $headers) = @_;
            push @received, {
                bus     => 1,
                headers => { %$headers },
                body    => $$body,
            };
        },
    );

    $cv = AnyEvent->condvar; $tmr = AnyEvent->timer( after => 0.1, cb => $cv); $cv->recv;

    # Message A should have expired
    is( scalar(@received), 1, "received only 1 message from queue");
    is( $received[0]->{body}, 'Message B', "got non expired message");
}

1;
