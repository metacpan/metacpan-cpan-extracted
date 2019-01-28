use strict;
use warnings;
use Test::More;

package _D;

use Class::Data::Lite (
    rw => {
        rw  => 11,
    },
    ro => {
        ro => 22,
    },
);

package _E;
our @ISA = ('_D');

package main;

eval { _E->rw(1) };
like $@, qr{can't call "_D::rw" as object method or inherited class method};

is(_E->rw, 11);
is(_E->ro, 22);

done_testing;
