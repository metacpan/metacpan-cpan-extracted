use strict;
use warnings;

use Test::More;
use DDP::S;
BEGIN {
  $ENV{ANSI_COLORS_DISABLED} = 1;
  delete $ENV{DATAPRINTERRC};
  use File::HomeDir::Test;  # avoid user's .dataprinter
};

my $expected = q{\ [
    [0] 1,
    [1] 2,
    [2] 3
]};
my $foo = [1,2,3];

scope {
  is (p($foo), $expected, "in scope print statements printed.");
};

is (p($foo), undef, "out of scope print statements are noop.");

done_testing;
