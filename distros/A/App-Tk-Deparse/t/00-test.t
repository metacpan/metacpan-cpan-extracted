use strict;
use warnings;
use Test::More;

use App::Tk::Deparse;

if (not $ENV{TRAVIS}) {
    App::Tk::Deparse->new;
}

pass;


done_testing();
