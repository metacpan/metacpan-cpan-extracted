package Cassandra::Client::Config;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Config::VERSION = '0.16';
use 5.010;
use strict;
use warnings;

use Ref::Util qw/is_plain_arrayref is_plain_coderef/;

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
        max_concurrent_queries  => 1000,
        tls                     => 0,

        throttler               => undef,
        command_queue           => undef,
        retry_policy            => undef,
        load_balancing_policy   => undef,
        protocol_version        => 4,

        stats_hook              => undef,
    }, $class;

    if (my $cp= $config->{contact_points}) {
        if (is_plain_arrayref($cp)) {
            @{$self->{contact_points}=[]}= @$cp;
        } else { die "contact_points must be an arrayref"; }
    } else { die "contact_points not specified"; }

    # Booleans
    for (qw/anyevent warmup tls/) {
        if (exists($config->{$_})) {
            $self->{$_}= !!$config->{$_};
        }
    }

    # Numbers, ignore undef
    for (qw/port timer_granularity request_timeout max_connections max_concurrent_queries/) {
        if (defined($config->{$_})) {
            $self->{$_}= 0+ $config->{$_};
        }
    }
    # Numbers, undef actually means undef
    for (qw/max_page_size/) {
        if (exists($config->{$_})) {
            $self->{$_}= defined($config->{$_}) ? (0+ $config->{$_}) : undef;
        }
    }

    # Strings
    for (qw/cql_version keyspace compression default_consistency/) {
        if (exists($config->{$_})) {
            $self->{$_}= defined($config->{$_}) ? "$config->{$_}" : undef;
        }
    }

    # Coderefs
    for (qw/stats_hook/) {
        if (defined($config->{$_})) {
            die "$_ must be a CODE reference" unless is_plain_coderef($config->{$_});
            $self->{$_}= $config->{$_};
        }
    }

    if (exists($config->{throttler})) {
        die "throttler must be a Cassandra::Client::Policy::Throttle::Default"
            unless $config->{throttler}->isa("Cassandra::Client::Policy::Throttle::Default");
        $self->{throttler}= $config->{throttler};
    }
    if (exists($config->{retry_policy})) {
        die "retry_policy must be a Cassandra::Client::Policy::Retry::Default"
            unless $config->{retry_policy}->isa("Cassandra::Client::Policy::Retry::Default");
        $self->{retry_policy}= $config->{retry_policy};
    }
    if (exists($config->{command_queue})) {
        die "command_queue must be a Cassandra::Client::Policy::Queue::Default"
            unless $config->{command_queue}->isa("Cassandra::Client::Policy::Queue::Default");
        $self->{command_queue}= $config->{command_queue};
    }
    if (exists($config->{load_balancing_policy})) {
        die "load_balancing_policy must be a Cassandra::Client::Policy::LoadBalancing::Default"
            unless $config->{load_balancing_policy}->isa("Cassandra::Client::Policy::LoadBalancing::Default");
        $self->{load_balancing_policy}= $config->{load_balancing_policy};
    }

    $self->{username}= $config->{username};
    $self->{password}= $config->{password};

    if (exists $config->{protocol_version}) {
        if ($config->{protocol_version} == 3 || $config->{protocol_version} == 4) {
            $self->{protocol_version}= 0+ $config->{protocol_version};
        } else {
            die "Invalid protocol_version: must be one of [3, 4]";
        }
    }

    return $self;
}

1;

__END__

=pod

=head1 NAME

Cassandra::Client::Config

=head1 VERSION

version 0.16

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
