#!perl -T

=head1 PURPOSE

Test inserting in a table, with created/modified being real timestamps as
opposed to the default unixtime format.

=cut

use strict;
use warnings;

use lib 't/lib';

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use TestSubclass::DateTable;


# SQLite and MySQL will have 2013-08-02 04:22:02, while PostgreSQL will format
# as 2013-08-02 04:22:02.161876.
my $date_pattern = qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/;

my $object_id;
subtest(
	'Insert test object.',
	sub
	{
		plan( tests => 2 );

		ok(
			my $object = TestSubclass::DateTable->new(),
			'Create new object.',
		);

		my $name = 'test_insert_timestamp_' . time();
		lives_ok(
			sub
			{
				$object->insert(
					{
						name => $name,
					}
				)
			},
			'Insert succeeds.',
		);

		$object_id = $object->id();
	}
);

ok(
	defined(
		my $object = TestSubclass::DateTable->new( { id => $object_id } )
	),
	'Retrieve the object.',
);

like(
	$object->get('created'),
	$date_pattern,
	'The created field is correctly formatted.',
);

like(
	$object->get('modified'),
	$date_pattern,
	'The modified field is correctly formatted.',
);
