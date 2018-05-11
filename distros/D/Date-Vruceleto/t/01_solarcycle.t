#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
# 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl solarcycle.t'

# Test file created outside of h2xs framework.
# Run this like so: `perl solarcycle.t'
#   Roman Pavlov <rp@freeshell.org>     2016/03/04 13:54:13

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw( no_plan );
#BEGIN { use_ok( Date::Vruceleto ); }

use Date::Vruceleto qw(vruceleto solarcycle);

is (solarcycle(7508), 4, "7508 AM");
is (solarcycle(2000, 1), 4, "2000 AD");
is (solarcycle(7308), 28, "Check 28");
is (solarcycle(7309), 1, "Check 1");

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.


