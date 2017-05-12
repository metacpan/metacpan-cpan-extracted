# $Id: holidays.t 1347 2004-05-26 09:10:20Z jonasbn $

use strict;
use Test::More tests => 6;

my $debug = 0;

use lib qw(t);
use_ok('TestModule');

my $mh = TestModule->new();

isa_ok($mh, 'Date::Holidays::Super');

can_ok($mh, "holidays");

use Data::Dumper;
print STDERR Dumper $mh if $debug;

ok(ref $mh);

my $hashref;
ok($hashref = $mh->holidays(
	year => 2004
));

is(ref $hashref, 'HASH');
