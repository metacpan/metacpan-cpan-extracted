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
my $m = Class::Measure::Scientific::FX_992vb->area( 1, 'm2' );
iz( $m->m2(),   1,                    q{1m2 via area} );
iz( $m->acre(), 0.000247105381467165, q{1m2 in acre via area} );
$m = Class::Measure::Scientific::FX_992vb->area( 1, 'acre' );
iz( $m->acre(), 1,            q{1 acre via area} );
iz( $m->m2(),   4046.8564224, q{1 acre in m2 via area} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
