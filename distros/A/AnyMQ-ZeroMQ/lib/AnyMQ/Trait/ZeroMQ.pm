package AnyMQ::Trait::ZeroMQ;

use Any::Moose 'Role';

use AnyEvent::ZeroMQ;
use AnyEvent::ZeroMQ::Publish;
use AnyEvent::ZeroMQ::Subscribe;
use AnyMQ::Topic::Trait::ZeroMQ;
use Carp qw/croak/;
use JSON;

has 'publish_address'   => ( is => 'rw', isa => 'Str' );
has 'subscribe_address' => ( is => 'rw', isa => 'Str' );

has '_zmq_sub' => ( is => 'rw', lazy_build => 1, isa => 'AnyEvent::ZeroMQ::Subscribe' );
has '_zmq_pub' => ( is => 'rw', lazy_build => 1, isa => 'AnyEvent::ZeroMQ::Publish' );
has '_zmq_context' => ( is => 'rw', lazy_build => 1, isa => 'ZeroMQ::Raw::Context' );
has '_zmq_json' => ( is => 'rw', lazy_build => 1, isa => 'JSON' );

# topic => [ callbacks ]
has 'subscriptions' => (
    traits     => ['Hash'],
    is         => 'ro',
    isa        => 'HashRef[ArrayRef[CodeRef]]',
    default    => sub { {} },
    handles    => {
        subscription_topics => 'keys',
    },
);        

sub _build__zmq_json {
    my ($self) = @_;
    return JSON->new->utf8;
}

sub _build__zmq_context {
    my ($self) = @_;

    my $c = ZeroMQ::Raw::Context->new( threads => 10 );
    return $c;
}

sub _build__zmq_sub {
    my ($self) = @_;

    my $address = $self->subscribe_address
        or croak 'subscribe_address must be defined to publish messages';

    my $sub = AnyEvent::ZeroMQ::Subscribe->new(
        context => $self->_zmq_context,
        connect => $address,
    );

    $sub->on_read(sub { $self->read_event(@_) });

    return $sub;
}

sub _build__zmq_pub {
    my ($self) = @_;

    my $address = $self->publish_address
        or croak 'publish_address must be defined to publish messages';

    my $pub = AnyEvent::ZeroMQ::Publish->new(
        context => $self->_zmq_context,
        connect => $address,
    );

    return $pub;
}

# called when we read some data
sub read_event {
    my ($self, $subscription, $json) = @_;

    my $event = $self->_zmq_json->decode($json);

    unless ($event) {
        warn "Got invalid JSON: $json";
        return;
    }

    my $topic = $event->{type};
    unless ($topic) {
        warn "Got event with no topic type\n";
    }

    # call event handler callbacks
    my $cbs = $self->subscriptions->{$topic};

    unless ($cbs && @$cbs) {
        #warn "Got event $topic but no callbacks found\n";
        return;
    }
    
    foreach my $cb (@$cbs) {
        $cb->($event);
    }
}

# calls $cb when we receive a $topic event
# returns ref that can be passed to unsubscribe()
sub subscribe {
    my ($self, $topic, $cb) = @_;

    # make sure subscriber bus exists
    $self->_zmq_sub;
    
    # undef or '' means "all topics"
    $topic ||= '';

    $self->subscriptions->{$topic} ||= [];
    my $cbs = $self->subscriptions->{$topic};

    push @$cbs, $cb;

    $self->update_topic_subscriptions;

    # for now just use $cb as ref, should generate some unique
    # id in the future
    my $ref = $cb;
    return $ref;
}

# this controls what events we are subscribed to in ZMQ
sub update_topic_subscriptions {
    my ($self) = @_;

    my @topics = $self->subscription_topics;
    
    # update list of topics we are subscribed to
    # FIXME: use trait::topics
    # $self->_zmq_sub->topics(\@topics);
}

sub unsubscribe {
    my ($self, $topic, $ref) = @_;

    $self->subscriptions->{$topic} ||= [];
    my $cbs = $self->subscriptions->{$topic};
    $cbs = [ grep { $_ != $ref } @$cbs ];

    $self->update_topic_subscriptions;
}

sub new_topic {
    my ($self, $opt) = @_;
    
    $opt = { name => $opt } unless ref $opt;

    return AnyMQ::Topic->new_with_traits(
        traits => [ 'ZeroMQ' ],
        %$opt,
        bus => $self,
    );
}

sub DEMOLISH {}; after 'DEMOLISH' => sub {
    my $self = shift;
    my ($igd) = @_;

    return if $igd;

    # cleanup
};

1;
