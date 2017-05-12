package BalanceOfPower::Commands::RecallRebelMilitarySupport;
$BalanceOfPower::Commands::RecallRebelMilitarySupport::VERSION = '0.400115';
use Moo;

use BalanceOfPower::Constants ':all';

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my @supported = $self->world->rebel_supporter($self->actor);
    my @out = ();
    for(@supported)
    {
        push @out, $_->destination($self->actor);
    }
    return @out;
}

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    if($actor->army <= ARMY_TO_RECALL_SUPPORT)
    {
        my @supports = $self->get_available_targets();
        if(@supports > 0)
        {
            @supports = $self->world->shuffle("Choosing support to recall", @supports);
            return "RECALL REBEL MILITARY SUPPORT " . $supports[0];
        }
    }
    return undef;
}

1;
