package Ascii::Text::Font::Cricket;
use strict;
use warnings;
use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable => 0,
	writable => 0,
	value => 8,
);

function space => sub {
	my @character = $_[0]->default_character(10);
	return \@character;
};

function character_A => sub {
	my @character = $_[0]->default_character(10);
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][6]
	    = $character[6][7] = $character[6][8] = "\-";
	$character[2][5] = "1";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][7]
	    = "\.";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[3][5] = "_";
	$character[6][1] = "\`";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = $character[5][6]
	    = "\:";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[3][1] = $character[3][9] = $character[4][1]
	    = $character[4][5] = $character[4][9] = $character[5][1]
	    = $character[5][5] = $character[5][9] = "\|";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(11);
	$character[2][5] = $character[4][5] = "1";
	$character[1][9] = $character[3][9] = $character[4][10] = "\\";
	$character[2][2] = $character[3][2] = $character[5][4]  = $character[5][5]
	    = $character[5][7] = "\.";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[1][1] = $character[2][1] = $character[3][1] = $character[4][1]
	    = $character[5][1] = "\|";
	$character[2][9] = $character[5][10] = "\/";
	$character[0][2] = $character[0][3]  = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[3][5] = "_";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(10);
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[5][7] = "\.";
	$character[2][5] = $character[4][5] = "1";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[3][1] = $character[3][5] = $character[4][1]
	    = $character[4][9] = $character[5][1] = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][6] = $character[2][7]
	    = $character[2][8] = $character[3][6] = $character[3][7]
	    = $character[3][8] = "_";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(11);
	$character[1][8] = $character[2][9] = $character[3][10] = "\\";
	$character[4][5] = "1";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[5][7] = "\.";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = "\-";
	$character[4][2]  = $character[5][2] = $character[5][3] = "\:";
	$character[6][8]  = "\'";
	$character[6][1]  = "\`";
	$character[4][10] = $character[5][9] = "\/";
	$character[1][1]  = $character[2][1] = $character[2][5] = $character[3][1]
	    = $character[3][5] = $character[4][1] = $character[5][1] = "\|";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[1][5] = "_";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(10);
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[5][7] = "\.";
	$character[3][7] = "\)";
	$character[2][5] = $character[4][5] = "1";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[3][1] = $character[4][1] = $character[4][9]
	    = $character[5][1] = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][1] = "\`";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][6] = $character[2][7]
	    = $character[2][8] = $character[3][5] = $character[3][6]
	    = $character[3][8] = "_";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][6] = $character[2][7]
	    = $character[2][8] = $character[3][5] = $character[3][6] = "_";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[3][1] = $character[4][1] = $character[4][5]
	    = $character[5][1] = $character[5][5] = "\|";
	$character[6][5] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][1] = "\`";
	$character[6][2] = $character[6][3] = $character[6][4] = "\-";
	$character[2][2] = $character[3][2] = $character[5][4] = "\.";
	$character[2][5] = "1";
	$character[3][7] = "\)";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(10);
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[4][5] = "1";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[5][7] = "\.";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][6] = $character[2][7]
	    = $character[2][8] = "_";
	$character[6][1] = "\`";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][1] = $character[3][5]
	    = $character[3][9] = $character[4][1] = $character[4][9]
	    = $character[5][1] = $character[5][9] = "\|";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(10);
	$character[2][5] = "1";
	$character[1][5] = "Y";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][7]
	    = "\.";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][6]
	    = $character[6][7] = $character[6][8] = "\-";
	$character[4][2] = $character[5][2] = $character[5][3] = $character[5][6]
	    = "\:";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[3][1] = $character[3][9] = $character[4][1]
	    = $character[4][5] = $character[4][9] = $character[5][1]
	    = $character[5][5] = $character[5][9] = "\|";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][6]
	    = $character[0][7] = $character[0][8] = $character[3][5] = "_";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[0][3] = $character[0][4] = "_";
	$character[1][1] = $character[1][5] = $character[2][1] = $character[2][5]
	    = $character[3][1] = $character[3][5] = $character[4][1]
	    = $character[4][5] = $character[5][1] = $character[5][5] = "\|";
	$character[6][5] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][1] = "\`";
	$character[6][2] = $character[6][3] = $character[6][4] = "\-";
	$character[2][2] = $character[3][2] = $character[5][4] = "\.";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][2] = $character[2][3]
	    = $character[2][4] = "_";
	$character[6][1] = "\`";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][1] = $character[3][5]
	    = $character[3][9] = $character[4][1] = $character[4][9]
	    = $character[5][1] = $character[5][9] = "\|";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[4][5] = "1";
	$character[3][2] = $character[5][4] = $character[5][5] = $character[5][7]
	    = "\.";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(11);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][6]
	    = $character[0][7] = $character[0][8] = $character[3][5] = "_";
	$character[2][8] = "\/";
	$character[2][5] = "1";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][7]
	    = "\.";
	$character[6][1] = "\`";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[1][1] = $character[2][1] = $character[3][1] = $character[4][1]
	    = $character[4][5] = $character[5][1] = $character[5][5] = "\|";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][6]
	    = $character[6][7] = $character[6][8] = "\-";
	$character[3][8] = $character[4][9] = "\\";
	$character[1][5] = "Y";
	$character[1][9] = $character[5][10] = "\)";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(10);
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[6][1] = "\`";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[1][1] = $character[1][5] = $character[2][1] = $character[2][5]
	    = $character[3][1] = $character[3][5] = $character[4][1]
	    = $character[4][9] = $character[5][1] = $character[5][9] = "\|";
	$character[4][5] = "1";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[5][7] = "\.";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[3][6]
	    = $character[3][7] = $character[3][8] = "_";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(10);
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[3][1] = $character[3][9] = $character[4][1]
	    = $character[4][5] = $character[4][9] = $character[5][1]
	    = $character[5][5] = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[4][2] = $character[5][2] = $character[5][3] = $character[5][6]
	    = "\:";
	$character[1][5] = "Y";
	$character[3][4] = "\\";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][6]
	    = $character[6][7] = $character[6][8] = "\-";
	$character[3][6] = "\/";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][6]
	    = $character[0][7] = $character[0][8] = $character[3][5] = "_";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][7]
	    = "\.";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[1][5] = "_";
	$character[2][2] = $character[3][2] = $character[5][4] = "\.";
	$character[6][1] = "\`";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[1][1] = $character[2][1] = $character[2][5] = $character[2][9]
	    = $character[3][1] = $character[3][5] = $character[3][9]
	    = $character[4][1] = $character[4][5] = $character[4][9]
	    = $character[5][1] = $character[5][5] = $character[5][9] = "\|";
	$character[1][8] = "\\";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][6]
	    = $character[6][7] = $character[6][8] = "\-";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(10);
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[5][7] = "\.";
	$character[4][5] = "1";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = "_";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][1] = $character[3][5]
	    = $character[3][9] = $character[4][1] = $character[4][9]
	    = $character[5][1] = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[3][5] = $character[3][6]
	    = $character[3][7] = $character[3][8] = "_";
	$character[2][2] = $character[3][2] = $character[5][4] = "\.";
	$character[2][5] = "1";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[3][1] = $character[3][9] = $character[4][1]
	    = $character[4][5] = $character[5][1] = $character[5][5] = "\|";
	$character[6][5] = "\'";
	$character[6][1] = "\`";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][2] = $character[6][3] = $character[6][4] = "\-";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(10);
	$character[6][1] = $character[7][6] = "\`";
	$character[7][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = $character[6][7]
	    = "\:";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][1] = $character[3][5]
	    = $character[3][9] = $character[4][1] = $character[4][9]
	    = $character[5][1] = $character[5][9] = $character[6][6]
	    = $character[6][9] = "\|";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[7][7] = $character[7][8] = "\-";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = "_";
	$character[4][5] = "1";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[6][8] = "\.";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(10);
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][7]
	    = "\.";
	$character[3][9] = "1";
	$character[2][5] = "l";
	$character[2][9] = "\/";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[3][5] = "_";
	$character[1][9] = "\\";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][6]
	    = $character[6][7] = $character[6][8] = "\-";
	$character[1][1] = $character[2][1] = $character[3][1] = $character[4][1]
	    = $character[4][5] = $character[4][9] = $character[5][1]
	    = $character[5][5] = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = $character[5][6]
	    = "\:";
	$character[6][1] = "\`";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][6] = $character[2][7]
	    = $character[2][8] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = "_";
	$character[2][5] = $character[4][5] = "1";
	$character[5][4] = $character[5][5] = $character[5][7] = "\.";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[3][1] = $character[3][9] = $character[4][1]
	    = $character[4][9] = $character[5][1] = $character[5][9] = "\|";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(10);
	$character[3][2] = $character[3][8] = $character[6][4] = $character[6][5]
	    = $character[6][6] = "\-";
	$character[3][1] = $character[6][3] = "\`";
	$character[4][4] = $character[5][4] = $character[5][5] = "\:";
	$character[3][9] = $character[6][7] = "\'";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][3]
	    = $character[2][7] = $character[2][9] = $character[3][3]
	    = $character[3][7] = $character[4][3] = $character[4][7]
	    = $character[5][3] = $character[5][7] = "\|";
	$character[2][2] = $character[3][4] = $character[5][6] = "\.";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8] = "_";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][6]
	    = $character[0][7] = $character[0][8] = "_";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[5][7] = "\.";
	$character[4][5] = "1";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][1] = $character[3][5]
	    = $character[3][9] = $character[4][1] = $character[4][9]
	    = $character[5][1] = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[1][5] = "Y";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][6]
	    = $character[0][7] = $character[0][8] = "_";
	$character[5][8] = "\/";
	$character[4][5] = "1";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[5][7] = "\.";
	$character[4][2] = $character[5][3] = "\:";
	$character[6][7] = "\'";
	$character[6][3] = "\`";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][1] = $character[3][5]
	    = $character[3][9] = $character[4][1] = $character[4][9] = "\|";
	$character[6][4] = $character[6][5] = $character[6][6] = "\-";
	$character[5][2] = "\\";
	$character[1][5] = "Y";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(10);
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][7]
	    = "\.";
	$character[3][4] = "\/";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][6]
	    = $character[0][7] = $character[0][8] = "_";
	$character[3][6] = "\\";
	$character[1][5] = "Y";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][6]
	    = $character[6][7] = $character[6][8] = "\-";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][1] = $character[3][9]
	    = $character[4][1] = $character[4][9] = $character[5][1]
	    = $character[5][5] = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = $character[5][6]
	    = "\:";
	$character[6][1] = "\`";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(12);
	$character[4][6]  = $character[5][6] = "\|";
	$character[1][2]  = $character[5][1] = "\(";
	$character[6][10] = "\'";
	$character[6][2]  = "\`";
	$character[4][3]  = $character[5][2] = $character[5][3] = $character[5][7]
	    = "\:";
	$character[2][3]  = $character[3][9]  = $character[4][10] = "\\";
	$character[1][10] = $character[5][11] = "\)";
	$character[1][6]  = "Y";
	$character[6][3]  = $character[6][4] = $character[6][5] = $character[6][7]
	    = $character[6][8] = $character[6][9] = "\-";
	$character[2][9] = $character[3][3] = $character[4][2] = "\/";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][7]
	    = $character[0][8] = $character[0][9] = $character[3][6] = "_";
	$character[5][4] = $character[5][8] = "\.";
	$character[2][6] = "1";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(10);
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[4][3] = $character[4][7] = $character[5][3]
	    = $character[5][7] = "\|";
	$character[6][7] = "\'";
	$character[4][4] = $character[5][4] = $character[5][5] = "\:";
	$character[6][3] = "\`";
	$character[1][5] = "Y";
	$character[3][2] = "\\";
	$character[6][4] = $character[6][5] = $character[6][6] = "\-";
	$character[3][8] = "\/";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][6]
	    = $character[0][7] = $character[0][8] = $character[3][3]
	    = $character[3][7] = "_";
	$character[5][6] = "\.";
	$character[2][5] = "1";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(10);
	$character[5][4] = $character[5][5] = $character[5][7] = "\.";
	$character[4][5] = "1";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][2] = $character[2][3]
	    = $character[2][4] = $character[3][5] = $character[3][6]
	    = $character[3][7] = "_";
	$character[3][2] = $character[3][8] = "\/";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[4][8] = "\\";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[4][1] = $character[5][1]
	    = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][1] = "\`";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(8);
	$character[1][1] = $character[1][5] = $character[1][7] = $character[3][5]
	    = "\.";
	$character[2][4] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][6] = "_";
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][6]
	    = "\-";
	$character[2][1] = $character[2][7] = $character[3][1] = $character[3][7]
	    = "\|";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(8);
	$character[1][7] = "\.";
	$character[0][2] = $character[0][3] = $character[2][4] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = "_";
	$character[1][5] = $character[1][6] = "\-";
	$character[1][1] = $character[1][4] = $character[2][1] = $character[2][7]
	    = $character[3][1] = $character[3][7] = "\|";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(7);
	$character[2][1] = $character[2][6] = $character[3][1] = $character[3][6]
	    = "\|";
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = "\-";
	$character[2][4] = $character[2][5] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = "_";
	$character[1][1] = $character[1][6] = "\.";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(8);
	$character[1][2] = $character[1][3] = "\-";
	$character[1][4] = $character[1][7] = $character[2][1] = $character[2][7]
	    = $character[3][1] = $character[3][7] = "\|";
	$character[1][1] = "\.";
	$character[0][5] = $character[0][6] = $character[2][4] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = "_";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(8);
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[1][6] = $character[2][4] = "\-";
	$character[2][1] = $character[2][7] = $character[3][1] = $character[3][7]
	    = "\|";
	$character[1][1] = $character[1][7] = "\.";
	$character[2][5] = $character[2][6] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(7);
	$character[1][2] = "\'";
	$character[1][6] = $character[2][1] = $character[2][6] = $character[3][1]
	    = $character[3][4] = "\|";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[1][5]
	    = $character[2][5] = $character[3][2] = $character[3][3] = "_";
	$character[1][1] = "\.";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(8);
	$character[2][1] = $character[2][7] = $character[3][1] = $character[3][7]
	    = $character[4][1] = $character[4][7] = "\|";
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[1][6] = "\-";
	$character[2][4] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[4][2] = $character[4][3] = $character[4][4]
	    = $character[4][5] = $character[4][6] = "_";
	$character[1][1] = $character[1][7] = "\.";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(8);
	$character[1][5] = $character[1][6] = "\-";
	$character[1][1] = $character[1][4] = $character[2][1] = $character[2][7]
	    = $character[3][1] = $character[3][4] = $character[3][7] = "\|";
	$character[1][7] = "\.";
	$character[0][2] = $character[0][3] = $character[3][2] = $character[3][3]
	    = $character[3][5] = $character[3][6] = "_";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = $character[1][4] = $character[2][1] = $character[2][4]
	    = $character[3][1] = $character[3][4] = "\|";
	$character[0][2] = $character[0][3] = $character[1][2] = $character[1][3]
	    = $character[3][2] = $character[3][3] = "_";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(6);
	$character[0][3] = $character[0][4] = $character[1][3] = $character[1][4]
	    = $character[4][2] = $character[4][3] = $character[4][4] = "_";
	$character[1][2] = $character[1][5] = $character[2][2] = $character[2][5]
	    = $character[3][2] = $character[3][5] = $character[4][1]
	    = $character[4][5] = "\|";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = $character[0][3] = $character[3][2] = $character[3][3]
	    = $character[3][5] = $character[3][6] = "_";
	$character[1][7] = "\.";
	$character[1][1] = $character[1][4] = $character[2][1] = $character[3][1]
	    = $character[3][4] = $character[3][7] = "\|";
	$character[2][6] = "\<";
	$character[1][5] = $character[1][6] = "\-";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(5);
	$character[0][2] = $character[0][3] = $character[3][2] = $character[3][3]
	    = "_";
	$character[1][1] = $character[1][4] = $character[2][1] = $character[2][4]
	    = $character[3][1] = $character[3][4] = "\|";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(11);
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[1][6] = $character[1][7] = $character[1][8]
	    = $character[1][9] = "\-";
	$character[2][1] = $character[2][10] = $character[3][1]
	    = $character[3][4] = $character[3][7] = $character[3][10] = "\|";
	$character[1][1] = $character[1][10] = "\.";
	$character[3][2] = $character[3][3]  = $character[3][5] = $character[3][6]
	    = $character[3][8] = $character[3][9] = "_";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(8);
	$character[3][2] = $character[3][3] = $character[3][5] = $character[3][6]
	    = "_";
	$character[1][1] = $character[1][7] = "\.";
	$character[2][1] = $character[2][7] = $character[3][1] = $character[3][4]
	    = $character[3][7] = "\|";
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[1][6] = "\-";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(8);
	$character[2][4] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[3][6] = "_";
	$character[1][1] = $character[1][7] = "\.";
	$character[2][1] = $character[2][7] = $character[3][1] = $character[3][7]
	    = "\|";
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[1][6] = "\-";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(8);
	$character[1][1] = $character[1][7] = "\.";
	$character[2][4] = $character[3][5] = $character[3][6] = $character[4][2]
	    = $character[4][3] = "_";
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[1][6] = "\-";
	$character[2][1] = $character[2][7] = $character[3][1] = $character[3][7]
	    = $character[4][1] = $character[4][4] = "\|";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(8);
	$character[2][4] = $character[3][2] = $character[3][3] = $character[4][5]
	    = $character[4][6] = "_";
	$character[1][1] = $character[1][7] = "\.";
	$character[2][1] = $character[2][7] = $character[3][1] = $character[3][7]
	    = $character[4][4] = $character[4][7] = "\|";
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[1][6] = "\-";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(7);
	$character[1][1] = $character[1][6] = "\.";
	$character[2][5] = $character[3][2] = $character[3][3] = "_";
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = "\-";
	$character[2][1] = $character[2][6] = $character[3][1] = $character[3][4]
	    = "\|";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(8);
	$character[2][2] = $character[2][3] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	$character[1][1] = $character[1][7] = "\.";
	$character[2][1] = $character[2][7] = $character[3][1] = $character[3][7]
	    = "\|";
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[1][6] = $character[2][5] = $character[2][6] = "\-";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(7);
	$character[0][2] = $character[0][3] = $character[1][5] = $character[2][5]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = "_";
	$character[1][1] = $character[1][4] = $character[2][1] = $character[2][6]
	    = $character[3][1] = $character[3][6] = "\|";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(8);
	$character[3][2] = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = "_";
	$character[1][1] = $character[1][4] = $character[1][7] = "\.";
	$character[2][1] = $character[2][4] = $character[2][7] = $character[3][1]
	    = $character[3][7] = "\|";
	$character[1][2] = $character[1][3] = $character[1][5] = $character[1][6]
	    = "\-";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(8);
	$character[1][1] = $character[1][4] = $character[1][7] = "\.";
	$character[3][6] = "\/";
	$character[3][3] = $character[3][4] = $character[3][5] = "_";
	$character[3][2] = "\\";
	$character[1][2] = $character[1][3] = $character[1][5] = $character[1][6]
	    = "\-";
	$character[2][1] = $character[2][4] = $character[2][7] = "\|";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(11);
	$character[2][1] = $character[2][4] = $character[2][7]
	    = $character[2][10] = $character[3][1] = $character[3][10] = "\|";
	$character[1][2] = $character[1][3] = $character[1][5] = $character[1][6]
	    = $character[1][8] = $character[1][9] = "\-";
	$character[3][2] = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[3][7] = $character[3][8]
	    = $character[3][9] = "_";
	$character[1][1] = $character[1][4] = $character[1][7]
	    = $character[1][10] = "\.";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(8);
	$character[1][1] = $character[1][4] = $character[1][7] = $character[3][4]
	    = "\.";
	$character[2][2] = $character[2][6] = $character[3][2] = $character[3][3]
	    = $character[3][5] = $character[3][6] = "_";
	$character[1][2] = $character[1][3] = $character[1][5] = $character[1][6]
	    = "\-";
	$character[2][1] = $character[2][7] = $character[3][1] = $character[3][7]
	    = "\|";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(8);
	$character[3][2] = $character[3][3] = $character[3][4] = $character[4][2]
	    = $character[4][3] = $character[4][4] = $character[4][5]
	    = $character[4][6] = "_";
	$character[1][1] = $character[1][4] = $character[1][7] = "\.";
	$character[2][1] = $character[2][4] = $character[2][7] = $character[3][1]
	    = $character[3][7] = $character[4][1] = $character[4][7] = "\|";
	$character[1][2] = $character[1][3] = $character[1][5] = $character[1][6]
	    = "\-";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(8);
	$character[2][1] = $character[2][7] = $character[3][1] = $character[3][7]
	    = "\|";
	$character[1][2] = $character[1][3] = $character[1][4] = $character[1][5]
	    = $character[1][6] = $character[2][2] = $character[2][3] = "\-";
	$character[2][5] = $character[2][6] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[3][6] = "_";
	$character[1][1] = $character[1][7] = "\.";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = "_";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[5][7] = "\.";
	$character[4][5] = "1";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][1] = $character[3][5]
	    = $character[3][9] = $character[4][1] = $character[4][9]
	    = $character[5][1] = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][1] = "\`";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[1][3] = "_";
	$character[2][2] = $character[3][4] = $character[5][6] = "\.";
	$character[4][4] = $character[5][4] = $character[5][5] = "\:";
	$character[6][7] = "\'";
	$character[3][1] = $character[6][3] = "\`";
	$character[1][1] = $character[1][7] = $character[2][1] = $character[2][3]
	    = $character[2][7] = $character[3][3] = $character[3][7]
	    = $character[4][3] = $character[4][7] = $character[5][3]
	    = $character[5][7] = "\|";
	$character[3][2] = $character[6][4] = $character[6][5] = $character[6][6]
	    = "\-";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(10);
	$character[4][8] = "\\";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[6][1] = "\`";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[4][1] = $character[5][1]
	    = $character[5][9] = "\|";
	$character[4][5] = "1";
	$character[5][4] = $character[5][5] = $character[5][7] = "\.";
	$character[3][2] = $character[3][8] = "\/";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[3][5] = $character[3][6] = $character[3][7] = "_";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(10);
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[6][1] = "\`";
	$character[6][9] = "\'";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[3][3] = "\(";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][9] = $character[4][1]
	    = $character[4][9] = $character[5][1] = $character[5][9] = "\|";
	$character[4][5] = "1";
	$character[5][4] = $character[5][5] = $character[5][7] = "\.";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][2] = $character[2][3]
	    = $character[2][4] = $character[3][2] = $character[3][4]
	    = $character[3][5] = "_";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(10);
	$character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[1][5] = "Y";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][1] = $character[3][9]
	    = $character[4][5] = $character[4][9] = $character[5][5]
	    = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[4][6] = $character[5][6] = $character[5][7] = "\:";
	$character[6][5] = "\`";
	$character[5][8] = "\.";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][6]
	    = $character[0][7] = $character[0][8] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5] = "_";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][6] = $character[2][7]
	    = $character[2][8] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = "_";
	$character[5][4] = $character[5][5] = $character[5][7] = "\.";
	$character[2][5] = $character[4][5] = "1";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[3][1] = $character[3][9] = $character[4][1]
	    = $character[4][9] = $character[5][1] = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(10);
	$character[3][2] = $character[5][4] = $character[5][5] = $character[5][7]
	    = "\.";
	$character[2][5] = $character[4][5] = "1";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][6] = $character[2][7]
	    = $character[2][8] = "_";
	$character[3][8] = "\\";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][9]
	    = $character[3][1] = $character[4][1] = $character[4][9]
	    = $character[5][1] = $character[5][9] = "\|";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[2][2] = $character[2][3]
	    = $character[2][4] = "_";
	$character[3][4] = $character[3][8] = "\/";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[4][3] = $character[4][7]
	    = $character[5][3] = $character[5][7] = "\|";
	$character[6][7] = "\'";
	$character[6][3] = "\`";
	$character[6][4] = $character[6][5] = $character[6][6] = "\-";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(10);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[3][5] = "_";
	$character[4][5] = "1";
	$character[2][2] = $character[3][2] = $character[5][4] = $character[5][5]
	    = $character[5][7] = "\.";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][1] = $character[3][9]
	    = $character[4][1] = $character[4][9] = $character[5][1]
	    = $character[5][9] = "\|";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(10);
	$character[4][5] = "1";
	$character[5][4] = $character[5][5] = $character[5][7] = "\.";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[0][8]
	    = $character[1][5] = $character[3][3] = $character[3][4]
	    = $character[3][5] = "_";
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6] = $character[6][7] = $character[6][8] = "\-";
	$character[3][2] = "\\";
	$character[4][2] = $character[5][2] = $character[5][3] = "\:";
	$character[6][9] = "\'";
	$character[6][1] = "\`";
	$character[1][1] = $character[1][9] = $character[2][1] = $character[2][5]
	    = $character[2][9] = $character[3][9] = $character[4][1]
	    = $character[4][9] = $character[5][1] = $character[5][9] = "\|";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Cricket - The great new Ascii::Text::Font::Cricket!

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	use Ascii::Text::Font::Cricket;

	my $foo = Ascii::Text::Font::Cricket->new();

	...

=head1 SUBROUTINES/METHODS

=head2 character_A

	  _______ 
	 |   _   |
	 |.  1   |
	 |.  _   |
	 |:  |   |
	 |::.|:. |
	 `--- ---'
	          

=head2 character_B

	  _______  
	 |   _   \ 
	 |.  1   / 
	 |.  _   \ 
	 |:  1    \
	 |::.. .  /
	 `-------' 
	           

=head2 character_C

	  _______ 
	 |   _   |
	 |.  1___|
	 |.  |___ 
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_D

	  ______   
	 |   _  \  
	 |.  |   \ 
	 |.  |    \
	 |:  1    /
	 |::.. . / 
	 `------'  
	           

=head2 character_E

	  _______ 
	 |   _   |
	 |.  1___|
	 |.  __)_ 
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_F

	  _______ 
	 |   _   |
	 |.  1___|
	 |.  __)  
	 |:  |    
	 |::.|    
	 `---'    
	          

=head2 character_G

	  _______ 
	 |   _   |
	 |.  |___|
	 |.  |   |
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_H

	  ___ ___ 
	 |   Y   |
	 |.  1   |
	 |.  _   |
	 |:  |   |
	 |::.|:. |
	 `--- ---'
	          

=head2 character_I

	  ___ 
	 |   |
	 |.  |
	 |.  |
	 |:  |
	 |::.|
	 `---'
	      

=head2 character_J

	  _______ 
	 |   _   |
	 |___|   |
	 |.  |   |
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_K

	  ___ ___  
	 |   Y   ) 
	 |.  1  /  
	 |.  _  \  
	 |:  |   \ 
	 |::.| .  )
	 `--- ---' 
	           

=head2 character_L

	  ___     
	 |   |    
	 |.  |    
	 |.  |___ 
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_M

	  ___ ___ 
	 |   Y   |
	 |.      |
	 |. \_/  |
	 |:  |   |
	 |::.|:. |
	 `--- ---'
	          

=head2 character_N

	  ______  
	 |   _  \ 
	 |.  |   |
	 |.  |   |
	 |:  |   |
	 |::.|   |
	 `--- ---'
	          

=head2 character_O

	  _______ 
	 |   _   |
	 |.  |   |
	 |.  |   |
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_P

	  _______ 
	 |   _   |
	 |.  1   |
	 |.  ____|
	 |:  |    
	 |::.|    
	 `---'    
	          

=head2 character_Q

	  _______ 
	 |   _   |
	 |.  |   |
	 |.  |   |
	 |:  1   |
	 |::..   |
	 `----|:.|
	      `--'

=head2 character_R

	  _______ 
	 |   _   \
	 |.  l   /
	 |.  _   1
	 |:  |   |
	 |::.|:. |
	 `--- ---'
	          

=head2 character_S

	  _______ 
	 |   _   |
	 |   1___|
	 |____   |
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_T

	  _______ 
	 |       |
	 |.|   | |
	 `-|.  |-'
	   |:  |  
	   |::.|  
	   `---'  
	          

=head2 character_U

	  ___ ___ 
	 |   Y   |
	 |.  |   |
	 |.  |   |
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_V

	  ___ ___ 
	 |   Y   |
	 |.  |   |
	 |.  |   |
	 |:  1   |
	  \:.. ./ 
	   `---'  
	          

=head2 character_W

	  ___ ___ 
	 |   Y   |
	 |.  |   |
	 |. / \  |
	 |:      |
	 |::.|:. |
	 `--- ---'
	          

=head2 character_X

	   ___ ___  
	  (   Y   ) 
	   \  1  /  
	   /  _  \  
	  /:  |   \ 
	 (::. |:.  )
	  `--- ---' 
	            

=head2 character_Y

	  ___ ___ 
	 |   Y   |
	 |   1   |
	  \_   _/ 
	   |:  |  
	   |::.|  
	   `---'  
	          

=head2 character_Z

	  _______ 
	 |   _   |
	 |___|   |
	  /  ___/ 
	 |:  1  \ 
	 |::.. . |
	 `-------'
	          

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

	  _______ 
	 |   _   |
	 |.  |   |
	 |.  |   |
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_1

	  _____ 
	 | _   |
	 |.|   |
	 `-|.  |
	   |:  |
	   |::.|
	   `---'
	        

=head2 character_2

	  _______ 
	 |       |
	 |___|   |
	  /  ___/ 
	 |:  1  \ 
	 |::.. . |
	 `-------'
	          

=head2 character_3

	  _______ 
	 |   _   |
	 |___|   |
	  _(__   |
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_4

	  ___ ___ 
	 |   Y   |
	 |   |   |
	 |____   |
	     |:  |
	     |::.|
	     `---'
	          

=head2 character_5

	  _______ 
	 |   _   |
	 |   1___|
	 |____   |
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_6

	  _______ 
	 |   _   |
	 |   1___|
	 |.     \ 
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_7

	  _______ 
	 |   _   |
	 |___|   |
	    /   / 
	   |   |  
	   |   |  
	   `---'  
	          

=head2 character_8

	  _______ 
	 |   _   |
	 |.  |   |
	 |.  _   |
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head2 character_9

	  _______ 
	 |   _   |
	 |   |   |
	  \___   |
	 |:  1   |
	 |::.. . |
	 `-------'
	          

=head1 EXTENDS

=head2 Ascii::Text::Font



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::cricket at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Cricket>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Cricket

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Cricket>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Cricket>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Cricket>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Cricket>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
