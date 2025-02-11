#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 1;

use Algorithm::X::ExactCoverProblem;
use Algorithm::X::DLX;

my $rows = [[]];
my $dlx = Algorithm::X::DLX->new(Algorithm::X::ExactCoverProblem->new(1, $rows));
is(0, $dlx->count_solutions(), 'no rows - no solution');

done_testing();

