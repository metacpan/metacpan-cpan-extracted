package BalanceOfPower::Nation::Role::Shareholder;
$BalanceOfPower::Nation::Role::Shareholder::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;

has available_stocks => (
    is => 'rw',
    default => 0
);

sub get_stocks
{
    my $self = shift;
    my $q = shift;
    if($q <= $self->available_stocks)
    {
        $self->available_stocks($self->available_stocks - $q);
    }
    else
    {
        return 0;
    }
}

1;
