#!perl

# Test XY format read/write

use Test::More tests => 27;
use File::Temp ();

use strict;

require_ok( "Astro::Catalog" );
require_ok( "Astro::Catalog::IO::XY" );

my $cat = new Astro::Catalog( Format => 'XY',
                              Data => \*DATA );
isa_ok( $cat, "Astro::Catalog" );

# There should be five items in the catalog.
is( $cat->sizeof, 5, "number of items in catalog" );

my @stars = $cat->stars;

is( $stars[0]->x, 1,  "star 0 x position is 1" );
is( $stars[0]->y, 2,  "star 0 y position is 2" );
is( $stars[1]->x, 2,  "star 1 x position is 2" );
is( $stars[1]->y, 3,  "star 1 y position is 3" );
is( $stars[2]->x, 4,  "star 2 x position is 4" );
is( $stars[2]->y, 7,  "star 2 y position is 7" );
is( $stars[3]->x, 2,  "star 3 x position is 2" );
is( $stars[3]->y, 9,  "star 3 y position is 9" );
is( $stars[4]->x, 12, "star 4 x position is 12" );
is( $stars[4]->y, 52, "star 4 y position is 52" );

# Write out a file, then read it back in.
my $fh = new File::Temp;
my $tempfile = $fh->filename;
ok( $cat->write_catalog( Format => 'XY', File => $tempfile ),
    "Writing catalogue to disk" );

my $newcat = new Astro::Catalog( Format => 'XY', File => $tempfile );
isa_ok( $newcat, "Astro::Catalog" );

# There should be five items in the new catalog.
is( $newcat->sizeof, 5, "number of items in new catalog" );

my @newstars = $newcat->stars;

is( $newstars[0]->x, 1,  "new star 0 x position is 1" );
is( $newstars[0]->y, 2,  "new star 0 y position is 2" );
is( $newstars[1]->x, 2,  "new star 1 x position is 2" );
is( $newstars[1]->y, 3,  "new star 1 y position is 3" );
is( $newstars[2]->x, 4,  "new star 2 x position is 4" );
is( $newstars[2]->y, 7,  "new star 2 y position is 7" );
is( $newstars[3]->x, 2,  "new star 3 x position is 2" );
is( $newstars[3]->y, 9,  "new star 3 y position is 9" );
is( $newstars[4]->x, 12, "new star 4 x position is 12" );
is( $newstars[4]->y, 52, "new star 4 y position is 52" );

exit;

__DATA__
1 2
2 3
4 7
# this is a comment
 2 9
  12      52     
