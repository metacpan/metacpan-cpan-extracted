#!perl -T

=head1 PURPOSE

Test updating rows, with modified being a real timestamps as opposed to the
default unixtime format.

=cut

use strict;
use warnings;

use lib 't/lib';

use LocalTest;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use TestSubclass::DateTable;


# SQLite and MySQL will have 2013-08-02 04:22:02, while PostgreSQL will format
# as 2013-08-02 04:22:02.161876.
my $date_pattern = qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/;

my $dbh = LocalTest::ok_database_handle();

my $object_id;
subtest(
	'Insert test object.',
	sub
	{
		plan( tests => 3 );

		ok(
			my $object = TestSubclass::DateTable->new(),
			'Create new object.',
		);

		my $name = 'test_update_timestamp_' . time();
		lives_ok(
			sub
			{
				$object->insert(
					{
						name  => $name,
						value => 1,
					},
				);
			},
			'Insert succeeds.',
		);

		$object_id = $object->id();

		# Forge the created and modified date, so that when we update the record we
		# can check if the modified date was properly changed.
		lives_ok(
			sub
			{
				$dbh->do(
					q|
						UPDATE date_tests
						SET created = ?, modified = ?
						WHERE test_id = ?
					|,
					{},
					'2010-01-01 00:00:01',
					'2010-01-01 00:00:01',
					$object_id,
				);
			},
			'Set the created and modified date in the past.',
		);
	}
);

subtest(
	'Update the object',
	sub
	{
		plan( tests => 4 );

		ok(
			defined(
				my $object = TestSubclass::DateTable->new( { id => $object_id } )
			),
			'Retrieve the object.',
		);

		is(
			$object->get('modified'),
			'2010-01-01 00:00:01',
			'The modified date has been correctly set in the past.',
		);

		lives_ok(
			sub
			{
				$object->update(
					{
						name => $object->get('name') . '_',
					}
				);
			},
			'Update the object.',
		);

		is(
			$object->get('modified'),
			TestSubclass::DateTable->get_current_time(),
			'The modified field on the non-reloaded object shows the SQL function string.',
		);
	}
);

subtest(
	'Verify updated row.',
	sub
	{
		plan( tests => 2 );

		ok(
			defined(
				my $object = TestSubclass::DateTable->new( { id => $object_id } )
			),
			'Retrieve the object.',
		);

		like(
			$object->get('modified'),
			$date_pattern,
			'The modified field on the reloaded object is correctly formatted.',
		);
	}
);
