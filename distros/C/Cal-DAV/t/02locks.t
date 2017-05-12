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
plan tests => 11;


# Parse
my $cal;
ok($cal = get_cal_dav('birthday.ics'), "Instantiated ok");
ok($cal->parse(filename => 't/ics/birthdays.ics'), "Parsed a file");

# Put
ok($cal->save, "Put");

# Lock
ok($cal->lock, "Locked first cal");

# Fail to obtain lock
my $cal2;
ok($cal2 = get_cal_dav('birthday.ics'), "Instantiated ok");
ok(!$cal2->lock, "Failed to get lock with second cal");

# Unlock 
ok($cal->unlock, "Unlocked first cal");

# Obtain lock
ok($cal2->lock, "Got lock with second cal");

# Forceably unlock
ok($cal->forcefully_unlock_all, "First cal forcefully unlocked");

# Lock
ok($cal->lock, "First cal got lock back");

# Steal lock
ok($cal2->steal_lock, "Second cal stole lock");

