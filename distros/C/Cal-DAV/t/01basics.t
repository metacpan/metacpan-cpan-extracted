#!perl -w

use strict;
use lib qw(t);
use Cal::DAV;
use Test::More;
use CalDAVTest;
use Data::ICal;
#use HTTP::DAV;
#HTTP::DAV::DebugLevel(3);

for (qw(CAL_DAV_USER CAL_DAV_PASS CAL_DAV_URL_BASE)) {
	if (!defined $ENV{$_}) {
	    plan skip_all => "Need to provide a $_ environment variable";
	}
}
plan tests => 14;

my $cal;
ok($cal = get_cal_dav('birthday.ics'), "Instantiated ok");

# Parse
ok($cal->parse(filename => 't/ics/birthdays.ics'), "Parsed a file");

# Save
ok($cal->save, "Saved");

# Get
$cal = undef;
ok($cal = get_cal_dav('birthday.ics'), "Instantiated again");

# Check
my $entries;
ok($entries = $cal->entries, "Got entries");
is(scalar(@$entries), 1, "Got 1 entry");

# Modify
ok($cal->add_entry(make_entry()), "Added an entry");

# Save
ok($cal->save, "Save modified calendar");

# Get
ok($entries = $cal->entries, "Got entries after modification");
is(scalar(@$entries), 2, "Got 2 entries");

# Check
$cal = undef;
ok($cal = get_cal_dav('birthday.ics'), "Instantiated yet again");
ok($entries = $cal->entries, "Got entries after modification and destroy");
is(scalar(@$entries), 2, "Still got 2 entries");

# Delete
ok($cal->delete, "Deleted");

sub make_entry {
	my $d = Data::ICal->new( filename => 't/ics/new.ics' );
	return $d->entries->[0];
}
