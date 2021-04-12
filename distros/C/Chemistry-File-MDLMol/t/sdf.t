use Test::More tests => 15;
BEGIN { use_ok('Chemistry::File::SDF') };

use strict;
use warnings;

# Read all at once

my @mols = Chemistry::Mol->read("t/sdf/1.sdf");

ok(@mols == 8, "read 8");
my $i;
for my $mol(@mols) {
    $i++ if $mol->isa('Chemistry::Mol');
}

ok($i == @mols, "isa Chemistry::Mol");
is($mols[1]->name, "[2-(4-Bromo-phenoxy)-ethyl]-(4-dimethylamino-6-methoxy-[1,3,5]triazin-2-yl)-cyan", "name");
ok($mols[1]->attr("sdf/data")->{'PKA'} == 4.65, "attr");


# sequential read

my $reader = Chemistry::Mol->file('t/sdf/1.sdf');
isa_ok( $reader, 'Chemistry::File' );

$reader->open;
$reader->read_header;

$reader->skip_mol($reader->fh);
my $mol = $reader->read_mol($reader->fh);
isa_ok( $mol, "Chemistry::Mol" );
is($mol->name, "[2-(4-Bromo-phenoxy)-ethyl]-(4-dimethylamino-6-methoxy-[1,3,5]triazin-2-yl)-cyan", "name");
ok($mol->attr("sdf/data")->{'PKA'} == 4.65, "attr");
$i = 2;
$i++ while ($reader->skip_mol($reader->fh));
is($i, 8, "sequential read 8");


# read/write test

my $fname = "t/sdf/rw.sdf";
open F, "<", "$fname" or die "couldn't open $fname; $!\n";
my $sdf_str;
{ local $/; $sdf_str = <F> }
@mols = Chemistry::Mol->parse($sdf_str, format => 'sdf');
my $sdf_out = Chemistry::Mol->print(format => 'sdf', mols => \@mols);
ok($sdf_str eq $sdf_out, "read-write test");


# test isotopes

my $C13_ISO = 13;
my $C13_atom_block = 12.0107;
my $M_ISO_out = 'M  ISO  1   2  13';
if( eval { require Chemistry::Isotope } ) {
    $C13_ISO = $C13_atom_block = Chemistry::Isotope::isotope_mass(13, 6);
    $M_ISO_out = 'M  ISO  2   2  13   3  13';
}
@mols = Chemistry::Mol->read("t/sdf/C.sdf");
my @atoms = $mols[0]->atoms;
is($atoms[0]->mass, 12.0107);
is($atoms[1]->mass, $C13_ISO);
is($atoms[2]->mass, $C13_atom_block);
my( $M_ISO ) = grep { /^M  ISO/ }
                    split "\n", Chemistry::Mol->print(format => 'sdf',
                                                      mols => \@mols);
is($M_ISO, $M_ISO_out);
