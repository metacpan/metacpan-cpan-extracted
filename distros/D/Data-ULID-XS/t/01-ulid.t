use v5.10;
use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Data::ULID::XS', 'ulid'); }
use Data::ULID qw();

isnt \&ulid, \&Data::ULID::ulid, 'not the same ulid function ok';

my %seen;

# generating randomness - test a couple of times to make sure corner case random values are covered
for (1 .. 20) {
	my $generated = ulid;

	is length $generated, 26, 'length ok';
	ok !$seen{$generated}, 'ulid unique ok';

	note $generated;

	my $perl_generated = Data::ULID::ulid;
	my $perl_regenerated = Data::ULID::ulid($generated);

	# time part is 10 characters, but it represents microtime, so lets just test first 7
	# this gives us 15 bit window in which the tests will pass - 32 seconds
	is substr($generated, 0, 7), substr($perl_generated, 0, 7), 'time part ok';
	is $generated, $perl_regenerated, 'perl regenerated ok';

	my $regenerated = ulid($perl_generated);

	is $perl_generated, $regenerated, 'xs regenerated ok';
}

done_testing;

