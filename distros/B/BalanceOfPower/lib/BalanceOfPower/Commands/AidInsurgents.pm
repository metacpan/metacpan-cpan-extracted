package BalanceOfPower::Commands::AidInsurgents;
$BalanceOfPower::Commands::AidInsurgents::VERSION = '0.400115';
use v5.10;
use Moo;

use Array::Utils qw(intersect);

use BalanceOfPower::Constants ":all";
use BalanceOfPower::Utils qw( prev_turn );

extends 'BalanceOfPower::Commands::InMilitaryRange';


sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();

    my @available = $self->get_available_targets();
    my @crises = $self->world->get_crises($actor->name);
    my @crisis_enemies;
    foreach my $c (@crises)
    {
       push @crisis_enemies, $c->destination($actor->name); 
    }
    my @choose = $self->world->shuffle("Choosing insurgents to aid for ". $actor->name , intersect(@available, @crisis_enemies));
    if(@choose > 0)
    {
        return "AID INSURGENTS IN " . $choose[0]; 
    }
    else
    {
        return undef;
    }
}

1;
