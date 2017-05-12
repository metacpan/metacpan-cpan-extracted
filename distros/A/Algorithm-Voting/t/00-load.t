#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok('Algorithm::Voting');
    use_ok('Algorithm::Voting::Ballot');
    use_ok('Algorithm::Voting::Plurality');
    use_ok('Algorithm::Voting::Sortition');
}

diag("Testing Algorithm::Voting $Algorithm::Voting::VERSION, Perl $], $^X");

