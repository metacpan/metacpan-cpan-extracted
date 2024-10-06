#! perl

use Test2::V0;
use Test::TypeTiny;
use List::Util qw( shuffle zip );

use CXC::Astro::Regions::CIAO::Types -all;

# Angle doesn't do much
subtest Angle => sub {
    should_pass( 22, Angle );
    should_fail( q{}, Angle );
};

subtest Length => sub {
    my @lengths = ( 22.3, q{22.3"}, q{22.3'}, q{22.3d} );

    should_pass( $_, Length ) for @lengths;
};

subtest Position => sub {
    my @XPosition = qw( 22.3 22.3d 10:20:30.22 );

    subtest XPosition => sub {
        should_pass( $_, XPosition ) for @XPosition;
        should_fail( $_, XPosition ) for qw( 10h20m30s 10h20m30.22s );
    };

    my @YPosition = qw( 22.3 22.3d -89:20:20.2  );

    subtest YPosition => sub {
        should_pass( $_, YPosition ) for @YPosition;
        should_fail( $_, YPosition ) for qw( 180:20:30 180d20m30s 180:20:30.22 180d20m30.22s );
    };

    subtest Vertex => sub {
        should_pass( $_, Vertex ) for zip [ shuffle @XPosition ], [ shuffle @YPosition ];
    };
};

done_testing;
