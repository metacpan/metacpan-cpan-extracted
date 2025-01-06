package Ascii::Text::Font::Thick;
use strict;
use warnings;
use Rope;
use Rope::Autoload;

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
	my @character = $_[0]->default_character(9);
	$character[0][3] = $character[1][2] = $character[2][1] = $character[3][0]
	    = "d";
	$character[2][3] = $character[2][4] = "w";
	$character[1][4] = $character[2][5] = $character[3][6] = "Y";
	$character[1][3] = $character[2][2] = $character[3][1] = "P";
	$character[0][4] = $character[1][5] = $character[2][6] = $character[3][7]
	    = "b";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(6);
	$character[0][3] = $character[2][4] = "b";
	$character[0][4] = "\.";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[2][0] = $character[3][0] = $character[3][1]
	    = $character[3][2] = "8";
	$character[1][1] = $character[1][2] = $character[1][3] = "w";
	$character[3][4] = "\'";
	$character[1][4] = $character[3][3] = "P";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[0][3] = $character[1][0] = $character[2][0]
	    = $character[3][2] = $character[3][3] = "8";
	$character[0][4] = $character[2][1] = "b";
	$character[0][0] = "\.";
	$character[1][1] = $character[3][4] = "P";
	$character[0][1] = "d";
	$character[3][1] = "Y";
	$character[3][0] = "\`";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[1][4] = $character[2][0] = $character[2][4]
	    = $character[3][0] = $character[3][1] = $character[3][2] = "8";
	$character[0][4] = "\.";
	$character[0][3] = "b";
	$character[3][3] = "P";
	$character[3][4] = "\'";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][3] = "8";
	$character[1][1] = $character[1][2] = $character[1][3] = "w";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[1][0] = $character[2][0] = $character[3][0] = "8";
	$character[1][1] = $character[1][2] = $character[1][3] = "w";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(7);
	$character[3][0] = "\`";
	$character[3][1] = "Y";
	$character[3][5] = "\'";
	$character[0][0] = "\.";
	$character[0][4] = $character[2][1] = "b";
	$character[0][2] = $character[0][3] = $character[1][0] = $character[2][0]
	    = $character[2][5] = $character[3][2] = $character[3][3] = "8";
	$character[0][1] = $character[2][4] = "d";
	$character[1][3] = $character[1][4] = $character[1][5] = "w";
	$character[1][1] = $character[3][4] = "P";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(6);
	$character[1][1] = $character[1][2] = $character[1][3] = "w";
	$character[0][0] = $character[0][4] = $character[1][0] = $character[1][4]
	    = $character[2][0] = $character[2][4] = $character[3][0]
	    = $character[3][4] = "8";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][1]
	    = $character[2][1] = $character[3][0] = $character[3][1]
	    = $character[3][2] = "8";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = $character[3][2] = "w";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[1][3] = $character[2][3] = "8";
	$character[3][0] = "\`";
	$character[3][1] = "Y";
	$character[3][3] = "\"";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(6);
	$character[0][3] = $character[1][2] = "d";
	$character[1][1] = "w";
	$character[0][4] = $character[1][3] = "P";
	$character[2][3] = $character[3][4] = "b";
	$character[0][0] = $character[1][0] = $character[2][0] = $character[2][1]
	    = $character[3][0] = "8";
	$character[2][2] = $character[3][3] = "Y";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[3][1] = $character[3][2] = $character[3][3] = "8";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(8);
	$character[1][5] = "P";
	$character[0][5] = $character[1][4] = "d";
	$character[0][0] = $character[0][6] = $character[1][0] = $character[1][6]
	    = $character[2][0] = $character[2][6] = $character[3][0]
	    = $character[3][6] = "8";
	$character[0][1] = $character[1][2] = "b";
	$character[1][1] = "Y";
	$character[1][3] = "m";
	$character[2][3] = "\"";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(6);
	$character[1][1] = "Y";
	$character[1][3] = "m";
	$character[2][3] = "\"";
	$character[0][0] = $character[0][4] = $character[1][0] = $character[1][4]
	    = $character[2][0] = $character[2][4] = $character[3][0]
	    = $character[3][4] = "8";
	$character[0][1] = $character[1][2] = "b";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(7);
	$character[1][1] = $character[3][4] = "P";
	$character[0][1] = $character[2][4] = "d";
	$character[0][2] = $character[0][3] = $character[1][0] = $character[1][5]
	    = $character[2][0] = $character[2][5] = $character[3][2]
	    = $character[3][3] = "8";
	$character[0][4] = $character[2][1] = "b";
	$character[0][0] = $character[0][5] = "\.";
	$character[3][5] = "\'";
	$character[1][4] = $character[3][1] = "Y";
	$character[3][0] = "\`";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(6);
	$character[2][3] = "P";
	$character[2][1] = $character[2][2] = "w";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[1][4] = $character[2][0] = $character[3][0] = "8";
	$character[0][3] = "b";
	$character[0][4] = $character[1][3] = "\.";
	$character[2][4] = "\'";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(7);
	$character[1][1] = $character[3][4] = "P";
	$character[0][1] = $character[2][4] = "d";
	$character[2][3] = $character[3][5] = "w";
	$character[0][2] = $character[0][3] = $character[1][0] = $character[1][5]
	    = $character[2][0] = $character[2][5] = $character[3][2]
	    = $character[3][3] = "8";
	$character[0][0] = $character[0][5] = "\.";
	$character[0][4] = $character[2][1] = "b";
	$character[3][0] = "\`";
	$character[1][4] = $character[3][1] = "Y";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(6);
	$character[0][4] = $character[1][3] = "\.";
	$character[0][3] = $character[3][4] = "b";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0]
	    = $character[1][4] = $character[2][0] = $character[3][0] = "8";
	$character[2][1] = $character[2][2] = "w";
	$character[2][4] = "\'";
	$character[3][3] = "Y";
	$character[2][3] = "K";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(7);
	$character[3][0] = "\`";
	$character[3][5] = "\'";
	$character[1][0] = $character[3][1] = "Y";
	$character[0][2] = $character[0][3] = $character[2][5] = $character[3][2]
	    = $character[3][3] = "8";
	$character[0][0] = $character[0][5] = $character[1][5] = "\.";
	$character[0][4] = "b";
	$character[1][1] = $character[3][4] = "P";
	$character[0][1] = $character[2][4] = "d";
	$character[1][2] = $character[1][3] = $character[1][4] = "w";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[1][2] = $character[2][2]
	    = $character[3][2] = "8";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(7);
	$character[3][1] = "Y";
	$character[3][5] = "\'";
	$character[3][0] = "\`";
	$character[2][2] = $character[2][3] = "\.";
	$character[2][1] = "b";
	$character[0][0] = $character[0][5] = $character[1][0] = $character[1][5]
	    = $character[2][0] = $character[2][5] = $character[3][2]
	    = $character[3][3] = "8";
	$character[2][4] = "d";
	$character[3][4] = "P";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[1][1] = $character[2][2] = $character[3][3]
	    = "Y";
	$character[0][6] = $character[1][5] = $character[2][4] = "d";
	$character[0][7] = $character[1][6] = $character[2][5] = $character[3][4]
	    = "P";
	$character[0][1] = $character[1][2] = $character[2][3] = "b";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(13);
	$character[0][1] = $character[1][2] = $character[1][6] = $character[2][3]
	    = $character[2][7] = "b";
	$character[0][11] = $character[1][10] = $character[2][5]
	    = $character[2][9] = $character[3][4] = $character[3][8] = "P";
	$character[0][10] = $character[1][5] = $character[1][9]
	    = $character[2][4] = $character[2][8] = "d";
	$character[0][0] = $character[1][1] = $character[2][2] = $character[2][6]
	    = $character[3][3] = $character[3][7] = "Y";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[1][2] = $character[2][4] = $character[3][5]
	    = "b";
	$character[0][4] = $character[1][3] = $character[2][1] = $character[3][0]
	    = "d";
	$character[0][5] = $character[1][4] = $character[2][2] = $character[3][1]
	    = "P";
	$character[0][0] = $character[1][1] = $character[2][3] = $character[3][4]
	    = "Y";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(7);
	$character[3][2] = $character[3][3] = "8";
	$character[0][1] = $character[1][2] = "b";
	$character[0][5] = $character[1][4] = $character[2][3] = "P";
	$character[0][4] = $character[1][3] = "d";
	$character[0][0] = $character[1][1] = $character[2][2] = "Y";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = $character[2][1] = $character[3][0] = "d";
	$character[0][4] = $character[1][3] = $character[2][2] = "P";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = "8";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = "d";
	$character[1][2] = $character[1][3] = $character[2][0] = $character[2][3]
	    = $character[3][2] = $character[3][3] = "8";
	$character[1][0] = "\.";
	$character[3][1] = "Y";
	$character[3][0] = "\`";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[1][0] = $character[1][1] = $character[2][0]
	    = $character[2][3] = $character[3][0] = $character[3][1] = "8";
	$character[1][3] = "\.";
	$character[1][2] = "b";
	$character[3][2] = "P";
	$character[3][3] = "\'";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(5);
	$character[3][1] = "Y";
	$character[3][0] = "\`";
	$character[3][3] = "P";
	$character[1][1] = "d";
	$character[1][2] = $character[2][0] = $character[3][2] = "8";
	$character[1][3] = "b";
	$character[1][0] = "\.";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = "d";
	$character[1][0] = "\.";
	$character[0][3] = $character[1][2] = $character[1][3] = $character[2][0]
	    = $character[2][3] = $character[3][2] = $character[3][3] = "8";
	$character[3][0] = "\`";
	$character[3][1] = "Y";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[2][1] = "\.";
	$character[1][4] = "b";
	$character[1][2] = $character[1][3] = $character[2][0] = $character[3][2]
	    = $character[3][3] = "8";
	$character[1][1] = $character[2][2] = "d";
	$character[2][3] = $character[3][4] = "P";
	$character[3][0] = "\`";
	$character[2][4] = "\'";
	$character[3][1] = "Y";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = "d";
	$character[2][0] = $character[2][2] = $character[2][3] = "w";
	$character[0][3] = "b";
	$character[0][2] = $character[1][1] = $character[2][1] = $character[3][1]
	    = "8";
	$character[1][2] = "\'";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(5);
	$character[4][0] = $character[4][1] = "w";
	$character[1][1] = $character[4][2] = "d";
	$character[4][3] = "P";
	$character[1][0] = "\.";
	$character[1][2] = $character[1][3] = $character[2][0] = $character[2][3]
	    = $character[3][2] = $character[3][3] = "8";
	$character[3][0] = "\`";
	$character[3][1] = "Y";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[1][0] = $character[1][2] = $character[2][0]
	    = $character[2][4] = $character[3][0] = $character[3][4] = "8";
	$character[1][4] = "\.";
	$character[1][3] = "b";
	$character[2][1] = "P";
	$character[1][1] = "d";
	$character[2][3] = "Y";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(2);
	$character[2][0] = $character[3][0] = "8";
	$character[0][0] = $character[1][0] = "w";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(4);
	$character[4][1] = "d";
	$character[0][2] = $character[1][2] = $character[4][0] = "w";
	$character[4][2] = "P";
	$character[2][2] = $character[3][2] = "8";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(5);
	$character[1][2] = "d";
	$character[1][3] = "P";
	$character[2][2] = $character[3][3] = "b";
	$character[1][1] = "\.";
	$character[0][0] = $character[1][0] = $character[2][0] = $character[2][1]
	    = $character[3][0] = "8";
	$character[3][2] = "Y";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(2);
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = "8";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(10);
	$character[1][1] = $character[1][5] = "d";
	$character[2][1] = $character[2][5] = "P";
	$character[1][3] = $character[1][7] = "b";
	$character[1][4] = $character[1][8] = "\.";
	$character[1][0] = $character[1][2] = $character[1][6] = $character[2][0]
	    = $character[2][4] = $character[2][8] = $character[3][0]
	    = $character[3][4] = $character[3][8] = "8";
	$character[2][3] = $character[2][7] = "Y";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(6);
	$character[2][3] = "Y";
	$character[2][1] = "P";
	$character[1][1] = "d";
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][4]
	    = $character[3][0] = $character[3][4] = "8";
	$character[1][4] = "\.";
	$character[1][3] = "b";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(6);
	$character[3][0] = "\`";
	$character[2][1] = $character[3][4] = "\'";
	$character[3][1] = "Y";
	$character[3][3] = "P";
	$character[1][1] = "d";
	$character[1][2] = $character[2][0] = $character[2][4] = $character[3][2]
	    = "8";
	$character[1][3] = "b";
	$character[1][0] = $character[1][4] = $character[2][3] = "\.";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(5);
	$character[3][3] = "\'";
	$character[3][2] = "P";
	$character[1][0] = $character[1][1] = $character[2][0] = $character[2][3]
	    = $character[3][0] = $character[3][1] = $character[4][0] = "8";
	$character[1][3] = "\.";
	$character[1][2] = "b";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(6);
	$character[4][4] = "P";
	$character[1][1] = "d";
	$character[1][2] = $character[1][3] = $character[2][0] = $character[2][3]
	    = $character[3][2] = $character[3][3] = $character[4][3] = "8";
	$character[1][0] = "\.";
	$character[3][1] = "Y";
	$character[3][0] = "\`";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = "d";
	$character[2][1] = "P";
	$character[1][3] = "b";
	$character[1][0] = $character[1][2] = $character[2][0] = $character[3][0]
	    = "8";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(5);
	$character[1][3] = $character[2][2] = "b";
	$character[2][3] = "\.";
	$character[1][1] = $character[1][2] = $character[3][1] = $character[3][2]
	    = "8";
	$character[1][0] = "d";
	$character[3][3] = "P";
	$character[2][1] = $character[3][0] = "Y";
	$character[2][0] = "\`";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = $character[2][1] = $character[3][2] = "8";
	$character[3][3] = "P";
	$character[0][1] = $character[1][0] = $character[1][2] = $character[1][3]
	    = "w";
	$character[3][1] = "Y";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(6);
	$character[2][3] = "d";
	$character[3][3] = "P";
	$character[2][1] = "b";
	$character[1][0] = $character[1][4] = $character[2][0] = $character[2][4]
	    = $character[3][2] = $character[3][4] = "8";
	$character[3][1] = "Y";
	$character[3][0] = "\`";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(7);
	$character[1][1] = $character[2][2] = "b";
	$character[1][4] = $character[2][3] = "d";
	$character[1][5] = $character[2][4] = $character[3][3] = "P";
	$character[1][0] = $character[2][1] = $character[3][2] = "Y";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(11);
	$character[1][1] = $character[1][5] = $character[2][2] = $character[2][6]
	    = "b";
	$character[1][9] = $character[2][4] = $character[2][8] = $character[3][3]
	    = $character[3][7] = "P";
	$character[1][4] = $character[1][8] = $character[2][3] = $character[2][7]
	    = "d";
	$character[1][0] = $character[2][1] = $character[2][5] = $character[3][2]
	    = $character[3][6] = "Y";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(6);
	$character[1][1] = $character[3][4] = "b";
	$character[2][3] = "\.";
	$character[2][2] = "8";
	$character[1][3] = $character[3][0] = "d";
	$character[1][4] = $character[3][1] = "P";
	$character[1][0] = $character[3][3] = "Y";
	$character[2][1] = "\`";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[2][1] = "Y";
	$character[1][4] = $character[2][3] = $character[3][2] = $character[4][1]
	    = "d";
	$character[1][5] = $character[2][4] = $character[3][3] = $character[4][2]
	    = "P";
	$character[1][1] = $character[2][2] = "b";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(5);
	$character[1][0] = $character[1][1] = $character[1][2] = $character[3][1]
	    = $character[3][2] = $character[3][3] = "8";
	$character[1][3] = $character[2][2] = "P";
	$character[2][1] = $character[3][0] = "d";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(7);
	$character[1][4] = $character[3][1] = "Y";
	$character[3][5] = "\'";
	$character[3][0] = "\`";
	$character[0][0] = $character[0][5] = "\.";
	$character[0][4] = $character[2][1] = "b";
	$character[0][2] = $character[0][3] = $character[1][0] = $character[1][5]
	    = $character[2][0] = $character[2][5] = $character[3][2]
	    = $character[3][3] = "8";
	$character[0][1] = $character[2][4] = "d";
	$character[1][1] = $character[3][4] = "P";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(3);
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = "8";
	$character[0][0] = "d";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(5);
	$character[1][0] = "\"";
	$character[1][3] = $character[2][2] = "P";
	$character[0][0] = $character[1][2] = $character[2][1] = $character[3][0]
	    = "d";
	$character[0][1] = $character[0][2] = $character[3][1] = $character[3][2]
	    = $character[3][3] = "8";
	$character[0][3] = "b";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(5);
	$character[3][0] = "Y";
	$character[1][1] = $character[1][2] = "w";
	$character[0][0] = "d";
	$character[1][3] = $character[3][3] = "P";
	$character[0][3] = "b";
	$character[0][1] = $character[0][2] = $character[2][3] = $character[3][1]
	    = $character[3][2] = "8";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][2] = $character[1][1] = $character[2][0] = "d";
	$character[2][2] = "w";
	$character[1][2] = $character[2][1] = "P";
	$character[0][3] = $character[1][3] = $character[2][3] = $character[3][3]
	    = "8";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(5);
	$character[3][0] = "Y";
	$character[2][2] = "\`";
	$character[1][3] = "\.";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[1][0] = $character[2][3] = $character[3][1]
	    = $character[3][2] = "8";
	$character[1][1] = $character[1][2] = "w";
	$character[3][3] = "P";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(7);
	$character[3][1] = "Y";
	$character[3][5] = "\'";
	$character[3][0] = "\`";
	$character[0][4] = $character[2][1] = "b";
	$character[1][5] = "\.";
	$character[0][2] = $character[0][3] = $character[1][0] = $character[2][0]
	    = $character[2][5] = $character[3][2] = $character[3][3] = "8";
	$character[1][2] = $character[1][3] = $character[1][4] = "w";
	$character[0][1] = $character[2][4] = "d";
	$character[1][1] = $character[3][4] = "P";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = "8";
	$character[0][4] = $character[1][3] = $character[2][2] = $character[3][1]
	    = "P";
	$character[1][2] = $character[2][1] = $character[3][0] = "d";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(7);
	$character[3][0] = "\`";
	$character[3][5] = "\'";
	$character[0][3] = $character[1][0] = $character[2][4] = $character[3][1]
	    = "Y";
	$character[2][2] = $character[2][3] = "\"";
	$character[0][2] = $character[1][5] = $character[2][1] = $character[3][4]
	    = "P";
	$character[0][1] = $character[1][4] = $character[2][0] = $character[3][3]
	    = "d";
	$character[1][2] = $character[1][3] = "w";
	$character[0][0] = $character[0][5] = "\.";
	$character[0][4] = $character[1][1] = $character[2][5] = $character[3][2]
	    = "b";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = "\`";
	$character[2][2] = "w";
	$character[0][1] = "d";
	$character[0][2] = $character[0][3] = $character[1][0] = $character[1][4]
	    = $character[2][1] = $character[2][3] = $character[2][4]
	    = $character[3][4] = "8";
	$character[0][4] = "b";
	$character[0][0] = "\.";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Thick - Thick Font

=head1 VERSION

Version 0.20

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	
	use Ascii::Text::Font::Thick;

	my $foo = Ascii::Text::Font::Thick->new();

	...

=head1 EXTENDS

=head2 Ascii::Text::Font

=head1 SUBROUTINES/METHODS

=head2 space

=head2 character_A

	   db   
	  dPYb  
	 dPwwYb 
	dP    Yb
	        

=head2 character_B

	888b.
	8wwwP
	8   b
	888P'
	     

=head2 character_C

	.d88b
	8P   
	8b   
	`Y88P
	     

=head2 character_D

	888b.
	8   8
	8   8
	888P'
	     

=head2 character_E

	8888
	8www
	8   
	8888
	    

=head2 character_F

	8888
	8www
	8   
	8   
	    

=head2 character_G

	.d88b 
	8P www
	8b  d8
	`Y88P'
	      

=head2 character_H

	8   8
	8www8
	8   8
	8   8
	     

=head2 character_I

	888
	 8 
	 8 
	888
	   

=head2 character_J

	 8888
	   8 
	w  8 
	`Yw" 
	     

=head2 character_K

	8  dP
	8wdP 
	88Yb 
	8  Yb
	     

=head2 character_L

	8   
	8   
	8   
	8888
	    

=head2 character_M

	8b   d8
	8YbmdP8
	8  "  8
	8     8
	       

=head2 character_N

	8b  8
	8Ybm8
	8  "8
	8   8
	     

=head2 character_O

	.d88b.
	8P  Y8
	8b  d8
	`Y88P'
	      

=head2 character_P

	888b.
	8  .8
	8wwP'
	8    
	     

=head2 character_Q

	.d88b.
	8P  Y8
	8b wd8
	`Y88Pw
	      

=head2 character_R

	888b.
	8  .8
	8wwK'
	8  Yb
	     

=head2 character_S

	.d88b.
	YPwww.
	    d8
	`Y88P'
	      

=head2 character_T

	88888
	  8  
	  8  
	  8  
	     

=head2 character_U

	8    8
	8    8
	8b..d8
	`Y88P'
	      

=head2 character_V

	Yb    dP
	 Yb  dP 
	  YbdP  
	   YP   
	        

=head2 character_W

	Yb        dP
	 Yb  db  dP 
	  YbdPYbdP  
	   YP  YP   
	            

=head2 character_X

	Yb  dP
	 YbdP 
	 dPYb 
	dP  Yb
	      

=head2 character_Y

	Yb  dP
	 YbdP 
	  YP  
	  88  
	      

=head2 character_Z

	8888P
	  dP 
	 dP  
	d8888
	     

=head2 character_a

	    
	.d88
	8  8
	`Y88
	    

=head2 character_b

	8   
	88b.
	8  8
	88P'
	    

=head2 character_c

	    
	.d8b
	8   
	`Y8P
	    

=head2 character_d

	   8
	.d88
	8  8
	`Y88
	    

=head2 character_e

	     
	.d88b
	8.dP'
	`Y88P
	     

=head2 character_f

	 d8b
	 8' 
	w8ww
	 8  
	    

=head2 character_g

	    
	.d88
	8  8
	`Y88
	wwdP

=head2 character_h

	8    
	8d8b.
	8P Y8
	8   8
	     

=head2 character_i

	w
	w
	8
	8
	 

=head2 character_j

	  w
	  w
	  8
	  8
	wdP

=head2 character_k

	8   
	8.dP
	88b 
	8 Yb
	    

=head2 character_l

	8
	8
	8
	8
	 

=head2 character_m

	         
	8d8b.d8b.
	8P Y8P Y8
	8   8   8
	         

=head2 character_n

	     
	8d8b.
	8P Y8
	8   8
	     

=head2 character_o

	     
	.d8b.
	8' .8
	`Y8P'
	     

=head2 character_p

	    
	88b.
	8  8
	88P'
	8   

=head2 character_q

	     
	.d88 
	8  8 
	`Y88 
	   8P

=head2 character_r

	    
	8d8b
	8P  
	8   
	    

=head2 character_s

	    
	d88b
	`Yb.
	Y88P
	    

=head2 character_t

	 w  
	w8ww
	 8  
	 Y8P
	    

=head2 character_u

	     
	8   8
	8b d8
	`Y8P8
	     

=head2 character_v

	      
	Yb  dP
	 YbdP 
	  YP  
	      

=head2 character_w

	          
	Yb  db  dP
	 YbdPYbdP 
	  YP  YP  
	          

=head2 character_x

	     
	Yb dP
	 `8. 
	dP Yb
	     

=head2 character_y

	      
	Yb  dP
	 YbdP 
	  dP  
	 dP   

=head2 character_z

	    
	888P
	 dP 
	d888
	    

=head2 character_0

	.d88b.
	8P  Y8
	8b  d8
	`Y88P'
	      

=head2 character_1

	d8
	 8
	 8
	 8
	  

=head2 character_2

	d88b
	" dP
	 dP 
	d888
	    

=head2 character_3

	d88b
	 wwP
	   8
	Y88P
	    

=head2 character_4

	  d8
	 dP8
	dPw8
	   8
	    

=head2 character_5

	8888
	8ww.
	  `8
	Y88P
	    

=head2 character_6

	 d88b 
	8Pwww.
	8b  d8
	`Y88P'
	      

=head2 character_7

	8888P
	  dP 
	 dP  
	dP   
	     

=head2 character_8

	.dPYb.
	YbwwdP
	dP""Yb
	`YbdP'
	      

=head2 character_9

	.d88b
	8   8
	`8w88
	    8
	     

=head1 PROPERTY

=head2 character_height



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::thick at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Thick>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Thick

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Thick>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Thick>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Thick>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Thick>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
