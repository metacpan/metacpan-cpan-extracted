package BalanceOfPower::Commands::BoostProduction;
$BalanceOfPower::Commands::BoostProduction::VERSION = '0.400115';
use Moo;

use BalanceOfPower::Constants ":all";

extends 'BalanceOfPower::Commands::NoArgs';

sub IA
{
    my $self = shift;
    my $nation = $self->get_nation();
    if($nation->production < EMERGENCY_PRODUCTION_LIMIT)
    {
        return "BOOST PRODUCTION"
    }
    else
    {
        return undef;
    }
}

1;
