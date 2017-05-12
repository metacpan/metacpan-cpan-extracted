use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Algorithm::SAT::Backtracking
    Algorithm::SAT::Backtracking::DPLL
    Algorithm::SAT::Backtracking::DPLLProb
    Algorithm::SAT::Backtracking::Ordered
    Algorithm::SAT::Backtracking::Ordered::DPLL
    Algorithm::SAT::Expression
);

done_testing;

