package main;

use strict;
use warnings;

use Test::More 0.88;

use Astro::Coord::ECI::TLE qw{ :constants };

my $tle = Astro::Coord::ECI::TLE->new();

note '';

note 'Test derivation of body type from name';

ok( $tle->body_type() == BODY_TYPE_UNKNOWN,
    'TLE without name is unknown body type' );

test_body_type( $tle, 'Misc deb', BODY_TYPE_DEBRIS );

test_body_type( $tle, 'Miscellaneous debris', BODY_TYPE_DEBRIS );

test_body_type( $tle, 'Dumped coolant', BODY_TYPE_DEBRIS );

test_body_type( $tle, 'Ejected shroud', BODY_TYPE_DEBRIS );

test_body_type( $tle, 'Westford needles', BODY_TYPE_DEBRIS );

test_body_type( $tle, 'R/B debris', BODY_TYPE_DEBRIS );

test_body_type( $tle, 'Delta R/B', BODY_TYPE_ROCKET_BODY );

test_body_type( $tle, 'Foosat akm', BODY_TYPE_ROCKET_BODY );

test_body_type( $tle, 'Foosat pkm', BODY_TYPE_ROCKET_BODY );

test_body_type( $tle, 'Foosat', BODY_TYPE_PAYLOAD );

test_body_type( $tle, 'Debut', BODY_TYPE_PAYLOAD );

note '';

note 'Test explicitly setting portions of international designator';

$tle->set( launch_year => 13, launch_num => 2, launch_piece => 'b' );

cmp_ok $tle->get( 'launch_year' ), '==', 2013,
    'Launch year, set individually';

cmp_ok $tle->get( 'launch_num' ), '==', 2,
    'Launch number, set individually';

is $tle->get( 'launch_piece' ), 'B',
    'Launch piece, set individually';

is $tle->get( 'international' ), '13002B',
    'International launch designator, from individual fields';

$tle->set( launch_year	=> undef );

is $tle->get( 'international' ), '  002B',
    'Result of making launch_year undef';

note <<'EOD';

The following tests UNSUPPORTED AND EXPERIMENTAL functionality.

EOD

is $tle->__list_type(), 'inertial', q<Initial list type is 'inertial'>;

$tle->set( model => 'null' );

$tle->universal( time );

$tle->ecef( 1000, 1000, 1000 );

is $tle->__list_type(), 'fixed',
    q<Setting fixed coordinates makes the list type 'fixed'>;

$tle->eci( 1000, 1000, 1000 );

is $tle->__list_type(), 'inertial',
    q<Setting inertial coordinates makes the list type 'inertial'>;

done_testing;

sub test_body_type {	## no critic (RequireArgUnpacking)
    my ( $body, $name, $want ) = @_;
    $body->set( name => $name );
    @_ = ( eval { $body->body_type() } == $want,
	"Name '$name' represents $want" );
    goto &ok;
}

1;

# ex: set textwidth=72 :
