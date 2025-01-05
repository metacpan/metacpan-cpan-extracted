package Ascii::Text::Font::Letters;
use strict;
use warnings;
use Rope;
use Rope::Autoload;
our $VERSION = 0.19;

extends 'Ascii::Text::Font';

property character_height => (
	initable  => 0,
	writeable => 0,
	value     => 6
);

function space => sub {
	my (@character) = $_[0]->default_character(7);
	return \@character;
};

function character_A => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[1][1]
	    = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[2][0] = $character[2][1]
	    = $character[2][5] = $character[2][6] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[4][0] = $character[4][1] = $character[4][5]
	    = $character[4][6] = "A";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[1][0] = $character[1][1]
	    = $character[1][5] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][1]
	    = $character[3][5] = $character[3][6] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[4][3]
	    = $character[4][4] = $character[4][5] = "B";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][0] = $character[1][1]
	    = $character[1][6] = $character[2][0] = $character[2][1]
	    = $character[3][0] = $character[3][1] = $character[3][6]
	    = $character[4][1] = $character[4][2] = $character[4][3]
	    = $character[4][4] = $character[4][5] = "C";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[1][0] = $character[1][1]
	    = $character[1][4] = $character[1][5] = $character[2][0]
	    = $character[2][1] = $character[2][5] = $character[2][6]
	    = $character[3][0] = $character[3][1] = $character[3][5]
	    = $character[3][6] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = "D";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][0] = $character[1][1] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4] = $character[3][0] = $character[3][1]
	    = $character[4][0] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[4][5]
	    = $character[4][6] = "E";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][0] = $character[1][1] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[3][0] = $character[3][1] = $character[4][0]
	    = $character[4][1] = "F";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[1][1] = $character[1][2] = $character[1][5]
	    = $character[1][6] = $character[2][0] = $character[2][1]
	    = $character[3][0] = $character[3][1] = $character[3][5]
	    = $character[3][6] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[4][5]
	    = $character[4][6] = "G";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][5] = $character[0][6]
	    = $character[1][0] = $character[1][1] = $character[1][5]
	    = $character[1][6] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[2][6] = $character[3][0]
	    = $character[3][1] = $character[3][5] = $character[3][6]
	    = $character[4][0] = $character[4][1] = $character[4][5]
	    = $character[4][6] = "H";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[1][1] = $character[1][2]
	    = $character[1][3] = $character[2][1] = $character[2][2]
	    = $character[2][3] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4] = "I";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(8);
	$character[0][4] = $character[0][5] = $character[0][6] = $character[1][4]
	    = $character[1][5] = $character[1][6] = $character[2][4]
	    = $character[2][5] = $character[2][6] = $character[3][0]
	    = $character[3][1] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[4][5] = "J";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[0][4] = $character[0][5]
	    = $character[1][0] = $character[1][1] = $character[1][3]
	    = $character[1][4] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[3][0]
	    = $character[3][1] = $character[3][3] = $character[3][4]
	    = $character[4][0] = $character[4][1] = $character[4][4]
	    = $character[4][5] = "K";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[1][0] = $character[1][1]
	    = $character[2][0] = $character[2][1] = $character[3][0]
	    = $character[3][1] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = $character[4][6] = "L";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[0][1] = $character[0][6] = $character[0][7]
	    = $character[1][0] = $character[1][1] = $character[1][2]
	    = $character[1][5] = $character[1][6] = $character[1][7]
	    = $character[2][0] = $character[2][1] = $character[2][3]
	    = $character[2][4] = $character[2][6] = $character[2][7]
	    = $character[3][0] = $character[3][1] = $character[3][6]
	    = $character[3][7] = $character[4][0] = $character[4][1]
	    = $character[4][6] = $character[4][7] = "M";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][5] = $character[0][6]
	    = $character[1][0] = $character[1][1] = $character[1][2]
	    = $character[1][5] = $character[1][6] = $character[2][0]
	    = $character[2][1] = $character[2][3] = $character[2][5]
	    = $character[2][6] = $character[3][0] = $character[3][1]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[4][0] = $character[4][1] = $character[4][5]
	    = $character[4][6] = "N";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][0] = $character[1][1]
	    = $character[1][5] = $character[1][6] = $character[2][0]
	    = $character[2][1] = $character[2][5] = $character[2][6]
	    = $character[3][0] = $character[3][1] = $character[3][5]
	    = $character[3][6] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][4] = "O";
	$character[4][5] = "0";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[1][0]
	    = $character[1][1] = $character[1][5] = $character[1][6]
	    = $character[2][0] = $character[2][1] = $character[2][2]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][0] = $character[3][1] = $character[4][0]
	    = $character[4][1] = "P";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][0] = $character[1][1]
	    = $character[1][5] = $character[1][6] = $character[2][0]
	    = $character[2][1] = $character[2][5] = $character[2][6]
	    = $character[3][0] = $character[3][1] = $character[3][4]
	    = $character[3][5] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[4][6] = "Q";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[1][0]
	    = $character[1][1] = $character[1][5] = $character[1][6]
	    = $character[2][0] = $character[2][1] = $character[2][2]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][0] = $character[3][1] = $character[3][4]
	    = $character[3][5] = $character[4][0] = $character[4][1]
	    = $character[4][5] = $character[4][6] = "R";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][0] = $character[1][1]
	    = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4] = $character[2][5] = $character[3][5]
	    = $character[3][6] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[4][5] = "S";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[4][2] = $character[4][3] = $character[4][4] = "T";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][5] = $character[0][6]
	    = $character[1][0] = $character[1][1] = $character[1][5]
	    = $character[1][6] = $character[2][0] = $character[2][1]
	    = $character[2][5] = $character[2][6] = $character[3][0]
	    = $character[3][1] = $character[3][5] = $character[3][6]
	    = $character[4][1] = $character[4][2] = $character[4][3]
	    = $character[4][4] = $character[4][5] = "U";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(10);
	$character[0][0] = $character[0][1] = $character[0][7] = $character[0][8]
	    = $character[1][0] = $character[1][1] = $character[1][7]
	    = $character[1][8] = $character[2][1] = $character[2][2]
	    = $character[2][6] = $character[2][7] = $character[3][2]
	    = $character[3][3] = $character[3][5] = $character[3][6]
	    = $character[4][3] = $character[4][4] = $character[4][5] = "V";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(11);
	$character[0][0] = $character[0][1] = $character[0][8] = $character[0][9]
	    = $character[1][0] = $character[1][1] = $character[1][8]
	    = $character[1][9] = $character[2][0] = $character[2][1]
	    = $character[2][5] = $character[2][8] = $character[2][9]
	    = $character[3][1] = $character[3][2] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[3][8]
	    = $character[3][9] = $character[4][2] = $character[4][3]
	    = $character[4][7] = $character[4][8] = "W";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[0][1] = $character[0][6] = $character[0][7]
	    = $character[1][1] = $character[1][2] = $character[1][5]
	    = $character[1][6] = $character[2][2] = $character[2][3]
	    = $character[2][4] = $character[2][5] = $character[3][1]
	    = $character[3][2] = $character[3][5] = $character[3][6]
	    = $character[4][0] = $character[4][1] = $character[4][6]
	    = $character[4][7] = "X";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][5] = $character[0][6]
	    = $character[1][0] = $character[1][1] = $character[1][5]
	    = $character[1][6] = $character[2][1] = $character[2][2]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[4][2] = $character[4][3] = $character[4][4] = "Y";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[1][3] = $character[1][4]
	    = $character[2][2] = $character[2][3] = $character[3][1]
	    = $character[3][2] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4] = "Z";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(8);
	$character[1][2] = $character[1][3] = $character[1][5] = $character[1][6]
	    = $character[2][1] = $character[2][2] = $character[2][4]
	    = $character[2][5] = $character[2][6] = $character[3][0]
	    = $character[3][1] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][5] = $character[4][6] = "a";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[1][0] = $character[1][1]
	    = $character[2][0] = $character[2][1] = $character[2][2]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][0] = $character[3][1] = $character[3][5]
	    = $character[3][6] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = "b";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(7);
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[3][0]
	    = $character[3][1] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[4][5] = "c";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(8);
	$character[0][5] = $character[0][6] = $character[1][5] = $character[1][6]
	    = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4] = $character[2][5] = $character[2][6]
	    = $character[3][0] = $character[3][1] = $character[3][5]
	    = $character[3][6] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[4][5]
	    = $character[4][6] = "d";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(7);
	$character[1][2] = $character[1][3] = $character[1][4] = $character[2][0]
	    = $character[2][1] = $character[2][5] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[4][5] = "e";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][0]
	    = $character[1][1] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[3][0]
	    = $character[3][1] = $character[4][0] = $character[4][1] = "f";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(8);
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[1][6] = $character[2][0]
	    = $character[2][1] = $character[2][5] = $character[2][6]
	    = $character[3][0] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[4][5] = $character[4][6]
	    = $character[5][1] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = "g";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[1][0] = $character[1][1]
	    = $character[2][0] = $character[2][1] = $character[2][2]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][0] = $character[3][1] = $character[3][5]
	    = $character[3][6] = $character[4][0] = $character[4][1]
	    = $character[4][5] = $character[4][6] = "h";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[4][0]
	    = $character[4][1] = $character[4][2] = "i";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[2][2]
	    = $character[2][3] = $character[2][4] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[5][0]
	    = $character[5][1] = $character[5][2] = $character[5][3] = "j";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[1][0] = $character[1][1]
	    = $character[1][4] = $character[1][5] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4] = $character[3][0] = $character[3][1]
	    = $character[3][3] = $character[3][4] = $character[4][0]
	    = $character[4][1] = $character[4][4] = $character[4][5] = "k";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[1][1] = $character[1][2] = $character[2][0]
	    = $character[2][1] = $character[2][2] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[4][0]
	    = $character[4][1] = $character[4][2] = "l";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(12);
	$character[1][0] = $character[1][1] = $character[1][3] = $character[1][4]
	    = $character[1][6]  = $character[1][7]  = $character[1][8]
	    = $character[1][9]  = $character[2][0]  = $character[2][1]
	    = $character[2][2]  = $character[2][5]  = $character[2][6]
	    = $character[2][9]  = $character[2][10] = $character[3][0]
	    = $character[3][1]  = $character[3][2]  = $character[3][5]
	    = $character[3][6]  = $character[3][9]  = $character[3][10]
	    = $character[4][0]  = $character[4][1]  = $character[4][2]
	    = $character[4][5]  = $character[4][6]  = $character[4][9]
	    = $character[4][10] = "m";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][1] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][5] = $character[2][6]
	    = $character[3][0] = $character[3][1] = $character[3][5]
	    = $character[3][6] = $character[4][0] = $character[4][1]
	    = $character[4][5] = $character[4][6] = "n";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(7);
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][1]
	    = $character[3][4] = $character[3][5] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4] = "o";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][1] = $character[1][3] = $character[1][4]
	    = $character[2][0] = $character[2][1] = $character[2][2]
	    = $character[2][5] = $character[2][6] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[4][0]
	    = $character[4][1] = $character[5][0] = $character[5][1] = "p";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(8);
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[1][6] = $character[2][0] = $character[2][1]
	    = $character[2][5] = $character[2][6] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[4][5]
	    = $character[4][6] = $character[5][5] = $character[5][6] = "q";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][1] = $character[1][3] = $character[1][4]
	    = $character[2][0] = $character[2][1] = $character[2][2]
	    = $character[2][5] = $character[3][0] = $character[3][1]
	    = $character[4][0] = $character[4][1] = "r";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][0]
	    = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[3][4] = $character[4][1] = $character[4][2]
	    = $character[4][3] = "s";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][1] = $character[1][0] = $character[1][1]
	    = $character[2][0] = $character[2][1] = $character[2][2]
	    = $character[2][3] = $character[3][0] = $character[3][1]
	    = $character[4][1] = $character[4][2] = $character[4][3]
	    = $character[4][4] = "t";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][1] = $character[1][5] = $character[1][6]
	    = $character[2][0] = $character[2][1] = $character[2][5]
	    = $character[2][6] = $character[3][0] = $character[3][1]
	    = $character[3][5] = $character[3][6] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][6] = "u";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][1] = $character[1][5] = $character[1][6]
	    = $character[2][1] = $character[2][2] = $character[2][4]
	    = $character[2][5] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[4][3] = "v";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(11);
	$character[1][0] = $character[1][1] = $character[1][8] = $character[1][9]
	    = $character[2][0] = $character[2][1] = $character[2][8]
	    = $character[2][9] = $character[3][1] = $character[3][2]
	    = $character[3][4] = $character[3][5] = $character[3][7]
	    = $character[3][8] = $character[4][2] = $character[4][3]
	    = $character[4][6] = $character[4][7] = "w";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = $character[4][0] = $character[4][1]
	    = $character[4][4] = $character[4][5] = "x";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][1] = $character[1][5] = $character[1][6]
	    = $character[2][0] = $character[2][1] = $character[2][5]
	    = $character[2][6] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[4][5] = $character[4][6]
	    = $character[5][1] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = "y";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][1] = $character[1][2] = $character[1][3]
	    = $character[1][4] = $character[2][2] = $character[2][3]
	    = $character[3][1] = $character[3][2] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[4][3]
	    = $character[4][4] = "z";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][0] = $character[1][1]
	    = $character[1][5] = $character[1][6] = $character[2][0]
	    = $character[2][1] = $character[2][5] = $character[2][6]
	    = $character[3][0] = $character[3][1] = $character[3][5]
	    = $character[3][6] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[4][5] = "0";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[1][0] = $character[1][1] = $character[1][2]
	    = $character[2][1] = $character[2][2] = $character[3][1]
	    = $character[3][2] = $character[4][0] = $character[4][1]
	    = $character[4][2] = "1";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[1][0] = $character[1][1] = $character[1][2]
	    = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[2][4] = $character[2][5] = $character[2][6]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = $character[4][6] = "2";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[1][3]
	    = $character[1][4] = $character[1][5] = $character[1][6]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[4][0] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = "3";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(9);
	$character[0][4] = $character[0][5] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[2][1] = $character[2][2]
	    = $character[2][5] = $character[3][0] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[3][7]
	    = $character[4][3] = $character[4][4] = $character[4][5] = "4";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[1][0]
	    = $character[1][1] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[4][0]
	    = $character[4][1] = $character[4][2] = $character[4][3]
	    = $character[4][4] = $character[4][5] = "5";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[1][1]
	    = $character[1][2] = $character[2][0] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][1]
	    = $character[3][5] = $character[3][6] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = "6";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][4] = $character[1][5] = $character[1][6]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[4][1] = $character[4][2] = $character[4][3] = "7";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][0] = $character[1][1]
	    = $character[1][5] = $character[1][6] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][1]
	    = $character[3][5] = $character[3][6] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = "8";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][0] = $character[1][1]
	    = $character[1][5] = $character[1][6] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[2][6] = $character[3][4]
	    = $character[3][5] = $character[4][2] = $character[4][3]
	    = $character[4][4] = "9";
	$character[5][0] = "\	";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Letters - Letters font

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	use Ascii::Text::Font::Letters;

	my $foo = Ascii::Text::Font::Letters->new();

	...

=head1 EXTENDS

=head2 Ascii::Text::Font



=head1 SUBROUTINES/METHODS

=head2 space



=head2 character_A

	  AAA  
	 AAAAA 
	AA   AA
	AAAAAAA
	AA   AA
	       

=head2 character_B

	BBBBB  
	BB   B 
	BBBBBB 
	BB   BB
	BBBBBB 
	       

=head2 character_C

	 CCCCC 
	CC    C
	CC     
	CC    C
	 CCCCC 
	       

=head2 character_D

	DDDDD  
	DD  DD 
	DD   DD
	DD   DD
	DDDDDD 
	       

=head2 character_E

	EEEEEEE
	EE     
	EEEEE  
	EE     
	EEEEEEE
	       

=head2 character_F

	FFFFFFF
	FF     
	FFFF   
	FF     
	FF     
	       

=head2 character_G

	  GGGG 
	 GG  GG
	GG     
	GG   GG
	 GGGGGG
	       

=head2 character_H

	HH   HH
	HH   HH
	HHHHHHH
	HH   HH
	HH   HH
	       

=head2 character_I

	IIIII
	 III 
	 III 
	 III 
	IIIII
	     

=head2 character_J

	    JJJ
	    JJJ
	    JJJ
	JJ  JJJ
	 JJJJJ 
	       

=head2 character_K

	KK  KK
	KK KK 
	KKKK  
	KK KK 
	KK  KK
	      

=head2 character_L

	LL     
	LL     
	LL     
	LL     
	LLLLLLL
	       

=head2 character_M

	MM    MM
	MMM  MMM
	MM MM MM
	MM    MM
	MM    MM
	        

=head2 character_N

	NN   NN
	NNN  NN
	NN N NN
	NN  NNN
	NN   NN
	       

=head2 character_O

	 OOOOO 
	OO   OO
	OO   OO
	OO   OO
	 OOOO0 
	       

=head2 character_P

	PPPPPP 
	PP   PP
	PPPPPP 
	PP     
	PP     
	       

=head2 character_Q

	 QQQQQ 
	QQ   QQ
	QQ   QQ
	QQ  QQ 
	 QQQQ Q
	       

=head2 character_R

	RRRRRR 
	RR   RR
	RRRRRR 
	RR  RR 
	RR   RR
	       

=head2 character_S

	 SSSSS 
	SS     
	 SSSSS 
	     SS
	 SSSSS 
	       

=head2 character_T

	TTTTTTT
	  TTT  
	  TTT  
	  TTT  
	  TTT  
	       

=head2 character_U

	UU   UU
	UU   UU
	UU   UU
	UU   UU
	 UUUUU 
	       

=head2 character_V

	VV     VV
	VV     VV
	 VV   VV 
	  VV VV  
	   VVV   
	         

=head2 character_W

	WW      WW
	WW      WW
	WW   W  WW
	 WW WWW WW
	  WW   WW 
	          

=head2 character_X

	XX    XX
	 XX  XX 
	  XXXX  
	 XX  XX 
	XX    XX
	        

=head2 character_Y

	YY   YY
	YY   YY
	 YYYYY 
	  YYY  
	  YYY  
	       

=head2 character_Z

	ZZZZZ
	   ZZ
	  ZZ 
	 ZZ  
	ZZZZZ
	     

=head2 character_a

	       
	  aa aa
	 aa aaa
	aa  aaa
	 aaa aa
	       

=head2 character_b

	bb     
	bb     
	bbbbbb 
	bb   bb
	bbbbbb 
	       

=head2 character_c

	      
	  cccc
	cc    
	cc    
	 ccccc
	      

=head2 character_d

	     dd
	     dd
	 dddddd
	dd   dd
	 dddddd
	       

=head2 character_e

	      
	  eee 
	ee   e
	eeeee 
	 eeeee
	      

=head2 character_f

	 fff
	ff  
	ffff
	ff  
	ff  
	    

=head2 character_g

	       
	 gggggg
	gg   gg
	ggggggg
	     gg
	 ggggg 

=head2 character_h

	hh     
	hh     
	hhhhhh 
	hh   hh
	hh   hh
	       

=head2 character_i

	iii
	   
	iii
	iii
	iii
	   

=head2 character_j

	  jjj
	     
	  jjj
	  jjj
	  jjj
	jjjj 

=head2 character_k

	kk    
	kk  kk
	kkkkk 
	kk kk 
	kk  kk
	      

=head2 character_l

	lll
	lll
	lll
	lll
	lll
	   

=head2 character_m

	           
	mm mm mmmm 
	mmm  mm  mm
	mmm  mm  mm
	mmm  mm  mm
	           

=head2 character_n

	       
	nn nnn 
	nnn  nn
	nn   nn
	nn   nn
	       

=head2 character_o

	      
	 oooo 
	oo  oo
	oo  oo
	 oooo 
	      

=head2 character_p

	       
	pp pp  
	ppp  pp
	pppppp 
	pp     
	pp     

=head2 character_q

	       
	  qqqqq
	qq   qq
	 qqqqqq
	     qq
	     qq

=head2 character_r

	      
	rr rr 
	rrr  r
	rr    
	rr    
	      

=head2 character_s

	 sss 
	s    
	 sss 
	    s
	 sss 
	     

=head2 character_t

	tt   
	tt   
	tttt 
	tt   
	 tttt
	     

=head2 character_u

	       
	uu   uu
	uu   uu
	uu   uu
	 uuuu u
	       

=head2 character_v

	       
	vv   vv
	 vv vv 
	  vvv  
	   v   
	       

=head2 character_w

	          
	ww      ww
	ww      ww
	 ww ww ww 
	  ww  ww  
	          

=head2 character_x

	      
	xx  xx
	  xx  
	  xx  
	xx  xx
	      

=head2 character_y

	       
	yy   yy
	yy   yy
	 yyyyyy
	     yy
	 yyyyy 

=head2 character_z

	     
	zzzzz
	  zz 
	 zz  
	zzzzz
	     

=head2 character_0

	 00000 
	00   00
	00   00
	00   00
	 00000 
	       

=head2 character_1

	 1 
	111
	 11
	 11
	111
	   

=head2 character_2

	 2222  
	222222 
	    222
	 2222  
	2222222
	       

=head2 character_3

	333333 
	   3333
	  3333 
	    333
	333333 
	       

=head2 character_4

	    44  
	   444  
	 44  4  
	44444444
	   444  
	        

=head2 character_5

	555555 
	55     
	555555 
	   5555
	555555 
	       

=head2 character_6

	  666  
	 66    
	666666 
	66   66
	 66666 
	       

=head2 character_7

	7777777
	    777
	   777 
	  777  
	 777   
	       

=head2 character_8

	 88888 
	88   88
	 88888 
	88   88
	 88888 
	       

=head2 character_9

	 99999 
	99   99
	 999999
	    99 
	  999  
		

=head1 PROPERTY

=head2 character_height



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::letters at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Letters>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Letters

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Letters>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Letters>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Letters>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Letters>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
