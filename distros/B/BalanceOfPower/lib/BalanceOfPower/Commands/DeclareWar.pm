package BalanceOfPower::Commands::DeclareWar;
$BalanceOfPower::Commands::DeclareWar::VERSION = '0.400115';
use v5.10;
use Moo;

use Array::Utils qw(intersect);

use BalanceOfPower::Constants ":all";
use BalanceOfPower::Utils qw( prev_turn );

extends 'BalanceOfPower::Commands::InMilitaryRange';

sub get_available_targets
{
    my $self = shift;
    my @targets = $self->SUPER::get_available_targets();
    my @out = ();
    for(@targets)
    {
        my $t = $_;
        if((! $self->world->is_under_influence($t) || $self->world->is_under_influence($t) ne $self->actor) &&
            ! $self->world->war_busy($t))
        {
            push @out, $t;
        }
    }
    return @out;
}


sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    my @choose = $self->world->shuffle("Choosing someone to declare war to for ". $actor->name , $self->get_available_targets());
    for(@choose)
    {
        my $enemy = $self->world->get_nation($_);
        if($actor->good_prey($enemy, $self->world))
        {
            return "DECLARE WAR TO " . $enemy->name;
        }
    }
    return undef;
}

1;
