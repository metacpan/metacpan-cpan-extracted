#!perl -T

=head1 PURPOSE

Test setting data into the memcache cache.

We only verify here that we're able to set data, not that they are set properly.
We'll verify that they're set properly into the next test suite, were we
verify that get_cache() works as well.

=cut

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More;
use TestSubclass::Memcache;


LocalTest::ok_memcache();

plan( tests => 6 );

dies_ok(
	sub
	{
		TestSubclass::Memcache->set_cache();
	},
	'The "key" argument cannot be undefined.'
);

dies_ok(
	sub
	{
		TestSubclass::Memcache->set_cache( key => '' );
	},
	'The "key" argument cannot be empty.'
);

dies_ok(
	sub
	{
		TestSubclass::Memcache->set_cache(
			key         => 'test_get_cache',
			expire_time => time() + 100,
		);
	},
	'The "value" argument cannot be undefined.',
);

dies_ok(
	sub
	{
		TestSubclass::Memcache->set_cache( invalid_argument => 1 );
	},
	'Invalid argument names are detected properly.'
);

lives_ok(
	sub
	{
		TestSubclass::Memcache->set_cache(
			key         => 'test_get_cache',
			value       => time(),
			expire_time => time() + 100,
		);
	},
	'Set a test cache key.',
);

lives_ok(
	sub
	{
		TestSubclass::Memcache->set_cache(
			key         => 'test_get_cache',
			value       => time(),
		);
	},
	'Set a test cache key without expire time.',
);
