use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 17;

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->speed( 1, 'kn' );
is( $m->kn(),  1,                    q{1kn via speed} );
is( $m->mps(), 0.514444444444444,    q{1kn in mps via speed} );
is( $m->mph(), 1.15077944802354,     q{1kn in mph via speed} );
is( $m->c(),   1.71600195640827e-09, q{1kn in c (speed of light) via speed} );
$m = Class::Measure::Scientific::FX_992vb->speed( 1, 'mps' );
is( $m->mps(), 1,                    q{1mps via speed} );
is( $m->kn(),  1.9438444924406,      q{1mps in kn via speed} );
is( $m->mph(), 2.2369362920544,      q{1mps in mph via speed} );
is( $m->c(),   3.33564095198152e-09, q{1mps in c (speed of light) via speed} );
$m = Class::Measure::Scientific::FX_992vb->speed( 1, 'mph' );
is( $m->mph(), 1,                    q{1mph via speed} );
is( $m->kn(),  0.868976241900648,    q{1mph in kn via speed} );
is( $m->mps(), 0.44704,              q{1mph in mps via speed} );
is( $m->c(),   1.49116493117382e-09, q{1mph in c (speed of light) via speed} );
$m = Class::Measure::Scientific::FX_992vb->speed( 1, 'c' );
is( $m->c(),   1,                q{1c via speed} );
is( $m->kn(),  582749918.358531, q{1c in kn via speed} );
is( $m->mps(), 299792458,        q{1c in mps via speed} );
is( $m->mph(), 670616629.384395, q{1c mph via speed} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
