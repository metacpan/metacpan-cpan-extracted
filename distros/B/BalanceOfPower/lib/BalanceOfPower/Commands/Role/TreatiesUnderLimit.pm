package BalanceOfPower::Commands::Role::TreatiesUnderLimit;
$BalanceOfPower::Commands::Role::TreatiesUnderLimit::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;

sub nations_under_treaty_limit
{
    my $self = shift;
    my @targets = @_;
    my @out = ();
    for(@targets)
    {
        my $nation_name = $_;
        my $n = $self->world->get_nation($nation_name);
        if($self->world->get_treaties_for_nation($n->name) < $n->treaty_limit)
        {
            push @out, $nation_name;
        }
    }
    return @out;
}

1;
