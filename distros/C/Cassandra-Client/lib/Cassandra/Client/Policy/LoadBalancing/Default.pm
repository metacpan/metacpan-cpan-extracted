package Cassandra::Client::Policy::LoadBalancing::Default;
use 5.010;
use strict;
use warnings;
use List::Util 'shuffle';

sub new {
    my ($class, %args)= @_;
    return bless {
        datacenter => undef,
        nodes => {},
        local_nodes => {},
        connected => {},
        candidates => [],
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
        if ($self->{local_nodes}{$maybe} && !$self->{connected}{$maybe}) {
            return $maybe;
        }
    }
    @$candidates= shuffle grep { !$self->{connected}{$_} } keys %{$self->{local_nodes}};
    return shift @$candidates;
}

sub set_connected {
    my ($self, $peer)= @_;
    $self->{connected}{$peer}= 1;
}

sub set_disconnected {
    my ($self, $peer)= @_;
    delete $self->{connected}{$peer};
}

1;
