package main;

use 5.008;

use strict;
use warnings;

use Astro::Coord::ECI::VSOP87D::Sun;
use Test::More 0.88;	# Because of done_testing();

my %cutoff_def = (
    'Meeus' => {
	'B0' => 5,
	'B1' => 1,
	'L0' => 64,
	'L1' => 34,
	'L2' => 20,
	'L3' => 7,
	'L4' => 3,
	'L5' => 1,
	'R0' => 40,
	'R1' => 10,
	'R2' => 6,
	'R3' => 2,
	'R4' => 1,
	'name' => 'Meeus',
    },
    'none' => {
	'B0' => '184',
	'B1' => '99',
	'B2' => '49',
	'B3' => '11',
	'B4' => '5',
	'L0' => '559',
	'L1' => '341',
	'L2' => '142',
	'L3' => '22',
	'L4' => '11',
	'L5' => '5',
	'R0' => '526',
	'R1' => '292',
	'R2' => '139',
	'R3' => '27',
	'R4' => '10',
	'R5' => '3',
	'name' => 'none',
    },
    'twenty_five' => {	# Cut off at 25e-8
	'B0' => 5,
	'L0' => 63,
	'L1' => 15,
	'L2' => 4,
	'L3' => 2,
	'L4' => 1,
	'R0' => 39,
	'R1' => 5,
	'R2' => 2,
	'R3' => 1,
	'name' => 'twenty_five',
    },
);

my $sun = Astro::Coord::ECI::VSOP87D::Sun->new();

is $sun->get( 'model_cutoff' ), 'Meeus', q<Default model cutoff is 'Meeus'>;

is_deeply $sun->model_cutoff_definition(), $cutoff_def{Meeus},
    q<model_cutoff_definition() returns 'Meeus' definition>;

is_deeply $sun->model_cutoff_definition( 'Meeus' ), $cutoff_def{Meeus},
    q<model_cutoff_definition( 'Meeus' ) returns 'Meeus' definition>;

$sun->set( model_cutoff => 'none' );
note q<cutoff changed to 'none'>;

is_deeply $sun->model_cutoff_definition(), $cutoff_def{none},
    q<model_cutoff_definition() now returns 'none' definition>;

$sun->model_cutoff_definition( twenty_five => $cutoff_def{twenty_five} );

is_deeply $sun->model_cutoff_definition( 'twenty_five' ),
    $cutoff_def{twenty_five},
    q<Able to define model cutoff 'twenty_five'>;

$sun->model_cutoff_definition( twenty_five => undef );

is_deeply $sun->model_cutoff_definition( 'twenty_five' ), undef,
    q<Able to undefine model cutoff 'twenty_five'>;

$sun->model_cutoff_definition( twenty_five => \&code_twenty_five );

is_deeply $sun->model_cutoff_definition( 'twenty_five' ),
    $cutoff_def{twenty_five},
    q<Able to define model cutoff 'twenty_five' procedurally>;

$sun->model_cutoff_definition( twenty_five => undef );

is_deeply $sun->model_cutoff_definition( 'twenty_five' ), undef,
    q<Make sure 'twenty_five' is gone>;

$sun->model_cutoff_definition( twenty_five => 25e-8 );

is_deeply $sun->model_cutoff_definition( 'twenty_five' ),
    $cutoff_def{twenty_five},
    q<Able to define model cutoff 'twenty_five' by minimum coefficient value>;

$sun->model_cutoff_definition( twenty_five => 25e-8 );

done_testing;

sub code_twenty_five {
    my ( @model ) = @_;
    my %cutoff;
    foreach my $series ( @model ) {
	my $count = 0;
	foreach my $term ( @{ $series->{terms} } ) {
	    last if $term->[0] < 25e-8;
	    $count++;
	}
	$count
	    and $cutoff{$series->{series}} = $count;
    }
    return \%cutoff;
}

1;

# ex: set textwidth=72 :
