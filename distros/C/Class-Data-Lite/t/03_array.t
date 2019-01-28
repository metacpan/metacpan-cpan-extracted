use strict;
use warnings;
use utf8;
use Test::More;

package _D;

use Class::Data::Lite (
    rw => [qw/rw rw2/],
);

package main;

is(_D->rw, undef);
is(_D->rw2(15), 15);
is(_D->rw2, 15);

done_testing;
