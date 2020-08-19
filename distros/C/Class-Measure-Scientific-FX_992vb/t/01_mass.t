use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 18;

sub iz {
    my ( $got, $exp, $msg ) = @_;
    my $FMT = q{%.15g};
    return is( sprintf( $FMT, $got ), sprintf( $FMT, $exp ), $msg );
}

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->mass( 1, 'kg' );
iz( $m->kg(),     1,                    q{1 kg via mass} );
iz( $m->ct(),     5000,                 q{1 kg in metric carat via mass} );
iz( $m->cwt_uk(), 0.0196841305522212,   q{1 kg in UK hundred weight via mass} );
iz( $m->cwt_us(), 0.0220462262184878,   q{1 kg in US hundred weight via mass} );
iz( $m->gr(),     15432.3583529414,     q{1 kg in grain via mass} );
iz( $m->lb(),     2.20462262184878,     q{1 kg in pound via mass} );
iz( $m->lbt(),    2.679228880719,       q{1 kg in troy pound via mass} );
iz( $m->oz(),     35.2739619558017,     q{1 kg in ounce via mass} );
iz( $m->ozt(),    32.150746568628,      q{1 kg in troy ounce via mass} );
iz( $m->slug(),   0.0685217658568216,   q{1 kg in slug via mass} );
iz( $m->ton_uk(), 0.000984206527611061, q{1 kg in long ton via mass} );
iz( $m->ton_us(), 0.00110231131092439,  q{1 kg in short ton via mass} );
iz( $m->m1h(), 5.97528835845325e+26,
    q{1 kg in mass of hydrogen atom via mass} );
iz( $m->me(), 1.09775099362931e+30, q{1 kg in mass of electron via mass} );
iz( $m->mn(), 5.97031214523286e+26, q{1 kg in mass of neutron via mass} );
iz( $m->mp(), 5.97854241342398e+26, q{1 kg in mass of proton via mass} );
iz( $m->u(),  6.02204489976457e+26, q{1 kg in atomic mass unit via mass} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
