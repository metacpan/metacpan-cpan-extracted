use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

plan tests => 59;

require Class::Measure::Scientific::FX_992vb;
my $m = Class::Measure::Scientific::FX_992vb->linear_density( 1, 'D' );
is( $m->D(),    1,                    q{1 denier via linear density} );
is( $m->kgpm(), 1.11111111111111e-07, q{1 denier in kg per meter} );
$m = Class::Measure::Scientific::FX_992vb->linear_density( 1, 'kgpm' );
is( $m->kgpm(), 1,         q{1 kg per meter via linear density} );
is( $m->D(),    9_000_000, q{1kg/m in denier} );
$m = Class::Measure::Scientific::FX_992vb->field_equation( 1, 'G' );
is( $m->G(),       1,         q{1 G via field equation} );
is( $m->Nm2pkg2(), 6.672e-11, q{1G in Newton m2 per kg2} );
$m = Class::Measure::Scientific::FX_992vb->heat_capacity( 1, 'BTUlbR' );
is( $m->BTUlbR(), 1,       q{1 BTUlbR via heat capacity} );
is( $m->JpkgK(),  4_186.8, q{1 BTUlbR in Joule per kilogram Kelvin} );
$m = Class::Measure::Scientific::FX_992vb->thermodynamic( 1, 'BTUlb' );
is( $m->BTUlb(), 1,     q{1 BTUlb via thermodynamic} );
is( $m->Jpkg(),  2_326, q{1 BTUlb in Joule per kilogram} );
$m = Class::Measure::Scientific::FX_992vb->magnetic( 1, 'Am2' );
is( $m->Am2(), 1,                   q{1 Am2 via magnetic} );
is( $m->muB(), 1.07827430392541e23, q{1 Ampere m2 in Bohr magneton} );
is( $m->mue(), 1.07703259125393e+23,
    q{1 Ampere m2 in magnetic moment of electron} );
is( $m->muN(), 1.97987496693609e+26, q{1 Ampere m2 in nuclear magneton} );
is( $m->mup(), 7.0891436634175e+25,
    q{1 Ampere m2 in magnetic moment of proton} );
$m = Class::Measure::Scientific::FX_992vb->gyromagnetic( 1, 'gammap' );
is( $m->gammap(), 1, q{1 Ampere m2 per Joule second via gyromagnetic} );
is( $m->gammapalt(), 1.00002564361262,
    q{1 gyromagnetic ratio in gyromagnetic ratio in water} );
$m = Class::Measure::Scientific::FX_992vb->electromagnetic( 1, 'h' );
is( $m->h(),    1,                q{1 Planck constant via electromagnetic} );
is( $m->hbar(), 6.28318509386645, q{1 Planck constant per radian} );
$m = Class::Measure::Scientific::FX_992vb->spectroscopic( 1, 'Rinf' );
is( $m->Rinf(), 1,           q{1 Rydberg constant via spectroscopic} );
is( $m->pm(),   10973731.77, q{1 Rydberg constant in per meter} );
$m = Class::Measure::Scientific::FX_992vb->radioactive( 1, 'Ci' );
is( $m->Ci(), 1,           q{1 Curie via radioactive} );
is( $m->Bq(), 37000000000, q{1 Curie in becquerel} );
$m = Class::Measure::Scientific::FX_992vb->radiation( 1, 'R' );
is( $m->R(),    1,        q{1 Rontgen via radiation} );
is( $m->Cpkg(), 0.000258, q{1 Rontgen in coulomb per kilogram} );
$m = Class::Measure::Scientific::FX_992vb->flux( 1, 'phi0' );
is( $m->phi0(), 1,             q{1 magnetic flux quantum via flux} );
is( $m->Wb(),   2.0678506e-15, q{1 magnetic flux quantum in weber} );
$m = Class::Measure::Scientific::FX_992vb->wavelength( 1, 'c1' );
is( $m->c1(),  1,            q{1 first radiation constant via wavelength} );
is( $m->Wm2(), 3.741832e-16, q{1 first radiation constant in Wm2} );
$m = Class::Measure::Scientific::FX_992vb->wavenumber( 1, 'c2' );
is( $m->c2(), 1,          q{1 second radiation constant via wavenumber} );
is( $m->mK(), 0.01438786, q{1 second radiation constant in mK} );
$m = Class::Measure::Scientific::FX_992vb->luminance( 1, 'lam' );
is( $m->lam(),   1,                q{1 lambert via luminance} );
is( $m->flam(),  929.030399999361, q{1 lambert in footlambert} );
is( $m->cdpm2(), 3183.09886184,    q{1 lambert in candela per square meter} );
$m = Class::Measure::Scientific::FX_992vb->luminance( 1, 'flam' );
is( $m->flam(), 1,                   q{1 footlambert via luminance} );
is( $m->lam(),  0.00107639104167171, q{1 footlambert in lambert} );
is( $m->cdpm2(), 3.42625909964, q{1 footlambert in candela per square meter} );
$m = Class::Measure::Scientific::FX_992vb->charge( 1, 'e' );
is( $m->e(), 1,             q{1 elementary charge via charge} );
is( $m->C(), 1.6021892e-19, q{1 elementary charge in Coulomb} );
$m = Class::Measure::Scientific::FX_992vb->electrolysis( 1, 'f' );
is( $m->f(),     1,        q{1 Faraday constant via electrolysis} );
is( $m->Cpmol(), 96484.56, q{1 Faraday constant in Coulomb per mol} );
$m = Class::Measure::Scientific::FX_992vb->entropy( 1, 'k' );
is( $m->k(),   1,            q{1 Boltzmann constant via entropy} );
is( $m->JpK(), 1.380662e-23, q{1 Boltzmann contant in Joule per Kelvin} );
$m = Class::Measure::Scientific::FX_992vb->proportionality( 1, 'Na' );
is( $m->Na(),   1,            q{1 Avogadro constant via proportionality} );
is( $m->pmol(), 6.022045e+23, q{1 Avogadro contant in per mole} );
$m = Class::Measure::Scientific::FX_992vb->gas( 1, 'R' );
is( $m->R(),      1,       q{1 molar gas constant via gas} );
is( $m->JpmolK(), 8.31441, q{1 molar gas constant in Joule per mole Kelvin} );
$m = Class::Measure::Scientific::FX_992vb->mixture( 1, 'Vm' );
is( $m->Vm(),     1,          q{1 molar volume via mixture} );
is( $m->m3pmol(), 0.02241383, q{1 molar volume in meter qubed per mole} );
$m = Class::Measure::Scientific::FX_992vb->isotropic( 1, 'alpha' );
is( $m->alpha(), 1, q{1 polarizability via isotropic} );
is( $m->Cm2pV(), 1.11265005605e-16,
    q{1 polarizabilty in Coulomb meter squared per Volt} );
$m = Class::Measure::Scientific::FX_992vb->susceptibility( 1, 'p' );
is( $m->p(),  1,                 q{1 dipole via suceptibility} );
is( $m->Cm(), 3.33564095198e-12, q{1 dipole in Coulomb meter} );
$m = Class::Measure::Scientific::FX_992vb->displacement( 1, 'Ds' );
is( $m->Ds(),  1,                 q{1 Ds via displacement} );
is( $m->Cpm2(), 2.65441872944e-07, q{1 Ds in Coulomb per quare meter} );
$m = Class::Measure::Scientific::FX_992vb->displacement( 1, 'Ps' );
is( $m->Ps(),  1,                 q{1 Ps via displacement} );
is( $m->Cpm2(), 3.33564095198e-06, q{1 Ps in Coulomb per quare meter} );
is( $m->Ds(), 12.5663706143443, q{1 Ps in Ds} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
