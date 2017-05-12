# -*-perl-*-
#
# The tests in this file are essentially "internal" tests: they
# check that the results are consistent (eg da = dl/(1+z)^2)
# but do not check that the dl is actually correct
# (there are checks against a set of numbers, but as they were
# calculated by an early version of this module they are only
# really a regression test).
#
# see t/cosmology2.t and the scripts in cpt/ and hogg/
# for external checks
#
# NOTE:
#  the volume code is not really tested here
#

use strict;
use Test;

use PDL;

plan tests => 43;

$|++;

# test fuctions

my $debug = 0;
#my $debug = 1;

# arbitrary value
my $abstol = 1.05e-5;

sub check0 ($) {
    my $result = shift;
    my $answer;
    if ( ref($result) ) { # ie assume a piddle
	$answer = abs(sum($result));
    } else {
	$answer = abs($result);
    }
    ok( $answer <= $abstol );
    print "  [ $answer ]\n" if $debug;
}

sub checks ($$) {
    my $str1 = shift;
    my $str2 = shift;

    ok( $str1 eq $str2 );
    print "  [ <$str1> <$str2> ]\n" if $debug;
}

## to the tests

# can we load the module?
eval "use Astro::Cosmology qw( :Func );";
ok( $@ ? 0 : 1 );

## try and create an "empty subclass" (man perltoot)

package Bob;

use Astro::Cosmology;
no strict;
@ISA = ( "Astro::Cosmology" );

package main;
use strict;

## back to testing

my $z = pdl( [ 0.5, 1.0, 2.0 ] );

my $eds = Astro::Cosmology->new;
my $sn  = Astro::Cosmology->new( matter => 0.3, lambda => 0.7, h => 70 );
my $opn = Astro::Cosmology->new( matter => 0.3, lambda => 0, h => 70 );

## simple check of the version command
print "Testing Astro::Cosmology version: ", $eds->version, "\n";
checks( Astro::Cosmology->version, $eds->version );

# check the subclass works
my $subclass = Bob->new( matter => 0.3, lambda => 0.7, h => 70 );
checks( "$sn", "$subclass" ); # need the quotes to stringify the objects

# test the values stored in the objects
ok( $eds->h0(), 50.0 );
ok( $sn->omega_lambda, 0.7 );
ok( $subclass->omega_lambda, 0.7 );

# repeat, using different names
ok( $eds->hO(), 50.0 );
ok( $sn->lambda, 0.7 );

## now check the calculations themselves

# first just check that z=0 does give zero
check0( $eds->lum_dist(0) - 0 );
check0( $sn->lum_dist(0) - 0 );
check0( $opn->lum_dist(0) - 0 );

check0( $eds->comov_vol(0) - 0 );
check0( $sn->comov_vol(0) - 0 );
check0( $opn->comov_vol(0) - 0 );

check0( $eds->dcomov_vol(0) - 0 );
check0( $sn->dcomov_vol(0) - 0 );
check0( $opn->dcomov_vol(0) - 0 );

check0( $eds->lookback_time(0) - 0 );
check0( $sn->lookback_time(0) - 0 );
check0( $opn->lookback_time(0) - 0 );

check0( $eds->lookback_time(0,0) - 0 );
check0( $sn->lookback_time(0,0) - 0 );
check0( $opn->lookback_time(0,0) - 0 );

# now a bit more sensible checks

my $dl_eds = $eds->lum_dist( $z );
my $dl_sn  = $sn->lum_dist( $z );
my $dl_opn = $opn->lum_dist( $z );

# check the "aliases" work
check0( $dl_eds - $eds->luminosity_distance($z) );
check0( $dl_sn  - $sn->luminosity_distance($z)  );
check0( $dl_opn - $opn->luminosity_distance($z)  );

# check we can call without the OO syntax
check0( $dl_eds - lum_dist($eds,$z) );
check0( $dl_sn  - lum_dist($sn,$z)  );
check0( $dl_opn - lum_dist($opn,$z)  );
check0( $dl_eds - luminosity_distance($eds,$z) );
check0( $dl_sn  - luminosity_distance($sn,$z)  );
check0( $dl_opn - luminosity_distance($opn,$z)  );

# not really a fair check, as calculated these using this module
my $dl_eds_ans = pdl( [3300.7765, 7024.5742, 15204.864] );
my $dl_sn_ans  = pdl( [2832.9381, 6607.6576, 15539.587] );
my $dl_opn_ans = pdl( [2565.1861, 5872.2944, 14242.634] );

# going for a percentage check here
check0( 100.0 * ($dl_eds - $dl_eds_ans) / $dl_eds_ans );
check0( 100.0 * ($dl_sn  - $dl_sn_ans) / $dl_sn_ans  );
check0( 100.0 * ($dl_opn - $dl_opn_ans) / $dl_opn_ans  );

my $zp1_sq = (1.0 + $z) * (1.0 + $z);
check0( 100.0 * ($dl_eds/$zp1_sq - $eds->angular_diameter_distance($z)) / $eds->adiam_dist($z) );
check0( 100.0 * ($dl_sn/$zp1_sq  - $sn->angular_diameter_distance($z))  / $sn->adiam_dist($z)  );
check0( 100.0 * ($dl_opn/$zp1_sq - $opn->angular_diameter_distance($z))  / $opn->adiam_dist($z)  );

my $dt_eds = $eds->lookback_time( $z );
my $dt_sn  = $sn->lookback_time( $z );
my $dt_opn = $opn->lookback_time( $z );

my $dt_eds_ans = pdl( [5.9407884e+09, 8.4280545e+09, 1.052844e+10] );
my $dt_sn_ans  = pdl( [5.0407463e+09, 7.7155029e+09, 1.0240577e+10] );
my $dt_opn_ans = pdl( [4.514814e+09, 6.6254651e+09, 8.5750495e+09] );

check0( 100.0 * ($dt_eds - $dt_eds_ans) / $dt_eds_ans );
check0( 100.0 * ($dt_sn  - $dt_sn_ans) / $dt_sn_ans );
check0( 100.0 * ($dt_opn - $dt_opn_ans) / $dt_opn_ans );

# can we change the sn model to equal the open model ?
$sn->lambda( 0 );
check0( $sn->lum_dist( $z ) - $opn->lum_dist( $z ) );
$sn->lambda( 0.7 ); # go back to a flat cosmology

# check that one of the constants is correct
# (temporary test, remove when constants are removed from module)
# (need to fully qualify the constant since load module using
#  an eval)
ok( 299792458, Astro::Cosmology::LIGHT );

## End of the test
exit;

