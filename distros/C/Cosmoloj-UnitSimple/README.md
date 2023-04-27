# Simple Unit (implémentation Perl)

## Utilisation

Utilisation des unités transformées :

```pl
use fundamentalUnit;

my $m = FundamentalUnit->new;
my $km = $m->scaleMultiply(1000);
my $cm = $m->scaleDivide(100);
my $cmToKm = $cm->getConverterTo($km);

$cmToKm->convert(3.0); # 0.00003
$cmToKm->inverse->convert(0.00003); # 3
```

Utilisation des unités dérivées :

```pl
use fundamentalUnit;
use derivedUnit;

my $m = FundamentalUnit->new;
my $km = $m->scaleMultiply(1000);

my $km2 = DerivedUnit->new($km->factor(2));
my $cm = $m->scaleDivide(100);
my $cm2 = DerivedUnit->new($cm->factor(2));
my $km2Tocm2 = $km2->getConverterTo($cm2);

$km2Tocm2->convert(3.); # 30000000000
$km2Tocm2->inverse()->convert(30000000000.); # 3
```

Utilisation des unités dérivées en combinant les dimensions :

```pl
use fundamentalUnit;
use derivedUnit;

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

$gPerM2ToTonPerKm2->convert(1.); # 1
$gPerM2ToTonPerKm2->inverse->convert(3.); # 3
$gPerM2ToTonPerCm2->convert(1.); # 1e-4
$gPerM2ToTonPerCm2->convert(3.); # 3e-10
$gPerM2ToTonPerCm2->offset; # 0.0
$gPerM2ToTonPerCm2->scale; # 1e-10
$gPerM2ToTonPerCm2->inverse->offset; # -0.0
$gPerM2ToTonPerCm2->inverse->convert(3e-10); # 3
```

Utilisation des températures (conversions affines et linéaires) :

```pl
use fundamentalUnit;

my $k = FundamentalUnit->new;
my $c = $k->shift(273.15);
my $kToC = $k->getConverterTo($c);

$kToC->convert(0); # -273.15
$kToC->inverse->convert(0); # 273.15

# en combinaison avec d'autres unites, les conversions d'unites de temperatures doivent devenir lineaires
my $m = FundamentalUnit->new;
my $cPerM = DerivedUnit->new($c, $m->factor(-1));
my $kPerM = DerivedUnit->new($k, $m->factor(-1));
my $kPerMToCPerM = $kPerM->getConverterTo($cPerM);

$kPerMToCPerM->convert(3.); # 3
$kPerMToCPerM->inverse->convert(3.); # 3
```

Utilisation des conversions non décimales :

```pl
use fundamentalUnit;
use derivedUnit;

my $m = FundamentalUnit->new;
my $km = $m->scaleMultiply(1000.);

my $s = FundamentalUnit->new;
my $min = $s->scaleMultiply(60.);
my $h = $s->scaleMultiply(3600.);

my $ms = DerivedUnit->new($m, $s->factor(-1));
my $kmh = DerivedUnit->new($km, $h->factor(-1));

my $msToKmh = $ms->getConverterTo($kmh);

$msToKmh->convert(100.); # 360
$msToKmh->inverse->convert(18.); # 5
```
