use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 59;

sub iz {
    my ( $got, $exp, $msg ) = @_;
    my $FMT = q{%.15g};
    return is( sprintf( $FMT, $got ), sprintf( $FMT, $exp ), $msg );
}

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->linear_density( 1, 'D' );
iz( $m->D(),    1,                    q{1 denier via linear density} );
iz( $m->kgpm(), 1.11111111111111e-07, q{1 denier in kg per meter} );
$m = Class::Measure::Scientific::FX_992vb->linear_density( 1, 'kgpm' );
iz( $m->kgpm(), 1,         q{1 kg per meter via linear density} );
iz( $m->D(),    9_000_000, q{1kg/m in denier} );
$m = Class::Measure::Scientific::FX_992vb->field_equation( 1, 'G' );
iz( $m->G(),       1,         q{1 G via field equation} );
iz( $m->Nm2pkg2(), 6.672e-11, q{1G in Newton m2 per kg2} );
$m = Class::Measure::Scientific::FX_992vb->heat_capacity( 1, 'BTUlbR' );
iz( $m->BTUlbR(), 1,       q{1 BTUlbR via heat capacity} );
iz( $m->JpkgK(),  4_186.8, q{1 BTUlbR in Joule per kilogram Kelvin} );
$m = Class::Measure::Scientific::FX_992vb->thermodynamic( 1, 'BTUlb' );
iz( $m->BTUlb(), 1,     q{1 BTUlb via thermodynamic} );
iz( $m->Jpkg(),  2_326, q{1 BTUlb in Joule per kilogram} );
$m = Class::Measure::Scientific::FX_992vb->magnetic( 1, 'Am2' );
iz( $m->Am2(), 1,                   q{1 Am2 via magnetic} );
iz( $m->muB(), 1.07827430392541e23, q{1 Ampere m2 in Bohr magneton} );
iz( $m->mue(), 1.07703259125393e+23,
    q{1 Ampere m2 in magnetic moment of electron} );
iz( $m->muN(), 1.97987496693609e+26, q{1 Ampere m2 in nuclear magneton} );
iz( $m->mup(), 7.0891436634175e+25,
    q{1 Ampere m2 in magnetic moment of proton} );
$m = Class::Measure::Scientific::FX_992vb->gyromagnetic( 1, 'gammap' );
iz( $m->gammap(), 1, q{1 Ampere m2 per Joule second via gyromagnetic} );
iz( $m->gammapalt(), 1.00002564361262,
    q{1 gyromagnetic ratio in gyromagnetic ratio in water} );
$m = Class::Measure::Scientific::FX_992vb->electromagnetic( 1, 'h' );
iz( $m->h(),    1,                q{1 Planck constant via electromagnetic} );
iz( $m->hbar(), 6.28318509386645, q{1 Planck constant per radian} );
$m = Class::Measure::Scientific::FX_992vb->spectroscopic( 1, 'Rinf' );
iz( $m->Rinf(), 1,           q{1 Rydberg constant via spectroscopic} );
iz( $m->pm(),   10973731.77, q{1 Rydberg constant in per meter} );
$m = Class::Measure::Scientific::FX_992vb->radioactive( 1, 'Ci' );
iz( $m->Ci(), 1,           q{1 Curie via radioactive} );
iz( $m->Bq(), 37000000000, q{1 Curie in becquerel} );
$m = Class::Measure::Scientific::FX_992vb->radiation( 1, 'R' );
iz( $m->R(),    1,        q{1 Rontgen via radiation} );
iz( $m->Cpkg(), 0.000258, q{1 Rontgen in coulomb per kilogram} );
$m = Class::Measure::Scientific::FX_992vb->flux( 1, 'phi0' );
iz( $m->phi0(), 1,             q{1 magnetic flux quantum via flux} );
iz( $m->Wb(),   2.0678506e-15, q{1 magnetic flux quantum in weber} );
$m = Class::Measure::Scientific::FX_992vb->wavelength( 1, 'c1' );
iz( $m->c1(),  1,            q{1 first radiation constant via wavelength} );
iz( $m->Wm2(), 3.741832e-16, q{1 first radiation constant in Wm2} );
$m = Class::Measure::Scientific::FX_992vb->wavenumber( 1, 'c2' );
iz( $m->c2(), 1,          q{1 second radiation constant via wavenumber} );
iz( $m->mK(), 0.01438786, q{1 second radiation constant in mK} );
$m = Class::Measure::Scientific::FX_992vb->luminance( 1, 'lam' );
iz( $m->lam(),   1,                q{1 lambert via luminance} );
iz( $m->flam(),  929.030399999361, q{1 lambert in footlambert} );
iz( $m->cdpm2(), 3183.09886184,    q{1 lambert in candela per square meter} );
$m = Class::Measure::Scientific::FX_992vb->luminance( 1, 'flam' );
iz( $m->flam(), 1,                   q{1 footlambert via luminance} );
iz( $m->lam(),  0.00107639104167171, q{1 footlambert in lambert} );
iz( $m->cdpm2(), 3.42625909964, q{1 footlambert in candela per square meter} );
$m = Class::Measure::Scientific::FX_992vb->charge( 1, 'e' );
iz( $m->e(), 1,             q{1 elementary charge via charge} );
iz( $m->C(), 1.6021892e-19, q{1 elementary charge in Coulomb} );
$m = Class::Measure::Scientific::FX_992vb->electrolysis( 1, 'f' );
iz( $m->f(),     1,        q{1 Faraday constant via electrolysis} );
iz( $m->Cpmol(), 96484.56, q{1 Faraday constant in Coulomb per mol} );
$m = Class::Measure::Scientific::FX_992vb->entropy( 1, 'k' );
iz( $m->k(),   1,            q{1 Boltzmann constant via entropy} );
iz( $m->JpK(), 1.380662e-23, q{1 Boltzmann contant in Joule per Kelvin} );
$m = Class::Measure::Scientific::FX_992vb->proportionality( 1, 'Na' );
iz( $m->Na(),   1,            q{1 Avogadro constant via proportionality} );
iz( $m->pmol(), 6.022045e+23, q{1 Avogadro contant in per mole} );
$m = Class::Measure::Scientific::FX_992vb->gas( 1, 'R' );
iz( $m->R(),      1,       q{1 molar gas constant via gas} );
iz( $m->JpmolK(), 8.31441, q{1 molar gas constant in Joule per mole Kelvin} );
$m = Class::Measure::Scientific::FX_992vb->mixture( 1, 'Vm' );
iz( $m->Vm(),     1,          q{1 molar volume via mixture} );
iz( $m->m3pmol(), 0.02241383, q{1 molar volume in meter qubed per mole} );
$m = Class::Measure::Scientific::FX_992vb->isotropic( 1, 'alpha' );
iz( $m->alpha(), 1, q{1 polarizability via isotropic} );
iz( $m->Cm2pV(), 1.11265005605e-16,
    q{1 polarizabilty in Coulomb meter squared per Volt} );
$m = Class::Measure::Scientific::FX_992vb->susceptibility( 1, 'p' );
iz( $m->p(),  1,                 q{1 dipole via suceptibility} );
iz( $m->Cm(), 3.33564095198e-12, q{1 dipole in Coulomb meter} );
$m = Class::Measure::Scientific::FX_992vb->displacement( 1, 'Ds' );
iz( $m->Ds(),  1,                 q{1 Ds via displacement} );
iz( $m->Cpm2(), 2.65441872944e-07, q{1 Ds in Coulomb per quare meter} );
$m = Class::Measure::Scientific::FX_992vb->displacement( 1, 'Ps' );
iz( $m->Ps(),  1,                 q{1 Ps via displacement} );
iz( $m->Cpm2(), 3.33564095198e-06, q{1 Ps in Coulomb per quare meter} );
iz( $m->Ds(), 12.5663706143443, q{1 Ps in Ds} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
