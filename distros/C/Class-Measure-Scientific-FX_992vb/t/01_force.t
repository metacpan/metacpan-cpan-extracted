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
my $m = Class::Measure::Scientific::FX_992vb->force( 1, 'N' );
iz( $m->N(),   1,                 q{1 Newton via force} );
iz( $m->kgf(), 0.101971621297793, q{1 Newton in kilogram-force via force} );
iz( $m->lbf(), 0.224808943099736, q{1 Newton in pound-force via force} );
iz( $m->pdl(), 7.23301385152379,  q{1 Newton in poundal via force} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
