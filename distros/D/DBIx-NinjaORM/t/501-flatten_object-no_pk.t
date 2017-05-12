#!perl -T

=head1 PURPOSE

Test the flatten_object() method for the case where no primary key is set but
the 'id' shortcut for the primary key is used.

=cut

use strict;
use warnings;

use lib 't/lib';

use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;
use TestSubclass::NoPK;


ok(
	defined(
		my $object = TestSubclass::NoPK->new()
	),
	'Create new object.',
);

lives_ok(
	sub
	{
		$object->set(
			{
				name => 'test_flatten_' . time(),
			}
		);
	},
	'Set fields.',
);

throws_ok(
	sub
	{
		$object->flatten_object(
			[ 'id' ],
		);
	},
	qr/Requested adding ID to the list of fields, but the class doesn't define a primary key name/,
	'Cannot flatten "id" when no primary key exists on the table.',
);
