use strict;
use warnings;
use Test::More 0.98;

package _D;

use Class::Data::Lite (
    rw => {
        rw  => 11,
        rw2 => 55,
    },
    ro => {
        ro => 22,
    },
);

package main;

is(_D->rw, 11);
is(_D->rw2, 55);
is(_D->ro, 22);

is(_D->rw(33), 33);
is(_D->rw, 33);
is(_D->rw2, 55);
is(_D->ro(33), 22);

done_testing;

