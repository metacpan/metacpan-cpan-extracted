#!/usr/bin/perl -w
use Test::More;
eval "use POSIX";
plan skip_all => "POSIX required for testing _ceil()" if $@;

# count number of tests
$m = 20;
$t = 0;
foreach my $a ( -$m..$m ) {
	foreach my $b ( -$m..$m ) {
		next if $b == 0;
		$t++;
	}
}
plan tests => $t;

use Data::SimplePaginator;

foreach my $a (-$m..$m) {
	foreach my $b (-$m..$m) {
		next if $b == 0;
		my $j = Data::SimplePaginator::_ceil($a/$b);
		my $p = POSIX::ceil($a/$b);
		ok( $j == $p );
	}
}

