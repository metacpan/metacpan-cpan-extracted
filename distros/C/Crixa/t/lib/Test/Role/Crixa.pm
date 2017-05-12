package Test::Role::Crixa;

use strict;
use warnings;
use namespace::autoclean;

use Crixa;
use Crixa::Message;
use Math::BigInt ();
use Math::UInt64 qw( uint64 );
use Test::Fatal qw( exception );
use Test::More;
use Try::Tiny;

use Moose::Role;

requires qw(
    _build_crixa
);

has crixa => (
    is      => 'ro',
    isa     => 'Crixa',
    lazy    => 1,
    builder => '_build_crixa',
);

# Using test_setup/teardown would be much more complicated, as we'd have to
# temporarily store the exchange & queue in an object attribute and then clear
# them.
my @test_methods = qw(
    test_handle_message
    test_check_for_message
    test_wait_for_message
    test_message_count
    test_consume
    test_consume_with_timeout
    test_partial_consume
);
around \@test_methods => sub {
    my $orig = shift;
    my $self = shift;

    my $exchange = $self->_channel()->exchange(
        name => $self->_fq_name('order'),
    );
    my $queue = $exchange->queue(
        name         => $self->_fq_name('new-orders'),
        routing_keys => ['order.new']
    );

    try {
        $self->$orig( $exchange, $queue );
    }
    catch {
        die $_;
    }
    finally {
        $queue->delete( { if_unused => 0, if_empty => 0 } );
        $exchange->delete( { if_unused => 0 } );
    };
};

sub test_handle_message {
    my $self     = shift;
    my $exchange = shift;
    my $queue    = shift;

    for my $i ( 1 .. 2 ) {
        my $body = 'body-' . $i;
        $exchange->publish( { routing_key => 'order.new', body => $body } );
        $self->_wait_for_min_messages( $queue, 1 );

        $self->_with_alarm(
            sub {
                $queue->handle_message(
                    sub {
                        is(
                            $_->body(), $body,
                            "expected body for message $i"
                        );
                    }
                );
            }
        );
    }
}

sub test_check_for_message {
    my $self     = shift;
    my $exchange = shift;
    my $queue    = shift;

    for my $i ( 1 .. 2 ) {
        my $body = 'body-' . $i;
        $exchange->publish( { routing_key => 'order.new', body => $body } );
        $self->_wait_for_min_messages( $queue, 1 );

        my $msg = $queue->check_for_message();
        is( $msg->body(), $body, "expected body for message $i" );
    }
}

sub test_wait_for_message {
    my $self     = shift;
    my $exchange = shift;
    my $queue    = shift;

    for my $i ( 1 .. 2 ) {
        my $body = 'body-' . $i;
        $exchange->publish( { routing_key => 'order.new', body => $body } );
        $self->_wait_for_min_messages( $queue, 1 );

        my $msg;
        $self->_with_alarm( sub { $msg = $queue->wait_for_message() } );
        is( $msg->body(), $body, "expected body for message $i" );
    }
}

sub test_message_count {
    my $self     = shift;
    my $exchange = shift;
    my $queue    = shift;

    for my $i ( 1 .. 2 ) {
        my $body = 'body-' . $i;
        $exchange->publish( { routing_key => 'order.new', body => $body } );
        $self->_wait_for_min_messages( $queue, $i );

        is( $queue->message_count(), $i, "message_count == $i" );
    }
}

sub test_consume {
    my $self     = shift;
    my $exchange = shift;
    my $queue    = shift;

    for my $i ( 1 .. 4 ) {
        $exchange->publish(
            { routing_key => 'order.new', body => 'body-' . $i } );
    }

    $self->_wait_for_min_messages( $queue, 4 );

    my @bodies;
    $self->_with_alarm(
        sub {
            $queue->consume(
                sub {
                    my $msg = shift;
                    push @bodies, $msg->body();
                    return @bodies != 4;
                }
            );
        }
    );

    is_deeply(
        [ sort @bodies ],
        [qw( body-1 body-2 body-3 body-4 )],
        'got all expected bodies via consume interface'
    );
}

# We are testing that the ->consume loop will continue when
# Net::AMQP::RabbitMQ->recv returns undef because of a timeout.
sub test_consume_with_timeout {
    my $self     = shift;
    my $exchange = shift;
    my $queue    = shift;

    my $published = 0;

    my @bodies;
    $self->_with_alarm(
        sub {
            $queue->consume(
                sub {
                    my $msg = shift;

                    # This ensures that we'll get called at least once with
                    # undef.
                    unless ( $published++ ) {
                        for my $i ( 1 .. 4 ) {
                            $exchange->publish(
                                {
                                    routing_key => 'order.new',
                                    body        => 'body-' . $i
                                }
                            );
                        }
                    }

                    return 1 unless $msg;

                    push @bodies, $msg->body();
                    return @bodies != 4;
                },
                timeout => 1,
            );
        },
    );

    is_deeply(
        [ sort @bodies ],
        [qw( body-1 body-2 body-3 body-4 )],
        'got all expected bodies via consume interface'
    );
}

sub test_partial_consume {
    my $self     = shift;
    my $exchange = shift;
    my $queue    = shift;

    for my $i ( 1 .. 4 ) {
        $exchange->publish(
            { routing_key => 'order.new', body => 'body-' . $i } );
    }

    $self->_wait_for_min_messages( $queue, 4 );

    my @bodies;
    $self->_with_alarm(
        sub {
            $queue->consume(
                sub {
                    my $msg = shift;
                    push @bodies, $msg->body();
                    return @bodies != 3;
                }
            );
        }
    );

    is(
        scalar @bodies,
        3,
        'got 3 message bodies via consume'
    );

    $self->_with_alarm(
        sub {
            $queue->consume(
                sub {
                    my $msg = shift;
                    push @bodies, $msg->body();
                    return @bodies != 4;
                }
            );
        }
    );

    is_deeply(
        [ sort @bodies ],
        [qw( body-1 body-2 body-3 body-4 )],
        'got all expected bodies via consume interface'
    );
}

sub test_channels {
    my $self = shift;

    my $channel = $self->crixa()->new_channel();

    my $first_id = $channel->id();
    like( $channel->id(), qr/^\d+$/, 'channel id is numeric' );
    isnt(
        $self->crixa()->new_channel()->id(),
        $channel->id(),
        'Crixa->new_channel returns a new channel'
    );

    my ( $exchange, $queue );
    try {
        $exchange = $channel->exchange( name => $self->_fq_name('foo') );
        is(
            $exchange->channel()->id(), $channel->id(),
            '$channel->exchange() returns an exchange attached to the channel it is called on'
        );

        $queue = $exchange->queue(
            name         => $self->_fq_name('foo'),
            routing_keys => ['foo']
        );
        is(
            $queue->channel->id, $channel->id,
            '$channel->queue() returns a queue attached to the channel it is called on'
        );
    }
    catch {
        die $_;
    }
    finally {
        $queue->delete( { if_unused => 0, if_empty => 0 } )
            if $queue;
        $exchange->delete( { if_unused => 0 } )
            if $exchange;
    };
}

sub test_message_constructor_delivery_tag_constraint {
    my $self = shift;

    for my $tag ( 1, '3132', uint64(1), Math::BigInt->bone, ) {
        is(
            exception {
                Crixa::Message->new(
                    channel       => $self->_channel,
                    body          => q{},
                    props         => {},
                    redelivered   => 0,
                    routing_key   => q{},
                    exchange      => q{},
                    message_count => 1,
                    delivery_tag  => $tag,
                    )
            },
            undef,
            sprintf(
                'no exception thrown in message constructor with delivery_tag of %s (%s)',
                $tag, ref $tag || 'scalar'
            )
        );
    }

}

sub _wait_for_min_messages {
    my $self      = shift;
    my $queue     = shift;
    my $min_count = shift;

    my $desc = "queue has at least $min_count message"
        . (
        $min_count == 1
        ? q{}
        : 's'
        );

    try {
        local $SIG{ALRM}
            = sub { die "waited 5 seconds and did not finish\n" };
        alarm 5;
        sleep 1 while $queue->message_count() < $min_count;
        alarm 0;
        pass($desc);
    }
    catch {
        alarm 0;
        warn $_;
        die $_ unless $_ =~ /waited \d+ seconds and did not finish/;
        fail($desc);
    };
}

sub _with_alarm {
    my $self = shift;
    my $cb   = shift;
    my $wait = shift || 10;

    try {
        local $SIG{ALRM}
            = sub { die "waited $wait seconds and did not finish\n" };
        alarm $wait;
        $cb->();
        alarm 0;
        pass('executed callback without alarm firing');
    }
    catch {
        alarm 0;
        warn $_;
        die $_ unless $_ =~ /waited \d+ seconds and did not finish/;
        fail('executed callback without alarm firing');
    };
}

sub _channel {
    return $_[0]->crixa()->new_channel();
}

{
    my $i = 0;

    sub _fq_name {
        return "crixa-test-$$-" . $_[1] . q{-} . $i++;
    }
}

1;
