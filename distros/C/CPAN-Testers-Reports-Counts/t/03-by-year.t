#!perl

use strict;
use warnings;
use lib './t/lib';

use CPAN::Testers::Reports::Counts::TestWrapper;
use Test::More 0.88 tests => 6;
use CPAN::Testers::Reports::Counts qw(reports_counts_by_year);

SKIP: {
    my $counts = reports_counts_by_year();

    ok(defined($counts), "get all counts");

    is($counts->{'1999'}->{REPORTS},2458,   "There were 2458 reports in total in 1999");
    is($counts->{'2004'}->{PASS},   41913,  "There were 41913 passes in 2004");
    is($counts->{'2010'}->{FAIL},   313898, "There were 313898 fails in 2010");
    is($counts->{'2002'}->{NA},     522,    "There were 522 NA reports in 2002");
    is($counts->{'2008'}->{UNKNOWN},55355,  "There were 55355 UNKNOWN reports in 2008");

};
