package Ascii::Text::Font::Tanja;
use strict;
use warnings;
use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable  => 0,
	writeable => 0,
	value     => 8
);

function space => sub {
	my (@character) = $_[0]->default_character(8);
	return \@character;
};

function character_A => sub {
	my @character = $_[0]->default_character(9);
	$character[0][4] = $character[0][5] = $character[1][5] = $character[1][6]
	    = $character[2][6] = $character[2][7] = $character[3][2]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[3][7] = $character[4][6]
	    = $character[4][7] = $character[5][6] = $character[5][7] = 'a';
	$character[0][2] = $character[1][1] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'A';
	$character[0][3] = $character[1][2] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'B';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[1][5] = $character[1][6] = $character[2][2]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][5] = $character[3][6] = $character[4][6]
	    = $character[4][7] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = $character[5][6] = 'b';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(9);
	$character[0][3] = $character[1][2] = $character[2][1] = $character[3][1]
	    = $character[4][2] = $character[5][3] = ')';
	$character[0][2] = $character[1][1] = $character[2][0] = $character[3][0]
	    = $character[4][1] = $character[5][2] = 'C';
	$character[0][4] = $character[0][5] = $character[0][6] = $character[1][6]
	    = $character[1][7] = $character[4][6] = $character[4][7]
	    = $character[5][4] = $character[5][5] = $character[5][6] = 'c';
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'D';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[1][5] = $character[1][6] = $character[2][6]
	    = $character[2][7] = $character[3][6] = $character[3][7]
	    = $character[4][6] = $character[4][7] = $character[5][2]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = 'd';
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[2][2]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[2][6] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = $character[5][6]
	    = $character[5][7] = 'e';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'E';
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(9);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[2][2]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[2][6] = 'f';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'F';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(9);
	$character[0][2] = $character[1][1] = $character[2][0] = $character[3][0]
	    = $character[4][1] = $character[5][2] = 'G';
	$character[0][4] = $character[0][5] = $character[0][6] = $character[0][7]
	    = $character[2][4] = $character[2][5] = $character[2][6]
	    = $character[3][6] = $character[3][7] = $character[4][6]
	    = $character[4][7] = $character[5][4] = $character[5][5]
	    = $character[5][6] = 'g';
	$character[0][3] = $character[1][2] = $character[2][1] = $character[3][1]
	    = $character[4][2] = $character[5][3] = ')';
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(9);
	$character[0][6] = $character[0][7] = $character[1][6] = $character[1][7]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[2][6] = $character[2][7]
	    = $character[3][6] = $character[3][7] = $character[4][6]
	    = $character[4][7] = $character[5][6] = $character[5][7] = 'h';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'H';
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[1][3] = $character[2][3] = $character[3][3]
	    = $character[4][3] = $character[5][1] = ')';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[5][2] = $character[5][3] = $character[5][4]
	    = $character[5][5] = 'i';
	$character[0][0] = $character[1][2] = $character[2][2] = $character[3][2]
	    = $character[4][2] = $character[5][0] = 'I';
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[1][4] = $character[2][4] = $character[3][0]
	    = $character[4][0] = $character[5][1] = 'J';
	$character[0][1] = $character[1][5] = $character[2][5] = $character[3][1]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[3][4]
	    = $character[3][5] = $character[4][4] = $character[4][5]
	    = $character[5][3] = $character[5][4] = 'j';
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(9);
	$character[0][5] = $character[0][6] = $character[1][4] = $character[1][5]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[3][4] = $character[3][5] = $character[4][5]
	    = $character[4][6] = $character[5][6] = $character[5][7] = 'k';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'K';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(9);
	$character[5][2] = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = $character[5][7] = 'l';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'L';
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(11);
	$character[0][3] = $character[0][4] = $character[0][6] = $character[0][7]
	    = $character[0][8] = $character[1][4] = $character[1][5]
	    = $character[1][8] = $character[1][9] = $character[2][4]
	    = $character[2][5] = $character[2][8] = $character[2][9]
	    = $character[3][4] = $character[3][5] = $character[3][8]
	    = $character[3][9] = $character[4][8] = $character[4][9]
	    = $character[5][8] = $character[5][9] = 'm';
	$character[0][1] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'M';
	$character[0][2] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'N';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	$character[0][2] = $character[0][6] = $character[0][7] = $character[1][2]
	    = $character[1][3] = $character[1][6] = $character[1][7]
	    = $character[2][3] = $character[2][4] = $character[2][6]
	    = $character[2][7] = $character[3][4] = $character[3][5]
	    = $character[3][6] = $character[3][7] = $character[4][5]
	    = $character[4][6] = $character[4][7] = $character[5][6]
	    = $character[5][7] = 'n';
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(9);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][6] = $character[1][7] = $character[2][6]
	    = $character[2][7] = $character[3][6] = $character[3][7]
	    = $character[4][6] = $character[4][7] = $character[5][3]
	    = $character[5][4] = $character[5][5] = $character[5][6] = 'o';
	$character[0][2] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][1] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][1] = 'O';
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'P';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[1][6] = $character[1][7]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[2][6] = 'p';
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(9);
	$character[0][2] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][6] = $character[1][7] = $character[2][6]
	    = $character[2][7] = $character[3][4] = $character[3][5]
	    = $character[3][7] = $character[4][5] = $character[4][6]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][7] = 'q';
	$character[0][1] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][1] = 'Q';
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(9);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[1][6] = $character[1][7]
	    = $character[2][4] = $character[2][5] = $character[2][6]
	    = $character[3][3] = $character[3][4] = $character[4][5]
	    = $character[4][6] = $character[5][6] = $character[5][7] = 'r';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'R';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[1][0] = $character[2][1] = $character[3][5]
	    = $character[4][0] = $character[5][1] = 'S';
	$character[0][2] = $character[1][1] = $character[2][2] = $character[3][6]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[1][6] = $character[1][7] = $character[2][3]
	    = $character[2][4] = $character[4][6] = $character[4][7]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = 's';
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[1][3] = $character[2][3] = $character[3][3]
	    = $character[4][3] = $character[5][3] = 'T';
	$character[0][1] = $character[1][4] = $character[2][4] = $character[3][4]
	    = $character[4][4] = $character[5][4] = ')';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = 't';
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(9);
	$character[0][6] = $character[0][7] = $character[1][6] = $character[1][7]
	    = $character[2][6] = $character[2][7] = $character[3][6]
	    = $character[3][7] = $character[4][6] = $character[4][7]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = 'u';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][1] = 'U';
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][2]
	    = $character[4][3] = $character[5][4] = ')';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][1]
	    = $character[4][2] = $character[5][3] = 'V';
	$character[0][6] = $character[0][7] = $character[1][6] = $character[1][7]
	    = $character[2][6] = $character[2][7] = $character[3][5]
	    = $character[3][6] = $character[4][4] = $character[4][5] = 'v';
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(11);
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][8] = $character[0][9] = $character[1][8] = $character[1][9]
	    = $character[2][4] = $character[2][5] = $character[2][8]
	    = $character[2][9] = $character[3][4] = $character[3][5]
	    = $character[3][8] = $character[3][9] = $character[4][4]
	    = $character[4][5] = $character[4][8] = $character[4][9]
	    = $character[5][3] = $character[5][4] = $character[5][6]
	    = $character[5][7] = $character[5][8] = 'w';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][1] = 'W';
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[1][1] = $character[2][2] = $character[3][2]
	    = $character[4][1] = $character[5][0] = 'X';
	$character[0][6] = $character[0][7] = $character[1][5] = $character[1][6]
	    = $character[2][4] = $character[2][5] = $character[3][4]
	    = $character[3][5] = $character[4][5] = $character[4][6]
	    = $character[5][6] = $character[5][7] = 'x';
	$character[0][1] = $character[1][2] = $character[2][3] = $character[3][3]
	    = $character[4][2] = $character[5][1] = ')';
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[1][2] = $character[2][3] = $character[3][4]
	    = $character[4][4] = $character[5][4] = ')';
	$character[0][6] = $character[0][7] = $character[1][5] = $character[1][6]
	    = $character[2][4] = $character[2][5] = 'y';
	$character[0][0] = $character[1][1] = $character[2][2] = $character[3][3]
	    = $character[4][3] = $character[5][3] = 'Y';
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(9);
	$character[0][0] = $character[1][6] = $character[2][4] = $character[3][3]
	    = $character[4][1] = $character[5][0] = 'Z';
	$character[0][1] = $character[1][7] = $character[2][5] = $character[3][4]
	    = $character[4][2] = $character[5][1] = ')';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[5][2]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = $character[5][7] = 'z';
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(8);
	$character[2][0] = $character[3][1] = $character[4][0] = $character[5][1]
	    = 'a';
	$character[2][1] = $character[3][2] = $character[4][1] = $character[5][2]
	    = ')';
	$character[2][2] = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[4][5] = $character[5][3] = $character[5][4]
	    = $character[5][5] = $character[5][6] = 'A';
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'b';
	$character[2][2] = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][5] = $character[3][6] = $character[4][5]
	    = $character[4][6] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = 'B';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(8);
	$character[2][2] = $character[3][1] = $character[4][1] = $character[5][2]
	    = ')';
	$character[2][3] = $character[2][4] = $character[2][5] = $character[2][6]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = 'C';
	$character[2][1] = $character[3][0] = $character[4][0] = $character[5][1]
	    = 'c';
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(8);
	$character[2][3] = $character[2][4] = $character[2][5] = $character[2][6]
	    = $character[3][5] = $character[3][6] = $character[4][5]
	    = $character[4][6] = $character[5][3] = $character[5][4]
	    = $character[5][5] = $character[5][6] = 'D';
	$character[0][6] = $character[1][6] = $character[2][2] = $character[3][1]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][5] = $character[1][5] = $character[2][1] = $character[3][0]
	    = $character[4][0] = $character[5][1] = 'd';
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(8);
	$character[2][2] = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[2][6] = $character[3][2] = $character[3][3]
	    = $character[3][4] = $character[3][5] = $character[5][3]
	    = $character[5][4] = $character[5][5] = $character[5][6] = 'E';
	$character[2][0] = $character[3][0] = $character[4][0] = $character[5][1]
	    = 'e';
	$character[2][1] = $character[3][1] = $character[4][1] = $character[5][2]
	    = ')';
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'f';
	$character[0][3] = $character[0][4] = $character[0][5] = $character[2][2]
	    = $character[2][3] = $character[2][4] = 'F';
	$character[0][2] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(8);
	$character[2][3] = $character[2][4] = $character[2][5] = $character[3][5]
	    = $character[3][6] = $character[4][5] = $character[4][6]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = $character[6][5] = $character[6][6]
	    = $character[7][2] = $character[7][3] = $character[7][4]
	    = $character[7][5] = 'G';
	$character[2][1] = $character[3][0] = $character[4][0] = $character[5][1]
	    = $character[7][0] = 'g';
	$character[2][2] = $character[3][1] = $character[4][1] = $character[5][2]
	    = $character[7][1] = ')';
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'h';
	$character[2][2] = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][5] = $character[3][6] = $character[4][5]
	    = $character[4][6] = $character[5][5] = $character[5][6] = 'H';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(3);
	$character[2][0] = $character[3][0] = $character[4][0] = $character[5][0]
	    = 'i';
	$character[2][1] = $character[3][1] = $character[4][1] = $character[5][1]
	    = ')';
	$character[0][0] = $character[0][1] = '#';
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(8);
	$character[2][6] = $character[3][6] = $character[4][6] = $character[5][6]
	    = $character[6][1] = $character[7][2] = ')';
	$character[2][5] = $character[3][5] = $character[4][5] = $character[5][5]
	    = $character[6][0] = $character[7][1] = 'j';
	$character[0][5] = $character[0][6] = '#';
	$character[6][5] = $character[6][6] = $character[7][3] = $character[7][4]
	    = $character[7][5] = 'J';
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][1] = ')';
	$character[2][4] = $character[2][5] = $character[3][2] = $character[3][3]
	    = $character[4][3] = $character[4][4] = $character[5][4]
	    = $character[5][5] = 'K';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][0] = 'k';
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(5);
	$character[0][2] = $character[5][2] = $character[5][3] = 'L';
	$character[0][0] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][0] = 'l';
	$character[0][1] = $character[1][2] = $character[2][2] = $character[3][2]
	    = $character[4][2] = $character[5][1] = ')';
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(11);
	$character[2][2] = $character[3][1] = $character[4][1] = $character[5][1]
	    = ')';
	$character[2][3] = $character[2][4] = $character[2][6] = $character[2][7]
	    = $character[2][8] = $character[3][4] = $character[3][5]
	    = $character[3][8] = $character[3][9] = $character[4][4]
	    = $character[4][5] = $character[4][8] = $character[4][9]
	    = $character[5][8] = $character[5][9] = 'M';
	$character[2][1] = $character[3][0] = $character[4][0] = $character[5][0]
	    = 'm';
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(8);
	$character[2][2] = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][5] = $character[3][6] = $character[4][5]
	    = $character[4][6] = $character[5][5] = $character[5][6] = 'N';
	$character[2][0] = $character[3][0] = $character[4][0] = $character[5][0]
	    = 'n';
	$character[2][1] = $character[3][1] = $character[4][1] = $character[5][1]
	    = ')';
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(8);
	$character[2][1] = $character[3][0] = $character[4][0] = $character[5][1]
	    = 'o';
	$character[2][2] = $character[3][1] = $character[4][1] = $character[5][2]
	    = ')';
	$character[2][3] = $character[2][4] = $character[2][5] = $character[3][5]
	    = $character[3][6] = $character[4][5] = $character[4][6]
	    = $character[5][3] = $character[5][4] = $character[5][5] = 'O';
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(8);
	$character[2][1] = $character[3][1] = $character[4][1] = $character[5][1]
	    = $character[6][1] = $character[7][1] = ')';
	$character[2][0] = $character[3][0] = $character[4][0] = $character[5][0]
	    = $character[6][0] = $character[7][0] = 'p';
	$character[2][2] = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][5] = $character[3][6] = $character[4][5]
	    = $character[4][6] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = 'P';
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(8);
	$character[2][3] = $character[2][4] = $character[2][5] = $character[3][5]
	    = $character[3][6] = $character[4][5] = $character[4][6]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = 'Q';
	$character[2][1] = $character[3][0] = $character[4][0] = $character[5][1]
	    = $character[6][5] = $character[7][5] = 'q';
	$character[2][2] = $character[3][1] = $character[4][1] = $character[5][2]
	    = $character[6][6] = $character[7][6] = ')';
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(8);
	$character[2][2] = $character[3][1] = $character[4][1] = $character[5][1]
	    = ')';
	$character[2][3] = $character[2][4] = $character[2][5] = $character[3][5]
	    = $character[3][6] = 'R';
	$character[2][1] = $character[3][0] = $character[4][0] = $character[5][0]
	    = 'r';
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(8);
	$character[2][3] = $character[2][4] = $character[2][5] = $character[2][6]
	    = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = 'S';
	$character[2][1] = $character[3][0] = $character[4][5] = $character[5][0]
	    = 's';
	$character[2][2] = $character[3][1] = $character[4][6] = $character[5][1]
	    = ')';
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(7);
	$character[0][3] = $character[1][1] = $character[2][3] = $character[3][3]
	    = $character[4][3] = $character[5][3] = ')';
	$character[1][3] = $character[1][4] = $character[1][5] = $character[5][4]
	    = 'T';
	$character[0][2] = $character[1][0] = $character[1][2] = $character[2][2]
	    = $character[3][2] = $character[4][2] = $character[5][2] = 't';
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(8);
	$character[2][1] = $character[3][1] = $character[4][1] = $character[5][2]
	    = ')';
	$character[2][0] = $character[3][0] = $character[4][0] = $character[5][1]
	    = 'u';
	$character[2][5] = $character[2][6] = $character[3][5] = $character[3][6]
	    = $character[4][5] = $character[4][6] = $character[5][3]
	    = $character[5][4] = $character[5][5] = 'U';
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(9);
	$character[2][1] = $character[3][2] = $character[4][3] = $character[5][4]
	    = ')';
	$character[2][6] = $character[2][7] = $character[3][5] = $character[3][6]
	    = $character[4][4] = $character[4][5] = 'V';
	$character[2][0] = $character[3][1] = $character[4][2] = $character[5][3]
	    = 'v';
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(11);
	$character[2][1] = $character[3][1] = $character[4][1] = $character[5][2]
	    = ')';
	$character[2][0] = $character[3][0] = $character[4][0] = $character[5][1]
	    = 'w';
	$character[2][8] = $character[2][9] = $character[3][4] = $character[3][5]
	    = $character[3][8] = $character[3][9] = $character[4][4]
	    = $character[4][5] = $character[4][8] = $character[4][9]
	    = $character[5][3] = $character[5][4] = $character[5][6]
	    = $character[5][7] = $character[5][8] = 'W';
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(8);
	$character[2][0] = $character[3][2] = $character[4][2] = $character[5][0]
	    = 'x';
	$character[2][5] = $character[2][6] = $character[3][4] = $character[4][4]
	    = $character[5][5] = $character[5][6] = 'X';
	$character[2][1] = $character[3][3] = $character[4][3] = $character[5][1]
	    = ')';
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(8);
	$character[2][1] = $character[3][1] = $character[4][1] = $character[5][2]
	    = $character[6][6] = $character[7][1] = ')';
	$character[2][0] = $character[3][0] = $character[4][0] = $character[5][1]
	    = $character[6][5] = $character[7][0] = 'y';
	$character[2][5] = $character[2][6] = $character[3][5] = $character[3][6]
	    = $character[4][5] = $character[4][6] = $character[5][3]
	    = $character[5][4] = $character[5][5] = $character[5][6]
	    = $character[7][2] = $character[7][3] = $character[7][4]
	    = $character[7][5] = 'Y';
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(8);
	$character[2][0] = $character[3][4] = $character[4][2] = $character[5][0]
	    = 'z';
	$character[2][1] = $character[3][5] = $character[4][3] = $character[5][1]
	    = ')';
	$character[2][2] = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[2][6] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = $character[5][6] = 'Z';
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[1][1] = $character[1][4] = $character[1][5]
	    = $character[1][6] = $character[2][1] = $character[2][3]
	    = $character[2][5] = $character[2][6] = $character[3][1]
	    = $character[3][3] = $character[3][5] = $character[3][6]
	    = $character[4][1] = $character[4][2] = $character[4][5]
	    = $character[4][6] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = ')';
	$character[0][1] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][1] = '0';
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = $character[1][1] = $character[2][3] = $character[3][3]
	    = $character[4][3] = $character[5][0] = '1';
	$character[0][3] = $character[1][2] = $character[2][4] = $character[3][4]
	    = $character[4][4] = $character[5][1] = ')';
	$character[0][4] = $character[1][3] = $character[1][4] = $character[5][2]
	    = $character[5][3] = $character[5][4] = $character[5][5]
	    = $character[5][6] = '!';
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[1][5]
	    = $character[1][6] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = $character[5][6] = 'A';
	$character[0][2] = $character[1][1] = $character[2][5] = $character[3][4]
	    = $character[4][3] = $character[5][1] = ')';
	$character[0][1] = $character[1][0] = $character[2][4] = $character[3][3]
	    = $character[4][2] = $character[5][0] = '2';
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[1][5]
	    = $character[1][6] = $character[2][5] = $character[4][5]
	    = $character[4][6] = $character[5][3] = $character[5][4]
	    = $character[5][5] = '#';
	$character[0][2] = $character[1][1] = $character[2][4] = $character[3][6]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][1] = $character[1][0] = $character[2][3] = $character[3][5]
	    = $character[4][0] = $character[5][1] = '3';
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][6]
	    = $character[4][6] = $character[5][6] = ')';
	$character[0][5] = $character[0][6] = $character[1][5] = $character[1][6]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[2][6] = 'S';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][5]
	    = $character[4][5] = $character[5][5] = '4';
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[5][2] = $character[5][3]
	    = $character[5][4] = $character[5][5] = '%';
	$character[0][1] = $character[1][1] = $character[2][1] = $character[3][6]
	    = $character[4][6] = $character[5][1] = ')';
	$character[0][0] = $character[1][0] = $character[2][0] = $character[3][5]
	    = $character[4][5] = $character[5][0] = '5';
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[1][0] = $character[2][0] = $character[3][0]
	    = $character[4][0] = $character[5][1] = '6';
	$character[0][2] = $character[1][1] = $character[2][1] = $character[3][1]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][3] = $character[0][4] = $character[0][5] = $character[2][2]
	    = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][5] = $character[3][6] = $character[4][5]
	    = $character[4][6] = $character[5][3] = $character[5][4]
	    = $character[5][5] = 'N';
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[1][5] = $character[2][4] = $character[3][3]
	    = $character[4][2] = $character[5][1] = ')';
	$character[0][0] = $character[1][4] = $character[2][3] = $character[3][2]
	    = $character[4][1] = $character[5][0] = '7';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = '&';
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[1][5]
	    = $character[1][6] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[3][5] = $character[3][6]
	    = $character[4][5] = $character[4][6] = $character[5][3]
	    = $character[5][4] = $character[5][5] = '*';
	$character[0][2] = $character[1][1] = $character[2][2] = $character[3][1]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][1] = $character[1][0] = $character[2][1] = $character[3][0]
	    = $character[4][0] = $character[5][1] = '8';
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[1][5]
	    = $character[1][6] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[2][6] = $character[4][5]
	    = $character[4][6] = $character[5][3] = $character[5][4]
	    = $character[5][5] = '(';
	$character[0][2] = $character[1][1] = $character[2][2] = $character[3][6]
	    = $character[4][1] = $character[5][2] = ')';
	$character[0][1] = $character[1][0] = $character[2][1] = $character[3][5]
	    = $character[4][0] = $character[5][1] = '9';
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Tanja - Tanja Font

=head1 VERSION

Version 0.21

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use Ascii::Text::Font::Tanja;

	my $foo = Ascii::Text::Font::Tanja->new();

	...

=head1 EXTENDS

=head2 Ascii::Text::Font

=head1 SUBROUTINES/METHODS

=head2 space

=head2 character_A

	  A)aa   
	 A)  aa  
	A)    aa 
	A)aaaaaa 
	A)    aa 
	A)    aa 
	         
	         

=head2 character_B

	B)bbbb   
	B)   bb  
	B)bbbb   
	B)   bb  
	B)    bb 
	B)bbbbb  
	         
	         

=head2 character_C

	  C)ccc  
	 C)   cc 
	C)       
	C)       
	 C)   cc 
	  C)ccc  
	         
	         

=head2 character_D

	D)dddd   
	D)   dd  
	D)    dd 
	D)    dd 
	D)    dd 
	D)ddddd  
	         
	         

=head2 character_E

	E)eeeeee 
	E)       
	E)eeeee  
	E)       
	E)       
	E)eeeeee 
	         
	         

=head2 character_F

	F)ffffff 
	F)       
	F)fffff  
	F)       
	F)       
	F)       
	         
	         

=head2 character_G

	  G)gggg 
	 G)      
	G)  ggg  
	G)    gg 
	 G)   gg 
	  G)ggg  
	         
	         

=head2 character_H

	H)    hh 
	H)    hh 
	H)hhhhhh 
	H)    hh 
	H)    hh 
	H)    hh 
	         
	         

=head2 character_I

	I)iiii 
	  I)   
	  I)   
	  I)   
	  I)   
	I)iiii 
	       
	       

=head2 character_J

	J)jjjjjj 
	    J)   
	    J)   
	J)  jj   
	J)  jj   
	 J)jj    
	         
	         

=head2 character_K

	K)   kk  
	K)  kk   
	K)kkk    
	K)  kk   
	K)   kk  
	K)    kk 
	         
	         

=head2 character_L

	L)       
	L)       
	L)       
	L)       
	L)       
	L)llllll 
	         
	         

=head2 character_M

	 M)mm mmm  
	M)  mm  mm 
	M)  mm  mm 
	M)  mm  mm 
	M)      mm 
	M)      mm 
	           
	           

=head2 character_N

	N)n   nn 
	N)nn  nn 
	N) nn nn 
	N)  nnnn 
	N)   nnn 
	N)    nn 
	         
	         

=head2 character_O

	 O)oooo  
	O)    oo 
	O)    oo 
	O)    oo 
	O)    oo 
	 O)oooo  
	         
	         

=head2 character_P

	P)ppppp  
	P)    pp 
	P)ppppp  
	P)       
	P)       
	P)       
	         
	         

=head2 character_Q

	 Q)qqqq  
	Q)    qq 
	Q)    qq 
	Q)  qq q 
	Q)   qq  
	 Q)qqq q 
	         
	         

=head2 character_R

	R)rrrrr  
	R)    rr 
	R)  rrr  
	R) rr    
	R)   rr  
	R)    rr 
	         
	         

=head2 character_S

	 S)ssss  
	S)    ss 
	 S)ss    
	     S)  
	S)    ss 
	 S)ssss  
	         
	         

=head2 character_T

	T)tttttt 
	   T)    
	   T)    
	   T)    
	   T)    
	   T)    
	         
	         

=head2 character_U

	U)    uu 
	U)    uu 
	U)    uu 
	U)    uu 
	U)    uu 
	 U)uuuu  
	         
	         

=head2 character_V

	V)    vv 
	V)    vv 
	V)    vv 
	 V)  vv  
	  V)vv   
	   V)    
	         
	         

=head2 character_W

	W)      ww 
	W)      ww 
	W)  ww  ww 
	W)  ww  ww 
	W)  ww  ww 
	 W)ww www  
	           
	           

=head2 character_X

	X)    xx 
	 X)  xx  
	  X)xx   
	  X)xx   
	 X)  xx  
	X)    xx 
	         
	         

=head2 character_Y

	Y)    yy 
	 Y)  yy  
	  Y)yy   
	   Y)    
	   Y)    
	   Y)    
	         
	         

=head2 character_Z

	Z)zzzzzz 
	      Z) 
	    Z)   
	   Z)    
	 Z)      
	Z)zzzzzz 
	         
	         

=head2 character_a

	        
	        
	a)AAAA  
	 a)AAA  
	a)   A  
	 a)AAAA 
	        
	        

=head2 character_b

	b)      
	b)      
	b)BBBB  
	b)   BB 
	b)   BB 
	b)BBBB  
	        
	        

=head2 character_c

	        
	        
	 c)CCCC 
	c)      
	c)      
	 c)CCCC 
	        
	        

=head2 character_d

	     d) 
	     d) 
	 d)DDDD 
	d)   DD 
	d)   DD 
	 d)DDDD 
	        
	        

=head2 character_e

	        
	        
	e)EEEEE 
	e)EEEE  
	e)      
	 e)EEEE 
	        
	        

=head2 character_f

	 f)FFF 
	f)     
	f)FFF  
	f)     
	f)     
	f)     
	       
	       

=head2 character_g

	        
	        
	 g)GGG  
	g)   GG 
	g)   GG 
	 g)GGGG 
	     GG 
	g)GGGG  

=head2 character_h

	h)      
	h)      
	h)HHHH  
	h)   HH 
	h)   HH 
	h)   HH 
	        
	        

=head2 character_i

	## 
	   
	i) 
	i) 
	i) 
	i) 
	   
	   

=head2 character_j

	     ## 
	        
	     j) 
	     j) 
	     j) 
	     j) 
	j)   JJ 
	 j)JJJ  

=head2 character_k

	k)     
	k)     
	k)  KK 
	k)KK   
	k) KK  
	k)  KK 
	       
	       

=head2 character_l

	l)L  
	 l)  
	 l)  
	 l)  
	 l)  
	l)LL 
	     
	     

=head2 character_m

	           
	           
	 m)MM MMM  
	m)  MM  MM 
	m)  MM  MM 
	m)      MM 
	           
	           

=head2 character_n

	        
	        
	n)NNNN  
	n)   NN 
	n)   NN 
	n)   NN 
	        
	        

=head2 character_o

	        
	        
	 o)OOO  
	o)   OO 
	o)   OO 
	 o)OOO  
	        
	        

=head2 character_p

	        
	        
	p)PPPP  
	p)   PP 
	p)   PP 
	p)PPPP  
	p)      
	p)      

=head2 character_q

	        
	        
	 q)QQQ  
	q)   QQ 
	q)   QQ 
	 q)QQQQ 
	     q) 
	     q) 

=head2 character_r

	        
	        
	 r)RRR  
	r)   RR 
	r)      
	r)      
	        
	        

=head2 character_s

	        
	        
	 s)SSSS 
	s)SSSS  
	     s) 
	s)SSSS  
	        
	        

=head2 character_t

	  t)   
	t)tTTT 
	  t)   
	  t)   
	  t)   
	  t)T  
	       
	       

=head2 character_u

	        
	        
	u)   UU 
	u)   UU 
	u)   UU 
	 u)UUU  
	        
	        

=head2 character_v

	         
	         
	v)    VV 
	 v)  VV  
	  v)VV   
	   v)    
	         
	         

=head2 character_w

	           
	           
	w)      WW 
	w)  WW  WW 
	w)  WW  WW 
	 w)WW WWW  
	           
	           

=head2 character_x

	        
	        
	x)   XX 
	  x)X   
	  x)X   
	x)   XX 
	        
	        

=head2 character_y

	        
	        
	y)   YY 
	y)   YY 
	y)   YY 
	 y)YYYY 
	     y) 
	y)YYYY  

=head2 character_z

	        
	        
	z)ZZZZZ 
	    z)  
	  z)    
	z)ZZZZZ 
	        
	        

=head2 character_0

	 0))))  
	0)  ))) 
	0) ) )) 
	0) ) )) 
	0))  )) 
	 0))))  
	        
	        

=head2 character_1

	  1)!   
	 1)!!   
	   1)   
	   1)   
	   1)   
	1)!!!!! 
	        
	        

=head2 character_2

	 2)AAA  
	2)   AA 
	    2)  
	   2)   
	  2)    
	2)AAAAA 
	        
	        

=head2 character_3

	 3)###  
	3)   ## 
	   3)#  
	     3) 
	3)   ## 
	 3)###  
	        
	        

=head2 character_4

	4)   SS 
	4)   SS 
	4)SSSSS 
	     4) 
	     4) 
	     4) 
	        
	        

=head2 character_5

	5)%%%%  
	5)      
	5)%%%%  
	     5) 
	     5) 
	5)%%%%  
	        
	        

=head2 character_6

	 6)NNN  
	6)      
	6)NNNN  
	6)   NN 
	6)   NN 
	 6)NNN  
	        
	        

=head2 character_7

	7)&&&&& 
	    7)  
	   7)   
	  7)    
	 7)     
	7)      
	        
	        

=head2 character_8

	 8)***  
	8)   ** 
	 8)***  
	8)   ** 
	8)   ** 
	 8)***  
	        
	        

=head2 character_9

	 9)(((  
	9)   (( 
	 9)(((( 
	     9) 
	9)   (( 
	 9)(((  
	        

=head1 PROPERTY

=head2 character_height

=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::tanja at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Tanja>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Tanja

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Tanja>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Tanja>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Tanja>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Tanja>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
