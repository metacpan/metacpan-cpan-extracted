use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 6;

sub iz {
    my ( $got, $exp, $msg ) = @_;
    my $FMT = q{%.15g};
    return is( sprintf( $FMT, $got ), sprintf( $FMT, $exp ), $msg );
}

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->angle( 1, 'rad' );
iz( $m->rad(),    1,                q{1 rad via angle} );
iz( $m->deg(),    57.2957795457242, q{1 rad in degree via angle} );
iz( $m->minute(), 3437.74677078165, q{1 rad in minutes via angle} );
iz( $m->second(), 206264.806251153, q{1 rad in seconds via angle} );
iz( $m->grade(),  63.6619772689741, q{1 rad in grade via angle} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
