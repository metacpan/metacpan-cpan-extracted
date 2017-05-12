package AnyMQ::Trait::Pg;

# use 5.010;

use Any::Moose 'Role';

use AnyEvent::Pg 0.04;
use JSON;
use Try::Tiny;

has 'debug' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has 'dsn' => (
    is => 'ro',
    isa => 'Str',
    default => '',
);

has '_client' => (
    is => 'ro',
    isa => 'AnyEvent::Pg',
    lazy => 1, # need to construct client after all param attributes have been created
    builder => '_build_client',
    predicate => '_client_exists',
);

has 'on_connect' => (
    is => 'ro',
    isa => 'Maybe[CodeRef]',
);

has 'on_error' => (
    is => 'ro',
    isa => 'Maybe[CodeRef]',
);

has 'channels' => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
        'add_channel'  => 'push',
        'all_channels' => 'elements',
    },
);

has 'publish_queue' => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
        'publish_queue_push'    => 'push',
        'publish_queue_unshift' => 'unshift',
    },
);

has 'is_connected' => (
    is => 'rw',
    isa => 'Bool',
);

has '_json' => ( is => 'rw', lazy_build => 1, isa => 'JSON' );

has '_pg_query_watchers' => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
        '_pg_query_watcher_push' => 'push',
    }
);

sub BUILD {
    my ($self) = @_;
    
    # once everything is set up, we can construct and connect our client object
    $self->_client;
}

# JSON codec pack
sub _build__json {
    my ($self) = @_;
    return JSON->new->utf8;
}

sub _build_client {
    my ($self) = @_;

    my $dsn = $self->dsn;
    my $pg = AnyEvent::Pg->new(
        $dsn,
        on_connect       => sub { $self->_on_connect(@_) },
        on_connect_error => sub { $self->_on_connect_error(@_) },
        on_error         => sub { $self->_on_error(@_) },
        on_notify        => sub { $self->_on_notify(@_) },
    );

    return $pg;
}

sub listen {
    my ($self, $channel, %query_opts) = @_;

    $self->add_channel($channel);
    return unless $self->is_connected;
    
    $self->_push_listen($channel, %query_opts);
}

sub _push_listen {
    my ($self, $channel, %query_opts) = @_;
    return $self->_push_notif_command('LISTEN', $channel, %query_opts);
}

sub unlisten {
    my ($self, $channel, %query_opts) = @_;

    return $self->_push_notif_command('UNLISTEN', $channel, %query_opts);
}

# publishes notification with $payload on channel
sub notify {
    my ($self, @rest) = @_;
    my ($channel, $payload, %query_opts) = @rest;

    unless ($self->is_connected) {
        $self->publish_queue_push(\@rest);
        return;
    }
    
    my $query = 'NOTIFY "' . $self->_client->dbc->escapeString($channel) . '"';
    $query = join(',', $query, $self->_client->dbc->escapeLiteral($payload)) if $payload;
    warn $query if $self->debug;
    my $qw = $self->_client->push_query(query => $query, %query_opts);
    $self->_pg_query_watcher_push($qw);
}

# handles LISTEN/UNLISTEN
sub _push_notif_command {
    my ($self, $cmd, $channel, %opts) = @_;

    my $query = $cmd . ' "' . $self->_client->dbc->escapeString($channel) . '"';
    my $qw = $self->_client->push_query(
        query => $query,
        %opts
    );
    warn $query if $self->debug;
    $self->_pg_query_watcher_push($qw);
    return $qw;
}

sub encode_event {
    my ($self, $evt) = @_;

    return $evt unless ref $evt;

    # encode refs with JSON
    return $self->_json->encode($evt);
}

sub _on_connect {
    my $self = shift;

    $self->is_connected(1);

    # subscribe to channels
    if ($self->all_channels) {
        $self->_push_listen($_) for $self->all_channels;
    }
    
    # publish outstanding notifs
    my $pub_queue = $self->publish_queue;
    if ($pub_queue) {
        foreach my $evt (@$pub_queue) {
            $self->notify(@$evt);
        }
    }
    
    # time to call our connect callback
    $self->on_connect->($self, @_) if $self->on_connect;
}

sub _on_connect_error {
    my ($self, @rest) = @_;

    $self->is_connected(0);
    $self->_on_error(@rest);
}

sub _on_error {
    my $self = shift;
    my ($pg) = @_;

    my $err = $pg->dbc->errorMessage;

    if ($self->on_error) {
        $self->on_error->($self, $err);
    } else {
        warn "AnyMQ::Pg error: $err";
    }
}

sub _on_notify {
    my ($self, $pg, $channel, $pid, $payload) = @_;

    my $evt;
    # assume payload is JSON
    try {
        # try decoding from json
        $evt = $self->_json->decode($payload);
    } catch {
        # we'll make the event whatever raw data we got from the payload
        $evt = $payload;
    };

    # no payload at all
    $evt //= { 'name' => $channel };

    # notify listeners
    $self->topic($channel)->append_to_queues($evt);
}

sub new_topic {
    my ($self, $opt) = @_;

    # name of topic to subscribe to, passed in
    $opt = { name => $opt } unless ref $opt;

    # use our topic role
    AnyMQ::Topic->new_with_traits(
        %$opt,
        traits => [ 'Pg' ],
        bus => $self,
    );
}

sub DEMOLISH {}; after 'DEMOLISH' => sub {
    my ($self, $igd) = @_;

    return if $igd;

    $self->_client->destroy if $self->_client_exists;
};

1;
