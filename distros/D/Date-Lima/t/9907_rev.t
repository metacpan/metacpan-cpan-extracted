
use strict;
use Test;

use Time::DeltaString qw/rev/;
plan tests => 1;

my $ds = rev("9h22m5s");

ok($ds, 33_725);
