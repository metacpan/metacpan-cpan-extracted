package Ascii::Text::Font::Block;

use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable => 0,
	writable => 0,
	value => 11
);

function character_A => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';
	$character[2][9] = $character[2][10] = $character[7][4] = $character[7][5] = $character[7][6] = $character[7][7] = $character[6][4] = $character[6][15] = $character[7][12] = $character[7][13] = $character[7][14] = $character[7][15] = $character[5][8] = $character[5][9] = $character[5][10] = $character[5][11] = '_';
	$character[3][8] = $character[4][7] = $character[5][6] = $character[6][5] = $character[4][9] = $character[6][7] = '/';
	$character[3][11] = $character[4][12] = $character[5][13] = $character[6][14] = $character[6][12] = $character[4][10] = '\\';
	$character[7][3] = $character[7][8] = $character[7][11] = $character[7][16] = '|';
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(20);
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[5][13] = '.';
	$character[1][0] = $character[1][19] = $character[2][0] = $character[2][2] = $character[2][17] = $character[2][19] = $character[3][0] = $character[3][2] = $character[3][5] = $character[3][17] = $character[3][19] = $character[4][0] = $character[4][2] = $character[4][7] = $character[4][9] = $character[4][13] = $character[4][17] = $character[4][19] = $character[5][0] = $character[5][2] = $character[5][7] = $character[5][17] = $character[5][19] = $character[6][0] = $character[6][2] = $character[6][7] = $character[6][9] = $character[6][14] = $character[6][17] = $character[6][19] = $character[7][0] = $character[7][2] = $character[7][5] = $character[7][17] = $character[7][19] = $character[8][0] = $character[8][2] = $character[8][17] = $character[8][19] = $character[9][0] = $character[9][19] = '|';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = $character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][8] = $character[9][9] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = '-';
	$character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[3][6] = $character[3][10] = $character[4][10] = $character[5][10] = $character[5][11] = $character[6][6] = $character[6][10] = $character[6][11] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = '_';
	$character[7][13] = '/';
	$character[3][12] = '\\';
	$character[5][12] = $character[9][2] = $character[9][17] = $character[10][1] = $character[10][18] = '\'';
	$character[4][11] = $character[6][12] = ')';
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';

	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[10][1] = $character[10][18] = '.';
	$character[10][1] = $character[9][2] = $character[9][17] = $character[10][18] = '\'';

	$character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[2][13] = $character[3][9] = $character[3][10] = $character[3][11] = $character[4][13] = $character[6][9] = $character[6][10] = $character[6][11] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = $character[7][13] = '_';
	$character[3][14] = $character[4][14] = $character[5][5] = $character[5][7] = '|';
	$character[4][12] = $character[6][5] = $character[6][14] = '\\';
	$character[4][5] = '/';
	$character[3][6] = $character[4][7] = $character[6][8] = $character[6][12] = $character[7][7] = $character[7][13] = '.';
	$character[3][7] = $character[4][8] = $character[6][13] = $character[7][14] = '\'';
	$character[6][7] = $character[7][6] = '`';
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';

	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[10][1] = $character[10][18] = '.';
	$character[10][1] = $character[9][2] = $character[9][17] = $character[10][18] = '\'';

	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[3][5] = $character[3][9] = $character[3][10] = $character[3][11] = $character[7][5] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = $character[6][5] = $character[6][9] = $character[6][10] = $character[6][11] = '_';
	$character[3][4] = $character[4][6] = $character[4][8] = $character[5][6] = $character[5][8] = $character[5][13] = $character[5][15] = $character[6][6] = $character[6][8] = $character[7][4] = '|';
	$character[3][14] = $character[4][13] = $character[6][12] = $character[7][13] = '.';
	$character[4][15] = '\\';
	$character[6][15] = '/';
	$character[6][13] = $character[7][14] = '\'';
	$character[3][13] = $character[4][12] = '`';
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[2][13] = $character[7][5] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = $character[7][13] = $character[3][5] = $character[3][9] = $character[3][10] = $character[3][11] = $character[4][9] = $character[4][13] = $character[5][9] = $character[5][13] = $character[6][5] = $character[6][9] = $character[6][10] = $character[6][11] = '_';
	$character[3][4] = $character[3][14] = $character[4][6] = $character[4][8] = $character[4][14] = $character[5][6] = $character[5][10] = $character[6][6] = $character[6][8] = $character[6][14] = $character[7][4] = $character[7][14] = '|';
	$character[4][12] = '\\';
	$character[6][12] = '/';
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[2][13] = $character[7][5] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][9] = $character[3][5] = $character[3][9] = $character[3][10] = $character[3][11] = $character[4][9] = $character[4][13] = $character[5][9] = $character[6][5] = $character[6][9] = '_';
	$character[3][4] = $character[3][14] = $character[4][6] = $character[4][8] = $character[4][14] = $character[5][6] = $character[5][10] = $character[6][6] = $character[6][8] = $character[7][4] = $character[7][10] = '|';
	$character[4][12] = '\\';
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[5][11] = $character[5][12] = $character[5][13] = $character[5][14] = $character[6][14] = $character[6][8] = $character[6][9] = $character[6][10] = $character[4][12] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[3][8] = $character[3][9] = $character[3][10] = '_';
	$character[3][13] = $character[4][13] = $character[5][4] = $character[5][6] = $character[6][15] = '|';
	$character[3][6] = $character[4][7] = $character[7][13] = '\'';
	$character[4][4] = '/';
	$character[6][4] = $character[4][11] = '\\';
	$character[3][5] = $character[4][6] = $character[6][7] = $character[7][6] = $character[7][12] = '.';
	$character[7][5] = $character[6][6] = '`';
	$character[6][11] = ']';
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][8] = $character[2][11] = $character[2][12] = $character[2][13] = $character[2][14] = $character[3][5] = $character[3][14] = $character[4][9] = $character[4][10] = $character[7][5] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][11] = $character[7][12] = $character[7][13] = $character[7][14] = $character[6][5] = $character[6][14] = $character[5][9] = $character[5][10] = '_';
	$character[3][4] = $character[3][9] = $character[3][10] = $character[3][15] = $character[4][6] = $character[4][8] = $character[4][11] = $character[4][13] = $character[5][13] = $character[5][6] = $character[6][6] = $character[6][8] = $character[6][11] = $character[6][13] = $character[7][4] = $character[7][9] = $character[7][10] = $character[7][15] = '|';
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';

	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[10][1] = $character[10][18] = '.';
	$character[10][1] = $character[9][2] = $character[9][17] = $character[10][18] = '\'';

	$character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[3][8] = $character[3][12] = $character[6][8] = $character[6][12] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = '_';
	$character[3][7] = $character[3][13] = $character[4][9] = $character[4][11] = $character[5][9] = $character[5][11] = $character[6][9] = $character[6][11] = $character[7][7] = $character[7][13] = '|';
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[3][8] = $character[3][12] = $character[5][6] = $character[6][8] = $character[7][7] = $character[7][8] = $character[7][9] = '_';
	$character[3][7] = $character[3][13] = $character[4][9] = $character[4][11] = $character[5][9] = $character[5][11] = $character[6][5] = $character[6][7] = $character[6][11] = '|';
	$character[6][9] = $character[7][11] = '\'';
	$character[7][5] = '`';
	$character[7][6] = $character[7][10] = '.';
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][8] = $character[9][9] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = '-';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[5][12] = '.';
	$character[9][2] = $character[9][17] = $character[10][1] = $character[10][18] = $character[5][11] = '\'';
	$character[1][0] = $character[1][19] = $character[2][0] = $character[2][19] = $character[3][0] = $character[3][19] = $character[4][0] = $character[4][19] = $character[5][0] = $character[5][19] = $character[6][0] = $character[6][19] = $character[7][0] = $character[7][19] = $character[8][0] = $character[8][19] = $character[9][0] = $character[9][19] = $character[2][2] = $character[2][17] = $character[3][2] = $character[3][17] = $character[4][2] = $character[4][17] = $character[5][2] = $character[5][17] = $character[6][2] = $character[6][17] = $character[7][2] = $character[7][17] = $character[8][2] = $character[8][17] = '|';
	$character[3][4] = $character[3][8] = $character[3][9] = $character[3][14] = $character[4][6] = $character[4][8] = $character[5][6] = $character[6][6] = $character[6][8] = $character[7][4] = $character[7][9] = $character[7][10] = $character[7][15] = '|';
	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][10] = $character[2][11] = $character[2][12] = $character[2][13] = $character[3][5] = $character[3][10] = $character[3][13] = $character[4][9] = $character[5][9] = $character[5][10] = $character[6][5] = $character[6][14] = $character[7][5] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][11] = $character[7][12] = $character[7][13] = $character[7][14] = '_';
	$character[4][10] = $character[4][12] = '/';
	$character[6][11] = $character[6][13] = '\\';
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';
	$character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[3][6] = $character[3][10] = $character[6][6] = $character[6][10] = $character[6][11] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = $character[7][13] = $character[5][13] = '_';
	$character[3][5] = $character[3][11] = $character[4][7] = $character[5][7] = $character[6][7] = $character[4][9] = $character[5][9] = $character[6][9] = $character[7][5] = $character[7][14] = $character[6][14] = '|';
	$character[6][12] = '/';
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][4] = $character[2][5] = $character[2][6] = $character[2][7] = $character[2][12] = $character[2][13] = $character[2][14] = $character[2][15] = $character[7][4] = $character[7][5] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][11] = $character[7][12] = $character[7][13] = $character[7][14] = $character[7][15] = $character[6][4] = $character[6][8] = $character[6][11] = $character[6][15] = $character[3][4] = $character[3][15] = '_';
	$character[3][3] = $character[3][16] = $character[4][5] = $character[4][14] = $character[5][5] = $character[5][14] = $character[6][5] = $character[6][14] = $character[7][3] = $character[7][9] = $character[7][10] = $character[7][16] = $character[5][7] = $character[5][12] = $character[6][7] = $character[6][12] = '|';
	$character[3][8] = $character[4][9] = $character[5][8] = $character[6][9] = '\\';
	$character[3][11] = $character[4][10] = $character[5][11] = $character[6][10] = '/';
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';
	$character[2][4] = $character[2][5] = $character[2][6] = $character[2][7] = $character[2][10] = $character[2][11] = $character[2][12] = $character[2][13] = $character[2][14] = $character[3][4] = $character[3][10] = $character[3][14] = $character[6][4] = $character[6][8] = $character[6][14] = $character[7][4] = $character[7][5] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][11] = $character[7][12] = $character[7][13] = $character[7][14] = '_';
	$character[3][3] = $character[3][9] = $character[3][15] = $character[4][5] = $character[4][11] = $character[4][13] = $character[5][5] = $character[5][11] = $character[5][13] = $character[6][5] = $character[6][7] = $character[6][13] = $character[7][3] = $character[7][9] = $character[7][15] = '|';
	$character[3][8] = $character[4][9] = $character[5][8] = $character[5][10] = $character[6][9] = $character[7][10] = '\\';
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(20);

	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';

	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';

	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';


	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';
	
	$character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = "_";
	$character[3][7] = $character[6][11] = $character[7][13] = "'";
	$character[3][12] = $character[6][8] = $character[7][6] = "`";
	$character[3][6] = $character[3][13] = $character[4][8] = $character[4][11] = $character[7][7] = $character[7][12] = ".";
	$character[4][9] = $character[4][10] = $character[6][9] = $character[6][10] = "-";
	$character[4][5] = $character[6][14] = "/";
	$character[4][14] = $character[6][5] = "\\";
	$character[5][5] = $character[5][7] = $character[5][12] = $character[5][14] = "|";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[3][6] = $character[3][10] = $character[3][11] = $character[4][10] = $character[4][11] = $character[5][10] = $character[5][11] = $character[5][12] = $character[6][6] = $character[6][10] = '_';
	$character[3][5] = $character[4][7] = $character[4][9] = $character[4][14] = $character[5][7] = $character[6][7] = $character[6][9] = $character[7][5] = $character[7][11] = '|';
	$character[3][14] = '\\';
	$character[4][12] = ')';
	$character[5][13] = '/';	
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';

	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[10][1] = $character[10][18] = '.';
	$character[10][1] = $character[9][2] = $character[9][17] = $character[10][18] = '\'';

	$character[2][7] = $character[2][8] = $character[2][9] = $character[6][13] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][12] = $character[7][13] = '_';
	$character[5][4] = $character[5][6] = $character[5][10] = $character[5][12] = $character[7][14] = '|';
	$character[3][5] = $character[3][11] = $character[4][7] = $character[4][9] = $character[7][6] = $character[7][10] = '.';
	$character[4][12] = $character[6][4] = $character[6][12] = $character[7][11] = '\\';
	$character[4][4] = '/';
	$character[6][7] = $character[7][5] = '`';
	$character[4][8] = $character[6][8] = '-';
	$character[3][6] = $character[3][10] = $character[6][9] = '\'';

	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';
	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[3][5] = $character[3][9] = $character[3][10] = $character[4][10] = $character[4][9] = $character[5][9] = $character[5][10] = $character[6][5] = $character[7][5] = $character[7][6] = $character[7][7] = $character[6][14] = $character[7][12] = $character[7][13] = $character[7][14] = '_';
	$character[3][4] = $character[4][6] = $character[4][8] = $character[4][13] = $character[5][6] = $character[6][6] = $character[6][8] = $character[7][4] = $character[7][9] = $character[7][11] = $character[7][15] = '|';
	$character[3][12] = $character[6][11] = $character[6][13] = '\\';
	$character[5][12] = '/';
	$character[4][11] = ')';
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[2][13] = '_';
	$character[3][9] = $character[3][10] = $character[3][11] = '_';
	$character[4][9] = $character[4][10] = $character[4][13] = '_';
	$character[5][8] = $character[5][9] = $character[5][10] = '_';
	$character[6][8] = $character[6][9] = $character[6][10] = $character[6][11] = '_';
	$character[7][6] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = '_';
	$character[4][5] = $character[6][5] = $character[7][5] = $character[3][14] = $character[4][14] = $character[6][14] = '|';
	$character[5][12] = '-';
	$character[5][7] = $character[5][12] = $character[7][13] = '.';
	$character[5][6] = $character[7][14] = '\'';
	$character[5][11] = $character[6][6] = '`';
	$character[3][6] = '/';
	$character[4][12] = $character[6][7] = '\\';
	$character[4][8] = '(';
	$character[6][12] = ')';
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[6][7] = $character[6][11] = $character[3][7] = $character[3][11] = $character[4][5] = $character[4][13] = $character[2][5] = $character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[2][13] = '_';
	$character[3][4] = $character[3][14] = $character[4][4] = $character[4][14] = $character[4][8] = $character[4][10] = $character[5][8] = $character[5][10] = $character[6][8] = $character[6][10] = $character[7][6] = $character[7][12] = '|';
	$character[4][6] = '/';
	$character[4][12] = '\\';
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';

	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';

	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';


	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';
	
	$character[2][4] = $character[2][5] = $character[2][6] = $character[2][7] = $character[2][8] = $character[2][11] = $character[2][12] = $character[2][13] = $character[2][14] = $character[2][15] = $character[3][4] = $character[3][8] = $character[3][11] = $character[3][15] = $character[7][9] = $character[7][10] = "_";
	$character[3][3] = $character[3][9] = $character[3][10] = $character[3][16] = $character[4][5] = $character[4][7] = $character[4][12] = $character[4][14] = $character[5][5] = $character[5][14] = "|";
	$character[5][7] = $character[5][12] = $character[7][12] = "'";
	$character[6][6] = "\\";
	$character[6][8] = $character[7][7] = "`";
	$character[6][9] = $character[6][10] = "-";
	$character[6][11] = "'";
	$character[6][13] = "/";
	$character[7][8] = $character[7][11] = ".";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(20);
	
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[9][2] = $character[9][17] = '.';
	$character[10][1] = $character[10][18] = '\'';

	$character[2][4] = $character[2][5] = $character[2][6] = $character[2][7] = $character[7][9] = $character[2][11] = $character[2][12] = $character[2][13] = $character[2][14] = $character[3][4] = $character[3][7] = $character[3][11] = $character[3][14] = '_';
	$character[3][3] = $character[3][8] = $character[3][10] = $character[3][15] = '|';
	$character[6][9] = '\'';
	$character[4][5] = $character[4][7] = $character[5][6] = $character[5][8] = $character[6][7] = $character[7][8] = '\\';
	$character[4][11] = $character[4][13] = $character[5][10] = $character[5][12] = $character[6][11] = $character[7][10] = '/';

	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][4] = $character[2][5] = $character[2][6] = $character[2][7] = $character[2][12] = $character[2][13] = $character[2][14] = $character[2][15] = $character[7][6] = $character[7][7] = $character[7][12] = $character[7][13] = $character[3][4] = $character[3][15] = $character[3][11] = $character[3][8] = $character[2][11] = $character[2][8] = '_';
	$character[3][3] = $character[3][16] = $character[4][5] = $character[4][14] = $character[5][5] = $character[5][14] = $character[6][5] = $character[6][14] = $character[7][5] = $character[3][9] = $character[3][10] = $character[7][14] = $character[5][7] = $character[5][12] = $character[4][7] = $character[4][12] = '|';
	$character[5][8] = $character[4][9] = $character[7][8] = $character[6][9] = '/';
	$character[5][11] = $character[4][10] = $character[7][11] = $character[6][10] = '\\';
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(20);

	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][12] = $character[2][13] = $character[2][14] = $character[7][4] = $character[7][5] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][11] = $character[7][12] = $character[7][13] = $character[7][14] = $character[7][15] = $character[3][5] = $character[3][14] = $character[3][11] = $character[3][8] = $character[6][5] = $character[6][8] = $character[6][11] = $character[6][14] = $character[2][11] = $character[2][8] = '_';
	$character[3][4] = $character[3][15] = $character[7][4] = $character[7][9] = $character[7][10] = $character[3][9] = $character[3][10] = $character[7][15] = '|';
	$character[4][6] = $character[4][8] = $character[6][11] = $character[6][13] = '\\';
	$character[4][11] = $character[4][13] = $character[6][6] = $character[6][8] = '/';
	$character[5][7] = '>';
	$character[5][12] = '<';
	$character[5][9] = $character[6][10] = '`';
	$character[5][10] = $character[6][9] = '\'';

	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] ='.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] =  '\'';
	$character[2][5]= $character[2][6]= $character[2][7]= $character[2][8]= $character[2][11]= $character[2][12]= $character[2][13]= $character[2][14]= $character[6][7]= $character[6][12]= $character[3][5]= $character[3][8]=$character[3][11]=$character[3][14]='_';
	for(my  $i=7;$i<13;$i++){
		$character[7][$i]='_';
	}
	$character[3][4]=$character[3][9]=$character[3][10]=$character[3][15]=$character[6][8]=$character[6][11]=$character[7][6]=$character[7][13]='|';
$character[4][6]=$character[4][8]=$character[5][7]=$character[5][9]='\\';
$character[4][11]=$character[4][13]=$character[5][10]=$character[5][12]='/';
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[9][2] = $character[9][17] = '.';
	$character[10][1] = $character[10][18] = '\'';

	$character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[2][13] = $character[4][6] = $character[3][8] = $character[3][9] = $character[3][13] = $character[6][6] = $character[6][10] = $character[6][11] = $character[5][13] = '_';
	$character[6][14] = $character[7][5] = $character[3][5] = $character[4][5] = $character[3][14] = $character[7][14] = '|';
	$character[4][7] = $character[4][10] = $character[4][12] = $character[5][8] = $character[6][7] = $character[6][9] = $character[6][12] = '/';
	$character[5][9] = $character[5][11] = '\'';
	$character[5][8] = $character[5][10] = '.';
	$character[7][6] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = $character[7][13] = '_';

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
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = '_';
	$character[4][5] = $character[4][14] = $character[5][5] = $character[5][7] = $character[5][12] = $character[5][14] = $character[6][5] = $character[6][14] = '|';
	$character[4][9] = $character[4][10] = $character[6][9] = $character[6][10] = '-';
	$character[3][6] = $character[3][13] = $character[4][8] = $character[4][11] = $character[7][7] = $character[7][12] = '.';
	$character[3][7] = $character[3][12] = $character[6][11] = $character[7][6] = $character[7][13] = '\'';
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[9][2] = $character[9][17] = '.';
	$character[10][1] = $character[10][18] = '\'';
	$character[2][8] = $character[2][9] = $character[6][7] = $character[6][11] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = '_';
	$character[3][10] = $character[4][8] = $character[4][10] = $character[5][8] = $character[5][10] = $character[6][8] = $character[6][10] = $character[7][6] = $character[7][12] = '|';
	$character[3][7] = '/';
	$character[4][7] = '`';
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(20);

	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';

	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';

	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';


	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';
	
	$character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[3][8] = $character[3][9] = $character[3][10] = $character[4][6] = $character[4][8] = $character[4][9] = $character[4][10] = $character[5][8] = $character[5][9] = $character[5][10] = $character[5][11] = $character[6][8] = $character[6][9] = $character[6][10] = $character[6][11] = $character[7][6] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = '_';
	$character[3][6] = $character[4][7] = $character[6][5] = $character[6][7] = '/';
	$character[3][12] = '`';
	$character[3][13] = $character[5][6] = $character[5][12] = '.';
	$character[4][5] = $character[4][13] = $character[7][5] = $character[7][13] = '|';
	$character[4][11] = ')';
	$character[5][7] = $character[5][13] = '\'';

	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(20);

	$character[0][1] = '.';
	$character[0][2] = '-';
	$character[0][3] = '-';
	$character[0][4] = '-';
	$character[0][5] = '-';
	$character[0][6] = '-';
	$character[0][7] = '-';
	$character[0][8] = '-';
	$character[0][9] = '-';
	$character[0][10] = '-';
	$character[0][11] = '-';
	$character[0][12] = '-';
	$character[0][13] = '-';
	$character[0][14] = '-';
	$character[0][15] = '-';
	$character[0][16] = '-';
	$character[0][17] = '-';
	$character[0][18] = '.';

	$character[1][0] = '|';
	$character[1][2] = '.';
	$character[1][3] = '-';
	$character[1][4] = '-';
	$character[1][5] = '-';
	$character[1][6] = '-';
	$character[1][7] = '-';
	$character[1][8] = '-';
	$character[1][9] = '-';
	$character[1][10] = '-';
	$character[1][11] = '-';
	$character[1][12] = '-';
	$character[1][13] = '-';
	$character[1][14] = '-';
	$character[1][15] = '-';
	$character[1][16] = '-';
	$character[1][17] = '.';
	$character[1][19] = '|';

	$character[2][0] = '|';
	$character[2][2] = '|';
	$character[2][7] = '_';
	$character[2][8] = '_';
	$character[2][9] = '_';
	$character[2][10] = '_';
	$character[2][11] = '_';
	$character[2][12] = '_';
	$character[2][17] = '|';
	$character[2][19] = '|';

	$character[3][0] = '|';
	$character[3][2] = '|';
	$character[3][6] = '/';
	$character[3][8] = '_';
	$character[3][9] = '_';
	$character[3][10] = '_';
	$character[3][11] = '_';
	$character[3][13] = '\'';
	$character[3][14] = '.';
	$character[3][17] = '|';
	$character[3][19] = '|';

	$character[4][0] = '|';
	$character[4][2] = '|';
	$character[4][6] = '\'';
	$character[4][7] = '\'';
	$character[4][10] = '_';
	$character[4][11] = '_';
	$character[4][12] = ')';
	$character[4][14] = '|';
	$character[4][17] = '|';
	$character[4][19] = '|';

	$character[5][0] = '|';
	$character[5][2] = '|';
	$character[5][6] = '_';
	$character[5][9] = '|';
	$character[5][10] = '_';
	$character[5][11] = '_';
	$character[5][13] = '\'';
	$character[5][14] = '.';
	$character[5][17] = '|';
	$character[5][19] = '|';

	$character[6][0] = '|';
	$character[6][2] = '|';
	$character[6][5] = '|';
	$character[6][7] = '\\';
	$character[6][8] = '_';
	$character[6][9] = '_';
	$character[6][10] = '_';
	$character[6][11] = '_';
	$character[6][12] = ')';
	$character[6][14] = '|';
	$character[6][17] = '|';
	$character[6][19] = '|';

	$character[7][0] = '|';
	$character[7][2] = '|';
	$character[7][6] = '\\';
	$character[7][7] = '_';
	$character[7][8] = '_';
	$character[7][9] = '_';
	$character[7][10] = '_';
	$character[7][11] = '_';
	$character[7][12] = '_';
	$character[7][13] = '.';
	$character[7][14] = '\'';
	$character[7][17] = '|';
	$character[7][19] = '|';

	$character[8][0] = '|';
	$character[8][2] = '|';
	$character[8][17] = '|';
	$character[8][19] = '|';

	$character[9][0] = '|';
	$character[9][2] = '|';
	$character[9][3] = '-';
	$character[9][4] = '-';
	$character[9][5] = '-';
	$character[9][6] = '-';
	$character[9][7] = '-';
	$character[9][8] = '-';
	$character[9][9] = '-';
	$character[9][10] = '-';
	$character[9][11] = '-';
	$character[9][12] = '-';
	$character[9][13] = '-';
	$character[9][14] = '-';
	$character[9][15] = '-';
	$character[9][16] = '-';
	$character[9][17] = '\'';
	$character[9][19] = '|';

	$character[10][1] = '\'';
	$character[10][2] = '-';
	$character[10][3] = '-';
	$character[10][4] = '-';
	$character[10][5] = '-';
	$character[10][6] = '-';
	$character[10][7] = '-';
	$character[10][8] = '-';
	$character[10][9] = '-';
	$character[10][10] = '-';
	$character[10][11] = '-';
	$character[10][12] = '-';
	$character[10][13] = '-';
	$character[10][14] = '-';
	$character[10][15] = '-';
	$character[10][16] = '-';
	$character[10][17] = '-';
	$character[10][18] = '\'';

	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(20);

	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][6] = $character[2][11] = $character[4][8] = $character[4][9] = $character[4][13] = $character[5][6] = $character[5][7] = $character[5][8] = $character[5][9] = $character[5][13] = $character[6][9] = $character[6][13] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = $character[7][13] = '_';
	$character[3][5] = $character[3][7] = $character[3][10] = $character[3][12] = $character[4][5] = $character[4][7] = $character[4][10] = $character[4][12] = $character[5][5] = $character[5][14] = $character[6][10] = $character[6][12] = $character[7][8] = $character[7][14] = '|';


	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(20);
	
	$character[0][1] = '.';
	$character[0][2] = '-';
	$character[0][3] = '-';
	$character[0][4] = '-';
	$character[0][5] = '-';
	$character[0][6] = '-';
	$character[0][7] = '-';
	$character[0][8] = '-';
	$character[0][9] = '-';
	$character[0][10] = '-';
	$character[0][11] = '-';
	$character[0][12] = '-';
	$character[0][13] = '-';
	$character[0][14] = '-';
	$character[0][15] = '-';
	$character[0][16] = '-';
	$character[0][17] = '-';
	$character[0][18] = '.';
	$character[1][0] = '|';
	$character[1][2] = '.';
	$character[1][3] = '-';
	$character[1][4] = '-';
	$character[1][5] = '-';
	$character[1][6] = '-';
	$character[1][7] = '-';
	$character[1][8] = '-';
	$character[1][9] = '-';
	$character[1][10] = '-';
	$character[1][11] = '-';
	$character[1][12] = '-';
	$character[1][13] = '-';
	$character[1][14] = '-';
	$character[1][15] = '-';
	$character[1][16] = '-';
	$character[1][17] = '.';
	$character[1][19] = '|';
	$character[2][0] = '|';
	$character[2][2] = '|';
	$character[2][6] = '_';
	$character[2][7] = '_';
	$character[2][8] = '_';
	$character[2][9] = '_';
	$character[2][10] = '_';
	$character[2][11] = '_';
	$character[2][12] = '_';
	$character[2][17] = '|';
	$character[2][19] = '|';
	$character[3][0] = '|';
	$character[3][2] = '|';
	$character[3][5] = '|';
	$character[3][8] = '_';
	$character[3][9] = '_';
	$character[3][10] = '_';
	$character[3][11] = '_';
	$character[3][12] = '_';
	$character[3][13] = '|';
	$character[3][17] = '|';
	$character[3][19] = '|';
	$character[4][0] = '|';
	$character[4][2] = '|';
	$character[4][5] = '|';
	$character[4][7] = '|';
	$character[4][8] = '_';
	$character[4][9] = '_';
	$character[4][10] = '_';
	$character[4][11] = '_';
	$character[4][17] = '|';
	$character[4][19] = '|';
	$character[5][0] = '|';
	$character[5][2] = '|';
	$character[5][5] = '\'';
	$character[5][6] = '_';
	$character[5][7] = '.';
	$character[5][8] = '_';
	$character[5][9] = '_';
	$character[5][10] = '_';
	$character[5][11] = '_';
	$character[5][12] = '\'';
	$character[5][13] = '\'';
	$character[5][14] = '.';
	$character[5][17] = '|';
	$character[5][19] = '|';
	$character[6][0] = '|';
	$character[6][2] = '|';
	$character[6][5] = '|';
	$character[6][7] = '\\';
	$character[6][8] = '_';
	$character[6][9] = '_';
	$character[6][10] = '_';
	$character[6][11] = '_';
	$character[6][12] = ')';
	$character[6][14] = '|';
	$character[6][17] = '|';
	$character[6][19] = '|';
	$character[7][0] = '|';
	$character[7][2] = '|';
	$character[7][6] = '\\';
	$character[7][7] = '_';
	$character[7][8] = '_';
	$character[7][9] = '_';
	$character[7][10] = '_';
	$character[7][11] = '_';
	$character[7][12] = '_';
	$character[7][13] = '.';
	$character[7][14] = '\'';
	$character[7][17] = '|';
	$character[7][19] = '|';
	$character[8][0] = '|';
	$character[8][2] = '|';
	$character[8][17] = '|';
	$character[8][19] = '|';
	$character[9][0] = '|';
	$character[9][2] = '\'';
	$character[9][3] = '-';
	$character[9][4] = '-';
	$character[9][5] = '-';
	$character[9][6] = '-';
	$character[9][7] = '-';
	$character[9][8] = '-';
	$character[9][9] = '-';
	$character[9][10] = '-';
	$character[9][11] = '-';
	$character[9][12] = '-';
	$character[9][13] = '-';
	$character[9][14] = '-';
	$character[9][15] = '-';
	$character[9][16] = '-';
	$character[9][17] = '\'';
	$character[9][19] = '|';
	$character[10][1] = '\'';
	$character[10][2] = '-';
	$character[10][3] = '-';
	$character[10][4] = '-';
	$character[10][5] = '-';
	$character[10][6] = '-';
	$character[10][7] = '-';
	$character[10][8] = '-';
	$character[10][9] = '-';
	$character[10][10] = '-';
	$character[10][11] = '-';
	$character[10][12] = '-';
	$character[10][13] = '-';
	$character[10][14] = '-';
	$character[10][15] = '-';
	$character[10][16] = '-';
	$character[10][17] = '-';
	$character[10][18] = '\'';

	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';
	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = '.';
	$character[10][1] = $character[10][18] = $character[9][2] = $character[9][17] = '\'';

	$character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[3][8] = $character[3][9] = $character[3][10] = $character[3][11] = $character[4][8] = $character[4][9] = $character[4][10] = $character[4][11] = $character[4][13] = $character[5][8] = $character[5][9] = $character[5][10] = $character[5][11] = $character[6][8] = $character[6][9] = $character[6][10] = $character[6][11] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = '_';
	$character[3][6] = $character[5][7] = $character[5][13] = $character[7][5] = $character[7][14] = '\'';
	$character[4][7] = $character[4][5] = $character[5][5] = $character[6][5] = $character[4][14] = $character[6][14] = '|';
	$character[3][13] = $character[4][12] = '\\';
	$character[6][7] = '(';
	$character[6][12] = ')';
	$character[3][5] = $character[7][6] = $character[5][14] = $character[7][13] = '.';
	$character[5][12] = '`';
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[8][17] = '|';

	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[10][1] = $character[10][18] = '.';
	$character[10][1] = $character[9][2] = $character[9][17] = $character[10][18] = '\'';
	$character[3][5] = $character[3][13] = $character[4][5] = '|';
	$character[2][6] = $character[2][7] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[2][12] = $character[4][6] = $character[3][8] = $character[3][9] = $character[3][10] = $character[7][8] = '_';
	$character[4][7] = $character[4][10] = $character[5][9] = $character[6][8] = $character[7][7] = $character[7][9] = $character[6][10] = $character[5][11] = $character[4][12] = '/';
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(20);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[0][7] = $character[0][8] = $character[0][9] = $character[0][10] = $character[0][11] = $character[0][12] = $character[0][13] = $character[0][14] = $character[0][15] = $character[0][16] = $character[0][17] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[1][7] = $character[1][8] = $character[1][9] = $character[1][10] = $character[1][11] = $character[1][12] = $character[1][13] = $character[1][14] = $character[1][15] = $character[1][16] = '-';
	$character[9][3] = $character[9][4] = $character[9][5] = $character[9][6] = $character[9][7] = $character[9][10] = $character[9][11] = $character[9][12] = $character[9][13] = $character[9][14] = $character[9][15] = $character[9][16] = $character[10][2] = $character[10][3] = $character[10][4] = $character[10][5] = $character[10][6] = $character[10][7] = $character[10][8] = $character[10][9] = $character[10][10] = $character[10][11] = $character[10][12] = $character[10][13] = $character[10][14] = $character[10][15] = $character[10][16] = $character[10][17] = $character[9][8] = $character[9][9] = '-';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = $character[7][0] = $character[8][0] = $character[9][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][2] = $character[6][2] = $character[7][2] = $character[6][5] = $character[4][6] = $character[4][13] = $character[8][2] = '|';
	$character[1][19] = $character[2][19] = $character[3][19] = $character[4][19] = $character[5][19] = $character[6][19] = $character[7][19] = $character[8][19] = $character[9][19] = $character[2][17] = $character[3][17] = $character[4][17] = $character[5][17] = $character[6][17] = $character[7][17] = $character[6][14] = $character[8][17] = '|';

	$character[0][1] = $character[0][18] = $character[1][2] = $character[1][17] = $character[3][6] = $character[3][13] = $character[10][1] = $character[7][6] = $character[7][13] = $character[5][13] = $character[5][6] = $character[10][18] = '.';
	$character[5][7] = $character[7][5] = '`';
	$character[4][9] = $character[4][10] = $character[3][9] = $character[3][10] = $character[2][8] = $character[2][9] = $character[2][10] = $character[2][11] = $character[5][8] = $character[5][9] = $character[5][10] = $character[5][11] = $character[6][8] = $character[6][9] = $character[6][10] = $character[6][11] = $character[7][7] = $character[7][8] = $character[7][9] = $character[7][10] = $character[7][11] = $character[7][12] = '_';
	$character[4][8] = $character[6][7] = '(';
	$character[4][11] = $character[6][12] = ')';
	$character[7][14] = $character[5][12] = $character[3][7] = $character[3][12] = $character[10][1] = $character[9][2] = $character[9][17] = $character[10][18] = '\'';

	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(20);
	$character[0][1] = '.';
	$character[0][2] = '-';
	$character[0][3] = '-';
	$character[0][4] = '-';
	$character[0][5] = '-';
	$character[0][6] = '-';
	$character[0][7] = '-';
	$character[0][8] = '-';
	$character[0][9] = '-';
	$character[0][10] = '-';
	$character[0][11] = '-';
	$character[0][12] = '-';
	$character[0][13] = '-';
	$character[0][14] = '-';
	$character[0][15] = '-';
	$character[0][16] = '-';
	$character[0][17] = '-';
	$character[0][18] = '.';
	$character[1][0] = '|';
	$character[1][2] = '.';
	$character[1][3] = '-';
	$character[1][4] = '-';
	$character[1][5] = '-';
	$character[1][6] = '-';
	$character[1][7] = '-';
	$character[1][8] = '-';
	$character[1][9] = '-';
	$character[1][10] = '-';
	$character[1][11] = '-';
	$character[1][12] = '-';
	$character[1][13] = '-';
	$character[1][14] = '-';
	$character[1][15] = '-';
	$character[1][16] = '-';
	$character[1][17] = '.';
	$character[1][19] = '|';
	$character[2][0] = '|';
	$character[2][2] = '|';
	$character[2][7] = '_';
	$character[2][8] = '_';
	$character[2][9] = '_';
	$character[2][10] = '_';
	$character[2][11] = '_';
	$character[2][12] = '_';
	$character[2][17] = '|';
	$character[2][19] = '|';
	$character[3][0] = '|';
	$character[3][2] = '|';
	$character[3][5] = '.';
	$character[3][6] = '\'';
	$character[3][8] = '_';
	$character[3][9] = '_';
	$character[3][10] = '_';
	$character[3][11] = '_';
	$character[3][13] = '\'';
	$character[3][14] = '.';
	$character[3][17] = '|';
	$character[3][19] = '|';
	$character[4][0] = '|';
	$character[4][2] = '|';
	$character[4][5] = '|';
	$character[4][7] = '(';
	$character[4][8] = '_';
	$character[4][9] = '_';
	$character[4][10] = '_';
	$character[4][11] = '_';
	$character[4][12] = ')';
	$character[4][14] = '|';
	$character[4][17] = '|';
	$character[4][19] = '|';
	$character[5][0] = '|';
	$character[5][2] = '|';
	$character[5][5] = '\'';
	$character[5][6] = '_';
	$character[5][7] = '.';
	$character[5][8] = '_';
	$character[5][9] = '_';
	$character[5][10] = '_';
	$character[5][11] = '_';
	$character[5][12] = '.';
	$character[5][14] = '|';
	$character[5][17] = '|';
	$character[5][19] = '|';
	$character[6][0] = '|';
	$character[6][2] = '|';
	$character[6][5] = '|';
	$character[6][7] = '\\';
	$character[6][8] = '_';
	$character[6][9] = '_';
	$character[6][10] = '_';
	$character[6][11] = '_';
	$character[6][12] = '|';
	$character[6][14] = '|';
	$character[6][17] = '|';
	$character[6][19] = '|';
	$character[7][0] = '|';
	$character[7][2] = '|';
	$character[7][6] = '\\';
	$character[7][7] = '_';
	$character[7][8] = '_';
	$character[7][9] = '_';
	$character[7][10] = '_';
	$character[7][11] = '_';
	$character[7][12] = '_';
	$character[7][13] = ',';
	$character[7][14] = '\'';
	$character[7][17] = '|';
	$character[7][19] = '|';
	$character[8][0] = '|';
	$character[8][2] = '|';
	$character[8][17] = '|';
	$character[8][19] = '|';
	$character[9][0] = '|';
	$character[9][2] = '\'';
	$character[9][3] = '-';
	$character[9][4] = '-';
	$character[9][5] = '-';
	$character[9][6] = '-';
	$character[9][7] = '-';
	$character[9][8] = '-';
	$character[9][9] = '-';
	$character[9][10] = '-';
	$character[9][11] = '-';
	$character[9][12] = '-';
	$character[9][13] = '-';
	$character[9][14] = '-';
	$character[9][15] = '-';
	$character[9][16] = '-';
	$character[9][17] = '\'';
	$character[9][19] = '|';
	$character[10][1] = '\'';
	$character[10][2] = '-';
	$character[10][3] = '-';
	$character[10][4] = '-';
	$character[10][5] = '-';
	$character[10][6] = '-';
	$character[10][7] = '-';
	$character[10][8] = '-';
	$character[10][9] = '-';
	$character[10][10] = '-';
	$character[10][11] = '-';
	$character[10][12] = '-';
	$character[10][13] = '-';
	$character[10][14] = '-';
	$character[10][15] = '-';
	$character[10][16] = '-';
	$character[10][17] = '-';
	$character[10][18] = '\'';
	return \@character;
};

function space => sub {
	my @character = $_[0]->default_character(20);
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Block - Block font

=head1 VERSION

Version 0.19

=cut

=head1 SYNOPSIS

	use Ascii::Text::Font::Block;

	my $font = Ascii::Text::Font::Block->new();

	$font->character_A;

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Ascii::Text::Font::Boomer object.

	my $font = Ascii::Text::Font::Block->new();


=head2 character_A

	 .----------------.
	| .--------------. |
	| |      __      | |
	| |     /  \     | |
	| |    / /\ \    | |
	| |   / ____ \   | |
	| | _/ /    \ \_ | |
	| ||____|  |____|| |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_B

	 .----------------.
	| .--------------. |
	| |   ______     | |
	| |  |_   _ \    | |
	| |    | |_) |   | |
	| |    |  __'.   | |
	| |   _| |__) |  | |
	| |  |_______/   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_C

	 .----------------.
	| .--------------. |
	| |     ______   | |
	| |   .' ___  |  | |
	| |  / .'   \_|  | |
	| |  | |         | |
	| |  \ `.___.'\  | |
	| |   `. ____.'  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_D

	 .----------------.
	| .--------------. |
	| |  ________    | |
	| | |_   ___ `.  | |
	| |   | |   `. \ | |
	| |   | |    | | | |
	| |  _| |___.' / | |
	| | |________.'  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_E

	 .----------------.
	| .--------------. |
	| |  _________   | |
	| | |_   ___  |  | |
	| |   | |_  \_|  | |
	| |   |  _|  _   | |
	| |  _| |___/ |  | |
	| | |_________|  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_F

	 .----------------.
	| .--------------. |
	| |  _________   | |
	| | |_   ___  |  | |
	| |   | |_  \_|  | |
	| |   |  _|      | |
	| |  _| |_       | |
	| | |_____|      | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_G

	 .----------------.
	| .--------------. |
	| |    ______    | |
	| |  .' ___  |   | |
	| | / .'   \_|   | |
	| | | |    ____  | |
	| | \ `.___]  _| | |
	| |  `._____.'   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_H

	 .----------------.
	| .--------------. |
	| |  ____  ____  | |
	| | |_   ||   _| | |
	| |   | |__| |   | |
	| |   |  __  |   | |
	| |  _| |  | |_  | |
	| | |____||____| | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_I

	 .----------------.
	| .--------------. |
	| |     _____    | |
	| |    |_   _|   | |
	| |      | |     | |
	| |      | |     | |
	| |     _| |_    | |
	| |    |_____|   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_J

	 .----------------.
	| .--------------. |
	| |     _____    | |
	| |    |_   _|   | |
	| |      | |     | |
	| |   _  | |     | |
	| |  | |_' |     | |
	| |  `.___.'     | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_K

	 .----------------.
	| .--------------. |
	| |  ___  ____   | |
	| | |_  ||_  _|  | |
	| |   | |_/ /    | |
	| |   |  __'.    | |
	| |  _| |  \ \_  | |
	| | |____||____| | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_L

	 .----------------.
	| .--------------. |
	| |   _____      | |
	| |  |_   _|     | |
	| |    | |       | |
	| |    | |   _   | |
	| |   _| |__/ |  | |
	| |  |________|  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_M

	 .----------------.
	| .--------------. |
	| | ____    ____ | |
	| ||_   \  /   _|| |
	| |  |   \/   |  | |
	| |  | |\  /| |  | |
	| | _| |_\/_| |_ | |
	| ||_____||_____|| |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_N

	 .----------------.
	| .--------------. |
	| | ____  _____  | |
	| ||_   \|_   _| | |
	| |  |   \ | |   | |
	| |  |  \ \| |   | |
	| | _| |_\   |_  | |
	| ||_____|\____| | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_O

	 .----------------.
	| .--------------. |
	| |     ____     | |
	| |   .'    `.   | |
	| |  /  .--.  \  | |
	| |  | |    | |  | |
	| |  \  `--'  /  | |
	| |   `.____.'   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_P

	 .----------------.
	| .--------------. |
	| |   ______     | |
	| |  |_   __  \  | |
	| |    | |__) |  | |
	| |    |  ___/   | |
	| |   _| |_      | |
	| |  |_____|     | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_Q

	 .----------------.
	| .--------------. |
	| |    ___       | |
	| |  .'   '.     | |
	| | /  .-.  \    | |
	| | | |   | |    | |
	| | \  `-'  \_   | |
	| |  `.___.\__|  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_R

	 .----------------.
	| .--------------. |
	| |  _______     | |
	| | |_   __ \    | |
	| |   | |__) |   | |
	| |   |  __ /    | |
	| |  _| |  \ \_  | |
	| | |___ | |___| | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_S

	 .----------------.
	| .--------------. |
	| |    _______   | |
	| |   /  ___  |  | |
	| |  |  (__ \_|  | |
	| |   '.___`.    | |
	| |  |`\____) |  | |
	| |  |_______.'  | |
	| |              | |
	|  --------------  |
	  ----------------

=head2 character_T

	 .----------------.
	| .--------------. |
	| |  _________   | |
	| | |  _   _  |  | |
	| | |_/ | | \_|  | |
	| |     | |      | |
	| |    _| |_     | |
	| |   |_____|    | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_U

	 .----------------.
	| .--------------. |
	| | _____  _____ | |
	| ||_   _||_   _|| |
	| |  | |    | |  | |
	| |  | '    ' |  | |
	| |   \ `--' /   | |
	| |    `.__.'    | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_V

	 .----------------.
	| .--------------. |
	| | ____   ____  | |
	| ||_  _| |_  _| | |
	| |  \ \   / /   | |
	| |   \ \ / /    | |
	| |    \ ' /     | |
	| |     \_/      | |
	| |              | |
	| .--------------. |
	 '----------------'

=head2 character_W

	 .----------------.
	| .--------------. |
	| | _____  _____ | |
	| ||_   _||_   _|| |
	| |  | | /\ | |  | |
	| |  | |/  \| |  | |
	| |  |   /\   |  | |
	| |  |__/  \__|  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_X

	 .----------------.
	| .--------------. |
	| |  ____  ____  | |
	| | |_  _||_  _| | |
	| |   \ \  / /   | |
	| |    > `' <    | |
	| |  _/ /'`\ \_  | |
	| | |____||____| | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_Y

	 .----------------.
	| .--------------. |
	| |  ____  ____  | |
	| | |_  _||_  _| | |
	| |   \ \  / /   | |
	| |    \ \/ /    | |
	| |    _|  |_    | |
	| |   |______|   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_Z

	 .----------------.
	| .--------------. |
	| |   ________   | |
	| |  |  __   _|  | |
	| |  |_/  / /    | |
	| |     .'.' _   | |
	| |   _/ /__/ |  | |
	| |  |________|  | |
	| |              | |
	| .--------------. |
	 '----------------'

=head2 character_a

	 .----------------.
	| .--------------. |
	| |      __      | |
	| |     /  \     | |
	| |    / /\ \    | |
	| |   / ____ \   | |
	| | _/ /    \ \_ | |
	| ||____|  |____|| |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_b

	 .----------------.
	| .--------------. |
	| |   ______     | |
	| |  |_   _ \    | |
	| |    | |_) |   | |
	| |    |  __'.   | |
	| |   _| |__) |  | |
	| |  |_______/   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_c

	 .----------------.
	| .--------------. |
	| |     ______   | |
	| |   .' ___  |  | |
	| |  / .'   \_|  | |
	| |  | |         | |
	| |  \ `.___.'\  | |
	| |   `. ____.'  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_d

	 .----------------.
	| .--------------. |
	| |  ________    | |
	| | |_   ___ `.  | |
	| |   | |   `. \ | |
	| |   | |    | | | |
	| |  _| |___.' / | |
	| | |________.'  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_e

	 .----------------.
	| .--------------. |
	| |  _________   | |
	| | |_   ___  |  | |
	| |   | |_  \_|  | |
	| |   |  _|  _   | |
	| |  _| |___/ |  | |
	| | |_________|  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_f

	 .----------------.
	| .--------------. |
	| |  _________   | |
	| | |_   ___  |  | |
	| |   | |_  \_|  | |
	| |   |  _|      | |
	| |  _| |_       | |
	| | |_____|      | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_g

	 .----------------.
	| .--------------. |
	| |    ______    | |
	| |  .' ___  |   | |
	| | / .'   \_|   | |
	| | | |    ____  | |
	| | \ `.___]  _| | |
	| |  `._____.'   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_h

	 .----------------.
	| .--------------. |
	| |  ____  ____  | |
	| | |_   ||   _| | |
	| |   | |__| |   | |
	| |   |  __  |   | |
	| |  _| |  | |_  | |
	| | |____||____| | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_i

	 .----------------.
	| .--------------. |
	| |     _____    | |
	| |    |_   _|   | |
	| |      | |     | |
	| |      | |     | |
	| |     _| |_    | |
	| |    |_____|   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_j

	 .----------------.
	| .--------------. |
	| |     _____    | |
	| |    |_   _|   | |
	| |      | |     | |
	| |   _  | |     | |
	| |  | |_' |     | |
	| |  `.___.'     | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_k

	 .----------------.
	| .--------------. |
	| |  ___  ____   | |
	| | |_  ||_  _|  | |
	| |   | |_/ /    | |
	| |   |  __'.    | |
	| |  _| |  \ \_  | |
	| | |____||____| | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_l

	 .----------------.
	| .--------------. |
	| |   _____      | |
	| |  |_   _|     | |
	| |    | |       | |
	| |    | |   _   | |
	| |   _| |__/ |  | |
	| |  |________|  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_m

	 .----------------.
	| .--------------. |
	| | ____    ____ | |
	| ||_   \  /   _|| |
	| |  |   \/   |  | |
	| |  | |\  /| |  | |
	| | _| |_\/_| |_ | |
	| ||_____||_____|| |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_n

	 .----------------.
	| .--------------. |
	| | ____  _____  | |
	| ||_   \|_   _| | |
	| |  |   \ | |   | |
	| |  |  \ \| |   | |
	| | _| |_\   |_  | |
	| ||_____|\____| | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_o

	 .----------------.
	| .--------------. |
	| |     ____     | |
	| |   .'    `.   | |
	| |  /  .--.  \  | |
	| |  | |    | |  | |
	| |  \  `--'  /  | |
	| |   `.____.'   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_p

	 .----------------.
	| .--------------. |
	| |   ______     | |
	| |  |_   __  \  | |
	| |    | |__) |  | |
	| |    |  ___/   | |
	| |   _| |_      | |
	| |  |_____|     | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_q

	 .----------------.
	| .--------------. |
	| |    ___       | |
	| |  .'   '.     | |
	| | /  .-.  \    | |
	| | | |   | |    | |
	| | \  `-'  \_   | |
	| |  `.___.\__|  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_r

	 .----------------.
	| .--------------. |
	| |  _______     | |
	| | |_   __ \    | |
	| |   | |__) |   | |
	| |   |  __ /    | |
	| |  _| |  \ \_  | |
	| | |___ | |___| | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_s

	 .----------------.
	| .--------------. |
	| |    _______   | |
	| |   /  ___  |  | |
	| |  |  (__ \_|  | |
	| |   '.___`.    | |
	| |  |`\____) |  | |
	| |  |_______.'  | |
	| |              | |
	|  --------------  |
	  ----------------

=head2 character_t

	 .----------------.
	| .--------------. |
	| |  _________   | |
	| | |  _   _  |  | |
	| | |_/ | | \_|  | |
	| |     | |      | |
	| |    _| |_     | |
	| |   |_____|    | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_u

	 .----------------.
	| .--------------. |
	| | _____  _____ | |
	| ||_   _||_   _|| |
	| |  | |    | |  | |
	| |  | '    ' |  | |
	| |   \ `--' /   | |
	| |    `.__.'    | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_v

	 .----------------.
	| .--------------. |
	| | ____   ____  | |
	| ||_  _| |_  _| | |
	| |  \ \   / /   | |
	| |   \ \ / /    | |
	| |    \ ' /     | |
	| |     \_/      | |
	| |              | |
	| .--------------. |
	 '----------------'

=head2 character_w

	 .----------------.
	| .--------------. |
	| | _____  _____ | |
	| ||_   _||_   _|| |
	| |  | | /\ | |  | |
	| |  | |/  \| |  | |
	| |  |   /\   |  | |
	| |  |__/  \__|  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_x

	 .----------------.
	| .--------------. |
	| |  ____  ____  | |
	| | |_  _||_  _| | |
	| |   \ \  / /   | |
	| |    > `' <    | |
	| |  _/ /'`\ \_  | |
	| | |____||____| | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_y

	 .----------------.
	| .--------------. |
	| |  ____  ____  | |
	| | |_  _||_  _| | |
	| |   \ \  / /   | |
	| |    \ \/ /    | |
	| |    _|  |_    | |
	| |   |______|   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_z

	 .----------------.
	| .--------------. |
	| |   ________   | |
	| |  |  __   _|  | |
	| |  |_/  / /    | |
	| |     .'.' _   | |
	| |   _/ /__/ |  | |
	| |  |________|  | |
	| |              | |
	| .--------------. |
	 '----------------'

=head2 character_0

	 .----------------.
	| .--------------. |
	| |     ____     | |
	| |   .'    '.   | |
	| |  |  .--.  |  | |
	| |  | |    | |  | |
	| |  |   --'  |  | |
	| |   '.____.'   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_1

	 .----------------.
	| .--------------. |
	| |     __       | |
	| |    /  |      | |
	| |    `| |      | |
	| |     | |      | |
	| |    _| |_     | |
	| |   |_____|    | |
	| |              | |
	| .--------------. |
	 '----------------'

=head2 character_2

	 .----------------.
	| .--------------. |
	| |    _____     | |
	| |   / ___ `.   | |
	| |  |_/___) |   | |
	| |   .'____.'   | |
	| |  / /____     | |
	| |  |_______|   | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_3

	 .----------------.
	| .--------------. |
	| |    ______    | |
	| |   / ____ '.  | |
	| |   ''  __) |  | |
	| |   _  |__ '.  | |
	| |  | \____) |  | |
	| |   \______.'  | |
	| |              | |
	| |--------------' |
	 '----------------'

=head2 character_4

	 .----------------.
	| .--------------. |
	| |   _    _     | |
	| |  | |  | |    | |
	| |  | |__| |_   | |
	| |  |____   _|  | |
	| |      _| |_   | |
	| |     |_____|  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_5

	 .----------------.
	| .--------------. |
	| |   _______    | |
	| |  |  _____|   | |
	| |  | |____     | |
	| |  '_.____''.  | |
	| |  | \____) |  | |
	| |   \______.'  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_6

	 .----------------.
	| .--------------. |
	| |    ______    | |
	| |  .' ____ \   | |
	| |  | |____\_|  | |
	| |  | '____`'.  | |
	| |  | (____) |  | |
	| |  '.______.'  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_7

	 .----------------.
	| .--------------. |
	| |   _______    | |
	| |  |  ___  |   | |
	| |  |_/  / /    | |
	| |      / /     | |
	| |     / /      | |
	| |    /_/       | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_8

	 .----------------.
	| .--------------. |
	| |     ____     | |
	| |   .' __ '.   | |
	| |   | (__) |   | |
	| |   .`____'.   | |
	| |  | (____) |  | |
	| |  `.______.'  | |
	| |              | |
	| '--------------' |
	 '----------------'

=head2 character_9

	 .----------------.
	| .--------------. |
	| |    ______    | |
	| |  .' ____ '.  | |
	| |  | (____) |  | |
	| |  '_.____. |  | |
	| |  | \____| |  | |
	| |   \______,'  | |
	| |              | |
	| '--------------' |
	 '----------------'
       
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



