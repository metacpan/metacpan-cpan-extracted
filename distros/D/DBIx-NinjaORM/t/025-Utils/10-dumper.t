#!perl -T

=head1 PURPOSE

Test the dumper() function provided by DBIx::NinjaORM::Utils.

=cut

use strict;
use warnings;

use DBIx::NinjaORM::Utils;
use Test::Exception;
use Test::More tests => 3;


can_ok(
	'DBIx::NinjaORM::Utils',
	'dumper',
);

my $test_hash =
{
	'key1' => 'value',
	'key2' => 'value',
};

subtest(
	'Test default dumper.',
	sub
	{
		plan( tests => 2 );

		my $output;
		lives_ok(
			sub
			{
				$output = DBIx::NinjaORM::Utils::dumper( $test_hash );
			},
			'Call dumper().',
		);

		like(
			$output,
			qr/key1/,
			'The stringified return value includes the original key.',
		) || diag( $output );
	}
);

subtest(
	'Test custom dumper.',
	sub
	{
		plan( tests => 3 );

		ok(
			local $DBIx::NinjaORM::Utils::DUMPER = sub
			{
				my ( $hash ) = @_;
				return join( ',', sort keys %$hash );
			},
			'Set up custom dumper.',
		);

		my $output;
		lives_ok(
			sub
			{
				$output = DBIx::NinjaORM::Utils::dumper( $test_hash );
			},
			'Call dumper().',
		);

		is(
			$output,
			'key1,key2',
			'Verify the stringified return value.',
		) || diag( $output );
	}
);
