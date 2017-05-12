use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok "Data::Entropy::RawSource::RandomOrg"; }

my $rawsrc = Data::Entropy::RawSource::RandomOrg->new;
ok $rawsrc;

1;
