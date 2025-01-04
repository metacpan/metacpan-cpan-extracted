#!perl -w

use strict;
use warnings;
use FindBin qw($Bin);
use Test::Most tests => 5;
use Test::Needs 'Test::Carp';
use Carp;
use lib 't/lib';

ERROR: {
	Test::Carp->import();

	use_ok('Database::test1');

	my $test1 = new_ok('Database::test1' => ["$Bin/../data"]);

	does_croak_that_matches(sub { my @rc = $test1->selectall_hash(number => undef) }, qr/value for number is not defined/);
	does_croak_that_matches(sub { my $res = $test1->fetchrow_hashref({ number => undef }) }, qr/value for number is not defined/);
	does_croak_that_matches(sub {
		my $non_existant = Database::test1->new({directory => "$Bin/../data", dbname => 'nan', max_slurp_size => 0});
		cmp_ok($non_existant->number('three'), '==', 3, "Database doesn't exist");
	}, qr/Can't find/);
}
