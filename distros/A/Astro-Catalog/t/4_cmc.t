#!perl
# Astro::Catalog::Query::BSC test harness

use strict;

use Test::More tests => 3;
use Data::Dumper;

BEGIN {
    use_ok("Astro::Catalog::Item");
    use_ok("Astro::Catalog");
    use_ok("Astro::Catalog::Query::CMC");
}

# Load the generic test code
my $p = (-d "t" ? "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";

exit;
