#!/usr/bin/perl -T
use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use Chemistry::File qw/ XYZ /";
    plan skip_all => __FILE__ . " requires Chemistry::File::XYZ" if $@;
    plan tests => 15;
};

use Chemistry::File qw/ InternalCoords /;
my $mol = Chemistry::Mol->read(\*DATA, format=>'xyz');
use IO::Scalar;
my $data;
my $SH = new IO::Scalar \$data;
$mol->write($SH, format=>'zmat');
my $ZMATRIX = <<EOF;
H 
H      1              B1

  B1                   0.70000000
EOF
is( $data, $ZMATRIX, "written as zmat" );

$SH = new IO::Scalar \$ZMATRIX;
$mol = Chemistry::Mol->read($SH, format=>'zmat');
my ($atom,$bond);

ok($mol, "got mol");
is($mol->atoms, 2, "got 2 atoms");
is($mol->bonds, 1, "got 1 bond");

$atom = $mol->atoms(1);
is($atom->symbol, 'H', "got H");
is($atom->coords, Math::VectorReal->new(0,0,0), "H1: coords");
is(join(" ",$atom->neighbors), "2", "H1: neighbors");
is(join(" ",$atom->bonds), "b1", "H1: bonds");

$atom = $mol->atoms(2);
is($atom->symbol, 'H', "got H");
is($atom->coords, Math::VectorReal->new(0.7,0,0), "H2: coords");
is(join(" ",$atom->neighbors), "1", "H2: neighbors");
is(join(" ",$atom->bonds), "b1", "H2: bonds");

$bond = $mol->bonds(1);
is($bond->id, 'b1', "got b1");
is(join(" ",$bond->atoms), '2 1', "b1: atoms");
is($bond->length, 0.7, "b1: length");

__DATA__
    2
    Hydrogen molecule
    H    0.0000   0.0000   0.0000
    H    0.0000   0.7000   0.0000
