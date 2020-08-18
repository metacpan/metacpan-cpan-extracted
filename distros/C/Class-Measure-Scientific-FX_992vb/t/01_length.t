use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 20;

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->length( 1, 'm' );
is( $m->m(),      1,                    q{1m via length} );
is( $m->AU(),     6.68458715354704e-12, q{1m in atronomical unit via length} );
is( $m->ly(),     1.05702323231362e-16, q{1m in lightyear via length} );
is( $m->nmi(),    0.000539956803455724, q{1m in nautical mile via length} );
is( $m->pc(),     3.24077930151335e-17, q{1m in parsec via length} );
is( $m->chain(),  0.049709595959596,    q{1m in chain via length} );
is( $m->fathom(), 0.546805555555556,    q{1m in fathom via length} );
is( $m->ft(),     3.28083989501312,     q{1m in feet via length} );
is( $m->ft_us(),  3.28083333333333,     q{1m in US surveyors feet via length} );
is( $m->in(),     39.3700787401575,     q{1m in inch via length} );
is( $m->mil(),    39370.0787401575,     q{1m in mil via length} );
is( $m->mile(),   0.000621371192237334, q{1m in miles via length} );
is( $m->sm(),     0.00062136994949495,  q{1m in US statute miles via length} );
is( $m->yd(),     1.09361329833771,     q{1m in yard via length} );
is( $m->yd_us(),  1.09361111111111,     q{1m in US yard via length} );
is( $m->lambdacn(), 757810621458514, q{1m in Compton wavelength n via length} );
is( $m->lambdacp(), 756767449676289, q{1m in Compton wavelength p via length} );
is( $m->a0(), 18897266635.1032, q{1m in Bohr radius via length} );
is( $m->re(), 354869411605223,  q{1m in electron radius via length} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
