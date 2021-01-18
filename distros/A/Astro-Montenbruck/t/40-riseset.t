
#!/usr/bin/env perl -w
use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 0.1;
use Astro::Montenbruck::MathUtils qw/ddd dms frac/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids @PLANETS/;

BEGIN {
    use_ok( 'Astro::Montenbruck::RiseSet::Constants', qw/:events :states/ );
    use_ok( 'Astro::Montenbruck::RiseSet',            qw/:all/ );
}

subtest 'Rise, Set, Transit, normal conditions' => sub {
    my @cases = (
        {
            id           => $SU,
            $EVT_RISE    => [ 7,  4 ],
            $EVT_TRANSIT => [ 11, 16 ],
            $EVT_SET     => [ 15, 29 ]
        },
        {
            id           => $ME,
            $EVT_RISE    => [ 6,  33 ],
            $EVT_TRANSIT => [ 10, 37 ],
            $EVT_SET     => [ 14, 41 ]
        },
        {
            id           => $VE,
            $EVT_RISE    => [ 3,  52 ],
            $EVT_TRANSIT => [ 8,  30 ],
            $EVT_SET     => [ 13, 8 ]
        },
        {
            id           => $MA,
            $EVT_RISE    => [ 9,  33 ],
            $EVT_TRANSIT => [ 14, 35 ],
            $EVT_SET     => [ 19, 37 ]
        },
        {
            id           => $JU,
            $EVT_RISE    => [ 11, 29 ],
            $EVT_TRANSIT => [ 18, 10 ],
            $EVT_SET     => [ 0,  55 ]
        },
        {
            id           => $SA,
            $EVT_RISE    => [ 12, 9 ],
            $EVT_TRANSIT => [ 19, 10 ],
            $EVT_SET     => [ 2,  14 ]
        },
        {
            id           => $UR,
            $EVT_RISE    => [ 9,  2 ],
            $EVT_TRANSIT => [ 13, 45 ],
            $EVT_SET     => [ 18, 28 ]
        },
        {
            id           => $NE,
            $EVT_RISE    => [ 8,  25 ],
            $EVT_TRANSIT => [ 12, 57 ],
            $EVT_SET     => [ 17, 29 ]
        },
        {
            id           => $PL,
            $EVT_RISE    => [ 4,  11 ],
            $EVT_TRANSIT => [ 9,  22 ],
            $EVT_SET     => [ 14, 32 ]
        },
    );

    my $func = rst(
        date   => [ 1999, 12, 31 ],
        phi    => 48.1,
        lambda => -11.6
    );

    for my $case (@cases) {
        $func->(
            $case->{id},
            on_event => sub {
                my ( $evt, $jd ) = @_;
                my $ut = frac( $jd - 0.5 ) * 24;
                my @hm = @{ $case->{$evt} };
                delta_ok( $ut, ddd(@hm),
                    sprintf( '%s %s: %02d:%02d', $case->{id}, $evt, @hm ) );
            },
            on_noevent => sub {
                fail("$case->{id}: event expected");
            }
        );
    }

    done_testing();
};

subtest 'Twilight, normal conditions' => sub {
    my ( $lat, $lng ) = ( 48.1, -11.6 );
    my @cases = (
        {
            date      => [ 1989, 3, 23 ],
            $EVT_RISE => [ 4,    3 ],
            $EVT_SET  => [ 18,   39 ],
        },
        {
            date      => [ 1989, 3, 24 ],
            $EVT_RISE => [ 4,    1 ],
            $EVT_SET  => [ 18,   40 ],
        },
        {
            date      => [ 1989, 3, 25 ],
            $EVT_RISE => [ 3,    59 ],
            $EVT_SET  => [ 18,   42 ],
        },
        {
            date      => [ 1989, 3, 26 ],
            $EVT_RISE => [ 3,    56 ],
            $EVT_SET  => [ 18,   44 ],
        },
        {
            date      => [ 1989, 3, 27 ],
            $EVT_RISE => [ 3,    54 ],
            $EVT_SET  => [ 18,   45 ],
        },
        {
            date      => [ 1989, 3, 28 ],
            $EVT_RISE => [ 3,    52 ],
            $EVT_SET  => [ 18,   47 ],
        },
        {
            date      => [ 1989, 3, 29 ],
            $EVT_RISE => [ 3,    50 ],
            $EVT_SET  => [ 18,   48 ],
        },
        {
            date      => [ 1989, 3, 30 ],
            $EVT_RISE => [ 3,    48 ],
            $EVT_SET  => [ 18,   50 ],
        },
        {
            date      => [ 1989, 3, 31 ],
            $EVT_RISE => [ 3,    45 ],
            $EVT_SET  => [ 18,   52 ],
        },
        {
            date      => [ 1989, 4, 1 ],
            $EVT_RISE => [ 3,    43 ],
            $EVT_SET  => [ 18,   53 ],
        },
    );

    for my $case (@cases) {
        twilight(
            date     => $case->{date},
            phi      => $lat,
            lambda   => $lng,
            on_event => sub {
                my ( $evt, $jd ) = @_;
                my $ut = frac( $jd - 0.5 ) * 24;
                my @hm = @{ $case->{$evt} };
                delta_ok( $ut, ddd(@hm),
                    sprintf( '%s: %02d:%02d', $evt, @hm ) );
            },
            on_noevent => sub {
                fail("Event expected at date $case->{date}");
            }
        );
    }
    done_testing();
};

subtest 'Twilight, extreme latitude' => sub {
    plan tests => 1;
    my ( $lat, $lng ) = ( 80.0, -10.0 );
    my @date = ( 1989, 6, 19 );
    twilight(
        date     => \@date,
        phi      => $lat,
        lambda   => $lng,
        on_event => sub {
            fail("Event not expected at high latitude ($lat)");
        },
        on_noevent => sub {
            my $state = shift;
            cmp_ok( $state, 'eq', $STATE_CIRCUMPOLAR );
        }
    );
};

done_testing();
