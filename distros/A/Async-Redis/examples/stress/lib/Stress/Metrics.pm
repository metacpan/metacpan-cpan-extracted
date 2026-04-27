package Stress::Metrics;
use strict;
use warnings;

use constant RESERVOIR_CAPACITY => 1024;

sub new {
    my ($class) = @_;
    return bless {
        ops          => {},
        latencies    => {},
        errors_typed => {},
    }, $class;
}

sub incr_op {
    my ($self, $op, $n) = @_;
    $self->{ops}{$op} += $n // 1;
    return;
}

sub record_latency {
    my ($self, $op, $sec) = @_;
    my $ms = $sec * 1000;
    my $r = $self->{latencies}{$op} //= {
        reservoir => [],
        count     => 0,
    };
    if (@{ $r->{reservoir} } < RESERVOIR_CAPACITY) {
        push @{ $r->{reservoir} }, $ms;
    } else {
        my $idx = int rand($r->{count} + 1);
        $r->{reservoir}[$idx] = $ms if $idx < RESERVOIR_CAPACITY;
    }
    $r->{count}++;
    return;
}

sub harvest {
    my ($self) = @_;
    my %throughput = %{ $self->{ops} };
    my %errors     = %{ $self->{errors_typed} };
    my %latency_ms;
    for my $op (keys %{ $self->{latencies} }) {
        my @sorted = sort { $a <=> $b } @{ $self->{latencies}{$op}{reservoir} };
        next unless @sorted;
        $latency_ms{$op} = {
            p50 => _percentile(\@sorted, 0.50),
            p95 => _percentile(\@sorted, 0.95),
            p99 => _percentile(\@sorted, 0.99),
        };
    }
    $self->{ops}          = {};
    $self->{latencies}    = {};
    $self->{errors_typed} = {};
    return {
        throughput   => \%throughput,
        latency_ms   => \%latency_ms,
        errors_typed => \%errors,
    };
}

sub _percentile {
    my ($sorted, $p) = @_;
    my $idx = int(@$sorted * $p);
    $idx = $#$sorted if $idx > $#$sorted;
    return $sorted->[$idx];
}

1;
