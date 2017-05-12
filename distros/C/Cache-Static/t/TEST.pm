$|++;
use strict;

use lib "../lib";
use lib "./lib";

use Cache::Static;

Cache::Static::_rebase('/tmp/Cache-Static-test');
Cache::Static::init('_TEST');

my $ok_count = 0;
sub ok {
	my ($name, $condition) = @_;
	$ok_count++;
	die "failed test $ok_count: \"$name\"\n" unless $condition;
	print "ok $ok_count\n";
}

1;

