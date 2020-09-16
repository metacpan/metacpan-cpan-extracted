use strict;
use warnings;
use Test::More;

use App::PerlTidy::Tk;

if (not $ENV{TRAVIS}) {
    App::PerlTidy::Tk->new;
}

pass;


done_testing();
