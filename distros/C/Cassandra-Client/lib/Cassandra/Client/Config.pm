package Cassandra::Client::Config;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Config::VERSION = '0.17';
use 5.010;
use strict;
use warnings;

use Ref::Util qw/is_plain_arrayref is_plain_coderef is_blessed_ref/;
use Cassandra::Client::Policy::Auth::Password;

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
        default_idempotency     => 0,
        max_page_size           => 5000,
        max_connections         => 2,
        timer_granularity       => 0.1,
        request_timeout         => 11,
        warmup                  => 0,
        max_concurrent_queries  => 1000,
        tls                     => 0,
        protocol_version        => 4,

        throttler               => undef,
        command_queue           => undef,
        retry_policy            => undef,
        load_balancing_policy   => undef,
        authentication          => undef,

        stats_hook              => undef,
    }, $class;

    if (my $cp= $config->{contact_points}) {
        if (is_plain_arrayref($cp)) {
            @{$self->{contact_points}=[]}= @$cp;
        } else { die "contact_points must be an arrayref"; }
    } else { die "contact_points not specified"; }

    # Booleans
    for (qw/anyevent warmup tls default_idempotency/) {
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

    # Policies
    for (qw/throttler retry_policy command_queue load_balancing_policy authentication/) {
        if (exists($config->{$_})) {
            die "$_ must be a blessed reference implementing the correct API"
                unless is_blessed_ref($config->{$_});
            $self->{$_}= $config->{$_};
        }
    }

    if (exists($config->{username}) || exists($config->{password})) {
        $self->{authentication}= Cassandra::Client::Policy::Auth::Password->new(
            username => $config->{username},
            password => $config->{password},
        );
    }

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

version 0.17

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
