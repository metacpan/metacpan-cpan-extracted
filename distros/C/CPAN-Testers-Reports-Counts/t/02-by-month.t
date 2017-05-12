#!perl

use strict;
use warnings;
use lib './t/lib';

use CPAN::Testers::Reports::Counts::TestWrapper;
use Test::More 0.88 tests => 6;
use CPAN::Testers::Reports::Counts qw(reports_counts_by_month);

SKIP: {
    my $count_ref = reports_counts_by_month();

    ok(defined($count_ref), "get all counts");

    is($count_ref->{'1999-08'}->{REPORTS},77, "There were 77 reports in total in August 1999");
    is($count_ref->{'2004-12'}->{PASS},4391, "There were 4391 passes in December 2004");
    is($count_ref->{'2010-03'}->{FAIL},15740, "There were 15740 fails in March 2010");
    is($count_ref->{'2002-10'}->{NA},15, "There were 15 NA reports in October 2002");
    is($count_ref->{'2008-11'}->{UNKNOWN},6630, "There were 6630 UNKNOWN reports in November 2008");

};
