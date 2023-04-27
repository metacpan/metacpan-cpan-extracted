use strict;
use warnings;

# pour trouver les modules dans le répertoire local
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;

use fundamentalUnit;
use derivedUnit;

my $m = FundamentalUnit->new;
my $km = $m->scaleMultiply(1000.);
my $cm = $m->scaleDivide(100.);

my $kmToCm = $km->getConverterTo($cm);
print $kmToCm->convert(5), "\n";
print $kmToCm->inverse->convert(5), "\n";

my $m2 = DerivedUnit->new($m->factor(2));
my $km2 = DerivedUnit->new($km->factor(2));
my $cm2 = DerivedUnit->new($cm->factor(2));

my $cm2ToKm2 = $cm2->getConverterTo($km2);
print $cm2ToKm2->convert(3), "\n";
print $cm2ToKm2->inverse->convert(4), "\n";
