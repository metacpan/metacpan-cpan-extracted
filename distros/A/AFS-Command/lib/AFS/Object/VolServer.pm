#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Object::VolServer;

use strict;

our @ISA = qw(AFS::Object);
our $VERSION = '1.99';

sub getPartitionNames {
    my $self = shift;
    return unless ref $self->{_partitions};
    return keys %{$self->{_partitions}};
}

sub getPartitions {
    my $self = shift;
    return unless ref $self->{_partitions};
    return values %{$self->{_partitions}};
}

sub getPartition {
    my $self = shift;
    my $partname = shift;
    return unless ref $self->{_partitions};
    return $self->{_partitions}->{$partname};
}

sub _addPartition {
    my $self = shift;
    my $partition = shift;
    unless ( ref $partition && $partition->isa("AFS::Object::Partition") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::Partition object");
    }
    return $self->{_partitions}->{$partition->partition()} = $partition;
}

sub getTransactions {
    my $self = shift;
    return unless ref $self->{_volumes};
    return values %{$self->{_volumes}};
}

sub getVolumes {
    my $self = shift;
    return unless ref $self->{_volumes};
    return keys %{$self->{_volumes}};
}

sub getTransactionByVolume {
    my $self = shift;
    my $volume = shift;
    return unless ref $self->{_volumes};
    return $self->{_volumes}->{$volume};
}

sub _addTransaction {

    my $self = shift;
    my $transaction = shift;

    unless ( ref $transaction && $transaction->isa("AFS::Object::Transaction") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::Transaction object");
    }

    unless ( $transaction->volume() ) {
	$self->_Croak("Invalid AFS::Object::Transaction object: has no 'volume' attribute");
    }

    $self->{_volumes}->{$transaction->volume()} = $transaction;

}

1;
