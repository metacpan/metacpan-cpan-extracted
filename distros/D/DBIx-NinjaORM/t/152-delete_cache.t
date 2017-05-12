#!perl -T

=head1 PURPOSE

Test deleting data from the memcache cache.

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

plan( tests => 7 );

dies_ok(
	sub
	{
		TestSubclass::Memcache->delete_cache();
	},
	'The "key" argument cannot be undefined.'
);

dies_ok(
	sub
	{
		TestSubclass::Memcache->delete_cache( key => '' );
	},
	'The "key" argument cannot be empty.'
);

dies_ok(
	sub
	{
		TestSubclass::Memcache->delete_cache( invalid_argument => 1 );
	},
	'Invalid argument names are detected properly.'
);

my $test_key = 'test_delete_cache';
my $test_value = time() + 10;
lives_ok(
	sub
	{
		TestSubclass::Memcache->set_cache(
			key         => $test_key,
			value       => $test_value,
			expire_time => time() + 100,
		);
	},
	'Set the test cache key.',
);

subtest(
	'Verify that the test key has been set correctly.',
	sub
	{
		plan( tests => 2 );
		my $retrieved_value;
		lives_ok(
			sub
			{
				$retrieved_value = TestSubclass::Memcache->get_cache(
					key => $test_key,
				);
			},
			'Retrieve the value associated with the test cache key.',
		);

		is(
			$retrieved_value,
			$test_value,
			'The retrieved value matches the set value.',
		);
	}
);

lives_ok(
	sub
	{
		TestSubclass::Memcache->delete_cache(
			key => $test_key,
		);
	},
	'Delete test cache key.',
);

subtest(
	'Verify that the test key has been deleted correctly.',
	sub
	{
		plan( tests => 2 );
		my $retrieved_value;
		lives_ok(
			sub
			{
				$retrieved_value = TestSubclass::Memcache->get_cache(
					key => $test_key,
				);
			},
			'Retrieve the value associated with the test cache key.',
		);

		is(
			$retrieved_value,
			undef,
			'The test key does not exist anymore in the cache.',
		);
	}
);
