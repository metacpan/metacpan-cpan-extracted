package BalanceOfPower::Commands::BuildTroops;
$BalanceOfPower::Commands::BuildTroops::VERSION = '0.400115';
use Moo;

use BalanceOfPower::Constants ':all';

extends 'BalanceOfPower::Commands::NoArgs';

sub allowed
{
    my $self = shift;
    my $nation = $self->world->get_nation($self->actor);
    my $other_checks = $self->SUPER::allowed();
    if($other_checks)
    {
        my $export_cost = $nation->build_troops_cost();
        return $nation->production_for_export >= $export_cost;
    }
    else
    {
        return 0;
    }
}

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    if($actor->army < MAX_ARMY_FOR_SIZE->[ $actor->size ])
    {
        if($actor->army < MINIMUM_ARMY_LIMIT)
        {
            return "BUILD TROOPS";
        }
        elsif($actor->army < MEDIUM_ARMY_LIMIT)
        {
            if($actor->production_for_export > MEDIUM_ARMY_BUDGET)
            {
                return "BUILD TROOPS";
            }
        }
        else
        {
            if($actor->production_for_export > MAX_ARMY_BUDGET)
            {
                return "BUILD TROOPS";
            }
        }
    }
    return undef;
}

1;
