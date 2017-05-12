# File:		test.pl
# Author:	Daniel Hagerty, hag@linnaean.org
# Date:		Mon Jul  5 18:16:25 1999
# Description:	Module test script for BSD::Itimer
#
# Copyright (c) 1999 Daniel Hagerty. All rights reserved. This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.
#
# $Id: test.pl,v 1.1 1999/07/06 02:56:11 hag Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use strict;

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $loaded;

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use BSD::Itimer;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

##
# Get ITIMER_REAL; should be (0,0,0,0)

my ($interval_sec, $interval_usec, $current_sec, $current_usec) =
    getitimer(ITIMER_REAL);

my @frob = getitimer(ITIMER_REAL);

if(($interval_sec != 0) || ($interval_usec != 0) ||
   ($current_sec != 0) || ($current_usec != 0)) {
    print "not ok 2\n";
} else {
    print "ok 2\n";
}

##
# Set ITIMER_REAL to 10 seconds and see what happens

my $got_alrm;
my $now;

sub alrm {
    $got_alrm = 1;
    $now = time;
}
$SIG{"ALRM"} = \&alrm;

my $start = time;

setitimer(ITIMER_REAL, 0, 0, 10, 0);

# Tight loop until the alarm happens.  Could call pause if we imported
# it from posix.
until($got_alrm) {
}

my $delta = $now - $start;

# Wish I could make this a more reasonable test, but there are too
# many reasons for us not to get scheduled.
if($delta < 10) {
    print "not ok 3\n";
} else {
    print "ok 3\n";
}
