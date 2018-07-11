use Test2::V0 -no_srand => 1;
use Alt::Alien::cmake3::System;

is(Alt::Alien::cmake3::System->can_run, T());

done_testing
