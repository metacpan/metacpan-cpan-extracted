package Ascii::Text::Font::Dotmatrix;
use strict;
use warnings;
use Rope;
use Rope::Autoload;
our $VERSION = 0.01;

extends 'Ascii::Text::Font';

# dotmatrix.flf by Curtis Wanner (cwanner@acs.bu.edu)

property character_height => (
	initable => 0,
	writable => 0,
	value => 10,
);

function space => sub {
	my @character = $_[0]->default_character(16);
	return \@character;
};

sub character_A {
	my @character = $_[0]->default_character(16);
	$character[0][8] = $character[1][6] = $character[1][8]
	    = $character[1][10] = $character[2][4]  = $character[2][6]
	    = $character[2][10] = $character[2][12] = $character[3][2]
	    = $character[3][4]  = $character[3][12] = $character[3][14]
	    = $character[4][2]  = $character[4][5]  = $character[4][8]
	    = $character[4][11] = $character[4][14] = $character[5][2]
	    = $character[5][5]  = $character[5][8]  = $character[5][11]
	    = $character[5][14] = $character[6][2]  = $character[6][14]
	    = $character[7][2]  = $character[7][14] = "_";
	$character[1][7] = $character[2][5] = $character[2][9] = $character[3][3]
	    = $character[3][11] = $character[4][1]  = $character[4][13]
	    = $character[5][1]  = $character[5][4]  = $character[5][7]
	    = $character[5][10] = $character[5][13] = $character[6][1]
	    = $character[6][13] = $character[7][1]  = $character[7][13] = "\(";
	$character[1][9] = $character[2][7] = $character[2][11]
	    = $character[3][5]  = $character[3][13] = $character[4][3]
	    = $character[4][15] = $character[5][3]  = $character[5][6]
	    = $character[5][9]  = $character[5][12] = $character[5][15]
	    = $character[6][3]  = $character[6][15] = $character[7][3]
	    = $character[7][15] = "\)";
	return \@character;
}

sub character_B {
	my @character = $_[0]->default_character(16);
	$character[0][2] = $character[0][5] = $character[0][8]
	    = $character[0][11] = $character[1][2]  = $character[1][5]
	    = $character[1][8]  = $character[1][11] = $character[1][14]
	    = $character[2][3]  = $character[2][14] = $character[3][3]
	    = $character[3][6]  = $character[3][9]  = $character[3][12]
	    = $character[3][14] = $character[4][3]  = $character[4][6]
	    = $character[4][9]  = $character[4][12] = $character[4][14]
	    = $character[5][3]  = $character[5][14] = $character[6][3]
	    = $character[6][5]  = $character[6][8]  = $character[6][11]
	    = $character[6][14] = $character[7][2]  = $character[7][5]
	    = $character[7][8]  = $character[7][11] = "_";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[2][4]  = $character[2][15]
	    = $character[3][4]  = $character[3][15] = $character[4][4]
	    = $character[4][7]  = $character[4][10] = $character[4][13]
	    = $character[5][4]  = $character[5][15] = $character[6][4]
	    = $character[6][15] = $character[7][3]  = $character[7][6]
	    = $character[7][9]  = $character[7][12] = "\)";
	$character[1][1] = $character[1][4] = $character[1][7]
	    = $character[1][10] = $character[2][2]  = $character[2][13]
	    = $character[3][2]  = $character[3][13] = $character[4][2]
	    = $character[4][5]  = $character[4][8]  = $character[4][11]
	    = $character[5][2]  = $character[5][13] = $character[6][2]
	    = $character[6][13] = $character[7][1]  = $character[7][4]
	    = $character[7][7]  = $character[7][10] = "\(";
	return \@character;
}

sub character_C {
	my @character = $_[0]->default_character(16);
	$character[0][5] = $character[0][8] = $character[0][11]
	    = $character[1][2]  = $character[1][5]  = $character[1][8]
	    = $character[1][11] = $character[1][14] = $character[2][2]
	    = $character[2][14] = $character[3][2]  = $character[4][2]
	    = $character[5][2]  = $character[5][14] = $character[6][2]
	    = $character[6][5]  = $character[6][8]  = $character[6][11]
	    = $character[6][14] = $character[7][5]  = $character[7][8]
	    = $character[7][11] = "_";
	$character[1][6] = $character[1][9] = $character[1][12]
	    = $character[2][3]  = $character[2][15] = $character[3][3]
	    = $character[4][3]  = $character[5][3]  = $character[6][3]
	    = $character[6][15] = $character[7][6]  = $character[7][9]
	    = $character[7][12] = "\)";
	$character[1][4] = $character[1][7] = $character[1][10]
	    = $character[2][1]  = $character[2][13] = $character[3][1]
	    = $character[4][1]  = $character[5][1]  = $character[6][1]
	    = $character[6][13] = $character[7][4]  = $character[7][7]
	    = $character[7][10] = "\(";
	return \@character;
}

sub character_D {
	my @character = $_[0]->default_character(16);
	$character[1][1] = $character[1][4] = $character[1][7]
	    = $character[1][10] = $character[2][2]  = $character[2][11]
	    = $character[3][2]  = $character[3][13] = $character[4][2]
	    = $character[4][13] = $character[5][2]  = $character[5][13]
	    = $character[6][2]  = $character[6][11] = $character[7][1]
	    = $character[7][4]  = $character[7][7]  = $character[7][10] = "\(";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[2][4]  = $character[2][13]
	    = $character[3][4]  = $character[3][15] = $character[4][4]
	    = $character[4][15] = $character[5][4]  = $character[5][15]
	    = $character[6][4]  = $character[6][13] = $character[7][3]
	    = $character[7][6]  = $character[7][9]  = $character[7][12] = "\)";
	$character[0][2] = $character[0][5] = $character[0][8]
	    = $character[0][11] = $character[1][2]  = $character[1][5]
	    = $character[1][8]  = $character[1][11] = $character[2][3]
	    = $character[2][12] = $character[2][14] = $character[3][3]
	    = $character[3][14] = $character[4][3]  = $character[4][14]
	    = $character[5][3]  = $character[5][12] = $character[5][14]
	    = $character[6][3]  = $character[6][5]  = $character[6][8]
	    = $character[6][12] = $character[7][2]  = $character[7][5]
	    = $character[7][8]  = $character[7][11] = "_";
	return \@character;
}

sub character_E {
	my @character = $_[0]->default_character(16);
	$character[0][2] = $character[0][5] = $character[0][8]
	    = $character[0][11] = $character[0][14] = $character[1][2]
	    = $character[1][5]  = $character[1][8]  = $character[1][11]
	    = $character[1][14] = $character[2][2]  = $character[3][2]
	    = $character[3][5]  = $character[3][8]  = $character[4][2]
	    = $character[4][5]  = $character[4][8]  = $character[5][2]
	    = $character[6][2]  = $character[6][5]  = $character[6][8]
	    = $character[6][11] = $character[6][14] = $character[7][2]
	    = $character[7][5]  = $character[7][8]  = $character[7][11]
	    = $character[7][14] = "_";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[1][15] = $character[2][3]
	    = $character[3][3]  = $character[4][3]  = $character[4][6]
	    = $character[4][9]  = $character[5][3]  = $character[6][3]
	    = $character[7][3]  = $character[7][6]  = $character[7][9]
	    = $character[7][12] = $character[7][15] = "\)";
	$character[1][1] = $character[1][4] = $character[1][7]
	    = $character[1][10] = $character[1][13] = $character[2][1]
	    = $character[3][1]  = $character[4][1]  = $character[4][4]
	    = $character[4][7]  = $character[5][1]  = $character[6][1]
	    = $character[7][1]  = $character[7][4]  = $character[7][7]
	    = $character[7][10] = $character[7][13] = "\(";
	return \@character;
}

sub character_F {
	my @character = $_[0]->default_character(16);
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[1][15] = $character[2][3]
	    = $character[3][3]  = $character[4][3]  = $character[4][6]
	    = $character[4][9]  = $character[5][3]  = $character[6][3]
	    = $character[7][3]  = "\)";
	$character[1][1] = $character[1][4] = $character[1][7]
	    = $character[1][10] = $character[1][13] = $character[2][1]
	    = $character[3][1]  = $character[4][1]  = $character[4][4]
	    = $character[4][7]  = $character[5][1]  = $character[6][1]
	    = $character[7][1]  = "\(";
	$character[0][2] = $character[0][5] = $character[0][8]
	    = $character[0][11] = $character[0][14] = $character[1][2]
	    = $character[1][5]  = $character[1][8]  = $character[1][11]
	    = $character[1][14] = $character[2][2]  = $character[3][2]
	    = $character[3][5]  = $character[3][8]  = $character[4][2]
	    = $character[4][5]  = $character[4][8]  = $character[5][2]
	    = $character[6][2]  = $character[7][2]  = "_";
	return \@character;
}

sub character_G {
	my @character = $_[0]->default_character(16);
	$character[1][4] = $character[1][7] = $character[1][10]
	    = $character[2][1]  = $character[2][13] = $character[3][1]
	    = $character[4][1]  = $character[4][7]  = $character[4][10]
	    = $character[4][13] = $character[5][1]  = $character[5][13]
	    = $character[6][1]  = $character[6][13] = $character[7][4]
	    = $character[7][7]  = $character[7][10] = $character[7][13] = "\(";
	$character[1][6] = $character[1][9] = $character[1][12]
	    = $character[2][3]  = $character[2][15] = $character[3][3]
	    = $character[4][3]  = $character[4][9]  = $character[4][12]
	    = $character[4][15] = $character[5][3]  = $character[5][15]
	    = $character[6][3]  = $character[6][15] = $character[7][6]
	    = $character[7][9]  = $character[7][12] = $character[7][15] = "\)";
	$character[0][5] = $character[0][8] = $character[0][11]
	    = $character[1][2]  = $character[1][5]  = $character[1][8]
	    = $character[1][11] = $character[1][14] = $character[2][2]
	    = $character[2][14] = $character[3][2]  = $character[3][8]
	    = $character[3][11] = $character[3][14] = $character[4][2]
	    = $character[4][8]  = $character[4][11] = $character[4][14]
	    = $character[5][2]  = $character[5][14] = $character[6][2]
	    = $character[6][5]  = $character[6][8]  = $character[6][11]
	    = $character[6][14] = $character[7][5]  = $character[7][8]
	    = $character[7][11] = $character[7][14] = "_";
	return \@character;
}

sub character_H {
	my @character = $_[0]->default_character(16);
	$character[1][3] = $character[1][15] = $character[2][3]
	    = $character[2][15] = $character[3][3]  = $character[3][15]
	    = $character[4][3]  = $character[4][6]  = $character[4][9]
	    = $character[4][12] = $character[4][15] = $character[5][3]
	    = $character[5][15] = $character[6][3]  = $character[6][15]
	    = $character[7][3]  = $character[7][15] = "\)";
	$character[1][1] = $character[1][13] = $character[2][1]
	    = $character[2][13] = $character[3][1]  = $character[3][13]
	    = $character[4][1]  = $character[4][4]  = $character[4][7]
	    = $character[4][10] = $character[4][13] = $character[5][1]
	    = $character[5][13] = $character[6][1]  = $character[6][13]
	    = $character[7][1]  = $character[7][13] = "\(";
	$character[0][2] = $character[0][14] = $character[1][2]
	    = $character[1][14] = $character[2][2]  = $character[2][14]
	    = $character[3][2]  = $character[3][5]  = $character[3][8]
	    = $character[3][11] = $character[3][14] = $character[4][2]
	    = $character[4][5]  = $character[4][8]  = $character[4][11]
	    = $character[4][14] = $character[5][2]  = $character[5][14]
	    = $character[6][2]  = $character[6][14] = $character[7][2]
	    = $character[7][14] = "_";
	return \@character;
}

sub character_I {
	my @character = $_[0]->default_character(10);
	$character[1][3] = $character[1][6] = $character[1][9] = $character[2][6]
	    = $character[3][6] = $character[4][6] = $character[5][6]
	    = $character[6][6] = $character[7][3] = $character[7][6]
	    = $character[7][9] = "\)";
	$character[1][1] = $character[1][4] = $character[1][7] = $character[2][4]
	    = $character[3][4] = $character[4][4] = $character[5][4]
	    = $character[6][4] = $character[7][1] = $character[7][4]
	    = $character[7][7] = "\(";
	$character[0][2] = $character[0][5] = $character[0][8] = $character[1][2]
	    = $character[1][5] = $character[1][8] = $character[2][5]
	    = $character[3][5] = $character[4][5] = $character[5][5]
	    = $character[6][2] = $character[6][5] = $character[6][8]
	    = $character[7][2] = $character[7][5] = $character[7][8] = "_";
	return \@character;
}

sub character_J {
	my @character = $_[0]->default_character(16);
	$character[0][8] = $character[0][11] = $character[0][14]
	    = $character[1][8]  = $character[1][11] = $character[1][14]
	    = $character[2][11] = $character[3][11] = $character[4][11]
	    = $character[5][3]  = $character[5][11] = $character[6][3]
	    = $character[6][7]  = $character[6][11] = $character[7][4]
	    = $character[7][7]  = $character[7][10] = "_";
	$character[1][7] = $character[1][10] = $character[1][13]
	    = $character[2][10] = $character[3][10] = $character[4][10]
	    = $character[5][10] = $character[6][2]  = $character[6][10]
	    = $character[7][3]  = $character[7][6]  = $character[7][9] = "\(";
	$character[1][9] = $character[1][12] = $character[1][15]
	    = $character[2][12] = $character[3][12] = $character[4][12]
	    = $character[5][12] = $character[6][4]  = $character[6][12]
	    = $character[7][5]  = $character[7][8]  = $character[7][11] = "\)";
	return \@character;
}

sub character_K {
	my @character = $_[0]->default_character(16);
	$character[0][2] = $character[0][14] = $character[1][2]
	    = $character[1][11] = $character[1][14] = $character[2][2]
	    = $character[2][8]  = $character[2][11] = $character[3][2]
	    = $character[3][5]  = $character[3][8]  = $character[4][2]
	    = $character[4][5]  = $character[4][8]  = $character[5][2]
	    = $character[5][8]  = $character[5][11] = $character[6][2]
	    = $character[6][11] = $character[6][14] = $character[7][2]
	    = $character[7][14] = "_";
	$character[1][1] = $character[1][13] = $character[2][1]
	    = $character[2][10] = $character[3][1]  = $character[3][7]
	    = $character[4][1]  = $character[4][4]  = $character[5][1]
	    = $character[5][7]  = $character[6][1]  = $character[6][10]
	    = $character[7][1]  = $character[7][13] = "\(";
	$character[1][3] = $character[1][15] = $character[2][3]
	    = $character[2][12] = $character[3][3]  = $character[3][9]
	    = $character[4][3]  = $character[4][6]  = $character[5][3]
	    = $character[5][9]  = $character[6][3]  = $character[6][12]
	    = $character[7][3]  = $character[7][15] = "\)";
	return \@character;
}

sub character_L {
	my @character = $_[0]->default_character(16);
	$character[1][1] = $character[2][1] = $character[3][1] = $character[4][1]
	    = $character[5][1]  = $character[6][1] = $character[7][1]
	    = $character[7][4]  = $character[7][7] = $character[7][10]
	    = $character[7][13] = "\(";
	$character[1][3] = $character[2][3] = $character[3][3] = $character[4][3]
	    = $character[5][3]  = $character[6][3] = $character[7][3]
	    = $character[7][6]  = $character[7][9] = $character[7][12]
	    = $character[7][15] = "\)";
	$character[0][2] = $character[1][2] = $character[2][2] = $character[3][2]
	    = $character[4][2]  = $character[5][2]  = $character[6][2]
	    = $character[6][5]  = $character[6][8]  = $character[6][11]
	    = $character[6][14] = $character[7][2]  = $character[7][5]
	    = $character[7][8]  = $character[7][11] = $character[7][14] = "_";
	return \@character;
}

sub character_M {
	my @character = $_[0]->default_character(16);
	$character[1][1] = $character[1][13] = $character[2][1]
	    = $character[2][4]  = $character[2][10] = $character[2][13]
	    = $character[3][1]  = $character[3][5]  = $character[3][9]
	    = $character[3][13] = $character[4][1]  = $character[4][7]
	    = $character[4][13] = $character[5][1]  = $character[5][13]
	    = $character[6][1]  = $character[6][13] = $character[7][1]
	    = $character[7][13] = "\(";
	$character[1][3] = $character[1][15] = $character[2][3]
	    = $character[2][6]  = $character[2][12] = $character[2][15]
	    = $character[3][3]  = $character[3][7]  = $character[3][11]
	    = $character[3][15] = $character[4][3]  = $character[4][9]
	    = $character[4][15] = $character[5][3]  = $character[5][15]
	    = $character[6][3]  = $character[6][15] = $character[7][3]
	    = $character[7][15] = "\)";
	$character[0][2] = $character[0][14] = $character[1][2]
	    = $character[1][5]  = $character[1][11] = $character[1][14]
	    = $character[2][2]  = $character[2][5]  = $character[2][11]
	    = $character[2][14] = $character[3][2]  = $character[3][6]
	    = $character[3][8]  = $character[3][10] = $character[3][14]
	    = $character[4][2]  = $character[4][8]  = $character[4][14]
	    = $character[5][2]  = $character[5][14] = $character[6][2]
	    = $character[6][14] = $character[7][2]  = $character[7][14] = "_";
	return \@character;
}

sub character_N {
	my @character = $_[0]->default_character(16);
	$character[1][3] = $character[1][15] = $character[2][3]
	    = $character[2][6]  = $character[2][15] = $character[3][3]
	    = $character[3][8]  = $character[3][15] = $character[4][3]
	    = $character[4][10] = $character[4][15] = $character[5][3]
	    = $character[5][12] = $character[5][15] = $character[6][3]
	    = $character[6][15] = $character[7][3]  = $character[7][15] = "\)";
	$character[1][1] = $character[1][13] = $character[2][1]
	    = $character[2][4]  = $character[2][13] = $character[3][1]
	    = $character[3][6]  = $character[3][13] = $character[4][1]
	    = $character[4][8]  = $character[4][13] = $character[5][1]
	    = $character[5][10] = $character[5][13] = $character[6][1]
	    = $character[6][13] = $character[7][1]  = $character[7][13] = "\(";
	$character[0][2] = $character[0][14] = $character[1][2]
	    = $character[1][5]  = $character[1][14] = $character[2][2]
	    = $character[2][5]  = $character[2][7]  = $character[2][14]
	    = $character[3][2]  = $character[3][7]  = $character[3][9]
	    = $character[3][14] = $character[4][2]  = $character[4][9]
	    = $character[4][11] = $character[4][14] = $character[5][2]
	    = $character[5][11] = $character[5][14] = $character[6][2]
	    = $character[6][14] = $character[7][2]  = $character[7][14] = "_";
	return \@character;
}

sub character_O {
	my @character = $_[0]->default_character(17);
	$character[0][4] = $character[0][7] = $character[0][10]
	    = $character[0][13] = $character[1][2]  = $character[1][4]
	    = $character[1][7]  = $character[1][10] = $character[1][13]
	    = $character[1][15] = $character[2][2]  = $character[2][15]
	    = $character[3][2]  = $character[3][15] = $character[4][2]
	    = $character[4][15] = $character[5][2]  = $character[5][15]
	    = $character[6][2]  = $character[6][4]  = $character[6][7]
	    = $character[6][10] = $character[6][13] = $character[6][15]
	    = $character[7][4]  = $character[7][7]  = $character[7][10]
	    = $character[7][13] = "_";
	$character[1][5] = $character[1][8] = $character[1][11]
	    = $character[1][14] = $character[2][3]  = $character[2][16]
	    = $character[3][3]  = $character[3][16] = $character[4][3]
	    = $character[4][16] = $character[5][3]  = $character[5][16]
	    = $character[6][3]  = $character[6][16] = $character[7][5]
	    = $character[7][8]  = $character[7][11] = $character[7][14] = "\)";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[2][1]  = $character[2][14]
	    = $character[3][1]  = $character[3][14] = $character[4][1]
	    = $character[4][14] = $character[5][1]  = $character[5][14]
	    = $character[6][1]  = $character[6][14] = $character[7][3]
	    = $character[7][6]  = $character[7][9]  = $character[7][12] = "\(";
	return \@character;
}

sub character_P {
	my @character = $_[0]->default_character(16);
	$character[0][3] = $character[0][6] = $character[0][9]
	    = $character[0][12] = $character[1][3]  = $character[1][6]
	    = $character[1][9]  = $character[1][12] = $character[1][14]
	    = $character[2][3]  = $character[2][14] = $character[3][3]
	    = $character[3][6]  = $character[3][9]  = $character[3][12]
	    = $character[3][14] = $character[4][3]  = $character[4][6]
	    = $character[4][9]  = $character[4][12] = $character[5][3]
	    = $character[6][3]  = $character[7][3]  = "_";
	$character[1][2] = $character[1][5] = $character[1][8]
	    = $character[1][11] = $character[2][2]  = $character[2][13]
	    = $character[3][2]  = $character[3][13] = $character[4][2]
	    = $character[4][5]  = $character[4][8]  = $character[4][11]
	    = $character[5][2]  = $character[6][2]  = $character[7][2] = "\(";
	$character[1][4] = $character[1][7] = $character[1][10]
	    = $character[1][13] = $character[2][4]  = $character[2][15]
	    = $character[3][4]  = $character[3][15] = $character[4][4]
	    = $character[4][7]  = $character[4][10] = $character[4][13]
	    = $character[5][4]  = $character[6][4]  = $character[7][4] = "\)";
	return \@character;
}

sub character_Q {
	my @character = $_[0]->default_character(17);
	$character[1][5] = $character[1][8] = $character[1][11]
	    = $character[1][14] = $character[2][3]  = $character[2][16]
	    = $character[3][3]  = $character[3][16] = $character[4][3]
	    = $character[4][16] = $character[5][3]  = $character[5][10]
	    = $character[5][16] = $character[6][3]  = $character[6][13]
	    = $character[7][5]  = $character[7][8]  = $character[7][11]
	    = $character[7][16] = "\)";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[2][1]  = $character[2][14]
	    = $character[3][1]  = $character[3][14] = $character[4][1]
	    = $character[4][14] = $character[5][1]  = $character[5][8]
	    = $character[5][14] = $character[6][1]  = $character[6][11]
	    = $character[7][3]  = $character[7][6]  = $character[7][9]
	    = $character[7][14] = "\(";
	$character[0][4] = $character[0][7] = $character[0][10]
	    = $character[0][13] = $character[1][2]  = $character[1][4]
	    = $character[1][7]  = $character[1][10] = $character[1][13]
	    = $character[1][15] = $character[2][2]  = $character[2][15]
	    = $character[3][2]  = $character[3][15] = $character[4][2]
	    = $character[4][9]  = $character[4][15] = $character[5][2]
	    = $character[5][9]  = $character[5][12] = $character[5][15]
	    = $character[6][2]  = $character[6][4]  = $character[6][7]
	    = $character[6][10] = $character[6][12] = $character[6][15]
	    = $character[7][4]  = $character[7][7]  = $character[7][10]
	    = $character[7][15] = "_";
	return \@character;
}

sub character_R {
	my @character = $_[0]->default_character(16);
	$character[0][2] = $character[0][5] = $character[0][8]
	    = $character[0][11] = $character[1][2]  = $character[1][5]
	    = $character[1][8]  = $character[1][11] = $character[1][14]
	    = $character[2][2]  = $character[2][14] = $character[3][2]
	    = $character[3][5]  = $character[3][8]  = $character[3][11]
	    = $character[3][14] = $character[4][2]  = $character[4][5]
	    = $character[4][8]  = $character[4][11] = $character[5][2]
	    = $character[5][8]  = $character[5][11] = $character[6][2]
	    = $character[6][11] = $character[6][14] = $character[7][2]
	    = $character[7][14] = "_";
	$character[1][1] = $character[1][4] = $character[1][7]
	    = $character[1][10] = $character[2][1]  = $character[2][13]
	    = $character[3][1]  = $character[3][13] = $character[4][1]
	    = $character[4][4]  = $character[4][7]  = $character[4][10]
	    = $character[5][1]  = $character[5][7]  = $character[6][1]
	    = $character[6][10] = $character[7][1]  = $character[7][13] = "\(";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[2][3]  = $character[2][15]
	    = $character[3][3]  = $character[3][15] = $character[4][3]
	    = $character[4][6]  = $character[4][9]  = $character[4][12]
	    = $character[5][3]  = $character[5][9]  = $character[6][3]
	    = $character[6][12] = $character[7][3]  = $character[7][15] = "\)";
	return \@character;
}

sub character_S {
	my @character = $_[0]->default_character(17);
	$character[0][4] = $character[0][7] = $character[0][10]
	    = $character[0][13] = $character[1][2]  = $character[1][4]
	    = $character[1][7]  = $character[1][10] = $character[1][13]
	    = $character[1][15] = $character[2][2]  = $character[2][15]
	    = $character[3][2]  = $character[3][4]  = $character[3][7]
	    = $character[3][10] = $character[3][13] = $character[4][4]
	    = $character[4][7]  = $character[4][10] = $character[4][13]
	    = $character[4][15] = $character[5][2]  = $character[5][15]
	    = $character[6][2]  = $character[6][4]  = $character[6][7]
	    = $character[6][10] = $character[6][13] = $character[6][15]
	    = $character[7][4]  = $character[7][7]  = $character[7][10]
	    = $character[7][13] = "_";
	$character[1][5] = $character[1][8] = $character[1][11]
	    = $character[1][14] = $character[2][3]  = $character[2][16]
	    = $character[3][3]  = $character[4][5]  = $character[4][8]
	    = $character[4][11] = $character[4][14] = $character[5][16]
	    = $character[6][3]  = $character[6][16] = $character[7][5]
	    = $character[7][8]  = $character[7][11] = $character[7][14] = "\)";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[2][1]  = $character[2][14]
	    = $character[3][1]  = $character[4][3]  = $character[4][6]
	    = $character[4][9]  = $character[4][12] = $character[5][14]
	    = $character[6][1]  = $character[6][14] = $character[7][3]
	    = $character[7][6]  = $character[7][9]  = $character[7][12] = "\(";
	return \@character;
}

sub character_T {
	my @character = $_[0]->default_character(16);
	$character[0][2] = $character[0][5] = $character[0][8]
	    = $character[0][11] = $character[0][14] = $character[1][2]
	    = $character[1][5]  = $character[1][8]  = $character[1][11]
	    = $character[1][14] = $character[2][8]  = $character[3][8]
	    = $character[4][8]  = $character[5][8]  = $character[6][8]
	    = $character[7][8]  = "_";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[1][15] = $character[2][9]
	    = $character[3][9]  = $character[4][9]  = $character[5][9]
	    = $character[6][9]  = $character[7][9]  = "\)";
	$character[1][1] = $character[1][4] = $character[1][7]
	    = $character[1][10] = $character[1][13] = $character[2][7]
	    = $character[3][7]  = $character[4][7]  = $character[5][7]
	    = $character[6][7]  = $character[7][7]  = "\(";
	return \@character;
}

sub character_U {
	my @character = $_[0]->default_character(17);
	$character[1][1] = $character[1][14] = $character[2][1]
	    = $character[2][14] = $character[3][1]  = $character[3][14]
	    = $character[4][1]  = $character[4][14] = $character[5][1]
	    = $character[5][14] = $character[6][1]  = $character[6][14]
	    = $character[7][3]  = $character[7][6]  = $character[7][9]
	    = $character[7][12] = "\(";
	$character[1][3] = $character[1][16] = $character[2][3]
	    = $character[2][16] = $character[3][3]  = $character[3][16]
	    = $character[4][3]  = $character[4][16] = $character[5][3]
	    = $character[5][16] = $character[6][3]  = $character[6][16]
	    = $character[7][5]  = $character[7][8]  = $character[7][11]
	    = $character[7][14] = "\)";
	$character[0][2] = $character[0][15] = $character[1][2]
	    = $character[1][15] = $character[2][2]  = $character[2][15]
	    = $character[3][2]  = $character[3][15] = $character[4][2]
	    = $character[4][15] = $character[5][2]  = $character[5][15]
	    = $character[6][2]  = $character[6][4]  = $character[6][7]
	    = $character[6][10] = $character[6][13] = $character[6][15]
	    = $character[7][4]  = $character[7][7]  = $character[7][10]
	    = $character[7][13] = "_";
	return \@character;
}

sub character_V {
	my @character = $_[0]->default_character(16);
	$character[1][1] = $character[1][13] = $character[2][1]
	    = $character[2][13] = $character[3][1]  = $character[3][13]
	    = $character[4][3]  = $character[4][11] = $character[5][4]
	    = $character[5][10] = $character[6][5]  = $character[6][9]
	    = $character[7][7]  = "\(";
	$character[1][3] = $character[1][15] = $character[2][3]
	    = $character[2][15] = $character[3][3]  = $character[3][15]
	    = $character[4][5]  = $character[4][13] = $character[5][6]
	    = $character[5][12] = $character[6][7]  = $character[6][11]
	    = $character[7][9]  = "\)";
	$character[0][2] = $character[0][14] = $character[1][2]
	    = $character[1][14] = $character[2][2]  = $character[2][14]
	    = $character[3][2]  = $character[3][4]  = $character[3][12]
	    = $character[3][14] = $character[4][4]  = $character[4][12]
	    = $character[5][5]  = $character[5][11] = $character[6][6]
	    = $character[6][8]  = $character[6][10] = $character[7][8] = "_";
	return \@character;
}

sub character_W {
	my @character = $_[0]->default_character(17);
	$character[0][1] = $character[0][15] = $character[1][1]
	    = $character[1][15] = $character[2][1]  = $character[2][15]
	    = $character[3][1]  = $character[3][8]  = $character[3][15]
	    = $character[4][1]  = $character[4][6]  = $character[4][8]
	    = $character[4][10] = $character[4][15] = $character[5][1]
	    = $character[5][6]  = $character[5][10] = $character[5][15]
	    = $character[6][1]  = $character[6][3]  = $character[6][5]
	    = $character[6][11] = $character[6][13] = $character[6][15]
	    = $character[7][3]  = $character[7][13] = "_";
	$character[1][2] = $character[1][16] = $character[2][2]
	    = $character[2][16] = $character[3][2]  = $character[3][16]
	    = $character[4][2]  = $character[4][9]  = $character[4][16]
	    = $character[5][2]  = $character[5][7]  = $character[5][11]
	    = $character[5][16] = $character[6][2]  = $character[6][6]
	    = $character[6][12] = $character[6][16] = $character[7][4]
	    = $character[7][14] = "\)";
	$character[1][0] = $character[1][14] = $character[2][0]
	    = $character[2][14] = $character[3][0]  = $character[3][14]
	    = $character[4][0]  = $character[4][7]  = $character[4][14]
	    = $character[5][0]  = $character[5][5]  = $character[5][9]
	    = $character[5][14] = $character[6][0]  = $character[6][4]
	    = $character[6][10] = $character[6][14] = $character[7][2]
	    = $character[7][12] = "\(";
	return \@character;
}

sub character_X {
	my @character = $_[0]->default_character(16);
	$character[0][2] = $character[0][14] = $character[1][2]
	    = $character[1][4]  = $character[1][12] = $character[1][14]
	    = $character[2][4]  = $character[2][6]  = $character[2][10]
	    = $character[2][12] = $character[3][6]  = $character[3][8]
	    = $character[3][10] = $character[4][6]  = $character[4][8]
	    = $character[4][10] = $character[5][4]  = $character[5][6]
	    = $character[5][10] = $character[5][12] = $character[6][2]
	    = $character[6][4]  = $character[6][12] = $character[6][14]
	    = $character[7][2]  = $character[7][14] = "_";
	$character[1][3] = $character[1][15] = $character[2][5]
	    = $character[2][13] = $character[3][7]  = $character[3][11]
	    = $character[4][9]  = $character[5][7]  = $character[5][11]
	    = $character[6][5]  = $character[6][13] = $character[7][3]
	    = $character[7][15] = "\)";
	$character[1][1] = $character[1][13] = $character[2][3]
	    = $character[2][11] = $character[3][5]  = $character[3][9]
	    = $character[4][7]  = $character[5][5]  = $character[5][9]
	    = $character[6][3]  = $character[6][11] = $character[7][1]
	    = $character[7][13] = "\(";
	return \@character;
}

sub character_Y {
	my @character = $_[0]->default_character(16);
	$character[0][2] = $character[0][14] = $character[1][2]
	    = $character[1][4]  = $character[1][12] = $character[1][14]
	    = $character[2][4]  = $character[2][6]  = $character[2][10]
	    = $character[2][12] = $character[3][6]  = $character[3][8]
	    = $character[3][10] = $character[4][8]  = $character[5][8]
	    = $character[6][8]  = $character[7][8]  = "_";
	$character[1][1] = $character[1][13] = $character[2][3]
	    = $character[2][11] = $character[3][5] = $character[3][9]
	    = $character[4][7]  = $character[5][7] = $character[6][7]
	    = $character[7][7]  = "\(";
	$character[1][3] = $character[1][15] = $character[2][5]
	    = $character[2][13] = $character[3][7] = $character[3][11]
	    = $character[4][9]  = $character[5][9] = $character[6][9]
	    = $character[7][9]  = "\)";
	return \@character;
}

sub character_Z {
	my @character = $_[0]->default_character(16);
	$character[1][1] = $character[1][4] = $character[1][7]
	    = $character[1][10] = $character[1][13] = $character[2][12]
	    = $character[3][10] = $character[4][8]  = $character[5][6]
	    = $character[6][4]  = $character[7][1]  = $character[7][4]
	    = $character[7][7]  = $character[7][10] = $character[7][13] = "\(";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[1][15] = $character[2][14]
	    = $character[3][12] = $character[4][10] = $character[5][8]
	    = $character[6][6]  = $character[7][3]  = $character[7][6]
	    = $character[7][9]  = $character[7][12] = $character[7][15] = "\)";
	$character[0][2] = $character[0][5] = $character[0][8]
	    = $character[0][11] = $character[0][14] = $character[1][2]
	    = $character[1][5]  = $character[1][8]  = $character[1][11]
	    = $character[1][14] = $character[2][11] = $character[2][13]
	    = $character[3][9]  = $character[3][11] = $character[4][7]
	    = $character[4][9]  = $character[5][5]  = $character[5][7]
	    = $character[6][2]  = $character[6][5]  = $character[6][8]
	    = $character[6][11] = $character[6][14] = $character[7][2]
	    = $character[7][5]  = $character[7][8]  = $character[7][11]
	    = $character[7][14] = "_";
	return \@character;
}

sub character_a {
	my @character = $_[0]->default_character(16);
	$character[3][5] = $character[3][8] = $character[3][11]
	    = $character[4][14] = $character[5][5]  = $character[5][8]
	    = $character[5][11] = $character[5][14] = $character[6][3]
	    = $character[6][14] = $character[7][5]  = $character[7][8]
	    = $character[7][11] = $character[7][16] = "\)";
	$character[3][3] = $character[3][6] = $character[3][9]
	    = $character[4][12] = $character[5][3]  = $character[5][6]
	    = $character[5][9]  = $character[5][12] = $character[6][1]
	    = $character[6][12] = $character[7][3]  = $character[7][6]
	    = $character[7][9]  = $character[7][14] = "\(";
	$character[2][4] = $character[2][7] = $character[2][10]
	    = $character[3][4]  = $character[3][7]  = $character[3][10]
	    = $character[3][13] = $character[4][4]  = $character[4][7]
	    = $character[4][10] = $character[4][13] = $character[5][2]
	    = $character[5][4]  = $character[5][7]  = $character[5][10]
	    = $character[5][13] = $character[6][2]  = $character[6][4]
	    = $character[6][7]  = $character[6][10] = $character[6][13]
	    = $character[6][15] = $character[7][4]  = $character[7][7]
	    = $character[7][10] = $character[7][15] = "_";
	return \@character;
}

sub character_b {
	my @character = $_[0]->default_character(16);
	$character[1][2] = $character[2][2] = $character[3][2] = $character[3][5]
	    = $character[3][8]  = $character[3][11] = $character[4][2]
	    = $character[4][13] = $character[5][2]  = $character[5][13]
	    = $character[6][2]  = $character[6][13] = $character[7][2]
	    = $character[7][5]  = $character[7][8]  = $character[7][11] = "\(";
	$character[1][4] = $character[2][4] = $character[3][4] = $character[3][7]
	    = $character[3][10] = $character[3][13] = $character[4][4]
	    = $character[4][15] = $character[5][4]  = $character[5][15]
	    = $character[6][4]  = $character[6][15] = $character[7][4]
	    = $character[7][7]  = $character[7][10] = $character[7][13] = "\)";
	$character[0][3] = $character[1][3] = $character[2][3] = $character[2][6]
	    = $character[2][9]  = $character[2][12] = $character[3][3]
	    = $character[3][6]  = $character[3][9]  = $character[3][12]
	    = $character[3][14] = $character[4][3]  = $character[4][14]
	    = $character[5][3]  = $character[5][14] = $character[6][3]
	    = $character[6][6]  = $character[6][9]  = $character[6][12]
	    = $character[6][14] = $character[7][3]  = $character[7][6]
	    = $character[7][9]  = $character[7][12] = "_";
	return \@character;
}

sub character_c {
	my @character = $_[0]->default_character(16);
	$character[3][6] = $character[3][9] = $character[3][12]
	    = $character[4][4] = $character[5][4] = $character[6][4]
	    = $character[7][6] = $character[7][9] = $character[7][12] = "\)";
	$character[3][4] = $character[3][7] = $character[3][10]
	    = $character[4][2] = $character[5][2] = $character[6][2]
	    = $character[7][4] = $character[7][7] = $character[7][10] = "\(";
	$character[2][5] = $character[2][8] = $character[2][11]
	    = $character[3][3]  = $character[3][5] = $character[3][8]
	    = $character[3][11] = $character[4][3] = $character[5][3]
	    = $character[6][3]  = $character[6][5] = $character[6][8]
	    = $character[6][11] = $character[7][5] = $character[7][8]
	    = $character[7][11] = "_";
	return \@character;
}

sub character_d {
	my @character = $_[0]->default_character(16);
	$character[1][13] = $character[2][13] = $character[3][4]
	    = $character[3][7]  = $character[3][10] = $character[3][13]
	    = $character[4][2]  = $character[4][13] = $character[5][2]
	    = $character[5][13] = $character[6][2]  = $character[6][13]
	    = $character[7][4]  = $character[7][7]  = $character[7][10]
	    = $character[7][13] = "\(";
	$character[1][15] = $character[2][15] = $character[3][6]
	    = $character[3][9]  = $character[3][12] = $character[3][15]
	    = $character[4][4]  = $character[4][15] = $character[5][4]
	    = $character[5][15] = $character[6][4]  = $character[6][15]
	    = $character[7][6]  = $character[7][9]  = $character[7][12]
	    = $character[7][15] = "\)";
	$character[0][14] = $character[1][14] = $character[2][5]
	    = $character[2][8]  = $character[2][11] = $character[2][14]
	    = $character[3][3]  = $character[3][5]  = $character[3][8]
	    = $character[3][11] = $character[3][14] = $character[4][3]
	    = $character[4][14] = $character[5][3]  = $character[5][14]
	    = $character[6][3]  = $character[6][5]  = $character[6][8]
	    = $character[6][11] = $character[6][14] = $character[7][5]
	    = $character[7][8]  = $character[7][11] = $character[7][14] = "_";
	return \@character;
}

sub character_e {
	my @character = $_[0]->default_character(16);
	$character[2][3] = $character[2][6] = $character[2][9]
	    = $character[2][12] = $character[3][3]  = $character[3][6]
	    = $character[3][9]  = $character[3][12] = $character[3][14]
	    = $character[4][2]  = $character[4][5]  = $character[4][8]
	    = $character[4][11] = $character[4][14] = $character[5][2]
	    = $character[5][5]  = $character[5][8]  = $character[5][11]
	    = $character[5][14] = $character[6][2]  = $character[6][4]
	    = $character[6][7]  = $character[6][10] = $character[6][13]
	    = $character[7][4]  = $character[7][7]  = $character[7][10]
	    = $character[7][13] = "_";
	$character[3][2] = $character[3][5] = $character[3][8]
	    = $character[3][11] = $character[4][1]  = $character[4][13]
	    = $character[5][1]  = $character[5][4]  = $character[5][7]
	    = $character[5][10] = $character[5][13] = $character[6][1]
	    = $character[7][3]  = $character[7][6]  = $character[7][9]
	    = $character[7][12] = "\(";
	$character[3][4] = $character[3][7] = $character[3][10]
	    = $character[3][13] = $character[4][3]  = $character[4][15]
	    = $character[5][3]  = $character[5][6]  = $character[5][9]
	    = $character[5][12] = $character[5][15] = $character[6][3]
	    = $character[7][5]  = $character[7][8]  = $character[7][11]
	    = $character[7][14] = "\)";
	return \@character;
}

sub character_f {
	my @character = $_[0]->default_character(12);
	$character[0][7] = $character[0][10] = $character[1][5]
	    = $character[1][7] = $character[1][10] = $character[2][2]
	    = $character[2][5] = $character[2][8]  = $character[3][2]
	    = $character[3][5] = $character[3][8]  = $character[4][5]
	    = $character[5][5] = $character[6][5]  = $character[7][5] = "_";
	$character[1][8] = $character[1][11] = $character[2][6]
	    = $character[3][3] = $character[3][6] = $character[3][9]
	    = $character[4][6] = $character[5][6] = $character[6][6]
	    = $character[7][6] = "\)";
	$character[1][6] = $character[1][9] = $character[2][4] = $character[3][1]
	    = $character[3][4] = $character[3][7] = $character[4][4]
	    = $character[5][4] = $character[6][4] = $character[7][4] = "\(";
	return \@character;
}

sub character_g {
	my @character = $_[0]->default_character(16);
	$character[3][6] = $character[3][9] = $character[3][12]
	    = $character[3][15] = $character[4][4]  = $character[4][15]
	    = $character[5][4]  = $character[5][15] = $character[6][4]
	    = $character[6][15] = $character[7][6]  = $character[7][9]
	    = $character[7][12] = $character[7][15] = $character[8][15]
	    = $character[9][6]  = $character[9][9]  = $character[9][12] = "\)";
	$character[3][4] = $character[3][7] = $character[3][10]
	    = $character[3][13] = $character[4][2]  = $character[4][13]
	    = $character[5][2]  = $character[5][13] = $character[6][2]
	    = $character[6][13] = $character[7][4]  = $character[7][7]
	    = $character[7][10] = $character[7][13] = $character[8][13]
	    = $character[9][4]  = $character[9][7]  = $character[9][10] = "\(";
	$character[2][5] = $character[2][8] = $character[2][11]
	    = $character[2][14] = $character[3][3]  = $character[3][5]
	    = $character[3][8]  = $character[3][11] = $character[3][14]
	    = $character[4][3]  = $character[4][14] = $character[5][3]
	    = $character[5][14] = $character[6][3]  = $character[6][5]
	    = $character[6][8]  = $character[6][11] = $character[6][14]
	    = $character[7][5]  = $character[7][8]  = $character[7][11]
	    = $character[7][14] = $character[8][5]  = $character[8][8]
	    = $character[8][11] = $character[8][14] = $character[9][5]
	    = $character[9][8]  = $character[9][11] = "_";
	return \@character;
}

sub character_h {
	my @character = $_[0]->default_character(16);
	$character[0][3] = $character[1][3] = $character[2][3] = $character[2][6]
	    = $character[2][9]  = $character[2][12] = $character[3][3]
	    = $character[3][6]  = $character[3][9]  = $character[3][12]
	    = $character[3][14] = $character[4][3]  = $character[4][14]
	    = $character[5][3]  = $character[5][14] = $character[6][3]
	    = $character[6][14] = $character[7][3]  = $character[7][14] = "_";
	$character[1][2] = $character[2][2] = $character[3][2] = $character[3][5]
	    = $character[3][8]  = $character[3][11] = $character[4][2]
	    = $character[4][13] = $character[5][2]  = $character[5][13]
	    = $character[6][2]  = $character[6][13] = $character[7][2]
	    = $character[7][13] = "\(";
	$character[1][4] = $character[2][4] = $character[3][4] = $character[3][7]
	    = $character[3][10] = $character[3][13] = $character[4][4]
	    = $character[4][15] = $character[5][4]  = $character[5][15]
	    = $character[6][4]  = $character[6][15] = $character[7][4]
	    = $character[7][15] = "\)";
	return \@character;
}

sub character_i {
	my @character = $_[0]->default_character(11);
	$character[1][7] = $character[3][4] = $character[3][7] = $character[4][7]
	    = $character[5][7] = $character[6][7] = $character[7][4]
	    = $character[7][7] = $character[7][10] = "\)";
	$character[1][5] = $character[3][2] = $character[3][5] = $character[4][5]
	    = $character[5][5] = $character[6][5] = $character[7][2]
	    = $character[7][5] = $character[7][8] = "\(";
	$character[0][6] = $character[1][6] = $character[2][3] = $character[2][6]
	    = $character[3][3] = $character[3][6] = $character[4][6]
	    = $character[5][6] = $character[6][3] = $character[6][6]
	    = $character[6][9] = $character[7][3] = $character[7][6]
	    = $character[7][9] = "_";
	return \@character;
}

sub character_j {
	my @character = $_[0]->default_character(14);
	$character[1][11] = $character[3][8] = $character[3][11]
	    = $character[4][11] = $character[5][11] = $character[6][11]
	    = $character[7][11] = $character[8][2]  = $character[8][9]
	    = $character[9][4]  = $character[9][7]  = "\(";
	$character[1][13] = $character[3][10] = $character[3][13]
	    = $character[4][13] = $character[5][13] = $character[6][13]
	    = $character[7][13] = $character[8][4]  = $character[8][11]
	    = $character[9][6]  = $character[9][9]  = "\)";
	$character[0][12] = $character[1][12] = $character[2][9]
	    = $character[2][12] = $character[3][9]  = $character[3][12]
	    = $character[4][12] = $character[5][12] = $character[6][12]
	    = $character[7][3]  = $character[7][10] = $character[7][12]
	    = $character[8][3]  = $character[8][5]  = $character[8][8]
	    = $character[8][10] = $character[9][5]  = $character[9][8] = "_";
	return \@character;
}

sub character_k {
	my @character = $_[0]->default_character(12);
	$character[0][3] = $character[1][3] = $character[2][3]
	    = $character[2][10] = $character[3][3] = $character[3][8]
	    = $character[3][10] = $character[4][3] = $character[4][6]
	    = $character[4][8]  = $character[5][3] = $character[5][6]
	    = $character[5][8]  = $character[6][3] = $character[6][8]
	    = $character[6][10] = $character[7][3] = $character[7][10] = "_";
	$character[1][4] = $character[2][4] = $character[3][4]
	    = $character[3][11] = $character[4][4] = $character[4][9]
	    = $character[5][4]  = $character[5][7] = $character[6][4]
	    = $character[6][9]  = $character[7][4] = $character[7][11] = "\)";
	$character[1][2] = $character[2][2] = $character[3][2] = $character[3][9]
	    = $character[4][2] = $character[4][7] = $character[5][2]
	    = $character[5][5] = $character[6][2] = $character[6][7]
	    = $character[7][2] = $character[7][9] = "\(";
	return \@character;
}

sub character_l {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][5] = $character[1][2] = $character[1][5]
	    = $character[2][5] = $character[3][5] = $character[4][5]
	    = $character[5][5] = $character[6][2] = $character[6][5]
	    = $character[6][8] = $character[7][2] = $character[7][5]
	    = $character[7][8] = "_";
	$character[1][3] = $character[1][6] = $character[2][6] = $character[3][6]
	    = $character[4][6] = $character[5][6] = $character[6][6]
	    = $character[7][3] = $character[7][6] = $character[7][9] = "\)";
	$character[1][1] = $character[1][4] = $character[2][4] = $character[3][4]
	    = $character[4][4] = $character[5][4] = $character[6][4]
	    = $character[7][1] = $character[7][4] = $character[7][7] = "\(";
	return \@character;
}

sub character_m {
	my @character = $_[0]->default_character(16);
	$character[3][4] = $character[3][7] = $character[3][11]
	    = $character[3][14] = $character[4][3] = $character[4][9]
	    = $character[4][15] = $character[5][3] = $character[5][9]
	    = $character[5][15] = $character[6][3] = $character[6][9]
	    = $character[6][15] = $character[7][3] = $character[7][9]
	    = $character[7][15] = "\)";
	$character[3][2] = $character[3][5] = $character[3][9]
	    = $character[3][12] = $character[4][1] = $character[4][7]
	    = $character[4][13] = $character[5][1] = $character[5][7]
	    = $character[5][13] = $character[6][1] = $character[6][7]
	    = $character[6][13] = $character[7][1] = $character[7][7]
	    = $character[7][13] = "\(";
	$character[2][3] = $character[2][6] = $character[2][10]
	    = $character[2][13] = $character[3][3]  = $character[3][6]
	    = $character[3][8]  = $character[3][10] = $character[3][13]
	    = $character[4][2]  = $character[4][8]  = $character[4][14]
	    = $character[5][2]  = $character[5][8]  = $character[5][14]
	    = $character[6][2]  = $character[6][8]  = $character[6][14]
	    = $character[7][2]  = $character[7][8]  = $character[7][14] = "_";
	return \@character;
}

sub character_n {
	my @character = $_[0]->default_character(16);
	$character[2][3] = $character[2][6] = $character[2][9]
	    = $character[2][12] = $character[3][3]  = $character[3][6]
	    = $character[3][9]  = $character[3][12] = $character[3][14]
	    = $character[4][3]  = $character[4][14] = $character[5][3]
	    = $character[5][14] = $character[6][3]  = $character[6][14]
	    = $character[7][3]  = $character[7][14] = "_";
	$character[3][2] = $character[3][5] = $character[3][8]
	    = $character[3][11] = $character[4][2]  = $character[4][13]
	    = $character[5][2]  = $character[5][13] = $character[6][2]
	    = $character[6][13] = $character[7][2]  = $character[7][13] = "\(";
	$character[3][4] = $character[3][7] = $character[3][10]
	    = $character[3][13] = $character[4][4]  = $character[4][15]
	    = $character[5][4]  = $character[5][15] = $character[6][4]
	    = $character[6][15] = $character[7][4]  = $character[7][15] = "\)";
	return \@character;
}

sub character_o {
	my @character = $_[0]->default_character(16);
	$character[2][5] = $character[2][8] = $character[2][11]
	    = $character[3][2]  = $character[3][5]  = $character[3][8]
	    = $character[3][11] = $character[3][14] = $character[4][2]
	    = $character[4][14] = $character[5][2]  = $character[5][14]
	    = $character[6][2]  = $character[6][5]  = $character[6][8]
	    = $character[6][11] = $character[6][14] = $character[7][5]
	    = $character[7][8]  = $character[7][11] = "_";
	$character[3][4] = $character[3][7] = $character[3][10]
	    = $character[4][1]  = $character[4][13] = $character[5][1]
	    = $character[5][13] = $character[6][1]  = $character[6][13]
	    = $character[7][4]  = $character[7][7]  = $character[7][10] = "\(";
	$character[3][6] = $character[3][9] = $character[3][12]
	    = $character[4][3]  = $character[4][15] = $character[5][3]
	    = $character[5][15] = $character[6][3]  = $character[6][15]
	    = $character[7][6]  = $character[7][9]  = $character[7][12] = "\)";
	return \@character;
}

sub character_p {
	my @character = $_[0]->default_character(16);
	$character[2][2] = $character[2][5] = $character[2][8]
	    = $character[2][11] = $character[3][2]  = $character[3][5]
	    = $character[3][8]  = $character[3][11] = $character[3][13]
	    = $character[4][2]  = $character[4][13] = $character[5][2]
	    = $character[5][13] = $character[6][2]  = $character[6][5]
	    = $character[6][8]  = $character[6][11] = $character[6][13]
	    = $character[7][2]  = $character[7][5]  = $character[7][8]
	    = $character[7][11] = $character[8][2]  = $character[9][2] = "_";
	$character[3][1] = $character[3][4] = $character[3][7]
	    = $character[3][10] = $character[4][1]  = $character[4][12]
	    = $character[5][1]  = $character[5][12] = $character[6][1]
	    = $character[6][12] = $character[7][1]  = $character[7][4]
	    = $character[7][7]  = $character[7][10] = $character[8][1]
	    = $character[9][1]  = "\(";
	$character[3][3] = $character[3][6] = $character[3][9]
	    = $character[3][12] = $character[4][3]  = $character[4][14]
	    = $character[5][3]  = $character[5][14] = $character[6][3]
	    = $character[6][14] = $character[7][3]  = $character[7][6]
	    = $character[7][9]  = $character[7][12] = $character[8][3]
	    = $character[9][3]  = "\)";
	return \@character;
}

sub character_q {
	my @character = $_[0]->default_character(16);
	$character[3][5] = $character[3][8] = $character[3][11]
	    = $character[3][14] = $character[4][3]  = $character[4][14]
	    = $character[5][3]  = $character[5][14] = $character[6][3]
	    = $character[6][14] = $character[7][5]  = $character[7][8]
	    = $character[7][11] = $character[7][14] = $character[8][14]
	    = $character[9][14] = "\)";
	$character[3][3] = $character[3][6] = $character[3][9]
	    = $character[3][12] = $character[4][1]  = $character[4][12]
	    = $character[5][1]  = $character[5][12] = $character[6][1]
	    = $character[6][12] = $character[7][3]  = $character[7][6]
	    = $character[7][9]  = $character[7][12] = $character[8][12]
	    = $character[9][12] = "\(";
	$character[2][4] = $character[2][7] = $character[2][10]
	    = $character[2][13] = $character[3][2]  = $character[3][4]
	    = $character[3][7]  = $character[3][10] = $character[3][13]
	    = $character[4][2]  = $character[4][13] = $character[5][2]
	    = $character[5][13] = $character[6][2]  = $character[6][4]
	    = $character[6][7]  = $character[6][10] = $character[6][13]
	    = $character[7][4]  = $character[7][7]  = $character[7][10]
	    = $character[7][13] = $character[8][13] = $character[9][13] = "_";
	return \@character;
}

sub character_r {
	my @character = $_[0]->default_character(16);
	$character[2][2] = $character[2][10] = $character[2][13]
	    = $character[3][2]  = $character[3][4]  = $character[3][7]
	    = $character[3][10] = $character[3][13] = $character[4][4]
	    = $character[4][7]  = $character[5][4]  = $character[6][4]
	    = $character[7][4]  = "_";
	$character[3][3] = $character[3][11] = $character[3][14]
	    = $character[4][5] = $character[4][8] = $character[5][5]
	    = $character[6][5] = $character[7][5] = "\)";
	$character[3][1] = $character[3][9] = $character[3][12]
	    = $character[4][3] = $character[4][6] = $character[5][3]
	    = $character[6][3] = $character[7][3] = "\(";
	return \@character;
}

sub character_s {
	my @character = $_[0]->default_character(17);
	$character[2][4] = $character[2][7] = $character[2][10]
	    = $character[2][13] = $character[3][2]  = $character[3][4]
	    = $character[3][7]  = $character[3][10] = $character[3][13]
	    = $character[4][2]  = $character[4][4]  = $character[4][7]
	    = $character[4][10] = $character[4][13] = $character[5][4]
	    = $character[5][7]  = $character[5][10] = $character[5][13]
	    = $character[5][15] = $character[6][4]  = $character[6][7]
	    = $character[6][10] = $character[6][13] = $character[6][15]
	    = $character[7][4]  = $character[7][7]  = $character[7][10]
	    = $character[7][13] = "_";
	$character[3][5] = $character[3][8] = $character[3][11]
	    = $character[3][14] = $character[4][3]  = $character[5][5]
	    = $character[5][8]  = $character[5][11] = $character[5][14]
	    = $character[6][16] = $character[7][5]  = $character[7][8]
	    = $character[7][11] = $character[7][14] = "\)";
	$character[3][3] = $character[3][6] = $character[3][9]
	    = $character[3][12] = $character[4][1]  = $character[5][3]
	    = $character[5][6]  = $character[5][9]  = $character[5][12]
	    = $character[6][14] = $character[7][3]  = $character[7][6]
	    = $character[7][9]  = $character[7][12] = "\(";
	return \@character;
}

sub character_t {
	my @character = $_[0]->default_character(15);
	$character[1][4] = $character[2][4] = $character[3][1] = $character[3][4]
	    = $character[3][7] = $character[3][10] = $character[4][4]
	    = $character[5][4] = $character[6][4]  = $character[6][11]
	    = $character[7][6] = $character[7][9]  = "\(";
	$character[1][6] = $character[2][6] = $character[3][3] = $character[3][6]
	    = $character[3][9] = $character[3][12] = $character[4][6]
	    = $character[5][6] = $character[6][6]  = $character[6][13]
	    = $character[7][8] = $character[7][11] = "\)";
	$character[0][5] = $character[1][5] = $character[2][2] = $character[2][5]
	    = $character[2][8]  = $character[2][11] = $character[3][2]
	    = $character[3][5]  = $character[3][8]  = $character[3][11]
	    = $character[4][5]  = $character[5][5]  = $character[5][12]
	    = $character[6][5]  = $character[6][7]  = $character[6][10]
	    = $character[6][12] = $character[7][7]  = $character[7][10] = "_";
	return \@character;
}

sub character_u {
	my @character = $_[0]->default_character(16);
	$character[2][2] = $character[2][12] = $character[3][2]
	    = $character[3][12] = $character[4][2]  = $character[4][12]
	    = $character[5][2]  = $character[5][12] = $character[6][2]
	    = $character[6][4]  = $character[6][7]  = $character[6][10]
	    = $character[6][12] = $character[6][14] = $character[7][4]
	    = $character[7][7]  = $character[7][10] = $character[7][14] = "_";
	$character[3][3] = $character[3][13] = $character[4][3]
	    = $character[4][13] = $character[5][3]  = $character[5][13]
	    = $character[6][3]  = $character[6][13] = $character[7][5]
	    = $character[7][8]  = $character[7][11] = $character[7][15] = "\)";
	$character[3][1] = $character[3][11] = $character[4][1]
	    = $character[4][11] = $character[5][1]  = $character[5][11]
	    = $character[6][1]  = $character[6][11] = $character[7][3]
	    = $character[7][6]  = $character[7][9]  = $character[7][13] = "\(";
	return \@character;
}

sub character_v {
	my @character = $_[0]->default_character(16);
	$character[3][1] = $character[3][14] = $character[4][1]
	    = $character[4][13] = $character[5][3] = $character[5][11]
	    = $character[6][5] = $character[6][9] = $character[7][7] = "\(";
	$character[3][3] = $character[3][16] = $character[4][3]
	    = $character[4][15] = $character[5][5] = $character[5][13]
	    = $character[6][7] = $character[6][11] = $character[7][9] = "\)";
	$character[2][0] = $character[2][16] = $character[3][2]
	    = $character[3][4]  = $character[3][13] = $character[3][15]
	    = $character[4][2]  = $character[4][4]  = $character[4][12]
	    = $character[4][14] = $character[5][4]  = $character[5][6]
	    = $character[5][10] = $character[5][12] = $character[6][6]
	    = $character[6][8]  = $character[6][10] = $character[7][8] = "_";
	return \@character;
}

sub character_w {
	my @character = $_[0]->default_character(17);
	$character[3][2] = $character[3][16] = $character[4][2]
	    = $character[4][16] = $character[5][2]  = $character[5][9]
	    = $character[5][16] = $character[6][4]  = $character[6][7]
	    = $character[6][11] = $character[6][14] = $character[7][6]
	    = $character[7][12] = "\)";
	$character[3][0] = $character[3][14] = $character[4][0]
	    = $character[4][14] = $character[5][0]  = $character[5][7]
	    = $character[5][14] = $character[6][2]  = $character[6][5]
	    = $character[6][9]  = $character[6][12] = $character[7][4]
	    = $character[7][10] = "\(";
	$character[2][1] = $character[2][15] = $character[3][1]
	    = $character[3][15] = $character[4][1]  = $character[4][8]
	    = $character[4][15] = $character[5][1]  = $character[5][3]
	    = $character[5][6]  = $character[5][8]  = $character[5][10]
	    = $character[5][13] = $character[5][15] = $character[6][3]
	    = $character[6][6]  = $character[6][10] = $character[6][13]
	    = $character[7][5]  = $character[7][11] = "_";
	return \@character;
}

sub character_x {
	my @character = $_[0]->default_character(14);
	$character[3][1] = $character[3][11] = $character[4][4]
	    = $character[4][8] = $character[5][6] = $character[6][4]
	    = $character[6][8] = $character[7][1] = $character[7][11] = "\(";
	$character[3][3] = $character[3][13] = $character[4][6]
	    = $character[4][10] = $character[5][8] = $character[6][6]
	    = $character[6][10] = $character[7][3] = $character[7][13] = "\)";
	$character[2][2] = $character[2][12] = $character[3][2]
	    = $character[3][5]  = $character[3][9] = $character[3][12]
	    = $character[4][5]  = $character[4][7] = $character[4][9]
	    = $character[5][5]  = $character[5][7] = $character[5][9]
	    = $character[6][2]  = $character[6][5] = $character[6][9]
	    = $character[6][12] = $character[7][2] = $character[7][12] = "_";
	return \@character;
}

sub character_y {
	my @character = $_[0]->default_character(18);
	$character[3][3] = $character[3][17] = $character[4][3]
	    = $character[4][15] = $character[5][5]  = $character[5][13]
	    = $character[6][7]  = $character[6][11] = $character[7][9]
	    = $character[8][7]  = $character[9][2]  = $character[9][5] = "\)";
	$character[3][1] = $character[3][15] = $character[4][1]
	    = $character[4][13] = $character[5][3] = $character[5][11]
	    = $character[6][5]  = $character[6][9] = $character[7][7]
	    = $character[8][5]  = $character[9][0] = $character[9][3] = "\(";
	$character[2][0] = $character[2][16] = $character[3][2]
	    = $character[3][4]  = $character[3][14] = $character[3][16]
	    = $character[4][2]  = $character[4][4]  = $character[4][12]
	    = $character[4][14] = $character[5][4]  = $character[5][6]
	    = $character[5][10] = $character[5][12] = $character[6][6]
	    = $character[6][8]  = $character[6][10] = $character[7][6]
	    = $character[7][8]  = $character[8][1]  = $character[8][4]
	    = $character[8][6]  = $character[9][1]  = $character[9][4] = "_";
	return \@character;
}

sub character_z {
	my @character = $_[0]->default_character(13);
	$character[3][1] = $character[3][4] = $character[3][7]
	    = $character[3][10] = $character[4][9]  = $character[5][6]
	    = $character[6][3]  = $character[7][1]  = $character[7][4]
	    = $character[7][7]  = $character[7][10] = "\(";
	$character[3][3] = $character[3][6] = $character[3][9]
	    = $character[3][12] = $character[4][11] = $character[5][8]
	    = $character[6][5]  = $character[7][3]  = $character[7][6]
	    = $character[7][9]  = $character[7][12] = "\)";
	$character[2][2] = $character[2][5] = $character[2][8]
	    = $character[2][11] = $character[3][2]  = $character[3][5]
	    = $character[3][8]  = $character[3][11] = $character[4][7]
	    = $character[4][10] = $character[5][4]  = $character[5][7]
	    = $character[6][2]  = $character[6][4]  = $character[6][8]
	    = $character[6][11] = $character[7][2]  = $character[7][5]
	    = $character[7][8]  = $character[7][11] = "_";
	return \@character;
}

sub character_0 {
	my @character = $_[0]->default_character(16);
	$character[1][8] = $character[1][11] = $character[2][5]
	    = $character[2][14] = $character[3][4]  = $character[3][15]
	    = $character[4][4]  = $character[4][15] = $character[5][4]
	    = $character[5][15] = $character[6][5]  = $character[6][14]
	    = $character[7][8]  = $character[7][11] = "\)";
	$character[1][6] = $character[1][9] = $character[2][3]
	    = $character[2][12] = $character[3][2]  = $character[3][13]
	    = $character[4][2]  = $character[4][13] = $character[5][2]
	    = $character[5][13] = $character[6][3]  = $character[6][12]
	    = $character[7][6]  = $character[7][9]  = "\(";
	$character[0][7] = $character[0][10] = $character[1][4]
	    = $character[1][7]  = $character[1][10] = $character[1][13]
	    = $character[2][4]  = $character[2][13] = $character[3][3]
	    = $character[3][14] = $character[4][3]  = $character[4][14]
	    = $character[5][3]  = $character[5][14] = $character[6][4]
	    = $character[6][7]  = $character[6][10] = $character[6][13]
	    = $character[7][7]  = $character[7][10] = "_";
	return \@character;
}

sub character_1 {
	my @character = $_[0]->default_character(10);
	$character[1][4] = $character[2][1] = $character[2][4] = $character[3][4]
	    = $character[4][4] = $character[5][4] = $character[6][4]
	    = $character[7][1] = $character[7][4] = $character[7][7] = "\(";
	$character[1][6] = $character[2][3] = $character[2][6] = $character[3][6]
	    = $character[4][6] = $character[5][6] = $character[6][6]
	    = $character[7][3] = $character[7][6] = $character[7][9] = "\)";
	$character[0][5] = $character[1][2] = $character[1][5] = $character[2][2]
	    = $character[2][5] = $character[3][5] = $character[4][5]
	    = $character[5][5] = $character[6][2] = $character[6][5]
	    = $character[6][8] = $character[7][2] = $character[7][5]
	    = $character[7][8] = "_";
	return \@character;
}

sub character_2 {
	my @character = $_[0]->default_character(16);
	$character[1][6] = $character[1][9] = $character[1][12]
	    = $character[2][3]  = $character[2][15] = $character[3][15]
	    = $character[4][12] = $character[5][9]  = $character[6][6]
	    = $character[7][3]  = $character[7][6]  = $character[7][9]
	    = $character[7][12] = $character[7][15] = "\)";
	$character[1][4] = $character[1][7] = $character[1][10]
	    = $character[2][1]  = $character[2][13] = $character[3][13]
	    = $character[4][10] = $character[5][7]  = $character[6][4]
	    = $character[7][1]  = $character[7][4]  = $character[7][7]
	    = $character[7][10] = $character[7][13] = "\(";
	$character[0][5] = $character[0][8] = $character[0][11]
	    = $character[1][2]  = $character[1][5]  = $character[1][8]
	    = $character[1][11] = $character[1][14] = $character[2][2]
	    = $character[2][14] = $character[3][11] = $character[3][14]
	    = $character[4][8]  = $character[4][11] = $character[5][5]
	    = $character[5][8]  = $character[6][2]  = $character[6][5]
	    = $character[6][8]  = $character[6][11] = $character[6][14]
	    = $character[7][2]  = $character[7][5]  = $character[7][8]
	    = $character[7][11] = $character[7][14] = "_";
	return \@character;
}

sub character_3 {
	my @character = $_[0]->default_character(16);
	$character[0][4] = $character[0][7] = $character[0][10]
	    = $character[0][13] = $character[1][2]  = $character[1][4]
	    = $character[1][7]  = $character[1][10] = $character[1][13]
	    = $character[1][15] = $character[2][2]  = $character[2][15]
	    = $character[3][10] = $character[3][13] = $character[3][15]
	    = $character[4][10] = $character[4][13] = $character[4][15]
	    = $character[5][2]  = $character[5][15] = $character[6][2]
	    = $character[6][4]  = $character[6][7]  = $character[6][10]
	    = $character[6][13] = $character[6][15] = $character[7][4]
	    = $character[7][7]  = $character[7][10] = $character[7][13] = "_";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[2][1] = $character[2][14]
	    = $character[3][14] = $character[4][9] = $character[4][12]
	    = $character[5][14] = $character[6][1] = $character[6][14]
	    = $character[7][3]  = $character[7][6] = $character[7][9]
	    = $character[7][12] = "\(";
	$character[1][5] = $character[1][8] = $character[1][11]
	    = $character[1][14] = $character[2][3]  = $character[2][16]
	    = $character[3][16] = $character[4][11] = $character[4][14]
	    = $character[5][16] = $character[6][3]  = $character[6][16]
	    = $character[7][5]  = $character[7][8]  = $character[7][11]
	    = $character[7][14] = "\)";
	return \@character;
}

sub character_4 {
	my @character = $_[0]->default_character(16);
	$character[1][12] = $character[2][9] = $character[2][12]
	    = $character[3][6]  = $character[3][12] = $character[4][3]
	    = $character[4][12] = $character[5][3]  = $character[5][6]
	    = $character[5][9]  = $character[5][12] = $character[5][15]
	    = $character[6][12] = $character[7][12] = "\)";
	$character[1][10] = $character[2][7] = $character[2][10]
	    = $character[3][4]  = $character[3][10] = $character[4][1]
	    = $character[4][10] = $character[5][1]  = $character[5][4]
	    = $character[5][7]  = $character[5][10] = $character[5][13]
	    = $character[6][10] = $character[7][10] = "\(";
	$character[0][11] = $character[1][8] = $character[1][11]
	    = $character[2][5]  = $character[2][8]  = $character[2][11]
	    = $character[3][2]  = $character[3][5]  = $character[3][11]
	    = $character[4][2]  = $character[4][5]  = $character[4][8]
	    = $character[4][11] = $character[4][14] = $character[5][2]
	    = $character[5][5]  = $character[5][8]  = $character[5][11]
	    = $character[5][14] = $character[6][11] = $character[7][11] = "_";
	return \@character;
}

sub character_5 {
	my @character = $_[0]->default_character(16);
	$character[0][2] = $character[0][5] = $character[0][8]
	    = $character[0][11] = $character[0][14] = $character[1][2]
	    = $character[1][5]  = $character[1][8]  = $character[1][11]
	    = $character[1][14] = $character[2][2]  = $character[2][5]
	    = $character[2][8]  = $character[2][11] = $character[3][2]
	    = $character[3][5]  = $character[3][8]  = $character[3][11]
	    = $character[3][14] = $character[4][14] = $character[5][2]
	    = $character[5][14] = $character[6][2]  = $character[6][5]
	    = $character[6][8]  = $character[6][11] = $character[6][14]
	    = $character[7][5]  = $character[7][8]  = $character[7][11] = "_";
	$character[1][1] = $character[1][4] = $character[1][7]
	    = $character[1][10] = $character[1][13] = $character[2][1]
	    = $character[3][1]  = $character[3][4]  = $character[3][7]
	    = $character[3][10] = $character[4][13] = $character[5][13]
	    = $character[6][1]  = $character[6][13] = $character[7][4]
	    = $character[7][7]  = $character[7][10] = "\(";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[1][15] = $character[2][3]
	    = $character[3][3]  = $character[3][6]  = $character[3][9]
	    = $character[3][12] = $character[4][15] = $character[5][15]
	    = $character[6][3]  = $character[6][15] = $character[7][6]
	    = $character[7][9]  = $character[7][12] = "\)";
	return \@character;
}

sub character_6 {
	my @character = $_[0]->default_character(16);
	$character[0][7] = $character[0][10] = $character[0][13]
	    = $character[1][5]  = $character[1][7]  = $character[1][10]
	    = $character[1][13] = $character[2][3]  = $character[2][5]
	    = $character[3][3]  = $character[3][6]  = $character[3][9]
	    = $character[3][12] = $character[4][3]  = $character[4][6]
	    = $character[4][9]  = $character[4][12] = $character[4][14]
	    = $character[5][3]  = $character[5][14] = $character[6][3]
	    = $character[6][5]  = $character[6][8]  = $character[6][11]
	    = $character[6][14] = $character[7][5]  = $character[7][8]
	    = $character[7][11] = "_";
	$character[1][6] = $character[1][9] = $character[1][12]
	    = $character[2][4]  = $character[3][2]  = $character[4][2]
	    = $character[4][5]  = $character[4][8]  = $character[4][11]
	    = $character[5][2]  = $character[5][13] = $character[6][2]
	    = $character[6][13] = $character[7][4]  = $character[7][7]
	    = $character[7][10] = "\(";
	$character[1][8] = $character[1][11] = $character[1][14]
	    = $character[2][6]  = $character[3][4]  = $character[4][4]
	    = $character[4][7]  = $character[4][10] = $character[4][13]
	    = $character[5][4]  = $character[5][15] = $character[6][4]
	    = $character[6][15] = $character[7][6]  = $character[7][9]
	    = $character[7][12] = "\)";
	return \@character;
}

sub character_7 {
	my @character = $_[0]->default_character(16);
	$character[1][1] = $character[1][4] = $character[1][7]
	    = $character[1][10] = $character[1][13] = $character[2][12]
	    = $character[3][10] = $character[4][8]  = $character[5][6]
	    = $character[6][4]  = $character[7][2]  = "\(";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[1][15] = $character[2][14]
	    = $character[3][12] = $character[4][10] = $character[5][8]
	    = $character[6][6]  = $character[7][4]  = "\)";
	$character[0][2] = $character[0][5] = $character[0][8]
	    = $character[0][11] = $character[0][14] = $character[1][2]
	    = $character[1][5]  = $character[1][8]  = $character[1][11]
	    = $character[1][14] = $character[2][11] = $character[2][13]
	    = $character[3][9]  = $character[3][11] = $character[4][7]
	    = $character[4][9]  = $character[5][5]  = $character[5][7]
	    = $character[6][3]  = $character[6][5]  = $character[7][3] = "_";
	return \@character;
}

sub character_8 {
	my @character = $_[0]->default_character(17);
	$character[0][4] = $character[0][7] = $character[0][10]
	    = $character[0][13] = $character[1][2]  = $character[1][4]
	    = $character[1][7]  = $character[1][10] = $character[1][13]
	    = $character[1][15] = $character[2][2]  = $character[2][15]
	    = $character[3][2]  = $character[3][4]  = $character[3][7]
	    = $character[3][10] = $character[3][13] = $character[3][15]
	    = $character[4][2]  = $character[4][4]  = $character[4][7]
	    = $character[4][10] = $character[4][13] = $character[4][15]
	    = $character[5][2]  = $character[5][15] = $character[6][2]
	    = $character[6][4]  = $character[6][7]  = $character[6][10]
	    = $character[6][13] = $character[6][15] = $character[7][4]
	    = $character[7][7]  = $character[7][10] = $character[7][13] = "_";
	$character[1][3] = $character[1][6] = $character[1][9]
	    = $character[1][12] = $character[2][1]  = $character[2][14]
	    = $character[3][1]  = $character[3][14] = $character[4][3]
	    = $character[4][6]  = $character[4][9]  = $character[4][12]
	    = $character[5][1]  = $character[5][14] = $character[6][1]
	    = $character[6][14] = $character[7][3]  = $character[7][6]
	    = $character[7][9]  = $character[7][12] = "\(";
	$character[1][5] = $character[1][8] = $character[1][11]
	    = $character[1][14] = $character[2][3]  = $character[2][16]
	    = $character[3][3]  = $character[3][16] = $character[4][5]
	    = $character[4][8]  = $character[4][11] = $character[4][14]
	    = $character[5][3]  = $character[5][16] = $character[6][3]
	    = $character[6][16] = $character[7][5]  = $character[7][8]
	    = $character[7][11] = $character[7][14] = "\)";
	return \@character;
}

sub character_9 {
	my @character = $_[0]->default_character(16);
	$character[1][4] = $character[1][7] = $character[1][10]
	    = $character[2][1]  = $character[2][13] = $character[3][1]
	    = $character[3][13] = $character[4][4]  = $character[4][7]
	    = $character[4][10] = $character[4][13] = $character[5][13]
	    = $character[6][11] = $character[7][3]  = $character[7][6]
	    = $character[7][9]  = "\(";
	$character[1][6] = $character[1][9] = $character[1][12]
	    = $character[2][3]  = $character[2][15] = $character[3][3]
	    = $character[3][15] = $character[4][6]  = $character[4][9]
	    = $character[4][12] = $character[4][15] = $character[5][15]
	    = $character[6][13] = $character[7][5]  = $character[7][8]
	    = $character[7][11] = "\)";
	$character[0][5] = $character[0][8] = $character[0][11]
	    = $character[1][2]  = $character[1][5]  = $character[1][8]
	    = $character[1][11] = $character[1][14] = $character[2][2]
	    = $character[2][14] = $character[3][2]  = $character[3][5]
	    = $character[3][8]  = $character[3][11] = $character[3][14]
	    = $character[4][5]  = $character[4][8]  = $character[4][11]
	    = $character[4][14] = $character[5][12] = $character[5][14]
	    = $character[6][4]  = $character[6][7]  = $character[6][10]
	    = $character[6][12] = $character[7][4]  = $character[7][7]
	    = $character[7][10] = "_";
	return \@character;
}

1;

__END__

=head1 NAME

Ascii::Text::Font::Dotmatrix - Dotmatrix font

=head1 VERSION

Version 0.18

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	use Ascii::Text::Font::Dotmatrix;

	my $foo = Ascii::Text::Font::Dotmatrix->new();

	...

=head1 SUBROUTINES/METHODS

=head2 character_A

	        _          
	      _(_)_        
	    _(_) (_)_      
	  _(_)     (_)_    
	 (_) _  _  _ (_)   
	 (_)(_)(_)(_)(_)   
	 (_)         (_)   
	 (_)         (_)   
	                   
	                   

=head2 character_B

	  _  _  _  _       
	 (_)(_)(_)(_) _    
	  (_)        (_)   
	  (_) _  _  _(_)   
	  (_)(_)(_)(_)_    
	  (_)        (_)   
	  (_)_  _  _ (_)   
	 (_)(_)(_)(_)      
	                   
	                   

=head2 character_C

	     _  _  _       
	  _ (_)(_)(_) _    
	 (_)         (_)   
	 (_)               
	 (_)               
	 (_)          _    
	 (_) _  _  _ (_)   
	    (_)(_)(_)      
	                   
	                   

=head2 character_D

	  _  _  _  _       
	 (_)(_)(_)(_)      
	  (_)      (_)_    
	  (_)        (_)   
	  (_)        (_)   
	  (_)       _(_)   
	  (_)_  _  (_)     
	 (_)(_)(_)(_)      
	                   
	                   

=head2 character_E

	  _  _  _  _  _    
	 (_)(_)(_)(_)(_)   
	 (_)               
	 (_) _  _          
	 (_)(_)(_)         
	 (_)               
	 (_) _  _  _  _    
	 (_)(_)(_)(_)(_)   
	                   
	                   

=head2 character_F

	  _  _  _  _  _    
	 (_)(_)(_)(_)(_)   
	 (_)               
	 (_) _  _          
	 (_)(_)(_)         
	 (_)               
	 (_)               
	 (_)               
	                   
	                   

=head2 character_G

	     _  _  _       
	  _ (_)(_)(_) _    
	 (_)         (_)   
	 (_)    _  _  _    
	 (_)   (_)(_)(_)   
	 (_)         (_)   
	 (_) _  _  _ (_)   
	    (_)(_)(_)(_)   
	                   
	                   

=head2 character_H

	  _           _    
	 (_)         (_)   
	 (_)         (_)   
	 (_) _  _  _ (_)   
	 (_)(_)(_)(_)(_)   
	 (_)         (_)   
	 (_)         (_)   
	 (_)         (_)   
	                   
	                   

=head2 character_I

	  _  _  _    
	 (_)(_)(_)   
	    (_)      
	    (_)      
	    (_)      
	    (_)      
	  _ (_) _    
	 (_)(_)(_)   
	             
	             

=head2 character_J

	        _  _  _    
	       (_)(_)(_)   
	          (_)      
	          (_)      
	          (_)      
	   _      (_)      
	  (_)  _  (_)      
	   (_)(_)(_)       
	                   
	                   

=head2 character_K

	  _           _    
	 (_)       _ (_)   
	 (_)    _ (_)      
	 (_) _ (_)         
	 (_)(_) _          
	 (_)   (_) _       
	 (_)      (_) _    
	 (_)         (_)   
	                   
	                   

=head2 character_L

	  _                
	 (_)               
	 (_)               
	 (_)               
	 (_)               
	 (_)               
	 (_) _  _  _  _    
	 (_)(_)(_)(_)(_)   
	                   
	                   

=head2 character_M

	  _           _    
	 (_) _     _ (_)   
	 (_)(_)   (_)(_)   
	 (_) (_)_(_) (_)   
	 (_)   (_)   (_)   
	 (_)         (_)   
	 (_)         (_)   
	 (_)         (_)   
	                   
	                   

=head2 character_N

	  _           _    
	 (_) _       (_)   
	 (_)(_)_     (_)   
	 (_)  (_)_   (_)   
	 (_)    (_)_ (_)   
	 (_)      (_)(_)   
	 (_)         (_)   
	 (_)         (_)   
	                   
	                   

=head2 character_O

	    _  _  _  _      
	  _(_)(_)(_)(_)_    
	 (_)          (_)   
	 (_)          (_)   
	 (_)          (_)   
	 (_)          (_)   
	 (_)_  _  _  _(_)   
	   (_)(_)(_)(_)     
	                    
	                    

=head2 character_P

	   _  _  _  _      
	  (_)(_)(_)(_)_    
	  (_)        (_)   
	  (_) _  _  _(_)   
	  (_)(_)(_)(_)     
	  (_)              
	  (_)              
	  (_)              
	                   
	                   

=head2 character_Q

	    _  _  _  _      
	  _(_)(_)(_)(_)_    
	 (_)          (_)   
	 (_)          (_)   
	 (_)     _    (_)   
	 (_)    (_) _ (_)   
	 (_)_  _  _(_) _    
	   (_)(_)(_)  (_)   
	                    
	                    

=head2 character_R

	  _  _  _  _       
	 (_)(_)(_)(_) _    
	 (_)         (_)   
	 (_) _  _  _ (_)   
	 (_)(_)(_)(_)      
	 (_)   (_) _       
	 (_)      (_) _    
	 (_)         (_)   
	                   
	                    

=head2 character_S

	    _  _  _  _      
	  _(_)(_)(_)(_)_    
	 (_)          (_)   
	 (_)_  _  _  _      
	   (_)(_)(_)(_)_    
	  _           (_)   
	 (_)_  _  _  _(_)   
	   (_)(_)(_)(_)     
	                    
	                   

=head2 character_T

	  _  _  _  _  _    
	 (_)(_)(_)(_)(_)   
	       (_)         
	       (_)         
	       (_)         
	       (_)         
	       (_)         
	       (_)         
	                   
	                   

=head2 character_U

	  _            _    
	 (_)          (_)   
	 (_)          (_)   
	 (_)          (_)   
	 (_)          (_)   
	 (_)          (_)   
	 (_)_  _  _  _(_)   
	   (_)(_)(_)(_)     
	                    
	                    

=head2 character_V

	  _           _    
	 (_)         (_)   
	 (_)         (_)   
	 (_)_       _(_)   
	   (_)     (_)     
	    (_)   (_)      
	     (_)_(_)       
	       (_)         
	                   
	                   

=head2 character_W

	 _             _    
	(_)           (_)   
	(_)           (_)   
	(_)     _     (_)   
	(_)   _(_)_   (_)   
	(_)  (_) (_)  (_)   
	(_)_(_)   (_)_(_)   
	  (_)       (_)     
	                    
	                    

=head2 character_X

	  _           _    
	 (_)_       _(_)   
	   (_)_   _(_)     
	     (_)_(_)       
	      _(_)_        
	    _(_) (_)_      
	  _(_)     (_)_    
	 (_)         (_)   
	                   
	                   

=head2 character_Y

	  _           _    
	 (_)_       _(_)   
	   (_)_   _(_)     
	     (_)_(_)       
	       (_)         
	       (_)         
	       (_)         
	       (_)         
	                   
	                   

=head2 character_Z

	  _  _  _  _  _    
	 (_)(_)(_)(_)(_)   
	           _(_)    
	         _(_)      
	       _(_)        
	     _(_)          
	  _ (_) _  _  _    
	 (_)(_)(_)(_)(_)   
	                   
	                   

=head2 character_a

	                   
	                   
	    _  _  _        
	   (_)(_)(_) _     
	    _  _  _ (_)    
	  _(_)(_)(_)(_)    
	 (_)_  _  _ (_)_   
	   (_)(_)(_)  (_)  
	                   
	                   

=head2 character_b

	   _               
	  (_)              
	  (_) _  _  _      
	  (_)(_)(_)(_)_    
	  (_)        (_)   
	  (_)        (_)   
	  (_) _  _  _(_)   
	  (_)(_)(_)(_)     
	                   
	                   

=head2 character_c

	                   
	                   
	     _  _  _       
	   _(_)(_)(_)      
	  (_)              
	  (_)              
	  (_)_  _  _       
	    (_)(_)(_)      
	                   
	                   

=head2 character_d

	              _    
	             (_)   
	     _  _  _ (_)   
	   _(_)(_)(_)(_)   
	  (_)        (_)   
	  (_)        (_)   
	  (_)_  _  _ (_)   
	    (_)(_)(_)(_)   
	                   
	                   

=head2 character_e

	                   
	                   
	   _  _  _  _      
	  (_)(_)(_)(_)_    
	 (_) _  _  _ (_)   
	 (_)(_)(_)(_)(_)   
	 (_)_  _  _  _     
	   (_)(_)(_)(_)    
	                   
	                   

=head2 character_f

	       _  _    
	     _(_)(_)   
	  _ (_) _      
	 (_)(_)(_)     
	    (_)        
	    (_)        
	    (_)        
	    (_)        
	               
	               

=head2 character_g

	                   
	                   
	     _  _  _  _    
	   _(_)(_)(_)(_)   
	  (_)        (_)   
	  (_)        (_)   
	  (_)_  _  _ (_)   
	    (_)(_)(_)(_)   
	     _  _  _ (_)   
	    (_)(_)(_)      

=head2 character_h

	   _               
	  (_)              
	  (_) _  _  _      
	  (_)(_)(_)(_)_    
	  (_)        (_)   
	  (_)        (_)   
	  (_)        (_)   
	  (_)        (_)   
	                   
	                   

=head2 character_i

	      _       
	     (_)      
	   _  _       
	  (_)(_)      
	     (_)      
	     (_)      
	   _ (_) _    
	  (_)(_)(_)   
	              
	              

=head2 character_j

	            _    
	           (_)   
	         _  _    
	        (_)(_)   
	           (_)   
	           (_)   
	           (_)   
	   _      _(_)   
	  (_)_  _(_)     
	    (_)(_)       

=head2 character_k

	   _           
	  (_)          
	  (_)     _    
	  (_)   _(_)   
	  (_) _(_)     
	  (_)(_)_      
	  (_)  (_)_    
	  (_)    (_)   
	               
	               

=head2 character_l

	  _  _       
	 (_)(_)      
	    (_)      
	    (_)      
	    (_)      
	    (_)      
	  _ (_) _    
	 (_)(_)(_)   
	             
	             

=head2 character_m

	                   
	                   
	   _  _   _  _     
	  (_)(_)_(_)(_)    
	 (_)   (_)   (_)   
	 (_)   (_)   (_)   
	 (_)   (_)   (_)   
	 (_)   (_)   (_)   
	                   
	                   

=head2 character_n

	                   
	                   
	   _  _  _  _      
	  (_)(_)(_)(_)_    
	  (_)        (_)   
	  (_)        (_)   
	  (_)        (_)   
	  (_)        (_)   
	                   
	                   

=head2 character_o

	                   
	                   
	     _  _  _       
	  _ (_)(_)(_) _    
	 (_)         (_)   
	 (_)         (_)   
	 (_) _  _  _ (_)   
	    (_)(_)(_)      
	                   
	                   

=head2 character_p

	                   
	                   
	  _  _  _  _       
	 (_)(_)(_)(_)_     
	 (_)        (_)    
	 (_)        (_)    
	 (_) _  _  _(_)    
	 (_)(_)(_)(_)      
	 (_)               
	 (_)               

=head2 character_q

	                   
	                   
	    _  _  _  _     
	  _(_)(_)(_)(_)    
	 (_)        (_)    
	 (_)        (_)    
	 (_)_  _  _ (_)    
	   (_)(_)(_)(_)    
	            (_)    
	            (_)    

=head2 character_r

	                   
	                   
	  _       _  _     
	 (_)_  _ (_)(_)    
	   (_)(_)          
	   (_)             
	   (_)             
	   (_)             
	                   
	                   

=head2 character_s

	                    
	                    
	    _  _  _  _      
	  _(_)(_)(_)(_)     
	 (_)_  _  _  _      
	   (_)(_)(_)(_)_    
	    _  _  _  _(_)   
	   (_)(_)(_)(_)     
	                    
	                    

=head2 character_t

	     _            
	    (_)           
	  _ (_) _  _      
	 (_)(_)(_)(_)     
	    (_)           
	    (_)     _     
	    (_)_  _(_)    
	      (_)(_)      
	                  
	                  

=head2 character_u

	                   
	                   
	  _         _      
	 (_)       (_)     
	 (_)       (_)     
	 (_)       (_)     
	 (_)_  _  _(_)_    
	   (_)(_)(_) (_)   
	                   
	                   

=head2 character_v

	                   
	                   
	_               _   
	 (_)_        _(_)   
	 (_)_       _(_)    
	   (_)_   _(_)      
	     (_)_(_)        
	       (_)          
	                    
	                    

=head2 character_w

	                    
	                    
	 _             _    
	(_)           (_)   
	(_)     _     (_)   
	(_)_  _(_)_  _(_)   
	  (_)(_) (_)(_)     
	    (_)   (_)       
	                    
	                    

=head2 character_x

	                 
	                 
	  _         _    
	 (_) _   _ (_)   
	    (_)_(_)      
	     _(_)_       
	  _ (_) (_) _    
	 (_)       (_)   
	                 
	                 

=head2 character_y

	                     
	                     
	_               _    
	 (_)_         _(_)   
	 (_)_       _(_)     
	   (_)_   _(_)       
	     (_)_(_)         
	      _(_)           
	 _  _(_)             
	(_)(_)               

=head2 character_z

	                
	                
	  _  _  _  _    
	 (_)(_)(_)(_)   
	       _ (_)    
	    _ (_)       
	  _(_)  _  _    
	 (_)(_)(_)(_)   
	                
	                

=head2 character_0

	       _  _        
	    _ (_)(_) _     
	   (_)      (_)    
	  (_)        (_)   
	  (_)        (_)   
	  (_)        (_)   
	   (_) _  _ (_)    
	      (_)(_)       
	                   
	                   

=head2 character_1

	     _       
	  _ (_)      
	 (_)(_)      
	    (_)      
	    (_)      
	    (_)      
	  _ (_) _    
	 (_)(_)(_)   
	             
	             

=head2 character_2

	     _  _  _       
	  _ (_)(_)(_) _    
	 (_)         (_)   
	           _ (_)   
	        _ (_)      
	     _ (_)         
	  _ (_) _  _  _    
	 (_)(_)(_)(_)(_)   
	                   
	                   

=head2 character_3

	    _  _  _  _     
	  _(_)(_)(_)(_)_   
	 (_)          (_)  
	          _  _(_)  
	         (_)(_)_   
	  _           (_)  
	 (_)_  _  _  _(_)  
	   (_)(_)(_)(_)    
	                   
	                   

=head2 character_4

	           _       
	        _ (_)      
	     _ (_)(_)      
	  _ (_)   (_)      
	 (_) _  _ (_) _    
	 (_)(_)(_)(_)(_)   
	          (_)      
	          (_)      
	                   
	                   

=head2 character_5

	  _  _  _  _  _    
	 (_)(_)(_)(_)(_)   
	 (_) _  _  _       
	 (_)(_)(_)(_) _    
	             (_)   
	  _          (_)   
	 (_) _  _  _ (_)   
	    (_)(_)(_)      
	                   
	                   

=head2 character_6

	       _  _  _     
	     _(_)(_)(_)    
	   _(_)            
	  (_) _  _  _      
	  (_)(_)(_)(_)_    
	  (_)        (_)   
	  (_)_  _  _ (_)   
	    (_)(_)(_)      
	                   
	                   

=head2 character_7

	  _  _  _  _  _    
	 (_)(_)(_)(_)(_)   
	           _(_)    
	         _(_)      
	       _(_)        
	     _(_)          
	   _(_)            
	  (_)              
	                   
	                   

=head2 character_8

	    _  _  _  _      
	  _(_)(_)(_)(_)_    
	 (_)          (_)   
	 (_)_  _  _  _(_)   
	  _(_)(_)(_)(_)_    
	 (_)          (_)   
	 (_)_  _  _  _(_)   
	   (_)(_)(_)(_)     
	                    
	                    

=head2 character_9

	     _  _  _       
	  _ (_)(_)(_) _    
	 (_)         (_)   
	 (_) _  _  _ (_)   
	    (_)(_)(_)(_)   
	            _(_)   
	    _  _  _(_)     
	   (_)(_)(_)       
	                   

=head1 EXTENDS

=head2 Ascii::Text::Font



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::dotmatrix at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Dotmatrix>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Dotmatrix

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Dotmatrix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Dotmatrix>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Dotmatrix>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Dotmatrix>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
