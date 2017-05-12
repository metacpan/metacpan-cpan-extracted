#!/usr/bin/perl -T
use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use Chemistry::File qw/ XYZ /";
    plan skip_all => __FILE__ . " requires Chemistry::File::XYZ" if $@;
    plan tests => 22;
};

use Chemistry::File qw/ InternalCoords /;
my $mol = Chemistry::Mol->read(\*DATA, format=>'xyz');
use IO::Scalar;
my $data;
my $SH = new IO::Scalar \$data;
$mol->write($SH, format=>'zmat');
my $ZMATRIX = <<EOF;
O 
H      1              B1
H      1              B2     2              A1

  B1                   0.96659987
  B2                   0.96659987
  A1                 107.67114171
EOF
is( $data, $ZMATRIX, "written as zmat" );

$SH = new IO::Scalar \$ZMATRIX;
$mol = Chemistry::Mol->read($SH, format=>'zmat');
my ($atom,$bond);

ok($mol, "got mol");
is($mol->atoms, 3, "got 3 atoms");
is($mol->bonds, 2, "got 2 bonds");

$atom = $mol->atoms(1);
is($atom->symbol, 'O', "got O");
is($atom->coords, Math::VectorReal->new(0,0,0), "O: coords");
is(join(" ",$atom->neighbors), "2 3", "O: neighbors");
is(join(" ",$atom->bonds), "b1 b2", "O: bonds");

$atom = $mol->atoms(2);
is($atom->symbol, 'H', "got H");
is($atom->coords, Math::VectorReal->new(0.96659987,0,0), "H1: coords");
is(join(" ",$atom->neighbors), "1", "H1: neighbors");
is(join(" ",$atom->bonds), "b1", "H1: bonds");

$atom = $mol->atoms(3);
is($atom->symbol, 'H', "got H");
is($atom->coords, Math::VectorReal->new(-0.2934144771811,0.9209903654570,0), "H2: coords");
is(join(" ",$atom->neighbors), "1", "H2: neighbors");
is(join(" ",$atom->bonds), "b2", "H2: bonds");

$bond = $mol->bonds(1);
is($bond->id, 'b1', "got b1");
is(join(" ",$bond->atoms), '2 1', "b1: atoms");
is($bond->length, 0.96659987, "b1: length");

$bond = $mol->bonds(2);
is($bond->id, 'b2', "got b2");
is(join(" ",$bond->atoms), '3 1', "b2: atoms");
is($bond->length, 0.96659987, "b2: length");

__DATA__
  3
  Water Molecule - XYZ Format
  O      .000000     .000000     .114079
  H      .000000     .780362    -.456316
  H      .000000    -.780362    -.456316
