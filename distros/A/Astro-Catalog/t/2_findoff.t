#!perl

# Astro::Catalog test harness
use Test::More tests => 11;

use strict;
use File::Temp;
use Data::Dumper;

# Load modules.
require_ok("Astro::Catalog");
require_ok("Astro::Catalog::Item");

my $tempfile = File::Temp->new();

my $cat = new Astro::Catalog(Format => 'FINDOFF', Data => \*DATA);

isa_ok($cat, "Astro::Catalog");

# Test star with ID 2.
my $star = $cat->popstarbyid( 2 );
$star = $star->[0];
$cat->pushstar($star);

isa_ok($star, "Astro::Catalog::Item");

is($star->id, 2, "Check star ID");
is($star->x, 25.4, "Check star X location");
is($star->y, 395, "Check star Y location");
is($star->comment, "second comment", "Check star comment");

ok($cat->write_catalog( Format => 'FINDOFF', File => $tempfile),
    "Check catalog write" );

# Read it back in.
my $newcat = new Astro::Catalog(Format => 'FINDOFF', File => $tempfile);

isa_ok($newcat, "Astro::Catalog");

is($newcat->sizeof, 5, "Confirm star count");

__DATA__
1 10 23 comment
2 25.4 395 second comment
3 12 49 third comment
4 523 398
5 349 23 fifth comment
