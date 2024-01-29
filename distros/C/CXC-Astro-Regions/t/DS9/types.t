#! perl

use Test2::V0;
use Test::TypeTiny;
use List::Util qw( shuffle zip );

use CXC::Astro::Regions::DS9::Types -all;

# Angle doesn't do much
subtest Angle => sub {
    should_pass( 22, Angle );
    should_fail( q{}, Angle );
};

subtest CoordSys => sub {
    should_pass( 'amplifier', CoordSys );
    should_fail( 'AmPlIfIeR', CoordSys );

    should_pass( $_, CoordSys )
      for 'amplifier',
      'detector',
      'ecliptic',
      'fk4',
      'fk5',
      'galactic',
      'icrs',
      'image',
      'linear',
      'physical',
      ;

    is( CoordSys->assert_coerce( 'AmPlIfIeR' ), 'amplifier', 'coerce q{AmPlIfIeR}' );
};

subtest Length => sub {
    my @lengths = ( 22.3, q{22.3"}, q{22.3'}, q{22.3d}, q{22.3r}, q{22.3p}, q{22.3i} );

    should_pass( $_, Length ) for @lengths;
    should_pass( $_, LengthPair ) for zip \@lengths, [ shuffle @lengths ];
};

subtest OneZero => sub {
    should_pass( 1, OneZero );
    should_pass( 0, OneZero );

    should_fail( q{}, OneZero );
    should_fail( 3,   OneZero );

    is( OneZero->assert_coerce( q{} ), 0, 'coerce q{}' );
    is( OneZero->assert_coerce( 3 ),   1, 'coerce q{3}' );
};

subtest PointType => sub {
    should_pass( $_, PointType ) for qw( circle box diamond cross x arrow boxcircle );
    is( PointType->assert_coerce( 'CiRcLe' ), 'circle', 'coerce q{CiRcLe}' );
};

subtest RuleCoords => sub {
    should_pass( $_, RulerCoords ) for qw[pixels degrees arcmin arcsec];
    is( RulerCoords->assert_coerce( 'PiXeLs' ), 'pixels', 'coerce q{PiXeLs}' );
};


subtest Position => sub {
    my @XPos = qw( 22.3 22.3d 22.3r 22.3p 22.3i
      10:20:30 10h20m30s 10:20:30.22  10h20m30.22s
    );

    my @YPos = qw( 22.3 22.3d 22.3r 22.3p 22.3i
      180:20:30 180d20m30s 180:20:30.22 180d20m30.22s
    );

    subtest XPos => sub {
        should_pass( $_, XPos ) for @XPos;
        should_fail( '180d20m30s', XPos );
    };

    subtest YPos => sub {
        should_pass( $_, YPos ) for @YPos;
        should_fail( '10h20m30s', YPos );
    };

    subtest Vertex => sub {
        should_pass( $_, Vertex ) for zip [ shuffle @XPos ], [ shuffle @YPos ];
    };
};

done_testing;
