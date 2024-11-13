#! perl

use strict;
use warnings;

use Test::More;

use Crypt::Bear;

my $config = Crypt::Bear->get_config();

ok exists $config->{BR_MAX_RSA_SIZE};
ok exists $config->{BR_RDRAND};

done_testing;
