#!perl -wT

use strict;
use warnings;
use Test::Most tests => 14;
use Test::NoWarnings;
use CHI;

BEGIN {
	use_ok('Class::Simple::Cached');
}

TEST: {
	my $cache = CHI->new(driver => 'RawMemory', datastore => {});
	$cache->on_set_error('die');
	$cache->on_get_error('die');
	my $l = new_ok('Class::Simple::Cached' => [ cache => $cache ]);

	ok($l->fred('wilma') eq 'wilma');
	ok($l->fred() eq 'wilma');
	ok($l->fred() eq 'wilma');

	my @rc = $l->adventure('plugh', 'xyzzy');
	ok(scalar(@rc) == 2);
	ok($rc[0] eq 'plugh');
	ok($rc[1] eq 'xyzzy');

	@rc = $l->foo();
	ok(!defined($rc[0]));

	ok($cache->get('fred') eq 'wilma');

	if($ENV{'TEST_VERBOSE'}) {
		foreach my $key($cache->get_keys()) {
			diag($key);
		}
	}

	$l = new_ok('Class::Simple::Cached' => [ cache => $cache, object => new_ok('foo') ]);
	@rc = $l->foo('bar', 'baz');
	ok(scalar(@rc) == 0);
}

package foo;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return {}, $class;
}

sub foo {
	return;
}

1;

