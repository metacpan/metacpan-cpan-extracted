use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 7;

require Class::Measure::Scientific::FX_992vb;
is( Class::Measure::Scientific::FX_992vb::dB(),
    0.11512925465, q{Decibel difference level} );
is( Class::Measure::Scientific::FX_992vb::Np(),
    8.68588963807, q{Neper difference level} );
is( Class::Measure::Scientific::FX_992vb::a(),
    7.2973506e-3, q{Fine-structure constant} );
is( Class::Measure::Scientific::FX_992vb::zC(),
    273.15, q{zero Celsius in Kelvin} );
is( Class::Measure::Scientific::FX_992vb::zF(),
    -160 / 9, q{zero Fahrenheit in Kelvin} );
is( Class::Measure::Scientific::FX_992vb::FK(),
    5 / 9, q{degree Fahrenheit in Kelvin} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
