use Test::More tests => 4;

# ------------------------

BEGIN{ use_ok('Date::MSAccess'); }

my($date) = Date::MSAccess -> new();

ok(defined $date, 'new() returned something');
ok($date -> isa('Date::MSAccess'), 'new() returned an object of type Date::MSAccess');

is($date -> decode_date(37988), '20040101', "Test decode_date(37988)");
#is($date -> todays_date(), 38006, 'Test todays_date() on 20-Jan-2004');
