use Test::More tests => 7;
use strict;
use warnings;

use_ok('Date::Span');

my $start = 10000000;
my $end   = 11000000;

my @durations = (
	[  9936000, 22400 ],
	[ 10022400, 86400 ],
	[ 10108800, 86400 ],
	[ 10195200, 86400 ],
	[ 10281600, 86400 ],
	[ 10368000, 86400 ],
	[ 10454400, 86400 ],
	[ 10540800, 86400 ],
	[ 10627200, 86400 ],
	[ 10713600, 86400 ],
	[ 10800000, 86400 ],
	[ 10886400, 86400 ],
	[ 10972800, 27200 ]
);

my @expansion = (
	[ 10000000, 10022399 ],
	[ 10022400, 10108799 ],
	[ 10108800, 10195199 ],
	[ 10195200, 10281599 ],
	[ 10281600, 10367999 ],
	[ 10368000, 10454399 ],
	[ 10454400, 10540799 ],
	[ 10540800, 10627199 ],
	[ 10627200, 10713599 ],
	[ 10713600, 10799999 ],
	[ 10800000, 10886399 ],
	[ 10886400, 10972799 ],
	[ 10972800, 11000000 ]
); 

is_deeply(
	[ range_durations($start, $end) ],
	\@durations,
	"durations: 10000000 to 11000000"
);

is_deeply(
	[ range_expand($start, $end) ],
	\@expansion,
	"expansion: 10000000 to 11000000"
);

is_deeply(
	[ range_durations(10000000, 10000500) ],
	[ [ 9936000, 500 ] ],
	"single day duration: 10000000 to 10000500"
);

is_deeply(
	[ range_expand(10000000, 10000500) ],
	[ [ 10000000, 10000500 ] ],
	"single day expansion 10000000 to 10000500"
);

is(range_expand(10000000, 9000000), undef, "can't expand backward range");
is(range_durations(10000000, 9000000), undef, "can't expand backward range");
