use Test::More;

use strict;
use warnings;
use Chemistry::Mol;
use Chemistry::Ring;

plan tests => 2;

# make a cyclobutane
my $mol = Chemistry::Mol->new;
$mol->new_atom(symbol => 'C', coords => [-1, -1, 0]);
$mol->new_atom(symbol => 'C', coords => [-1,  1, 0]);
$mol->new_atom(symbol => 'C', coords => [ 1,  1, 0]);
$mol->new_atom(symbol => 'C', coords => [ 1, -1, 0]);
$mol->new_bond(atoms => [$mol->atoms(1,2)]);
$mol->new_bond(atoms => [$mol->atoms(2,3)]);
$mol->new_bond(atoms => [$mol->atoms(3,4)]);
$mol->new_bond(atoms => [$mol->atoms(4,1)]);

isa_ok( $mol, 'Chemistry::Mol' );

my $ring = Chemistry::Ring->new;
$ring->add_atom( $_ ) for $mol->atoms(1..4);

my( $normal, $distance ) = $ring->plane;
ok( $distance < 1e-6 );
