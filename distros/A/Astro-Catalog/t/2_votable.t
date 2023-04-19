#!perl

use strict;
use Test::More;

# Astro::VO::VOTable is optional
BEGIN {
    eval {require Astro::VO::VOTable;};
    if ($@) {
        plan skip_all => "Astro::VO::VOTable not installed";
    }
    else {
        plan tests => 134;
    }
}

use File::Temp;
use Data::Dumper;
use Astro::Coords::Angle;
use Astro::Coords::Angle::Hour;

# Fix the precision used by Astro::Coords::Angle since we will be
# comparing values formatted as strings to this precision.
Astro::Coords::Angle->NDP(2);
Astro::Coords::Angle::Hour->NDP(3);

# load modules
require_ok("Astro::Catalog");
require_ok("Astro::Catalog::Item");
require_ok("Astro::VO::VOTable");

# Load the generic test code
my $p = (-d "t" ? "t/" : "");
do $p."helper.pl" or die "Error reading test functions: $!";

# GENERATE A CATALOG

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

isa_ok($star[0], "Astro::Catalog::Item");

# STAR 2

# magnitude and colour hashes
my $flux4 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 9.5,
            Error => 0.6),
        'mag', 'R');
my $flux5 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 9.3,
            Error => 0.2),
        'mag', 'B');
my $flux6 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 9.1,
            Error => 0.1),
        'mag', 'V' );
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

my $tempfile; # for cleanup

# Write it out to disk using the votable writer
$tempfile = File::Temp->new();

ok($catalog->write_catalog(Format => 'VOTable', File => $tempfile),
    "Check catalog write");
ok(-e $tempfile, "Check file exists");


# Read the votable back from disk into an array

my $opstat = open(my $CAT, $tempfile);
ok( $opstat, "Read catalog from disk" );
my @file;
@file = <$CAT>;
chomp @file;
ok(close($CAT), "Closing catalog file");


# Read comparison catalog from __DATA__

my @buffer = <DATA>;
chomp @buffer;

# Compare @file and @data

foreach my $i (0 .. $#buffer) {
    is($buffer[$i], $file[$i], "Line $i in \@buffer ok");
}

# Read catalog in from temporary file using the votable reader

my $read_catalog = new Astro::Catalog(Format => 'VOTable', File => $tempfile);

# Generate a catalog

my @star2;

# STAR 3

# magnitude and colour hashes
my $flux7 = new Astro::Flux(
        new Number::Uncertainty (
            Value => 16.1),
        'mag', 'R');
my $flux8 = new Astro::Flux(
        new Number::Uncertainty (
            Value => 16.4),
        'mag', 'B');
my $flux9 = new Astro::Flux(
        new Number::Uncertainty (
            Value => 16.3),
        'mag', 'V');
my $col5 = new Astro::FluxColor(
        upper => 'B', lower => 'V',
        quantity => new Number::Uncertainty(
            Value => 0.1));
my $col6 = new Astro::FluxColor(
        upper => 'B', lower => 'R',
        quantity => new Number::Uncertainty(
            Value => 0.3));
my $fluxes3 = new Astro::Fluxes($flux7, $flux8, $flux9, $col5, $col6);

# create a star
$star2[0] = new Astro::Catalog::Item(
        ID         => 'U1500_01194794',
        RA         => '09 55 39',
        Dec        => '+60 07 23.6',
        Fluxes     => $fluxes3,
        Quality    => '0' );
isa_ok($star2[0], "Astro::Catalog::Item");

# STAR 4

# magnitude and colour hashes
my $flux10 = new Astro::Flux(
        new Number::Uncertainty (
            Value => 9.5),
        'mag', 'R');
my $flux11 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 9.3),
        'mag', 'B');
my $flux12 = new Astro::Flux(
        new Number::Uncertainty(
            Value => 9.1),
        'mag', 'V');
my $col7 = new Astro::FluxColor(
        upper => 'B', lower => 'V',
        quantity => new Number::Uncertainty(
            Value => -0.2));
my $col8 = new Astro::FluxColor(
        upper => 'B', lower => 'R',
        quantity => new Number::Uncertainty(
            Value => 0.2));
my $fluxes4 = new Astro::Fluxes($flux10, $flux11, $flux12, $col7, $col8);

# create a star
$star2[1] = new Astro::Catalog::Item(
        ID         => 'U1500_01194795',
        RA         => '10 44 57',
        Dec        => '+12 34 53.5',
        Fluxes     => $fluxes4,
        Quality    => '0');

isa_ok($star2[1], "Astro::Catalog::Item");

# Create Catalog Object

my $catalog2 = new Astro::Catalog(Stars  => \@star2);

isa_ok($catalog2, "Astro::Catalog");

# Compare catalogs

compare_catalog($read_catalog, $catalog2);

exit;

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<VOTABLE>
  <DESCRIPTION>Created using Astro::Catalog::IO::VOTable</DESCRIPTION>
  <DEFINITIONS>
    <COOSYS ID="J2000" equinox="2000" epoch="2000" system="eq_FK5"/>
  </DEFINITIONS>
  <RESOURCE>
    <LINK title="eSTAR Project" href="http://www.estar.org.uk/" content-role="doc"/>
    <TABLE>
      <FIELD name="Identifier" ucd="ID_MAIN" datatype="char" unit="" arraysize="*"/>
      <FIELD name="RA" ucd="POS_EQ_RA_MAIN" datatype="char" unit="&quot;h:m:s.ss&quot;" arraysize="*"/>
      <FIELD name="Dec" ucd="POS_EQ_DEC_MAIN" datatype="char" unit="&quot;d:m:s.ss&quot;" arraysize="*"/>
      <FIELD name="R Magnitude" ucd="PHOT_MAG_R" datatype="double" unit="mag"/>
      <FIELD name="R Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="B Magnitude" ucd="PHOT_MAG_B" datatype="double" unit="mag"/>
      <FIELD name="B Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="V Magnitude" ucd="PHOT_MAG_V" datatype="double" unit="mag"/>
      <FIELD name="V Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="B-V Colour" ucd="PHOT_CI_B-V" datatype="double" unit="mag"/>
      <FIELD name="B-V Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="B-R Colour" ucd="PHOT_CI_B-R" datatype="double" unit="mag"/>
      <FIELD name="B-R Error" ucd="CODE_ERROR" datatype="double" unit="mag"/>
      <FIELD name="Quality" ucd="CODE_QUALITY" datatype="int" unit=""/>
      <DATA>
        <TABLEDATA>
          <TR>
            <TD>U1500_01194794</TD>
            <TD>09:55:39.000</TD>
            <TD> 60:07:23.60</TD>
            <TD>16.1</TD>
            <TD>0.1</TD>
            <TD>16.4</TD>
            <TD>0.4</TD>
            <TD>16.3</TD>
            <TD>0.3</TD>
            <TD>0.1</TD>
            <TD>0.02</TD>
            <TD>0.3</TD>
            <TD>0.05</TD>
            <TD>0</TD>
          </TR>
          <TR>
            <TD>U1500_01194795</TD>
            <TD>10:44:57.000</TD>
            <TD> 12:34:53.50</TD>
            <TD>9.5</TD>
            <TD>0.6</TD>
            <TD>9.3</TD>
            <TD>0.2</TD>
            <TD>9.1</TD>
            <TD>0.1</TD>
            <TD>-0.2</TD>
            <TD>0.05</TD>
            <TD>0.2</TD>
            <TD>0.07</TD>
            <TD>0</TD>
          </TR>
        </TABLEDATA>
      </DATA>
    </TABLE>
  </RESOURCE>
</VOTABLE>
