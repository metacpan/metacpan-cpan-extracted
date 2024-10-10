package Ascii::Text::Font::Colossal;
use strict;
use warnings;
use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable => 0,
	writable => 0,
	value => 12,
);

function space => sub {
	my @character = $_[0]->default_character(12);
	return \@character;
};

function character_A => sub {
	my @character = $_[0]->default_character(14);
	$character[0][8] = $character[0][9] = $character[0][10]
	    = $character[0][11] = $character[1][7]  = $character[1][8]
	    = $character[1][9]  = $character[1][10] = $character[1][11]
	    = $character[2][6]  = $character[2][7]  = $character[2][9]
	    = $character[2][10] = $character[2][11] = $character[3][5]
	    = $character[3][6]  = $character[3][9]  = $character[3][10]
	    = $character[3][11] = $character[4][4]  = $character[4][5]
	    = $character[4][9]  = $character[4][10] = $character[4][11]
	    = $character[5][3]  = $character[5][4]  = $character[5][9]
	    = $character[5][10] = $character[5][11] = $character[6][2]
	    = $character[6][3]  = $character[6][4]  = $character[6][5]
	    = $character[6][6]  = $character[6][7]  = $character[6][8]
	    = $character[6][9]  = $character[6][10] = $character[6][11]
	    = $character[7][1]  = $character[7][2]  = $character[7][9]
	    = $character[7][10] = $character[7][11] = "8";
	$character[0][7] = $character[1][6] = $character[2][5] = $character[3][4]
	    = $character[4][3] = $character[5][2] = $character[6][1]
	    = $character[7][0] = "d";
	$character[0][6] = $character[0][12] = $character[1][5]
	    = $character[1][12] = $character[2][4]  = $character[2][12]
	    = $character[3][3]  = $character[3][12] = $character[4][2]
	    = $character[4][12] = $character[5][1]  = $character[5][12]
	    = $character[6][0]  = $character[6][12] = $character[7][12] = "\$";
	$character[2][8] = $character[3][7] = $character[4][6] = $character[5][5]
	    = $character[7][3] = "P";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(12);
	$character[0][7] = $character[2][5] = $character[3][8] = "\.";
	$character[2][8] = $character[6][9] = $character[7][7] = "P";
	$character[0][8] = $character[1][9] = $character[2][9] = $character[3][9]
	    = $character[4][10] = $character[5][10] = $character[6][10]
	    = $character[7][9]  = "\$";
	$character[0][6] = $character[1][8] = $character[4][9] = "b";
	$character[4][6] = "Y";
	$character[6][6] = "d";
	$character[3][7] = "K";
	$character[1][5] = $character[4][5] = $character[7][8] = "\"";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[1][0]
	    = $character[1][1] = $character[1][2] = $character[1][6]
	    = $character[1][7] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][6] = $character[2][7]
	    = $character[3][0] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][7] = $character[4][8]
	    = $character[5][0] = $character[5][1] = $character[5][2]
	    = $character[5][7] = $character[5][8] = $character[5][9]
	    = $character[6][0] = $character[6][1] = $character[6][2]
	    = $character[6][7] = $character[6][8] = $character[7][0]
	    = $character[7][1] = $character[7][2] = $character[7][3]
	    = $character[7][4] = $character[7][5] = $character[7][6] = "8";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(12);
	$character[1][6] = $character[6][0] = $character[7][2] = "Y";
	$character[0][2] = $character[1][0] = $character[6][6] = "d";
	$character[1][3] = $character[6][9] = $character[7][7] = "P";
	$character[0][0] = $character[0][9] = $character[1][10]
	    = $character[2][10] = $character[3][9] = $character[4][9]
	    = $character[5][10] = $character[6][10] = $character[7][0]
	    = $character[7][9]  = "\$";
	$character[0][7] = $character[1][9] = $character[6][3] = "b";
	$character[0][1] = $character[0][8] = "\.";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][1] = $character[1][2] = $character[1][7]
	    = $character[1][8] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][7] = $character[2][8]
	    = $character[2][9] = $character[3][0] = $character[3][1]
	    = $character[3][2] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[5][0] = $character[5][1]
	    = $character[5][2] = $character[5][7] = $character[5][8]
	    = $character[5][9] = $character[6][1] = $character[6][2]
	    = $character[6][7] = $character[6][8] = $character[7][3]
	    = $character[7][4] = $character[7][5] = $character[7][6] = "8";
	$character[7][1] = $character[7][8] = "\"";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(12);
	$character[0][8] = $character[6][5]  = "\.";
	$character[6][9] = $character[7][7]  = "P";
	$character[0][9] = $character[1][10] = $character[2][10]
	    = $character[3][10] = $character[4][10] = $character[5][10]
	    = $character[6][10] = $character[7][9] = "\$";
	$character[0][7] = $character[1][9] = "b";
	$character[1][6] = "Y";
	$character[6][6] = "d";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][0] = $character[1][1] = $character[1][2]
	    = $character[1][7] = $character[1][8] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[2][7]
	    = $character[2][8] = $character[2][9] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][7]
	    = $character[3][8] = $character[3][9] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[4][7]
	    = $character[4][8] = $character[4][9] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[5][7]
	    = $character[5][8] = $character[5][9] = $character[6][0]
	    = $character[6][1] = $character[6][2] = $character[6][7]
	    = $character[6][8] = $character[7][0] = $character[7][1]
	    = $character[7][2] = $character[7][3] = $character[7][4]
	    = $character[7][5] = $character[7][6] = "8";
	$character[1][5] = $character[7][8] = "\"";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(12);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[0][7] = $character[0][8] = $character[0][9]
	    = $character[1][0] = $character[1][1] = $character[1][2]
	    = $character[2][0] = $character[2][1] = $character[2][2]
	    = $character[3][0] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[5][0] = $character[5][1]
	    = $character[5][2] = $character[6][0] = $character[6][1]
	    = $character[6][2] = $character[7][0] = $character[7][1]
	    = $character[7][2] = $character[7][3] = $character[7][4]
	    = $character[7][5] = $character[7][6] = $character[7][7]
	    = $character[7][8] = $character[7][9] = "8";
	$character[0][10] = $character[1][7] = $character[2][7]
	    = $character[3][7] = $character[4][7] = $character[5][7]
	    = $character[6][7] = $character[7][10] = "\$";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(12);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[0][7] = $character[0][8] = $character[0][9]
	    = $character[1][0] = $character[1][1] = $character[1][2]
	    = $character[2][0] = $character[2][1] = $character[2][2]
	    = $character[3][0] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[5][0] = $character[5][1]
	    = $character[5][2] = $character[6][0] = $character[6][1]
	    = $character[6][2] = $character[7][0] = $character[7][1]
	    = $character[7][2] = "8";
	$character[0][10] = $character[1][7] = $character[2][7]
	    = $character[3][7] = $character[4][7] = $character[5][7]
	    = $character[6][7] = $character[7][7] = "\$";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(12);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][1] = $character[1][2] = $character[1][7]
	    = $character[1][8] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][7] = $character[2][8]
	    = $character[2][9] = $character[3][0] = $character[3][1]
	    = $character[3][2] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][5] = $character[4][6]
	    = $character[4][7] = $character[4][8] = $character[4][9]
	    = $character[5][0] = $character[5][1] = $character[5][2]
	    = $character[5][7] = $character[5][8] = $character[5][9]
	    = $character[6][1] = $character[6][2] = $character[6][7]
	    = $character[6][8] = $character[7][3] = $character[7][4]
	    = $character[7][5] = $character[7][6] = $character[7][8]
	    = $character[7][9] = "8";
	$character[7][1] = "\"";
	$character[0][1] = $character[0][8] = "\.";
	$character[1][6] = $character[6][0] = $character[7][2] = "Y";
	$character[0][2] = $character[1][0] = $character[6][6] = "d";
	$character[1][3] = $character[6][9] = $character[7][7] = "P";
	$character[0][0] = $character[0][9] = $character[1][10]
	    = $character[2][10] = $character[3][10] = $character[4][10]
	    = $character[5][10] = $character[6][10] = $character[7][0]
	    = $character[7][10] = "\$";
	$character[0][7] = $character[1][9] = $character[6][3] = "b";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(12);
	$character[0][10] = $character[1][10] = $character[2][10]
	    = $character[3][10] = $character[4][10] = $character[5][10]
	    = $character[6][10] = $character[7][10] = "\$";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][7]
	    = $character[0][8] = $character[0][9] = $character[1][0]
	    = $character[1][1] = $character[1][2] = $character[1][7]
	    = $character[1][8] = $character[1][9] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[2][7]
	    = $character[2][8] = $character[2][9] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[3][7] = $character[3][8] = $character[3][9]
	    = $character[4][0] = $character[4][1] = $character[4][2]
	    = $character[4][7] = $character[4][8] = $character[4][9]
	    = $character[5][0] = $character[5][1] = $character[5][2]
	    = $character[5][7] = $character[5][8] = $character[5][9]
	    = $character[6][0] = $character[6][1] = $character[6][2]
	    = $character[6][7] = $character[6][8] = $character[6][9]
	    = $character[7][0] = $character[7][1] = $character[7][2]
	    = $character[7][7] = $character[7][8] = $character[7][9] = "8";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[5][2] = $character[5][3] = $character[5][4]
	    = $character[6][2] = $character[6][3] = $character[6][4]
	    = $character[7][0] = $character[7][1] = $character[7][2]
	    = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6] = "8";
	$character[0][7] = $character[1][6] = $character[2][6] = $character[3][6]
	    = $character[4][6] = $character[5][6] = $character[6][6]
	    = $character[7][7] = "\$";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(10);
	$character[8][4] = $character[9][2] = "d";
	$character[6][7] = $character[8][7] = $character[9][5]
	    = $character[10][3] = "P";
	$character[0][8] = $character[1][8] = $character[2][8] = $character[3][8]
	    = $character[4][8]  = $character[5][8] = $character[6][8]
	    = $character[7][8]  = $character[8][8] = $character[9][7]
	    = $character[10][6] = "\$";
	$character[1][7] = "b";
	$character[8][3] = $character[9][1] = "\.";
	$character[1][4] = $character[9][6] = $character[10][4] = "\"";
	$character[0][2] = $character[0][3] = $character[0][4]  = $character[0][5]
	    = $character[0][6]  = $character[0][7]  = $character[1][5]
	    = $character[1][6]  = $character[2][5]  = $character[2][6]
	    = $character[2][7]  = $character[3][5]  = $character[3][6]
	    = $character[3][7]  = $character[4][5]  = $character[4][6]
	    = $character[4][7]  = $character[5][5]  = $character[5][6]
	    = $character[5][7]  = $character[6][5]  = $character[6][6]
	    = $character[7][5]  = $character[7][6]  = $character[7][7]
	    = $character[8][5]  = $character[8][6]  = $character[9][3]
	    = $character[9][4]  = $character[10][0] = $character[10][1]
	    = $character[10][2] = "8";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(13);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][8]
	    = $character[1][0] = $character[1][1] = $character[1][2]
	    = $character[1][7] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][6] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][4]
	    = $character[3][5] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = $character[4][6] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[5][6]
	    = $character[5][7] = $character[6][0] = $character[6][1]
	    = $character[6][2] = $character[6][7] = $character[6][8]
	    = $character[7][0] = $character[7][1] = $character[7][2]
	    = $character[7][8] = $character[7][9] = "8";
	$character[3][6]  = "K";
	$character[0][9]  = $character[1][8]  = $character[2][7] = "P";
	$character[0][10] = $character[1][10] = $character[2][9]
	    = $character[3][8] = $character[4][9] = $character[5][10]
	    = $character[6][11] = $character[7][11] = "\$";
	$character[4][7] = $character[5][8] = $character[6][9]
	    = $character[7][10] = "b";
	$character[5][5] = $character[6][6] = $character[7][7] = "Y";
	$character[0][7] = $character[1][6] = $character[2][5] = $character[3][3]
	    = "d";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(10);
	$character[0][6] = $character[1][6] = $character[2][6] = $character[3][6]
	    = $character[4][6] = $character[5][6] = $character[6][6]
	    = $character[7][8] = "\$";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[1][1] = $character[1][2] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[6][0]
	    = $character[6][1] = $character[6][2] = $character[7][0]
	    = $character[7][1] = $character[7][2] = $character[7][3]
	    = $character[7][4] = $character[7][5] = $character[7][6]
	    = $character[7][7] = "8";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(15);
	$character[0][13] = $character[1][13] = $character[2][13]
	    = $character[3][13] = $character[4][13] = $character[5][13]
	    = $character[6][13] = $character[7][13] = "\$";
	$character[3][9] = $character[4][8] = $character[5][7] = "P";
	$character[0][3] = $character[1][4] = $character[2][5] = "b";
	$character[3][3] = $character[4][4] = $character[5][5] = "Y";
	$character[0][9] = $character[1][8] = $character[2][7] = "d";
	$character[2][6] = "\.";
	$character[6][6] = "\"";
	$character[0][0] = $character[0][1] = $character[0][2]
	    = $character[0][10] = $character[0][11] = $character[0][12]
	    = $character[1][0]  = $character[1][1]  = $character[1][2]
	    = $character[1][3]  = $character[1][9]  = $character[1][10]
	    = $character[1][11] = $character[1][12] = $character[2][0]
	    = $character[2][1]  = $character[2][2]  = $character[2][3]
	    = $character[2][4]  = $character[2][8]  = $character[2][9]
	    = $character[2][10] = $character[2][11] = $character[2][12]
	    = $character[3][0]  = $character[3][1]  = $character[3][2]
	    = $character[3][4]  = $character[3][5]  = $character[3][6]
	    = $character[3][7]  = $character[3][8]  = $character[3][10]
	    = $character[3][11] = $character[3][12] = $character[4][0]
	    = $character[4][1]  = $character[4][2]  = $character[4][5]
	    = $character[4][6]  = $character[4][7]  = $character[4][10]
	    = $character[4][11] = $character[4][12] = $character[5][0]
	    = $character[5][1]  = $character[5][2]  = $character[5][6]
	    = $character[5][10] = $character[5][11] = $character[5][12]
	    = $character[6][0]  = $character[6][1]  = $character[6][2]
	    = $character[6][10] = $character[6][11] = $character[6][12]
	    = $character[7][0]  = $character[7][1]  = $character[7][2]
	    = $character[7][10] = $character[7][11] = $character[7][12] = "8";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(13);
	$character[3][3] = $character[4][4] = $character[5][5] = $character[6][6]
	    = $character[7][7] = "Y";
	$character[0][3] = $character[1][4] = $character[2][5] = $character[3][6]
	    = $character[4][7] = "b";
	$character[0][11] = $character[1][11] = $character[2][11]
	    = $character[3][11] = $character[4][11] = $character[5][11]
	    = $character[6][11] = $character[7][11] = "\$";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][8]
	    = $character[0][9]  = $character[0][10] = $character[1][0]
	    = $character[1][1]  = $character[1][2]  = $character[1][3]
	    = $character[1][8]  = $character[1][9]  = $character[1][10]
	    = $character[2][0]  = $character[2][1]  = $character[2][2]
	    = $character[2][3]  = $character[2][4]  = $character[2][8]
	    = $character[2][9]  = $character[2][10] = $character[3][0]
	    = $character[3][1]  = $character[3][2]  = $character[3][4]
	    = $character[3][5]  = $character[3][8]  = $character[3][9]
	    = $character[3][10] = $character[4][0]  = $character[4][1]
	    = $character[4][2]  = $character[4][5]  = $character[4][6]
	    = $character[4][8]  = $character[4][9]  = $character[4][10]
	    = $character[5][0]  = $character[5][1]  = $character[5][2]
	    = $character[5][6]  = $character[5][7]  = $character[5][8]
	    = $character[5][9]  = $character[5][10] = $character[6][0]
	    = $character[6][1]  = $character[6][2]  = $character[6][7]
	    = $character[6][8]  = $character[6][9]  = $character[6][10]
	    = $character[7][0]  = $character[7][1]  = $character[7][2]
	    = $character[7][8]  = $character[7][9]  = $character[7][10] = "8";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(13);
	$character[0][1] = $character[0][9] = $character[6][4] = $character[6][6]
	    = "\.";
	$character[1][7] = $character[6][0]  = $character[7][2] = "Y";
	$character[0][2] = $character[1][0]  = $character[6][7] = "d";
	$character[0][0] = $character[0][10] = $character[1][11]
	    = $character[2][11] = $character[3][11] = $character[4][11]
	    = $character[5][11] = $character[6][11] = $character[7][0]
	    = $character[7][10] = "\$";
	$character[1][3] = $character[6][10] = $character[7][8] = "P";
	$character[0][8] = $character[1][10] = $character[6][3] = "b";
	$character[1][4] = $character[1][6]  = $character[7][1] = $character[7][9]
	    = "\"";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[0][7] = $character[1][1]  = $character[1][2]
	    = $character[1][8] = $character[1][9]  = $character[2][0]
	    = $character[2][1] = $character[2][2]  = $character[2][8]
	    = $character[2][9] = $character[2][10] = $character[3][0]
	    = $character[3][1] = $character[3][2]  = $character[3][8]
	    = $character[3][9] = $character[3][10] = $character[4][0]
	    = $character[4][1] = $character[4][2]  = $character[4][8]
	    = $character[4][9] = $character[4][10] = $character[5][0]
	    = $character[5][1] = $character[5][2]  = $character[5][8]
	    = $character[5][9] = $character[5][10] = $character[6][1]
	    = $character[6][2] = $character[6][8]  = $character[6][9]
	    = $character[7][3] = $character[7][4]  = $character[7][5]
	    = $character[7][6] = $character[7][7]  = "8";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(12);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][0] = $character[1][1] = $character[1][2]
	    = $character[1][7] = $character[1][8] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[2][7]
	    = $character[2][8] = $character[2][9] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][7]
	    = $character[3][8] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = $character[4][6] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[6][0]
	    = $character[6][1] = $character[6][2] = $character[7][0]
	    = $character[7][1] = $character[7][2] = "8";
	$character[4][8] = "\"";
	$character[3][6] = "d";
	$character[1][6] = "Y";
	$character[0][7] = $character[1][9]  = "b";
	$character[0][9] = $character[1][10] = $character[2][10]
	    = $character[3][10] = $character[4][9] = $character[5][4]
	    = $character[6][4] = $character[7][4] = "\$";
	$character[3][9] = $character[4][7] = "P";
	$character[0][8] = "\.";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(13);
	$character[1][7] = $character[5][4] = $character[6][0] = $character[6][5]
	    = $character[7][2] = $character[8][7] = "Y";
	$character[0][2] = $character[1][0]  = "d";
	$character[1][3] = $character[6][10] = "P";
	$character[0][0] = $character[0][10] = $character[1][11]
	    = $character[2][11] = $character[3][11] = $character[4][11]
	    = $character[5][11] = $character[6][11] = $character[7][0]
	    = $character[7][11] = $character[8][11] = "\$";
	$character[0][8] = $character[1][10] = $character[5][6]
	    = $character[6][3] = $character[6][7] = $character[8][9] = "b";
	$character[0][1] = $character[0][9] = $character[6][4] = "\.";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[0][7] = $character[1][1]  = $character[1][2]
	    = $character[1][8] = $character[1][9]  = $character[2][0]
	    = $character[2][1] = $character[2][2]  = $character[2][8]
	    = $character[2][9] = $character[2][10] = $character[3][0]
	    = $character[3][1] = $character[3][2]  = $character[3][8]
	    = $character[3][9] = $character[3][10] = $character[4][0]
	    = $character[4][1] = $character[4][2]  = $character[4][8]
	    = $character[4][9] = $character[4][10] = $character[5][0]
	    = $character[5][1] = $character[5][2]  = $character[5][5]
	    = $character[5][8] = $character[5][9]  = $character[5][10]
	    = $character[6][1] = $character[6][2]  = $character[6][6]
	    = $character[6][8] = $character[6][9]  = $character[7][3]
	    = $character[7][4] = $character[7][5]  = $character[7][6]
	    = $character[7][7] = $character[7][8]  = $character[8][8] = "8";
	$character[1][4] = $character[1][6] = $character[7][1] = $character[7][9]
	    = "\"";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(12);
	$character[0][8] = "\.";
	$character[3][6] = "d";
	$character[1][6] = "Y";
	$character[5][4] = $character[6][5] = $character[7][6] = "T";
	$character[0][7] = $character[1][9] = $character[5][7] = $character[6][8]
	    = $character[7][9] = "b";
	$character[0][9] = $character[1][10] = $character[2][10]
	    = $character[3][10] = $character[4][9] = $character[5][9]
	    = $character[6][9] = $character[7][10] = "\$";
	$character[3][9] = $character[4][7] = "P";
	$character[4][8] = "\"";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][0] = $character[1][1] = $character[1][2]
	    = $character[1][7] = $character[1][8] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[2][7]
	    = $character[2][8] = $character[2][9] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][7]
	    = $character[3][8] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = $character[4][6] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[5][5]
	    = $character[5][6] = $character[6][0] = $character[6][1]
	    = $character[6][2] = $character[6][6] = $character[6][7]
	    = $character[7][0] = $character[7][1] = $character[7][2]
	    = $character[7][7] = $character[7][8] = "8";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(12);
	$character[0][1] = $character[0][8] = $character[2][4] = $character[3][7]
	    = $character[4][9] = "\.";
	$character[1][3] = $character[6][9] = $character[7][7] = "P";
	$character[0][0] = $character[0][9] = $character[1][10]
	    = $character[2][9]  = $character[3][0]  = $character[3][9]
	    = $character[4][0]  = $character[4][10] = $character[5][0]
	    = $character[5][10] = $character[6][10] = $character[7][9] = "\$";
	$character[0][7] = $character[1][9] = $character[2][3] = $character[3][6]
	    = $character[4][8] = $character[6][3] = "b";
	$character[1][6] = $character[2][0] = $character[3][2] = $character[4][5]
	    = $character[6][0] = $character[7][2] = "Y";
	$character[0][2] = $character[1][0] = $character[6][6] = "d";
	$character[3][1] = $character[4][4] = $character[5][6] = $character[7][1]
	    = $character[7][8] = "\"";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][1] = $character[1][2] = $character[1][7]
	    = $character[1][8] = $character[2][1] = $character[2][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[4][6] = $character[4][7] = $character[5][7]
	    = $character[5][8] = $character[5][9] = $character[6][1]
	    = $character[6][2] = $character[6][7] = $character[6][8]
	    = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6] = "8";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(13);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4]  = $character[0][5] = $character[0][6]
	    = $character[0][7]  = $character[0][8] = $character[0][9]
	    = $character[0][10] = $character[1][4] = $character[1][5]
	    = $character[1][6]  = $character[2][4] = $character[2][5]
	    = $character[2][6]  = $character[3][4] = $character[3][5]
	    = $character[3][6]  = $character[4][4] = $character[4][5]
	    = $character[4][6]  = $character[5][4] = $character[5][5]
	    = $character[5][6]  = $character[6][4] = $character[6][5]
	    = $character[6][6]  = $character[7][4] = $character[7][5]
	    = $character[7][6]  = "8";
	$character[0][11] = $character[1][8] = $character[2][8]
	    = $character[3][8] = $character[4][8] = $character[5][8]
	    = $character[6][8] = $character[7][8] = "\$";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(13);
	$character[6][4]  = $character[6][6] = "\.";
	$character[6][7]  = "d";
	$character[6][0]  = $character[7][2] = "Y";
	$character[6][3]  = "b";
	$character[6][10] = $character[7][8]  = "P";
	$character[0][11] = $character[1][11] = $character[2][11]
	    = $character[3][11] = $character[4][11] = $character[5][11]
	    = $character[6][11] = $character[7][0] = $character[7][10] = "\$";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][8]
	    = $character[0][9] = $character[0][10] = $character[1][0]
	    = $character[1][1] = $character[1][2]  = $character[1][8]
	    = $character[1][9] = $character[1][10] = $character[2][0]
	    = $character[2][1] = $character[2][2]  = $character[2][8]
	    = $character[2][9] = $character[2][10] = $character[3][0]
	    = $character[3][1] = $character[3][2]  = $character[3][8]
	    = $character[3][9] = $character[3][10] = $character[4][0]
	    = $character[4][1] = $character[4][2]  = $character[4][8]
	    = $character[4][9] = $character[4][10] = $character[5][0]
	    = $character[5][1] = $character[5][2]  = $character[5][8]
	    = $character[5][9] = $character[5][10] = $character[6][1]
	    = $character[6][2] = $character[6][8]  = $character[6][9]
	    = $character[7][3] = $character[7][4]  = $character[7][5]
	    = $character[7][6] = $character[7][7]  = "8";
	$character[7][1] = $character[7][9] = "\"";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(13);
	$character[5][5] = "o";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][8]
	    = $character[0][9] = $character[0][10] = $character[1][0]
	    = $character[1][1] = $character[1][2]  = $character[1][8]
	    = $character[1][9] = $character[1][10] = $character[2][0]
	    = $character[2][1] = $character[2][2]  = $character[2][8]
	    = $character[2][9] = $character[2][10] = $character[3][1]
	    = $character[3][2] = $character[3][8]  = $character[3][9]
	    = $character[4][2] = $character[4][3]  = $character[4][7]
	    = $character[4][8] = $character[5][3]  = $character[5][4]
	    = $character[5][6] = $character[5][7]  = $character[6][4]
	    = $character[6][5] = $character[6][6]  = $character[7][5] = "8";
	$character[3][3]  = $character[4][4] = "b";
	$character[3][10] = $character[4][9] = $character[5][8]
	    = $character[6][7] = $character[7][6] = "P";
	$character[0][11] = $character[1][11] = $character[2][11]
	    = $character[3][11] = $character[4][11] = $character[5][10]
	    = $character[6][9] = $character[7][8] = "\$";
	$character[3][7] = $character[4][6] = "d";
	$character[3][0] = $character[4][1] = $character[5][2] = $character[6][3]
	    = $character[7][4] = "Y";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(15);
	$character[5][7]  = $character[6][8]  = $character[7][9] = "Y";
	$character[2][5]  = $character[3][4]  = $character[4][3] = "d";
	$character[0][13] = $character[1][13] = $character[2][13]
	    = $character[3][13] = $character[4][13] = $character[5][13]
	    = $character[6][13] = $character[7][13] = "\$";
	$character[5][5] = $character[6][4] = $character[7][3] = "P";
	$character[2][7] = $character[3][8] = $character[4][9] = "b";
	$character[0][0] = $character[0][1] = $character[0][2]
	    = $character[0][10] = $character[0][11] = $character[0][12]
	    = $character[1][0]  = $character[1][1]  = $character[1][2]
	    = $character[1][10] = $character[1][11] = $character[1][12]
	    = $character[2][0]  = $character[2][1]  = $character[2][2]
	    = $character[2][6]  = $character[2][10] = $character[2][11]
	    = $character[2][12] = $character[3][0]  = $character[3][1]
	    = $character[3][2]  = $character[3][5]  = $character[3][6]
	    = $character[3][7]  = $character[3][10] = $character[3][11]
	    = $character[3][12] = $character[4][0]  = $character[4][1]
	    = $character[4][2]  = $character[4][4]  = $character[4][5]
	    = $character[4][6]  = $character[4][7]  = $character[4][8]
	    = $character[4][10] = $character[4][11] = $character[4][12]
	    = $character[5][0]  = $character[5][1]  = $character[5][2]
	    = $character[5][3]  = $character[5][4]  = $character[5][8]
	    = $character[5][9]  = $character[5][10] = $character[5][11]
	    = $character[5][12] = $character[6][0]  = $character[6][1]
	    = $character[6][2]  = $character[6][3]  = $character[6][9]
	    = $character[6][10] = $character[6][11] = $character[6][12]
	    = $character[7][0]  = $character[7][1]  = $character[7][2]
	    = $character[7][10] = $character[7][11] = $character[7][12] = "8";
	$character[1][6] = "o";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(13);
	$character[0][1] = $character[0][2] = $character[0][8] = $character[0][9]
	    = $character[1][2] = $character[1][3] = $character[1][7]
	    = $character[1][8] = $character[2][3] = $character[2][4]
	    = $character[2][6] = $character[2][7] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[4][4]
	    = $character[4][5] = $character[4][6] = $character[5][3]
	    = $character[5][4] = $character[5][5] = $character[5][6]
	    = $character[5][7] = $character[6][2] = $character[6][3]
	    = $character[6][7] = $character[6][8] = $character[7][1]
	    = $character[7][2] = $character[7][8] = $character[7][9] = "8";
	$character[2][5] = "o";
	$character[0][0] = $character[1][1] = $character[2][2] = $character[3][3]
	    = $character[6][6] = $character[7][7] = "Y";
	$character[0][7] = $character[1][6] = $character[4][3] = $character[5][2]
	    = $character[6][1] = $character[7][0] = "d";
	$character[0][11] = $character[1][11] = $character[2][10]
	    = $character[3][10] = $character[4][10] = $character[5][10]
	    = $character[6][11] = $character[7][11] = "\$";
	$character[0][10] = $character[1][9] = $character[2][8]
	    = $character[3][7] = $character[6][4] = $character[7][3] = "P";
	$character[0][3] = $character[1][4] = $character[4][7] = $character[5][8]
	    = $character[6][9] = $character[7][10] = "b";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(13);
	$character[0][3]  = $character[1][4]  = "b";
	$character[0][11] = $character[1][11] = $character[2][10]
	    = $character[3][9] = $character[4][8] = $character[5][8]
	    = $character[6][8] = $character[7][8] = "\$";
	$character[0][10] = $character[1][9] = $character[2][8]
	    = $character[3][7] = "P";
	$character[0][7] = $character[1][6] = "d";
	$character[0][0] = $character[1][1] = $character[2][2] = $character[3][3]
	    = "Y";
	$character[2][5] = "o";
	$character[0][1] = $character[0][2] = $character[0][8] = $character[0][9]
	    = $character[1][2] = $character[1][3] = $character[1][7]
	    = $character[1][8] = $character[2][3] = $character[2][4]
	    = $character[2][6] = $character[2][7] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[4][4]
	    = $character[4][5] = $character[4][6] = $character[5][4]
	    = $character[5][5] = $character[5][6] = $character[6][4]
	    = $character[6][5] = $character[6][6] = $character[7][4]
	    = $character[7][5] = $character[7][6] = "8";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(13);
	$character[1][6] = $character[2][5] = $character[3][4] = $character[4][3]
	    = $character[5][2] = $character[6][1] = $character[7][0] = "d";
	$character[0][11] = $character[1][4] = $character[1][11]
	    = $character[2][3] = $character[2][10] = $character[3][2]
	    = $character[3][9] = $character[4][1]  = $character[4][9]
	    = $character[5][0] = $character[5][9]  = $character[6][0]
	    = $character[6][9] = $character[7][11] = "\$";
	$character[0][10] = $character[1][9] = $character[2][8]
	    = $character[3][7] = $character[4][6] = $character[5][5]
	    = $character[6][4] = "P";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4]  = $character[0][5] = $character[0][6]
	    = $character[0][7]  = $character[0][8] = $character[0][9]
	    = $character[1][7]  = $character[1][8] = $character[2][6]
	    = $character[2][7]  = $character[3][5] = $character[3][6]
	    = $character[4][4]  = $character[4][5] = $character[5][3]
	    = $character[5][4]  = $character[6][2] = $character[6][3]
	    = $character[7][1]  = $character[7][2] = $character[7][3]
	    = $character[7][4]  = $character[7][5] = $character[7][6]
	    = $character[7][7]  = $character[7][8] = $character[7][9]
	    = $character[7][10] = "8";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(10);
	$character[3][6] = $character[5][0] = "\.";
	$character[5][1] = "d";
	$character[7][1] = "Y";
	$character[3][5] = $character[4][7] = "b";
	$character[3][0] = $character[3][8] = $character[4][0] = $character[4][8]
	    = $character[5][8] = $character[6][8] = $character[7][8] = "\$";
	$character[4][4] = $character[7][0] = "\"";
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[4][5] = $character[4][6] = $character[5][2]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = $character[5][7] = $character[6][0]
	    = $character[6][1] = $character[6][2] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[7][2]
	    = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6] = $character[7][7] = "8";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(10);
	$character[3][6] = "\.";
	$character[6][7] = $character[7][5] = "P";
	$character[0][4] = $character[1][4] = $character[2][4] = $character[3][7]
	    = $character[4][8] = $character[5][8] = $character[6][8]
	    = $character[7][7] = "\$";
	$character[3][5] = $character[4][7] = "b";
	$character[6][4] = "d";
	$character[4][4] = $character[7][6] = "\"";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[1][1] = $character[1][2] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][5] = $character[4][6]
	    = $character[5][0] = $character[5][1] = $character[5][2]
	    = $character[5][5] = $character[5][6] = $character[5][7]
	    = $character[6][0] = $character[6][1] = $character[6][2]
	    = $character[6][5] = $character[6][6] = $character[7][0]
	    = $character[7][1] = $character[7][2] = $character[7][3]
	    = $character[7][4] = "8";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(10);
	$character[3][3] = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[4][1] = $character[4][2] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[6][1]
	    = $character[6][2] = $character[7][3] = $character[7][4]
	    = $character[7][5] = $character[7][6] = "8";
	$character[4][4] = $character[7][1] = "\"";
	$character[3][2] = $character[4][0] = "d";
	$character[6][0] = $character[7][2] = "Y";
	$character[3][7] = $character[6][3] = "b";
	$character[4][3] = $character[7][7] = "P";
	$character[3][0] = $character[3][8] = $character[4][7] = $character[5][7]
	    = $character[6][7] = $character[7][0] = $character[7][8] = "\$";
	$character[3][1] = $character[6][4] = "\.";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(10);
	$character[6][3] = "b";
	$character[0][8] = $character[1][8] = $character[2][8] = $character[3][0]
	    = $character[3][8] = $character[4][8] = $character[5][8]
	    = $character[6][8] = $character[7][0] = $character[7][8] = "\$";
	$character[3][2] = $character[4][0] = "d";
	$character[6][0] = $character[7][2] = "Y";
	$character[3][1] = "\.";
	$character[0][5] = $character[0][6] = $character[0][7] = $character[1][5]
	    = $character[1][6] = $character[1][7] = $character[2][5]
	    = $character[2][6] = $character[2][7] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[3][7] = $character[4][1] = $character[4][2]
	    = $character[4][5] = $character[4][6] = $character[4][7]
	    = $character[5][0] = $character[5][1] = $character[5][2]
	    = $character[5][5] = $character[5][6] = $character[5][7]
	    = $character[6][1] = $character[6][2] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[7][3]
	    = $character[7][4] = $character[7][5] = $character[7][6]
	    = $character[7][7] = "8";
	$character[4][3] = $character[7][1] = "\"";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(10);
	$character[3][1] = $character[3][6] = $character[6][3] = "\.";
	$character[4][5] = $character[6][0] = $character[7][2] = "Y";
	$character[3][2] = $character[4][0] = "d";
	$character[4][2] = "P";
	$character[3][0] = $character[3][7] = $character[4][8] = $character[5][8]
	    = $character[6][4] = $character[7][0] = $character[7][7] = "\$";
	$character[3][5] = $character[4][7] = $character[6][2] = "b";
	$character[3][3] = $character[3][4] = $character[4][1] = $character[4][6]
	    = $character[5][0] = $character[5][1] = $character[5][2]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = $character[5][7] = $character[6][1]
	    = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6] = "8";
	$character[7][1] = "\"";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(8);
	$character[1][4] = "\"";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[1][1]
	    = $character[1][2] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[3][0] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[5][0] = $character[5][1]
	    = $character[5][2] = $character[6][0] = $character[6][1]
	    = $character[6][2] = $character[7][0] = $character[7][1]
	    = $character[7][2] = "8";
	$character[1][3] = "P";
	$character[0][0] = $character[0][6] = $character[1][5] = $character[2][4]
	    = $character[3][6] = $character[4][4] = $character[5][4]
	    = $character[6][4] = $character[7][4] = "\$";
	$character[0][2] = $character[1][0] = "d";
	$character[0][1] = "\.";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(10);
	$character[3][5] = $character[4][7] = $character[6][3] = $character[9][2]
	    = "b";
	$character[4][3] = $character[9][7] = $character[10][5] = "P";
	$character[3][0] = $character[3][7] = $character[4][8]  = $character[5][8]
	    = $character[6][8]  = $character[7][0] = $character[7][8]
	    = $character[8][0]  = $character[8][8] = $character[9][8]
	    = $character[10][7] = "\$";
	$character[3][2] = $character[4][0] = $character[9][4] = "d";
	$character[6][0] = $character[7][2] = $character[9][0]
	    = $character[10][2] = "Y";
	$character[3][1] = $character[3][6] = "\.";
	$character[4][4] = $character[7][1] = $character[10][1]
	    = $character[10][6] = "\"";
	$character[3][3] = $character[3][4] = $character[4][1] = $character[4][2]
	    = $character[4][5]  = $character[4][6]  = $character[5][0]
	    = $character[5][1]  = $character[5][2]  = $character[5][5]
	    = $character[5][6]  = $character[5][7]  = $character[6][1]
	    = $character[6][2]  = $character[6][5]  = $character[6][6]
	    = $character[6][7]  = $character[7][3]  = $character[7][4]
	    = $character[7][5]  = $character[7][6]  = $character[7][7]
	    = $character[8][5]  = $character[8][6]  = $character[8][7]
	    = $character[9][1]  = $character[9][5]  = $character[9][6]
	    = $character[10][3] = $character[10][4] = "8";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(10);
	$character[3][6] = "\.";
	$character[3][5] = $character[4][7] = "b";
	$character[0][4] = $character[1][4] = $character[2][4] = $character[3][7]
	    = $character[4][8] = $character[5][8] = $character[6][8]
	    = $character[7][8] = "\$";
	$character[4][4] = "\"";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[1][1] = $character[1][2] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][5] = $character[4][6]
	    = $character[5][0] = $character[5][1] = $character[5][2]
	    = $character[5][5] = $character[5][6] = $character[5][7]
	    = $character[6][0] = $character[6][1] = $character[6][2]
	    = $character[6][5] = $character[6][6] = $character[6][7]
	    = $character[7][0] = $character[7][1] = $character[7][2]
	    = $character[7][5] = $character[7][6] = $character[7][7] = "8";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(5);
	$character[0][2] = "b";
	$character[1][2] = "P";
	$character[0][3] = $character[1][3] = $character[2][0] = $character[2][3]
	    = $character[3][3] = $character[4][3] = $character[5][3]
	    = $character[6][3] = $character[7][3] = "\$";
	$character[0][0] = "d";
	$character[1][0] = "Y";
	$character[0][1] = $character[1][1] = $character[3][0] = $character[3][1]
	    = $character[3][2] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[5][0] = $character[5][1]
	    = $character[5][2] = $character[6][0] = $character[6][1]
	    = $character[6][2] = $character[7][0] = $character[7][1]
	    = $character[7][2] = "8";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(8);
	$character[1][5] = $character[9][5] = $character[10][3] = "P";
	$character[0][2] = $character[0][6] = $character[1][2]  = $character[1][6]
	    = $character[2][1] = $character[2][6]  = $character[3][1]
	    = $character[3][6] = $character[4][1]  = $character[4][6]
	    = $character[5][1] = $character[5][6]  = $character[6][1]
	    = $character[6][6] = $character[7][1]  = $character[7][6]
	    = $character[8][1] = $character[8][6]  = $character[9][0]
	    = $character[9][6] = $character[10][5] = "\$";
	$character[0][5] = "b";
	$character[1][3] = "Y";
	$character[0][3] = $character[9][2]  = "d";
	$character[4][2] = $character[10][4] = "\"";
	$character[0][4] = $character[1][4]  = $character[3][2] = $character[3][3]
	    = $character[3][4]  = $character[3][5]  = $character[4][3]
	    = $character[4][4]  = $character[4][5]  = $character[5][3]
	    = $character[5][4]  = $character[5][5]  = $character[6][3]
	    = $character[6][4]  = $character[6][5]  = $character[7][3]
	    = $character[7][4]  = $character[7][5]  = $character[8][3]
	    = $character[8][4]  = $character[8][5]  = $character[9][3]
	    = $character[9][4]  = $character[10][0] = $character[10][1]
	    = $character[10][2] = "8";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(10);
	$character[6][7] = "b";
	$character[4][7] = "P";
	$character[0][4] = $character[1][4] = $character[2][4] = $character[3][8]
	    = $character[4][8] = $character[5][7] = $character[6][8]
	    = $character[7][8] = "\$";
	$character[4][4] = "\.";
	$character[5][6] = "K";
	$character[6][4] = "\"";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[1][1] = $character[1][2] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][5]
	    = $character[3][6] = $character[3][7] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[4][5]
	    = $character[4][6] = $character[5][0] = $character[5][1]
	    = $character[5][2] = $character[5][3] = $character[5][4]
	    = $character[5][5] = $character[6][0] = $character[6][1]
	    = $character[6][2] = $character[6][5] = $character[6][6]
	    = $character[7][0] = $character[7][1] = $character[7][2]
	    = $character[7][5] = $character[7][6] = $character[7][7] = "8";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[1][1] = $character[1][2] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[6][0]
	    = $character[6][1] = $character[6][2] = $character[7][0]
	    = $character[7][1] = $character[7][2] = "8";
	$character[0][3] = $character[1][3] = $character[2][3] = $character[3][3]
	    = $character[4][3] = $character[5][3] = $character[6][3]
	    = $character[7][3] = "\$";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(15);
	$character[3][0] = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4]  = $character[3][8]  = $character[3][9]
	    = $character[4][0]  = $character[4][1]  = $character[4][2]
	    = $character[4][5]  = $character[4][6]  = $character[4][7]
	    = $character[4][10] = $character[4][11] = $character[5][0]
	    = $character[5][1]  = $character[5][2]  = $character[5][5]
	    = $character[5][6]  = $character[5][7]  = $character[5][10]
	    = $character[5][11] = $character[5][12] = $character[6][0]
	    = $character[6][1]  = $character[6][2]  = $character[6][5]
	    = $character[6][6]  = $character[6][7]  = $character[6][10]
	    = $character[6][11] = $character[6][12] = $character[7][0]
	    = $character[7][1]  = $character[7][2]  = $character[7][5]
	    = $character[7][6]  = $character[7][7]  = $character[7][10]
	    = $character[7][11] = $character[7][12] = "8";
	$character[4][4]  = $character[4][9] = "\"";
	$character[3][7]  = "d";
	$character[3][12] = $character[4][13] = $character[5][13]
	    = $character[6][13] = $character[7][13] = "\$";
	$character[3][5] = $character[3][10] = $character[4][12] = "b";
	$character[3][6] = $character[3][11] = "\.";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(10);
	$character[3][6] = "\.";
	$character[3][5] = $character[4][7] = "b";
	$character[3][7] = $character[4][8] = $character[5][8] = $character[6][8]
	    = $character[7][8] = "\$";
	$character[4][4] = "\"";
	$character[3][0] = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][5] = $character[4][6]
	    = $character[5][0] = $character[5][1] = $character[5][2]
	    = $character[5][5] = $character[5][6] = $character[5][7]
	    = $character[6][0] = $character[6][1] = $character[6][2]
	    = $character[6][5] = $character[6][6] = $character[6][7]
	    = $character[7][0] = $character[7][1] = $character[7][2]
	    = $character[7][5] = $character[7][6] = $character[7][7] = "8";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(10);
	$character[6][0] = $character[7][2] = "Y";
	$character[3][2] = $character[4][0] = "d";
	$character[3][0] = $character[3][7] = $character[4][8] = $character[5][8]
	    = $character[6][8] = $character[7][0] = $character[7][7] = "\$";
	$character[6][7] = $character[7][5] = "P";
	$character[3][5] = $character[4][7] = "b";
	$character[3][1] = $character[3][6] = $character[6][3] = $character[6][4]
	    = "\.";
	$character[3][3] = $character[3][4] = $character[4][1] = $character[4][2]
	    = $character[4][5] = $character[4][6] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[5][5]
	    = $character[5][6] = $character[5][7] = $character[6][1]
	    = $character[6][2] = $character[6][5] = $character[6][6]
	    = $character[7][3] = $character[7][4] = "8";
	$character[4][3] = $character[4][4] = $character[7][1] = $character[7][6]
	    = "\"";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(10);
	$character[6][4] = "d";
	$character[3][5] = $character[4][7] = "b";
	$character[3][7] = $character[4][8] = $character[5][8] = $character[6][8]
	    = $character[7][7]  = $character[8][4] = $character[9][4]
	    = $character[10][4] = "\$";
	$character[6][7] = $character[7][5] = "P";
	$character[3][6] = "\.";
	$character[3][0] = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4]  = $character[4][0]  = $character[4][1]
	    = $character[4][2]  = $character[4][5]  = $character[4][6]
	    = $character[5][0]  = $character[5][1]  = $character[5][2]
	    = $character[5][5]  = $character[5][6]  = $character[5][7]
	    = $character[6][0]  = $character[6][1]  = $character[6][2]
	    = $character[6][5]  = $character[6][6]  = $character[7][0]
	    = $character[7][1]  = $character[7][2]  = $character[7][3]
	    = $character[7][4]  = $character[8][0]  = $character[8][1]
	    = $character[8][2]  = $character[9][0]  = $character[9][1]
	    = $character[9][2]  = $character[10][0] = $character[10][1]
	    = $character[10][2] = "8";
	$character[4][4] = $character[7][6] = "\"";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(10);
	$character[6][0] = $character[7][2] = "Y";
	$character[3][2] = $character[4][0] = "d";
	$character[3][0] = $character[3][8] = $character[4][8] = $character[5][8]
	    = $character[6][8] = $character[7][0]  = $character[7][8]
	    = $character[8][3] = $character[8][8]  = $character[9][3]
	    = $character[9][8] = $character[10][3] = $character[10][8] = "\$";
	$character[6][3] = "b";
	$character[3][1] = "\.";
	$character[4][3] = $character[7][1] = "\"";
	$character[3][3] = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[3][7]  = $character[4][1]  = $character[4][2]
	    = $character[4][5]  = $character[4][6]  = $character[4][7]
	    = $character[5][0]  = $character[5][1]  = $character[5][2]
	    = $character[5][5]  = $character[5][6]  = $character[5][7]
	    = $character[6][1]  = $character[6][2]  = $character[6][5]
	    = $character[6][6]  = $character[6][7]  = $character[7][3]
	    = $character[7][4]  = $character[7][5]  = $character[7][6]
	    = $character[7][7]  = $character[8][5]  = $character[8][6]
	    = $character[8][7]  = $character[9][5]  = $character[9][6]
	    = $character[9][7]  = $character[10][5] = $character[10][6]
	    = $character[10][7] = "8";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(9);
	$character[3][3] = "d";
	$character[4][3] = "P";
	$character[3][7] = $character[4][5] = $character[5][4] = $character[6][4]
	    = $character[7][4] = "\$";
	$character[3][0] = $character[3][1] = $character[3][2] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[6][0]
	    = $character[6][1] = $character[6][2] = $character[7][0]
	    = $character[7][1] = $character[7][2] = "8";
	$character[4][4] = "\"";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(10);
	$character[4][2] = "K";
	$character[5][0] = "\"";
	$character[3][2] = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[4][0] = $character[4][1] = $character[5][2]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[6][6] = $character[6][7] = $character[7][1]
	    = $character[7][2] = $character[7][3] = $character[7][4]
	    = $character[7][5] = "8";
	$character[7][7] = "\'";
	$character[6][5] = "X";
	$character[3][0] = $character[5][7] = "\.";
	$character[5][1] = "Y";
	$character[3][1] = "d";
	$character[7][6] = "P";
	$character[3][7] = $character[4][6] = $character[5][8] = $character[6][0]
	    = $character[6][8] = $character[7][0] = $character[7][8] = "\$";
	$character[3][6] = $character[5][6] = "b";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(8);
	$character[7][1] = "\"";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[1][1] = $character[1][2] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[6][1]
	    = $character[6][2] = $character[7][3] = $character[7][4]
	    = $character[7][5] = "8";
	$character[6][4] = "\.";
	$character[6][3] = "b";
	$character[0][4] = $character[1][4] = $character[2][4] = $character[3][6]
	    = $character[4][4] = $character[5][4] = $character[6][5]
	    = $character[7][6] = "\$";
	$character[6][0] = $character[7][2] = "Y";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(10);
	$character[7][1] = "\"";
	$character[3][0] = $character[3][1] = $character[3][2] = $character[3][5]
	    = $character[3][6] = $character[3][7] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[4][5]
	    = $character[4][6] = $character[4][7] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[5][5]
	    = $character[5][6] = $character[5][7] = $character[6][1]
	    = $character[6][2] = $character[6][5] = $character[6][6]
	    = $character[6][7] = $character[7][3] = $character[7][4]
	    = $character[7][5] = $character[7][6] = $character[7][7] = "8";
	$character[6][3] = "b";
	$character[3][8] = $character[4][8] = $character[5][8] = $character[6][8]
	    = $character[7][0] = $character[7][8] = "\$";
	$character[6][0] = $character[7][2] = "Y";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(10);
	$character[3][0] = $character[3][1] = $character[3][2] = $character[3][5]
	    = $character[3][6] = $character[3][7] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[4][5]
	    = $character[4][6] = $character[4][7] = $character[5][1]
	    = $character[5][2] = $character[5][5] = $character[5][6]
	    = $character[6][2] = $character[6][5] = $character[7][3]
	    = $character[7][4] = "8";
	$character[6][4] = "d";
	$character[5][0] = $character[6][1] = $character[7][2] = "Y";
	$character[6][3] = "b";
	$character[3][8] = $character[4][8] = $character[5][8] = $character[6][0]
	    = $character[6][7] = $character[7][0] = $character[7][7] = "\$";
	$character[5][7] = $character[6][6] = $character[7][5] = "P";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(15);
	$character[7][1] = $character[7][11] = "\"";
	$character[3][0] = $character[3][1]  = $character[3][2] = $character[3][5]
	    = $character[3][6]  = $character[3][7]  = $character[3][10]
	    = $character[3][11] = $character[3][12] = $character[4][0]
	    = $character[4][1]  = $character[4][2]  = $character[4][5]
	    = $character[4][6]  = $character[4][7]  = $character[4][10]
	    = $character[4][11] = $character[4][12] = $character[5][0]
	    = $character[5][1]  = $character[5][2]  = $character[5][5]
	    = $character[5][6]  = $character[5][7]  = $character[5][10]
	    = $character[5][11] = $character[5][12] = $character[6][1]
	    = $character[6][2]  = $character[6][5]  = $character[6][6]
	    = $character[6][7]  = $character[6][10] = $character[6][11]
	    = $character[7][3]  = $character[7][4]  = $character[7][5]
	    = $character[7][6]  = $character[7][7]  = $character[7][8]
	    = $character[7][9]  = "8";
	$character[6][3]  = "b";
	$character[3][13] = $character[4][13] = $character[5][13]
	    = $character[6][13] = $character[7][0] = $character[7][12] = "\$";
	$character[6][12] = $character[7][10] = "P";
	$character[6][9]  = "d";
	$character[6][0]  = $character[7][2] = "Y";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(10);
	$character[6][3] = $character[6][4] = "\"";
	$character[5][2] = "X";
	$character[3][8] = $character[4][8] = $character[5][0] = $character[5][7]
	    = $character[6][8] = $character[7][8] = "\$";
	$character[4][6] = "P";
	$character[4][3] = $character[6][6] = "b";
	$character[4][1] = "Y";
	$character[4][4] = $character[6][1] = "d";
	$character[3][0] = $character[3][1] = $character[3][2] = $character[3][5]
	    = $character[3][6] = $character[3][7] = $character[4][2]
	    = $character[4][5] = $character[5][3] = $character[5][4]
	    = $character[6][2] = $character[6][5] = $character[7][0]
	    = $character[7][1] = $character[7][2] = $character[7][5]
	    = $character[7][6] = $character[7][7] = "8";
	$character[5][5] = "K";
	$character[4][7] = "\'";
	$character[4][0] = "\`";
	$character[6][0] = $character[6][7] = "\.";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(10);
	$character[6][0] = $character[7][2] = $character[9][0]
	    = $character[10][2] = "Y";
	$character[9][4] = "d";
	$character[3][8] = $character[4][8] = $character[5][8] = $character[6][8]
	    = $character[7][0]  = $character[7][8] = $character[8][0]
	    = $character[8][8]  = $character[9][8] = $character[10][0]
	    = $character[10][7] = "\$";
	$character[9][7] = $character[10][5] = "P";
	$character[6][3] = $character[9][2]  = "b";
	$character[7][1] = $character[10][1] = $character[10][6] = "\"";
	$character[3][0] = $character[3][1]  = $character[3][2] = $character[3][5]
	    = $character[3][6]  = $character[3][7]  = $character[4][0]
	    = $character[4][1]  = $character[4][2]  = $character[4][5]
	    = $character[4][6]  = $character[4][7]  = $character[5][0]
	    = $character[5][1]  = $character[5][2]  = $character[5][5]
	    = $character[5][6]  = $character[5][7]  = $character[6][1]
	    = $character[6][2]  = $character[6][5]  = $character[6][6]
	    = $character[6][7]  = $character[7][3]  = $character[7][4]
	    = $character[7][5]  = $character[7][6]  = $character[7][7]
	    = $character[8][5]  = $character[8][6]  = $character[8][7]
	    = $character[9][1]  = $character[9][5]  = $character[9][6]
	    = $character[10][3] = $character[10][4] = "8";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(10);
	$character[4][6] = $character[5][5] = $character[6][4] = "P";
	$character[3][8] = $character[4][1] = $character[4][8] = $character[5][0]
	    = $character[5][7] = $character[6][0] = $character[6][6]
	    = $character[7][8] = "\$";
	$character[4][3] = $character[5][2] = $character[6][1] = "d";
	$character[3][0] = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[3][7] = $character[4][4] = $character[4][5]
	    = $character[5][3] = $character[5][4] = $character[6][2]
	    = $character[6][3] = $character[7][0] = $character[7][1]
	    = $character[7][2] = $character[7][3] = $character[7][4]
	    = $character[7][5] = $character[7][6] = $character[7][7] = "8";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(12);
	$character[1][6] = $character[6][0] = $character[7][2] = "Y";
	$character[0][2] = $character[1][0] = $character[6][6] = "d";
	$character[1][3] = $character[6][9] = $character[7][7] = "P";
	$character[0][0] = $character[0][9] = $character[1][10]
	    = $character[2][10] = $character[3][10] = $character[4][10]
	    = $character[5][10] = $character[6][10] = $character[7][0]
	    = $character[7][9]  = "\$";
	$character[0][7] = $character[1][9] = $character[6][3] = "b";
	$character[7][1] = $character[7][8] = "\"";
	$character[0][1] = $character[0][8] = "\.";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][1] = $character[1][2] = $character[1][7]
	    = $character[1][8] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][7] = $character[2][8]
	    = $character[2][9] = $character[3][0] = $character[3][1]
	    = $character[3][2] = $character[3][7] = $character[3][8]
	    = $character[3][9] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][7] = $character[4][8]
	    = $character[4][9] = $character[5][0] = $character[5][1]
	    = $character[5][2] = $character[5][7] = $character[5][8]
	    = $character[5][9] = $character[6][1] = $character[6][2]
	    = $character[6][7] = $character[6][8] = $character[7][3]
	    = $character[7][4] = $character[7][5] = $character[7][6] = "8";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(9);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[1][1]
	    = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[5][2] = $character[5][3] = $character[5][4]
	    = $character[6][2] = $character[6][3] = $character[6][4]
	    = $character[7][0] = $character[7][1] = $character[7][2]
	    = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6] = "8";
	$character[0][1] = $character[1][0] = "d";
	$character[0][6] = $character[1][6] = $character[2][6] = $character[3][6]
	    = $character[4][6] = $character[5][6] = $character[6][6]
	    = $character[7][7] = "\$";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(12);
	$character[4][8] = $character[5][4] = $character[6][3] = "\"";
	$character[4][2] = "o";
	$character[0][9] = $character[1][10] = $character[2][1]
	    = $character[2][10] = $character[3][1] = $character[3][10]
	    = $character[4][10] = $character[5][10] = $character[6][10]
	    = $character[7][10] = "\$";
	$character[1][3] = $character[3][9] = $character[4][7] = $character[5][3]
	    = "P";
	$character[0][7] = $character[1][9] = "b";
	$character[1][6] = "Y";
	$character[0][2] = $character[1][0] = $character[3][6] = $character[4][3]
	    = $character[5][0] = "d";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][1] = $character[1][2] = $character[1][7]
	    = $character[1][8] = $character[2][7] = $character[2][8]
	    = $character[2][9] = $character[3][7] = $character[3][8]
	    = $character[4][4] = $character[4][5] = $character[4][6]
	    = $character[5][1] = $character[5][2] = $character[6][0]
	    = $character[6][1] = $character[6][2] = $character[7][0]
	    = $character[7][1] = $character[7][2] = $character[7][3]
	    = $character[7][4] = $character[7][5] = $character[7][6]
	    = $character[7][7] = $character[7][8] = "8";
	$character[0][1] = $character[0][8] = $character[3][5] = $character[4][1]
	    = "\.";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(12);
	$character[0][1] = $character[0][8] = $character[2][5] = $character[4][9]
	    = "\.";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][1] = $character[1][2] = $character[1][7]
	    = $character[1][8] = $character[2][7] = $character[2][8]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[3][7] = $character[4][7] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[5][7]
	    = $character[5][8] = $character[5][9] = $character[6][1]
	    = $character[6][2] = $character[6][7] = $character[6][8]
	    = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6] = "8";
	$character[0][2] = $character[1][0] = $character[2][6] = $character[6][6]
	    = "d";
	$character[1][6] = $character[4][6] = $character[6][0] = $character[7][2]
	    = "Y";
	$character[0][7] = $character[1][9] = $character[4][8] = $character[6][3]
	    = "b";
	$character[1][3] = $character[2][9] = $character[6][9] = $character[7][7]
	    = "P";
	$character[0][9] = $character[1][10] = $character[2][1]
	    = $character[2][10] = $character[3][1]  = $character[3][10]
	    = $character[4][1]  = $character[4][10] = $character[5][10]
	    = $character[6][10] = $character[7][10] = "\$";
	$character[3][8] = $character[4][5] = $character[7][1] = $character[7][8]
	    = "\"";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(12);
	$character[0][5] = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][4] = $character[1][6] = $character[1][7]
	    = $character[1][8] = $character[2][3] = $character[2][6]
	    = $character[2][7] = $character[2][8] = $character[3][2]
	    = $character[3][6] = $character[3][7] = $character[3][8]
	    = $character[4][1] = $character[4][2] = $character[4][6]
	    = $character[4][7] = $character[4][8] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = $character[5][6]
	    = $character[5][7] = $character[5][8] = $character[5][9]
	    = $character[6][6] = $character[6][7] = $character[6][8]
	    = $character[7][6] = $character[7][7] = $character[7][8] = "8";
	$character[1][5]  = $character[2][4]  = $character[3][3] = "P";
	$character[0][10] = $character[1][10] = $character[2][10]
	    = $character[3][10] = $character[4][10] = $character[5][10]
	    = $character[6][10] = $character[7][10] = "\$";
	$character[0][4] = $character[1][3] = $character[2][2] = $character[3][1]
	    = $character[4][0] = "d";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(12);
	$character[6][9] = $character[7][7] = "P";
	$character[0][9] = $character[1][9] = $character[2][9] = $character[3][9]
	    = $character[4][0] = $character[4][10] = $character[5][0]
	    = $character[5][10] = $character[6][10] = $character[7][9] = "\$";
	$character[3][7] = $character[4][9] = $character[6][3] = "b";
	$character[4][6] = $character[6][0] = $character[7][2] = "Y";
	$character[6][6] = "d";
	$character[4][5] = $character[7][1] = $character[7][8] = "\"";
	$character[3][8] = "\.";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[0][7] = $character[0][8] = $character[1][0]
	    = $character[1][1] = $character[1][2] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[4][7] = $character[4][8] = $character[5][7]
	    = $character[5][8] = $character[5][9] = $character[6][1]
	    = $character[6][2] = $character[6][7] = $character[6][8]
	    = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6] = "8";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(12);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][1] = $character[1][2] = $character[1][7]
	    = $character[1][8] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[3][0] = $character[3][1]
	    = $character[3][2] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][7] = $character[4][8]
	    = $character[5][0] = $character[5][1] = $character[5][2]
	    = $character[5][7] = $character[5][8] = $character[5][9]
	    = $character[6][1] = $character[6][2] = $character[6][7]
	    = $character[6][8] = $character[7][3] = $character[7][4]
	    = $character[7][5] = $character[7][6] = "8";
	$character[0][1] = $character[0][8] = $character[3][8] = "\.";
	$character[4][5] = $character[7][1] = $character[7][8] = "\"";
	$character[0][7] = $character[1][9] = $character[3][7] = $character[4][9]
	    = $character[6][3] = "b";
	$character[0][0] = $character[0][9] = $character[1][10]
	    = $character[2][9]  = $character[3][9] = $character[4][10]
	    = $character[5][10] = $character[6][10] = $character[7][0]
	    = $character[7][9]  = "\$";
	$character[1][3] = $character[4][3] = $character[6][9] = $character[7][7]
	    = "P";
	$character[0][2] = $character[1][0] = $character[3][3] = $character[6][6]
	    = "d";
	$character[1][6] = $character[4][6] = $character[6][0] = $character[7][2]
	    = "Y";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(12);
	$character[1][9] = $character[2][8] = $character[3][7] = $character[5][5]
	    = $character[6][4] = $character[7][3] = "P";
	$character[0][10] = $character[1][4] = $character[1][10]
	    = $character[2][3] = $character[2][10] = $character[3][2]
	    = $character[3][9] = $character[4][0]  = $character[4][9]
	    = $character[5][0] = $character[5][7]  = $character[6][0]
	    = $character[6][6] = $character[7][5]  = "\$";
	$character[1][6] = $character[2][5] = $character[3][4] = $character[5][2]
	    = $character[6][1] = $character[7][0] = "d";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[0][7] = $character[0][8] = $character[0][9]
	    = $character[1][7] = $character[1][8] = $character[2][6]
	    = $character[2][7] = $character[3][5] = $character[3][6]
	    = $character[4][1] = $character[4][2] = $character[4][3]
	    = $character[4][4] = $character[4][5] = $character[4][6]
	    = $character[4][7] = $character[4][8] = $character[5][3]
	    = $character[5][4] = $character[6][2] = $character[6][3]
	    = $character[7][1] = $character[7][2] = "8";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(12);
	$character[3][1] = $character[3][8] = $character[4][4] = $character[4][5]
	    = $character[7][1] = $character[7][8] = "\"";
	$character[0][2] = $character[1][0] = $character[2][6] = $character[4][1]
	    = $character[6][6] = "d";
	$character[1][6] = $character[2][0] = $character[3][2] = $character[4][6]
	    = $character[6][0] = $character[7][2] = "Y";
	$character[0][7] = $character[1][9] = $character[2][3] = $character[4][8]
	    = $character[6][3] = "b";
	$character[0][9] = $character[1][10] = $character[2][10]
	    = $character[3][10] = $character[4][10] = $character[5][10]
	    = $character[6][10] = $character[7][10] = "\$";
	$character[1][3] = $character[2][9] = $character[4][3] = $character[6][9]
	    = $character[7][7] = "P";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][1] = $character[1][2] = $character[1][7]
	    = $character[1][8] = $character[2][1] = $character[2][2]
	    = $character[2][7] = $character[2][8] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[3][7] = $character[4][2] = $character[4][7]
	    = $character[5][0] = $character[5][1] = $character[5][2]
	    = $character[5][7] = $character[5][8] = $character[5][9]
	    = $character[6][1] = $character[6][2] = $character[6][7]
	    = $character[6][8] = $character[7][3] = $character[7][4]
	    = $character[7][5] = $character[7][6] = "8";
	$character[0][1] = $character[0][8] = $character[2][4] = $character[4][0]
	    = $character[4][9] = "\.";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(12);
	$character[1][3] = $character[4][6] = $character[6][9] = $character[7][7]
	    = "P";
	$character[0][0] = $character[0][9] = $character[1][10]
	    = $character[2][10] = $character[3][10] = $character[4][0]
	    = $character[4][10] = $character[5][0]  = $character[5][10]
	    = $character[6][10] = $character[7][9]  = "\$";
	$character[0][7] = $character[1][9] = $character[3][3] = $character[6][3]
	    = "b";
	$character[1][6] = $character[3][0] = $character[4][2] = $character[6][0]
	    = $character[7][2] = "Y";
	$character[0][2] = $character[1][0] = $character[3][6] = $character[6][6]
	    = "d";
	$character[4][1] = $character[7][1] = $character[7][8] = "\"";
	$character[0][1] = $character[0][8] = $character[3][4] = "\.";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][1] = $character[1][2] = $character[1][7]
	    = $character[1][8] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][7] = $character[2][8]
	    = $character[2][9] = $character[3][1] = $character[3][2]
	    = $character[3][7] = $character[3][8] = $character[3][9]
	    = $character[4][3] = $character[4][4] = $character[4][5]
	    = $character[4][7] = $character[4][8] = $character[4][9]
	    = $character[5][7] = $character[5][8] = $character[5][9]
	    = $character[6][1] = $character[6][2] = $character[6][7]
	    = $character[6][8] = $character[7][3] = $character[7][4]
	    = $character[7][5] = $character[7][6] = "8";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Colossal - Colossal font 

=head1 VERSION

Version 0.17

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	use Ascii::Text::Font::Colossal;

	my $foo = Ascii::Text::Font::Colossal->new();

	...

=head1 SUBROUTINES/METHODS

=head2 character_A

	      $d8888$
	     $d88888$
	    $d88P888$
	   $d88P 888$
	  $d88P  888$
	 $d88P   888$
	$d8888888888$
	d88P     888$
	             
	             
	             

=head2 character_B

	888888b.$  
	888  "88b$ 
	888  .88P$ 
	8888888K.$ 
	888  "Y88b$
	888    888$
	888   d88P$
	8888888P"$ 
	           
	           
	           

=head2 character_C

	$.d8888b.$ 
	d88P  Y88b$
	888    888$
	888      $ 
	888      $ 
	888    888$
	Y88b  d88P$
	$"Y8888P"$ 
	           
	           
	           

=head2 character_D

	8888888b.$ 
	888  "Y88b$
	888    888$
	888    888$
	888    888$
	888    888$
	888  .d88P$
	8888888P"$ 
	           
	           
	           

=head2 character_E

	8888888888$
	888    $   
	888    $   
	8888888$   
	888    $   
	888    $   
	888    $   
	8888888888$
	           
	           
	           

=head2 character_F

	8888888888$
	888    $   
	888    $   
	8888888$   
	888    $   
	888    $   
	888    $   
	888    $   
	           
	           
	           

=head2 character_G

	$.d8888b.$ 
	d88P  Y88b$
	888    888$
	888       $
	888  88888$
	888    888$
	Y88b  d88P$
	$"Y8888P88$
	           
	           
	           

=head2 character_H

	888    888$
	888    888$
	888    888$
	8888888888$
	888    888$
	888    888$
	888    888$
	888    888$
	           
	           
	           

=head2 character_I

	8888888$
	  888 $ 
	  888 $ 
	  888 $ 
	  888 $ 
	  888 $ 
	  888 $ 
	8888888$
	        
	        
	        

=head2 character_J

	  888888$
	    "88b$
	     888$
	     888$
	     888$
	     888$
	     88P$
	     888$
	   .d88P$
	 .d88P"$ 
	888P" $  

=head2 character_K

	888    d8P$ 
	888   d8P $ 
	888  d8P $  
	888d88K $   
	8888888b $  
	888  Y88b $ 
	888   Y88b $
	888    Y88b$
	            
	            
	            

=head2 character_L

	888   $  
	888   $  
	888   $  
	888   $  
	888   $  
	888   $  
	888   $  
	88888888$
	         
	         
	         

=head2 character_M

	888b     d888$
	8888b   d8888$
	88888b.d88888$
	888Y88888P888$
	888 Y888P 888$
	888  Y8P  888$
	888   "   888$
	888       888$
	              
	              
	              

=head2 character_N

	888b    888$
	8888b   888$
	88888b  888$
	888Y88b 888$
	888 Y88b888$
	888  Y88888$
	888   Y8888$
	888    Y888$
	            
	            
	            

=head2 character_O

	$.d88888b.$ 
	d88P" "Y88b$
	888     888$
	888     888$
	888     888$
	888     888$
	Y88b. .d88P$
	$"Y88888P"$ 
	            
	            
	            

=head2 character_P

	8888888b.$ 
	888   Y88b$
	888    888$
	888   d88P$
	8888888P"$ 
	888 $      
	888 $      
	888 $      
	           
	           
	           

=head2 character_Q

	$.d88888b.$ 
	d88P" "Y88b$
	888     888$
	888     888$
	888     888$
	888 Y8b 888$
	Y88b.Y8b88P$
	$"Y888888" $
	       Y8b $
	            
	            

=head2 character_R

	8888888b.$ 
	888   Y88b$
	888    888$
	888   d88P$
	8888888P"$ 
	888 T88b $ 
	888  T88b$ 
	888   T88b$
	           
	           
	           

=head2 character_S

	$.d8888b.$ 
	d88P  Y88b$
	Y88b.    $ 
	$"Y888b. $ 
	$   "Y88b.$
	$     "888$
	Y88b  d88P$
	 "Y8888P"$ 
	           
	           
	           

=head2 character_T

	88888888888$
	    888 $   
	    888 $   
	    888 $   
	    888 $   
	    888 $   
	    888 $   
	    888 $   
	            
	            
	            

=head2 character_U

	888     888$
	888     888$
	888     888$
	888     888$
	888     888$
	888     888$
	Y88b. .d88P$
	$"Y88888P"$ 
	            
	            
	            

=head2 character_V

	888     888$
	888     888$
	888     888$
	Y88b   d88P$
	 Y88b d88P $
	  Y88o88P $ 
	   Y888P $  
	    Y8P $   
	            
	            
	            

=head2 character_W

	888       888$
	888   o   888$
	888  d8b  888$
	888 d888b 888$
	888d88888b888$
	88888P Y88888$
	8888P   Y8888$
	888P     Y888$
	              
	              
	              

=head2 character_X

	Y88b   d88P$
	 Y88b d88P $
	  Y88o88P $ 
	   Y888P  $ 
	   d888b  $ 
	  d88888b $ 
	 d88P Y88b $
	d88P   Y88b$
	            
	            
	            

=head2 character_Y

	Y88b   d88P$
	 Y88b d88P $
	  Y88o88P $ 
	   Y888P $  
	    888 $   
	    888 $   
	    888 $   
	    888 $   
	            
	            
	            

=head2 character_Z

	8888888888P$
	    $ d88P $
	   $ d88P $ 
	  $ d88P $  
	 $ d88P  $  
	$ d88P   $  
	$d88P    $  
	d8888888888$
	            
	            
	            

=head2 character_a

	         
	         
	         
	$8888b. $
	$   "88b$
	.d888888$
	888  888$
	"Y888888$
	         
	         
	         

=head2 character_b

	888 $    
	888 $    
	888 $    
	88888b.$ 
	888 "88b$
	888  888$
	888 d88P$
	88888P"$ 
	         
	         
	         

=head2 character_c

	         
	         
	         
	$.d8888b$
	d88P"  $ 
	888    $ 
	Y88b.  $ 
	$"Y8888P$
	         
	         
	         

=head2 character_d

	     888$
	     888$
	     888$
	$.d88888$
	d88" 888$
	888  888$
	Y88b 888$
	$"Y88888$
	         
	         
	         

=head2 character_e

	         
	         
	         
	$.d88b.$ 
	d8P  Y8b$
	88888888$
	Y8b.$    
	$"Y8888$ 
	         
	         
	         

=head2 character_f

	$.d888$
	d88P"$ 
	888 $  
	888888$
	888 $  
	888 $  
	888 $  
	888 $  
	       
	       
	       

=head2 character_g

	         
	         
	         
	$.d88b.$ 
	d88P"88b$
	888  888$
	Y88b 888$
	$"Y88888$
	$    888$
	Y8b d88P$
	 "Y88P"$ 

=head2 character_h

	888 $    
	888 $    
	888 $    
	88888b.$ 
	888 "88b$
	888  888$
	888  888$
	888  888$
	         
	         
	         

=head2 character_i

	d8b$
	Y8P$
	$  $
	888$
	888$
	888$
	888$
	888$
	    
	    
	    

=head2 character_j

	  $d8b$
	  $Y8P$
	 $    $
	 $8888$
	 $"888$
	 $ 888$
	 $ 888$
	 $ 888$
	 $ 888$
	$ d88P$
	888P"$ 

=head2 character_k

	888 $    
	888 $    
	888 $    
	888  888$
	888 .88P$
	888888K$ 
	888 "88b$
	888  888$
	         
	         
	         

=head2 character_l

	888$
	888$
	888$
	888$
	888$
	888$
	888$
	888$
	    
	    
	    

=head2 character_m

	              
	              
	              
	88888b.d88b.$ 
	888 "888 "88b$
	888  888  888$
	888  888  888$
	888  888  888$
	              
	              
	              

=head2 character_n

	         
	         
	         
	88888b.$ 
	888 "88b$
	888  888$
	888  888$
	888  888$
	         
	         
	         

=head2 character_o

	         
	         
	         
	$.d88b.$ 
	d88""88b$
	888  888$
	Y88..88P$
	$"Y88P"$ 
	         
	         
	         

=head2 character_p

	         
	         
	         
	88888b.$ 
	888 "88b$
	888  888$
	888 d88P$
	88888P"$ 
	888 $    
	888 $    
	888 $    

=head2 character_q

	         
	         
	         
	$.d88888$
	d88" 888$
	888  888$
	Y88b 888$
	$"Y88888$
	   $ 888$
	   $ 888$
	   $ 888$

=head2 character_r

	        
	        
	        
	888d888$
	888P"$  
	888 $   
	888 $   
	888 $   
	        
	        
	        

=head2 character_s

	         
	         
	         
	.d8888b$ 
	88K   $  
	"Y8888b.$
	$    X88$
	$88888P'$
	         
	         
	         

=head2 character_t

	888 $  
	888 $  
	888 $  
	888888$
	888 $  
	888 $  
	Y88b.$ 
	 "Y888$
	       
	       
	       

=head2 character_u

	         
	         
	         
	888  888$
	888  888$
	888  888$
	Y88b 888$
	$"Y88888$
	         
	         
	         

=head2 character_v

	         
	         
	         
	888  888$
	888  888$
	Y88  88P$
	$Y8bd8P$ 
	$ Y88P $ 
	         
	         
	         

=head2 character_w

	              
	              
	              
	888  888  888$
	888  888  888$
	888  888  888$
	Y88b 888 d88P$
	$"Y8888888P"$ 
	              
	              
	              

=head2 character_x

	         
	         
	         
	888  888$
	`Y8bd8P'$
	$ X88K $ 
	.d8""8b.$
	888  888$
	         
	         
	         

=head2 character_y

	         
	         
	         
	888  888$
	888  888$
	888  888$
	Y88b 888$
	$"Y88888$
	$    888$
	Y8b d88P$
	$"Y88P"$ 

=head2 character_z

	         
	         
	         
	88888888$
	 $ d88P $
	$ d88P $ 
	$d88P $  
	88888888$
	         
	         
	         

=head2 character_0

	$.d8888b.$ 
	d88P  Y88b$
	888    888$
	888    888$
	888    888$
	888    888$
	Y88b  d88P$
	$"Y8888P"$ 
	           
	           
	           

=head2 character_1

	 d888 $ 
	d8888 $ 
	  888 $ 
	  888 $ 
	  888 $ 
	  888 $ 
	  888 $ 
	8888888$
	        
	        
	        

=head2 character_2

	 .d8888b.$ 
	d88P  Y88b$
	 $     888$
	 $   .d88P$
	 .od888P" $
	d88P"     $
	888"      $
	888888888 $
	           
	           
	           

=head2 character_3

	 .d8888b.$ 
	d88P  Y88b$
	 $   .d88P$
	 $  8888" $
	 $   "Y8b.$
	888    888$
	Y88b  d88P$
	 "Y8888P" $
	           
	           
	           

=head2 character_4

	    d8888 $
	   d8P888 $
	  d8P 888 $
	 d8P  888 $
	d88   888 $
	8888888888$
	      888 $
	      888 $
	           
	           
	           

=head2 character_5

	888888888$ 
	888      $ 
	888      $ 
	8888888b.$ 
	$    "Y88b$
	$      888$
	Y88b  d88P$
	 "Y8888P"$ 
	           
	           
	           

=head2 character_6

	$.d8888b.$ 
	d88P  Y88b$
	888      $ 
	888d888b.$ 
	888P "Y88b$
	888    888$
	Y88b  d88P$
	$"Y8888P"$ 
	           
	           
	           

=head2 character_7

	8888888888$
	    $ d88P$
	   $ d88P $
	  $ d88P $ 
	$88888888$ 
	$ d88P $   
	$d88P $    
	d88P $     
	           
	           
	           

=head2 character_8

	 .d8888b.$ 
	d88P  Y88b$
	Y88b. d88P$
	 "Y88888" $
	.d8P""Y8b.$
	888    888$
	Y88b  d88P$
	 "Y8888P" $
	           
	           
	           

=head2 character_9

	$.d8888b.$ 
	d88P  Y88b$
	888    888$
	Y88b. d888$
	$"Y888P888$
	$      888$
	Y88b  d88P$
	 "Y8888P"$ 
	           
	           
	           

=head1 EXTENDS

=head2 Ascii::Text::Font



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::colossal at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Colossal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Colossal

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Colossal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Colossal>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Colossal>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Colossal>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
