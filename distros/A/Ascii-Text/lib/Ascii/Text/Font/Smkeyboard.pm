package Ascii::Text::Font::Smkeyboard;
use strict;
use warnings;
use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable  => 0,
	writeable => 0,
	value     => 4
);

function space => sub {
	my (@character) = $_[0]->default_character(6);
	return \@character;
};

function character_A => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[1][2] = "A";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[1][2] = "B";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "C";
	$character[3][1] = "\/";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[1][2] = "D";
	$character[3][1] = "\/";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "E";
	$character[3][1] = "\/";
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "F";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[1][2] = "G";
	$character[3][1] = "\/";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "H";
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[3][1] = "\/";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "I";
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][1] = "\/";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][2] = "J";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[3][1] = "\/";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "K";
	$character[3][1] = "\/";
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[1][2] = "L";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "M";
	$character[3][1] = "\/";
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "N";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[1][2] = "O";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[3][1] = "\/";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[1][2] = "P";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "Q";
	$character[3][1] = "\/";
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "R";
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][1] = "\/";
	$character[1][2] = "S";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[1][2] = "T";
	$character[3][1] = "\/";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "U";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "V";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "W";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[1][2] = "X";
	$character[3][1] = "\/";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[1][2] = "Y";
	$character[3][1] = "\/";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[1][2] = "Z";
	$character[3][1] = "\/";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[3][4] = "\\";
	$character[1][2] = "a";
	$character[3][1] = "\/";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "b";
	$character[3][1] = "\/";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[1][2] = "c";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[1][2] = "d";
	$character[3][4] = "\\";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[1][2] = "e";
	$character[3][1] = "\/";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][2] = "f";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[3][4] = "\\";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "g";
	$character[3][1] = "\/";
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[1][2] = "h";
	$character[3][1] = "\/";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][2] = "i";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "j";
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][2] = "k";
	$character[3][1] = "\/";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[1][2] = "l";
	$character[3][4] = "\\";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "m";
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "n";
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "o";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[3][4] = "\\";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "p";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "q";
	$character[3][1] = "\/";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[3][4] = "\\";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "r";
	$character[3][1] = "\/";
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "s";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[1][2] = "t";
	$character[3][1] = "\/";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[3][4] = "\\";
	$character[1][2] = "u";
	$character[3][1] = "\/";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "v";
	$character[3][1] = "\/";
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[1][2] = "w";
	$character[3][1] = "\/";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "x";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[3][1] = "\/";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "y";
	$character[3][4] = "\\";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = "z";
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][1] = "\/";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][1] = "\/";
	$character[1][2] = "0";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "1";
	$character[3][4] = "\\";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "2";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "3";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[3][1] = "\/";
	$character[1][2] = "4";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\\";
	$character[1][2] = "5";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[3][1] = "\/";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[3][1] = "\/";
	$character[1][2] = "6";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = "\/";
	$character[1][2] = "7";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[3][4] = "\\";
	$character[3][1] = "\/";
	$character[1][2] = "8";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[2][0] = $character[2][1] = $character[2][4]
	    = $character[2][5] = $character[3][0] = $character[3][5] = "\|";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4]
	    = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][4] = "\\";
	$character[1][2] = "9";
	$character[3][1] = "\/";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Smkeyboard - Smkeyboard Font

=head1 VERSION

Version 0.21

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	
	use Ascii::Text::Font::Smkeyboard;

	my $foo = Ascii::Text::Font::Smkeyboard->new();

	...

=head1 EXTENDS

=head2 Ascii::Text::Font

=head1 SUBROUTINES/METHODS

=head2 space

=head2 character_A

	 ____ 
	||A ||
	||__||
	|/__\|

=head2 character_B

	 ____ 
	||B ||
	||__||
	|/__\|

=head2 character_C

	 ____ 
	||C ||
	||__||
	|/__\|

=head2 character_D

	 ____ 
	||D ||
	||__||
	|/__\|

=head2 character_E

	 ____ 
	||E ||
	||__||
	|/__\|

=head2 character_F

	 ____ 
	||F ||
	||__||
	|/__\|

=head2 character_G

	 ____ 
	||G ||
	||__||
	|/__\|

=head2 character_H

	 ____ 
	||H ||
	||__||
	|/__\|

=head2 character_I

	 ____ 
	||I ||
	||__||
	|/__\|

=head2 character_J

	 ____ 
	||J ||
	||__||
	|/__\|

=head2 character_K

	 ____ 
	||K ||
	||__||
	|/__\|

=head2 character_L

	 ____ 
	||L ||
	||__||
	|/__\|

=head2 character_M

	 ____ 
	||M ||
	||__||
	|/__\|

=head2 character_N

	 ____ 
	||N ||
	||__||
	|/__\|

=head2 character_O

	 ____ 
	||O ||
	||__||
	|/__\|

=head2 character_P

	 ____ 
	||P ||
	||__||
	|/__\|

=head2 character_Q

	 ____ 
	||Q ||
	||__||
	|/__\|

=head2 character_R

	 ____ 
	||R ||
	||__||
	|/__\|

=head2 character_S

	 ____ 
	||S ||
	||__||
	|/__\|

=head2 character_T

	 ____ 
	||T ||
	||__||
	|/__\|

=head2 character_U

	 ____ 
	||U ||
	||__||
	|/__\|

=head2 character_V

	 ____ 
	||V ||
	||__||
	|/__\|

=head2 character_W

	 ____ 
	||W ||
	||__||
	|/__\|

=head2 character_X

	 ____ 
	||X ||
	||__||
	|/__\|

=head2 character_Y

	 ____ 
	||Y ||
	||__||
	|/__\|

=head2 character_Z

	 ____ 
	||Z ||
	||__||
	|/__\|

=head2 character_a

	 ____ 
	||a ||
	||__||
	|/__\|

=head2 character_b

	 ____ 
	||b ||
	||__||
	|/__\|

=head2 character_c

	 ____ 
	||c ||
	||__||
	|/__\|

=head2 character_d

	 ____ 
	||d ||
	||__||
	|/__\|

=head2 character_e

	 ____ 
	||e ||
	||__||
	|/__\|

=head2 character_f

	 ____ 
	||f ||
	||__||
	|/__\|

=head2 character_g

	 ____ 
	||g ||
	||__||
	|/__\|

=head2 character_h

	 ____ 
	||h ||
	||__||
	|/__\|

=head2 character_i

	 ____ 
	||i ||
	||__||
	|/__\|

=head2 character_j

	 ____ 
	||j ||
	||__||
	|/__\|

=head2 character_k

	 ____ 
	||k ||
	||__||
	|/__\|

=head2 character_l

	 ____ 
	||l ||
	||__||
	|/__\|

=head2 character_m

	 ____ 
	||m ||
	||__||
	|/__\|

=head2 character_n

	 ____ 
	||n ||
	||__||
	|/__\|

=head2 character_o

	 ____ 
	||o ||
	||__||
	|/__\|

=head2 character_p

	 ____ 
	||p ||
	||__||
	|/__\|

=head2 character_q

	 ____ 
	||q ||
	||__||
	|/__\|

=head2 character_r

	 ____ 
	||r ||
	||__||
	|/__\|

=head2 character_s

	 ____ 
	||s ||
	||__||
	|/__\|

=head2 character_t

	 ____ 
	||t ||
	||__||
	|/__\|

=head2 character_u

	 ____ 
	||u ||
	||__||
	|/__\|

=head2 character_v

	 ____ 
	||v ||
	||__||
	|/__\|

=head2 character_w

	 ____ 
	||w ||
	||__||
	|/__\|

=head2 character_x

	 ____ 
	||x ||
	||__||
	|/__\|

=head2 character_y

	 ____ 
	||y ||
	||__||
	|/__\|

=head2 character_z

	 ____ 
	||z ||
	||__||
	|/__\|

=head2 character_0

	 ____ 
	||0 ||
	||__||
	|/__\|

=head2 character_1

	 ____ 
	||1 ||
	||__||
	|/__\|

=head2 character_2

	 ____ 
	||2 ||
	||__||
	|/__\|

=head2 character_3

	 ____ 
	||3 ||
	||__||
	|/__\|

=head2 character_4

	 ____ 
	||4 ||
	||__||
	|/__\|

=head2 character_5

	 ____ 
	||5 ||
	||__||
	|/__\|

=head2 character_6

	 ____ 
	||6 ||
	||__||
	|/__\|

=head2 character_7

	 ____ 
	||7 ||
	||__||
	|/__\|

=head2 character_8

	 ____ 
	||8 ||
	||__||
	|/__\|

=head2 character_9

	 ____ 
	||9 ||
	||__||
	|/__\|

=head1 PROPERTY

=head2 character_height



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::smkeyboard at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Smkeyboard>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Smkeyboard

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Smkeyboard>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Smkeyboard>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Smkeyboard>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Smkeyboard>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
