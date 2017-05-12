# $Id: is_holiday.t 1347 2004-05-26 09:10:20Z jonasbn $

use strict;
use Test::More tests => 5;

my $debug = 0;

use lib qw(t);
use_ok('TestModule');

my $mh = TestModule->new();

isa_ok($mh, 'Date::Holidays::Super');

can_ok($mh, "holidays");

use Data::Dumper;
print STDERR Dumper $mh if $debug;

ok(ref $mh);

ok(! $mh->is_holiday(
	year  => 2004,
	month => 12,
	day   => 25
));
