
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 0.1;
use Math::Trig qw/deg2rad/;
use Astro::Montenbruck::MathUtils qw/dms ddd frac/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids/;
use Astro::Montenbruck::RiseSet;

BEGIN {
    use_ok( 'Astro::Montenbruck::RiseSet::Constants', qw/:events :states :altitudes/ );
    use_ok( 'Astro::Montenbruck::RiseSet::Sunset', qw/riseset/ );
}

subtest 'Sun & Moon, normal conditions' => sub {
    my ( $lat, $lng ) = ( 48.1, -11.6 );

    my @cases = (
        {
            date => [ 1989, 3, 23 ],
            $MO  => {
                $EVT_RISE => [ 18, 57 ],
                $EVT_SET  => [ 5,  13 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  11 ],
                $EVT_SET  => [ 17, 30 ],
            },
        },
        {
            date => [ 1989, 3, 24 ],
            $MO  => {
                $EVT_RISE => [ 20, 5 ],
                $EVT_SET  => [ 5,  28 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  9 ],
                $EVT_SET  => [ 17, 32 ],
            },
        },
        {
            date => [ 1989, 3, 25 ],
            $MO  => {
                $EVT_RISE => [ 21, 15 ],
                $EVT_SET  => [ 5,  45 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  7 ],
                $EVT_SET  => [ 17, 33 ],
            },
        },
        {
            date => [ 1989, 3, 26 ],
            $MO  => {
                $EVT_RISE => [ 22, 26 ],
                $EVT_SET  => [ 6,  6 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  5 ],
                $EVT_SET  => [ 17, 35 ],
            },
        },
        {
            date => [ 1989, 3, 27 ],
            $MO  => {
                $EVT_RISE => [ 23, 34 ],
                $EVT_SET  => [ 6,  33 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  2 ],
                $EVT_SET  => [ 17, 36 ],
            },
        },
        {
            date => [ 1989, 3, 28 ],
            $MO  => {
                set => [ 7, 9 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  0 ],
                $EVT_SET  => [ 17, 38 ],
            },
        },
        {
            date => [ 1989, 3, 29 ],
            $MO  => {
                $EVT_RISE => [ 0, 38 ],
                $EVT_SET  => [ 7, 58 ],
            },
            $SU => {
                $EVT_RISE => [ 4,  58 ],
                $EVT_SET  => [ 17, 39 ],
            },
        },
        {
            date => [ 1989, 3, 30 ],
            $MO  => {
                $EVT_RISE => [ 1, 31 ],
                $EVT_SET  => [ 9, 0 ],
            },
            $SU => {
                $EVT_RISE => [ 4,  56 ],
                $EVT_SET  => [ 17, 41 ],
            },
        },
        {
            date => [ 1989, 3, 31 ],
            $MO  => {
                $EVT_RISE => [ 2,  14 ],
                $EVT_SET  => [ 10, 14 ],
            },
            $SU => {
                $EVT_RISE => [ 4,  54 ],
                $EVT_SET  => [ 17, 42 ],
            },
        },
        {
            date => [ 1989, 4, 1 ],
            $MO  => {
                $EVT_RISE => [ 2,  47 ],
                $EVT_SET  => [ 11, 35 ],
            },
            $SU => {
                $EVT_RISE => [ 4,  52 ],
                $EVT_SET  => [ 17, 43 ],
            },
        },
    );

    my %h0 = (
        $SU => $H0_SUN,
        $MO => $H0_MOO
    );

    for my $case (@cases) {
        for my $pla ( $MO, $SU ) {
            riseset(
                date   => $case->{date},
                phi    => $lat,
                lambda => $lng,
                get_position => sub { Astro::Montenbruck::RiseSet::_get_equatorial( $pla, $_[0] ) },
                sin_h0       => sin( deg2rad($h0{$pla}) ),
                on_event => sub {
                    my ($evt, $ut) = @_;
                    my @hm  = @{ $case->{$pla}->{$evt} };
                    delta_ok( $ut, ddd(@hm),
                        sprintf( '%s %s: %02d:%02d', $pla, $evt, @hm )
                    );
                },
                on_noevent => sub { fail("$pla: event expected") }
            );
        }
    }
    done_testing();
};

done_testing();
