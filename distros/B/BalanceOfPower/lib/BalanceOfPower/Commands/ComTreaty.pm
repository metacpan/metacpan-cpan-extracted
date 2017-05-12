package BalanceOfPower::Commands::ComTreaty;
$BalanceOfPower::Commands::ComTreaty::VERSION = '0.400115';
use Moo;

use BalanceOfPower::Utils qw( prev_turn );

extends 'BalanceOfPower::Commands::TargetRoute';
with 'BalanceOfPower::Commands::Role::TreatiesUnderLimit';

sub get_available_targets
{
    my $self = shift;
    my @targets = $self->SUPER::get_available_targets();
    my $nation = $self->actor;
    @targets = grep {! $self->world->exists_treaty($nation, $_) } @targets;
    @targets = grep {! $self->world->diplomacy_status($nation, $_) ne 'HATE' } @targets;
    return $self->nations_under_treaty_limit(@targets);
}

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    my $prev_year = prev_turn($actor->current_year);
    my @trade_ok = $actor->get_events("TRADE OK", $prev_year);
    for(@trade_ok)
    {
        my $route = $_;
        $route =~ s/^TRADE OK //;
        $route =~ s/ \[.*$//;
        my $status = $self->world->diplomacy_status($actor->name, $route);
        if(! $self->world->exists_treaty($actor->name, $route) && $status ne 'HATE')
        {
            return "TREATY COM WITH " . $route;
        }
    }
    return undef;
}

1;
