#!perl
# Astro::Catalog::Query::MPC test harness

use strict;

use Test::More tests => 202;
use Data::Dumper;

use Astro::Flux;
use Astro::Fluxes;
use Number::Uncertainty;

# Catalog modules need to be loaded first
BEGIN {
    use_ok( "Astro::Catalog::Item");
    use_ok( "Astro::Catalog");
    use_ok( "Astro::Catalog::Query::MPC");
}


# Load the generic test code
my $p = (-d "t" ? "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";


# Grab MPC sample from the DATA block
my @buffer = <DATA>;
chomp @buffer;

# test catalog
my $catalog_data = new Astro::Catalog();

my $epoch = 2004.16427554485;

# create a temporary object to hold stars
my $star;

# Parse data block
foreach my $line (0 .. $#buffer) {
    my ($name, $ra, $dec, $vmag, $raoff, $decoff, $pm_ra, $pm_dec, $orbit,
            $comment) = unpack("A24A11A10A6A7A7A7A7A6A*", $buffer[$line]);

    if (defined $ra) {
        $star = new Astro::Catalog::Item();

        $name =~ s/^\s+//;
        $star->id( $name );

        $vmag =~ s/^\s+//;

        $star->fluxes(new Astro::Fluxes(new Astro::Flux(
            new Number::Uncertainty(Value => $vmag),
            'mag', "V")));

        $comment =~ s/^\s+//;
        $star->comment($comment);

        # Deal with the coordinates. RA and Dec are almost in the
        # right format (need to replace separating spaces with colons).
        $ra =~ s/^\s+//;
        $ra =~ s/ /:/g;
        $dec =~ s/^\s+//;
        $dec =~ s/ /:/g;

        my $coords = new Astro::Coords(
                name => $name,
                ra => $ra,
                dec => $dec,
                type => 'J2000',
                epoch => $epoch,
            );

        $star->coords($coords);

        # Push the star onto the catalog.
        $catalog_data->pushstar( $star );
    }
}

# field centre
$catalog_data->fieldcentre(
        RA => '07 13 42',
        Dec => '-14 02 00',
        Radius => '300');

# Grab comparison from ESO/ST-ECF Archive Site

my $mpc_byname = new Astro::Catalog::Query::MPC(
    RA => "07 13 42",
    Dec => "-14 02 00",
    Radmax => '300',
    Year => 2004,
    Month => 03,
    Day => 1.87,
);

print "# Connecting to MPC Minor Planet Checker\n";
my $catalog_byname;
eval {$catalog_byname = $mpc_byname->querydb()};
SKIP: {
    diag($@) if $@;
    skip "Cannot connect to MPC website", 199 if $@;
    skip "No asteroids returned from MPC", 199 if ($catalog_byname->sizeof() == 0);
    print "# Continuing tests\n";

    # check sizes
    print "# DAT has " . $catalog_data->sizeof() . " stars\n";
    print "# NET has " . $catalog_byname->sizeof() . " stars\n";

    # Compare catalogues
    compare_mpc_catalog($catalog_byname, $catalog_data);
}

exit;

# Name                   RA         Dec       V_mag raoff  decoff pm_ra pm_dec orbits  comment
__DATA__
(32467) 2000 SL174      07 19 09.3 -12 33 33  19.1  79.4E  88.5N     6-    12+   10o  None needed at this time.
 (75285) 1999 XY24       07 06 17.0 -12 06 32  18.0 107.9W 115.5N     0+    22+    5o  None needed at this time.
 (15834) McBride         07 23 45.8 -12 52 09  18.3 146.5E  69.9N    16-     4+    8o  None needed at this time.
  (4116) Elachi          07 18 20.6 -10 57 31  15.6  67.6E 184.5N    14+    64+   12o  None needed at this time.
 (24972) 1998 FC116      07 28 09.0 -13 36 50  18.8 210.3E  25.2N     4-    31+    8o  None needed at this time.
         1999 XA6        07 22 33.0 -17 10 33  19.2 128.8E 188.6S    13+    20+    2o  Desirable between 2006 Mar. 30-Apr. 29.  At the first date, object will be within 60 deg of the sun.
         2002 TT191      07 15 52.8 -09 58 09  20.0  31.7E 243.8N     6-    15+  111d  Desirable between 2006 Mar. 30-Apr. 14.  (132.1,-24.9,20.2)
         2000 KK60       07 13 55.3 -09 56 02  20.0   3.2E 246.0N     6-    16+    4o  Desirable between 2006 Mar. 30-Apr. 29.  ( 86.1,-07.4,19.7)
 (30505) 2000 RW82       07 06 07.3 -10 20 38  18.6 110.3W 221.4N     4-    14+    7o  None needed at this time.
  (6911) Nancygreen      07 32 17.7 -14 26 49  15.5 270.6E  24.8S     0-    43+   10o  None needed at this time.
(114533) 2003 BY18       07 21 19.7 -09 52 15  18.2 111.0E 249.7N     5-    13+    4o  None needed at this time.
         1999 TM234      07 22 49.8 -09 56 50  18.9 132.9E 245.2N     7-    20+    2o  Desirable between 2006 Mar. 30-Apr. 29.  At the first date, object will be within 60 deg of the sun.
         2000 RS48       07 07 17.2 -09 38 41  19.5  93.3W 263.3N     4+    32+    3o  Desirable between 2006 Mar. 30-Apr. 29.  At the first date, object will be within 60 deg of the sun.
 (54857) 2001 OY22       07 33 08.1 -15 43 07  19.2 282.8E 101.1S    13-    24+    7o  None needed at this time.
