# ABSTRACT: Easy to use asynchronous AMQP client
use strict;
use warnings;
package AnyEvent::RabbitMQ::Simple;
our $AUTHORITY = 'cpan:AJGB';
$AnyEvent::RabbitMQ::Simple::VERSION = '0.02';
use AnyEvent;
use AnyEvent::RabbitMQ;
use Moo;

has 'host' => (
    is => 'ro',
    default => '127.0.0.1',
);

has 'port' => (
    is => 'ro',
    default => 5672,
);

has 'vhost' => (
    is => 'ro',
    default => '/',
);

has 'user' => (
    is => 'ro',
    default => 'guest'
);

has 'pass' => (
    is => 'ro',
    default => '',
);

has 'failure_cb' => (
    is => 'ro',
    required => 1,
);

has [qw( tls tune )] => (
    is => 'ro',
);

has $_ => (
    is => 'ro',
    predicate => "_has_$_",
) for qw(exchange exchanges queue queues bind_exchanges bind_queues);

has 'timeout' => (
    is => 'ro',
    default => 0,
);

has 'prefetch_count' => (
    is => 'ro',
    default => 0,
);

has 'confirm_publish' => (
    is => 'ro',
    default => 0,
);

has 'gen_queue' => (
    is => 'rw',
);

has 'verbose' => (
    is => 'ro',
    default => 0,
);

has '_guard' => (
    is => 'rw',
    default => sub { +{} },
);

sub _handle_error {
    my $self = shift;

    my $guard = $self->_guard;

    # cancel pending actions
    delete $guard->{flows};

    # exec failure callback
    $self->failure_cb->( @_ );

    # send undef
    $guard->{flow}->send();
}

sub connect {
    my ($self) = @_;
    my $guard = $self->_guard;
    my $cv = $guard->{cv} = AE::cv;
    my $flow = $guard->{flow} = AE::cv;
    $flow->begin(
        sub {
            $cv->send($guard->{channel});
        }
    );
    $guard->{conn} = AnyEvent::RabbitMQ->new(verbose=>$self->verbose)->load_xml_spec()->connect(
        host       => $self->host,
        port       => $self->port,
        user       => $self->user,
        pass       => $self->pass,
        vhost      => $self->vhost,
        timeout    => $self->timeout,
        tls        => $self->tls,
        tune       => $self->tune,
        on_success => sub {
            my $conn = shift;
            $self->_open_channel($conn);
            $flow->end;
        },
        on_failure => sub { $self->_handle_error( 'ConnectOnFailure', '', @_ ) },
        on_read_failure => sub { $self->_handle_error( 'ConnectOnReadFailure', '', @_ ) },
        on_return => sub { $self->_handle_error( 'ConnectOnReturn', '', @_ ) },
        on_close => sub { $self->_handle_error( 'ConnectOnClose', '', @_ ) },
    );

    return $cv;
}

sub disconnect {
    my ($self) = @_;

    delete $self->_guard->{conn};
}

sub _open_channel {
    my ($self, $conn) = @_;
    $self->_guard->{flow}->begin;
    $conn->open_channel(
        on_success => sub {
            my $channel = shift;
            $self->_guard->{channel} = $channel;

            my $cv_dec_ex = $self->_guard->{flows}->{cv_dec_ex} = AE::cv;
            my $cv_dec_q = $self->_guard->{flows}->{cv_dec_q} = AE::cv;
            my $cv_bind_ex = $self->_guard->{flows}->{cv_bind_ex} = AE::cv;
            my $cv_bind_q = $self->_guard->{flows}->{cv_bind_q} = AE::cv;
            my $cv_confirm_channel = $self->_guard->{flows}->{cv_confirm_channel} = AE::cv;
            my $cv_qos_channel = $self->_guard->{flows}->{cv_qos_channel} = AE::cv;

            $cv_dec_ex->cb(
                sub {
                    my $done = shift->recv;
                    $self->_declare_queues($cv_dec_q) if $done;
                }
            );
            $cv_dec_q->cb(
                sub {
                    my $done = shift->recv;
                    $self->_bind_exchanges($cv_bind_ex) if $done;
                }
            );
            $cv_bind_ex->cb(
                sub {
                    my $done = shift->recv;
                    $self->_bind_queues($cv_bind_q) if $done;
                }
            );
            $cv_bind_q->cb(
                sub {
                    my $done = shift->recv;
                    $self->_confirm_channel( $cv_confirm_channel ) if $done;
                }
            );
            $cv_confirm_channel->cb(
                sub {
                    my $done = shift->recv;
                    $self->_qos_channel( $cv_qos_channel ) if $done;
                }
            );
            $cv_qos_channel->cb(
                sub {
                    my $done = shift->recv;
                    $self->_guard->{flow}->end;
                }
            );

            $self->_declare_exchanges($cv_dec_ex);

        },
        on_failure => sub { $self->_handle_error( 'OpenChannelOnFailure', '', @_ ) },
        on_return  => sub { $self->_handle_error( 'OpenChannelOnReturn', '', @_ ) },
        on_close  => sub { $self->_handle_error( 'OpenChannelOnClose', '', @_ ) },
    );
}

sub _confirm_channel {
    my ($self, $cv) = @_;
    if ( $self->confirm_publish ) {
        $self->_guard->{flow}->begin;
        $self->_guard->{channel}->confirm(
            on_success => sub {
                $self->_guard->{flow}->end;
                $cv->send(1);
            },
            on_failure => sub {
                $self->_handle_error( 'ConfirmChannelOnFailure', '', @_ );
                $cv->send;
            },
        );
    } else {
        $cv->send(1);
    }
}

sub _qos_channel {
    my ($self, $cv) = @_;
    if ( $self->prefetch_count ) {
        $self->_guard->{flow}->begin;
        $self->_guard->{channel}->qos(
            prefetch_count => $self->prefetch_count,
            on_success => sub {
                $self->_guard->{flow}->end;
                $cv->send(1);
            },
            on_failure => sub {
                $self->_handle_error( 'QosChannelOnFailure', '', @_ );
                $cv->send;
            },
        );
    } else {
        $cv->send(1);
    }
}

sub _declare_exchanges {
    my ($self, $cv) = @_;

    $cv->begin( sub { shift->send(1) } );

    if ( $self->_has_exchange ) {
        $self->_declare_exchange($cv, $self->exchange);
    }
    if ( $self->_has_exchanges ) {
        my @exchanges = @{ $self->exchanges || [] };
        for ( my $i = 0; $i < scalar @exchanges; $i += 2 ) {
            my $name = $exchanges[$i];
            my $opts = $exchanges[$i+1];

            # another name
            if ( defined $opts && ref $opts ne 'HASH' ) {
                $self->_declare_exchange($cv, $name);
                $self->_declare_exchange($cv, $opts);
            } else {
                $self->_declare_exchange($cv, $name, %{ $opts || {} });
            }
        }
    }
    $cv->end;
}

sub _declare_exchange {
    my ($self, $cv, $name, %options) = @_;

    $self->_guard->{flow}->begin;
    $cv->begin;
    $self->_guard->{channel}->declare_exchange(
        %options,
        exchange    => $name,
        on_success  => sub {
            $self->_guard->{flow}->end;
            $cv->end;
        },
        on_failure => sub {
            $self->_handle_error( 'DeclareExchangeOnFailure', "exchange:$name", @_ );
            $cv->end;
        }
    );
}

sub _declare_queues {
    my ($self, $cv) = @_;

    $cv->begin( sub { shift->send(1) } );

    if ( $self->_has_queue ) {
        $self->_declare_queue($cv, $self->queue);
    }
    if ( $self->_has_queues ) {
        my @queues = @{ $self->queues || [] };
        for ( my $i = 0; $i < scalar @queues; $i += 2 ) {
            my $name = $queues[$i];
            my $opts = $queues[$i+1];

            # another name
            if ( defined $opts && ref $opts ne 'HASH' ) {
                $self->_declare_queue($cv, $name);
                $self->_declare_queue($cv, $opts);
            } else {
                $self->_declare_queue($cv, $name, %{ $opts || {} });
            }
        }
    } else {
        $self->_declare_queue($cv, '');
    }
    $cv->end;
}

sub _declare_queue {
    my ($self, $cv, $name, %options) = @_;

    $self->_guard->{flow}->begin;
    $cv->begin;
    $self->_guard->{channel}->declare_queue(
        %options,
        queue       => $name || '',
        on_success  => sub {
            my $method = shift;
            if ( ! $name ) {
                $self->gen_queue( $method->method_frame->queue );
            }
            $self->_guard->{flow}->end;
            $cv->end;
        },
        on_failure => sub {
            $self->_handle_error( 'DeclareQueueOnFailure', "queue:$name", @_ );
            $cv->send;
        },
    );
}

sub _make_pair {
    my ($pairs) = @_;

    my @list;
    while (my ($l,$r) = each %{ $pairs || {} }) {
        push @list, $l, ref $r eq 'ARRAY' ? $r : [ $r, undef ];
    }

    return @list;
}

sub _bind_exchanges {
    my ($self, $cv) = @_;

    $cv->begin( sub { shift->send(1) } );

    if ( $self->_has_bind_exchanges ) {
        my @pairs;
        my $bind_exchanges = $self->bind_exchanges;
        if ( ref $bind_exchanges eq 'ARRAY' ) {
            for my $pair ( @{ $bind_exchanges || [] } ) {
                push @pairs, _make_pair($pair);
            }
        } elsif ( ref $bind_exchanges eq 'HASH' ) {
            push @pairs, _make_pair($bind_exchanges);
        }

        for ( my $i = 0; $i < scalar @pairs; $i += 2 ) {
            my $destination = $pairs[$i];
            my ($source, $routing_key) = @{ $pairs[$i+1] };
            my %opts;
            if ( $routing_key ) {
                $opts{routing_key} = $routing_key;
            }

            $self->_bind_exchange($cv, $source, $destination, %opts);
        }
    }
    $cv->end;
}

sub _bind_exchange {
    my ($self, $cv, $source, $destination, %options ) = @_;

    $self->_guard->{flow}->begin;
    $cv->begin;
    $self->_guard->{channel}->bind_exchange(
        %options,
        source      => $source,
        destination => $destination,
        on_success  => sub {
            $self->_guard->{flow}->end;
            $cv->end;
        },
        on_failure => sub {
            $self->_handle_error( 'BindExchangeOnFailure', "source:$source, destination:$destination", @_ );
            $cv->send;
        },
    );
}

sub _bind_queues {
    my ($self, $cv) = @_;

    $cv->begin( sub { shift->send(1) } );

    if ( $self->_has_bind_queues ) {
        my @pairs;
        my $bind_queues = $self->bind_queues;
        if ( ref $bind_queues eq 'ARRAY' ) {
            for my $pair ( @{ $bind_queues || [] } ) {
                push @pairs, _make_pair($pair);
            }
        } elsif ( ref $bind_queues eq 'HASH' ) {
            push @pairs, _make_pair($bind_queues);
        }

        for ( my $i = 0; $i < scalar @pairs; $i += 2 ) {
            my $queue = $pairs[$i];
            my ($exchange, $routing_key) = @{ $pairs[$i+1] };
            my %opts;
            if ( $routing_key ) {
                $opts{routing_key} = $routing_key;
            }

            $self->_bind_queue($cv, $queue, $exchange, %opts);
        }
    }
    $cv->end;
}

sub _bind_queue {
    my ($self, $cv, $queue, $exchange, %options) = @_;

    $self->_guard->{flow}->begin;
    $cv->begin;
    $self->_guard->{channel}->bind_queue(
        %options,
        queue       => $queue,
        exchange    => $exchange,
        on_success  => sub {
            $self->_guard->{flow}->end;
            $cv->end;
        },
        on_failure => sub {
            $self->_handle_error( 'BindQueueOnFailure', "queue:$queue, exchange:$exchange", @_ );
            $cv->send;
        },
    );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::RabbitMQ::Simple - Easy to use asynchronous AMQP client

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use strict;
    use warnings;
    use AnyEvent::RabbitMQ::Simple;

    # create main loop
    my $loop = AE::cv;

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        host       => '127.0.0.1',
        port       => 5672,
        user       => 'username',
        pass       => 'password',
        vhost      => '/',
        timeout    => 1,
        tls        => 0,
        verbose    => 0,
        confirm_publish => 1,
        prefetch_count => 10,

        failure_cb => sub {
            my ($event, $details, $why) = @_;
            if ( ref $why ) {
                my $method_frame = $why->method_frame;
                $why = $method_frame->reply_text;
            }
            $loop->croak("[ERROR] $event($details): $why" );
        },

        # routing layout
        # [========== exchanges ===================] [===== queues ==============]
        # [             (type/routing key)         ] [        (routing key) ]
        #  logger ----------> stats -------------->   stats-logs
        #   |(fanout)           (direct)                (mail.stats)
        #   |  |
        #   |  | \----------> errors ------------->   ftp-error-logs
        #   |  |              | (topic:*.error.#)       (ftp.error.#)
        #   |  |              |
        #   |  |              \------------------->   mail-error-logs
        #   |  |                                        (mail.error.#)
        #   |  |
        #   |   \-----------> info --------------->   info-logs
        #   |                   (topic:*.info.#)        (*.info.#)
        #   |
        #    \------------------------------------>   debug-queue


        # declare exchanges
        exchanges => [
            'logger' => {
                durable => 0,
                type => 'fanout',
                internal => 0,
                auto_delete => 1,
            },
            'stats' => {
                durable => 0,
                type => 'direct',
                internal => 0,
                auto_delete => 1,
            },
            'errors' => {
                durable => 0,
                type => 'topic',
                internal => 0,
                auto_delete => 1,
            },
            'info' => {
                durable => 0,
                type => 'topic',
                internal => 0,
                auto_delete => 1,
            },
        ],

        # declare queues
        queues => [
            'debug-queue' => {
                durable => 0,
                auto_delete => 1,
            },
            'stats-logs' => {
                durable => 0,
                auto_delete => 1,
            },
            'ftp-error-logs' => {
                durable => 0,
                auto_delete => 1,
            },
            'mail-error-logs' => {
                durable => 0,
                auto_delete => 1,
            },
            'info-logs' => {
                durable => 0,
                auto_delete => 1,
            },
        ],

        # exchange to exchange bindings, with optional routing key
        bind_exchanges => [
            { 'stats'   =>   'logger'                 },
            { 'errors'  => [ 'logger', '*.error.#' ]  },
            { 'info'    => [ 'logger', '*.info.#'  ]  },
        ],


        # queue to exchange bindings, with optional routing key
        bind_queues => [
            { 'debug-queue'     =>   'logger'                   },
            { 'ftp-error-logs'  => [ 'errors', 'ftp.error.#'  ] },
            { 'mail-error-logs' => [ 'errors', 'mail.error.#' ] },
            { 'info-logs'       => [ 'info',   'info.#'       ] },
            { 'stats-logs'      => [ 'stats',  'mail.stats'   ] },
        ],

    );

    # publisher timer
    my $t;

    # connect and set up channel
    my $conn = $rmq->connect();
    $conn->cb(
        sub {
            print "waiting for channel..\n";
            my $channel = shift->recv or $loop->croak("Could not open channel");

            print "************* consuming\n";
            for my $q ( qw( debug-queue ftp-error-logs mail-error-logs info-logs stats-logs ) ) {
                consume($channel, $q);
            }

            print "************* starting publishing\n";
            $t = AE::timer 0, 1.0, sub { publish($channel, "message prepared at ". scalar(localtime) ) };
        }
    );

    # consumes from requested queue
    sub consume {
        my ($channel, $queue) = @_;

        my $consumer_tag;

        $channel->consume(
            queue => $queue,
            no_ack => 0,
            on_success => sub {
                my $frame = shift;
                $consumer_tag = $frame->method_frame->consumer_tag;
                print "************* consuming from $queue with $consumer_tag\n";
            },
            on_consume => sub {
                my $res = shift;
                my $body = $res->{body}->payload;
                print "+++++++++++++ consumed($queue): $body\n";
                $channel->ack(
                    delivery_tag => $res->{deliver}->method_frame->delivery_tag
                );
            },
            on_failure => sub {
                print "************* failed to consume($queue)\n";
            }
        );
    }

    # randomly generates routing key and message body
    sub publish {
        my ($channel, $msg) = @_;

        unless ( $channel->is_open ) {
            warn "Cannot publish, channel closed";
            return;
        }

        my @system = qw( mail ftp web );
        my @levels = qw( debug info error stats );

        my $routing_key = $system[rand @system] .'.'. $levels[ rand @levels ];

        $msg = sprintf("[%s] %s", uc($routing_key), $msg);
        print "\n------- publishing: $msg\n";
        $channel->publish(
            routing_key => $routing_key,
            exchange => 'logger',
            body => $msg,
            on_ack => sub {
                print "------- published: $msg\n";
            },
            on_return => sub {
                print "************* failed to publish: $msg\n";
            }
        );
    }

    # wait forever or die on error
    my $done = $loop->recv;

=head1 DESCRIPTION

This module is meant to simplify the process of setting up the RabbitMQ channel,
so you can start publishing and/or consuming messages without chaining
C<on_success> callbacks.

=head1 METHODS

=head2 new

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        ...
    );

Returns configured object using following parameters:

=head3 host

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        host => '127.0.0.1', # default
        ...
    );

Host IP.

=head3 port

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        port => 5672, # default
        ...
    );

Port number.

=head3 vhost

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        vhost => '/', # default
        ...
    );

Virtual host namespace.

=head3 user

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        user => 'guest', # default
        ...
    );

User name.

=head3 pass

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        pass => 'guest', # default
        ...
    );

Password.

=head3 tune

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        tune => {
            heartbeat => $connection_heartbeat,
            channel_max => $max_channel_number,
            frame_max => $max_frame_size
        },
        ...
    );

Optional connection tuning options.

=head3 timeout

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        timeout => 0, # default
        ...
    );

Connection timeout.

=head3 tls

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        tls => 0, # default
        ...
    );

Use TLS.

=head3 verbose

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        verbose => 0, # default
        ...
    );

Turn on protocol debug.

=head3 confirm_publish

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        confirm_publish => 0, # default
        ...
    );

Turn on confirm mode on channel. If set it enables the C<on_ack> callback of
channel's C<publish> method.

=head3 prefetch_count

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        prefetch_count => 0, # default
        ...
    );

Specify the number of prefetched messages when consuming from the channel.

=head3 exchange

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        exchange => 'name_of_exchange',
        ...
    );

Optional name of exchange to declare with its default configuration options.

See L<AnyEvent::RabbitMQ::Channel/"declare_exchange (%args)"> for details.

=head3 exchanges

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        exchanges => [
            'name_of_exchange' => {
                durable => 1,
                type => 'fanout',
                ... # other exchange configuration parameters
            },
            ...
        ],
        ...
    );

Optional list of exchanges to declare with their configuration options.

See L<AnyEvent::RabbitMQ::Channel/"declare_exchange (%args)"> for details.

=head3 queue

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        queue => 'name_of_queue',
        ...
    );

Optional name of queue to declare with its default configuration options.

If no queues were declared or empty name has been specified a unique
generated queue name will be available:

    my $gen_queue = $rmq->gen_queue;

See L<AnyEvent::RabbitMQ::Channel/"declare_queue"> for details.

=head3 queues

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        queues => [
            'name_of_queue' => {
                durable => 1,
                no_ack => 0,
                ... # other queue configuration parameters
            },
            ...
        ],
        ...
    );

Optional list of queues to declare with their configuration options.

See L<AnyEvent::RabbitMQ::Channel/"declare_queue"> for details.

=head3 bind_exchanges

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        bind_exchanges => [
            # without routing key
            { 'destination1' => 'source' },

            # with routing key
            { 'destination2'  => [ 'source', 'routing_key' ]  },
            ...
        ],
        ...
    );

Optional list of exchange-to-exchange bindings.

See L<AnyEvent::RabbitMQ::Channel/"bind_exchange"> for details.

=head3 bind_queues

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        bind_queues => [
            # without routing key
            { 'queue1' => 'exchange' },

            # with routing key
            { 'queue2'  => [ 'exchange', 'routing_key' ]  },
            ...
        ],
        ...
    );

Optional list of queue-to-exchange bindings.

See L<AnyEvent::RabbitMQ::Channel/"bind_queue"> for details.

=head3 failure_cb

    my $rmq = AnyEvent::RabbitMQ::Simple->new(
        failure_cb => sub {
            my ($event, $details, $why) = @_;
            if ( ref $why ) {
                my $method_frame = $why->method_frame;
                $why = $method_frame->reply_text;
            }
            $loop->croak("[ERROR] $event($details): $why" );
        },
        ...
    );

Required catch-all error handling callback. The value of C<$event> is one of:

=over 4

=item ConnectOnFailure

=item ConnectOnReadFailure

=item ConnectOnReturn

=item ConnectOnClose

=item OpenChannelOnFailure

=item OpenChannelOnReturn

=item OpenChannelOnClose

=item DeclareExchangeOnFailure

Value of C<$details> has following format: C<name:$name_of_exchange>.

=item BindExchangeOnFailure

Value of C<$details> has following format:
C<source:$name_of_source_exchange, destination:$name_of_destination_exchange>.

=item DeclareQueueOnFailure

Value of C<$details> has following format: C<name:$name_of_queue>.

=item BindQueueOnFailure

Value of C<$details> has following format:
C<queue:$name_of_queue, exchange:$name_of_exchange>.

=item ConfirmChannelOnFailure

=item QosChannelOnFailure

=back

=head2 connect

    my $conn = $rmq->connect();
    $conn->cb(
        sub {
            my $channel = shift->recv or $loop->croak("Could not open channel");

            ...
        }
    );

Returns the AnyEvent condvar that returns L<AnyEvent::RabbitMQ::Channel> object
after all the configuration steps were successful.

=head2 disconnect

    $rmq->disconnect();

Disconnects from RabbitMQ server.

=head2 gen_queue

    my $gen_queue = $rmq->gen_queue;

Name of the generated queue if no queues were declared (or queue with empty name
has been specified).

=head1 SEE ALSO

=over 4

=item * L<AnyEvent::RabbitMQ>

=item * L<https://www.rabbitmq.com/>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
