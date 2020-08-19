use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 5;

sub iz {
    my ( $got, $exp, $msg ) = @_;
    my $FMT = q{%.15g};
    return is( sprintf( $FMT, $got ), sprintf( $FMT, $exp ), $msg );
}

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->duration( 1, 's' );
iz( $m->s(),    1,                    q{1s via duration} );
iz( $m->year(), 3.16887646154128e-08, q{1s in years via duration} );
$m = Class::Measure::Scientific::FX_992vb->duration( 1, 'year' );
iz( $m->year(), 1,        q{1 year via duration} );
iz( $m->s(),    31556926, q{1 year in seconds via duration} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
