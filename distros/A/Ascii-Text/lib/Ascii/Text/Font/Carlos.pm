package Ascii::Text::Font::Carlos;

use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable => 0,
	writable => 0,
	value => 8
);

function character_A => sub {
	my @character = $_[0]->default_character(10);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = '_';
	$character[1][2] = '(';
	$character[1][7] = ')';
	$character[2][0] = $character[2][1] = $character[2][3] = $character[2][6] = $character[2][8] = $character[2][9] = ' ';
	$character[2][2] = $character[2][4] = '/';
	$character[2][5] = $character[2][7] = '\\';
	$character[3][1] = $character[3][3] = '(';
	$character[3][4] = $character[3][5] = '_';
	$character[3][6] = $character[3][8] = ')';
	$character[4][2] = ')';
	$character[4][7] = '(';
	$character[5][1] = $character[5][4] = '/';
	$character[5][5] = $character[5][8] = '\\';
	$character[6][0] = '/';
	$character[6][1] = $character[6][2] = $character[6][7] = $character[6][8] = '_';
	$character[6][3] = '(';
	$character[6][6] = ')';
	$character[6][9] = '\\';
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[2][5] = $character[4][5] = $character[5][5] = '_';
	$character[0][5] = $character[0][6] = $character[1][1] = $character[1][5] = $character[3][6] = $character[5][1] = '_';
	$character[1][0] = $character[2][4] = $character[5][4] = $character[6][0] = '(';
	$character[1][7] = $character[3][2] = $character[4][7] = '\\';
	$character[2][2] = $character[2][6] = $character[2][8] = $character[5][2] = $character[5][6] = $character[5][8] = ')';
	$character[3][7] = $character[4][2] = $character[6][7] = '/';
	$character[6][1] = $character[6][2] = $character[6][3] = $character[6][4] = $character[6][5] = $character[6][6] = '_';
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(8);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[1][4] = $character[1][5] = $character[1][6] = $character[5][4] = $character[5][5] = $character[5][6] = $character[6][3] = $character[6][4] = $character[6][5] = $character[6][6] = '_';
	$character[1][2] = $character[2][1] = $character[2][3] = '/';
	$character[5][1] = $character[5][3] = $character[6][2] = '\\';
	$character[3][0] = $character[3][2] = $character[4][0] = $character[4][2] = '(';
	$character[1][7] = $character[6][7] = ')';
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(10);
	$character[0][1] = '_';
	$character[0][2] = '_';
	$character[0][3] = '_';
	$character[0][4] = '_';
	$character[0][5] = '_';
	$character[0][6] = '_';

	$character[1][0] = '(';
	$character[1][1] = '_';
	$character[1][4] = '_';
	$character[1][5] = '_';
	$character[1][7] = '\\';

	$character[2][2] = ')';
	$character[2][4] = ')';
	$character[2][6] = '\\';
	$character[2][8] = '\\';

	$character[3][1] = '(';
	$character[3][3] = '(';
	$character[3][7] = ')';
	$character[3][9] = ')';

	$character[4][2] = ')';
	$character[4][4] = ')';
	$character[4][7] = ')';
	$character[4][9] = ')';

	$character[5][1] = '/';
	$character[5][3] = '/';
	$character[5][4] = '_';
	$character[5][5] = '_';
	$character[5][6] = '/';
	$character[5][8] = '/';

	$character[6][0] = '(';
	$character[6][1] = '_';
	$character[6][2] = '_';
	$character[6][3] = '_';
	$character[6][4] = '_';
	$character[6][5] = '_';
	$character[6][6] = '_';
	$character[6][7] = '/';

	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = '_';
	$character[0][3] = '_';
	$character[0][4] = '_';
	$character[0][5] = '_';
	$character[0][6] = '_';

	$character[1][1] = '/';
	$character[1][3] = '_';
	$character[1][4] = '_';
	$character[1][5] = '_';
	$character[1][6] = '/';

	$character[2][0] = '(';
	$character[2][2] = '(';
	$character[2][3] = '_';
	$character[2][4] = '_';

	$character[3][1] = ')';
	$character[3][3] = '_';
	$character[3][4] = '_';
	$character[3][5] = ')';

	$character[4][0] = '(';
	$character[4][2] = '(';

	$character[5][1] = '\\';
	$character[5][3] = '\\';
	$character[5][4] = '_';
	$character[5][5] = '_';
	$character[5][6] = '_';

	$character[6][2] = '\\';
	$character[6][3] = '_';
	$character[6][4] = '_';
	$character[6][5] = '_';
	$character[6][6] = '_';
	$character[6][7] = '\\';
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(11);
	$character[0][1] = '_';
	$character[0][2] = '_';
	$character[0][3] = '_';
	$character[0][4] = '_';
	$character[0][5] = '_';
	$character[0][6] = '_';
	$character[0][7] = '_';
	$character[0][8] = '_';
	$character[0][9] = '_';

	$character[1][0] = '(';
	$character[1][1] = '_';
	$character[1][5] = '_';
	$character[1][6] = '_';
	$character[1][7] = '_';
	$character[1][8] = '_';
	$character[1][9] = '_';
	$character[1][10] = ')';

	$character[2][2] = ')';
	$character[2][4] = '(';
	$character[2][5] = '_';
	$character[2][6] = '_';
	$character[2][7] = '_';

	$character[3][1] = '(';
	$character[3][5] = '_';
	$character[3][6] = '_';
	$character[3][7] = '_';
	$character[3][8] = ')';

	$character[4][2] = ')';
	$character[4][4] = '(';

	$character[5][1] = '(';
	$character[5][5] = ')';

	$character[6][2] = '\\';
	$character[6][3] = '_';
	$character[6][4] = '/';
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(10);
	$character[0][3] = '_';
	$character[0][4] = '_';
	$character[0][5] = '_';
	$character[0][6] = '_';
	$character[0][7] = '_';

	$character[1][2] = '/';
	$character[1][4] = '_';
	$character[1][5] = '_';
	$character[1][6] = '_';
	$character[1][8] = '\\';

	$character[2][1] = '/';
	$character[2][3] = '/';
	$character[2][7] = '\\';
	$character[2][8] = '_';
	$character[2][9] = ')';

	$character[3][0] = '(';
	$character[3][2] = '(';
	$character[3][5] = '_';
	$character[3][6] = '_';
	$character[3][7] = '_';
	$character[3][8] = '_';

	$character[4][0] = '(';
	$character[4][2] = '(';
	$character[4][4] = '(';
	$character[4][5] = '_';
	$character[4][6] = '_';
	$character[4][9] = ')';

	$character[5][1] = '\\';
	$character[5][3] = '\\';
	$character[5][4] = '_';
	$character[5][5] = '_';
	$character[5][6] = '/';
	$character[5][8] = '/';

	$character[6][2] = '\\';
	$character[6][3] = '_';
	$character[6][4] = '_';
	$character[6][5] = '_';
	$character[6][6] = '_';
	$character[6][7] = '/';
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(10);
	$character[0][0] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[1][1] = $character[1][2] = $character[1][4] = $character[1][5] = $character[1][7] = $character[1][8] = $character[2][0] = $character[2][2] = $character[2][7] = $character[3][0] = $character[3][1] = $character[3][3] = $character[3][6] = $character[4][0] = $character[4][2] = $character[4][4] = $character[4][5] = $character[4][7] = $character[5][0] = $character[5][1] = $character[5][3] = $character[5][6] = $character[6][0] = $character[6][4] = $character[6][5] = ' ';
	$character[0][1] = $character[0][2] = $character[0][7] = $character[0][8] = $character[2][4] = $character[2][5] = $character[3][4] = $character[3][5] = $character[6][2] = $character[6][7] = '_';
	$character[1][0] = $character[2][3] = $character[3][7] = $character[4][1] = $character[4][3] = $character[5][5] = $character[5][7] = '(';
	$character[1][3] = $character[2][1] = $character[6][6] = $character[6][8] = '\\';
	$character[1][6] = $character[2][8] = $character[6][1] = $character[6][3] = '/';
	$character[1][9] = $character[2][6] = $character[3][2] = $character[4][6] = $character[4][8] = $character[5][2] = $character[5][4] = ')';
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[1][2] = $character[1][6] = $character[5][2] = $character[5][6] = $character[5][7] = $character[6][2] = $character[6][3] = $character[6][4] = $character[6][5] = $character[6][6] = '_';
	$character[2][3] = $character[2][5] = $character[3][3] = $character[3][5] = $character[4][3] = $character[4][5] = $character[5][3] = $character[5][5] = '|';
	$character[1][1] = $character[6][7] = '(';
	$character[1][7] = ')';
	$character[6][1] = '/';
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(11);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[1][2] = $character[1][3] = $character[1][4] = $character[1][7] = $character[1][8] = $character[1][9] = $character[4][1] = $character[4][2] = $character[5][3] = $character[6][2] = $character[6][3] = $character[6][4] = '_';
	$character[1][1] = $character[3][4] = $character[3][6] = $character[5][0] = $character[5][2] = '(';
	$character[1][10] = $character[2][5] = $character[2][7] = $character[4][5] = $character[4][7] = ')';
	$character[5][4] = $character[5][6] = $character[6][5] = '/';
	$character[6][1] = '\\';
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(10);
	$character[0][1] = $character[0][2] = $character[0][6] = $character[0][7] = $character[0][8] = $character[1][7] = $character[1][8] = $character[2][3] = $character[6][2] = $character[6][7] = '_';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[2][2] = $character[3][5] = $character[5][2] = '(';
	$character[1][1] = $character[3][1] = $character[4][1] = $character[6][1] = $character[6][3] = $character[1][3] = $character[1][9] = ')';
	$character[4][3] = $character[2][4] = $character[1][5] = $character[2][6] = '/';
	$character[4][4] = $character[5][5] = $character[6][6] = $character[4][6] = $character[5][7] = $character[6][8] = '\\';
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(11);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][1] = $character[1][5] = $character[5][0] = $character[5][1] = $character[5][5] = $character[5][6] = $character[5][7] = $character[4][8] = $character[4][9] = $character[6][1] = $character[6][2] = $character[6][3] = $character[6][4] = $character[6][5] = $character[6][6] = $character[6][7] = $character[6][8] = '_';
	$character[6][0] = '\\';
	$character[6][9] = '/';
	$character[2][2] = $character[2][4] = $character[3][2] = $character[3][4] = $character[4][2] = $character[4][4] = $character[5][2] = $character[5][4] = '|';
	$character[1][0] = '(';
	$character[1][6] = $character[5][8] = $character[5][10] = ')';
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(14);
	$character[6][1] = $character[5][1] = $character[4][2] = $character[3][3] = $character[5][3] = $character[4][4] = $character[2][7] = $character[4][7] = $character[1][8] = $character[1][10] = '/';
	$character[1][3] = $character[1][5] = $character[2][6] = $character[4][6] = $character[3][10] = $character[4][9] = $character[5][10] = $character[4][11] = $character[5][12] = $character[6][12] = '\\';
	$character[0][3] = $character[0][4] = $character[0][9] = $character[0][10] = $character[3][5] = $character[3][8] = $character[5][2] = $character[5][11] = '_';
	$character[2][4] = $character[2][10] = $character[6][13] = ')';
	$character[2][3] = $character[2][9] = $character[6][0] = '(';
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(14);
	$character[3][2] = $character[3][4] = $character[3][6] = $character[3][8] = $character[3][10] = $character[3][12] = $character[1][13] = ')';
	$character[6][0] = $character[4][1] = $character[4][3] = $character[4][5] = $character[4][7] = $character[4][9] = $character[4][11] = '(';
	$character[1][3] = $character[2][2] = $character[2][4] = $character[5][1] = $character[5][3] = $character[6][2] = $character[1][11] = $character[2][10] = $character[2][12] = $character[5][9] = $character[5][11] = $character[6][10] = '/';
	$character[1][6] = $character[2][5] = $character[2][7] = $character[5][6] = $character[5][8] = $character[6][7] = '\\';
	$character[0][4] = $character[0][5] = $character[0][12] = $character[6][1] = $character[6][8] = $character[6][9] = '_';
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(11);
	$character[0][3] = '_';
	$character[0][4] = '_';
	$character[0][5] = '_';
	$character[0][6] = '_';
	$character[1][2] = '/';
	$character[1][4] = '_';
	$character[1][5] = '_';
	$character[1][7] = '\\';

	$character[2][1] = '/';
	$character[2][3] = '/';
	$character[2][6] = '\\';
	$character[2][8] = '\\';

	$character[3][0] = '(';
	$character[3][2] = '(';
	$character[3][3] = ')';
	$character[3][6] = '(';
	$character[3][7] = ')';
	$character[3][9] = ')';
	$character[4][0] = '(';
	$character[4][2] = '(';
	$character[4][3] = ')';
	$character[4][6] = '(';
	$character[4][7] = ')';
	$character[4][9] = ')';
	$character[5][1] = '\\';
	$character[5][3] = '\\';
	$character[5][4] = '_';
	$character[5][5] = '_';
	$character[5][6] = '/';
	$character[5][8] = '/';
	$character[6][2] = '\\';
	$character[6][3] = '_';
	$character[6][4] = '_';
	$character[6][5] = '_';
	$character[6][6] = '_';
	$character[6][7] = '/';
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(9);
	$character[0][1]=$character[0][2]=$character[0][3]=$character[0][4]=$character[0][5]=$character[1][3]=$character[1][4]=$character[2][4]=$character[3][4]=$character[3][5]=$character[6][1]=$character[6][2]='_';
	$character[1][0]=$character[3][0]=$character[5][0]=$character[5][2]='(';
	$character[1][6]=$character[6][3]='\\';
	$character[2][1]=$character[4][1]=$character[4][3]=$character[2][3]=$character[2][5]=$character[2][7]=')';
	$character[3][6]=$character[6][0]='/';
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(11);
	$character[0][3] = '_';
	$character[0][4] = '_';
	$character[0][5] = '_';
	$character[0][6] = '_';
	$character[1][2] = '/';
	$character[1][4] = '_';
	$character[1][5] = '_';
	$character[1][7] = '\\';

	$character[2][1] = '/';
	$character[2][3] = '/';
	$character[2][6] = '\\';
	$character[2][8] = '\\';

	$character[3][0] = '(';
	$character[3][2] = '(';
	$character[3][7] = ')';
	$character[3][9] = ')';
	$character[4][0] = '(';
	$character[4][2] = '(';
	$character[4][5] = '/';
	$character[4][6] = '\\';
	$character[4][7] = ')';
	$character[4][9] = ')';
	$character[5][1] = '\\';
	$character[5][3] = '\\';
	$character[5][4] = '_';
	$character[5][5] = '\\';
	$character[5][7] = '\\';
	$character[5][8] = '/';
	$character[6][2] = '\\';
	$character[6][3] = '_';
	$character[6][4] = '_';
	$character[6][5] = '_';
	$character[6][6] = '\\';
	$character[6][8] = '\\';
	$character[6][9] = '_';

	$character[7][10] = ')';
	$character[7][9] = $character[7][8] = '_';
	$character[7][7] = '\\';
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(10);
       $character[1][0] = $character[3][0] = $character[5][0] = $character[2][3] = $character[5][2] = '(';
	$character[2][1] = $character[4][1] = $character[6][1] = $character[6][3] = $character[5][8] = $character[5][9] = $character[2][6] = $character[2][8] = ')';
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = '_';
	$character[1][4] = $character[1][5] = $character[2][4] = $character[2][5] = $character[3][5] = $character[3][6] = $character[4][8] = $character[5][7] = $character[6][2] = $character[6][6] = $character[6][7] = '_';
	$character[1][7] = $character[4][3] = $character[5][4] = $character[6][5] = $character[4][5] = $character[5][6] = '\\';
	$character[3][7] = $character[6][8] = '/';
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(9);
	$character[0][3] = '_';
	$character[0][4] = '_';
	$character[0][5] = '_';
	$character[0][6] = '_';
	$character[0][7] = ' ';
	$character[1][1] = '/';
	$character[1][3] = '_';
	$character[1][4] = '_';
	$character[1][5] = '_';
	$character[1][6] = '_';
	$character[1][7] = '\\';
	$character[2][0] = '(';
	$character[2][1] = ' ';
	$character[2][2] = '(';
	$character[2][3] = '_';
	$character[2][4] = '_';
	$character[2][5] = '_';
	$character[3][1] = '\\';
	$character[3][2] = '_';
	$character[3][3] = '_';
	$character[3][4] = '_';
	$character[3][5] = '_';
	$character[3][7] = '\\';
	$character[4][6] = ')';
	$character[4][8] = ')';
	$character[5][4] = '_';
	$character[5][3] = '_';
	$character[5][2] = '_';
	$character[5][5] = '/';
	$character[5][7] = '/';
	$character[6][1] = '/';
	$character[6][2] = '_';
	$character[6][3] = '_';
	$character[6][4] = '_';
	$character[6][5] = '_';
	$character[6][6] = '/';
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(10);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][1] = $character[1][2] = $character[1][3] = $character[0][4] = $character[0][5] = $character[6][4] = $character[6][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[1][6] = $character[1][7] = $character[1][8] = '_';
	$character[1][0] = $character[3][3] = $character[5][3] = $character[3][5] = $character[5][5] = '(';
	$character[1][9] = $character[2][4] = $character[4][4] = $character[2][6] = $character[4][6] = ')';
	$character[6][3] = '/';
	$character[6][6] = '\\';
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(11);
	$character[0][0] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][9] = $character[0][10] = $character[1][0] = $character[1][2] = $character[1][4] = $character[1][5] = $character[1][7] = $character[1][9] = $character[1][10] = $character[2][1] = $character[2][3] = $character[2][4] = $character[2][5] = $character[2][6] = $character[2][8] = $character[2][10] = $character[3][0] = $character[3][2] = $character[3][4] = $character[3][5] = $character[3][7] = $character[3][9] = $character[3][10] = $character[4][1] = $character[4][3] = $character[4][4] = $character[4][5] = $character[4][6] = $character[4][8] = $character[4][10] = $character[5][0] = $character[5][2] = $character[5][7] = $character[5][9] = $character[5][10] = $character[6][0] = $character[6][9] = $character[6][10] = ' ';
	$character[0][1] = $character[0][2] = $character[0][7] = $character[0][8] = $character[5][4] = $character[5][5] = $character[6][2] = $character[6][3] = $character[6][4] = $character[6][5] = $character[6][6] = $character[6][7] = '_';
	$character[1][1] = $character[1][3] = $character[2][7] = $character[2][9] = $character[3][1] = $character[3][3] = $character[4][7] = $character[4][9] = $character[5][1] = ')';
	$character[1][6] = $character[1][8] = $character[2][0] = $character[2][2] = $character[3][6] = $character[3][8] = $character[4][0] = $character[4][2] = $character[5][8] = '(';
	$character[5][3] = $character[6][1] = '\\';
	$character[5][6] = $character[6][8] = '/';
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(10);
	$character[3][1] = $character[3][3] = $character[4][2] = $character[4][4] = $character[5][3] = $character[6][4] ='\\';
	$character[3][8] = $character[3][6] = $character[4][7] = $character[4][5] = $character[5][6] = $character[6][5] ='/';
	$character[0][1] = $character[0][2] = $character[0][7] = $character[0][8] = '_';
	$character[2][0] = $character[2][2] = $character[1][8] = $character[1][6] = '(';
	$character[1][1] = $character[1][3] = $character[2][7] = $character[2][9] = ')';
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3] = $character[6][6] = $character[6][7] =' ';
	$character[6][8] = $character[6][9] = $character[5][0] = $character[5][1] = $character[5][2] = $character[5][4] =' ';
	$character[5][5] = $character[5][7] = $character[5][8] = $character[5][9] = $character[4][0] = $character[4][1] =' ';
	$character[4][3] = $character[4][6] = $character[4][8] = $character[4][9] = $character[3][0] = $character[3][2] =' ';
	$character[3][4] = $character[3][5] = $character[3][7] = $character[3][9] = $character[2][1] = $character[2][3] =' ';
	$character[2][4] = $character[2][5] = $character[2][6] = $character[2][8] = $character[1][0] = $character[1][2] =' ';
	$character[1][4] = $character[1][5] = $character[1][7] = $character[1][9] = $character[0][0] = $character[0][3] =' ';
	$character[0][4] = $character[0][5] = $character[0][6] = $character[0][9] = ' ';
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(15);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][11] = $character[0][12] = $character[0][13] = $character[6][5] = $character[6][9] = $character[4][7] = $character[2][7] = '_';
	$character[4][11] = $character[1][0] = $character[1][3] = $character[5][6] = '(';
	$character[1][11] = $character[1][14] = $character[5][8] = $character[4][3] = ')';
	$character[2][1] = $character[2][4] = $character[3][2] = $character[3][5] = $character[5][3] = $character[6][4] = $character[3][8] = $character[6][8] = '\\';
	$character[2][10] = $character[2][13] = $character[3][9] = $character[3][12] = $character[5][11] = $character[6][10] = $character[3][6] = $character[6][6] = '/';

	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(11);
	$character[0][0] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[1][2] = $character[1][4] = $character[1][5] = $character[1][7] = $character[1][8] = $character[2][0] = $character[2][2] = $character[2][7] = $character[3][0] = $character[3][1] = $character[3][3] = $character[3][6] = $character[4][0] = $character[4][2] = $character[4][4] = $character[4][5] = $character[4][7] = $character[5][0] = $character[5][1] = $character[5][3] = $character[5][6] = $character[6][0] = $character[6][4] = $character[6][5] = ' ';
	$character[0][1] = $character[0][2] = $character[0][9] = $character[0][8] = $character[1][1] = $character[1][9] = $character[2][5] = $character[4][5] = $character[5][1] = $character[5][9] = $character[6][1] = $character[6][2] = $character[6][8] = $character[6][9] = '_';
	$character[1][0] = $character[6][0] = '(';
	$character[1][3] = $character[2][2] = $character[2][4] = $character[3][3] = $character[4][7] = $character[5][6] = $character[5][8] = $character[6][7] = '\\';
	$character[1][7] = $character[2][8] = $character[2][6] = $character[3][7] = $character[4][3] = $character[5][2] = $character[5][4] = $character[6][3] = '/';
	$character[1][10] = $character[6][10] = ')';
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(10);
	$character[0][0] = $character[0][1] = $character[0][9] = $character[0][8] = $character[6][4] = $character[6][5] = '_';
	$character[1][9] = $character[5][5] = '(';
	$character[1][0] = $character[5][4] = ')';
	$character[1][2] = $character[2][1] = $character[2][3] = $character[3][2] = $character[3][4] = $character[4][3] = $character[6][6] = '\\';
	$character[1][7] = $character[2][8] = $character[2][6] = $character[3][7] = $character[3][5] = $character[4][6] = $character[6][3] = '/';
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(10);
	$character[0][8] = '_';
	$character[0][2] = '_';
	$character[0][3] = '_';
	$character[0][4] = '_';
	$character[0][5] = '_';
	$character[0][6] = '_';
	$character[0][7] = '_';

	$character[1][1] = '(';
	$character[1][2] = '_';
	$character[1][3] = '_';
	$character[1][4] = '_';
	$character[1][5] = '_';
	$character[1][7] = ' ';
	$character[1][8] = ' ';
	$character[1][9] = ')';

	$character[2][5] = '/';
	$character[2][8] = '/';

	$character[3][1] = '_';
	$character[3][2] = '_';
	$character[3][3] = '_';
	$character[3][4] = '/';
	$character[3][5] = ' ';
	$character[3][6] = ' ';
	$character[3][7] = '/';
	$character[3][8] = '_';

	$character[4][0] = '/';
	$character[4][1] = '_';
	$character[4][2] = '_';
	$character[4][3] = ' ';
	$character[4][4] = ' ';
	$character[4][5] = ' ';
	$character[4][6] = '_';
	$character[4][7] = '_';
	$character[4][8] = '_';
	$character[4][9] = ')';

	$character[5][2] = '/';
	$character[5][4] = '/';
	$character[5][5] = '_';
	$character[5][6] = '_';
	$character[5][7] = '_';
	$character[5][8] = '_';
	$character[3][9] = ' ';

	$character[6][1] = '(';
	$character[6][2] = '_';
	$character[6][3] = '_';
	$character[6][4] = '_';
	$character[6][5] = '_';
	$character[6][6] = '_';
	$character[6][7] = '_';
	$character[6][8] = '_';
	$character[6][9] = ')';

	return \@character;
};

function character_a => sub { $_[0]->character_A };
 
function character_b => sub { $_[0]->character_B };
 
function character_c => sub { $_[0]->character_C };
 
function character_d => sub { $_[0]->character_D };
 
function character_e => sub { $_[0]->character_E };
 
function character_f => sub { $_[0]->character_F };
 
function character_g => sub { $_[0]->character_G };
 
function character_h => sub { $_[0]->character_H };
 
function character_i => sub { $_[0]->character_I };
 
function character_j => sub { $_[0]->character_J };
 
function character_k => sub { $_[0]->character_K };
 
function character_l => sub { $_[0]->character_L };
 
function character_m => sub { $_[0]->character_M };
 
function character_n => sub { $_[0]->character_N };
 
function character_o => sub { $_[0]->character_O };
 
function character_p => sub { $_[0]->character_P };
 
function character_q => sub { $_[0]->character_Q };
 
function character_r => sub { $_[0]->character_R };
 
function character_s => sub { $_[0]->character_S };
 
function character_t => sub { $_[0]->character_T };
 
function character_u => sub { $_[0]->character_U };
 
function character_v => sub { $_[0]->character_V };
 
function character_w => sub { $_[0]->character_W };
 
function character_x => sub { $_[0]->character_X };
 
function character_y => sub { $_[0]->character_Y };
 
function character_z => sub { $_[0]->character_Z };

function character_0 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = $character[1][4] = $character[5][3] = $character[5][4] = $character[6][2] = $character[6][3] = $character[6][4] = $character[6][5] = '_';
	$character[2][0] = $character[2][2] = $character[3][0] = $character[3][2] = $character[4][0] = $character[4][2] = $character[5][0] = $character[5][2] = '(';
	$character[2][5] = $character[2][7] = $character[3][5] = $character[3][7] = $character[4][5] = $character[4][7] = $character[5][5] = $character[5][7] = ')';
	$character[1][1] = $character[6][6] = '/';
	$character[1][6] = $character[6][1] = '\\';

	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(7);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[3][1] = $character[6][4] = $character[6][5] = '_';
	$character[1][2] = $character[2][1] = $character[3][0] = $character[1][6] = $character[2][3] = $character[3][2] = $character[6][3] = '/';
	$character[6][6] = '\\';
	$character[2][4] = $character[4][4] = $character[2][6] = $character[4][6] = ')';
	$character[3][3] = $character[5][3] = $character[3][5] = $character[5][5] = '(';
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(11);
	$character[0][3]= '_'; $character[0][4]= '_'; $character[0][5]= '_';
	$character[0][6]= '_'; $character[0][7]= '_'; $character[0][8]= '_'; 
	$character[1][2]= '('; $character[1][3]= '_'; $character[1][4]= '_';
	$character[1][5]= '_'; $character[1][6]= '_'; $character[1][9]= '\\';

	$character[2][7]= ')'; $character[2][9]= '/'; 
	$character[3][2]= '_'; $character[3][3]= '_'; $character[3][6]= '/'; $character[3][8]= '/'; 
	$character[4][1]= '/'; $character[4][4]= '\\';
	$character[4][5]= '/'; $character[4][7]= '/'; $character[4][9]= '_'; $character[4][10]= '_'; 
	$character[5][0]= '('; $character[5][2]= '('; $character[5][3]= ')'; $character[5][5]= '\\';
	$character[5][6]= '_'; $character[5][7]= '_'; $character[5][8]= '/'; $character[5][10]= '/'; 
	$character[6][1]= '\\';
	$character[6][2]= '_'; $character[6][3]= '_'; $character[6][4]= '\\';
	$character[6][5]= '_'; $character[6][6]= '_'; $character[6][7]= '_'; $character[6][8]= '_'; $character[6][9]= '(';
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(7);
	$character[0][0]=  $character[0][1]=  $character[0][2]= $character[0][3]= $character[0][4]= '_';
	$character[1][1]=  $character[1][2]= '_';
	$character[2][1]=  $character[2][2]= '_';
	$character[3][1]=  $character[3][2]= '_'; 
	$character[5][0]=  $character[5][1]=  $character[5][2]= '_';
	$character[6][1]=  $character[6][2]=  $character[6][3]= $character[6][4]= '_';

	$character[1][5]=  $character[4][3]=  $character[4][5]= '\\';

	$character[2][5]=  $character[5][3]=  $character[6][5]='/'; 

	$character[3][0]= $character[3][4]= '(';

	$character[1][0]= $character[2][3]=   $character[5][6]= $character[6][0]=')';
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(11);
	$character[0][2] = $character[0][6] = $character[2][3] = $character[2][4] = $character[2][8] = $character[2][9] = $character[2][10] = $character[3][2] = $character[3][3] = $character[3][4] = $character[3][8] = $character[3][9] = $character[6][5] = $character[6][6] = $character[6][7] = '_';
	$character[1][1] = $character[1][3] = $character[1][5] = $character[6][4] = '/';
	$character[1][7] = $character[3][1] = $character[6][8] = '\\';
	$character[2][0] = $character[2][2] = $character[2][7] = $character[3][10] = $character[4][7] = $character[5][7] = '(';
	$character[2][5] = $character[4][5] = $character[5][5] = ')';
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1]='_',$character[0][2]='_',$character[0][3]='_',$character[0][4]='_',$character[0][5]='_',$character[0][6]='_';
	$character[1][0]='|',$character[1][3]='_',$character[1][4]='_',$character[1][5]='_',$character[1][6]='(';
	$character[2][0]='|',$character[2][2]='|',$character[2][3]='_',$character[2][4]='_';
	$character[3][0]='|',$character[3][1]='_',$character[3][2]='_',$character[3][3]='_',$character[3][5]='\\';
	$character[4][4]='\\',$character[4][6]='\\';
	$character[5][0]='_',$character[5][1]='_',$character[5][2]='_',$character[5][3]='_',$character[5][4]='_',$character[5][5]=')',$character[5][7]=')';
	$character[6][0]=')',$character[6][1]='_',$character[6][2]='_',$character[6][3]='_',$character[6][4]='_',$character[6][5]='_',$character[6][6]='/';
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(8);
	$character[0][0] = $character[0][1] = $character[0][2] =' ';
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] ='_';
	$character[0][9] =' ' ;
	$character[1][0] = $character[1][1] =' ';
	$character[1][2] ='/';
	$character[1][3] =' ';
	$character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] ='_';
	$character[1][8] ='(';
	$character[1][9] = ' ';
	$character[2][0] =' ';
	$character[2][1] ='/';
	$character[2][2] =' ';
	$character[2][3] ='/';
	$character[2][4] = $character[2][5] = $character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = ' ';
	$character[3][0] ='(';
	$character[3][1] =' ';
	$character[3][2] ='(';
	$character[3][3] = $character[3][4] = $character[3][5] = $character[3][6] = $character[3][7] ='_';
	$character[3][8] = $character[3][9] =' ' ; 
	$character[4][0] ='(';
	$character[4][1] = $character[4][2] = $character[4][3] =' ';
	$character[4][4] = $character[4][5] = $character[4][6] ='_';
	$character[4][7] =' ';
	$character[4][8] ='\\';
	$character[4][9] =' ' ;
	$character[5][0] =' ';
	$character[5][1] ='\\';
	$character[5][2] =' ';
	$character[5][3] ='(';
	$character[5][4] = $character[5][5] = $character[5][6] ='_';
	$character[5][7] =')';
	$character[5][8] =' ';
	$character[5][9] =')' ;
	$character[6][0] = $character[6][1] =' ';
	$character[6][2] ='\\';
	$character[6][3] = $character[6][4] = $character[6][5] = $character[6][6] ='_';
	$character[6][7] ='_';
	$character[6][8] ='/';
	$character[6][9] =' '; 
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] ='_';
	$character[0][9] =' ' ;
	$character[1][0] =')';
	$character[1][1] = $character[1][2] = $character[1][3] = $character[1][4] ='_';
	$character[1][5] = $character[1][6] = $character[1][7] =' ';
	$character[1][8] ='/';
	$character[1][9] = ' ';
	$character[2][0] = $character[2][1] =' ';
	$character[2][2] = $character[2][3] = $character[2][4] ='_';
	$character[2][5] =')';
	$character[2][6] =' ';
	$character[2][7] ='/';
	$character[2][8] = $character[2][9] = ' '; 
	$character[3][0] =' ';
	$character[3][1] =')';
	$character[3][2] = $character[3][3] = $character[3][4] ='_';
	$character[3][5] =' ';
	$character[3][6] ='(';
	$character[3][7] = $character[3][8] = $character[3][9] =' ' ; 
	$character[4][0] = $character[4][1] = $character[4][2] = $character[4][3] = $character[4][4] =' ';
	$character[4][5] =')';
	$character[4][6] =' ';
	$character[4][7] =')';
	$character[4][8] = $character[4][9] =' ' ;  
	$character[5][0] = $character[5][1] = $character[5][2] = $character[5][3] =' ';
	$character[5][4] ='(';
	$character[5][5] =' ';
	$character[5][6] ='(';
	$character[5][7] = $character[5][8] = $character[5][9] =' ' ; 
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3] =' ';
	$character[6][4] ='/';
	$character[6][5] = $character[6][6] ='_';
	$character[6][7] ='\\';
	$character[6][8] = $character[6][9] =' ' ; 
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(9);
	$character[0][2]= '_'; $character[0][3]= '_'; $character[0][4]= '_'; $character[0][5]= '_'; $character[0][6]= '_'; 
	$character[1][1]= '/'; $character[1][4]= '_'; $character[1][7]= '\\';

	$character[2][0]= '('; $character[2][3]= '('; $character[2][4]= '_'; $character[2][5]= ')'; $character[2][8]= ')'; 
	$character[3][1]= '\\';
	$character[3][4]= '_'; $character[3][7]= '/'; 
	$character[4][1]= '/'; $character[4][3]= '/'; $character[4][5]= '\\';
	$character[4][7]= '\\';

	$character[5][0]= '('; $character[5][2]= '('; $character[5][3]= '_'; $character[5][4]= '_';
	$character[5][5]= '_'; $character[5][6]= ')'; $character[5][8]= ')'; 
	$character[6][1]= '\\';
	$character[6][2]= '_'; $character[6][3]= '_'; $character[6][4]= '_'; $character[6][5]= '_'; 
	$character[6][6]= '_'; $character[6][7]= '/'; 
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(11);

	$character[0][2]= '_'; $character[0][3]= '_';
	$character[0][4]= '_'; $character[0][5]= '_'; $character[0][6]= '_'; 
	$character[1][1]= '/'; $character[1][3]= '_'; 
	$character[1][4]= '_'; $character[1][7]= '\\';

	$character[2][0]= '('; $character[2][2]= '(';
	$character[2][3]= '_'; $character[2][4]= '_'; $character[2][5]= ')'; $character[2][8]= '\\';

	$character[3][1]= '\\';
	$character[3][2]= '_'; $character[3][3]= '_'; $character[3][4]= '_'; $character[3][5]= '_'; $character[3][6]= '_'; $character[3][9]= ')'; 
	$character[4][7]= ')'; $character[4][9]= ')'; 
	$character[5][2]= '_'; $character[5][3]= '_'; $character[5][4]= '_'; $character[5][5]= '_'; $character[5][6]= '/'; $character[5][8]= '/'; 
	$character[6][1]= '('; $character[6][2]= '_'; $character[6][3]= '_'; $character[6][4]= '_'; $character[6][5]= '_'; $character[6][6]= '_'; $character[6][7]= '/'; 

	return \@character;
};

function space => sub {
	my @character = $_[0]->default_character(11);
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Carlos - Carlos font

=head1 VERSION

Version 0.18

=cut

=head1 SYNOPSIS

	use Ascii::Text::Font::Carlos;

	my $font = Ascii::Text::Font::Carlos->new();

	$font->character_A;

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Ascii::Text::Font::Carlos object.

	my $font = Ascii::Text::Font::Carlos->new();

=head2 character_A

	   ____
	  (    )
	  / /\ \
	 ( (__) )
	  )    (
	 /  /\  \
	/__(  )__\


=head2 character_B

	 ______
	(_   _ \
	  ) (_) )
	  \   _/
	  /  _ \
	 _) (_) )
	(______/


=head2 character_C

	   ____
	  / ___)
	 / /
	( (
	( (
	 \ \___
	  \____)


=head2 character_D

	 ______
	(_  __ \
	  ) ) \ \
	 ( (   ) )
	  ) )  ) )
	 / /__/ /
	(______/


=head2 character_E

	  _____
	 / ___/
	( (__
	 ) __)
	( (
	 \ \___
	  \____\


=head2 character_F

	 _________
	(_   _____)
	  ) (___
	 (   ___)
	  ) (
	 (   )
	  \_/


=head2 character_G

	   _____
	  / ___ \
	 / /   \_)
	( (  ____
	( ( (__  )
	 \ \__/ /
	  \____/


=head2 character_H

	 __    __
	(  \  /  )
	 \ (__) /
	  ) __ (
	 ( (  ) )
	  ) )( (
	 /_/  \_\


=head2 character_I

	  _____
	 (_   _)
	   | |
	   | |
	   | |
	  _| |__
	 /_____(


=head2 character_J

	  ________
	 (___  ___)
	     ) )
	    ( (
	 __  ) )
	( (_/ /
	 \___/


=head2 character_K

	 __   ___
	() ) / __)
	( (_/ /
	()   (
	() /\ \
	( (  \ \
	()_)  \_\


=head2 character_L

	 _____
	(_   _)
	  | |
	  | |
	  | |   __
	__| |___) )
	\________/


=head2 character_M

	   __    __
	   \ \  / /
	   () \/ ()
	   / _  _ \
	  / / \/ \ \
	 /_/      \_\
	(/          \)


=head2 character_N

	    __      _
	   /  \    / )
	  / /\ \  / /
	  ) ) ) ) ) )
	 ( ( ( ( ( (
	 / /  \ \/ /
	(_/    \__/


=head2 character_O

	   ____
	  / __ \
	 / /  \ \
	( ()  () )
	( ()  () )
	 \ \__/ /
	  \____/


=head2 character_P

	 _____
	(  __ \
	 ) )_) )
	(   __/
	 ) )
	( (
	/__\


=head2 character_Q

	   ____
	  / __ \
	 / /  \ \
	( (    ) )
	( (  /\) )
	 \ \_\ \/
	  \___\ \_
	       \__)

=head2 character_R

	 ______
	(   __ \
	 ) (__) )
	(    __/
	 ) \ \  _
	( ( \ \_))
	 )_) \__/


=head2 character_S

	   ____
	 / ____\
	( (___
	 \____ \
	      ) )
	  ___/ /
	 /____/


=head2 character_T

	 ________
	(___  ___)
	    ) )
	   ( (
	    ) )
	   ( (
	   /__\


=head2 character_U

	 __    __
	 ) )  ( (
	( (    ) )
	 ) )  ( (
	( (    ) )
	 ) \__/ (
	 \______/


=head2 character_V

	 __    __
	 ) )  ( (
	( (    ) )
	 \ \  / /
	  \ \/ /
	   \  /
	    \/


=head2 character_W

	 ___       ___
	(  (       )  )
	 \  \  _  /  /
	  \  \/ \/  /
	   )   _   (
	   \  ( )  /
	    \_/ \_/


=head2 character_X

	 __     __
	(_ \   / _)
	  \ \_/ /
	   \   /
	   / _ \
	 _/ / \ \_
	(__/   \__)


=head2 character_Y

	__      __
	) \    / (
	 \ \  / /
	  \ \/ /
	   \  /
	    )(
	   /__\


=head2 character_Z

	  _______
	 (____   )
	     /  /
	 ___/  /_
	/__   ___)
	  / /____
	 (_______)


=head2 character_a

	   ____
	  (    )
	  / /\ \
	 ( (__) )
	  )    (
	 /  /\  \
	/__(  )__\


=head2 character_b

	 ______
	(_   _ \
	  ) (_) )
	  \   _/
	  /  _ \
	 _) (_) )
	(______/


=head2 character_c

	   ____
	  / ___)
	 / /
	( (
	( (
	 \ \___
	  \____)


=head2 character_d

	 ______
	(_  __ \
	  ) ) \ \
	 ( (   ) )
	  ) )  ) )
	 / /__/ /
	(______/


=head2 character_e

	  _____
	 / ___/
	( (__
	 ) __)
	( (
	 \ \___
	  \____\


=head2 character_f

	 _________
	(_   _____)
	  ) (___
	 (   ___)
	  ) (
	 (   )
	  \_/


=head2 character_g

	   _____
	  / ___ \
	 / /   \_)
	( (  ____
	( ( (__  )
	 \ \__/ /
	  \____/


=head2 character_h

	 __    __
	(  \  /  )
	 \ (__) /
	  ) __ (
	 ( (  ) )
	  ) )( (
	 /_/  \_\


=head2 character_i

	  _____
	 (_   _)
	   | |
	   | |
	   | |
	  _| |__
	 /_____(


=head2 character_j

	  ________
	 (___  ___)
	     ) )
	    ( (
	 __  ) )
	( (_/ /
	 \___/


=head2 character_k

	 __   ___
	() ) / __)
	( (_/ /
	()   (
	() /\ \
	( (  \ \
	()_)  \_\


=head2 character_l

	 _____
	(_   _)
	  | |
	  | |
	  | |   __
	__| |___) )
	\________/


=head2 character_m

	   __    __
	   \ \  / /
	   () \/ ()
	   / _  _ \
	  / / \/ \ \
	 /_/      \_\
	(/          \)


=head2 character_n

	    __      _
	   /  \    / )
	  / /\ \  / /
	  ) ) ) ) ) )
	 ( ( ( ( ( (
	 / /  \ \/ /
	(_/    \__/


=head2 character_o

	   ____
	  / __ \
	 / /  \ \
	( ()  () )
	( ()  () )
	 \ \__/ /
	  \____/


=head2 character_p

	 _____
	(  __ \
	 ) )_) )
	(   __/
	 ) )
	( (
	/__\


=head2 character_q

	   ____
	  / __ \
	 / /  \ \
	( (    ) )
	( (  /\) )
	 \ \_\ \/
	  \___\ \_
	       \__)

=head2 character_r

	 ______
	(   __ \
	 ) (__) )
	(    __/
	 ) \ \  _
	( ( \ \_))
	 )_) \__/


=head2 character_s

	   ____
	 / ____\
	( (___
	 \____ \
	      ) )
	  ___/ /
	 /____/


=head2 character_t

	 ________
	(___  ___)
	    ) )
	   ( (
	    ) )
	   ( (
	   /__\


=head2 character_u

	 __    __
	 ) )  ( (
	( (    ) )
	 ) )  ( (
	( (    ) )
	 ) \__/ (
	 \______/


=head2 character_v

	 __    __
	 ) )  ( (
	( (    ) )
	 \ \  / /
	  \ \/ /
	   \  /
	    \/


=head2 character_w

	 ___       ___
	(  (       )  )
	 \  \  _  /  /
	  \  \/ \/  /
	   )   _   (
	   \  ( )  /
	    \_/ \_/


=head2 character_x

	 __     __
	(_ \   / _)
	  \ \_/ /
	   \   /
	   / _ \
	 _/ / \ \_
	(__/   \__)


=head2 character_y

	__      __
	) \    / (
	 \ \  / /
	  \ \/ /
	   \  /
	    )(
	   /__\


=head2 character_z

	  _______
	 (____   )
	     /  /
	 ___/  /_
	/__   ___)
	  / /____
	 (_______)


=head2 character_0

	  ____
	 / __ \
	( (  ) )
	( (  ) )
	( (  ) )
	( (__) )
	 \____/


=head2 character_1

	   ____
	  /   /
	 / /) )
	/_/( (
	    ) )
	   ( (
	   /__\


=head2 character_2

	   ______
	  (____  \
	       ) /
	  __  / /
	 /  \/ / __
	( () \__/ /
	 \__\____(


=head2 character_3

	_____
	)__  \
	 __) /
	(__ (
	   \ \
	___/  )
	)____/


=head2 character_4

	  _   _
	 / / / \
	( (__) (___
	 \___   __(
	     ) (
	     ) (
	    /___\


=head2 character_5

	 ______
	|  ___(
	| |__
	|___ \
	    \ \
	_____) )
	)_____/


=head2 character_6

	   ______
	  / ____(
	 / /
	( (_____
	(   ___ \
	 \ (___) )
	  \_____/


=head2 character_7

	_________
	)____   /
	  ___) /
	 )___ (
	     ) )
	    ( (
	    /__\


=head2 character_8

	  _____
	 /  _  \
	(  (_)  )
	 \  _  /
	 / / \ \
	( (___) )
	 \_____/


=head2 character_9

	  _____
	 / __  \
	( (__)  \
	 \_____  )
	       ) )
	  ____/ /
	 (_____/

       
=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii-text at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut



