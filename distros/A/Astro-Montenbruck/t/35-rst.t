
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 0.1;
use Math::Trig qw/deg2rad/;
use Astro::Montenbruck::MathUtils qw/ddd dms frac/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids/;
use Astro::Montenbruck::RiseSet;

BEGIN {
    use_ok( 'Astro::Montenbruck::RiseSet::Constants', qw/:events :states/ );
    use_ok( 'Astro::Montenbruck::RiseSet::Plarise', qw/rst_func/ );
}


subtest 'Meeus Venus example' => sub {
    plan tests => 3;
    my %cases = (
        $EVT_RISE    => ddd( 12, 25 ),
        $EVT_TRANSIT => ddd( 19, 41 ),
        $EVT_SET     => ddd( 2,  55 )
    );

    my $func = rst_func(
        date   => [1988, 3, 20],
        phi    => 42.3333,
        lambda => 71.0833,
    )->(
        get_position => sub { Astro::Montenbruck::RiseSet::_get_equatorial( $VE, $_[0] ) },
        sin_h0       => sin( deg2rad(-34 / 60) ),
    );    

    for my $evt ( @RS_EVENTS) {
        my $case = $cases{$evt};
        my ($state, $jd) = $func->($evt);
        my $ut = frac( $jd - 0.5 ) * 24;
        delta_ok( $ut, $case,
            sprintf( '%s %s at %02d:%02d', $VE, $evt, dms( $case, 2 ) )
        );
    }
};

done_testing();
