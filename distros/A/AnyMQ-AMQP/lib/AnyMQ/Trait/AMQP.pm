package AnyMQ::Trait::AMQP;
use Moose::Role;
use File::ShareDir;

use AnyEvent;
use AnyEvent::RabbitMQ;
use JSON;
use Try::Tiny;
use Carp qw(croak carp);

has host => (is => "ro", isa => "Str");
has port => (is => "ro", isa => "Int");
has user => (is => "ro", isa => "Str");
has pass => (is => "ro", isa => "Str");
has vhost => (is => "ro", isa => "Str");
has exchange => (is => "ro", isa => "Str");

has bind_mode => (is => "ro", isa => "Str", default => sub { 'exchange' });

has _rf => (is => "rw");
has _rf_channel => (is => "rw");
has _rf_queue => (is => "rw");

has cv => (is => "rw", isa => "AnyEvent::CondVar");

has on_ready => (is => "rw", isa => "CodeRef");

has _connected => (is => "rw", isa => "Bool");

sub default_amqp_spec { #this is to avoid loading coro
    my $dir = File::ShareDir::dist_dir("AnyEvent-RabbitMQ");
    return "$dir/fixed_amqp0-8.xml";
}

AnyEvent::RabbitMQ->load_xml_spec(default_amqp_spec());

sub BUILD {}; after 'BUILD' => sub {
    my $self = shift;

    my $cv = $self->cv(AE::cv);

    $self->connect($cv);
    my $cb; $cb = sub {
        my $msg = $_[0]->recv;
        if ( $msg eq 'init' ) {
            $self->_connected(1);
            $self->on_ready->() if $self->on_ready;
        }
        else {
            my $cv = AE::cv;
            $cv->cb($cb);
            $self->cv($cv);
            carp "Connection failed, retrying in 5 seconds.  Reason: ".$msg;
            my $w; $w = AnyEvent->timer(after => 5,
                                        cb => sub {
                                            undef $w;
                                            $self->connect($cv);
                                        });
        }
    };
    $cv->cb($cb);

    if (!$self->on_ready) {
        while ((my $msg = $self->cv->recv) ne 'init') {};
    }
};

sub connect {
    my $self = shift;
    my $cv = shift;

    my $rf = AnyEvent::RabbitMQ->new(timeout => 1, verbose => 0);
    $self->_rf($rf);

    # XXX: wrapped object with monadic method modifier
    # my $channel = run_monad { $rf->connect(....)->open_channel()->return }
    # my $queue = run_monad { $channel->declare_queue(....)->return }->method_frame->queue;
    # run_monad { $channel->consume( ....) }

    my $init = sub {
        my $channel = shift;
        $channel->declare_queue(
            exclusive => 1,
            on_success => sub {
                my $method = shift;
                my $queue = $method->method_frame->queue;
                $self->_rf_queue($queue);
                $channel->consume(queue => $queue,
                                  no_ack => 1,
                                  on_success => sub {
                                      $cv->send('init');
                                  },
                                  on_consume => $self->on_consume,
                                  on_failure => $cv,
                              );
            },
            on_failure => $cv,
        )
    };

    $rf->connect(
        (map { $_ => $self->$_ }
             qw(host port user pass vhost)),
        on_success => sub {
            $rf->open_channel(
                on_success => sub {
                    my $channel = shift;
                    $self->_rf_channel($channel);
                    $channel->qos();
                    return $init->($channel)
                        unless $self->exchange;

                    $channel->declare_exchange(
                        type => 'topic',
                        exchange => $self->exchange,
                        on_failure => $cv,
                        on_success => sub {
                            $init->($channel);
                        },
                    );
                },
                on_failure => $cv,
            );
        },
        on_close => sub {
            # XXX: try to reconnect and reinstantiate all topics
            warn "==> connection closed";
        },
        on_failure => $cv,
    );
}

sub on_consume {
    my $self = shift;
    sub {
        my $frame = shift;
        my $payload = $frame->{body}->payload;
        my $reply_to = $frame->{header}->reply_to;
        return if $reply_to && $reply_to eq $self->_rf_queue;
        my $topic = $frame->{deliver}->method_frame->routing_key;
        try { $self->topics->{$topic}->AnyMQ::Topic::publish(JSON::from_json($payload)) }
        catch { croak "failed to republsih on $topic: $_" };
    };
}

sub new_topic {
    my ($self, $opt) = @_;
    $opt = { name => $opt } unless ref $opt;
    AnyMQ::Topic->new_with_traits(
        traits => ['AMQP'],
        %$opt,
        bus  => $self );
}

sub DEMOLISH {}; after 'DEMOLISH' => sub {
    my $self = shift;
    my ($igd) = @_;
    return unless $self->_rf;
    return if $igd;
    my $q = AE::cv;
    $self->_rf->close( on_success => $q, on_failure => $q );
    $q->recv;
};

1;
