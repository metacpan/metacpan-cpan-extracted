use Test::More;

use strict;
use warnings;
use Chemistry::File::QChemOut;

#plan 'no_plan';
plan tests => 14;

my $mol = Chemistry::Mol->read("ethane.out", format => 'qchemout');

isa_ok($mol => 'Chemistry::Mol');
is ($mol->atoms * 1, 8, 'got 8 atoms');
is ($mol->formula, 'C2H6', 'formula is C2H6');
ok (abs($mol->atoms(1)->coords->x - -0.771166) < 0.00001, 'x1');
ok (abs($mol->atoms(8)->coords->z -  0.867544) < 0.00001, 'z8');

my @mols = Chemistry::Mol->read("ethane.out", format => 'qchemout', all => 1);

is (@mols * 1, 4, 'all => got 4 mols');

my @x1 = (-0.765796, -0.768590, -0.769884, -0.771166 );

for my $i (0 .. 3) {
    isa_ok($mols[$i] => 'Chemistry::Mol');
    ok(abs($mols[$i]->atoms(1)->coords->x - $x1[$i]) < 0.000001, "x1 (mol $i)");
}



