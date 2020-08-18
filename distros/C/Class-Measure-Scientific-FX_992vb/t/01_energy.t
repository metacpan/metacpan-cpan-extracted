use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 9;

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->energy( 1, 'J' );
is( $m->J(),     1,                    q{1 Joule via energy} );
is( $m->BTU(),   0.000947817120313317, q{1 Joule in BTU} );
is( $m->ftlbf(), 0.737562149278027,    q{1 Joule in foot pound-force} );
is( $m->hp(),    0.00134102208959551,  q{1 Joule in horsepower} );
is( $m->cal15(), 0.238920081232828,    q{1 Joule in 15 degree calorie} );
is( $m->calit(), 0.238845896627496,    q{1 Joule in I.T. calorie} );
is( $m->calth(), 0.239005736137667,    q{1 Joule in thermo chemical calorie} );
is( $m->therm(), 9.47817120313317e-09, q{1 Joule in therm} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
