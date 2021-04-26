package Beekeeper::Worker::Util::SharedCache;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Beekeeper::Worker::Util::SharedCache - Locally mirrored shared cache

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use Beekeeper::Worker::Util 'shared_cache'
  
  my $c = $self->shared_cache(
      id      => "mycache",
      max_age => 300,
      persist => 1,
  );
  
  $c->set( $key => $value );
  $c->get( $key );
  $c->delete( $key );
  $c->touch( $key );

=head1 DESCRIPTION

This module implements a locally mirrored shared cache: each worker keeps a
copy of all cached data, and all copies are synced through message bus.

Access operations are essentially free, as data is held locally. But changes 
are expensive as they need to be propagated to every worker, and memory usage
is high due to data cloning.

Keep in mind that retrieved data may be stale due to latency in changes 
propagation through the bus (which involves two network operations).

Even if you are using this cache for small data sets that do not change very
often, please consider if a distributed memory cache like Redis or such (or 
even a plain DB) is a better alternative.

=cut

use Beekeeper::Worker ':log';
use AnyEvent;
use JSON::XS;
use Fcntl qw(:DEFAULT :flock);
use Scalar::Util 'weaken';
use Carp;


sub new {
    my ($class, %args) = @_;

    my $worker = $args{'worker'};
    my $id     = $args{'id'};
    my $uid    = "$$-" . int(rand(90000000)+10000000);

    my $self = {
        id        => $id,
        uid       => $uid,
        resolver  => $args{'resolver'},
        on_update => $args{'on_update'},
        persist   => $args{'persist'},
        max_age   => $args{'max_age'},
        refresh   => $args{'refresh'},
        synced    => 0,
        data      => {},
        vers      => {},
        time      => {},
        _BUS      => undef,
        _CLUSTER  => undef,
    };

    bless $self, $class;

    $self->_load_state if $self->{persist};

    $self->_connect_to_all_brokers($worker);

    AnyEvent->now_update;

    if ($self->{max_age}) {
        my $Self = $self;
        $self->{gc_timer} = AnyEvent->timer(
            after    => $self->{max_age} * rand() + 60,
            interval => $self->{max_age},
            cb       => sub { $Self->_gc },
        );
    }

    if ($self->{refresh}) {
        my $Self = $self;
        $self->{refresh_timer} = AnyEvent->timer(
            after    => $self->{refresh} * rand() + 60,
            interval => $self->{refresh},
            cb       => sub { $Self->_send_sync_request },
        );
    }

    return $self;
}

sub _connect_to_all_brokers {
    my ($self, $worker) = @_;
    weaken($self);

    #TODO: using multiple shared_cache from the same worker will cause multiple cluster connections

    my $worker_bus = $worker->{_BUS};
    my $cluster_config = Beekeeper::Config->get_cluster_config( bus_id => $worker_bus->bus_id );

    my $cluster = $self->{_CLUSTER} = [];

    foreach my $config (@$cluster_config) {

        my $bus_id = $config->{'bus-id'};

        if ($bus_id eq $worker_bus->bus_id) {
            # Already connected to our own bus
            $self->_setup_sync_listeners($worker_bus);
            $self->_send_sync_request($worker_bus);
            $self->{_BUS} = $worker_bus;
            weaken($self->{_BUS});
            next;
        }

        my $bus; $bus = Beekeeper::Bus::STOMP->new( 
            %$config,
            bus_id     => $bus_id,
            timeout    => 300,
            on_connect => sub {
                # Setup
                log_debug "Connected to $bus_id";
                $self->_setup_sync_listeners($bus);
                $self->_accept_sync_requests($bus) if $self->{synced};
            },
            on_error => sub {
                # Reconnect
                my $errmsg = $_[0] || ""; $errmsg =~ s/\s+/ /sg;
                log_error "Connection to $bus_id failed: $errmsg";
                my $delay = $self->{connect_err}->{$bus_id}++;
                $self->{reconnect_tmr}->{$bus_id} = AnyEvent->timer(
                    after => ($delay < 10 ? $delay * 3 : 30),
                    cb    => sub { $bus->connect },
                );
            },
        );

        push @$cluster, $bus;

        $bus->connect;
    }
}

sub _setup_sync_listeners {
    my ($self, $bus) = @_;
    weaken($self);

    my $cache_id  = $self->{id};
    my $uid       = $self->{uid};
    my $local_bus = $bus->{cluster};

    $bus->subscribe(
        destination    => "/topic/msg.$local_bus._sync.$cache_id.set",
        on_receive_msg => sub {
            my ($body_ref, $msg_headers) = @_;

            my $entry = decode_json($$body_ref);

            $self->_merge($entry);
        }
    );

    $bus->subscribe(
        destination    => "/temp-queue/reply-$uid",
        on_receive_msg => sub {
            my ($body_ref, $msg_headers) = @_;

            my $dump = decode_json($$body_ref);

            $self->_merge_dump($dump);

            $self->_sync_completed(1);
        }
    );
}

sub _send_sync_request {
    my ($self, $bus) = @_;
    weaken($self);

    # Do not send more than one sync request at the time
    return if $self->{_sync_timeout};

    my $cache_id  = $self->{id};
    my $uid       = $self->{uid};
    my $local_bus = $bus->{cluster};

    $bus->send(
        destination => "/queue/req.$local_bus._sync.$cache_id.dump",
       'reply-to'   => "/temp-queue/reply-$uid",
        body        => "",
    );

    # When a fresh cluster is started nobody will answer, and determining which
    # worker have the best data set is a complex task when persistence and
    # clustering is involved. So just let the older workers act as masters
    my $timeout = 20 + rand();

    if ($self->{persist}) {
        # Give precedence to workers with bigger data sets
        my $size = keys %{$self->{data}};
        $timeout += 20 / (1 + log($size + 1));
    }

    # Ensure that timeout is set properly when the event loop was blocked
    AnyEvent->now_update;

    $self->{_sync_timeout} = AnyEvent->timer(
        after => $timeout,
        cb    => sub { $self->_sync_completed(0) },
    );
}

sub _sync_completed {
    my ($self, $success) = @_;

    delete $self->{_sync_timeout};

    return if $self->{synced};

    # On a fresh cluster, the first worker to timeout the sync request
    # will act as a master and relpy all sync requests remaining
    log_debug( $success ? "Sync completed" : "Acting as master" );

    $self->{synced} = 1;

    foreach my $bus ( @{$self->{_CLUSTER}} ) {

        # Connections to other buses could have failed or be in progress
        next unless $bus->{is_connected};

        $self->_accept_sync_requests($bus);
    }
}

sub _accept_sync_requests {
    my ($self, $bus) = @_;
    weaken($self);
    weaken($bus);

    my $cache_id  = $self->{id};
    my $uid       = $self->{uid};
    my $bus_id    = $bus->{bus_id};
    my $local_bus = $bus->{cluster};

    log_debug "Accepting $cache_id sync requests from $local_bus";

    $bus->subscribe(
        destination     => "/queue/req.$local_bus._sync.$cache_id.dump",
        ack             => 'client', # manual ack
       'prefetch-count' => '1',
        on_receive_msg  => sub {
            my ($body_ref, $msg_headers) = @_;

            my $dump = encode_json( $self->dump );

            $bus->send(
                destination => $msg_headers->{'reply-to'},
                body        => \$dump,
            );

            $bus->ack(
                id           => $msg_headers->{'ack'},
               'message-id'  => $msg_headers->{'message-id'},
                subscription => $msg_headers->{'subscription'}, 
            );
        }
    );
}

my $_now = 0;

sub set {
    my ($self, $key, $value) = @_;
    weaken($self);

    croak "Key value is undefined" unless (defined $key);

    my $old = $self->{data}->{$key};

    $self->{data}->{$key} = $value;
    $self->{vers}->{$key}++;
    $self->{time}->{$key} = Time::HiRes::time();

    my $json = encode_json([
        $key,
        $value,
        $self->{vers}->{$key},
        $self->{time}->{$key},
        $self->{uid},
    ]);

    $self->{on_update}->($key, $value, $old) if $self->{on_update};

    # Notify all workers in every cluster about the change
    my @cluster = grep { $_->{is_connected} } @{$self->{_CLUSTER}};

    unshift @cluster, $self->{_BUS};

    foreach my $bus (@cluster) {
        my $local_bus = $bus->{cluster};
        my $cache_id = $self->{id};

        $bus->send(
            destination => "/topic/msg.$local_bus._sync.$cache_id.set",
            body        => \$json,
        );
    }

    unless (defined $value) {
        # Postpone delete because it is necessary to keep the versioning 
        # of this modification until it is propagated to all workers

        # Ensure that timer is set properly when the event loop was blocked
        if ($_now != time) { $_now = time; AnyEvent->now_update }

        $self->{_destroy}->{$key} = AnyEvent->timer( after => 60, cb => sub {
            delete $self->{_destroy}->{$key};
            delete $self->{data}->{$key};
            delete $self->{vers}->{$key};
            delete $self->{time}->{$key};
        });
    }

    return 1;
}

sub get {
    my ($self, $key) = @_;

    $self->{data}->{$key};
}

sub delete {
    my ($self, $key) = @_;

    $self->set( $key => undef );
}

sub raw_data {
    my $self = shift;

    $self->{data};
}

sub _merge {
    my ($self, $entry) = @_;

    my ($key, $value, $version, $time, $uid) = @$entry;

    # Discard updates sent by myself
    return if (defined $uid && $uid eq $self->{uid});

    if ($version > ($self->{vers}->{$key} || 0)) {

        # Received a fresher value for the entry
        my $old = $self->{data}->{$key};

        $self->{data}->{$key} = $value;
        $self->{vers}->{$key} = $version;
        $self->{time}->{$key} = $time;

        $self->{on_update}->($key, $value, $old) if $self->{on_update};
    }
    elsif ($version < $self->{vers}->{$key}) {

        # Received a stale value (we have a newest version)
        return;
    }
    else {

        # Version conflict, default resolution is to keep newest value
        my $resolver = $self->{resolver} || sub {
            return $_[0]->{time} > $_[1]->{time} ? $_[0] : $_[1];
        };

        my $keep = $resolver->(
            {   # Mine
                data => $self->{data}->{$key},
                vers => $self->{vers}->{$key},
                time => $self->{time}->{$key},
            },
            {   # Theirs
                data => $value,
                vers => $version,
                time => $time,
            },
        );

        my $old = $self->{data}->{$key};

        $self->{data}->{$key} = $keep->{data};
        $self->{vers}->{$key} = $keep->{vers};
        $self->{time}->{$key} = $keep->{time};

        $self->{on_update}->($key, $keep->{data}, $old) if $self->{on_update};
    }

    unless (defined $self->{data}->{$key}) {
        # Postpone delete because it is necessary to keep the versioning 
        # of this modification until it is propagated to all workers

        # Ensure that timer is set properly when the event loop was blocked
        if ($_now != time) { $_now = time; AnyEvent->now_update }

        $self->{_destroy}->{$key} = AnyEvent->timer( after => 60, cb => sub {
            delete $self->{_destroy}->{$key};
            delete $self->{data}->{$key};
            delete $self->{vers}->{$key};
            delete $self->{time}->{$key};
        });
    }
}

sub dump {
    my $self = shift;

    my @dump;

    foreach my $key (keys %{$self->{data}}) {
        push @dump, [
            $key,
            $self->{data}->{$key},
            $self->{vers}->{$key},
            $self->{time}->{$key},
        ];
    }

    return {
        uid   => $self->{uid},
        time  => Time::HiRes::time(),
        dump  => \@dump,
    };
}

sub _merge_dump {
    my ($self, $dump) = @_;

    # Discard dumps sent by myself
    return if ($dump->{uid} eq $self->{uid});

    foreach my $entry (@{$dump->{dump}}) {
        $self->_merge($entry);
    }
}

sub touch {
    my ($self, $key) = @_;

    return unless defined $self->{data}->{$key};

    croak "No max_age specified (gc is disabled)" unless $self->{max_age};

    my $age = time() - $self->{time}->{$key};

    return unless ( $age > $self->{max_age} * 0.3);
    return unless ( $age < $self->{max_age} * 1.3);

    # Set to current value but without increasing version
    $self->{vers}->{$key}--;

    $self->set( $key => $self->{data}->{$key} );
}

sub _gc {
    my $self = shift;

    my $min_time = time() - $self->{max_age} * 1.3;

    foreach my $key (keys %{$self->{data}}) {

        next unless ( $self->{time}->{$key} < $min_time );
        next unless ( defined $self->{data}->{$key} );

        $self->delete( $key );
    }
}

sub _save_state {
    my $self = shift;

    return unless ($self->{synced});

    my $id = $self->{id};
    my $tmp_file = "/tmp/beekeeper-cache-$id.dump";

    # Avoid stampede when several workers are exiting simultaneously
    return if (-e $tmp_file && (stat($tmp_file))[9] == time());

    # Lock file because several workers may try to write simultaneously to it
    sysopen(my $fh, $tmp_file, O_RDWR|O_CREAT) or return;
    flock($fh, LOCK_EX | LOCK_NB) or return;
    truncate($fh, 0) or return;

    print $fh encode_json( $self->dump );

    close($fh);
}

sub _load_state {
    my $self = shift;

    my $id = $self->{id};
    my $tmp_file = "/tmp/beekeeper-cache-$id.dump";
    return unless (-e $tmp_file);

    # Do not load stale dumps
    return if ($self->{max_age} && (stat($tmp_file))[9] < time() - $self->{max_age});

    local($/);
    open(my $fh, '<', $tmp_file) or die "Couldn't read $tmp_file: $!";
    my $data = <$fh>;
    close($fh);

    local $@;
    my $dump = eval { decode_json($data) };
    return if $@;

    my $min_time = $self->{max_age} ? time() - $self->{max_age} : undef;

    foreach my $entry (@{$dump->{dump}}) {
        next if ($min_time && $entry->[3] < $min_time);
        $self->_merge($entry);
    }
}

sub disconnect {
    my $self = shift;

    $self->_save_state if $self->{persist};

    foreach my $bus (@{$self->{_CLUSTER}}) {

        next unless ($bus->{is_connected});
        $bus->disconnect( blocking => 1 );
    }
}

sub DESTROY {
    my $self = shift;

    #TODO: $self contains a circular reference
    $self->disconnect;
}

1;

=encoding utf8

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
