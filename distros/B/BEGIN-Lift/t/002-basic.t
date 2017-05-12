#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

our $TEST;

BEGIN {
	use_ok('BEGIN::Lift');

    $TEST = 0;

    BEGIN::Lift::install(
        ('main', 'test') => sub {
            $TEST++;
            return;
        }
    );
}

BEGIN { is($TEST, 0, '... variable is in expected start state (in BEGIN)') }
is($TEST, 4, '... we have the full value as expected (in RUN)');

test();
BEGIN { is($TEST, 1, '... we incremented correctly for the 1st time (in BEGIN)') }
is($TEST, 4, '... we have the full value as expected (in RUN)');

BEGIN { test(); }
BEGIN { is($TEST, 2, '... we incremented correctly for the 2nd time (in BEGIN)') }
is($TEST, 4, '... we have the full value as expected (in RUN)');

my $loop_one; BEGIN { $loop_one = 0 }
BEGIN {
    foreach (0 .. 4) {
        $loop_one++;
        test();
    }
}
BEGIN { is($TEST, 3, '... we incremented correctly for the 3rd time (in BEGIN)') }
is($TEST, 4, '... we have the full value as expected (in RUN)');
is($loop_one, 5, '... but the loop ran all five times');

my $loop_two; BEGIN { $loop_two = 0 }
foreach (0 .. 4) {
    $loop_two++;
    BEGIN { test(); }
}
BEGIN { is($TEST, 4, '... we incremented correctly for the 4th time (in BEGIN)') }
is($TEST, 4, '... we have the full value as expected (in RUN)');
is($loop_two, 5, '... but the loop ran all five times');

done_testing;

1;
