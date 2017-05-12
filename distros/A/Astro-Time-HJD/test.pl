# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 11 };
BEGIN{ use_ok( 'Astro::Time::HJD' ) };

#########################

my ($correction, $jd, $hjd )
   = Astro::Time::HJD::correction( 2452425.6907291, 179.470833, 6.375277 );
ok( abs($correction - 0.001745) < (1 / 864000), 'Calc within .1 second' ) or
   diag( "$correction vs actual of 0.001745" );
ok( $jd == 2452425.6907291, 'Julian Date same as went in' ) or
   diag( "$jd returned doesn't match what went in" );
ok( ($hjd - 2452425.6924741) < (1 / 864000), 'Correction properly applied' ) or
   diag( "$correction not properly applied to $jd" );

$hjd = 2452425.6907291
       + Astro::Time::HJD::correction( 2452425.6907291, 179.470833, 6.375277 );

ok( ($hjd - 2452425.6924741) < (1 / 864000), 'Scalar properly returned' ) or
   diag( 'Single scalar not properly returned' );

use Astro::Time::HJD qw( correction );

($correction, $jd, $hjd )
   = correction( '2002-06-01T08:30:00', 
                 188.73625,
                 -54.5361111111111 );
ok( abs($correction - 0.0033495) < (1 / 864000), 'Calc within .1 second' ) or
   diag( "$correction vs actual of 0.0033495" );
ok( abs($jd - 2452426.85416667) < 1e-8, 'Julian Date correctly calculated' ) or
   diag( "$jd returned doesn't match what went in" );
ok( abs($hjd - 2452426.8575160364) < (1 / 864000),
    'Correction properly applied' ) or
   diag( "$correction not properly applied to $jd" );

#
# RA/DEC location is location of sun on the date given.  First correction,
# should make the observation 'earlier', while the second should make the
# observation 'later' (RA/DEC is 'opposite' the first
my ($correction1, $jd1l, $hjd1 )
   = correction( '2002-07-09T21:24:00', 
                 108.95,
                 22.297 );

my ($correction2, $jd2, $hjd2 )
   = correction( '2002-07-09T21:24:00', 
                 288.95,
                 -22.297 );

ok( $correction1 < 0, "Correction 1 has correct sign" ) or
   diag( "$correction1 should be < 0" );
ok( $correction2 > 0, "Correction 2 has correct sign" ) or
   diag( "$correction1 should be > 0" );
ok( abs($correction1 + $correction2) < 1e-8,
    "'Opposite' observations are opposite" ) or
   diag( "$correction1 is not opposite $correction2" );
