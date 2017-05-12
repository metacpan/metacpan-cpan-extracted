package BalanceOfPower::Commands::LowerDisorder;
$BalanceOfPower::Commands::LowerDisorder::VERSION = '0.400115';
use Moo;

use BalanceOfPower::Constants ":all";

extends 'BalanceOfPower::Commands::NoArgs';

sub IA
{
    my $self = shift;
    my $nation = $self->get_nation();
    if($nation->internal_disorder > WORRYING_LIMIT && $nation->production_for_domestic > DOMESTIC_BUDGET)
    {
        return "LOWER DISORDER";
    }
    else
    {
        return undef;
    }
}

1;
