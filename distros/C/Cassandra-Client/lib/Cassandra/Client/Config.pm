package Cassandra::Client::Config;
use 5.010;
use strict;
use warnings;

sub new {
    my ($class, $config)= @_;

    my $self= bless {
        anyevent                => 0,
        contact_points          => undef,
        port                    => 9042,
        cql_version             => undef,
        keyspace                => undef,
        compression             => undef,
        default_consistency     => undef,
        max_page_size           => 5000,
        max_connections         => 2,
        timer_granularity       => 0.1,
        request_timeout         => 11,
        warmup                  => 0,
        throttler               => undef,
        throttler_config        => undef,
        max_concurrent_queries  => 1000,
        command_queue           => "Default",
        command_queue_config    => undef,
        tls                     => 0,
    }, $class;

    if (my $cp= $config->{contact_points}) {
        if (ref($cp) eq 'ARRAY') {
            @{$self->{contact_points}=[]}= @$cp;
        } else { die "contact_points must be an arrayref"; }
    } else { die "contact_points not specified"; }

    # Booleans
    for (qw/anyevent warmup tls/) {
        if (exists($config->{$_})) {
            $self->{$_}= !!$config->{$_};
        }
    }

    # Numbers
    for (qw/port timer_granularity request_timeout max_connections max_concurrent_queries/) {
        if (defined($config->{$_})) {
            $self->{$_}= 0+ $config->{$_};
        }
    }
    for (qw/max_page_size/) {
        if (exists($config->{$_})) {
            $self->{$_}= defined($config->{$_}) ? (0+ $config->{$_}) : undef;
        }
    }

    # Strings
    for (qw/cql_version keyspace compression default_consistency throttler/) {
        if (exists($config->{$_})) {
            $self->{$_}= defined($config->{$_}) ? "$config->{$_}" : undef;
        }
    }

    # Arbitrary hashes
    for (qw/throttler_config command_queue_config/) {
        if (exists($config->{$_})) {
            $self->{$_}= $config->{$_};
        }
    }

    $self->{username}= $config->{username};
    $self->{password}= $config->{password};

    return $self;
}

1;
