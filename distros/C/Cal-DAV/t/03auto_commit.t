#!perl -w

use strict;
use lib qw(t);
use Cal::DAV;
use Test::More;
use CalDAVTest;

for (qw(CAL_DAV_USER CAL_DAV_PASS CAL_DAV_URL_BASE)) {
    if (!defined $ENV{$_}) {
        plan skip_all => "Need to provide a $_ environment variable";
    }
}
plan tests => 5;

my $cal;
ok($cal = get_cal_dav('new.ics', 1), "Instantiated ok");

# Parse
ok($cal->parse(filename => 't/ics/new.ics'), "Parsed a file");

# Destroy
$cal = undef;

# Get 
ok($cal = get_cal_dav('new.ics'), "Instantiated ok again");

# Check
is(scalar(@{$cal->entries}), 1, "Got 1 entry");

ok($cal->delete, "Delete");



