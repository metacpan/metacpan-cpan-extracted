use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 18;

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->mass( 1, 'kg' );
is( $m->kg(),     1,                    q{1 kg via mass} );
is( $m->ct(),     5000,                 q{1 kg in metric carat via mass} );
is( $m->cwt_uk(), 0.0196841305522212,   q{1 kg in UK hundred weight via mass} );
is( $m->cwt_us(), 0.0220462262184878,   q{1 kg in US hundred weight via mass} );
is( $m->gr(),     15432.3583529414,     q{1 kg in grain via mass} );
is( $m->lb(),     2.20462262184878,     q{1 kg in pound via mass} );
is( $m->lbt(),    2.679228880719,       q{1 kg in troy pound via mass} );
is( $m->oz(),     35.2739619558017,     q{1 kg in ounce via mass} );
is( $m->ozt(),    32.150746568628,      q{1 kg in troy ounce via mass} );
is( $m->slug(),   0.0685217658568216,   q{1 kg in slug via mass} );
is( $m->ton_uk(), 0.000984206527611061, q{1 kg in long ton via mass} );
is( $m->ton_us(), 0.00110231131092439,  q{1 kg in short ton via mass} );
is( $m->m1h(), 5.97528835845325e+26,
    q{1 kg in mass of hydrogen atom via mass} );
is( $m->me(), 1.09775099362931e+30, q{1 kg in mass of electron via mass} );
is( $m->mn(), 5.97031214523286e+26, q{1 kg in mass of neutron via mass} );
is( $m->mp(), 5.97854241342398e+26, q{1 kg in mass of proton via mass} );
is( $m->u(),  6.02204489976457e+26, q{1 kg in atomic mass unit via mass} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
