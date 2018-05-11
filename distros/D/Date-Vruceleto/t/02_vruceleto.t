#!/usr/bin/perl -Iblib/lib -Iblib/arch -I../blib/lib -I../blib/arch
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Vruceleto.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
#BEGIN { use_ok('Date::Vruceleto') };

use Date::Vruceleto qw(vruceleto solarcycle vrutseleto);
use utf8;

is (vruceleto(7508), 'Е', "7508 AM");
is (vruceleto(2000, 1), 'Е', "2000 AD");
is (vruceleto(7308), 'З', "Check 28");
is (vruceleto(7309), 'А', "Check 1");

is (vruceleto(7521), 'З', "7521 AM");

is (vrutseleto(7521), 'З', "7521 AM");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

