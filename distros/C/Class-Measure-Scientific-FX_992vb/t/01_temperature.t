use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 37;

sub iz {
    my ( $got, $exp, $msg ) = @_;
    my $FMT = q{%.15g};
    return is( sprintf( $FMT, $got ), sprintf( $FMT, $exp ), $msg );
}

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->temperature( 0, 'C' );
iz( $m->C(),                     0,      q{0 degree Celsius} );
iz( $m->K(),                     273.15, q{0 degree Celsius in Kelvin} );
iz( sprintf( q{%.0f}, $m->F() ), 32,     q{0 degree Celsius in Fahrenheit} );
$m = Class::Measure::Scientific::FX_992vb->temperature( 1, 'C' );
iz( $m->C(),                     1,      q{1 degree Celsius} );
iz( $m->K(),                     274.15, q{1 degree Celsius in Kelvin} );
iz( sprintf( q{%.1f}, $m->F() ), 33.8,   q{1 degree Celsius in Fahrenheit} );
$m = Class::Measure::Scientific::FX_992vb->temperature( 100, 'C' );
iz( $m->C(),                     100,    q{100 degree Celsius} );
iz( $m->K(),                     373.15, q{100 degree Celsius in Kelvin} );
iz( sprintf( q{%.0f}, $m->F() ), 212,    q{100 degree Celsius in Fahrenheit} );
$m = Class::Measure::Scientific::FX_992vb->temperature( -100, 'C' );
iz( $m->C(),                     -100,   q{-100 degree Celsius} );
iz( $m->K(),                     173.15, q{-100 degree Celsius in Kelvin} );
iz( sprintf( q{%.0f}, $m->F() ), -148,   q{-100 degree Celsius in Fahrenheit} );
$m = Class::Measure::Scientific::FX_992vb->temperature( 0, 'F' );
iz( $m->F(), 0,       q{0 degree Fahrenheit} );
iz( sprintf( q{%.3f}, $m->K()), 255.372, q{0 degree Fahrenheit in Kelvin} );
iz( sprintf( q{%.3f}, $m->C()), -17.778, q{0 degree Fahrenheit in Celsius} );
$m = Class::Measure::Scientific::FX_992vb->temperature( 1, 'F' );
iz( $m->F(), 1, q{1 degree Fahrenheit} );
iz( sprintf( q{%.3f}, $m->K() ), 255.928, q{1 degree Fahrenheit in Kelvin} );
iz( sprintf( q{%.3f}, $m->C() ), -17.222, q{1 degree Fahrenheit in Celsius} );
$m = Class::Measure::Scientific::FX_992vb->temperature( 100, 'F' );
iz( $m->F(), 100, q{100 degree Fahrenheit} );
iz( sprintf( q{%.3f}, $m->K() ), 310.928, q{100 degree Fahrenheit in Kelvin} );
iz( sprintf( q{%.3f}, $m->C() ), 37.778,  q{100 degree Fahrenheit in Celsius} );
$m = Class::Measure::Scientific::FX_992vb->temperature( -100, 'F' );
iz( $m->F(), -100, q{-100 degree Fahrenheit} );
iz( sprintf( q{%.3f}, $m->K() ), 199.817, q{-100 degree Fahrenheit in Kelvin} );
iz( sprintf( q{%.3f}, $m->C() ), -73.333,
    q{-100 degree Fahrenheit in Celsius} );
$m = Class::Measure::Scientific::FX_992vb->temperature( 0, 'K' );
iz( $m->K(),                     0,       q{0 Kelvin} );
iz( sprintf( q{%.2f}, $m->F() ), -459.67, q{0 Kelvin in Fahrenheit} );
iz( $m->C(),                     -273.15, q{0 Kelvin in Celsius} );
$m = Class::Measure::Scientific::FX_992vb->temperature( 1, 'K' );
iz( $m->K(),                     1,       q{1 Kelvin} );
iz( sprintf( q{%.2f}, $m->F() ), -457.87, q{1 Kelvin in Fahrenheit} );
iz( $m->C(),                     -272.15, q{1 Kelvin in Celsius} );
$m = Class::Measure::Scientific::FX_992vb->temperature( 100, 'K' );
iz( $m->K(),                     100,     q{100 Kelvin} );
iz( sprintf( q{%.2f}, $m->F() ), -279.67, q{100 Kelvin in Fahrenheit} );
iz( $m->C(),                     -173.15, q{100 Kelvin in Celsius} );
$m = Class::Measure::Scientific::FX_992vb->temperature( -100, 'K' );
iz( $m->K(),                     -100,    q{-100 Kelvin} );
iz( sprintf( q{%.2f}, $m->F() ), -639.67, q{-100 Kelvin in Fahrenheit} );
iz( $m->C(),                     -373.15, q{-100 Kelvin in Celsius} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
