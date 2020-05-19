package Daemonise::Plugin::RabbitMQ;

use 5.010;
use Mouse::Role;
use experimental 'smartmatch';

# ABSTRACT: Daemonise RabbitMQ plugin

use Net::AMQP::RabbitMQ 2.300000;
use Carp;
use JSON;
use Try::Tiny;


our $js = JSON->new;
$js->utf8;
$js->allow_blessed;
$js->convert_blessed;
$js->allow_nonref;


has 'is_worker' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { 0 },
);


has 'rabbit_host' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'localhost' },
);


has 'rabbit_port' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 5672 },
);


has 'rabbit_user' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'guest' },
);


has 'rabbit_pass' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'guest' },
);


has 'rabbit_vhost' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { '/' },
);


has 'rabbit_exchange' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'amq.direct' },
);


has 'rabbit_channel' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { int(rand(63999)) + 1 },
);


has 'rabbit_consumer_tag' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { '' },
);


has 'last_delivery_tag' => (
    is  => 'rw',
    isa => 'Math::UInt64',
);


has 'admin_queue' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { 1 },
);


has 'reply_queue' => (
    is        => 'rw',
    lazy      => 1,
    clearer   => 'no_reply',
    predicate => 'wants_reply',
    default   => sub { undef },
);


has 'correlation_id' => (
    is      => 'rw',
    isa     => 'Str',
    clearer => 'no_correlation_id',
);


has 'mq' => (
    is      => 'rw',
    isa     => 'Net::AMQP::RabbitMQ',
    lazy    => 1,
    default => sub { Net::AMQP::RabbitMQ->new },
);


after 'configure' => sub {
    my ($self, $reconfig) = @_;

    $self->log("configuring RabbitMQ plugin") if $self->debug;

    if ($reconfig) {
        $self->log("closing channel " . $self->rabbit_channel) if $self->debug;
        $self->mq->channel_close($self->rabbit_channel);
        $self->log("disconnecting from rabbitMQ server: " . $self->rabbit_host)
            if $self->debug;
        $self->mq->disconnect;
        $self->mq(Net::AMQP::RabbitMQ->new);
    }

    $self->_setup_rabbit_connection;

    return;
};


sub dont_reply {
    my ($self) = @_;

    $self->no_reply;
    $self->no_correlation_id;

    return;
}


sub queue {
    my ($self, $queue, $hash, $reply_to, $exchange) = @_;

    my $rpc;
    $rpc = 1 if defined wantarray;

    unless (defined $hash) {
        $self->log("message hash missing");
        return;
    }

    unless ($queue) {
        $self->log("target queue missing");
        return;
    }

    # we want the receiver to reply to same priority queue
    $reply_to .= '.' . $hash->{meta}->{priority}
        if defined $reply_to
        and exists $hash->{meta}->{priority}
        and $hash->{meta}->{priority} =~ m/^(high|low)$/;

    my $tag;
    my $reply_channel = $self->rabbit_channel + 1;
    if ($rpc) {
        try {
            $self->mq->channel_open($reply_channel);
        }
        catch {
            warn "Could not open channel on first try! >>" . $@ . "<<";
            $self->_setup_rabbit_connection;
            $self->mq->channel_open($reply_channel);
        };
        $self->log("opened channel $reply_channel for reply") if $self->debug;

        $reply_to =
            $self->mq->queue_declare($reply_channel, '',
            { durable => 0, auto_delete => 1, exclusive => 1 });
        $self->log("declared reply queue $reply_to") if $self->debug;

        $tag = $self->mq->consume($reply_channel, $reply_to);
        $self->log("got consumer tag: " . $tag) if $self->debug;
    }

    my $props = { content_type => 'application/json' };
    $props->{reply_to} = $reply_to if defined $reply_to;

    # If the queue we're sending to is Daemonise's reply_queue, then this is
    # probably a response for an RPC message. Include the correlation_id
    if (defined $self->reply_queue
        and $queue eq $self->reply_queue)
    {
        $props->{correlation_id} = $self->correlation_id
            if defined $self->correlation_id;
    }
    else {
        # HACK: priorities should be implemented using rabbitMQ properties in the
        #       future, however for now we just rename the queue and hope...
        $queue .= '.' . $hash->{meta}->{priority}
            if ref $hash eq 'HASH'
            and exists $hash->{meta}
            and exists $hash->{meta}->{priority}
            and $hash->{meta}->{priority} =~ m/^(high|low)$/;
    }

    my $options;
    $options->{exchange} = $exchange if $exchange;

    $self->log("sending message to '$queue' via channel "
            . $self->rabbit_channel
            . " using "
            . ($exchange ? $exchange : 'amq.direct') . ": "
            . $self->dump($hash))
        if $self->debug;

    my $json = $js->encode($hash);
    utf8::encode($json);

    try {
        $self->mq->publish($self->rabbit_channel,
            $queue, $json, $options, $props);
    }
    catch {
        $self->log(
            "sending message to '$queue' failed on first try! >>" . $@ . "<<");
        $self->_setup_rabbit_connection;
        $self->mq->publish($self->rabbit_channel,
            $queue, $json, $options, $props);
    };

    if ($rpc) {
        my $msg = $self->dequeue($tag);

        $self->mq->channel_close($reply_channel);
        $self->log("closed reply channel $reply_channel") if $self->debug;

        return $msg;
    }

    return;
}


sub dequeue {
    my ($self, $tag) = @_;

    # clear reply_queue if this not an RPC response
    $self->dont_reply unless defined $tag;

    my $frame;
    my $msg;
    while (1) {
        try {
            $frame = $self->mq->recv();
        }
        catch {
            warn "receiving message failed on first try! >>" . $@ . "<<";
            $self->_setup_rabbit_connection;
            $frame = $self->mq->recv();
        };

        if ($frame) {
            if (defined $tag) {
                unless (($frame->{consumer_tag} eq $tag)
                    or ($frame->{consumer_tag} eq $self->rabbit_consumer_tag))
                {
                    $self->log("LOSING MESSAGE: " . $self->dump($frame));
                }
            }

            # ACK all admin messages no matter what
            $self->mq->ack($self->rabbit_channel, $frame->{delivery_tag})
                if ($frame->{routing_key} =~ m/^admin/);

            # decode
            eval { $msg = $js->decode($frame->{body} || '{}'); };
            if ($@) {
                $self->log("JSON parsing error: $@");
                $msg = {};
            }

            $self->log("received message body: " . $self->dump($msg))
                if $self->debug;

            last unless ($frame->{routing_key} =~ m/^admin/);

            if (   ($frame->{routing_key} eq 'admin')
                or ($frame->{routing_key} eq 'admin.' . $self->hostname))
            {
                given ($msg->{command} || 'stop') {
                    when ('configure') {
                        $self->log("reconfiguring");
                        $self->configure('reconfig');
                    }
                    when ('stop') {
                        my $name = $self->name;
                        if (grep { $_ eq $name }
                            @{ $msg->{daemons} || [$name] })
                        {
                            $self->stop;
                        }
                    }
                }
            }
        }
    }

    # store delivery tag to ack later
    $self->last_delivery_tag($frame->{delivery_tag}) unless $tag;
    $self->reply_queue($frame->{props}->{reply_to})
        if exists $frame->{props}->{reply_to};
    $self->correlation_id($frame->{props}->{correlation_id})
        if exists $frame->{props}->{correlation_id};

    return $msg;
}


sub ack {
    my ($self) = @_;

    $self->log("acknowledging AMQP message") if $self->debug;
    $self->mq->ack($self->rabbit_channel, $self->last_delivery_tag);

    return;
}

sub _setup_rabbit_connection {
    my $self = shift;

    if (ref($self->config->{rabbitmq}) eq 'HASH') {
        foreach
            my $conf_key ('user', 'pass', 'host', 'port', 'vhost', 'exchange')
        {
            my $attr = "rabbit_" . $conf_key;
            $self->$attr($self->config->{rabbitmq}->{$conf_key})
                if defined $self->config->{rabbitmq}->{$conf_key};
        }
    }

    eval {
        $self->mq->connect(
            $self->rabbit_host, {
                user     => $self->rabbit_user,
                password => $self->rabbit_pass,
                port     => $self->rabbit_port,
                vhost    => $self->rabbit_vhost,
            });
    };
    my $err = $@;

    if ($err) {
        confess "Could not connect to the RabbitMQ server '"
            . $self->rabbit_host
            . "': $err\n";
    }

    $self->mq->channel_open($self->rabbit_channel);
    $self->log("opened channel " . $self->rabbit_channel) if $self->debug;

    return unless $self->is_worker;

    $self->log("preparing worker queue") if $self->debug;

    $self->mq->basic_qos($self->rabbit_channel, { prefetch_count => 1 });
    $self->mq->queue_declare($self->rabbit_channel, $self->name,
        { durable => 1, auto_delete => 0 });
    $self->mq->queue_bind(
        $self->rabbit_channel,  $self->name,
        $self->rabbit_exchange, $self->name,
    );
    $self->rabbit_consumer_tag(
        $self->mq->consume($self->rabbit_channel, $self->name, { no_ack => 0 })
    );
    $self->log("got consumer tag: " . $self->rabbit_consumer_tag)
        if $self->debug;

    # setup admin queue per worker using z.queue.host.pid
    # and bind to fanout exchange
    if ($self->admin_queue) {
        my $admin_queue = join('.', 'z', $self->name, $self->hostname, $$);

        $self->log("declaring and binding admin queue " . $admin_queue)
            if $self->debug;

        $self->mq->queue_declare($self->rabbit_channel, $admin_queue,
            { durable => 0, auto_delete => 1 });
        $self->mq->queue_bind($self->rabbit_channel, $admin_queue, 'amq.fanout',
            'admin');
        $self->mq->queue_bind($self->rabbit_channel, $admin_queue, 'amq.fanout',
            'admin.' . $self->hostname);
        $self->mq->consume($self->rabbit_channel, $admin_queue,
            { no_ack => 0 });
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Daemonise::Plugin::RabbitMQ - Daemonise RabbitMQ plugin

=head1 VERSION

version 2.13

=head1 SYNOPSIS

    use Daemonise;

    my $d = Daemonise->new();

    # this is the rabbitMQ queue name we eventually create and subscribe to
    $d->name("queue_name");

    $d->debug(1);
    $d->foreground(1) if $d->debug;
    $d->config_file('/path/to/some.conf');

    $d->load_plugin('RabbitMQ');

    $d->is_worker(1); # make it create its own queue
    $d->configure;

    # fetch next message from our subscribed queue
    $msg = $d->dequeue;

    # send message to some_queue and don't wait (rabbitMQ publish)
    # $msg can be anything that encodes into JSON
    $d->queue('some_queue', $msg);

    # send message and wait for response (rabbitMQ RPC)
    my $response = $d->queue('some_queue', $msg);

    # worker that wants a reply from us, not necessarily from an RPC call
    my $worker = $d->reply_queue;

    # does NOT reply to caller, no matter what, usually not what you want
    $d->dont_reply;

    # at last, acknowledge message as processed
    $d->ack;

=head1 ATTRIBUTES

=head2 is_worker

=head2 rabbit_host

=head2 rabbit_port

=head2 rabbit_user

=head2 rabbit_pass

=head2 rabbit_vhost

=head2 rabbit_exchange

=head2 rabbit_channel

=head2 rabbit_consumer_tag

=head2 last_delivery_tag

=head2 admin_queue

=head2 reply_queue

=head2 correlation_id

=head2 mq

=head1 SUBROUTINES/METHODS provided

=head2 configure

=head2 dont_reply

=head2 queue

=head2 dequeue

=head2 ack

=head1 AUTHOR

Lenz Gschwendtner <norbu09@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lenz Gschwendtner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
