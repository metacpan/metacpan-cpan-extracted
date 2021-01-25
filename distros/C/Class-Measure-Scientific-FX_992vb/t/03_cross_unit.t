use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 6;

require Class::Measure::Scientific::FX_992vb;
my $d = Class::Measure::Scientific::FX_992vb->length( 1, 'nmi' );
my $s = Class::Measure::Scientific::FX_992vb->speed( 1, 'kn' );
is( $d->mile(), $s->mph(), q{Knots equal nautical miles per hour} );

$d = Class::Measure::Scientific::FX_992vb->duration( 1, 'year' );
$s = Class::Measure::Scientific::FX_992vb->speed( 1, 'c' );
my $l   = Class::Measure::Scientific::FX_992vb->length( 1, 'ly' );
my $acc = 5;
is(
    sprintf( qq{%.${acc}e}, $d->s() * $s->mps() ),
    sprintf( qq{%.${acc}e}, $l->m() ),
    q{Light travels approximately one light-year per tropical year}
);

$d = Class::Measure::Scientific::FX_992vb->length( 1, 'mile' );
my $m =
  Class::Measure::Scientific::FX_992vb->area( ( ( $d->m()**2 ) / 640 ), 'm2' );
my $a = Class::Measure::Scientific::FX_992vb->area( 1, 'acre' );
is(
    sprintf( qq{%.${acc}e}, $m->m2() ),
    sprintf( qq{%.${acc}e}, $a->m2() ),
    q{One acre is 1/640 of a square mile}
);

$d = Class::Measure::Scientific::FX_992vb->length( 1, 'ft' );
my $i = Class::Measure::Scientific::FX_992vb->length( 1, 'in' );
my $v =
  Class::Measure::Scientific::FX_992vb->volume( $i->m() * $d->m()**2, 'm3' );
is( sprintf( qq{%.${acc}f}, $v->m3() ),
    0.00236, q{Board foot calculated from dimensions} );

$d = Class::Measure::Scientific::FX_992vb->length( 1, 'mile' );
is( $d->m() / 3600, 0.44704, q{One mile per hour in meters per second} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
