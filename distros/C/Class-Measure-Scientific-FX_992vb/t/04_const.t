use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 7;

require Class::Measure::Scientific::FX_992vb;
my $c;
$c = Class::Measure::Scientific::FX_992vb::CONST(1);
is( $c, 0.01745329251, q{CONST 1} );
$c = Class::Measure::Scientific::FX_992vb::CONST(127);
is( $c, 2.58e-4, q{CONST 127} );
$c = Class::Measure::Scientific::FX_992vb::CONST(128);
is( $c, 2.067_850_6e-15, q{CONST 128} );
$c = Class::Measure::Scientific::FX_992vb::CONST(0);
is( $c, undef, q{CONST 0} );
$c = Class::Measure::Scientific::FX_992vb::CONST(129);
is( $c, undef, q{CONST 129} );
$c = Class::Measure::Scientific::FX_992vb::CONST(999);
is( $c, undef, q{CONST 999} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
