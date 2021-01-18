# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2020-2021, Roland van Ipenburg
package Class::Measure::Scientific::FX_992vb v0.0.6;
use Moose;
use MooseX::NonMoose;
use List::MoreUtils qw(uniq);
extends
  'Class::Measure' => { '-version' => 0.08 },
  'Moose::Object';

use Log::Log4perl qw(:easy get_logger);

use utf8;
use 5.016000;

use Readonly;
## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $EMPTY  => q{};
Readonly::Scalar my $SEP    => q{,};
Readonly::Scalar my $PREFIX => q{C};
Readonly::Scalar my $CODE   => q{CODE};

Readonly::Scalar my $AM2        => q{Am2};
Readonly::Scalar my $AM2PJS     => q{Am2pJs};
Readonly::Scalar my $AMPERE     => q{A};
Readonly::Scalar my $APM        => q{Apm};
Readonly::Scalar my $BQ         => q{Bq};
Readonly::Scalar my $CDPM2      => q{cdpm2};
Readonly::Scalar my $CELSIUS    => q{C};
Readonly::Scalar my $CM         => q{Cm};
Readonly::Scalar my $CM2PV      => q{Cm2pV};
Readonly::Scalar my $COULOMB    => q{C};
Readonly::Scalar my $CPKG       => q{Cpkg};
Readonly::Scalar my $CPM        => q{Cpmol};
Readonly::Scalar my $CPM2       => q{Cpm2};
Readonly::Scalar my $FAHRENHEIT => q{F};
Readonly::Scalar my $FARAD      => q{f};
Readonly::Scalar my $FPM        => q{Fpm};
Readonly::Scalar my $HPM        => q{Hpm};
Readonly::Scalar my $JOULE      => q{J};
Readonly::Scalar my $JPK        => q{JpK};
Readonly::Scalar my $JPKG       => q{Jpkg};
Readonly::Scalar my $JPKGK      => q{JpkgK};
Readonly::Scalar my $JPMOLK     => q{JpmolK};
Readonly::Scalar my $JS         => q{Js};
Readonly::Scalar my $KELVIN     => q{K};
Readonly::Scalar my $KG         => q{kg};
Readonly::Scalar my $KGPM       => q{kgpm};
Readonly::Scalar my $M2         => q{m2};
Readonly::Scalar my $M3         => q{m3};
Readonly::Scalar my $M3PMOL     => q{m3pmol};
Readonly::Scalar my $METER      => q{m};
Readonly::Scalar my $MK         => q{mK};
Readonly::Scalar my $MPS        => q{mps};
Readonly::Scalar my $MPS2       => q{mps2};
Readonly::Scalar my $NEWTON     => q{N};
Readonly::Scalar my $NM2PKG2    => q{Nm2pkg2};
Readonly::Scalar my $PA         => q{pa};
Readonly::Scalar my $PM         => q{pm};
Readonly::Scalar my $PMOL       => q{pmol};
Readonly::Scalar my $RAD        => q{rad};
Readonly::Scalar my $SECOND     => q{s};
Readonly::Scalar my $SKIP       => q{};
Readonly::Scalar my $VOLT       => q{V};
Readonly::Scalar my $VPM        => q{Vpm};
Readonly::Scalar my $WATT       => q{W};
Readonly::Scalar my $WB         => q{Wb};
Readonly::Scalar my $WM2        => q{Wm2};
Readonly::Scalar my $WPM2K4     => q{Wpm2K4};
Readonly::Hash my %IDX          => (
    'idx'        => 0,
    'unit'       => 1,
    'multiplier' => 3,
    'base'       => 4,
);
Readonly::Hash my %TYPES => (
    'acceleration'    => $MPS2,
    'angle'           => $RAD,
    'area'            => $M2,
    'charge'          => $COULOMB,
    'displacement'    => $CPM2,
    'duration'        => $SECOND,
    'electrolysis'    => $CPM,
    'electromagnetic' => $JS,
    'energy'          => $JOULE,
    'entropy'         => $JPK,
    'field_equation'  => $NM2PKG2,
    'flux'            => $WB,
    'force'           => $NEWTON,
    'gas'             => $JPMOLK,
    'gyromagnetic'    => $AM2PJS,
    'heat_capacity'   => $JPKGK,
    'isotropic'       => $CM2PV,
    'length'          => $METER,
    'linear_density'  => $KGPM,
    'luminance'       => $CDPM2,
    'magnetic'        => $AM2,
    'mass'            => $KG,
    'mixture'         => $M3PMOL,
    'power'           => $WATT,
    'pressure'        => $PA,
    'proportionality' => $PMOL,
    'radiation'       => $CPKG,
    'radioactive'     => $BQ,
    'spectroscopic'   => $PM,
    'speed'           => $MPS,
    'susceptibility'  => $CM,
    'temperature'     => $KELVIN,
    'thermodynamic'   => $JPKG,
    'volume'          => $M3,
    'wavelength'      => $WM2,
    'wavenumber'      => $MK,
);
Readonly::Array my @CONST => (
    [ 1, q{deg},    q{degree (angle)},            0.017_453_292_51,    $RAD ],
    [ 2, q{minute}, q{minute (angle)},            2.908_882_086_66e-4, $RAD ],
    [ 3, q{second}, q{second (angle)},            4.848_136_811e-6,    $RAD ],
    [ 4, q{AU},     q{astronomical unit},         149_597_870_000,     $METER ],
    [ 5, q{g},      q{acceleration of free fall}, 9.806_65,            $MPS2 ],
    [ 6, q{grade},  q{grade},                     0.015_707_963_26,    $RAD ],
    [ 7, q{kn},     q{knot},                      1852 / 3600,         $MPS ],
    [ 8, q{ly},     q{light year},                9.460_53e15,         $METER ],
    [ 9, q{nmi},    q{nautical mile},             1852,                $METER ],
    [ 10, q{pc},         q{parsec},               3.085_677_57e16,  $METER ],
    [ 11, q{year},       q{tropical year},        31_556_926,       $SECOND ],
    [ 12, q{acre},       q{acre},                 4_046.856_422_4,  $M2 ],
    [ 13, q{bbl},        q{barrel for petroleum}, 0.158_987_294_92, $M3 ],
    [ 14, q{dry_barrel}, q{dry barrel},           0.115_627_123_58, $M3 ],
    [ 15, q{bushel_uk},  q{bushel},               0.036_368_794_35, $M3 ],
    [ 16, q{bu},         q{bushel},               0.035_239_070_16, $M3 ],
    [ 17, q{chain},      q{chain (surveyors)},    79_200 / 3_937,   $METER ],
    [ 18, q{cu},         q{US cup},               2.365_882_365e-4, $M3 ],
    [ 19, q{pt_dry},  q{dry pint},                5.506_104_713_58e-4, $M3 ],
    [ 20, q{fathom},  q{fathom (surveyors)},      7200 / 3937,         $METER ],
    [ 21, q{fbm},     q{board foot},              2.359_737_216e-3,    $M3 ],
    [ 22, q{floz_uk}, q{fluid ounce UK},          2.841_312_059_3e-5,  $M3 ],
    [ 23, q{floz_us}, q{fluid ounce US},          2.957_352_956_25e-5, $M3 ],
    [ 24, q{ft},      q{foot},                    0.304_8,             $METER ],
    [ 25, q{ft_us},   q{foot (surveyors = US)},   1200 / 3937,         $METER ],
    [ 26, q{gal_uk},  q{gallon (United Kingdom)}, 4.546_099_294_88e-3, $M3 ],
    [ 27, q{gal_us},  q{gallon (United States)},  3.785_411_784e-3,    $M3 ],
    [ 28, q{in},      q{inch},                    0.025_4,             $METER ],
    [ 29, q{mil},     q{mil},                     2.54e-5,             $METER ],
    [ 30, q{mile},    q{mile (international)},    1_609.344,           $METER ],
    [ 31, q{sm},      q{US statute mile},         6_336_000 / 3_937,   $METER ],
    [ 32, q{mph},     q{miles per hour},          0.447_04,            $MPS ],
    [ 33, q{pk},      q{peck},                    8.809_767_541_72e-3, $M3 ],
    [ 34, q{pt_uk},   q{pint},                    5.682_624_118_6e-4,  $M3 ],
    [ 35, q{pt_us},   q{liquid pint},             4.731_764_73e-4,     $M3 ],
    [ 36, q{tbsp},    q{tablespoon},              1.478_676_478_13e-5, $M3 ],
    [ 37, q{tsp},     q{teaspoon},                4.928_921_593_75e-6, $M3 ],
    [ 38, q{yd},      q{yard},                    0.914_4,             $METER ],
    [ 39, q{yd_us},   q{US yard},                 3_600 / 3_937,       $METER ],
    [ 40, q{at},      q{technical atmosphere},    98_066.5,            $PA ],
    [ 41, q{atm},     q{standard atmosphere},     101_325,             $PA ],
    [ 42, q{ct},      q{metric carat},            2e-4,                $KG ],
    [ 43, q{D},       q{denier},                  50 / 450_000_000,    $KGPM ],
    [ 44, q{G},       q{gravitational constant},  6.672e-11,        $NM2PKG2 ],
    [ 45, q{kgf},     q{kilogramforce},           9.806_65,         $NEWTON ],
    [ 46, q{mH2O},    q{meter of water},          9_806.65,         $PA ],
    [ 47, q{mmHg},    q{mm of mercury},           101_325 / 760,    $PA ],
    [ 48, q{PS},      q{metric horsepower},       735.49875,        $WATT ],
    [ 49, q{Torr},    q{Torr},                    101_325 / 760,    $PA ],
    [ 50, q{cwt_uk},  q{hundred-weight},          50.802_345_44,    $KG ],
    [ 51, q{cwt_us},  q{hundred-weight},          45.359_237,       $KG ],
    [ 52, q{ftlbf},   q{foot pound-force},        1.355_817_948_33, $JOULE ],
    [ 53, q{ftH2O},   q{foot of water},           2_989.066_92,     $PA ],
    [ 54, q{gr},      q{grain},                   6.479_891e-5,     $KG ],
    [ 55, q{hp},      q{horsepower},              745.699_871_582,  $JOULE ],
    [ 56, q{inH2O},   q{inch of water},           249.088_91,       $PA ],
    [ 57, q{inHg},    q{inch of mercury},         3_386.388_157_89, $PA ],
    [ 58, q{lb},      q{pound},                   0.453_592_37,     $KG ],
    [ 59, q{lbf},     q{pound-force},             4.448_221_615_26, $NEWTON ],
    [ 60, q{lbt},     q{troy pound},              0.373_241_721_6,  $KG ],
    [ 61, q{oz},      q{ounce},                   0.028_349_523_12, $KG ],
    [ 62, q{ozt},     q{troy ounce},              0.031_103_476_8,  $KG ],
    [ 63, q{pdl},     q{poundal},                 0.138_254_954_37, $NEWTON ],
    [ 64, q{psi},     q{pounds per square inch},  6_894.757_293_17, $PA ],
    [ 65, q{slug},    q{slug},                    14.593_902_937_2, $KG ],
    [ 66, q{ton_uk},  q{long ton},                1_016.046_908_8,  $KG ],
    [ 67, q{ton_us},  q{short ton},               907.184_74,       $KG ],
    [ 68, q{zC},      q{zero Celsius},            273.15,           $SKIP ],
    [ 69, q{cal15},   q{15 degree calorie},       4.185_5,          $JOULE ],
    [ 70, q{calit},   q{I.T. calorie},            4.186_8,          $JOULE ],
    [ 71, q{calth},   q{thermo chemical calorie}, 4.184,            $JOULE ],
    [ 72, q{FK},      q{degree Fahrenheit},       5 / 9,            $SKIP ],
    [ 73, q{zF},      q{zero Fahrenheit in Celsius}, -160 / 9,         $SKIP ],
    [ 74, q{BTU},     q{British thermal unit},       1_055.055_852_62, $JOULE ],
    [ 75, q{BTUlbR},  q{specific heat capacity},     4_186.8,          $JPKGK ],
    [ 76, q{BTUh},    q{Btu per hour},               0.293_071_070_17, $WATT ],
    [ 77, q{BTUlb},   q{specific internal enegry},   2_326,            $JPKG ],
    [ 78, q{therm},   q{therm},                      105_505_585.262,  $JOULE ],
    [ 79, q{eps0}, q{permittivity of vacuum},   8.854_187_817_62e-12,  $FPM ],
    [ 80, q{mu0},  q{permeability of vacuum},   1.256_637_061_44e-6,   $HPM ],
    [ 81, q{Cs},   q{G. electric capacitance},  1.112_650_056_05e-12,  $FARAD ],
    [ 82, q{Ds},   q{G. electric flux density}, 2.654_418_729_44e-7,   $CPM2 ],
    [ 83, q{Es},   q{G. electric field strength}, 29_979.245_8,      $VPM ],
    [ 84, q{Is},   q{G. electric current},        3.33564095198e-10, $AMPERE ],
    [ 85, q{Oe},   q{Hs, G. magnetic field strength}, 79.5774715459, $APM ],
    [ 86, q{Ps}, q{G. electric polarization}, 3.335_640_951_98e-6,   $CPM2 ],
    [ 87, q{Qs}, q{G. electric charge},       3.335_640_951_98e-10,  $COULOMB ],
    [ 88, q{Vs}, q{G. electric potential},    299.792458,            $VOLT ],
    [ 89,  q{sigma}, q{Stefan-Boltzmann constant}, 5.67032e-8,       $WPM2K4 ],
    [ 90,  q{c},     q{speed of light},            299_792_458,      $MPS ],
    [ 91,  q{c1},    q{first radiation constant},  3.741_832e-16,    $WM2 ],
    [ 92,  q{c2},    q{second radiation constant}, 0.014_387_86,     $MK ],
    [ 93,  q{lam},   q{lambert},                   3_183.098_861_84, $CDPM2 ],
    [ 94,  q{flam},  q{footlambert},               3.426_259_099_64, $CDPM2 ],
    [ 95,  q{dB},    q{decibel level difference},  0.115_129_254_65, $SKIP ],
    [ 96,  q{Np},    q{neper level difference},    8.685_889_638_07, $SKIP ],
    [ 97,  q{e},     q{elementary charge},         1.602_189_2e-19,  $COULOMB ],
    [ 98,  q{f},     q{Faraday constant},          96_484.56,        $CPM ],
    [ 99,  q{k},     q{Boltzmann constant},        1.380_662e-23,    $JPK ],
    [ 100, q{Na},    q{Avogadro constant},         6.022_045e23,     $PMOL ],
    [ 101, q{R},     q{molar gas constant},        8.314_41,         $JPMOLK ],
    [ 102, q{Vm},    q{molar volume},              0.02241383,       $M3PMOL ],
    [
        103, q{alpha}, q{G. el. polarizability of molecule},
        1.11265005605e-16, $CM2PV,
    ],
    [ 104, q{p}, q{mu, G. el. dipole of molecule}, 3.33564095198e-12, $CM ],
    [ 105, q{a}, q{fine-structure constant},       7.297_350_6e-3,    $SKIP ],
    [ 106, q{gammap}, q{gyromagnetic ratio of proton}, 267_519_870,   $AM2PJS ],
    [
        107,         q{gammapalt}, q{gyromagnetic ratio of proton in water},
        267_513_010, $AM2PJS,
    ],
    [ 108, q{lambdacn}, q{Compton wavelength n},     1.319_590_9e-15,  $METER ],
    [ 109, q{lambdacp}, q{Compton wavelength p},     1.321_409_9e-15,  $METER ],
    [ 110, q{muB},      q{Bohr magneton},            9.274_078e-24,    $AM2 ],
    [ 111, q{mue},      q{m. moment of electron},    9.284_770_1e-24,  $AM2 ],
    [ 112, q{muN},      q{nuclear magneton},         5.050_824e-27,    $AM2 ],
    [ 113, q{mup},      q{m. moment of proton},      1.410_607_61e-26, $AM2 ],
    [ 114, q{a0},       q{Bohr radius},              5.291_770_6e-11,  $METER ],
    [ 115, q{eh},       q{Hartree energy},           4.359_81e-18,     $JOULE ],
    [ 116, q{ev},       q{electronvolt},             1.602_189_2e-19,  $JOULE ],
    [ 117, q{h},        q{Planck constant},          6.626176e-34,     $JS ],
    [ 118, q{hbar},     q{Planck constant per 2 pi}, 1.0545887e-34,    $JS ],
    [ 119, q{m1h},      q{mass of hydrogen atom},    1.673_559_4e-27,  $KG ],
    [ 120, q{me},       q{rest mass of electron},    9.109_534e-31,    $KG ],
    [ 121, q{mn},       q{rest mass of neutron},     1.674_954_3e-27,  $KG ],
    [ 122, q{mp},       q{rest mass of proton},      1.672_648_5e-27,  $KG ],
    [ 123, q{Rinf},     q{Rydberg constant},         10_973_731.77,    $PM ],
    [ 124, q{re},       q{electron radius},          2.817_938e-15,    $METER ],
    [ 125, q{u},        q{atomic mass unit},         1.660_565_5e-27,  $KG ],
    [ 126, q{Ci},       q{curie},                    37_000_000_000,   $BQ ],
    [ 127, q{R},        q{rontgen},                  2.58e-4,          $CPKG ],
    [ 128, q{phi0},     q{fluxiod quantum},          2.067_850_6e-15,  $WB ],
    [
        undef, $CELSIUS,
        q{Celsius to Kelvin},
        sub {
            return shift() + Class::Measure::Scientific::FX_992vb::zC();
        },
        $KELVIN,
    ],
    [
        undef,
        $KELVIN,
        q{Kelvin to Celsius},
        sub {
            return shift() - Class::Measure::Scientific::FX_992vb::zC();
        },
        $CELSIUS,
    ],
    [
        undef,
        $FAHRENHEIT,
        q{Fahrenheit to Kelvin},
        sub {
            return Class::Measure::Scientific::FX_992vb::zC() +
              ( ( shift() * Class::Measure::Scientific::FX_992vb::FK() ) +
                  Class::Measure::Scientific::FX_992vb::zF() );
        },
        $KELVIN,
    ],
    [
        undef,
        $KELVIN,
        q{Kelvin to Fahrenheit},
        sub {
            return (
                shift() - (
                    Class::Measure::Scientific::FX_992vb::zF() +
                      Class::Measure::Scientific::FX_992vb::zC()
                )
              ) /
              Class::Measure::Scientific::FX_992vb::FK();
        },
        $FAHRENHEIT,
    ],
);
Readonly::Scalar my $MAX => length grep { $_[ $IDX{'idx'} ] } @CONST;
Readonly::Hash my %LOG   => (
    'UNITS' => q{Registering units '%s'},
    'CONST' => q{Contant %d is not available, there are only 128 constants},
);
## use critic

Log::Log4perl->easy_init($ERROR);
my $log = get_logger();

for my $type ( keys %TYPES ) {

    sub _nom {
        my $label = lc shift;
        $label =~ s{\s+}{_}msx;
        return $label;
    }
    ## no critic (ProhibitNoStrict)
    no strict q{refs};
    ## use critic
    *{ _nom($type) } = sub {
        new(@_);
    };
}

my @units = ();
my @convs = ();
for my $const (@CONST) {
    my $base       = ${$const}[ $IDX{'base'} ];
    my $unit       = ${$const}[ $IDX{'unit'} ];
    my $multiplier = ${$const}[ $IDX{'multiplier'} ];
    if ( $base ne $SKIP ) {
        push @convs,
          (
              ( ref $multiplier eq $CODE )
            ? ( $unit => $base, $multiplier )
            : ( $unit => $multiplier, $base )
          );
        push @units, ( $unit, $base );
    }
    else {
        ## no critic (ProhibitNoStrict)
        no strict q{refs};
        ## use critic
        *{$unit} = sub {
            return $multiplier;
        };
    }
}

sub CONST {
    my $idx = shift;
    $idx--;
    if ( exists $CONST[$idx] && defined $CONST[$idx][ $IDX{'idx'} ] ) {
        return $CONST[$idx][ $IDX{'multiplier'} ];
    }
    else {
        $log->error( sprintf $LOG{'CONST'}, $idx + 1 );
        return;
    }
}

sub new {
    my ( $class, $amount, $unit ) = @_;

    @units = uniq(@units);

    # Register in the constructor because Class::Measure doesn't allow
    # inheritance of registered data:
    $log->debug( sprintf $LOG{'UNITS'}, join $SEP, @units );
    if ( 0 == $class->units() ) {
        $class->reg_units(@units);
        $class->reg_convs(@convs);
    }

    my $measure = $class->SUPER::new( $amount, $unit );
## no critic (ProhibitHashBarewords)
    return $class->meta->new_object( __INSTANCE__ => $measure, $amount, $unit );
## use critic
}

no Moose;
__PACKAGE__->meta->make_immutable( 'inline_constructor' => 0 );

1;

__END__

=begin stopwords

Ipenburg JIS merchantability fx gradian poundal torr pdl inHg thermo ps BTUlbR
BTUlb muB magneton gammap gyromagnetic Rinf weber wavenumber luminance lambert
footlambert candela mol Vm polarizability Ds Neper thermochemical Bitbucket

=end stopwords

=head1 NAME

Class::Measure::Scientific::FX_992vb - units of measurement like the CASIO fx-992vb

=head1 VERSION

This document describes Class::Measure::Scientific::FX_992vb C<v0.0.6>.

=head1 SYNOPSIS

    use Class::Measure::Scientific::FX_992vb;
    $m = Class::Measure::Scientific::FX_992vb->mass(1, 'u');
    print $m->kg();

=head1 DESCRIPTION

Create, compare and convert units of measurement as the CASIO fx-992vb. This
has little to do with the CASIO fx-992vb itself, the hardware just provides a
stable curated scope of range and precision for the 128 constants used in this
module so it won't be endlessly updated with more units or more precise
constants.

=head1 SUBROUTINES/METHODS

=over 4

=item C<Class::Measure::Scientific::FX_992vb-E<gt>new(1, 'inHg')>

Constructs a new Class::Measure::Scientific::FX_992vb object. This is the same
type of object as the following list of specific objects, but the specific
objects might in the future be able to handle conflicting aliases for units
which the generic constructor can't.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>volume(1, 'cu');>

Construct a L<volume|https://en.wikipedia.org/wiki/Volume> object. Unit must
be one of C<m3> for L<cubic meter|https://en.wikipedia.org/wiki/Cubic_metre>,
C<bbl> for L<barrel|https://en.wikipedia.org/wiki/Barrel_(unit)>,
C<dry_barrel> for L<dry barrel|https://en.wikipedia.org/wiki/Barrel_(unit)>,
C<bushel_uk> for L<UK bushel|https://en.wikipedia.org/wiki/Bushel>, C<bu> for
L<bushel|https://en.wikipedia.org/wiki/Bushel>, C<cu> for
L<cup|https://en.wikipedia.org/wiki/Cup_(unit)>, C<pt_dry> for L<dry
pint|https://en.wikipedia.org/wiki/Dry_measure>, C<fbm> for L<board
foot|https://en.wikipedia.org/wiki/Board_foot>, C<floz_uk> for L<UK fluid
ounce|https://en.wikipedia.org/wiki/Fluid_ounce>, C<floz_us> for L<US fluid
ounce|https://en.wikipedia.org/wiki/Fluid_ounce>, C<gal_uk> for L<UK
gallon|https://en.wikipedia.org/wiki/Gallon>, C<gal_us> for L<US
gallon|https://en.wikipedia.org/wiki/Gallon>, C<pk> for
L<peck|https://en.wikipedia.org/wiki/Peck>, C<pt_uk> for
L<pint|https://en.wikipedia.org/wiki/Pint>, C<pt_us> for L<liquid
pint|https://en.wikipedia.org/wiki/Pint>, C<tbsp> for
L<tablespoon|https://en.wikipedia.org/wiki/Tablespoon> or C<tsp> for
L<teaspoon|https://en.wikipedia.org/wiki/Teaspoon>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>area(1, 'acre');>

Construct an L<area|https://en.wikipedia.org/wiki/Area> object. Unit must be
C<m2> for L<square meter|https://en.wikipedia.org/wiki/Square_metre> or
C<acre> for L<acre|https://en.wikipedia.org/wiki/Acre>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>length(1, 'fathom');>

Construct a L<length|https://en.wikipedia.org/wiki/Length> object. Unit must
be one of C<m> for L<meter|https://en.wikipedia.org/wiki/Metre>, C<AU> for
L<astronomical unit|https://en.wikipedia.org/wiki/Astronomical_unit>, C<ly>
for L<light-year|https://en.wikipedia.org/wiki/Light-year>, C<nmi> for
L<Nautical mile|https://en.wikipedia.org/wiki/Nautical_mile>, C<pc> for
L<parsec|https://en.wikipedia.org/wiki/Parsec>, C<chain> for
L<chain|https://en.wikipedia.org/wiki/Chain_(unit)>, C<fathom> for
L<fathom|https://en.wikipedia.org/wiki/Fathom>, C<ft> for
L<foot|https://en.wikipedia.org/wiki/Foot_(unit)>, C<ft_us> for US surveyors
foot, C<in> for L<inch|https://en.wikipedia.org/wiki/Inch>, C<mil> for L<mil
(1/1000th inch)|https://en.wikipedia.org/wiki/Thousandth_of_an_inch>, C<mile>
for L<mile|https://en.wikipedia.org/wiki/Mile>, C<sm> for US statute miles,
C<yd> for L<yard|https://en.wikipedia.org/wiki/Yard>, C<yd_us> for US yard,
C<lambdacn> for L<Compton
wavelength|https://en.wikipedia.org/wiki/Compton_wavelength> of neutron,
C<lambdacp> for L<Compton
wavelength|https://en.wikipedia.org/wiki/Compton_wavelength> of proton, C<a0>
for L<Bohr radius|https://en.wikipedia.org/wiki/Bohr_radius> or C<re> for
L<electron radius|https://en.wikipedia.org/wiki/Classical_electron_radius>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>duration(1, 'year');>

Construct a duration object. Unit must be C<s> for
L<seconds|https://en.wikipedia.org/wiki/Second> or C<year> for L<tropical
year|https://en.wikipedia.org/wiki/Tropical_year>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>speed(1, 'c');>

Construct a L<speed|https://en.wikipedia.org/wiki/Speed> object. Unit must be
one of C<mps> for L<meter per
second|https://en.wikipedia.org/wiki/Metre_per_second>, C<mph> for L<miles per
hour|https://en.wikipedia.org/wiki/Miles_per_hour>, C<kn> for
L<knot|https://en.wikipedia.org/wiki/Knot_(unit)> or C<c> for the L<speed of
light|https://en.wikipedia.org/wiki/Speed_of_light>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>acceleration(1, 'g');>

Construct an L<acceleration|https://en.wikipedia.org/wiki/Acceleration>
object. Unit must be one of C<g> for L<acceleration of free
fall|https://en.wikipedia.org/wiki/Gravitational_acceleration> or C<mps2> for
L<meters per second
squared|https://en.wikipedia.org/wiki/Metre_per_second_squared>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>angle(90, 'deg');>

Construct an L<angle|https://en.wikipedia.org/wiki/Angle> object. Unit must be
one of C<rad> for L<radian|https://en.wikipedia.org/wiki/Radian>, C<deg> for
L<degree|https://en.wikipedia.org/wiki/Degree_(angle)>, C<minute> for L<minute
of arc|https://en.wikipedia.org/wiki/Minute_and_second_of_arc>, C<second> for
L<second of arc|https://en.wikipedia.org/wiki/Minute_and_second_of_arc> or
C<grade> for L<gradian|https://en.wikipedia.org/wiki/Gradian>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>mass(1, 'u');>

Construct a L<mass|https://en.wikipedia.org/wiki/Mass> object. Unit must be
one of C<kg> for L<kilogram|https://en.wikipedia.org/wiki/Kilogram>, C<ct> for
L<metric carat|https://en.wikipedia.org/wiki/Carat_(mass)>, C<cwt_uk> for L<UK
hundredweight|https://en.wikipedia.org/wiki/Hundredweight>, C<cwt_us> for US
hundred weight, C<gr> for L<grain|https://en.wikipedia.org/wiki/Grain_(unit)>,
C<lb> for L<pound|https://en.wikipedia.org/wiki/Pound_(mass)>, C<lbt> for troy
pound, C<oz> for L<ounce|https://en.wikipedia.org/wiki/Ounce>, C<ozt> for
L<troy ounce|https://en.wikipedia.org/wiki/Troy_weight>, C<slug> for
L<slug|https://en.wikipedia.org/wiki/Slug_(unit)>, C<ton_uk> for L<long
ton|https://en.wikipedia.org/wiki/Long_ton>, C<ton_us> for L<short
ton|https://en.wikipedia.org/wiki/Short_ton>, C<m1h> for L<mass of hydrogen
atom|https://en.wikipedia.org/wiki/Hydrogen_atom>, C<me> for mass of
L<electron|https://en.wikipedia.org/wiki/Electron>, C<mn> for mass of
L<neutron|https://en.wikipedia.org/wiki/Neutron>, C<mp> for mass of
L<proton|https://en.wikipedia.org/wiki/Proton> or C<u> for L<atomic mass
unit|https://en.wikipedia.org/wiki/Dalton_(unit)>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>force(1, 'pdl');>

Construct a L<force|https://en.wikipedia.org/wiki/Force> object. Unit must be
one of C<N> for L<Newton|https://en.wikipedia.org/wiki/Newton_(unit)>, C<kgf>
for L<kilogram-force|https://en.wikipedia.org/wiki/Kilogram-force>, C<lbf> for
L<pound-force|https://en.wikipedia.org/wiki/Pound_(force)> or C<pdl> for
L<poundal|https://en.wikipedia.org/wiki/Poundal>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>pressure(1, 'inHg');>

Construct a L<pressure|https://en.wikipedia.org/wiki/Pressure> object. Unit
must be one of C<pa> for
L<Pascal|https://en.wikipedia.org/wiki/Pascal_(unit)>, C<at> for L<technical
atmosphere|https://en.wikipedia.org/wiki/Kilogram-force_per_square_centimetre>,
C<atm> for L<standard
atmosphere|https://en.wikipedia.org/wiki/Standard_atmosphere_(unit)>, C<mH2O>
for L<meter of water|https://en.wikipedia.org/wiki/Centimetre_of_water>,
C<mmHg> for millimeter mercury, C<Torr> for
L<torr|https://en.wikipedia.org/wiki/Torr>, C<ftH2O> for foot of water, C<inH2O>
for L<inch of water|https://en.wikipedia.org/wiki/Inch_of_water>, C<inHg> for
L<inch of mercury|https://en.wikipedia.org/wiki/Inch_of_mercury> or C<psi> for
L<pounds per square
inch|https://en.wikipedia.org/wiki/Pounds_per_square_inch>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>temperature(1, 'C');>

Construct a L<temperature|https://en.wikipedia.org/wiki/Temperature> object.
Unit must be one of C<C> for degrees
L<Celsius|https://en.wikipedia.org/wiki/Celsius>, C<F> for degrees
L<Fahrenheit|https://en.wikipedia.org/wiki/Fahrenheit> or C<K> for
L<Kelvin|https://en.wikipedia.org/wiki/Kelvin>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>energy(1, 'J');>

Construct an L<energy|https://en.wikipedia.org/wiki/Energy> object. Unit must
be one of C<J> for L<Joule|https://en.wikipedia.org/wiki/Joule>, C<BTU> for
L<British thermal unit|https://en.wikipedia.org/wiki/British_thermal_unit>,
C<ftlbf> for L<foot-pound|https://en.wikipedia.org/wiki/Foot-pound_(energy)>,
C<hp> for L<horsepower|https://en.wikipedia.org/wiki/Horsepower>, C<cal15> for
L<15 degree calorie|https://en.wikipedia.org/wiki/Calorie>, C<calit> for
L<International calorie|https://en.wikipedia.org/wiki/Calorie> or C<calth> for
L<thermochemical calorie|https://en.wikipedia.org/wiki/Calorie>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>power(1, 'ps');>

Construct a L<power|https://en.wikipedia.org/wiki/Power_(physics)> object.
Unit must be one of C<W> for L<Watts|https://en.wikipedia.org/wiki/Watt>,
C<ps> for L<metric
horsepower|https://en.wikipedia.org/wiki/Horsepower#Metric_horsepower_(PS,_cv,_hk,_pk,_ks,_ch)>
or C<BTUh> for L<BTU per
hour|https://en.wikipedia.org/wiki/British_thermal_unit#As_a_unit_of_power>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>linear_density(1, 'D');>

Construct a L<linear density|https://en.wikipedia.org/wiki/Linear_density>
object. Unit must be one of C<D> for
L<Denier|https://en.wikipedia.org/wiki/Units_of_textile_measurement#Denier> or
C<kgpm> for kilogram per meter.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>field_equation(1, 'G');>

Construct a L<field
equation|https://en.wikipedia.org/wiki/Einstein_field_equations> object. Unit
must be one of C<G> for L<gravitational
constant|https://en.wikipedia.org/wiki/Gravitational_constant> or C<Nm2pkg2>
for Newton meter squared per kilogram squared.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>heat_capacity(1,
'BTUlbR');>

Construct a L<heat capacity|https://en.wikipedia.org/wiki/Heat_capacity>
object. Unit must be one of C<BTUlbR> (British thermal unit per pound
L<Rankine|https://en.wikipedia.org/wiki/Rankine_scale>) for L<specific heat
capacity|https://en.wikipedia.org/wiki/Specific_heat_capacity#English_(Imperial)_engineering_units>
or C<JpkgK> for Joule per kilogram Kelvin.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>thermodynamic(1,
'BTUlb');>

Construct a L<thermodynamic|https://en.wikipedia.org/wiki/Thermodynamics>
object. Unit must be one of C<BTUlb> for L<specific internal
energy|https://en.wikipedia.org/wiki/Internal_energy> or C<Jpkg> for Joule per
kilogram.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>magnetic(1, 'muB');>

Construct a L<magnetic object|https://en.wikipedia.org/wiki/Bohr_magneton>.
Unit must be one of C<muB> for L<Bohr
magneton|https://en.wikipedia.org/wiki/Bohr_magneton>, C<mue> for L<magnetic
moment of electron|https://en.wikipedia.org/wiki/Electron_magnetic_moment>,
C<muN> for L<nuclear
magneton|https://en.wikipedia.org/wiki/Neutron_magnetic_moment>, C<mup> for
L<magnetic moment of
proton|https://en.wikipedia.org/wiki/Proton_magnetic_moment> or C<Am2> for
Ampere meter squared.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>gyromagnetic(1, 'gammap');>

Construct a L<gyromagnetic|https://en.wikipedia.org/wiki/Gyromagnetic_ratio>
object. Unit must be one of C<gammap> for gyromagnetic ratio of proton,
C<gammapalt> for gyromagnetic ratio of proton in water or C<Am2pJs> for Ampere
meter squared per Joule second.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>electromagnetic(1, 'h');>

Construct a electromagnetic object. Unit must be one of
C<h> for L<Planck constant|https://en.wikipedia.org/wiki/Planck_constant>,
C<hbar> for Planck constant per 2 Pi or C<Js> for Joule second.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>spectroscopic(1,
'Rinf');>

Construct a L<spectroscopic|https://en.wikipedia.org/wiki/Spectroscopy>
object. Unit must be one of C<Rinf> for L<Rydberg constant for heavy
atoms|https://en.wikipedia.org/wiki/Rydberg_constant> or C<pm> for per meter.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>radioactive(1, 'Ci');>

Construct a L<radioactive|https://en.wikipedia.org/wiki/Radioactive_decay>
object. Unit must be one of C<Ci> for
L<Curie|https://en.wikipedia.org/wiki/Curie_(unit)> or C<Bq> for
L<becquerel|https://en.wikipedia.org/wiki/Becquerel>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>radiation(1, 'R');>

Construct a L<radiation|https://en.wikipedia.org/wiki/Ionizing_radiation>
object. Unit must be one of C<R> for
L<Rontgen|https://en.wikipedia.org/wiki/Roentgen_(unit)> or C<Cpkg> for
coulomb per kilogram.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>flux(1, 'phi0');>

Construct a L<quantum
flux|https://en.wikipedia.org/wiki/Magnetic_flux_quantum> object. Unit must be
one of C<phi0> for L<magnetic flux
quantum|https://en.wikipedia.org/wiki/Magnetic_flux_quantum> or C<Wb> for
L<weber|https://en.wikipedia.org/wiki/Weber_(unit)>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>wavelength(1, 'c1');>

Construct a L<wavelength|https://en.wikipedia.org/wiki/Planck%27s_law> object.
Unit must be one of C<c1> for first radiation constant or C<Wm2> for Watt
meter squared.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>wavenumber(1, 'c2');>

Construct a L<wavenumber|https://en.wikipedia.org/wiki/Planck%27s_law> object.
Unit must be one of C<c2> for second radiation constant or C<mK> for meter
Kelvin.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>luminance(1, 'lam');>

Construct a L<luminance|https://en.wikipedia.org/wiki/Luminance> object. Unit
must be one of C<lam> for
L<lambert|https://en.wikipedia.org/wiki/Lambert_(unit)>, C<flam> for
L<footlambert|https://en.wikipedia.org/wiki/Foot-lambert> or C<cdpm2> for
L<candela per square
meter|https://en.wikipedia.org/wiki/Candela_per_square_metre>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>charge(1, 'e');>

Construct a L<charge|https://en.wikipedia.org/wiki/Electric_charge> object.
Unit must be one of C<e> for L<elementary
charge|https://en.wikipedia.org/wiki/Elementary_charge> or C<C> for
L<coulomb|https://en.wikipedia.org/wiki/Coulomb>.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>electrolysis(1, 'F');>

Construct an L<electrolysis|https://en.wikipedia.org/wiki/Electrolysis>
object. Unit must be one of C<f> for L<Faraday
constant|https://en.wikipedia.org/wiki/Faraday_constant> (lowercase to avoid
conflict with Fahrenheit) or C<Cpmol> for coulombs per mole.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>entropy(1, 'k');>

Construct an L<entropy|https://en.wikipedia.org/wiki/Entropy> object. Unit
must be one of C<k> for L<Boltzmann
constant|https://en.wikipedia.org/wiki/Boltzmann_constant> or C<JpK> for Joule
per Kelvin.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>proportionality(1,
'Na');>

Construct a
L<proportionality|https://en.wikipedia.org/wiki/Proportionality_(mathematics)>
object. Unit must be one of C<Na> for L<Avogadro
constant|https://en.wikipedia.org/wiki/Avogadro_constant> or C<pmol> for per
mole.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>gas(1, 'R');>

Construct a L<gas|https://en.wikipedia.org/wiki/Ideal_gas_law> object. Unit
must be one of C<R> for L<molar gas
constant|https://en.wikipedia.org/wiki/Gas_constant> or C<JpmolK> for Joule
per mole Kelvin.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>mixture(1, 'Vm');>

Construct a L<mixture|https://en.wikipedia.org/wiki/Ideal_solution> object.
Unit must be one of C<Vm> for L<molar
volume|https://en.wikipedia.org/wiki/Molar_volume> or C<m3pmol> for cubic
meter per mole.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>isotropic(1, 'alpha');>

Construct an L<isotropic|https://en.wikipedia.org/wiki/Polarizability> object.
Unit must be one of C<alpha> for polarizability of molecule or C<Cm2pV> for
coulomb meter squared per Volt.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>susceptibility(1, 'p');>

Construct a
L<susceptibility|https://en.wikipedia.org/wiki/Electric_susceptibility>
object. Unit must be one of C<p> for dipole of molecule or C<Cm> for coulomb
meter.

=item C<$f = Class::Measure::Scientific::FX_992vb-E<gt>displacement(1, 'Ds');>

Construct a
L<displacement|https://en.wikipedia.org/wiki/Electric_displacement_field>
object. Unit must be one of C<Ds> for G. electric flux density, C<Ps> for G.
electric polarization or C<Cpm2> for coulomb per square meter.

=item C<Class::Measure::Scientific::FX_992vb::CONST(1);>

All constants are available as the class method C<CONST> which takes the index
of the constant as argument as number from 1 to 128. This is the way the
constants are recalled on the CASIO fx-992vb.

=back

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over 4

=item * Perl 5.16

=item * L<Moose>

=item * L<MooseX::NonMoose>

=item * L<Class::Measure> 0.08 or newer

=item * L<List::MoreUtils>

=item * L<Log::Log4perl>

=back

=head1 INCOMPATIBILITIES

This module has the same incompatibilities as L<Class::Measure>.

=head1 DIAGNOSTICS

This module uses L<Log::Log4perl> for logging.

=head1 BUGS AND LIMITATIONS

The values are based on the constants from the CASIO fx-992vb scientific
calculator from the 90s, which are based on JIS-Z-8202-1988 (Japan Industrial
Standards). These are not the latest standards and should not be used when
more accurate values than those displayed in a pocket calculator from that era
are expected. For example the L<2019 redefinition of the SI base
units|https://en.wikipedia.org/wiki/2019_redefinition_of_the_SI_base_units> is
not and won't be implemented in this module.

=head2 Interval scales

While the CASIO fx-992vb has the constants to convert between Celsius,
Fahrenheit and Kelvin - using zero Celsius in Kelvin, zero Fahrenheit in
Celsius and degree Fahrenheit in Kelvin/Celsius - Celsius and Fahrenheit are
only units on interval scales as opposed to Kelvin which has a defined
thermodynamic zero which makes it a unit on a ratio scale. This module does of
course convert directly between those scales, but for completeness the
constants used in those calculations can also be accessed as class methods.

=over 4

=item * Zero Celsius C<Class::Measure::Scientific::FX_992vb::zC()> as
I<273.15> Kelvin

=item * Zero Fahrenheit C<Class::Measure::Scientific::FX_992vb::zF()> as
I<-160/9> Celsius

=item * Fahrenheit Kelvin ratio C<Class::Measure::Scientific::FX_992vb::FK()>
as I<5/9>

=back

=head2 Dimensionless quantities

Some constants are dimensionless quantities, which means they are independent
of the system of unit used and can't be used to convert between units so they
are useless in the functionality of this module. These dimensionless quantity
constants are listed here for completeness and are available as class methods.

=over 4

=item * L<Decibel|https://en.wikipedia.org/wiki/Decibel> level difference
C<Class::Measure::Scientific::FX_992vb::dB()> as I<0.11512925465>

=item * L<Neper|https://en.wikipedia.org/wiki/Neper> level difference
C<Class::Measure::Scientific::FX_992vb::Np()> as I<8.68588963807>

=item * L<Fine-structure
constant|https://en.wikipedia.org/wiki/Fine-structure_constant>
C<Class::Measure::Scientific::FX_992vb::a()> as I<7.2973506e-3>

=back

Please report any bugs or feature requests at
L<Bitbucket|
https://bitbucket.org/rolandvanipenburg/class-measure-scientific-fx_992vb/issues>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>roland@rolandvanipenburg.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2020-2021 by Roland van Ipenburg
This program is free software; you can redistribute it and/or modify
it under the GNU General Public License v3.0.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
