use strict;
use warnings;

use lib 'lib';

use Data::ULID qw();
use Data::ULID::XS qw();
use Benchmark qw(cmpthese);

my $benches = {
	'Data::ULID::ulid' => sub { Data::ULID::ulid() },
	'Data::ULID::binary_ulid' => sub { Data::ULID::binary_ulid() },
	'Data::ULID::XS::ulid' => sub { Data::ULID::XS::ulid() },
	'Data::ULID::XS::binary_ulid' => sub { Data::ULID::XS::binary_ulid() },
};

cmpthese -3, $benches;

