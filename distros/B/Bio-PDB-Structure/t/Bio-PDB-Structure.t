# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PDB-Molecule.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 37;
BEGIN { use_ok('Bio::PDB::Structure') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#create our pdb file
my $pdbfile ="ATOM      1  N   MET A   0      24.486   8.308  -9.406  1.00 37.00
ATOM      2  CA  MET A   0      24.542   9.777  -9.621  1.00 36.40
ATOM      3  C   MET A   0      25.882  10.156 -10.209  1.00 34.30
ATOM      4  O   MET A   0      26.833   9.391 -10.078  1.00 34.80
ATOM      5  CB  MET A   0      24.399  10.484  -8.303  1.00 39.00
ATOM      6  CG  MET A   0      24.756   9.581  -7.138  1.00 41.80
ATOM      7  SD  MET A   0      24.017  10.289  -5.719  1.00 44.80
ATOM      8  CE  MET A   0      24.761  12.009  -5.824  1.00 41.00
ATOM      9  N   VAL A   1      25.951  11.334 -10.816  1.00 31.10
ATOM     10  CA  VAL A   1      27.185  11.834 -11.382  1.00 28.40
ATOM     11  C   VAL A   1      27.330  13.341 -11.124  1.00 26.30
ATOM     12  O   VAL A   1      26.444  14.135 -11.452  1.00 26.60
ATOM     13  CB  VAL A   1      27.270  11.547 -12.912  1.00 29.30
ATOM     14  CG1 VAL A   1      28.532  12.207 -13.526  1.00 28.60
ATOM     15  CG2 VAL A   1      27.275  10.038 -13.163  1.00 29.70
ATOM     16  N   LEU A   2      28.435  13.739 -10.500  1.00 23.00
ATOM     17  CA  LEU A   2      28.691  15.142 -10.318  1.00 20.80
ATOM     18  C   LEU A   2      29.289  15.737 -11.599  1.00 20.10
ATOM     19  O   LEU A   2      30.129  15.110 -12.276  1.00 19.50
ATOM     20  CB  LEU A   2      29.661  15.356  -9.134  1.00 20.90
ATOM     21  CG  LEU A   2      29.036  15.387  -7.726  1.00 20.40
ATOM     22  CD1 LEU A   2      28.556  13.983  -7.402  1.00 19.60
ATOM     23  CD2 LEU A   2      30.058  15.904  -6.689  1.00 19.50
ATOM     24  N   SER A   3      28.996  17.003 -11.826  1.00 18.80
ATOM     25  CA  SER A   3      29.696  17.733 -12.852  1.00 19.40
ATOM     26  C   SER A   3      31.096  18.141 -12.385  1.00 19.50
ATOM     27  O   SER A   3      31.397  18.121 -11.174  1.00 19.10
ATOM     28  CB  SER A   3      28.861  18.954 -13.223  1.00 20.60
ATOM     29  OG  SER A   3      29.019  19.969 -12.261  1.00 22.10
END\n";
open(OUT,">temp.pdb") or die "could't create file\n";
print OUT $pdbfile;
close OUT;
my $mol = Bio::PDB::Structure::Molecule-> new;
my $atom = Bio::PDB::Structure::Atom -> new;
$mol -> read("temp.pdb");
close STDOUT;
my $out;
open (STDOUT, '>', \$out) or die "Cant open STDOUT\n";
$mol-> print;
##test that read write methods are working correctly
&ok($out eq $pdbfile, "pdb read/write test (Molecule)");
#assume method atom is working correctly or rest of tests will fail
$atom = $mol ->atom(1);
&ok($atom->type eq "ATOM", "type access (Atom)");
$atom->type("HETATM");
&ok($atom->type eq "HETATM", "type modification (Atom)");

&ok($atom->number == 2, "number access (Atom)");
$atom->number(5);
&ok($atom->number == 5, "number modification (Atom)");

&ok($atom->name eq "CA", "name access (Atom)");
$atom->name("CB");
&ok($atom->name eq "CB", "name modification (Atom)");

&ok($atom->residue_name eq "MET", "residue_name access (Atom)");
$atom->residue_name("ALA");
&ok($atom->residue_name eq "ALA", "residue_name modification (Atom)");

&ok($atom->chain eq "A", "chain access (Atom)");
$atom->chain("X");
&ok($atom->chain eq "X", "chain modification (Atom)");

&ok($atom->residue_number == 0, "residue_number access (Atom)");
$atom->residue_number(5);
&ok($atom->residue_number == 5, "residue_number modification (Atom)");

&ok($atom->x == 24.542, "x access (Atom)");
$atom->x(30.0);
&ok($atom->x == 30.0, "x modification (Atom)");

&ok($atom->y == 9.777, "y access (Atom)");
$atom->y(12.0);
&ok($atom->y == 12.0, "y modification (Atom)");

&ok($atom->z == -9.621, "z access (Atom)");
$atom->z(13.0);
&ok($atom->z == 13.0, "z modification (Atom)");

&ok($atom->occupancy == 1.00, "occupancy access (Atom)");
$atom->occupancy(0.5);
&ok($atom->occupancy == 0.5, "occupancy modification (Atom)");

&ok($atom->beta == 36.40, "beta access (Atom)");
$atom->beta(44.0);
&ok($atom->beta == 44.0, "beta modification (Atom)");

$mol = Bio::PDB::Structure::Molecule -> new;
$mol -> read("temp.pdb");
&ok( abs(distance Bio::PDB::Structure::Atom ($mol->atom(1),$mol->atom(9)) - 3.783889) < 0.00001,"distance method (Atom)");
&ok( abs(angle Bio::PDB::Structure::Atom($mol->atom(1),$mol->atom(9),$mol->atom(16)) - 128.450638) < 0.0001,"angle method (Atom)");
&ok( abs(dihedral Bio::PDB::Structure::Atom($mol->atom(1),$mol->atom(9),$mol->atom(16),$mol->atom(24)) + 145.558411 ) < 0.0001,"dihedral method (Atom)");

#Molecule methods

&ok($mol->size == 29, "size test (Molecule)");

$mol -> push($mol->atom(0));
$atom = $mol->atom(29);
&ok($atom->name eq "N" && $atom->residue_name eq "MET" && $atom->x == 24.486 && $atom->y == 8.308 && $atom->z == -9.406, "method push (Molecule), for an atom");

$mol -> push($mol);
$atom = $mol->atom(59);
&ok($atom->name eq "N" && $atom->residue_name eq "MET" && $atom->x == 24.486 && $atom->y == 8.308 && $atom->z == -9.406, "method push (Molecule), for a molecule");

$out.=$out;
open(OUT,">temp2.pdb");
print OUT $out;
close OUT;
my $nm = models Bio::PDB::Structure::Molecule "temp2.pdb";
&ok($nm == 2, "method models (Molecule)");

$mol = Bio::PDB::Structure::Molecule -> new;
$mol -> read("temp.pdb");
$atom = $mol->center;
&ok(abs($atom->x - 27.675275862069) < 0.0000001 && abs($atom->y - 13.61068965517240 ) < 0.0000001 && abs($atom->z + 10.34613793103450 ) < 0.0000001, "method center (Molecule)");
$atom = $mol ->cm;
&ok(abs($atom->x - 27.53121212121210) < 0.0000001 && abs($atom->y - 13.51003030303030 ) < 0.0000001 && abs($atom->z + 10.17397979797980 ) < 0.0000001, "method cm (Molecule)");
$mol = Bio::PDB::Structure::Molecule -> new;
$mol -> read("temp.pdb");
$mol -> translate((1,1,1));
$atom = $mol -> atom(9); 
&ok(abs($atom->x - 28.185) < 0.00001 && abs($atom->y - 12.834 ) < 0.00001 && abs($atom->z + 10.382 ) < 0.000001, "method translate (Molecule)");

my $mol2 = Bio::PDB::Structure::Molecule -> new;
$mol2 -> read("temp.pdb");
my $sqrt = 1/sqrt(2);
my @mat = ($sqrt,0.0,$sqrt,0.0,1.0,0.0,-1*$sqrt,0.0,$sqrt);
$mol2 -> rotate(@mat);
$atom = $mol2 -> atom(9);
&ok(abs($atom->x - 11.174408463091) < 0.000001 && abs($atom->y - 11.834 ) < 0.000001 && abs($atom->z + 27.2709872300216 ) < 0.000001, "method rotate (Molecule)");
my $mol1 = Bio::PDB::Structure::Molecule -> new;
$mol1 -> read("temp.pdb");
my $rmsd = $mol1->rmsd($mol2);
&ok(abs($rmsd - 22.7357879535303) < 0.0000001, "method rmsd (Molecule)");
my @rottrans=$mol2 -> superpose($mol1);
$mol2 -> rotate_translate(@rottrans);
open (STDOUT, '>', \$out) or die "Cant open STDOUT\n";
$mol2-> print;
&ok($out eq $pdbfile,"superpose and rotate_translate methods (Molecule)");
unlink("temp.pdb","temp2.pdb");
