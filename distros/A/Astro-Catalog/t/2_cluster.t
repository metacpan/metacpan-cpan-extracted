# Astro::Catalog test harness

use Test::More tests => 72;
use strict;
use File::Temp;

BEGIN {
    use_ok( "Astro::Catalog" );
}

# Load the generic test code
my $p = (-d "t" ? "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";

# Read in the catalogue from the DATA block
my $cat = new Astro::Catalog(Format => 'Cluster', Data => \*DATA);

# Is it an Astro::Catalog object?
isa_ok($cat, "Astro::Catalog");

# Write the catalogue out to disk.
my $tempfile = File::Temp->new();
ok($cat->write_catalog(
            Format => 'Cluster',
            File   => $tempfile,
            ),
        "Writing catalogue to disk" );

# Read it back in...
my $newcat = new Astro::Catalog(
        Format => 'Cluster',
        File   => $tempfile,
    );

# ...check to make sure it's an Astro::Catalog object...
isa_ok($newcat, "Astro::Catalog");

# ...and that it's the same as the old catalogue.
compare_catalog($cat, $newcat);

# Pop off the first item.
my $item = $cat->popstar;

# Is it an Astro::Catalog::Item object?
isa_ok($item, "Astro::Catalog::Item");

# Check its attributes.
is($item->id, "2", "Cluster Star ID");
is($item->field, "00081", "Cluster Star field");
is($item->ra, "10 44 57.00", "Cluster Star RA");
is($item->dec, "+12 34 53.50", "Cluster Star Dec");
is($item->get_magnitude( 'B' ), 9.3, "Cluster Star B magnitude");
is($item->get_errors( 'B' ), 0.2, "Cluster Star B magnitude error");

exit;

__DATA__
5 colours were created
B R V B-R B-V
A sub-set of USNO-A2: Field centre at RA 01 10 12.90, Dec +60 04 35.90, Search Radius 1 arcminutes 
00080  1  09 55 39.00  +60 07 23.60  0.000  0.000  16.4  0.4  0  16.1  0.1  0  16.3  0.3  0  0.3  0.05  0  0.1  0.02  0
00081  2  10 44 57.00  +12 34 53.50  0.000  0.000  9.3  0.2  0  9.5  0.6  0  9.1  0.1  0  0.2  0.07  0  -0.2  0.05  0
