#!/usr/bin/perl -sw
##
##
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id$

# Ideally, Strength => 1 should be tested.  However, at the time of the test, 
# it's possible there isn't enough entropy to read off off /dev/random.
# which blocks if entropy_avail < read_wakeup_threshold.
# 
# This can be checked as follows: 
# cat /proc/sys/kernel/random/entropy_avail 
# cat /proc/sys/kernel/random/read_wakeup_threshold
#
# To enable /dev/random test, bump plan_tests to 15 and add this to the list of tests: 
#tests( new Crypt::Random::Generator Strength => 1 );


use Test;
use Crypt::Random::Generator;
BEGIN { plan tests => 10 };

tests( new Crypt::Random::Generator Strength => 0 );
tests( new Crypt::Random::Generator Provider => 'rand' );

sub tests { 

    my $gen = shift;
    my $x = $gen->integer (Size => 10);
    my $y = $gen->integer (Size => 10);
    ok($x < 1025, 1);
    ok($y < 1025, 1);
    ok($gen->integer (Upper => 500) < 501, 1);
    ok($gen->integer (Size => 128));
    ok(length($gen->string (Length => 30)), 30);

}
