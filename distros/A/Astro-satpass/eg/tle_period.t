package main;

# This script is not really a test, but is intended to demonstrate the
# effect of the model chosen on the calculation of the satellite's
# period. It is run from the distribution directory as
#
#   perl -Mblib eg/tle_period.t
#
# It needs as input the TLE file used to test sgp4r.

use strict;
use warnings;

use Astro::Coord::ECI::TLE;
use Test::More 0.88;

my $tle_file = 't/sgp4-ver.tle';
unless ( -f $tle_file ) {
    diag <<'EOD';

Because I do not have authority to distribute TLE data, I have not
included sgp4-ver.tle in this kit. A copy is contained in
http://celestrak.com/publications/AIAA/2006-6753/AIAA-2006-6753.zip

If you wish to run this test, obtain and unzip the file, and place
sgp4-ver.tle in the t directory.

EOD
    plan skip_all => "$tle_file not available";
    exit;
}

my @satrecs;
{
    local $/ = undef;	# Slurp mode.
    open (my $fh, '<', $tle_file) or die "Failed to open $tle_file: $!";
    my $data = <$fh>;
    close $fh;
    @satrecs = Astro::Coord::ECI::TLE->parse ($data);
}

my $tolerance = 1;

print <<eod;
#
# This file does not really test anything, as I have no comparison data.
# What it does is to demonstrate the effect of the model used on the
# period calculated for a given satellite.
#
eod

my @gravconst = (72, 84);
my @max_delta = (0) x 2;
foreach my $tle (@satrecs) {
    my $oid = $tle->get ('id');
    $tle->set (model => 'model4');
    my $want = $tle->period ();
    $tle->set (model => 'model');
    foreach my $inx (0 .. 1) {
	my $const = $gravconst[$inx];
	$tle->set (gravconst_r => $const);
	my $got = $tle->period ();
	my $delta = $want - $got;
	my $title = <<"EOD";
OID $oid period, gravconst_r = $const
      Got: $got (new calculation)
     Want: $want (old calculation)
    Delta: $delta
Tolerance: $tolerance
EOD
	cmp_ok abs( $delta ), '<', $tolerance, $title;
	abs $delta > abs ($max_delta[$inx]) and $max_delta[$inx] = $delta;
    }
}

note <<"EOD";

Maximum delta by gravconst_r:
    $gravconst[0] => $max_delta[0]
    $gravconst[1] => $max_delta[1]
EOD

done_testing;

1;

# ex: set textwidth=72 :
