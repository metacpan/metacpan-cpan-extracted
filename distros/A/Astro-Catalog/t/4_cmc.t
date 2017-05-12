#!perl
# Astro::Catalog::Query::BSC test harness

# strict
use strict;

#load test
use Test::More tests => 3;
use Data::Dumper;

BEGIN {
  # load modules
  use_ok("Astro::Catalog::Star");
  use_ok("Astro::Catalog");
  use_ok("Astro::Catalog::Query::CMC");
}

# Load the generic test code
my $p = ( -d "t" ?  "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";

# T E S T   H A R N E S S --------------------------------------------------

exit;
