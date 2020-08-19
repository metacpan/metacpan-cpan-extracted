use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 11;

sub iz {
    my ( $got, $exp, $msg ) = @_;
    my $FMT = q{%.15g};
    return is( sprintf( $FMT, $got ), sprintf( $FMT, $exp ), $msg );
}

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->pressure( 1, 'pa' );
iz( $m->pa(), 1, q{1 Pascal via pressure} );
iz( $m->at(), 1.01971621297793e-05,
    q{1 Pascal in technical atmosphere via pressure} );
iz( $m->atm(), 9.86923266716013e-06,
    q{1 Pascal in standard atmosphere via pressure} );
iz( $m->mH2O(), 0.000101971621297793,
    q{1 Pascal in meters of water via pressure} );
iz( $m->mmHg(), 0.0075006168270417,
    q{1 Pascal in millimeters of mercury via pressure} );
iz( $m->Torr(), 0.0075006168270417, q{1 Pascal in Torr via pressure} );
iz( $m->ftH2O(), 0.000334552563312969,
    q{1 Pascal in foot of water via pressure} );
iz( $m->inH2O(), 0.00401463075975562,
    q{1 Pascal in inch of water via pressure} );
iz( $m->inHg(), 0.000295299875080795,
    q{1 Pascal in inch of mercury via pressure} );
iz( $m->psi(), 0.000145037737730175, q{1 Pascal in PSI via pressure} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
