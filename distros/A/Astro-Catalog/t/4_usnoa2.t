#!perl
# Astro::Catalog::Query::USNOA2 test harness

# strict
use strict;

#load test
use Test::More tests => 351;
use Data::Dumper;

use Astro::Flux;
use Astro::Fluxes;
use Astro::FluxColor;
use Number::Uncertainty;

BEGIN {
  # load modules
  use_ok("Astro::Catalog::Item");
  use_ok("Astro::Catalog");
  use_ok("Astro::Catalog::Query::USNOA2");
}

# Load the generic test code
my $p = ( -d "t" ?  "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";


# Grab USNO-A2 sample from the DATA block
my @buffer = <DATA>;
chomp @buffer;

# test catalog
my $catalog_data = new Astro::Catalog();

# create a temporary object to hold stars
my $star;

# Parse data block
foreach my $line (0 .. $#buffer) {
   # split each line
   my @separated = split( /\s+/, $buffer[$line] );

   # check that there is something on the line
   if (defined $separated[0]) {
       # create a temporary place holder object
       $star = new Astro::Catalog::Item();

       # ID
       my $id = $separated[2];
       $star->id($id);

       # RA
       my $objra = "$separated[3] $separated[4] $separated[5]";

       # Dec
       my $objdec = "$separated[6] $separated[7] $separated[8]";

       $star->coords( new Astro::Coords(
                   name => $id,
                   ra => $objra,
                   dec => $objdec,
                   units => 'sex',
                   type => 'J2000',
               ));

       # Quality
       my $quality = $separated[11];
       $star->quality($quality);

       # Field
       my $field = $separated[12];
       $star->field($field);

       # GSC
       my $gsc = $separated[13];
       if ($gsc eq "+") {
          $star->gsc("TRUE");
       }
       else {
          $star->gsc("FALSE");
       }

       # Distance
       my $distance = $separated[14];
       $star->distance($distance);

       # Position Angle
       my $pos_angle = $separated[15];
       $star->posangle($pos_angle);
    }


    # Calculate error

    my ($power, $delta_r, $delta_b);

    # delta.R
    $power = 0.8 * ($separated[9] - 19.0);
    $delta_r = 0.15 * ((1.0 + (10.0 ** $power)) ** (1.0 / 2.0));

    # delta.B
    $power = 0.8 * ($separated[10] - 19.0);
    $delta_b = 0.15 * ((1.0 + (10.0 ** $power)) ** (1.0 / 2.0));

    # calcuate B-R colour and error

    my $b_minus_r = $separated[10] - $separated[9];

    # delta.(B-R)
    my $delta_bmr = (($delta_r ** 2.0) + ($delta_b ** 2.0)) ** (1.0 / 2.0);

    # Build the fluxes object

    $star->fluxes(new Astro::Fluxes(
                new Astro::Flux(
                    new Number::Uncertainty(
                        Value => $separated[9],
                        Error => $delta_r ),
                    'mag', "R"),
                new Astro::Flux(
                    new Number::Uncertainty(
                        Value => $separated[10],
                        Error => $delta_b),
                    'mag', "B" ),
                new Astro::FluxColor(
                    lower => "R",
                    upper => "B",
                    quantity => new Number::Uncertainty(
                        Value => $b_minus_r,
                        Error => $delta_bmr) ),
                ));

    # Push the star into the catalog
    $catalog_data->pushstar($star);

}

# field centre
$catalog_data->fieldcentre(
        RA => '01 10 13.1', Dec => '+60 04 35.4', Radius => '1');


# Grab comparison from ESO/ST-ECF Archive Site

my $usno_byname = new Astro::Catalog::Query::USNOA2(
        Target => 'HT Cas',
        Radius => '1');

SKIP: {
    print "# Connecting to ESO/ST-ECF USNO-A2 Catalogue\n";
    my $catalog_byname = eval {
        $usno_byname->querydb();
    };

    unless (defined $catalog_byname) {
        diag('Cannot connect to USNO-A2: ' . $@);
        skip 'Cannot connect', 348
    }

    unless ($catalog_byname->sizeof() > 0) {
        diag('No items retrieved from USNO-A2');
        skip 'No items retrieved', 348
    }

    print "# Continuing tests\n";

    # check sizes
    print "# DAT has " . $catalog_data->sizeof() . " stars\n";
    print "# NET has " . $catalog_byname->sizeof() . " stars\n";

    # Now compare the stars in the catalogues in order
    compare_catalog( $catalog_byname, $catalog_data);
}

exit;

# nr ID              ra           dec        r_mag b_mag  q field gsc    d'     pa
__DATA__
   1 U1500_01193693  01 10 08.76 +60 05 10.2  16.2  18.8   0 00080  -   0.793 316.988
   2 U1500_01194083  01 10 10.31 +60 04 42.4  18.2  19.6   0 00080  -   0.367 288.521
   3 U1500_01194433  01 10 11.62 +60 04 49.8  17.5  18.8   0 00080  -   0.303 322.442
   4 U1500_01194688  01 10 12.60 +60 04 14.3  13.4  14.6   0 00080  -   0.357 190.009
   5 U1500_01194713  01 10 12.67 +60 04 26.8  17.6  18.2   0 00080  -   0.153 200.521
   6 U1500_01194715  01 10 12.68 +60 04 43.0  17.8  18.9   0 00080  -   0.137 337.466
   7 U1500_01194794  01 10 12.95 +60 04 36.2  16.1  16.4   0 00080  -   0.023 307.226
   8 U1500_01195060  01 10 13.89 +60 05 28.7  18.1  19.1   0 00080  -   0.894   6.318
   9 U1500_01195140  01 10 14.23 +60 05 25.5  16.5  17.9   0 00080  -   0.846   9.563
  10 U1500_01195144  01 10 14.26 +60 04 38.1  18.4  19.5   0 00080  -   0.151  72.472
  11 U1500_01195301  01 10 14.83 +60 04 19.1  14.2  16.8   0 00080  -   0.347 141.668
  12 U1500_01195521  01 10 15.71 +60 04 43.8  18.7  19.6   0 00080  -   0.354  66.790
  13 U1500_01195912  01 10 17.30 +60 05 22.1  14.1  16.9   0 00080  -   0.937  33.929
  14 U1500_01196088  01 10 18.00 +60 04 37.1  15.1  17.7   0 00080  -   0.611  87.287
  15 U1500_01196555  01 10 20.00 +60 04 12.3  18.2  19.1   0 00080  -   0.943 114.060
