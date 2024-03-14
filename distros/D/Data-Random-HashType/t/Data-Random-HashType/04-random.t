use strict;
use warnings;

use Data::Random::HashType;
use Test::More 'tests' => 16;
use Test::NoWarnings;

# Test.
my $obj = Data::Random::HashType->new(
	'num_generated' => 1,
	'possible_hash_types' => ['sha256'],
);
my ($ret) = $obj->random;
is($ret->active, 1, 'Get active flag of hash type (1).');
is($ret->name, 'sha256', 'Get name of hash type (sha256).');

# Test.
$obj = Data::Random::HashType->new(
	'mode_id' => 1,
	'num_generated' => 1,
	'possible_hash_types' => ['sha256'],
);
($ret) = $obj->random;
isa_ok($ret, 'Data::HashType');
is($ret->active, 1, 'Get active flag of hash type (1).');
is($ret->id, 1, 'Get id of hash type (1).');
is($ret->name, 'sha256', 'Get name of hash type (sha256).');

# Test.
$obj = Data::Random::HashType->new(
	'num_generated' => 2,
	'possible_hash_types' => ['sha256', 'sha512'],
);
my @ret = $obj->random;
is(scalar @ret, 2, 'Number of random hash types (2).');
isa_ok($ret[0], 'Data::HashType');
isa_ok($ret[1], 'Data::HashType');

# Test.
$obj = Data::Random::HashType->new(
	'num_generated' => 1,
	'possible_hash_types' => ['sha256', 'sha512'],
);
@ret = $obj->random;
is(scalar @ret, 1, 'Number of random hash types (1).');
isa_ok($ret[0], 'Data::HashType');

# Test.
$obj = Data::Random::HashType->new(
	'mode_id' => 1,
	'num_generated' => 1,
	'possible_hash_types' => ['sha256', 'sha512'],
);
@ret = $obj->random;
is(scalar @ret, 1, 'Number of random hash types (1).');
isa_ok($ret[0], 'Data::HashType');

# Test.
$obj = Data::Random::HashType->new(
	'id' => 5,
	'mode_id' => 1,
	'num_generated' => 2,
	'possible_hash_types' => ['sha256', 'sha512'],
);
@ret = $obj->random;
is_deeply(
	[map { $_->id } @ret],
	[5, 6],
	'Generated ids are ok with explicit begin id (5, 6).',
);

# Test.
$obj = Data::Random::HashType->new(
	'cb_id' => sub {
		my $self = shift;
		my $id = $self->{'id'};
		$self->{'id'} += 2;
		return $id;
	},
	'id' => 5,
	'mode_id' => 1,
	'num_generated' => 2,
	'possible_hash_types' => ['sha256', 'sha512'],
);
@ret = $obj->random;
is_deeply(
	[map { $_->id } @ret],
	[5, 7],
	'Generated ids are ok with callback (5, 7).',
);
