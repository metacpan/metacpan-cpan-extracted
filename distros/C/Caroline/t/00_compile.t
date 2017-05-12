use strict;
use Test::More;

{ package Term::ReadLine::Stub; }

use_ok $_ for qw(
    Caroline
    Term::ReadLine::Caroline
);

done_testing;

