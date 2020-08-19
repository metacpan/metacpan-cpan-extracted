use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 20;

sub iz {
    my ( $got, $exp, $msg ) = @_;

    # Length unit conversion can lead to repeating digits that are rounded
    # differently based on the use of the -Duselongdouble perl configuration
    # option so we limit the precision of the test to 13 significants:
    my $FMT = q{%.13g};
    return is( sprintf( $FMT, $got ), sprintf( $FMT, $exp ), $msg );
}

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->length( 1, 'm' );
iz( $m->m(),      1,                    q{1m via length} );
iz( $m->AU(),     6.68458715354704e-12, q{1m in atronomical unit via length} );
iz( $m->ly(),     1.05702323231362e-16, q{1m in lightyear via length} );
iz( $m->nmi(),    0.000539956803455724, q{1m in nautical mile via length} );
iz( $m->pc(),     3.24077930151335e-17, q{1m in parsec via length} );
iz( $m->chain(),  0.049709595959596,    q{1m in chain via length} );
iz( $m->fathom(), 0.546805555555556,    q{1m in fathom via length} );
iz( $m->ft(),     3.28083989501312,     q{1m in feet via length} );
iz( $m->ft_us(),  3.28083333333333,     q{1m in US surveyors feet via length} );
iz( $m->in(),     39.3700787401575,     q{1m in inch via length} );
iz( $m->mil(),    39370.0787401575,     q{1m in mil via length} );
iz( $m->mile(),   0.000621371192237334, q{1m in miles via length} );
iz( $m->sm(),     0.000621369949494949, q{1m in US statute miles via length} );
iz( $m->yd(),     1.09361329833771,     q{1m in yard via length} );
iz( $m->yd_us(),  1.09361111111111,     q{1m in US yard via length} );
iz( $m->lambdacn(), 757810621458514, q{1m in Compton wavelength n via length} );
iz( $m->lambdacp(), 756767449676289, q{1m in Compton wavelength p via length} );
iz( $m->a0(), 18897266635.1032, q{1m in Bohr radius via length} );
iz( $m->re(), 354869411605223,  q{1m in electron radius via length} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
