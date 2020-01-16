#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use Getopt::Long qw(:config posix_default no_ignore_case);
use BettingStrategy::MonteCarlo;

GetOptions(
    \my %options, qw(
        magnification=i
        tries=i
        denominator=i
        numerator=i
        )
);

my $magnification = $options{magnification} || 2;
my $tries         = $options{tries}         || 10;
my $denominator   = $options{denominator}   || $magnification;
my $numerator     = $options{numerator}     || 1;

my $cash     = 0;
my $wins     = 0;
my $loses    = 0;
my $max_bet  = 0;
my $min_cash = $cash;
my $max_cash = $cash;
for my $i (1 .. $tries) {
    my $strategy = BettingStrategy::MonteCarlo->new(+{magnification => $magnification});
    while (!$strategy->is_finished) {
        my $bet = $strategy->bet;
        $max_bet = $bet if $bet > $max_bet;
        $cash -= $bet;
        $min_cash = $cash if $cash < $min_cash;
        my $judge = rand $denominator;
        if ($judge < $numerator) {
            $cash += $bet * $strategy->magnification;
            $max_cash = $cash if $cash > $max_cash;
            $strategy->won;
            $wins++;
        }
        else {
            $strategy->lost;
            $loses++;
        }
    }
    say sprintf '----- # %d -----', $i;
    say 'cash : ' . $cash;
    say 'wins : ' . $wins;
    say 'loses: ' . $loses;
    say 'win rate: ' . $wins / ($wins + $loses);
    say 'max_bet : ' . $max_bet;
    say 'min_cash: ' . $min_cash;
    say 'max_cash: ' . $max_cash;
}
