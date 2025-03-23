package Ascii::Text::Font::Lean;
use strict;
use warnings;
use Rope;
use Rope::Autoload;
our $VERSION = 0.21;

extends 'Ascii::Text::Font';

property character_height => (
	initable  => 0,
	writeable => 0,
	value     => 9
);

function space => sub {
	my (@character) = $_[0]->default_character(15);
	return \@character;
};

function character_A => sub {
	my @character = $_[0]->default_character(12);
	$character[1][6] = $character[1][8] = $character[2][3] = $character[2][9]
	    = $character[3][2] = $character[3][4] = $character[3][6]
	    = $character[3][8] = $character[4][1] = $character[4][7]
	    = $character[5][0] = $character[5][6] = "_";
	$character[1][7] = $character[1][9] = $character[2][4]
	    = $character[2][10] = $character[3][3] = $character[3][5]
	    = $character[3][7]  = $character[3][9] = $character[4][2]
	    = $character[4][8]  = $character[5][1] = $character[5][7] = "\/";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(12);
	$character[1][5] = $character[1][7] = $character[1][9] = $character[2][4]
	    = $character[2][10] = $character[3][3] = $character[3][5]
	    = $character[3][7]  = $character[4][2] = $character[4][8]
	    = $character[5][1]  = $character[5][3] = $character[5][5] = "\/";
	$character[1][4] = $character[1][6] = $character[1][8] = $character[2][3]
	    = $character[2][9] = $character[3][2] = $character[3][4]
	    = $character[3][6] = $character[4][1] = $character[4][7]
	    = $character[5][0] = $character[5][2] = $character[5][4] = "_";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(12);
	$character[1][5] = $character[1][7] = $character[1][9] = $character[2][2]
	    = $character[3][1] = $character[4][0] = $character[5][1]
	    = $character[5][3] = $character[5][5] = "_";
	$character[1][6] = $character[1][8] = $character[1][10]
	    = $character[2][3] = $character[3][2] = $character[4][1]
	    = $character[5][2] = $character[5][4] = $character[5][6] = "\/";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(12);
	$character[1][5] = $character[1][7] = $character[1][9] = $character[2][4]
	    = $character[2][10] = $character[3][3] = $character[3][9]
	    = $character[4][2]  = $character[4][8] = $character[5][1]
	    = $character[5][3]  = $character[5][5] = "\/";
	$character[1][4] = $character[1][6] = $character[1][8] = $character[2][3]
	    = $character[2][9] = $character[3][2] = $character[3][8]
	    = $character[4][1] = $character[4][7] = $character[5][0]
	    = $character[5][2] = $character[5][4] = "_";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(13);
	$character[1][5] = $character[1][7] = $character[1][9]
	    = $character[1][11] = $character[2][4] = $character[3][3]
	    = $character[3][5]  = $character[3][7] = $character[4][2]
	    = $character[5][1]  = $character[5][3] = $character[5][5]
	    = $character[5][7]  = "\/";
	$character[1][4] = $character[1][6] = $character[1][8]
	    = $character[1][10] = $character[2][3] = $character[3][2]
	    = $character[3][4]  = $character[3][6] = $character[4][1]
	    = $character[5][0]  = $character[5][2] = $character[5][4]
	    = $character[5][6]  = "_";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(13);
	$character[1][5] = $character[1][7] = $character[1][9]
	    = $character[1][11] = $character[2][4] = $character[3][3]
	    = $character[3][5]  = $character[3][7] = $character[4][2]
	    = $character[5][1]  = "\/";
	$character[1][4] = $character[1][6] = $character[1][8]
	    = $character[1][10] = $character[2][3] = $character[3][2]
	    = $character[3][4]  = $character[3][6] = $character[4][1]
	    = $character[5][0]  = "_";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(12);
	$character[1][5] = $character[1][7] = $character[1][9] = $character[2][2]
	    = $character[3][1] = $character[3][5] = $character[3][7]
	    = $character[4][0] = $character[4][6] = $character[5][1]
	    = $character[5][3] = $character[5][5] = "_";
	$character[1][6] = $character[1][8] = $character[1][10]
	    = $character[2][3] = $character[3][2] = $character[3][6]
	    = $character[3][8] = $character[4][1] = $character[4][7]
	    = $character[5][2] = $character[5][4] = $character[5][6] = "\/";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(13);
	$character[1][4] = $character[1][10] = $character[2][3]
	    = $character[2][9] = $character[3][2] = $character[3][4]
	    = $character[3][6] = $character[3][8] = $character[4][1]
	    = $character[4][7] = $character[5][0] = $character[5][6] = "_";
	$character[1][5] = $character[1][11] = $character[2][4]
	    = $character[2][10] = $character[3][3] = $character[3][5]
	    = $character[3][7]  = $character[3][9] = $character[4][2]
	    = $character[4][8]  = $character[5][1] = $character[5][7] = "\/";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(11);
	$character[1][4] = $character[1][6] = $character[1][8] = $character[2][5]
	    = $character[3][4] = $character[4][3] = $character[5][0]
	    = $character[5][2] = $character[5][4] = "_";
	$character[1][5] = $character[1][7] = $character[1][9] = $character[2][6]
	    = $character[3][5] = $character[4][4] = $character[5][1]
	    = $character[5][3] = $character[5][5] = "\/";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(12);
	$character[1][10] = $character[2][9] = $character[3][8]
	    = $character[4][1] = $character[4][7] = $character[5][2]
	    = $character[5][4] = "\/";
	$character[1][9] = $character[2][8] = $character[3][7] = $character[4][0]
	    = $character[4][6] = $character[5][1] = $character[5][3] = "_";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(13);
	$character[1][4] = $character[1][10] = $character[2][3]
	    = $character[2][7] = $character[3][2] = $character[3][4]
	    = $character[4][1] = $character[4][5] = $character[5][0]
	    = $character[5][6] = "_";
	$character[1][5] = $character[1][11] = $character[2][4]
	    = $character[2][8] = $character[3][3] = $character[3][5]
	    = $character[4][2] = $character[4][6] = $character[5][1]
	    = $character[5][7] = "\/";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(9);
	$character[1][5] = $character[2][4] = $character[3][3] = $character[4][2]
	    = $character[5][1] = $character[5][3] = $character[5][5]
	    = $character[5][7] = "\/";
	$character[1][4] = $character[2][3] = $character[3][2] = $character[4][1]
	    = $character[5][0] = $character[5][2] = $character[5][4]
	    = $character[5][6] = "_";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(15);
	$character[1][4] = $character[1][12] = $character[2][3]
	    = $character[2][5] = $character[2][9] = $character[2][11]
	    = $character[3][2] = $character[3][6] = $character[3][10]
	    = $character[4][1] = $character[4][9] = $character[5][0]
	    = $character[5][8] = "_";
	$character[1][5] = $character[1][13] = $character[2][4]
	    = $character[2][6] = $character[2][10] = $character[2][12]
	    = $character[3][3] = $character[3][7]  = $character[3][11]
	    = $character[4][2] = $character[4][10] = $character[5][1]
	    = $character[5][9] = "\/";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(15);
	$character[1][5] = $character[1][13] = $character[2][4]
	    = $character[2][6] = $character[2][12] = $character[3][3]
	    = $character[3][7] = $character[3][11] = $character[4][2]
	    = $character[4][8] = $character[4][10] = $character[5][1]
	    = $character[5][9] = "\/";
	$character[1][4] = $character[1][12] = $character[2][3]
	    = $character[2][5] = $character[2][11] = $character[3][2]
	    = $character[3][6] = $character[3][10] = $character[4][1]
	    = $character[4][7] = $character[4][9]  = $character[5][0]
	    = $character[5][8] = "_";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(11);
	$character[1][5] = $character[1][7] = $character[2][2] = $character[2][8]
	    = $character[3][1] = $character[3][7] = $character[4][0]
	    = $character[4][6] = $character[5][1] = $character[5][3] = "_";
	$character[1][6] = $character[1][8] = $character[2][3] = $character[2][9]
	    = $character[3][2] = $character[3][8] = $character[4][1]
	    = $character[4][7] = $character[5][2] = $character[5][4] = "\/";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(12);
	$character[1][5] = $character[1][7] = $character[1][9] = $character[2][4]
	    = $character[2][10] = $character[3][3] = $character[3][5]
	    = $character[3][7] = $character[4][2] = $character[5][1] = "\/";
	$character[1][4] = $character[1][6] = $character[1][8] = $character[2][3]
	    = $character[2][9] = $character[3][2] = $character[3][4]
	    = $character[3][6] = $character[4][1] = $character[5][0] = "_";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(11);
	$character[1][6] = $character[1][8] = $character[2][3] = $character[2][9]
	    = $character[3][2] = $character[3][6] = $character[3][8]
	    = $character[4][1] = $character[4][7] = $character[5][2]
	    = $character[5][4] = $character[5][8] = "\/";
	$character[1][5] = $character[1][7] = $character[2][2] = $character[2][8]
	    = $character[3][1] = $character[3][5] = $character[3][7]
	    = $character[4][0] = $character[4][6] = $character[5][1]
	    = $character[5][3] = $character[5][7] = "_";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(12);
	$character[1][5] = $character[1][7] = $character[1][9] = $character[2][4]
	    = $character[2][10] = $character[3][3] = $character[3][5]
	    = $character[3][7]  = $character[4][2] = $character[4][8]
	    = $character[5][1]  = $character[5][7] = "\/";
	$character[1][4] = $character[1][6] = $character[1][8] = $character[2][3]
	    = $character[2][9] = $character[3][2] = $character[3][4]
	    = $character[3][6] = $character[4][1] = $character[4][7]
	    = $character[5][0] = $character[5][6] = "_";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(13);
	$character[1][6] = $character[1][8] = $character[1][10]
	    = $character[2][3] = $character[3][4] = $character[3][6]
	    = $character[4][7] = $character[5][0] = $character[5][2]
	    = $character[5][4] = "_";
	$character[1][7] = $character[1][9] = $character[1][11]
	    = $character[2][4] = $character[3][5] = $character[3][7]
	    = $character[4][8] = $character[5][1] = $character[5][3]
	    = $character[5][5] = "\/";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(11);
	$character[1][0] = $character[1][2] = $character[1][4] = $character[1][6]
	    = $character[1][8] = $character[2][3] = $character[3][2]
	    = $character[4][1] = $character[5][0] = "_";
	$character[1][1] = $character[1][3] = $character[1][5] = $character[1][7]
	    = $character[1][9] = $character[2][4] = $character[3][3]
	    = $character[4][2] = $character[5][1] = "\/";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(12);
	$character[1][4] = $character[1][10] = $character[2][3]
	    = $character[2][9] = $character[3][2] = $character[3][8]
	    = $character[4][1] = $character[4][7] = $character[5][2]
	    = $character[5][4] = "\/";
	$character[1][3] = $character[1][9] = $character[2][2] = $character[2][8]
	    = $character[3][1] = $character[3][7] = $character[4][0]
	    = $character[4][6] = $character[5][1] = $character[5][3] = "_";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(13);
	$character[1][3] = $character[1][11] = $character[2][2]
	    = $character[2][10] = $character[3][1] = $character[3][9]
	    = $character[4][2] = $character[4][6] = $character[5][3] = "\/";
	$character[1][2] = $character[1][10] = $character[2][1]
	    = $character[2][9] = $character[3][0] = $character[3][8]
	    = $character[4][1] = $character[4][5] = $character[5][2] = "_";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(17);
	$character[1][3] = $character[1][15] = $character[2][2]
	    = $character[2][14] = $character[3][1] = $character[3][7]
	    = $character[3][13] = $character[4][2] = $character[4][6]
	    = $character[4][10] = $character[5][3] = $character[5][7] = "\/";
	$character[1][2] = $character[1][14] = $character[2][1]
	    = $character[2][13] = $character[3][0] = $character[3][6]
	    = $character[3][12] = $character[4][1] = $character[4][5]
	    = $character[4][9]  = $character[5][2] = $character[5][6] = "_";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(15);
	$character[1][5] = $character[1][13] = $character[2][6]
	    = $character[2][10] = $character[3][7] = $character[4][4]
	    = $character[4][8] = $character[5][1] = $character[5][9] = "\/";
	$character[1][4] = $character[1][12] = $character[2][5]
	    = $character[2][9] = $character[3][6] = $character[4][3]
	    = $character[4][7] = $character[5][0] = $character[5][8] = "_";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(11);
	$character[1][0] = $character[1][8] = $character[2][1] = $character[2][5]
	    = $character[3][2] = $character[4][1] = $character[5][0] = "_";
	$character[1][1] = $character[1][9] = $character[2][2] = $character[2][6]
	    = $character[3][3] = $character[4][2] = $character[5][1] = "\/";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(15);
	$character[1][5] = $character[1][7] = $character[1][9]
	    = $character[1][11] = $character[1][13] = $character[2][10]
	    = $character[3][7]  = $character[4][4]  = $character[5][1]
	    = $character[5][3]  = $character[5][5]  = $character[5][7]
	    = $character[5][9]  = "\/";
	$character[1][4] = $character[1][6] = $character[1][8]
	    = $character[1][10] = $character[1][12] = $character[2][9]
	    = $character[3][6]  = $character[4][3]  = $character[5][0]
	    = $character[5][2]  = $character[5][4]  = $character[5][6]
	    = $character[5][8]  = "_";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(11);
	$character[2][5] = $character[2][7] = $character[2][9] = $character[3][2]
	    = $character[3][8] = $character[4][1] = $character[4][7]
	    = $character[5][2] = $character[5][4] = $character[5][6] = "\/";
	$character[2][4] = $character[2][6] = $character[2][8] = $character[3][1]
	    = $character[3][7] = $character[4][0] = $character[4][6]
	    = $character[5][1] = $character[5][3] = $character[5][5] = "_";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(11);
	$character[1][5] = $character[2][4] = $character[2][6] = $character[2][8]
	    = $character[3][3] = $character[3][9] = $character[4][2]
	    = $character[4][8] = $character[5][1] = $character[5][3]
	    = $character[5][5] = "\/";
	$character[1][4] = $character[2][3] = $character[2][5] = $character[2][7]
	    = $character[3][2] = $character[3][8] = $character[4][1]
	    = $character[4][7] = $character[5][0] = $character[5][2]
	    = $character[5][4] = "_";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(11);
	$character[2][5] = $character[2][7] = $character[2][9] = $character[3][2]
	    = $character[4][1] = $character[5][2] = $character[5][4]
	    = $character[5][6] = "\/";
	$character[2][4] = $character[2][6] = $character[2][8] = $character[3][1]
	    = $character[4][0] = $character[5][1] = $character[5][3]
	    = $character[5][5] = "_";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(12);
	$character[1][10] = $character[2][5] = $character[2][7]
	    = $character[2][9] = $character[3][2] = $character[3][8]
	    = $character[4][1] = $character[4][7] = $character[5][2]
	    = $character[5][4] = $character[5][6] = "\/";
	$character[1][9] = $character[2][4] = $character[2][6] = $character[2][8]
	    = $character[3][1] = $character[3][7] = $character[4][0]
	    = $character[4][6] = $character[5][1] = $character[5][3]
	    = $character[5][5] = "_";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(10);
	$character[2][5] = $character[2][7] = $character[3][2] = $character[3][4]
	    = $character[3][6] = $character[3][8] = $character[4][1]
	    = $character[5][2] = $character[5][4] = $character[5][6] = "\/";
	$character[2][4] = $character[2][6] = $character[3][1] = $character[3][3]
	    = $character[3][5] = $character[3][7] = $character[4][0]
	    = $character[5][1] = $character[5][3] = $character[5][5] = "_";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(11);
	$character[1][7] = $character[1][9] = $character[2][4] = $character[3][1]
	    = $character[3][3] = $character[3][5] = $character[3][7]
	    = $character[4][2] = $character[5][1] = "\/";
	$character[1][6] = $character[1][8] = $character[2][3] = $character[3][0]
	    = $character[3][2] = $character[3][4] = $character[3][6]
	    = $character[4][1] = $character[5][0] = "_";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(12);
	$character[2][5] = $character[2][7] = $character[2][9] = $character[3][2]
	    = $character[3][8] = $character[4][1] = $character[4][7]
	    = $character[5][2] = $character[5][4] = $character[5][6]
	    = $character[6][5] = $character[7][0] = $character[7][2] = "_";
	$character[2][6] = $character[2][8] = $character[2][10]
	    = $character[3][3] = $character[3][9] = $character[4][2]
	    = $character[4][8] = $character[5][3] = $character[5][5]
	    = $character[5][7] = $character[6][6] = $character[7][1]
	    = $character[7][3] = "\/";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(11);
	$character[1][4] = $character[2][3] = $character[2][5] = $character[2][7]
	    = $character[3][2] = $character[3][8] = $character[4][1]
	    = $character[4][7] = $character[5][0] = $character[5][6] = "_";
	$character[1][5] = $character[2][4] = $character[2][6] = $character[2][8]
	    = $character[3][3] = $character[3][9] = $character[4][2]
	    = $character[4][8] = $character[5][1] = $character[5][7] = "\/";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(7);
	$character[1][4] = $character[3][2] = $character[4][1] = $character[5][0]
	    = "_";
	$character[1][5] = $character[3][3] = $character[4][2] = $character[5][1]
	    = "\/";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(11);
	$character[1][8] = $character[3][6] = $character[4][5] = $character[5][4]
	    = $character[6][3] = $character[7][0] = "_";
	$character[1][9] = $character[3][7] = $character[4][6] = $character[5][5]
	    = $character[6][4] = $character[7][1] = "\/";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(10);
	$character[1][5] = $character[2][4] = $character[2][8] = $character[3][3]
	    = $character[3][5] = $character[4][2] = $character[4][6]
	    = $character[5][1] = $character[5][7] = "\/";
	$character[1][4] = $character[2][3] = $character[2][7] = $character[3][2]
	    = $character[3][4] = $character[4][1] = $character[4][5]
	    = $character[5][0] = $character[5][6] = "_";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(7);
	$character[1][5] = $character[2][4] = $character[3][3] = $character[4][2]
	    = $character[5][1] = "\/";
	$character[1][4] = $character[2][3] = $character[3][2] = $character[4][1]
	    = $character[5][0] = "_";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(17);
	$character[2][4] = $character[2][6] = $character[2][8]
	    = $character[2][12] = $character[2][14] = $character[3][3]
	    = $character[3][9]  = $character[3][15] = $character[4][2]
	    = $character[4][8]  = $character[4][14] = $character[5][1]
	    = $character[5][7]  = $character[5][13] = "\/";
	$character[2][3] = $character[2][5] = $character[2][7]
	    = $character[2][11] = $character[2][13] = $character[3][2]
	    = $character[3][8]  = $character[3][14] = $character[4][1]
	    = $character[4][7]  = $character[4][13] = $character[5][0]
	    = $character[5][6]  = $character[5][12] = "_";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(11);
	$character[2][4] = $character[2][6] = $character[2][8] = $character[3][3]
	    = $character[3][9] = $character[4][2] = $character[4][8]
	    = $character[5][1] = $character[5][7] = "\/";
	$character[2][3] = $character[2][5] = $character[2][7] = $character[3][2]
	    = $character[3][8] = $character[4][1] = $character[4][7]
	    = $character[5][0] = $character[5][6] = "_";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(10);
	$character[2][4] = $character[2][6] = $character[3][1] = $character[3][7]
	    = $character[4][0] = $character[4][6] = $character[5][1]
	    = $character[5][3] = "_";
	$character[2][5] = $character[2][7] = $character[3][2] = $character[3][8]
	    = $character[4][1] = $character[4][7] = $character[5][2]
	    = $character[5][4] = "\/";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(13);
	$character[2][5] = $character[2][7] = $character[2][9] = $character[3][4]
	    = $character[3][10] = $character[4][3] = $character[4][9]
	    = $character[5][2]  = $character[5][4] = $character[5][6]
	    = $character[6][1]  = $character[7][0] = "_";
	$character[2][6] = $character[2][8] = $character[2][10]
	    = $character[3][5]  = $character[3][11] = $character[4][4]
	    = $character[4][10] = $character[5][3]  = $character[5][5]
	    = $character[5][7]  = $character[6][2]  = $character[7][1] = "\/";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(11);
	$character[2][4] = $character[2][6] = $character[2][8] = $character[3][1]
	    = $character[3][7] = $character[4][0] = $character[4][6]
	    = $character[5][1] = $character[5][3] = $character[5][5]
	    = $character[6][4] = $character[7][3] = "_";
	$character[2][5] = $character[2][7] = $character[2][9] = $character[3][2]
	    = $character[3][8] = $character[4][1] = $character[4][7]
	    = $character[5][2] = $character[5][4] = $character[5][6]
	    = $character[6][5] = $character[7][4] = "\/";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(12);
	$character[2][3] = $character[2][7] = $character[2][9] = $character[3][2]
	    = $character[3][4] = $character[4][1] = $character[5][0] = "_";
	$character[2][4] = $character[2][8] = $character[2][10]
	    = $character[3][3] = $character[3][5] = $character[4][2]
	    = $character[5][1] = "\/";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(12);
	$character[2][5] = $character[2][7] = $character[2][9] = $character[3][2]
	    = $character[3][4] = $character[4][5] = $character[4][7]
	    = $character[5][0] = $character[5][2] = $character[5][4] = "_";
	$character[2][6] = $character[2][8] = $character[2][10]
	    = $character[3][3] = $character[3][5] = $character[4][6]
	    = $character[4][8] = $character[5][1] = $character[5][3]
	    = $character[5][5] = "\/";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(9);
	$character[1][3] = $character[2][0] = $character[2][2] = $character[2][4]
	    = $character[2][6] = $character[3][1] = $character[4][0]
	    = $character[5][1] = $character[5][3] = "_";
	$character[1][4] = $character[2][1] = $character[2][3] = $character[2][5]
	    = $character[2][7] = $character[3][2] = $character[4][1]
	    = $character[5][2] = $character[5][4] = "\/";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(11);
	$character[2][2] = $character[2][8] = $character[3][1] = $character[3][7]
	    = $character[4][0] = $character[4][6] = $character[5][1]
	    = $character[5][3] = $character[5][5] = "_";
	$character[2][3] = $character[2][9] = $character[3][2] = $character[3][8]
	    = $character[4][1] = $character[4][7] = $character[5][2]
	    = $character[5][4] = $character[5][6] = "\/";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(12);
	$character[2][2] = $character[2][10] = $character[3][1]
	    = $character[3][9] = $character[4][2] = $character[4][6]
	    = $character[5][3] = "\/";
	$character[2][1] = $character[2][9] = $character[3][0] = $character[3][8]
	    = $character[4][1] = $character[4][5] = $character[5][2] = "_";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(20);
	$character[2][1] = $character[2][9] = $character[2][17]
	    = $character[3][0]  = $character[3][8] = $character[3][16]
	    = $character[4][1]  = $character[4][5] = $character[4][9]
	    = $character[4][13] = $character[5][2] = $character[5][10] = "_";
	$character[2][2] = $character[2][10] = $character[2][18]
	    = $character[3][1]  = $character[3][9] = $character[3][17]
	    = $character[4][2]  = $character[4][6] = $character[4][10]
	    = $character[4][14] = $character[5][3] = $character[5][11] = "\/";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(12);
	$character[2][3] = $character[2][9] = $character[3][4] = $character[3][6]
	    = $character[4][1] = $character[4][7] = $character[5][0]
	    = $character[5][6] = "_";
	$character[2][4] = $character[2][10] = $character[3][5]
	    = $character[3][7] = $character[4][2] = $character[4][8]
	    = $character[5][1] = $character[5][7] = "\/";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(12);
	$character[2][3] = $character[2][9] = $character[3][2] = $character[3][8]
	    = $character[4][1] = $character[4][7] = $character[5][2]
	    = $character[5][4] = $character[5][6] = $character[6][5]
	    = $character[7][0] = $character[7][2] = "_";
	$character[2][4] = $character[2][10] = $character[3][3]
	    = $character[3][9] = $character[4][2] = $character[4][8]
	    = $character[5][3] = $character[5][5] = $character[5][7]
	    = $character[6][6] = $character[7][1] = $character[7][3] = "\/";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(12);
	$character[2][4] = $character[2][6] = $character[2][8]
	    = $character[2][10] = $character[3][7] = $character[4][4]
	    = $character[5][1]  = $character[5][3] = $character[5][5]
	    = $character[5][7]  = "\/";
	$character[2][3] = $character[2][5] = $character[2][7] = $character[2][9]
	    = $character[3][6] = $character[4][3] = $character[5][0]
	    = $character[5][2] = $character[5][4] = $character[5][6] = "_";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(9);
	$character[1][6] = $character[2][3] = $character[2][7] = $character[3][2]
	    = $character[3][6] = $character[4][1] = $character[4][5]
	    = $character[5][2] = "\/";
	$character[1][5] = $character[2][2] = $character[2][6] = $character[3][1]
	    = $character[3][5] = $character[4][0] = $character[4][4]
	    = $character[5][1] = "_";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(7);
	$character[1][4] = $character[2][1] = $character[2][3] = $character[3][2]
	    = $character[4][1] = $character[5][0] = "_";
	$character[1][5] = $character[2][2] = $character[2][4] = $character[3][3]
	    = $character[4][2] = $character[5][1] = "\/";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(12);
	$character[1][7] = $character[1][9] = $character[2][4]
	    = $character[2][10] = $character[3][7] = $character[4][4]
	    = $character[5][1]  = $character[5][3] = $character[5][5]
	    = $character[5][7]  = "\/";
	$character[1][6] = $character[1][8] = $character[2][3] = $character[2][9]
	    = $character[3][6] = $character[4][3] = $character[5][0]
	    = $character[5][2] = $character[5][4] = $character[5][6] = "_";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(12);
	$character[1][4] = $character[1][6] = $character[1][8] = $character[2][9]
	    = $character[3][4] = $character[3][6] = $character[4][7]
	    = $character[5][0] = $character[5][2] = $character[5][4] = "_";
	$character[1][5] = $character[1][7] = $character[1][9]
	    = $character[2][10] = $character[3][5] = $character[3][7]
	    = $character[4][8]  = $character[5][1] = $character[5][3]
	    = $character[5][5]  = "\/";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(9);
	$character[1][2] = $character[1][6] = $character[2][1] = $character[2][5]
	    = $character[3][0] = $character[3][2] = $character[3][4]
	    = $character[3][6] = $character[4][3] = $character[5][2] = "_";
	$character[1][3] = $character[1][7] = $character[2][2] = $character[2][6]
	    = $character[3][1] = $character[3][3] = $character[3][5]
	    = $character[3][7] = $character[4][4] = $character[5][3] = "\/";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(13);
	$character[1][4] = $character[1][6] = $character[1][8]
	    = $character[1][10] = $character[2][3] = $character[3][2]
	    = $character[3][4]  = $character[3][6] = $character[4][7]
	    = $character[5][0]  = $character[5][2] = $character[5][4] = "_";
	$character[1][5] = $character[1][7] = $character[1][9]
	    = $character[1][11] = $character[2][4] = $character[3][3]
	    = $character[3][5]  = $character[3][7] = $character[4][8]
	    = $character[5][1]  = $character[5][3] = $character[5][5] = "\/";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(12);
	$character[1][6] = $character[1][8] = $character[1][10]
	    = $character[2][3] = $character[3][2] = $character[3][4]
	    = $character[3][6] = $character[4][1] = $character[4][7]
	    = $character[5][2] = $character[5][4] = "\/";
	$character[1][5] = $character[1][7] = $character[1][9] = $character[2][2]
	    = $character[3][1] = $character[3][3] = $character[3][5]
	    = $character[4][0] = $character[4][6] = $character[5][1]
	    = $character[5][3] = "_";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(13);
	$character[1][3] = $character[1][5] = $character[1][7] = $character[1][9]
	    = $character[1][11] = $character[2][10] = $character[3][7]
	    = $character[4][4] = $character[5][1] = "\/";
	$character[1][2] = $character[1][4] = $character[1][6] = $character[1][8]
	    = $character[1][10] = $character[2][9] = $character[3][6]
	    = $character[4][3] = $character[5][0] = "_";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(11);
	$character[1][5] = $character[1][7] = $character[2][2] = $character[2][8]
	    = $character[3][3] = $character[3][5] = $character[4][0]
	    = $character[4][6] = $character[5][1] = $character[5][3] = "_";
	$character[1][6] = $character[1][8] = $character[2][3] = $character[2][9]
	    = $character[3][4] = $character[3][6] = $character[4][1]
	    = $character[4][7] = $character[5][2] = $character[5][4] = "\/";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(12);
	$character[1][6] = $character[1][8] = $character[2][3] = $character[2][9]
	    = $character[3][4] = $character[3][6] = $character[3][8]
	    = $character[4][7] = $character[5][0] = $character[5][2]
	    = $character[5][4] = "_";
	$character[1][7] = $character[1][9] = $character[2][4]
	    = $character[2][10] = $character[3][5] = $character[3][7]
	    = $character[3][9]  = $character[4][8] = $character[5][1]
	    = $character[5][3]  = $character[5][5] = "\/";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Lean - Lean font

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	use Ascii::Text::Font::Lean;

	my $foo = Ascii::Text::Font::Lean->new();

	...

=head1 EXTENDS

=head2 Ascii::Text::Font



=head1 SUBROUTINES/METHODS

=head2 space



=head2 character_A

	              
	      _/_/    
	   _/    _/   
	  _/_/_/_/    
	 _/    _/     
	_/    _/      
	              
	              

=head2 character_B

	              
	    _/_/_/    
	   _/    _/   
	  _/_/_/      
	 _/    _/     
	_/_/_/        
	              
	              

=head2 character_C

	              
	     _/_/_/   
	  _/          
	 _/           
	_/            
	 _/_/_/       
	              
	              

=head2 character_D

	              
	    _/_/_/    
	   _/    _/   
	  _/    _/    
	 _/    _/     
	_/_/_/        
	              
	              

=head2 character_E

	               
	    _/_/_/_/   
	   _/          
	  _/_/_/       
	 _/            
	_/_/_/_/       
	               
	               

=head2 character_F

	               
	    _/_/_/_/   
	   _/          
	  _/_/_/       
	 _/            
	_/             
	               
	               

=head2 character_G

	              
	     _/_/_/   
	  _/          
	 _/  _/_/     
	_/    _/      
	 _/_/_/       
	              
	              

=head2 character_H

	               
	    _/    _/   
	   _/    _/    
	  _/_/_/_/     
	 _/    _/      
	_/    _/       
	               
	               

=head2 character_I

	             
	    _/_/_/   
	     _/      
	    _/       
	   _/        
	_/_/_/       
	             
	             

=head2 character_J

	              
	         _/   
	        _/    
	       _/     
	_/    _/      
	 _/_/         
	              
	              

=head2 character_K

	               
	    _/    _/   
	   _/  _/      
	  _/_/         
	 _/  _/        
	_/    _/       
	               
	               

=head2 character_L

	           
	    _/     
	   _/      
	  _/       
	 _/        
	_/_/_/_/   
	           
	           

=head2 character_M

	                 
	    _/      _/   
	   _/_/  _/_/    
	  _/  _/  _/     
	 _/      _/      
	_/      _/       
	                 
	                 

=head2 character_N

	                 
	    _/      _/   
	   _/_/    _/    
	  _/  _/  _/     
	 _/    _/_/      
	_/      _/       
	                 
	                 

=head2 character_O

	             
	     _/_/    
	  _/    _/   
	 _/    _/    
	_/    _/     
	 _/_/        
	             
	             

=head2 character_P

	              
	    _/_/_/    
	   _/    _/   
	  _/_/_/      
	 _/           
	_/            
	              
	              

=head2 character_Q

	             
	     _/_/    
	  _/    _/   
	 _/  _/_/    
	_/    _/     
	 _/_/  _/    
	             
	             

=head2 character_R

	              
	    _/_/_/    
	   _/    _/   
	  _/_/_/      
	 _/    _/     
	_/    _/      
	              
	              

=head2 character_S

	               
	      _/_/_/   
	   _/          
	    _/_/       
	       _/      
	_/_/_/         
	               
	               

=head2 character_T

	             
	_/_/_/_/_/   
	   _/        
	  _/         
	 _/          
	_/           
	             
	             

=head2 character_U

	              
	   _/    _/   
	  _/    _/    
	 _/    _/     
	_/    _/      
	 _/_/         
	              
	              

=head2 character_V

	               
	  _/      _/   
	 _/      _/    
	_/      _/     
	 _/  _/        
	  _/           
	               
	               

=head2 character_W

	                   
	  _/          _/   
	 _/          _/    
	_/    _/    _/     
	 _/  _/  _/        
	  _/  _/           
	                   
	                   

=head2 character_X

	                 
	    _/      _/   
	     _/  _/      
	      _/         
	   _/  _/        
	_/      _/       
	                 
	                 

=head2 character_Y

	             
	_/      _/   
	 _/  _/      
	  _/         
	 _/          
	_/           
	             
	             

=head2 character_Z

	                 
	    _/_/_/_/_/   
	         _/      
	      _/         
	   _/            
	_/_/_/_/_/       
	                 
	                 

=head2 character_a

	             
	             
	    _/_/_/   
	 _/    _/    
	_/    _/     
	 _/_/_/      
	             
	             

=head2 character_b

	             
	    _/       
	   _/_/_/    
	  _/    _/   
	 _/    _/    
	_/_/_/       
	             
	             

=head2 character_c

	             
	             
	    _/_/_/   
	 _/          
	_/           
	 _/_/_/      
	             
	             

=head2 character_d

	              
	         _/   
	    _/_/_/    
	 _/    _/     
	_/    _/      
	 _/_/_/       
	              
	              

=head2 character_e

	            
	            
	    _/_/    
	 _/_/_/_/   
	_/          
	 _/_/_/     
	            
	            

=head2 character_f

	             
	      _/_/   
	   _/        
	_/_/_/_/     
	 _/          
	_/           
	             
	             

=head2 character_g

	              
	              
	     _/_/_/   
	  _/    _/    
	 _/    _/     
	  _/_/_/      
	     _/       
	_/_/          

=head2 character_h

	             
	    _/       
	   _/_/_/    
	  _/    _/   
	 _/    _/    
	_/    _/     
	             
	             

=head2 character_i

	         
	    _/   
	         
	  _/     
	 _/      
	_/       
	         
	         

=head2 character_j

	             
	        _/   
	             
	      _/     
	     _/      
	    _/       
	   _/        
	_/           

=head2 character_k

	            
	    _/      
	   _/  _/   
	  _/_/      
	 _/  _/     
	_/    _/    
	            
	            

=head2 character_l

	         
	    _/   
	   _/    
	  _/     
	 _/      
	_/       
	         
	         

=head2 character_m

	                   
	                   
	   _/_/_/  _/_/    
	  _/    _/    _/   
	 _/    _/    _/    
	_/    _/    _/     
	                   
	                   

=head2 character_n

	             
	             
	   _/_/_/    
	  _/    _/   
	 _/    _/    
	_/    _/     
	             
	             

=head2 character_o

	            
	            
	    _/_/    
	 _/    _/   
	_/    _/    
	 _/_/       
	            
	            

=head2 character_p

	               
	               
	     _/_/_/    
	    _/    _/   
	   _/    _/    
	  _/_/_/       
	 _/            
	_/             

=head2 character_q

	             
	             
	    _/_/_/   
	 _/    _/    
	_/    _/     
	 _/_/_/      
	    _/       
	   _/        

=head2 character_r

	              
	              
	   _/  _/_/   
	  _/_/        
	 _/           
	_/            
	              
	              

=head2 character_s

	              
	              
	     _/_/_/   
	  _/_/        
	     _/_/     
	_/_/_/        
	              
	              

=head2 character_t

	           
	   _/      
	_/_/_/_/   
	 _/        
	_/         
	 _/_/      
	           
	           

=head2 character_u

	             
	             
	  _/    _/   
	 _/    _/    
	_/    _/     
	 _/_/_/      
	             
	             

=head2 character_v

	              
	              
	 _/      _/   
	_/      _/    
	 _/  _/       
	  _/          
	              
	              

=head2 character_w

	                      
	                      
	 _/      _/      _/   
	_/      _/      _/    
	 _/  _/  _/  _/       
	  _/      _/          
	                      
	                      

=head2 character_x

	              
	              
	   _/    _/   
	    _/_/      
	 _/    _/     
	_/    _/      
	              
	              

=head2 character_y

	              
	              
	   _/    _/   
	  _/    _/    
	 _/    _/     
	  _/_/_/      
	     _/       
	_/_/          

=head2 character_z

	              
	              
	   _/_/_/_/   
	      _/      
	   _/         
	_/_/_/_/      
	              
	              

=head2 character_0

	           
	     _/    
	  _/  _/   
	 _/  _/    
	_/  _/     
	 _/        
	           
	           

=head2 character_1

	         
	    _/   
	 _/_/    
	  _/     
	 _/      
	_/       
	         
	         

=head2 character_2

	              
	      _/_/    
	   _/    _/   
	      _/      
	   _/         
	_/_/_/_/      
	              
	              

=head2 character_3

	              
	    _/_/_/    
	         _/   
	    _/_/      
	       _/     
	_/_/_/        
	              
	              

=head2 character_4

	           
	  _/  _/   
	 _/  _/    
	_/_/_/_/   
	   _/      
	  _/       
	           
	           

=head2 character_5

	               
	    _/_/_/_/   
	   _/          
	  _/_/_/       
	       _/      
	_/_/_/         
	               
	               

=head2 character_6

	              
	     _/_/_/   
	  _/          
	 _/_/_/       
	_/    _/      
	 _/_/         
	              
	              

=head2 character_7

	               
	  _/_/_/_/_/   
	         _/    
	      _/       
	   _/          
	_/             
	               
	               

=head2 character_8

	             
	     _/_/    
	  _/    _/   
	   _/_/      
	_/    _/     
	 _/_/        
	             
	             

=head2 character_9

	              
	      _/_/    
	   _/    _/   
	    _/_/_/    
	       _/     
	_/_/_/        
	              
	              

=head1 PROPERTY

=head2 character_height



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::lean at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Lean>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Lean

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Lean>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Lean>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Lean>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Lean>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
