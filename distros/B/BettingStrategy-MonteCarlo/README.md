[![Build Status](https://travis-ci.org/nqounet/p5-betting_strategy-monte_carlo.svg?branch=master)](https://travis-ci.org/nqounet/p5-betting_strategy-monte_carlo) [![Coverage Status](http://codecov.io/github/nqounet/p5-betting_strategy-monte_carlo/coverage.svg?branch=master)](https://codecov.io/github/nqounet/p5-betting_strategy-monte_carlo?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/BettingStrategy-MonteCarlo.svg)](https://metacpan.org/release/BettingStrategy-MonteCarlo)
# NAME

BettingStrategy::MonteCarlo - Monte Carlo method for gambling.

# SYNOPSIS

```perl
use BettingStrategy::MonteCarlo;
my $strategy = BettingStrategy::MonteCarlo->new(+{magnification => 2});
my $cash     = 100;
while (!$strategy->is_finished) {
    my $bet = $strategy->bet;
    last if $cash < $bet;
    $cash -= $bet;
    if (rand 2 < 1) {
        $cash += $bet * 2;
        $strategy->won;
    }
    else {
        $strategy->lost;
    }
}
print $cash;
```

# DESCRIPTION

Monte Carlo is one of betting strategy.

# LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

nqounet <mail@nqou.net>
