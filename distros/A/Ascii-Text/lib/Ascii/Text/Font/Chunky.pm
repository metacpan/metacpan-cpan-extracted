package Ascii::Text::Font::Chunky;
use strict;
use warnings;
use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable => 0,
	writable => 0,
	value => 5,
);

function space => sub {
	my @character = $_[0]->default_character(9);
	return \@character;
};


function character_A => sub {
	my @character = $_[0]->default_character(9);
	$character[1][0] = $character[1][8] = $character[2][0] = $character[2][8]
	    = $character[3][0] = $character[3][4] = $character[3][8] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[1][4] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][5] = $character[3][6]
	    = $character[3][7] = "_";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(8);
	$character[1][7] = "\\";
	$character[1][0] = $character[2][0] = $character[3][0] = "\|";
	$character[2][7] = "\<";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][4]
	    = $character[1][5] = $character[2][4] = $character[2][5]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	$character[3][7] = "\/";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][7] = $character[2][0] = $character[2][7]
	    = $character[3][0] = $character[3][7] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[3][6] = "_";
	$character[2][4] = $character[2][5] = $character[2][6] = "\-";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5] = "_";
	$character[1][6] = "\\";
	$character[1][0] = $character[2][0] = $character[2][7] = $character[3][0]
	    = "\|";
	$character[3][6] = "\/";
	$character[2][3] = $character[2][4] = "\-";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(9);
	$character[1][0] = $character[1][8] = $character[2][0] = $character[2][8]
	    = $character[3][0] = $character[3][8] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[1][5] = $character[1][6] = $character[1][7]
	    = $character[2][5] = $character[2][6] = $character[2][7]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[3][7] = "_";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[1][5] = $character[1][6] = $character[1][7]
	    = $character[2][5] = $character[2][6] = $character[2][7]
	    = $character[3][1] = $character[3][2] = $character[3][3] = "_";
	$character[1][0] = $character[1][8] = $character[2][0] = $character[2][8]
	    = $character[3][0] = $character[3][4] = "\|";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(9);
	$character[1][0] = $character[1][8] = $character[2][0] = $character[2][5]
	    = $character[2][8] = $character[3][0] = $character[3][8] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[1][6] = $character[1][7] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[3][7] = "_";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][5] = $character[3][6] = $character[3][7] = "_";
	$character[1][0] = $character[1][4] = $character[1][8] = $character[2][0]
	    = $character[2][8] = $character[3][0] = $character[3][4]
	    = $character[3][8] = "\|";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[1][1] = $character[1][7] = $character[2][1]
	    = $character[2][7] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[3][7] = "_";
	$character[1][0] = $character[1][8] = $character[2][2] = $character[2][6]
	    = $character[3][0] = $character[3][8] = "\|";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(9);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[0][7] = $character[1][1] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[3][7] = "_";
	$character[1][2] = $character[1][8] = $character[2][0] = $character[2][8]
	    = $character[3][0] = $character[3][8] = "\|";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][3] = $character[1][7] = $character[2][0]
	    = $character[3][0] = $character[3][3] = $character[3][7] = "\|";
	$character[3][4] = "\\";
	$character[2][6] = "\<";
	$character[0][1] = $character[0][2] = $character[0][5] = $character[0][6]
	    = $character[3][1] = $character[3][2] = $character[3][5]
	    = $character[3][6] = "_";
	$character[1][4] = "\/";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][7] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[3][7] = "_";
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][8]
	    = $character[3][0] = $character[3][8] = "\|";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(9);
	$character[1][0] = $character[1][4] = $character[1][8] = $character[2][0]
	    = $character[2][8] = $character[3][0] = $character[3][3]
	    = $character[3][5] = $character[3][8] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[3][1] = $character[3][2] = $character[3][4]
	    = $character[3][6] = $character[3][7] = "_";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[3][1] = $character[3][2] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[3][7] = "_";
	$character[1][0] = $character[1][5] = $character[1][8] = $character[2][0]
	    = $character[2][8] = $character[3][0] = $character[3][3]
	    = $character[3][8] = "\|";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(9);
	$character[2][4] = "\-";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[3][7] = "_";
	$character[1][0] = $character[1][8] = $character[2][0] = $character[2][8]
	    = $character[3][0] = $character[3][8] = "\|";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][4]
	    = $character[1][5] = $character[2][5] = $character[2][6]
	    = $character[3][1] = $character[3][2] = $character[3][3] = "_";
	$character[1][0] = $character[2][0] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[1][7] = "\\";
	$character[2][7] = "\/";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[2][7] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[3][7] = "_";
	$character[1][0] = $character[1][8] = $character[2][0] = $character[2][8]
	    = $character[3][0] = $character[3][8] = "\|";
	$character[2][4] = "\-";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(8);
	$character[2][7] = "\<";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][4]
	    = $character[1][5] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][5] = $character[3][6] = "_";
	$character[1][7] = "\\";
	$character[1][0] = $character[2][0] = $character[3][0] = $character[3][4]
	    = $character[3][7] = "\|";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(9);
	$character[1][0] = $character[1][8] = $character[2][0] = $character[2][8]
	    = $character[3][0] = $character[3][8] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[1][6] = $character[1][7] = $character[2][1]
	    = $character[2][2] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[3][7] = "_";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[1][1] = $character[1][7] = $character[3][3]
	    = $character[3][4] = $character[3][5] = "_";
	$character[1][0] = $character[1][8] = $character[2][2] = $character[2][6]
	    = $character[3][2] = $character[3][6] = "\|";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(9);
	$character[1][0] = $character[1][4] = $character[1][8] = $character[2][0]
	    = $character[2][4] = $character[2][8] = $character[3][0]
	    = $character[3][8] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[3][7] = "_";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = "_";
	$character[1][0] = $character[1][4] = $character[1][8] = $character[2][0]
	    = $character[2][4] = $character[2][8] = "\|";
	$character[3][1] = "\\";
	$character[3][7] = "\/";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(10);
	$character[1][0] = $character[1][3] = $character[1][6] = $character[1][9]
	    = $character[2][0] = $character[2][3] = $character[2][6]
	    = $character[2][9] = $character[3][0] = $character[3][9] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[0][8] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[3][7] = $character[3][8] = "_";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(9);
	$character[2][1] = $character[2][7] = "\-";
	$character[1][0] = $character[1][4] = $character[1][8] = $character[2][0]
	    = $character[2][8] = $character[3][0] = $character[3][4]
	    = $character[3][8] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][5]
	    = $character[3][6] = $character[3][7] = "_";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(9);
	$character[2][1] = "\\";
	$character[1][0] = $character[1][4] = $character[1][8] = $character[3][2]
	    = $character[3][6] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[3][3]
	    = $character[3][4] = $character[3][5] = "_";
	$character[2][7] = "\/";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(9);
	$character[1][0] = $character[1][8] = $character[2][0] = $character[2][8]
	    = $character[3][0] = $character[3][8] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[1][1] = $character[1][2] = $character[2][6]
	    = $character[2][7] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[3][7] = "_";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(7);
	$character[2][3] = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][5] = "_";
	$character[2][0] = $character[2][6] = $character[3][0] = $character[3][6]
	    = "\|";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][5]
	    = "\-";
	$character[1][0] = $character[1][4] = $character[1][6] = $character[3][4]
	    = "\.";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][3] = $character[2][0] = $character[2][6]
	    = $character[3][0] = $character[3][6] = "\|";
	$character[0][1] = $character[0][2] = $character[2][3] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = "_";
	$character[1][6] = "\.";
	$character[1][4] = $character[1][5] = "\-";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(6);
	$character[2][3] = $character[2][4] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = "_";
	$character[2][0] = $character[2][5] = $character[3][0] = $character[3][5]
	    = "\|";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = "\-";
	$character[1][0] = $character[1][5] = "\.";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = "\.";
	$character[1][1] = $character[1][2] = "\-";
	$character[1][3] = $character[1][6] = $character[2][0] = $character[2][6]
	    = $character[3][0] = $character[3][6] = "\|";
	$character[0][4] = $character[0][5] = $character[2][3] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = "_";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(7);
	$character[2][4] = $character[2][5] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5] = "_";
	$character[2][0] = $character[2][6] = $character[3][0] = $character[3][6]
	    = "\|";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[2][3] = "\-";
	$character[1][0] = $character[1][6] = "\.";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = "\.";
	$character[1][1] = "\'";
	$character[1][5] = $character[2][0] = $character[2][5] = $character[3][0]
	    = $character[3][3] = "\|";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[1][4]
	    = $character[2][4] = $character[3][1] = $character[3][2] = "_";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(7);
	$character[2][3] = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[4][1] = $character[4][2] = $character[4][3]
	    = $character[4][4] = $character[4][5] = "_";
	$character[2][0] = $character[2][6] = $character[3][0] = $character[3][6]
	    = $character[4][0] = $character[4][6] = "\|";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = "\-";
	$character[1][0] = $character[1][6] = "\.";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][3] = $character[2][0] = $character[2][6]
	    = $character[3][0] = $character[3][3] = $character[3][6] = "\|";
	$character[0][1] = $character[0][2] = $character[3][1] = $character[3][2]
	    = $character[3][4] = $character[3][5] = "_";
	$character[1][6] = "\.";
	$character[1][4] = $character[1][5] = "\-";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[1][3] = $character[2][0] = $character[2][3]
	    = $character[3][0] = $character[3][3] = "\|";
	$character[0][1] = $character[0][2] = $character[1][1] = $character[1][2]
	    = $character[3][1] = $character[3][2] = "_";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = $character[1][4] = $character[2][1] = $character[2][4]
	    = $character[3][1] = $character[3][4] = $character[4][0]
	    = $character[4][4] = "\|";
	$character[0][2] = $character[0][3] = $character[1][2] = $character[1][3]
	    = $character[4][1] = $character[4][2] = $character[4][3] = "_";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[3][1] = $character[3][2]
	    = $character[3][4] = $character[3][5] = "_";
	$character[2][5] = "\<";
	$character[1][0] = $character[1][3] = $character[2][0] = $character[3][0]
	    = $character[3][3] = $character[3][6] = "\|";
	$character[1][4] = $character[1][5] = "\-";
	$character[1][6] = "\.";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[3][1] = $character[3][2]
	    = "_";
	$character[1][0] = $character[1][3] = $character[2][0] = $character[2][3]
	    = $character[3][0] = $character[3][3] = "\|";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(10);
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[1][6] = $character[1][7]
	    = $character[1][8] = "\-";
	$character[1][0] = $character[1][9] = "\.";
	$character[3][1] = $character[3][2] = $character[3][4] = $character[3][5]
	    = $character[3][7] = $character[3][8] = "_";
	$character[2][0] = $character[2][9] = $character[3][0] = $character[3][3]
	    = $character[3][6] = $character[3][9] = "\|";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(7);
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = "\-";
	$character[1][0] = $character[1][6] = "\.";
	$character[3][1] = $character[3][2] = $character[3][4] = $character[3][5]
	    = "_";
	$character[2][0] = $character[2][6] = $character[3][0] = $character[3][3]
	    = $character[3][6] = "\|";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(7);
	$character[2][3] = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = "_";
	$character[2][0] = $character[2][6] = $character[3][0] = $character[3][6]
	    = "\|";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = "\-";
	$character[1][0] = $character[1][6] = "\.";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][6] = "\.";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = "\-";
	$character[2][0] = $character[2][6] = $character[3][0] = $character[3][6]
	    = $character[4][0] = $character[4][3] = "\|";
	$character[2][3] = $character[3][4] = $character[3][5] = $character[4][1]
	    = $character[4][2] = "_";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(7);
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = "\-";
	$character[1][0] = $character[1][6] = "\.";
	$character[2][3] = $character[3][1] = $character[3][2] = $character[4][4]
	    = $character[4][5] = "_";
	$character[2][0] = $character[2][6] = $character[3][0] = $character[3][6]
	    = $character[4][3] = $character[4][6] = "\|";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][5] = "\.";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = "\-";
	$character[2][0] = $character[2][5] = $character[3][0] = $character[3][3]
	    = "\|";
	$character[2][4] = $character[3][1] = $character[3][2] = "_";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(7);
	$character[2][1] = $character[2][2] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5] = "_";
	$character[2][0] = $character[2][6] = $character[3][0] = $character[3][6]
	    = "\|";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[2][4] = $character[2][5] = "\-";
	$character[1][0] = $character[1][6] = "\.";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[1][4] = $character[2][4]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = "_";
	$character[1][0] = $character[1][3] = $character[2][0] = $character[2][5]
	    = $character[3][0] = $character[3][5] = "\|";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(7);
	$character[2][0] = $character[2][3] = $character[2][6] = $character[3][0]
	    = $character[3][6] = "\|";
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = "_";
	$character[1][0] = $character[1][3] = $character[1][6] = "\.";
	$character[1][1] = $character[1][2] = $character[1][4] = $character[1][5]
	    = "\-";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(7);
	$character[3][2] = $character[3][3] = $character[3][4] = "_";
	$character[3][1] = "\\";
	$character[2][0] = $character[2][3] = $character[2][6] = "\|";
	$character[3][5] = "\/";
	$character[1][1] = $character[1][2] = $character[1][4] = $character[1][5]
	    = "\-";
	$character[1][0] = $character[1][3] = $character[1][6] = "\.";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(10);
	$character[2][0] = $character[2][3] = $character[2][6] = $character[2][9]
	    = $character[3][0] = $character[3][9] = "\|";
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[3][6] = $character[3][7]
	    = $character[3][8] = "_";
	$character[1][0] = $character[1][3] = $character[1][6] = $character[1][9]
	    = "\.";
	$character[1][1] = $character[1][2] = $character[1][4] = $character[1][5]
	    = $character[1][7] = $character[1][8] = "\-";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(7);
	$character[2][1] = $character[2][5] = $character[3][1] = $character[3][2]
	    = $character[3][4] = $character[3][5] = "_";
	$character[2][0] = $character[2][6] = $character[3][0] = $character[3][6]
	    = "\|";
	$character[1][1] = $character[1][2] = $character[1][4] = $character[1][5]
	    = "\-";
	$character[1][0] = $character[1][3] = $character[1][6] = $character[3][3]
	    = "\.";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(7);
	$character[2][0] = $character[2][3] = $character[2][6] = $character[3][0]
	    = $character[3][6] = $character[4][0] = $character[4][6] = "\|";
	$character[3][1] = $character[3][2] = $character[3][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = "_";
	$character[1][0] = $character[1][3] = $character[1][6] = "\.";
	$character[1][1] = $character[1][2] = $character[1][4] = $character[1][5]
	    = "\-";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(7);
	$character[2][4] = $character[2][5] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5] = "_";
	$character[2][0] = $character[2][6] = $character[3][0] = $character[3][6]
	    = "\|";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[2][1] = $character[2][2] = "\-";
	$character[1][0] = $character[1][6] = "\.";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[3][6] = "_";
	$character[1][0] = $character[1][7] = $character[2][0] = $character[2][7]
	    = $character[3][0] = $character[3][7] = "\|";
	$character[2][3] = $character[2][4] = "\-";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][5] = $character[2][2] = $character[2][5]
	    = $character[3][0] = $character[3][7] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[1][1] = $character[2][1] = $character[2][6]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][7] = $character[2][0] = $character[2][7]
	    = $character[3][0] = $character[3][7] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][1]
	    = $character[1][2] = $character[2][5] = $character[2][6]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][1]
	    = $character[1][2] = $character[2][1] = $character[2][2]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	$character[1][0] = $character[1][7] = $character[2][0] = $character[2][7]
	    = $character[3][0] = $character[3][7] = "\|";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][3] = $character[1][6] = $character[2][0]
	    = $character[2][7] = $character[3][3] = $character[3][6] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[2][1] = $character[2][2]
	    = $character[3][4] = $character[3][5] = "_";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][5]
	    = $character[1][6] = $character[2][1] = $character[2][2]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	$character[1][0] = $character[1][7] = $character[2][0] = $character[2][7]
	    = $character[3][0] = $character[3][7] = "\|";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][5]
	    = $character[1][6] = $character[2][3] = $character[2][4]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	$character[1][0] = $character[1][7] = $character[2][0] = $character[2][7]
	    = $character[3][0] = $character[3][7] = "\|";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[2][1]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = "_";
	$character[1][0] = $character[1][7] = $character[2][0] = $character[2][7]
	    = $character[3][2] = $character[3][7] = "\|";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][3]
	    = $character[1][4] = $character[2][3] = $character[2][4]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	$character[1][0] = $character[1][7] = $character[2][0] = $character[2][7]
	    = $character[3][0] = $character[3][7] = "\|";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][7] = $character[2][0] = $character[2][7]
	    = $character[3][0] = $character[3][7] = "\|";
	$character[4][0] = "\
";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][3]
	    = $character[1][4] = $character[2][1] = $character[2][2]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Chunky - Chunky font

=head1 VERSION

Version 0.19

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	use Ascii::Text::Font::Chunky;

	my $foo = Ascii::Text::Font::Chunky->new();

	...

=head1 SUBROUTINES/METHODS

=head2 character_A

	 _______ 
	|   _   |
	|       |
	|___|___|
	         

=head2 character_B

	 ______ 
	|   __ \
	|   __ <
	|______/
	        

=head2 character_C

	 ______ 
	|      |
	|   ---|
	|______|
	        

=head2 character_D

	 _____  
	|     \ 
	|  --  |
	|_____/ 
	        

=head2 character_E

	 _______ 
	|    ___|
	|    ___|
	|_______|
	         

=head2 character_F

	 _______ 
	|    ___|
	|    ___|
	|___|    
	         

=head2 character_G

	 _______ 
	|     __|
	|    |  |
	|_______|
	         

=head2 character_H

	 _______ 
	|   |   |
	|       |
	|___|___|
	         

=head2 character_I

	 _______ 
	|_     _|
	 _|   |_ 
	|_______|
	         

=head2 character_J

	   _____ 
	 _|     |
	|       |
	|_______|
	         

=head2 character_K

	 __  __ 
	|  |/  |
	|     < 
	|__|\__|
	        

=head2 character_L

	 _____   
	|     |_ 
	|       |
	|_______|
	         

=head2 character_M

	 _______ 
	|   |   |
	|       |
	|__|_|__|
	         

=head2 character_N

	 _______ 
	|    |  |
	|       |
	|__|____|
	         

=head2 character_O

	 _______ 
	|       |
	|   -   |
	|_______|
	         

=head2 character_P

	 ______ 
	|   __ \
	|    __/
	|___|   
	        

=head2 character_Q

	 _______ 
	|       |
	|   -  _|
	|_______|
	         

=head2 character_R

	 ______ 
	|   __ \
	|      <
	|___|__|
	        

=head2 character_S

	 _______ 
	|     __|
	|__     |
	|_______|
	         

=head2 character_T

	 _______ 
	|_     _|
	  |   |  
	  |___|  
	         

=head2 character_U

	 _______ 
	|   |   |
	|   |   |
	|_______|
	         

=head2 character_V

	 ___ ___ 
	|   |   |
	|   |   |
	 \_____/ 
	         

=head2 character_W

	 ________ 
	|  |  |  |
	|  |  |  |
	|________|
	          

=head2 character_X

	 ___ ___ 
	|   |   |
	|-     -|
	|___|___|
	         

=head2 character_Y

	 ___ ___ 
	|   |   |
	 \     / 
	  |___|  
	         

=head2 character_Z

	 _______ 
	|__     |
	|     __|
	|_______|
	         

=head2 character_a

	       
	.---.-.
	|  _  |
	|___._|
	       

=head2 character_b

	 __    
	|  |--.
	|  _  |
	|_____|
	       

=head2 character_c

	      
	.----.
	|  __|
	|____|
	      

=head2 character_d

	    __ 
	.--|  |
	|  _  |
	|_____|
	       

=head2 character_e

	       
	.-----.
	|  -__|
	|_____|
	       

=head2 character_f

	  ___ 
	.'  _|
	|   _|
	|__|  
	      

=head2 character_g

	       
	.-----.
	|  _  |
	|___  |
	|_____|

=head2 character_h

	 __    
	|  |--.
	|     |
	|__|__|
	       

=head2 character_i

	 __ 
	|__|
	|  |
	|__|
	    

=head2 character_j

	  __ 
	 |__|
	 |  |
	 |  |
	|___|

=head2 character_k

	 __    
	|  |--.
	|    < 
	|__|__|
	       

=head2 character_l

	 __ 
	|  |
	|  |
	|__|
	    

=head2 character_m

	          
	.--------.
	|        |
	|__|__|__|
	          

=head2 character_n

	       
	.-----.
	|     |
	|__|__|
	       

=head2 character_o

	       
	.-----.
	|  _  |
	|_____|
	       

=head2 character_p

	       
	.-----.
	|  _  |
	|   __|
	|__|   

=head2 character_q

	       
	.-----.
	|  _  |
	|__   |
	   |__|

=head2 character_r

	      
	.----.
	|   _|
	|__|  
	      

=head2 character_s

	       
	.-----.
	|__ --|
	|_____|
	       

=head2 character_t

	 __   
	|  |_ 
	|   _|
	|____|
	      

=head2 character_u

	       
	.--.--.
	|  |  |
	|_____|
	       

=head2 character_v

	       
	.--.--.
	|  |  |
	 \___/ 
	       

=head2 character_w

	          
	.--.--.--.
	|  |  |  |
	|________|
	          

=head2 character_x

	       
	.--.--.
	|_   _|
	|__.__|
	       

=head2 character_y

	       
	.--.--.
	|  |  |
	|___  |
	|_____|

=head2 character_z

	       
	.-----.
	|-- __|
	|_____|
	       

=head2 character_0

	 ______ 
	|      |
	|  --  |
	|______|
	        

=head2 character_1

	 ____   
	|_   |  
	 _|  |_ 
	|______|
	        

=head2 character_2

	 ______ 
	|__    |
	|    __|
	|______|
	        

=head2 character_3

	 ______ 
	|__    |
	|__    |
	|______|
	        

=head2 character_4

	 _____  
	|  |  | 
	|__    |
	   |__| 
	        

=head2 character_5

	 ______ 
	|    __|
	|__    |
	|______|
	        

=head2 character_6

	 ______ 
	|    __|
	|  __  |
	|______|
	        

=head2 character_7

	 ______ 
	|      |
	|_     |
	  |____|
	        

=head2 character_8

	 ______ 
	|  __  |
	|  __  |
	|______|
	        

=head2 character_9

	 ______ 
	|  __  |
	|__    |
	|______|
	


=head1 EXTENDS

=head2 Ascii::Text::Font



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::chunky at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Chunky>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Chunky

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Chunky>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Chunky>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Chunky>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Chunky>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
