use strict;
use warnings;
use Test::More;

use App::PerlTidy::Tk;

if (not $ENV{TRAVIS} and not $ENV{GITHUB_ACTIONS}) {
    App::PerlTidy::Tk->new;
}

pass;


done_testing();
