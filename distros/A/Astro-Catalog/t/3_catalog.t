#!perl

use strict;

use Test::More tests => 9;
use File::Temp;
use Data::Dumper;

BEGIN {
    use_ok "Astro::Catalog";
    use_ok "Astro::Catalog::Item";
}

my @star;

# STAR 1

# magnitude and colour hashes
my $flux1 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 16.1,
            Error => 0.1),
        'mag', 'R');
my $flux2 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 16.4,
            Error => 0.4),
        'mag', 'B');
my $flux3 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 16.3,
            Error => 0.3),
        'mag', 'V');
my $col1 = new Astro::FluxColor(
        upper => 'B', lower => 'V',
        quantity => new Number::Uncertainty(
            Value => 0.1,
            Error => 0.02));
my $col2 = new Astro::FluxColor(
        upper => 'B', lower => 'R',
        quantity => new Number::Uncertainty(
            Value => 0.3,
            Error => 0.05));
my $fluxes1 = new Astro::Fluxes($flux1, $flux2, $flux3, $col1, $col2);

# create a star
$star[0] = new Astro::Catalog::Item(
        ID         => 'U1500_01194794',
        RA         => '09 55 39',
        Dec        => '+60 07 23.6',
        Fluxes     => $fluxes1,
        Quality    => '0',
        GSC        => 'FALSE',
        Distance   => '0.09',
        PosAngle   => '50.69',
        Field      => '00080');

# STAR 2

# magnitude and colour hashes
my $flux4 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 9.5,
            Error => 0.6 ),
        'mag', 'R' );
my $flux5 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 9.3,
            Error => 0.2 ),
        'mag', 'B' );
my $flux6 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 9.1,
            Error => 0.1),
        'mag', 'V');
my $col3 = new Astro::FluxColor(
        upper => 'B', lower => 'V',
        quantity => new Number::Uncertainty(
            Value => -0.2,
            Error => 0.05));
my $col4 = new Astro::FluxColor(
        upper => 'B', lower => 'R',
        quantity => new Number::Uncertainty(
            Value => 0.2,
            Error => 0.07));
my $fluxes2 = new Astro::Fluxes($flux4, $flux5, $flux6, $col3, $col4);

# create a star
$star[1] = new Astro::Catalog::Item(
        ID         => 'U1500_01194795',
        RA         => '10 44 57',
        Dec        => '+12 34 53.5',
        Fluxes     => $fluxes2,
        Quality    => '0',
        GSC        => 'FALSE',
        Distance   => '0.08',
        PosAngle   => '12.567',
        Field      => '00081');

isa_ok($star[1], "Astro::Catalog::Item");

# Create Catalog Object
my $catalog = new Astro::Catalog(
        RA     => '01 10 12.9',
        Dec    => '+60 04 35.9',
        Radius => '1',
        Stars  => \@star);

isa_ok($catalog, "Astro::Catalog");

# Write Catalog to Cluster File

my $file_name = File::Temp->new();

# write it to /tmp/temporary.cat under UNIX
$catalog->write_catalog(Format => 'Cluster', File => $file_name);

# Compare output file and DATA block

# data block
my @buffer = <DATA>;
chomp @buffer;

# temporary file
open( FILE, $file_name );
my @file = <FILE>;
chomp @file;
close(FILE);

for my $i (0 .. $#buffer) {
   is($file[$i], $buffer[$i], "compare buffer");
}

exit;

__DATA__
5 colours were created
R B V B-V B-R
Origin: UNKNOWN   Field Centre: RA 01 10 12.90, Dec +60 04 35.90   Catalogue Radius: 1 arcmin
00080  0 09 55 39.00  60 07 23.60  0.000  0.000  16.1  0.1  0  16.4  0.4  0  16.3  0.3  0  0.1  0.02  0  0.3  0.05  0  
00081  1 10 44 57.00  12 34 53.50  0.000  0.000  9.5  0.6  0  9.3  0.2  0  9.1  0.1  0  -0.2  0.05  0  0.2  0.07  0  
