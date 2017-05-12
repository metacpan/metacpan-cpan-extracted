use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok "Data::Entropy::RawSource::RandomnumbersInfo"; }

my $rawsrc = Data::Entropy::RawSource::RandomnumbersInfo->new;
ok $rawsrc;

1;
