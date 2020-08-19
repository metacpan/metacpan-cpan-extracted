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
my $m = Class::Measure::Scientific::FX_992vb->acceleration( 1, 'g' );
iz( $m->g(),    1,       q{1g via acceleration} );
iz( $m->mps2(), 9.80665, q{1g in mps2 via acceleration} );
$m = Class::Measure::Scientific::FX_992vb->acceleration( 1, 'mps2' );
iz( $m->mps2(), 1,                 q{1mps2 via acceleration} );
iz( $m->g(),    0.101971621297793, q{1mps2 in g via acceleration} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
