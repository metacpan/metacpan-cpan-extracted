package BalanceOfPower::Commands::Progress;
$BalanceOfPower::Commands::Progress::VERSION = '0.400115';
use Moo;

use BalanceOfPower::Constants ":all";
use BalanceOfPower::Utils qw( prev_turn );

extends 'BalanceOfPower::Commands::NoArgs';

sub IA
{
    return "PROGRESS";
}

1;
