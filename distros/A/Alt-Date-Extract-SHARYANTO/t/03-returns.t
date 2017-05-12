#!perl -T
use strict;
use warnings;
use Test::More tests => 17;
use Test::MockTime 'set_fixed_time';
use Date::Extract;

# a Thursday. The time I wrote this line of code, in fact (in UTC)
set_fixed_time('2007-11-16T02:48:52Z');

my $in = "Today I see a boat. Tomorrow I'll see another. Yesterday I swam.";

my $parser = Date::Extract->new(time_zone => 'UTC');
my $dt = $parser->extract($in);
is($dt->ymd, '2007-11-16', 'default: returns first date, today');

my @dt = $parser->extract($in, returns => 'all');
is($dt[0]->ymd, '2007-11-16', 'all: 1st date out was today');
is($dt[1]->ymd, '2007-11-17', 'all: 2nd date out was tomorrow');
is($dt[2]->ymd, '2007-11-15', 'all: 3rd date out was yesterday');

@dt = $parser->extract($in, returns => 'all_cron');
is($dt[0]->ymd, '2007-11-15', 'all_cron: 1st date out was yesterday');
is($dt[1]->ymd, '2007-11-16', 'all_cron: 2nd date out was today');
is($dt[2]->ymd, '2007-11-17', 'all_cron: 3rd date out was tomorrow');

@dt = $parser->extract($in, returns => 'first');
is(@dt, 1, "only one day came out");
is($dt[0]->ymd, '2007-11-16', 'first: returns first date, today');

@dt = $parser->extract($in, returns => 'last');
is(@dt, 1, "only one day came out");
is($dt[0]->ymd, '2007-11-15', 'last: returns last date, yesterday');

@dt = $parser->extract($in, returns => 'earliest');
is(@dt, 1, "only one day came out");
is($dt[0]->ymd, '2007-11-15', 'earliest: returns earliest date, yesterday');

@dt = $parser->extract($in, returns => 'latest');
is(@dt, 1, "only one day came out");
is($dt[0]->ymd, '2007-11-17', 'latest: returns latest date, tomorrow');

$dt = $parser->extract($in, returns => 'all_cron');
is($dt->ymd, '2007-11-15', 'scalar all_cron: only date out was yesterday');

$dt = $parser->extract($in, returns => 'all');
is($dt->ymd, '2007-11-16', 'scalar all: only date out was today');

