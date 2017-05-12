use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

BEGIN {
	use_ok('Config::SL');
}

my $config = Config::SL->new;
isa_ok($config, 'Config::SL');

1;
