#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Dump::Streamer;

note "Single variable with Terse"; {
    is_deeply(eval(Dump([])->Terse(1)->Out), []);
    is_deeply eval(Dump({})->Terse(1)->Out), {};
    is eval(Dump(23)->Terse(1)->Out), 23;
    is_deeply eval(Dump({ foo => 23 })->Terse(1)->Out), { foo => 23 };
}

note "Many variables with Terse";

note "Code refs with Terse"; {
    is eval(Dump(sub { 23 })->Terse(1)->Out)->(), 23;
}

done_testing;
