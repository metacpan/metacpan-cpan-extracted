package BalanceOfPower::Relations::Crisis;
$BalanceOfPower::Relations::Crisis::VERSION = '0.400115';
#DEPRECATED

use strict;
use v5.10;

use Moo;

has factor => (
    is => 'rw',
    default => 1
);

with 'BalanceOfPower::Relations::Role::Relation';

sub print 
{
    my $self = shift;
    return $self->node1 . " <-> " . $self->node2 . " (" . $self->factor . ")";
}

1;
