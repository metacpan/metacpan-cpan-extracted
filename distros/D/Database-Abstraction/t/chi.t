#!perl -w

use strict;
use warnings;
use lib 't/lib';

use File::Spec;
use Test::Most tests => 22;
use FindBin qw($Bin);
use Test::Needs 'CHI';

CHI: {
	use_ok('MyLogger');
	use_ok('Database::test1');
	CHI->import();

	my $cache = CHI->new(driver => 'RawMemory', global => 1);
	$cache->on_set_error('die');
	$cache->on_get_error('die');
	my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
	my $test1 = new_ok('Database::test1' => [{
		cache => $cache,
		directory => $directory,
		logger => new_ok('MyLogger'),
		max_slurp_size => 0,	# force to not use slurp and therefore to use SQL and cache
	}]);

	cmp_ok(scalar $cache->get_keys(), '==', 0, 'cache is empty');
	my $rc = $test1->fetchrow_hashref(entry => 'two');
	cmp_ok(ref($rc), 'eq', 'HASH', 'fetchrow hashref returns a reference to a hash');
	cmp_ok($rc->{'number'}, '==', 2, 'basic test works');

	# White box test the cache
	# ok($cache->get('barney::') eq 'betty');
	# ok($cache->get('barney::betty') eq 'betty');

	cmp_ok(scalar $cache->get_keys(), '==', 1, 'cache is populated');

	if($ENV{'TEST_VERBOSE'}) {
		foreach my $key($cache->get_keys()) {
			diag(__LINE__, " $key");
		}
	}
	$rc = $test1->fetchrow_hashref(entry => 'two');
	cmp_ok(scalar $cache->get_keys(), '==', 1, 'cache hit');
	cmp_ok(ref($rc), 'eq', 'HASH', 'fetchrow hashref returns a reference to a hash');
	cmp_ok($rc->{'number'}, '==', 2, 'basic test works');
	cmp_ok($test1->count(entry => 'two'), '==', 1, 'count works with a cache');

	$rc = $test1->selectall_hashref();
	cmp_ok(scalar $cache->get_keys(), '==', 2, 'cache miss');
	cmp_ok(ref($rc), 'eq', 'ARRAY', 'selectall hashref returns a reference to an array');
	cmp_ok(scalar @{$rc}, '==', 4, 'selectall_hashref returns all matches');

	if($ENV{'TEST_VERBOSE'}) {
		foreach my $key($cache->get_keys()) {
			diag(__LINE__, " $key");
		}
	}

	my @rc = $test1->selectall_hash();
	cmp_ok(scalar $cache->get_keys(), '==', 2, 'cache hit');
	cmp_ok(ref($rc[1]), 'eq', 'HASH', 'selectall hashref returns a reference to an array');
	cmp_ok(scalar @rc, '==', 4, 'selectall_hashref returns all matches');

	cmp_ok($test1->number('three'), '==', 3, 'AUTOLOAD with cache works');
	cmp_ok($test1->number('three'), '==', 3, 'AUTOLOAD retrieves from the cache');

	if($ENV{'TEST_VERBOSE'}) {
		foreach my $key($cache->get_keys()) {
			diag(__LINE__, " $key");
		}
	}

	@rc = $test1->number();
	cmp_ok(scalar(@rc), '==', 4, 'AUTOLOAD returns all of an array');
	diag(Data::Dumper->new([\@rc])->Dump()) if($ENV{'TEST_VERBOSE'});
	@rc = $test1->number();
	cmp_ok(scalar(@rc), '==', 4, 'AUTOLOAD returns all of an array from the cache');
	diag(Data::Dumper->new([\@rc])->Dump()) if($ENV{'TEST_VERBOSE'});
}
