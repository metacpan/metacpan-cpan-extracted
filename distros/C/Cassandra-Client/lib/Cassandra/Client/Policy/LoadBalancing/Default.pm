package Cassandra::Client::Policy::LoadBalancing::Default;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Policy::LoadBalancing::Default::VERSION = '0.16';
use 5.010;
use strict;
use warnings;
use List::Util 'shuffle';
use Time::HiRes qw/time/;

sub new {
    my ($class, %args)= @_;
    return bless {
        datacenter => undef,
        nodes => {},
        local_nodes => {},
        connected => {},
        candidates => [],
        try_times => {},
    }, $class;
}

sub get_distance {
    my ($self, $peer)= @_;
    my $node= $self->{nodes}{$peer};
    if (!$node) {
        warn 'Being asked about a distance for a node we don\'t know';
        return 'ignored';
    }

    if ($self->{local_nodes}{$peer}) {
        return 'local';
    }
    return 'remote';
}

sub on_new_node {
    my ($self, $node)= @_;

    my $peer= $node->{peer};
    if ($self->{nodes}{$peer}) {
        warn 'BUG: "new" node is already known!';
    }

    $self->{nodes}{$peer}= $node;
    if (!$self->{datacenter} || $node->{data_center} eq $self->{datacenter}) {
        $self->{local_nodes}{$peer}= $node;
    }
}

sub on_removed_node {
    my ($self, $node)= @_;

    my $peer= $node->{peer};
    if (!$self->{nodes}{$peer}) {
        warn 'BUG: "removed" node wasn\'t there!';
    }

    delete $self->{nodes}{$peer};
    delete $self->{local_nodes}{$peer};
}

sub get_next_candidate {
    my ($self)= @_;
    my $candidates= $self->{candidates};
    while (my $maybe= shift @$candidates) {
        if ($self->{local_nodes}{$maybe} && !$self->{connected}{$maybe} && $self->check_backoff($maybe)) {
            return $maybe;
        }
    }
    @$candidates= shuffle grep { !$self->{connected}{$_} && $self->check_backoff($_) } keys %{$self->{local_nodes}};
    return shift @$candidates;
}

my @all_backoff= map { $_ * (rand()*.4 + 0.8) } (1, 5, 20, 60, 180, 600);
sub check_backoff {
    my ($self, $peer)= @_;
    my $times= $self->{try_times}{$peer};
    return 1 unless $times;

    my $count= 0+@$times;
    $count= @all_backoff if $count > @all_backoff;
    my $backoff= $all_backoff[$count-1];

    if (time() - $times->[-1] < $backoff) {
        return;
    }

    return 1;
}

sub set_connecting {
    my ($self, $peer)= @_;
    $self->{connected}{$peer}= 1;
    push @{$self->{try_times}{$peer} ||= []}, time;
}

sub set_connected {
    my ($self, $peer)= @_;
    warn "BUG" unless $self->{connected}{$peer};
    delete $self->{try_times}{$peer};
}

sub set_disconnected {
    my ($self, $peer)= @_;
    delete $self->{connected}{$peer};
}

sub known_node_count {
    my ($self)= @_;
    return (0+ keys %{$self->{local_nodes}});
}

1;

__END__

=pod

=head1 NAME

Cassandra::Client::Policy::LoadBalancing::Default

=head1 VERSION

version 0.16

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
