package BalanceOfPower::Commands::AddRoute;
$BalanceOfPower::Commands::AddRoute::VERSION = '0.400115';
use Moo;

use BalanceOfPower::Constants ":all";
use BalanceOfPower::Utils qw( prev_turn );

extends 'BalanceOfPower::Commands::NoArgs';

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    my $prev_year = prev_turn($actor->current_year);
    my @trade_ok = $actor->get_events("TRADE OK", $prev_year);
    my @trade_ko = $actor->get_events("TRADE KO", $prev_year);
    my @remains = $actor->get_events("REMAIN", $prev_year);
    my @deleted = $actor->get_events("TRADEROUTE DELETED", $prev_year);
    my @boost = $actor->get_events("BOOST OF PRODUCTION", $prev_year);
    if(@remains > 0 && @deleted == 0 && @boost == 0)
    {
        my $rem = $remains[0];
        $rem =~ m/^REMAIN (.*)$/;
        my $remaining = $1;
        if($remaining >= TRADING_QUOTE)
        {
            return "ADD ROUTE";
        }
    }
    return undef;
}

1;
