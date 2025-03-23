package Ascii::Text::Font::Doom;
use strict;
use warnings;
use Rope;
use Rope::Autoload;

# DOOM by Frans P. de Vries <fpv@xymph.iaf.nl>  18 Jun 1996
# based on Big by Glenn Chappell 4/93 -- based on Standard
# Permission is hereby given to modify this font, as long as the
# modifier's name is placed on a comment line.

extends 'Ascii::Text::Font';

property character_height => (
	initable => 0,
	writable => 0,
	value => 8,
);

function space => sub {
	my @character = $_[0]->default_character(7);
	return \@character;
};

function character_A => sub {
	my @character = $_[0]->default_character(7);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[1][3]
	    = $character[2][3] = $character[3][3] = $character[5][1]
	    = $character[5][5] = "_";
	$character[1][1] = $character[2][0] = $character[2][2] = $character[5][6]
	    = "\/";
	$character[1][5] = $character[2][4] = $character[2][6] = $character[5][0]
	    = "\\";
	$character[3][0] = $character[3][6] = $character[4][0] = $character[4][2]
	    = $character[4][4] = $character[4][6] = $character[5][2]
	    = $character[5][4] = "\|";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[2][0] = $character[2][2] = $character[3][0]
	    = $character[4][0] = $character[4][2] = "\|";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[1][2]
	    = $character[1][3] = $character[1][4] = $character[2][3]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[4][3] = $character[5][1] = $character[5][2]
	    = $character[5][3] = $character[5][4] = "_";
	$character[2][4] = $character[2][6] = $character[4][4] = $character[4][6]
	    = $character[5][5] = "\/";
	$character[1][6] = $character[3][6] = $character[5][0] = "\\";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(7);
	$character[2][0] = $character[3][0] = $character[3][2] = $character[4][0]
	    = "\|";
	$character[1][0] = $character[2][2] = $character[2][6] = $character[4][5]
	    = $character[5][6] = "\/";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][3] = $character[1][4]
	    = $character[4][3] = $character[4][4] = $character[5][2]
	    = $character[5][3] = $character[5][4] = $character[5][5] = "_";
	$character[1][6] = $character[2][5] = $character[4][2] = $character[4][6]
	    = $character[5][1] = "\\";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(7);
	$character[4][3] = $character[4][5] = $character[5][4] = "\/";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[1][3]
	    = $character[5][1] = $character[5][2] = $character[5][3] = "_";
	$character[1][6] = "\\";
	$character[1][0] = $character[2][0] = $character[2][2] = $character[2][4]
	    = $character[2][6] = $character[3][0] = $character[3][2]
	    = $character[3][4] = $character[3][6] = $character[4][0]
	    = $character[4][2] = $character[5][0] = "\|";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2]
	    = $character[3][0] = $character[3][5] = $character[4][0]
	    = $character[4][2] = "\|";
	$character[5][0] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[2][3] = $character[2][4]
	    = $character[3][3] = $character[3][4] = $character[4][3]
	    = $character[4][4] = $character[4][5] = $character[5][1]
	    = $character[5][2] = $character[5][3] = $character[5][4] = "_";
	$character[5][5] = "\/";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(7);
	$character[5][0] = "\\";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[1][3]
	    = $character[1][4] = $character[1][5] = $character[2][3]
	    = $character[3][3] = $character[5][1] = "_";
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2]
	    = $character[3][0] = $character[3][4] = $character[4][0]
	    = $character[4][2] = $character[5][2] = "\|";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(7);
	$character[1][6] = $character[2][5] = $character[4][4] = $character[4][6]
	    = $character[5][1] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][3] = $character[1][4]
	    = $character[3][4] = $character[3][5] = $character[4][3]
	    = $character[5][2] = $character[5][3] = $character[5][4]
	    = $character[5][5] = "_";
	$character[2][6] = $character[5][6] = "\/";
	$character[1][0] = $character[2][0] = $character[2][2] = $character[3][0]
	    = $character[3][2] = $character[4][0] = $character[4][2] = "\|";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][2] = $character[1][4] = $character[1][6]
	    = $character[2][0] = $character[2][2] = $character[2][4]
	    = $character[2][6] = $character[3][0] = $character[3][6]
	    = $character[4][0] = $character[4][2] = $character[4][4]
	    = $character[4][6] = $character[5][2] = $character[5][4] = "\|";
	$character[5][6] = "\/";
	$character[0][1] = $character[0][5] = $character[2][3] = $character[3][3]
	    = $character[5][1] = $character[5][5] = "_";
	$character[5][0] = "\\";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(7);
	$character[5][1] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][1] = $character[1][5]
	    = $character[4][1] = $character[4][5] = $character[5][2]
	    = $character[5][3] = $character[5][4] = "_";
	$character[5][5] = "\/";
	$character[1][0] = $character[1][6] = $character[2][2] = $character[2][4]
	    = $character[3][2] = $character[3][4] = $character[4][2]
	    = $character[4][4] = "\|";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(7);
	$character[2][2] = "\$";
	$character[4][1] = $character[5][0] = "\\";
	$character[4][0] = $character[4][4] = $character[4][6] = $character[5][5]
	    = "\/";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[1][3]
	    = $character[4][2] = $character[4][3] = $character[5][1]
	    = $character[5][2] = $character[5][3] = $character[5][4] = "_";
	$character[1][2] = $character[1][6] = $character[2][4] = $character[2][6]
	    = $character[3][4] = $character[3][6] = "\|";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(7);
	$character[1][4] = $character[1][6] = $character[2][3] = $character[2][5]
	    = $character[5][6] = "\/";
	$character[0][1] = $character[0][5] = $character[0][6] = $character[5][1]
	    = $character[5][5] = "_";
	$character[3][5] = $character[4][3] = $character[4][6] = $character[5][0]
	    = $character[5][4] = "\\";
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2]
	    = $character[3][0] = $character[4][0] = $character[4][2]
	    = $character[5][2] = "\|";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(7);
	$character[1][4] = $character[2][4] = "\$";
	$character[5][6] = "\/";
	$character[0][1] = $character[4][3] = $character[4][4] = $character[4][5]
	    = $character[4][6] = $character[5][1] = $character[5][2]
	    = $character[5][3] = $character[5][4] = $character[5][5] = "_";
	$character[5][0] = "\\";
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2]
	    = $character[3][0] = $character[3][2] = $character[4][0]
	    = $character[4][2] = "\|";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(8);
	$character[1][4] = $character[3][4] = $character[5][7] = "\/";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[5][1]
	    = $character[5][6] = "_";
	$character[1][3] = $character[3][3] = $character[5][0] = "\\";
	$character[2][2] = $character[2][5] = "\.";
	$character[1][0] = $character[1][7] = $character[2][0] = $character[2][7]
	    = $character[3][0] = $character[3][2] = $character[3][5]
	    = $character[3][7] = $character[4][0] = $character[4][2]
	    = $character[4][5] = $character[4][7] = $character[5][2]
	    = $character[5][5] = "\|";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(7);
	$character[5][6] = "\/";
	$character[3][4] = "\`";
	$character[1][2] = $character[2][3] = $character[4][3] = $character[5][0]
	    = $character[5][4] = "\\";
	$character[3][2] = "\.";
	$character[0][1] = $character[0][5] = $character[5][1] = $character[5][5]
	    = "_";
	$character[1][0] = $character[1][4] = $character[1][6] = $character[2][0]
	    = $character[2][4] = $character[2][6] = $character[3][0]
	    = $character[3][6] = $character[4][0] = $character[4][2]
	    = $character[4][6] = $character[5][2] = "\|";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(7);
	$character[4][4] = $character[4][6] = $character[5][5] = "\/";
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2]
	    = $character[2][4] = $character[2][6] = $character[3][0]
	    = $character[3][2] = $character[3][4] = $character[3][6] = "\|";
	$character[4][0] = $character[4][2] = $character[5][1] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][3] = $character[4][3]
	    = $character[5][2] = $character[5][3] = $character[5][4] = "_";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[2][0] = $character[2][2] = $character[3][0]
	    = $character[4][0] = $character[4][2] = $character[5][2] = "\|";
	$character[1][6] = $character[5][0] = "\\";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[1][2]
	    = $character[1][3] = $character[1][4] = $character[2][3]
	    = $character[3][3] = $character[3][4] = $character[5][1] = "_";
	$character[2][4] = $character[2][6] = $character[3][5] = "\/";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(7);
	$character[4][4] = "\'";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][3] = $character[5][2]
	    = $character[5][5] = "_";
	$character[4][0] = $character[4][2] = $character[5][1] = $character[5][4]
	    = $character[5][6] = "\\";
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2]
	    = $character[2][4] = $character[2][6] = $character[3][0]
	    = $character[3][2] = $character[3][4] = $character[3][6] = "\|";
	$character[4][3] = $character[4][6] = $character[5][3] = "\/";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[2][0] = $character[2][2] = $character[3][0]
	    = $character[4][0] = $character[4][2] = $character[5][2]
	    = $character[5][6] = "\|";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3]
	    = $character[0][4] = $character[0][5] = $character[1][2]
	    = $character[1][3] = $character[1][4] = $character[2][3]
	    = $character[5][1] = $character[5][5] = "_";
	$character[1][6] = $character[4][3] = $character[4][5] = $character[5][0]
	    = $character[5][4] = "\\";
	$character[2][4] = $character[2][6] = $character[3][5] = "\/";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[4][0] = $character[4][4] = $character[4][6]
	    = $character[5][5] = "\/";
	$character[2][2] = $character[3][1] = "\`";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[4][2] = $character[4][3]
	    = $character[5][1] = $character[5][2] = $character[5][3]
	    = $character[5][4] = "_";
	$character[2][5] = $character[3][4] = "\.";
	$character[2][3] = $character[2][4] = $character[3][2] = $character[3][3]
	    = "\-";
	$character[2][0] = $character[3][6] = $character[4][1] = $character[5][0]
	    = "\\";
	$character[1][6] = "\|";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(7);
	$character[5][4] = "\/";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][1] = $character[1][5]
	    = $character[5][3] = "_";
	$character[5][2] = "\\";
	$character[1][0] = $character[1][6] = $character[2][2] = $character[2][4]
	    = $character[3][2] = $character[3][4] = $character[4][2]
	    = $character[4][4] = "\|";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(7);
	$character[5][1] = "\\";
	$character[0][1] = $character[0][5] = $character[4][3] = $character[5][2]
	    = $character[5][3] = $character[5][4] = "_";
	$character[1][0] = $character[1][2] = $character[1][4] = $character[1][6]
	    = $character[2][0] = $character[2][2] = $character[2][4]
	    = $character[2][6] = $character[3][0] = $character[3][2]
	    = $character[3][4] = $character[3][6] = $character[4][0]
	    = $character[4][2] = $character[4][4] = $character[4][6] = "\|";
	$character[5][5] = "\/";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(7);
	$character[4][4] = $character[4][6] = $character[5][5] = "\/";
	$character[1][0] = $character[1][2] = $character[1][4] = $character[1][6]
	    = $character[2][0] = $character[2][2] = $character[2][4]
	    = $character[2][6] = $character[3][0] = $character[3][2]
	    = $character[3][4] = $character[3][6] = "\|";
	$character[0][1] = $character[0][5] = $character[4][3] = $character[5][2]
	    = $character[5][3] = $character[5][4] = "_";
	$character[4][0] = $character[4][2] = $character[5][1] = "\\";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(8);
	$character[1][0] = $character[1][2] = $character[1][5] = $character[1][7]
	    = $character[2][0] = $character[2][2] = $character[2][5]
	    = $character[2][7] = $character[3][0] = $character[3][2]
	    = $character[3][5] = $character[3][7] = "\|";
	$character[0][1] = $character[0][6] = "_";
	$character[3][4] = $character[4][0] = $character[4][4] = $character[5][1]
	    = $character[5][5] = "\\";
	$character[3][3] = $character[4][3] = $character[4][7] = $character[5][2]
	    = $character[5][6] = "\/";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][2] = $character[2][1] = $character[3][5]
	    = $character[4][4] = $character[4][6] = $character[5][0]
	    = $character[5][5] = "\\";
	$character[2][3] = "V";
	$character[0][0] = $character[0][1] = $character[0][5] = $character[0][6]
	    = "_";
	$character[4][3] = "\^";
	$character[1][4] = $character[1][6] = $character[2][5] = $character[3][1]
	    = $character[4][0] = $character[4][2] = $character[5][1]
	    = $character[5][6] = "\/";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][2] = $character[2][1] = $character[3][2]
	    = $character[5][2] = "\\";
	$character[0][0] = $character[0][1] = $character[0][5] = $character[0][6]
	    = $character[5][3] = "_";
	$character[2][3] = "V";
	$character[4][2] = $character[4][4] = "\|";
	$character[1][4] = $character[1][6] = $character[2][5] = $character[3][4]
	    = $character[5][4] = "\/";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(7);
	$character[1][6] = $character[2][3] = $character[2][5] = $character[3][2]
	    = $character[3][4] = $character[4][1] = $character[4][3]
	    = $character[5][6] = "\/";
	$character[2][2] = "\$";
	$character[4][0] = "\.";
	$character[5][0] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][1]
	    = $character[1][2] = $character[1][3] = $character[4][4]
	    = $character[4][5] = $character[4][6] = $character[5][1]
	    = $character[5][2] = $character[5][3] = $character[5][4]
	    = $character[5][5] = "_";
	$character[1][0] = "\|";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(7);
	$character[3][1] = "\/";
	$character[5][4] = "\,";
	$character[3][4] = "\`";
	$character[5][1] = "\\";
	$character[4][2] = "\(";
	$character[2][2] = $character[2][3] = $character[2][5] = $character[3][3]
	    = $character[4][3] = $character[5][2] = $character[5][3]
	    = $character[5][5] = "_";
	$character[3][6] = $character[4][0] = $character[4][4] = $character[4][6]
	    = $character[5][6] = "\|";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(7);
	$character[3][5] = "\\";
	$character[5][2] = "\.";
	$character[0][1] = $character[2][3] = $character[2][4] = $character[3][3]
	    = $character[4][3] = $character[5][1] = $character[5][3]
	    = $character[5][4] = "_";
	$character[3][2] = "\'";
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2]
	    = $character[3][0] = $character[4][0] = $character[4][2]
	    = $character[4][6] = $character[5][0] = "\|";
	$character[4][4] = "\)";
	$character[5][5] = "\/";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[5][1] = "\\";
	$character[2][2] = $character[2][3] = $character[2][4] = $character[3][3]
	    = $character[3][4] = $character[4][3] = $character[4][4]
	    = $character[5][2] = $character[5][3] = $character[5][4] = "_";
	$character[4][2] = "\(";
	$character[3][5] = $character[4][0] = $character[5][5] = "\|";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(7);
	$character[3][1] = "\/";
	$character[5][4] = "\,";
	$character[3][4] = "\`";
	$character[0][5] = $character[2][2] = $character[2][3] = $character[3][3]
	    = $character[4][3] = $character[5][2] = $character[5][3]
	    = $character[5][5] = "_";
	$character[4][2] = "\(";
	$character[5][1] = "\\";
	$character[1][4] = $character[1][6] = $character[2][4] = $character[2][6]
	    = $character[3][6] = $character[4][0] = $character[4][4]
	    = $character[4][6] = $character[5][6] = "\|";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = $character[4][5] = "\/";
	$character[4][0] = $character[5][5] = "\|";
	$character[2][2] = $character[2][3] = $character[2][4] = $character[3][3]
	    = $character[4][3] = $character[4][4] = $character[5][2]
	    = $character[5][3] = $character[5][4] = "_";
	$character[3][5] = $character[5][1] = "\\";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = "\/";
	$character[0][2] = $character[0][3] = $character[1][3] = $character[2][3]
	    = $character[3][3] = $character[5][1] = "_";
	$character[1][4] = $character[2][0] = $character[2][2] = $character[3][0]
	    = $character[3][4] = $character[4][0] = $character[4][2]
	    = $character[5][0] = $character[5][2] = "\|";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(7);
	$character[5][1] = "\\";
	$character[4][2] = "\(";
	$character[2][2] = $character[2][3] = $character[2][5] = $character[3][3]
	    = $character[4][3] = $character[5][2] = $character[5][3]
	    = $character[6][2] = $character[6][3] = $character[7][2]
	    = $character[7][3] = $character[7][4] = "_";
	$character[3][6] = $character[4][0] = $character[4][4] = $character[4][6]
	    = $character[5][6] = $character[6][6] = $character[7][1] = "\|";
	$character[3][1] = $character[6][4] = $character[7][5] = "\/";
	$character[5][4] = "\,";
	$character[3][4] = "\`";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2]
	    = $character[3][0] = $character[4][0] = $character[4][2]
	    = $character[4][4] = $character[4][6] = $character[5][0]
	    = $character[5][2] = $character[5][4] = $character[5][6] = "\|";
	$character[3][2] = "\'";
	$character[3][5] = "\\";
	$character[0][1] = $character[2][3] = $character[2][4] = $character[3][3]
	    = $character[5][1] = $character[5][5] = "_";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(3);
	$character[0][1] = $character[1][1] = $character[2][1] = $character[5][1]
	    = "_";
	$character[1][0] = "\(";
	$character[3][0] = $character[3][2] = $character[4][0] = $character[4][2]
	    = $character[5][0] = $character[5][2] = "\|";
	$character[1][2] = "\)";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(5);
	$character[1][4] = "\)";
	$character[3][2] = $character[3][4] = $character[4][2] = $character[4][4]
	    = $character[5][2] = $character[5][4] = $character[6][4]
	    = $character[7][0] = "\|";
	$character[0][3] = $character[1][3] = $character[2][3] = $character[6][1]
	    = $character[7][1] = $character[7][2] = "_";
	$character[1][2] = "\(";
	$character[6][2] = $character[7][3] = "\/";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2]
	    = $character[3][0] = $character[3][2] = $character[4][0]
	    = $character[5][0] = $character[5][2] = "\|";
	$character[0][1] = $character[2][4] = $character[2][5] = $character[5][1]
	    = $character[5][4] = "_";
	$character[5][3] = $character[5][5] = "\\";
	$character[4][4] = "\<";
	$character[3][3] = $character[3][5] = "\/";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(3);
	$character[0][1] = $character[5][1] = "_";
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2]
	    = $character[3][0] = $character[3][2] = $character[4][0]
	    = $character[4][2] = $character[5][0] = $character[5][2] = "\|";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(11);
	$character[3][5] = "\`";
	$character[3][0] = $character[4][0] = $character[4][2] = $character[4][4]
	    = $character[4][6] = $character[4][8] = $character[4][10]
	    = $character[5][0] = $character[5][2] = $character[5][4]
	    = $character[5][6] = $character[5][8] = $character[5][10] = "\|";
	$character[3][2] = "\'";
	$character[2][1] = $character[2][3] = $character[2][4] = $character[2][6]
	    = $character[2][7] = $character[2][8] = $character[3][3]
	    = $character[3][7] = $character[5][1] = $character[5][5]
	    = $character[5][9] = "_";
	$character[3][9] = "\\";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(7);
	$character[3][5] = "\\";
	$character[2][1] = $character[2][3] = $character[2][4] = $character[3][3]
	    = $character[5][1] = $character[5][5] = "_";
	$character[3][2] = "\'";
	$character[3][0] = $character[4][0] = $character[4][2] = $character[4][4]
	    = $character[4][6] = $character[5][0] = $character[5][2]
	    = $character[5][4] = $character[5][6] = "\|";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(7);
	$character[4][4] = "\)";
	$character[4][0] = $character[4][6] = "\|";
	$character[3][5] = $character[5][1] = "\\";
	$character[4][2] = "\(";
	$character[2][2] = $character[2][3] = $character[2][4] = $character[3][3]
	    = $character[4][3] = $character[5][2] = $character[5][3]
	    = $character[5][4] = "_";
	$character[3][1] = $character[5][5] = "\/";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(7);
	$character[5][5] = "\/";
	$character[2][1] = $character[2][3] = $character[2][4] = $character[3][3]
	    = $character[4][3] = $character[5][3] = $character[5][4]
	    = $character[7][1] = "_";
	$character[3][5] = "\\";
	$character[5][2] = "\.";
	$character[3][2] = "\'";
	$character[4][4] = "\)";
	$character[3][0] = $character[4][0] = $character[4][2] = $character[4][6]
	    = $character[5][0] = $character[6][0] = $character[6][2]
	    = $character[7][0] = $character[7][2] = "\|";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(7);
	$character[2][2] = $character[2][3] = $character[2][5] = $character[3][3]
	    = $character[4][3] = $character[5][2] = $character[5][3]
	    = $character[7][5] = "_";
	$character[4][2] = "\(";
	$character[5][1] = "\\";
	$character[3][6] = $character[4][0] = $character[4][4] = $character[4][6]
	    = $character[5][6] = $character[6][4] = $character[6][6]
	    = $character[7][4] = $character[7][6] = "\|";
	$character[3][1] = "\/";
	$character[3][4] = "\`";
	$character[5][4] = "\,";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(6);
	$character[3][0] = $character[3][5] = $character[4][0] = $character[4][2]
	    = $character[5][0] = $character[5][2] = "\|";
	$character[2][1] = $character[2][3] = $character[2][4] = $character[3][3]
	    = $character[3][4] = $character[5][1] = "_";
	$character[3][2] = "\'";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(5);
	$character[3][0] = $character[5][4] = "\/";
	$character[3][4] = $character[5][0] = "\|";
	$character[4][0] = $character[4][4] = "\\";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = $character[4][1] = $character[4][2]
	    = $character[5][1] = $character[5][2] = $character[5][3] = "_";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(5);
	$character[5][1] = "\\";
	$character[0][1] = $character[2][3] = $character[3][2] = $character[3][3]
	    = $character[4][3] = $character[5][2] = $character[5][3] = "_";
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2]
	    = $character[3][0] = $character[3][4] = $character[4][0]
	    = $character[4][2] = $character[5][4] = "\|";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(7);
	$character[5][4] = "\,";
	$character[3][0] = $character[3][2] = $character[3][4] = $character[3][6]
	    = $character[4][0] = $character[4][2] = $character[4][4]
	    = $character[4][6] = $character[5][6] = "\|";
	$character[5][1] = "\\";
	$character[2][1] = $character[2][5] = $character[4][3] = $character[5][2]
	    = $character[5][3] = $character[5][5] = "_";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(7);
	$character[3][4] = $character[3][6] = $character[4][5] = $character[5][4]
	    = "\/";
	$character[2][0] = $character[2][1] = $character[2][5] = $character[2][6]
	    = $character[5][3] = "_";
	$character[4][3] = "V";
	$character[3][0] = $character[3][2] = $character[4][1] = $character[5][2]
	    = "\\";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(10);
	$character[3][4] = $character[3][7] = $character[3][9] = $character[4][8]
	    = $character[5][4] = $character[5][7] = "\/";
	$character[4][3] = $character[4][6] = "V";
	$character[2][0] = $character[2][1] = $character[2][8] = $character[2][9]
	    = $character[5][3] = $character[5][6] = "_";
	$character[3][0] = $character[3][2] = $character[3][5] = $character[4][1]
	    = $character[5][2] = $character[5][5] = "\\";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(6);
	$character[4][1] = "\>";
	$character[3][3] = $character[3][5] = $character[5][0] = $character[5][2]
	    = "\/";
	$character[4][4] = "\<";
	$character[2][0] = $character[2][1] = $character[2][4] = $character[2][5]
	    = $character[5][1] = $character[5][4] = "_";
	$character[3][0] = $character[3][2] = $character[5][3] = $character[5][5]
	    = "\\";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(7);
	$character[5][4] = "\,";
	$character[6][4] = $character[7][5] = "\/";
	$character[3][0] = $character[3][2] = $character[3][4] = $character[3][6]
	    = $character[4][0] = $character[4][2] = $character[4][4]
	    = $character[4][6] = $character[5][6] = $character[6][6]
	    = $character[7][1] = "\|";
	$character[5][1] = "\\";
	$character[2][1] = $character[2][5] = $character[4][3] = $character[5][2]
	    = $character[5][3] = $character[6][2] = $character[6][3]
	    = $character[7][2] = $character[7][3] = $character[7][4] = "_";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(5);
	$character[3][0] = $character[5][4] = "\|";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[3][1] = $character[5][1] = $character[5][2]
	    = $character[5][3] = "_";
	$character[3][4] = $character[4][1] = $character[4][3] = $character[5][0]
	    = "\/";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(7);
	$character[2][4] = "\'";
	$character[4][0] = $character[5][1] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][3] = $character[4][3]
	    = $character[5][2] = $character[5][3] = $character[5][4] = "_";
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2]
	    = $character[2][6] = $character[3][0] = $character[3][4]
	    = $character[3][6] = $character[4][2] = "\|";
	$character[2][3] = $character[3][3] = $character[4][4] = $character[4][6]
	    = $character[5][5] = "\/";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(5);
	$character[2][0] = "\`";
	$character[1][0] = $character[5][4] = "\/";
	$character[1][3] = $character[2][1] = $character[2][3] = $character[3][1]
	    = $character[3][3] = $character[4][1] = $character[4][3] = "\|";
	$character[0][1] = $character[0][2] = $character[4][0] = $character[4][4]
	    = $character[5][1] = $character[5][2] = $character[5][3] = "_";
	$character[5][0] = "\\";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(7);
	$character[2][0] = "\`";
	$character[1][0] = $character[2][3] = $character[2][5] = $character[3][2]
	    = $character[3][4] = $character[4][1] = $character[4][3]
	    = $character[5][6] = "\/";
	$character[2][1] = $character[2][6] = "\'";
	$character[4][0] = "\.";
	$character[1][6] = $character[5][0] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][2] = $character[1][3]
	    = $character[4][4] = $character[4][5] = $character[4][6]
	    = $character[5][1] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = "_";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(7);
	$character[2][4] = $character[2][6] = $character[4][4] = $character[4][6]
	    = $character[5][5] = "\/";
	$character[3][2] = "\$";
	$character[1][0] = $character[1][6] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][1] = $character[1][2]
	    = $character[1][3] = $character[1][4] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[5][1]
	    = $character[5][2] = $character[5][3] = $character[5][4] = "_";
	$character[3][4] = $character[3][6] = $character[5][0] = "\\";
	$character[4][0] = "\.";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(7);
	$character[1][6] = $character[2][4] = $character[2][6] = $character[3][4]
	    = $character[3][6] = $character[4][6] = $character[5][4] = "\|";
	$character[4][0] = "\\";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[3][3]
	    = $character[4][1] = $character[4][2] = $character[4][3]
	    = $character[5][5] = "_";
	$character[1][2] = $character[2][1] = $character[2][3] = $character[3][0]
	    = $character[3][2] = $character[5][6] = "\/";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(7);
	$character[2][5] = $character[3][4] = $character[3][6] = $character[4][1]
	    = $character[5][0] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][3] = $character[1][4]
	    = $character[1][5] = $character[2][1] = $character[2][2]
	    = $character[2][3] = $character[4][2] = $character[4][3]
	    = $character[5][1] = $character[5][2] = $character[5][3]
	    = $character[5][4] = "_";
	$character[1][0] = $character[1][6] = $character[2][0] = "\|";
	$character[4][0] = $character[4][4] = $character[4][6] = $character[5][5]
	    = "\/";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(7);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[4][3] = $character[5][1] = $character[5][2]
	    = $character[5][3] = $character[5][4] = $character[5][5] = "_";
	$character[3][6] = $character[4][2] = $character[5][0] = "\\";
	$character[1][6] = $character[3][0] = $character[4][0] = $character[4][6]
	    = "\|";
	$character[1][1] = $character[2][0] = $character[2][2] = $character[4][4]
	    = $character[5][6] = "\/";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(7);
	$character[1][6] = $character[2][3] = $character[2][5] = $character[3][2]
	    = $character[3][4] = $character[4][1] = $character[4][3]
	    = $character[5][2] = "\/";
	$character[2][2] = "\$";
	$character[1][0] = "\|";
	$character[4][0] = "\.";
	$character[5][0] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[0][6] = $character[1][1]
	    = $character[1][2] = $character[1][3] = $character[5][1] = "_";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][6] = $character[4][0] = $character[4][2]
	    = $character[4][4] = $character[4][6] = "\|";
	$character[2][3] = "V";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][3] = $character[3][3]
	    = $character[4][3] = $character[5][1] = $character[5][2]
	    = $character[5][3] = $character[5][4] = $character[5][5] = "_";
	$character[2][1] = $character[3][5] = $character[5][0] = "\\";
	$character[2][5] = $character[3][1] = $character[5][6] = "\/";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(7);
	$character[4][4] = $character[4][6] = $character[5][5] = "\/";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[0][5] = $character[1][3] = $character[2][3]
	    = $character[3][1] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[4][1] = $character[4][2]
	    = $character[4][3] = $character[5][1] = $character[5][2]
	    = $character[5][3] = $character[5][4] = "_";
	$character[3][0] = $character[5][0] = "\\";
	$character[4][0] = "\.";
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2]
	    = $character[2][4] = $character[2][6] = $character[3][6] = "\|";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Doom - Doom font

=head1 VERSION

Version 0.21

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use Ascii::Text::Font::Doom;

	my $foo = Ascii::Text::Font::Doom->new();

	...

=head1 SUBROUTINES/METHODS

=head2 character_A

	  ___  
	 / _ \ 
	/ /_\ \
	|  _  |
	| | | |
	\_| |_/
	       
	       

=head2 character_B

	______ 
	| ___ \
	| |_/ /
	| ___ \
	| |_/ /
	\____/ 
	       
	       

=head2 character_C

	 _____ 
	/  __ \
	| /  \/
	| |    
	| \__/\
	 \____/
	       
	       

=head2 character_D

	______ 
	|  _  \
	| | | |
	| | | |
	| |/ / 
	|___/  
	       
	       

=head2 character_E

	 _____ 
	|  ___|
	| |__  
	|  __| 
	| |___ 
	\____/ 
	       
	       

=head2 character_F

	______ 
	|  ___|
	| |_   
	|  _|  
	| |    
	\_|    
	       
	       

=head2 character_G

	 _____ 
	|  __ \
	| |  \/
	| | __ 
	| |_\ \
	 \____/
	       
	       

=head2 character_H

	 _   _ 
	| | | |
	| |_| |
	|  _  |
	| | | |
	\_| |_/
	       
	       

=head2 character_I

	 _____ 
	|_   _|
	  | |  
	  | |  
	 _| |_ 
	 \___/ 
	       
	       

=head2 character_J

	   ___ 
	  |_  |
	  $ | |
	    | |
	/\__/ /
	\____/ 
	       
	       

=head2 character_K

	 _   __
	| | / /
	| |/ / 
	|    \ 
	| |\  \
	\_| \_/
	       
	       

=head2 character_L

	 _     
	| | $  
	| | $  
	| |    
	| |____
	\_____/
	       
	       

=head2 character_M

	___  ___
	|  \/  |
	| .  . |
	| |\/| |
	| |  | |
	\_|  |_/
	        
	        

=head2 character_N

	 _   _ 
	| \ | |
	|  \| |
	| . ` |
	| |\  |
	\_| \_/
	       
	       

=head2 character_O

	 _____ 
	|  _  |
	| | | |
	| | | |
	\ \_/ /
	 \___/ 
	       
	       

=head2 character_P

	______ 
	| ___ \
	| |_/ /
	|  __/ 
	| |    
	\_|    
	       
	       

=head2 character_Q

	 _____ 
	|  _  |
	| | | |
	| | | |
	\ \/' /
	 \_/\_\
	       
	       

=head2 character_R

	______ 
	| ___ \
	| |_/ /
	|    / 
	| |\ \ 
	\_| \_|
	       
	       

=head2 character_S

	 _____ 
	/  ___|
	\ `--. 
	 `--. \
	/\__/ /
	\____/ 
	       
	       

=head2 character_T

	 _____ 
	|_   _|
	  | |  
	  | |  
	  | |  
	  \_/  
	       
	       

=head2 character_U

	 _   _ 
	| | | |
	| | | |
	| | | |
	| |_| |
	 \___/ 
	       
	       

=head2 character_V

	 _   _ 
	| | | |
	| | | |
	| | | |
	\ \_/ /
	 \___/ 
	       
	       

=head2 character_W

	 _    _ 
	| |  | |
	| |  | |
	| |/\| |
	\  /\  /
	 \/  \/ 
	        
	        

=head2 character_X

	__   __
	\ \ / /
	 \ V / 
	 /   \ 
	/ /^\ \
	\/   \/
	       
	       

=head2 character_Y

	__   __
	\ \ / /
	 \ V / 
	  \ /  
	  | |  
	  \_/  
	       
	       

=head2 character_Z

	 ______
	|___  /
	  $/ / 
	  / /  
	./ /___
	\_____/
	       
	       

=head2 character_a

	       
	       
	  __ _ 
	 / _` |
	| (_| |
	 \__,_|
	       
	       

=head2 character_b

	 _     
	| |    
	| |__  
	| '_ \ 
	| |_) |
	|_.__/ 
	       
	       

=head2 character_c

	      
	      
	  ___ 
	 / __|
	| (__ 
	 \___|
	      
	      

=head2 character_d

	     _ 
	    | |
	  __| |
	 / _` |
	| (_| |
	 \__,_|
	       
	       

=head2 character_e

	      
	      
	  ___ 
	 / _ \
	|  __/
	 \___|
	      
	      

=head2 character_f

	  __ 
	 / _|
	| |_ 
	|  _|
	| |  
	|_|  
	     
	     

=head2 character_g

	       
	       
	  __ _ 
	 / _` |
	| (_| |
	 \__, |
	  __/ |
	 |___/ 

=head2 character_h

	 _     
	| |    
	| |__  
	| '_ \ 
	| | | |
	|_| |_|
	       
	       

=head2 character_i

	 _ 
	(_)
	 _ 
	| |
	| |
	|_|
	   
	   

=head2 character_j

	   _ 
	  (_)
	   _ 
	  | |
	  | |
	  | |
	 _/ |
	|__/ 

=head2 character_k

	 _    
	| |   
	| | __
	| |/ /
	|   < 
	|_|\_\
	      
	      

=head2 character_l

	 _ 
	| |
	| |
	| |
	| |
	|_|
	   
	   

=head2 character_m

	           
	           
	 _ __ ___  
	| '_ ` _ \ 
	| | | | | |
	|_| |_| |_|
	           
	           

=head2 character_n

	       
	       
	 _ __  
	| '_ \ 
	| | | |
	|_| |_|
	       
	       

=head2 character_o

	       
	       
	  ___  
	 / _ \ 
	| (_) |
	 \___/ 
	       
	       

=head2 character_p

	       
	       
	 _ __  
	| '_ \ 
	| |_) |
	| .__/ 
	| |    
	|_|    

=head2 character_q

	       
	       
	  __ _ 
	 / _` |
	| (_| |
	 \__, |
	    | |
	    |_|

=head2 character_r

	      
	      
	 _ __ 
	| '__|
	| |   
	|_|   
	      
	      

=head2 character_s

	     
	     
	 ___ 
	/ __|
	\__ \
	|___/
	     
	     

=head2 character_t

	 _   
	| |  
	| |_ 
	| __|
	| |_ 
	 \__|
	     
	     

=head2 character_u

	       
	       
	 _   _ 
	| | | |
	| |_| |
	 \__,_|
	       
	       

=head2 character_v

	       
	       
	__   __
	\ \ / /
	 \ V / 
	  \_/  
	       
	       

=head2 character_w

	          
	          
	__      __
	\ \ /\ / /
	 \ V  V / 
	  \_/\_/  
	          
	          

=head2 character_x

	      
	      
	__  __
	\ \/ /
	 >  < 
	/_/\_\
	      
	      

=head2 character_y

	       
	       
	 _   _ 
	| | | |
	| |_| |
	 \__, |
	  __/ |
	 |___/ 

=head2 character_z

	     
	     
	 ____
	|_  /
	 / / 
	/___|
	     
	     

=head2 character_0

	 _____ 
	|  _  |
	| |/' |
	|  /| |
	\ |_/ /
	 \___/ 
	       
	       

=head2 character_1

	 __  
	/  | 
	`| | 
	 | | 
	_| |_
	\___/
	     
	     

=head2 character_2

	 _____ 
	/ __  \
	`' / /'
	  / /  
	./ /___
	\_____/
	       
	       

=head2 character_3

	 _____ 
	|____ |
	    / /
	  $ \ \
	.___/ /
	\____/ 
	       
	       

=head2 character_4

	   ___ 
	  /   |
	 / /| |
	/ /_| |
	\___  |
	    |_/
	       
	       

=head2 character_5

	 _____ 
	|  ___|
	|___ \ 
	    \ \
	/\__/ /
	\____/ 
	       
	       

=head2 character_6

	  ____ 
	 / ___|
	/ /___ 
	| ___ \
	| \_/ |
	\_____/
	       
	       

=head2 character_7

	 ______
	|___  /
	  $/ / 
	  / /  
	./ /   
	\_/    
	       
	       

=head2 character_8

	 _____ 
	|  _  |
	 \ V / 
	 / _ \ 
	| |_| |
	\_____/
	       
	       

=head2 character_9

	 _____ 
	|  _  |
	| |_| |
	\____ |
	.___/ /
	\____/ 
	       
	       

=head1 EXTENDS

=head2 Ascii::Text::Font



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::doom at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Doom>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Doom

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Doom>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Doom>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Doom>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Doom>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
