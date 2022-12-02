use strict;
use warnings;

use lib 'lib';

use Data::ULID qw();
use Data::ULID::XS qw();
use Benchmark qw(cmpthese);

cmpthese -3, {
	perl_text => sub { Data::ULID::ulid() },
	perl_binary => sub { Data::ULID::binary_ulid() },
	xs_text => sub { Data::ULID::XS::ulid() },
	xs_binary => sub { Data::ULID::XS::binary_ulid() },
};

