use strict;
use Test;
use warnings;

# pour trouver les modules dans le répertoire local
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;

use fundamentalUnit;
use derivedUnit;

BEGIN { plan tests => 18 }

# test_transformedUnitConversion 
{
  my $m = FundamentalUnit->new;
  my $km = $m->scaleMultiply(1000);
  my $cm = $m->scaleDivide(100);
  my $cmToKm = $cm->getConverterTo($km);

  ok($cmToKm->convert(3.0), 0.0000300000);
  ok($cmToKm->inverse->convert(0.00003), 3.0000000000);
}

# test_derivedUnitConversion
{
  my $m = FundamentalUnit->new;
  my $km = $m->scaleMultiply(1000);

  my $km2 = DerivedUnit->new($km->factor(2));
  my $cm = $m->scaleDivide(100);
  my $cm2 = DerivedUnit->new($cm->factor(2));
  my $km2Tocm2 = $km2->getConverterTo($cm2);

  ok($km2Tocm2->convert(3.), 30000000000.0000000000);
  ok($km2Tocm2->inverse()->convert(30000000000.), 3.0000000000);
}

# test_combinedDimensionDerivedUnitConversion
{
  my $m = FundamentalUnit->new;
  my $kg = FundamentalUnit->new;
  my $g = $kg->scaleDivide(1000);
  my $ton = $kg->scaleMultiply(1000);
  my $gPerM2 = DerivedUnit->new($g, $m->factor(-2));
  my $km = $m->scaleMultiply(1000);
  my $tonPerKm2 = DerivedUnit->new($ton, $km->factor(-2));
  my $cm = $m->scaleDivide(100);
  my $tonPerCm2 = DerivedUnit->new($ton, $cm->factor(-2));
  my $gPerM2ToTonPerKm2 = $gPerM2->getConverterTo($tonPerKm2);
  my $gPerM2ToTonPerCm2 = $gPerM2->getConverterTo($tonPerCm2);

  ok($gPerM2ToTonPerKm2->convert(1.), 1.0000000000);
  ok($gPerM2ToTonPerKm2->inverse->convert(3.), 3.0000000000);
  ok($gPerM2ToTonPerCm2->convert(1.), 1.0000000000e-10);
  ok($gPerM2ToTonPerCm2->convert(3.), 3.0000000000e-10);
  ok($gPerM2ToTonPerCm2->offset, 0.);
  ok($gPerM2ToTonPerCm2->scale, 1e-10);
  ok($gPerM2ToTonPerCm2->inverse->offset, -0);
  ok($gPerM2ToTonPerCm2->inverse->convert(3e-10), 3.0000000000);
}

# test_temperatures(self):
{
  my $k = FundamentalUnit->new;
  my $c = $k->shift(273.15);
  my $kToC = $k->getConverterTo($c);

  ok($kToC->convert(0), -273.1500000000);
  ok($kToC->inverse->convert(0), 273.1500000000);

  # en combinaison avec d'autres unites, les conversions d'unites de temperatures doivent devenir lineaires
  my $m = FundamentalUnit->new;
  my $cPerM = DerivedUnit->new($c, $m->factor(-1));
  my $kPerM = DerivedUnit->new($k, $m->factor(-1));
  my $kPerMToCPerM = $kPerM->getConverterTo($cPerM);

  ok($kPerMToCPerM->convert(3.), 3.0000000000);
  ok($kPerMToCPerM->inverse->convert(3.), 3.0000000000);
}


# test_speed
{
  my $m = FundamentalUnit->new;
  my $km = $m->scaleMultiply(1000.);

  my $s = FundamentalUnit->new;
  my $min = $s->scaleMultiply(60.);
  my $h = $s->scaleMultiply(3600.);

  my $ms = DerivedUnit->new($m, $s->factor(-1));
  my $kmh = DerivedUnit->new($km, $h->factor(-1));

  my $msToKmh = $ms->getConverterTo($kmh);

  ok($msToKmh->convert(100.), 360.0000000000);
  ok($msToKmh->inverse->convert(18.), 5.0000000000);
}
