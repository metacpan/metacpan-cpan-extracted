package Ascii::Text::Font::Doh;
use strict;
use warnings;
use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable => 0,
	writable => 0,
	value => 25,
);

function space => sub {
	my @character = $_[0]->default_character(30);
	return \@character;
};


function character_A => sub {
	my @character = $_[0]->default_character(33);
	$character[2][15] = $character[2][16] = $character[2][17]
	    = $character[3][14]  = $character[3][18]  = $character[4][13]
	    = $character[4][19]  = $character[5][12]  = $character[5][20]
	    = $character[6][11]  = $character[6][21]  = $character[7][10]
	    = $character[7][16]  = $character[7][22]  = $character[8][9]
	    = $character[8][15]  = $character[8][17]  = $character[8][23]
	    = $character[9][8]   = $character[9][14]  = $character[9][18]
	    = $character[9][24]  = $character[10][7]  = $character[10][13]
	    = $character[10][19] = $character[10][25] = $character[11][6]
	    = $character[11][12] = $character[11][13] = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[11][19] = $character[11][20]
	    = $character[11][26] = $character[12][5]  = $character[12][27]
	    = $character[13][4]  = $character[13][10] = $character[13][11]
	    = $character[13][12] = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[13][18] = $character[13][19] = $character[13][20]
	    = $character[13][21] = $character[13][22] = $character[13][28]
	    = $character[14][3]  = $character[14][9]  = $character[14][23]
	    = $character[14][29] = $character[15][2]  = $character[15][8]
	    = $character[15][24] = $character[15][30] = $character[16][1]
	    = $character[16][7]  = $character[16][25] = $character[16][31]
	    = $character[17][0]  = $character[17][1]  = $character[17][2]
	    = $character[17][3]  = $character[17][4]  = $character[17][5]
	    = $character[17][6]  = $character[17][26] = $character[17][27]
	    = $character[17][28] = $character[17][29] = $character[17][30]
	    = $character[17][31] = $character[17][32] = 'A';
	$character[3][15] = $character[3][16] = $character[3][17]
	    = $character[4][14]  = $character[4][15]  = $character[4][16]
	    = $character[4][17]  = $character[4][18]  = $character[5][13]
	    = $character[5][14]  = $character[5][15]  = $character[5][16]
	    = $character[5][17]  = $character[5][18]  = $character[5][19]
	    = $character[6][12]  = $character[6][13]  = $character[6][14]
	    = $character[6][15]  = $character[6][16]  = $character[6][17]
	    = $character[6][18]  = $character[6][19]  = $character[6][20]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[7][17]
	    = $character[7][18]  = $character[7][19]  = $character[7][20]
	    = $character[7][21]  = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[8][18]  = $character[8][19]  = $character[8][20]
	    = $character[8][21]  = $character[8][22]  = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][19]  = $character[9][20]
	    = $character[9][21]  = $character[9][22]  = $character[9][23]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[10][12] = $character[10][20]
	    = $character[10][21] = $character[10][22] = $character[10][23]
	    = $character[10][24] = $character[11][7]  = $character[11][8]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[11][21] = $character[11][22] = $character[11][23]
	    = $character[11][24] = $character[11][25] = $character[12][6]
	    = $character[12][7]  = $character[12][8]  = $character[12][9]
	    = $character[12][10] = $character[12][11] = $character[12][12]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[12][18]
	    = $character[12][19] = $character[12][20] = $character[12][21]
	    = $character[12][22] = $character[12][23] = $character[12][24]
	    = $character[12][25] = $character[12][26] = $character[13][5]
	    = $character[13][6]  = $character[13][7]  = $character[13][8]
	    = $character[13][9]  = $character[13][23] = $character[13][24]
	    = $character[13][25] = $character[13][26] = $character[13][27]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][7]  = $character[14][8]  = $character[14][24]
	    = $character[14][25] = $character[14][26] = $character[14][27]
	    = $character[14][28] = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][25] = $character[15][26] = $character[15][27]
	    = $character[15][28] = $character[15][29] = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][26] = $character[16][27]
	    = $character[16][28] = $character[16][29] = $character[16][30] = ':';
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(20);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[3][0]   = $character[3][17]
	    = $character[4][0]   = $character[4][7]   = $character[4][8]
	    = $character[4][9]   = $character[4][10]  = $character[4][11]
	    = $character[4][12]  = $character[4][18]  = $character[5][0]
	    = $character[5][1]   = $character[5][7]   = $character[5][13]
	    = $character[5][19]  = $character[6][2]   = $character[6][7]
	    = $character[6][13]  = $character[6][19]  = $character[7][2]
	    = $character[7][7]   = $character[7][13]  = $character[7][19]
	    = $character[8][2]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][18]  = $character[9][2]
	    = $character[9][16]  = $character[9][17]  = $character[10][2]
	    = $character[10][7]  = $character[10][8]  = $character[10][9]
	    = $character[10][10] = $character[10][11] = $character[10][12]
	    = $character[10][18] = $character[11][2]  = $character[11][7]
	    = $character[11][13] = $character[11][19] = $character[12][2]
	    = $character[12][7]  = $character[12][13] = $character[12][19]
	    = $character[13][2]  = $character[13][7]  = $character[13][13]
	    = $character[13][19] = $character[14][0]  = $character[14][1]
	    = $character[14][7]  = $character[14][8]  = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][19] = $character[15][0]  = $character[15][18]
	    = $character[16][0]  = $character[16][17] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][14] = $character[17][15]
	    = $character[17][16] = 'B';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[4][1]   = $character[4][2]   = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][6]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[4][16]  = $character[4][17]  = $character[5][2]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[5][18]
	    = $character[6][3]   = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[7][3]   = $character[7][4]   = $character[7][5]
	    = $character[7][6]   = $character[7][14]  = $character[7][15]
	    = $character[7][16]  = $character[7][17]  = $character[7][18]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[8][16]  = $character[8][17]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][9]   = $character[9][10]  = $character[9][11]
	    = $character[9][12]  = $character[9][13]  = $character[9][14]
	    = $character[9][15]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][13]
	    = $character[10][14] = $character[10][15] = $character[10][16]
	    = $character[10][17] = $character[11][3]  = $character[11][4]
	    = $character[11][5]  = $character[11][6]  = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[12][3]  = $character[12][4]
	    = $character[12][5]  = $character[12][6]  = $character[12][14]
	    = $character[12][15] = $character[12][16] = $character[12][17]
	    = $character[12][18] = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[13][18] = $character[14][2]  = $character[14][3]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][17] = $character[14][18]
	    = $character[15][1]  = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[15][16] = $character[15][17] = $character[16][1]
	    = $character[16][2]  = $character[16][3]  = $character[16][4]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[16][16] = ':';
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(21);
	$character[2][8] = $character[2][9] = $character[2][10]
	    = $character[2][11]  = $character[2][12]  = $character[2][13]
	    = $character[2][14]  = $character[2][15]  = $character[2][16]
	    = $character[2][17]  = $character[2][18]  = $character[2][19]
	    = $character[2][20]  = $character[3][5]   = $character[3][6]
	    = $character[3][7]   = $character[3][20]  = $character[4][3]
	    = $character[4][4]   = $character[4][20]  = $character[5][2]
	    = $character[5][8]   = $character[5][9]   = $character[5][10]
	    = $character[5][11]  = $character[5][12]  = $character[5][13]
	    = $character[5][14]  = $character[5][15]  = $character[5][20]
	    = $character[6][1]   = $character[6][7]   = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[6][20]  = $character[7][0]
	    = $character[7][6]   = $character[8][0]   = $character[8][6]
	    = $character[9][0]   = $character[9][6]   = $character[10][0]
	    = $character[10][6]  = $character[11][0]  = $character[11][6]
	    = $character[12][0]  = $character[12][6]  = $character[13][1]
	    = $character[13][7]  = $character[13][15] = $character[13][16]
	    = $character[13][17] = $character[13][18] = $character[13][19]
	    = $character[13][20] = $character[14][2]  = $character[14][8]
	    = $character[14][9]  = $character[14][10] = $character[14][11]
	    = $character[14][12] = $character[14][13] = $character[14][14]
	    = $character[14][15] = $character[14][20] = $character[15][3]
	    = $character[15][4]  = $character[15][20] = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][20]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16]
	    = $character[17][17] = $character[17][18] = $character[17][19]
	    = $character[17][20] = 'C';
	$character[3][8] = $character[3][9] = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[3][19]
	    = $character[4][5]   = $character[4][6]   = $character[4][7]
	    = $character[4][8]   = $character[4][9]   = $character[4][10]
	    = $character[4][11]  = $character[4][12]  = $character[4][13]
	    = $character[4][14]  = $character[4][15]  = $character[4][16]
	    = $character[4][17]  = $character[4][18]  = $character[4][19]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[5][7]   = $character[5][16]
	    = $character[5][17]  = $character[5][18]  = $character[5][19]
	    = $character[6][2]   = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[7][1]
	    = $character[7][2]   = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[8][1]   = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[9][1]   = $character[9][2]   = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[11][1]  = $character[11][2]
	    = $character[11][3]  = $character[11][4]  = $character[11][5]
	    = $character[12][1]  = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[13][2]
	    = $character[13][3]  = $character[13][4]  = $character[13][5]
	    = $character[13][6]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][16] = $character[14][17] = $character[14][18]
	    = $character[14][19] = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[15][16] = $character[15][17] = $character[15][18]
	    = $character[15][19] = $character[16][8]  = $character[16][9]
	    = $character[16][10] = $character[16][11] = $character[16][12]
	    = $character[16][13] = $character[16][14] = $character[16][15]
	    = $character[16][16] = $character[16][17] = $character[16][18]
	    = $character[16][19] = ':';
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(21);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[3][0]   = $character[3][13]  = $character[3][14]
	    = $character[3][15]  = $character[4][0]   = $character[4][16]
	    = $character[4][17]  = $character[5][0]   = $character[5][1]
	    = $character[5][2]   = $character[5][8]   = $character[5][9]
	    = $character[5][10]  = $character[5][11]  = $character[5][12]
	    = $character[5][18]  = $character[6][2]   = $character[6][8]
	    = $character[6][13]  = $character[6][19]  = $character[7][2]
	    = $character[7][8]   = $character[7][14]  = $character[7][20]
	    = $character[8][2]   = $character[8][8]   = $character[8][14]
	    = $character[8][20]  = $character[9][2]   = $character[9][8]
	    = $character[9][14]  = $character[9][20]  = $character[10][2]
	    = $character[10][8]  = $character[10][14] = $character[10][20]
	    = $character[11][2]  = $character[11][8]  = $character[11][14]
	    = $character[11][20] = $character[12][2]  = $character[12][8]
	    = $character[12][14] = $character[12][20] = $character[13][2]
	    = $character[13][8]  = $character[13][13] = $character[13][19]
	    = $character[14][0]  = $character[14][1]  = $character[14][2]
	    = $character[14][8]  = $character[14][9]  = $character[14][10]
	    = $character[14][11] = $character[14][12] = $character[14][18]
	    = $character[15][0]  = $character[15][16] = $character[15][17]
	    = $character[16][0]  = $character[16][13] = $character[16][14]
	    = $character[16][15] = $character[17][0]  = $character[17][1]
	    = $character[17][2]  = $character[17][3]  = $character[17][4]
	    = $character[17][5]  = $character[17][6]  = $character[17][7]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][12] = 'D';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[4][7]
	    = $character[4][8]   = $character[4][9]   = $character[4][10]
	    = $character[4][11]  = $character[4][12]  = $character[4][13]
	    = $character[4][14]  = $character[4][15]  = $character[5][3]
	    = $character[5][4]   = $character[5][5]   = $character[5][6]
	    = $character[5][7]   = $character[5][13]  = $character[5][14]
	    = $character[5][15]  = $character[5][16]  = $character[5][17]
	    = $character[6][3]   = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[6][7]   = $character[6][14]
	    = $character[6][15]  = $character[6][16]  = $character[6][17]
	    = $character[6][18]  = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[7][6]   = $character[7][7]
	    = $character[7][15]  = $character[7][16]  = $character[7][17]
	    = $character[7][18]  = $character[7][19]  = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[8][6]
	    = $character[8][7]   = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[8][18]  = $character[8][19]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[9][18]
	    = $character[9][19]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][7]
	    = $character[10][15] = $character[10][16] = $character[10][17]
	    = $character[10][18] = $character[10][19] = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][6]
	    = $character[11][7]  = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[11][18] = $character[11][19]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][6]  = $character[12][7]  = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[12][18]
	    = $character[12][19] = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][7]
	    = $character[13][14] = $character[13][15] = $character[13][16]
	    = $character[13][17] = $character[13][18] = $character[14][3]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][7]  = $character[14][13] = $character[14][14]
	    = $character[14][15] = $character[14][16] = $character[14][17]
	    = $character[15][1]  = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[16][1]  = $character[16][2]  = $character[16][3]
	    = $character[16][4]  = $character[16][5]  = $character[16][6]
	    = $character[16][7]  = $character[16][8]  = $character[16][9]
	    = $character[16][10] = $character[16][11] = $character[16][12] = ':';
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(22);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[3][19]
	    = $character[3][20]  = $character[4][1]   = $character[4][2]
	    = $character[4][3]   = $character[4][4]   = $character[4][5]
	    = $character[4][6]   = $character[4][7]   = $character[4][8]
	    = $character[4][9]   = $character[4][10]  = $character[4][11]
	    = $character[4][12]  = $character[4][13]  = $character[4][14]
	    = $character[4][15]  = $character[4][16]  = $character[4][17]
	    = $character[4][18]  = $character[4][19]  = $character[4][20]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[5][7]
	    = $character[5][17]  = $character[5][18]  = $character[5][19]
	    = $character[5][20]  = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][7]
	    = $character[7][3]   = $character[7][4]   = $character[7][5]
	    = $character[7][6]   = $character[7][7]   = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[8][6]
	    = $character[8][7]   = $character[8][8]   = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[9][6]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[10][3]
	    = $character[10][4]  = $character[10][5]  = $character[10][6]
	    = $character[10][7]  = $character[10][8]  = $character[10][9]
	    = $character[10][10] = $character[10][11] = $character[10][12]
	    = $character[10][13] = $character[10][14] = $character[10][15]
	    = $character[10][16] = $character[10][17] = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][6]
	    = $character[11][7]  = $character[11][8]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][6]
	    = $character[12][7]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][7]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][16] = $character[14][17] = $character[14][18]
	    = $character[14][19] = $character[14][20] = $character[15][1]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[15][17] = $character[15][18] = $character[15][19]
	    = $character[15][20] = $character[16][1]  = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = $character[16][13] = $character[16][14]
	    = $character[16][15] = $character[16][16] = $character[16][17]
	    = $character[16][18] = $character[16][19] = $character[16][20] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[2][17]  = $character[2][18]
	    = $character[2][19]  = $character[2][20]  = $character[2][21]
	    = $character[3][0]   = $character[3][21]  = $character[4][0]
	    = $character[4][21]  = $character[5][0]   = $character[5][1]
	    = $character[5][8]   = $character[5][9]   = $character[5][10]
	    = $character[5][11]  = $character[5][12]  = $character[5][13]
	    = $character[5][14]  = $character[5][15]  = $character[5][16]
	    = $character[5][21]  = $character[6][2]   = $character[6][8]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[6][20]  = $character[6][21]
	    = $character[7][2]   = $character[7][8]   = $character[8][2]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[8][16]  = $character[8][17]
	    = $character[8][18]  = $character[9][2]   = $character[9][18]
	    = $character[10][2]  = $character[10][18] = $character[11][2]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[11][12] = $character[11][13] = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[12][2]  = $character[12][8]
	    = $character[13][2]  = $character[13][8]  = $character[13][16]
	    = $character[13][17] = $character[13][18] = $character[13][19]
	    = $character[13][20] = $character[13][21] = $character[14][0]
	    = $character[14][1]  = $character[14][8]  = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][21] = $character[15][0]  = $character[15][21]
	    = $character[16][0]  = $character[16][21] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][14] = $character[17][15]
	    = $character[17][16] = $character[17][17] = $character[17][18]
	    = $character[17][19] = $character[17][20] = $character[17][21] = 'E';
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(22);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[2][17]  = $character[2][18]
	    = $character[2][19]  = $character[2][20]  = $character[2][21]
	    = $character[3][0]   = $character[3][21]  = $character[4][0]
	    = $character[4][21]  = $character[5][0]   = $character[5][1]
	    = $character[5][8]   = $character[5][9]   = $character[5][10]
	    = $character[5][11]  = $character[5][12]  = $character[5][13]
	    = $character[5][14]  = $character[5][15]  = $character[5][16]
	    = $character[5][21]  = $character[6][2]   = $character[6][8]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[6][20]  = $character[6][21]
	    = $character[7][2]   = $character[7][8]   = $character[8][2]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[8][16]  = $character[8][17]
	    = $character[8][18]  = $character[9][2]   = $character[9][18]
	    = $character[10][2]  = $character[10][18] = $character[11][2]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[11][12] = $character[11][13] = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[12][2]  = $character[12][8]
	    = $character[13][2]  = $character[13][8]  = $character[14][0]
	    = $character[14][1]  = $character[14][9]  = $character[14][10]
	    = $character[15][0]  = $character[15][9]  = $character[15][10]
	    = $character[16][0]  = $character[16][9]  = $character[16][10]
	    = $character[17][0]  = $character[17][1]  = $character[17][2]
	    = $character[17][3]  = $character[17][4]  = $character[17][5]
	    = $character[17][6]  = $character[17][7]  = $character[17][8]
	    = $character[17][9]  = $character[17][10] = 'F';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[3][19]
	    = $character[3][20]  = $character[4][1]   = $character[4][2]
	    = $character[4][3]   = $character[4][4]   = $character[4][5]
	    = $character[4][6]   = $character[4][7]   = $character[4][8]
	    = $character[4][9]   = $character[4][10]  = $character[4][11]
	    = $character[4][12]  = $character[4][13]  = $character[4][14]
	    = $character[4][15]  = $character[4][16]  = $character[4][17]
	    = $character[4][18]  = $character[4][19]  = $character[4][20]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[5][7]
	    = $character[5][17]  = $character[5][18]  = $character[5][19]
	    = $character[5][20]  = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][7]
	    = $character[7][3]   = $character[7][4]   = $character[7][5]
	    = $character[7][6]   = $character[7][7]   = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[8][6]
	    = $character[8][7]   = $character[8][8]   = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[9][6]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[10][3]
	    = $character[10][4]  = $character[10][5]  = $character[10][6]
	    = $character[10][7]  = $character[10][8]  = $character[10][9]
	    = $character[10][10] = $character[10][11] = $character[10][12]
	    = $character[10][13] = $character[10][14] = $character[10][15]
	    = $character[10][16] = $character[10][17] = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][6]
	    = $character[11][7]  = $character[11][8]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][6]
	    = $character[12][7]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][7]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][8]  = $character[15][1]  = $character[15][2]
	    = $character[15][3]  = $character[15][4]  = $character[15][5]
	    = $character[15][6]  = $character[15][7]  = $character[15][8]
	    = $character[16][1]  = $character[16][2]  = $character[16][3]
	    = $character[16][4]  = $character[16][5]  = $character[16][6]
	    = $character[16][7]  = $character[16][8]  = ':';
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(21);
	$character[2][8] = $character[2][9] = $character[2][10]
	    = $character[2][11]  = $character[2][12]  = $character[2][13]
	    = $character[2][14]  = $character[2][15]  = $character[2][16]
	    = $character[2][17]  = $character[2][18]  = $character[2][19]
	    = $character[2][20]  = $character[3][5]   = $character[3][6]
	    = $character[3][7]   = $character[3][20]  = $character[4][3]
	    = $character[4][4]   = $character[4][20]  = $character[5][2]
	    = $character[5][8]   = $character[5][9]   = $character[5][10]
	    = $character[5][11]  = $character[5][12]  = $character[5][13]
	    = $character[5][14]  = $character[5][15]  = $character[5][20]
	    = $character[6][1]   = $character[6][7]   = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[6][20]  = $character[7][0]
	    = $character[7][6]   = $character[8][0]   = $character[8][6]
	    = $character[9][0]   = $character[9][6]   = $character[9][11]
	    = $character[9][12]  = $character[9][13]  = $character[9][14]
	    = $character[9][15]  = $character[9][16]  = $character[9][17]
	    = $character[9][18]  = $character[9][19]  = $character[9][20]
	    = $character[10][0]  = $character[10][6]  = $character[10][11]
	    = $character[10][20] = $character[11][0]  = $character[11][6]
	    = $character[11][11] = $character[11][12] = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][20]
	    = $character[12][0]  = $character[12][6]  = $character[12][15]
	    = $character[12][20] = $character[13][1]  = $character[13][7]
	    = $character[13][15] = $character[13][20] = $character[14][2]
	    = $character[14][8]  = $character[14][9]  = $character[14][10]
	    = $character[14][11] = $character[14][12] = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[14][20]
	    = $character[15][3]  = $character[15][4]  = $character[15][20]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][14] = $character[16][15] = $character[16][16]
	    = $character[16][20] = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][17] = $character[17][18]
	    = $character[17][19] = $character[17][20] = 'G';
	$character[3][8] = $character[3][9] = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[3][19]
	    = $character[4][5]   = $character[4][6]   = $character[4][7]
	    = $character[4][8]   = $character[4][9]   = $character[4][10]
	    = $character[4][11]  = $character[4][12]  = $character[4][13]
	    = $character[4][14]  = $character[4][15]  = $character[4][16]
	    = $character[4][17]  = $character[4][18]  = $character[4][19]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[5][7]   = $character[5][16]
	    = $character[5][17]  = $character[5][18]  = $character[5][19]
	    = $character[6][2]   = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[7][1]
	    = $character[7][2]   = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[8][1]   = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[9][1]   = $character[9][2]   = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][12] = $character[10][13]
	    = $character[10][14] = $character[10][15] = $character[10][16]
	    = $character[10][17] = $character[10][18] = $character[10][19]
	    = $character[11][1]  = $character[11][2]  = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][16]
	    = $character[11][17] = $character[11][18] = $character[11][19]
	    = $character[12][1]  = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][16]
	    = $character[12][17] = $character[12][18] = $character[12][19]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][16]
	    = $character[13][17] = $character[13][18] = $character[13][19]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][7]  = $character[14][16]
	    = $character[14][17] = $character[14][18] = $character[14][19]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[15][17] = $character[15][18] = $character[15][19]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][17] = $character[16][18] = $character[16][19] = ':';
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(23);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][15]  = $character[3][16]  = $character[3][17]
	    = $character[3][18]  = $character[3][19]  = $character[3][20]
	    = $character[3][21]  = $character[4][1]   = $character[4][2]
	    = $character[4][3]   = $character[4][4]   = $character[4][5]
	    = $character[4][6]   = $character[4][7]   = $character[4][15]
	    = $character[4][16]  = $character[4][17]  = $character[4][18]
	    = $character[4][19]  = $character[4][20]  = $character[4][21]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[5][7]
	    = $character[5][15]  = $character[5][16]  = $character[5][17]
	    = $character[5][18]  = $character[5][19]  = $character[5][20]
	    = $character[6][3]   = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[6][7]   = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[7][6]   = $character[7][7]
	    = $character[7][15]  = $character[7][16]  = $character[7][17]
	    = $character[7][18]  = $character[7][19]  = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[8][6]
	    = $character[8][7]   = $character[8][8]   = $character[8][14]
	    = $character[8][15]  = $character[8][16]  = $character[8][17]
	    = $character[8][18]  = $character[8][19]  = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[9][6]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[9][18]
	    = $character[9][19]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][7]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[10][12] = $character[10][13]
	    = $character[10][14] = $character[10][15] = $character[10][16]
	    = $character[10][17] = $character[10][18] = $character[10][19]
	    = $character[11][3]  = $character[11][4]  = $character[11][5]
	    = $character[11][6]  = $character[11][7]  = $character[11][8]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[11][18] = $character[11][19]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][6]  = $character[12][7]  = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[12][18]
	    = $character[12][19] = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][7]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[13][18] = $character[13][19] = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][7]  = $character[14][15]
	    = $character[14][16] = $character[14][17] = $character[14][18]
	    = $character[14][19] = $character[14][20] = $character[15][1]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][15] = $character[15][16] = $character[15][17]
	    = $character[15][18] = $character[15][19] = $character[15][20]
	    = $character[15][21] = $character[16][1]  = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][15]
	    = $character[16][16] = $character[16][17] = $character[16][18]
	    = $character[16][19] = $character[16][20] = $character[16][21] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][14]
	    = $character[2][15]  = $character[2][16]  = $character[2][17]
	    = $character[2][18]  = $character[2][19]  = $character[2][20]
	    = $character[2][21]  = $character[2][22]  = $character[3][0]
	    = $character[3][8]   = $character[3][14]  = $character[3][22]
	    = $character[4][0]   = $character[4][8]   = $character[4][14]
	    = $character[4][22]  = $character[5][0]   = $character[5][1]
	    = $character[5][8]   = $character[5][14]  = $character[5][21]
	    = $character[5][22]  = $character[6][2]   = $character[6][8]
	    = $character[6][14]  = $character[6][20]  = $character[7][2]
	    = $character[7][8]   = $character[7][14]  = $character[7][20]
	    = $character[8][2]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][12]  = $character[8][13]
	    = $character[8][20]  = $character[9][2]   = $character[9][20]
	    = $character[10][2]  = $character[10][20] = $character[11][2]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[11][12] = $character[11][13] = $character[11][20]
	    = $character[12][2]  = $character[12][8]  = $character[12][14]
	    = $character[12][20] = $character[13][2]  = $character[13][8]
	    = $character[13][14] = $character[13][20] = $character[14][0]
	    = $character[14][1]  = $character[14][8]  = $character[14][14]
	    = $character[14][21] = $character[14][22] = $character[15][0]
	    = $character[15][8]  = $character[15][14] = $character[15][22]
	    = $character[16][0]  = $character[16][8]  = $character[16][14]
	    = $character[16][22] = $character[17][0]  = $character[17][1]
	    = $character[17][2]  = $character[17][3]  = $character[17][4]
	    = $character[17][5]  = $character[17][6]  = $character[17][7]
	    = $character[17][8]  = $character[17][14] = $character[17][15]
	    = $character[17][16] = $character[17][17] = $character[17][18]
	    = $character[17][19] = $character[17][20] = $character[17][21]
	    = $character[17][22] = 'H';
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(10);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]  = $character[3][6]  = $character[3][7]
	    = $character[3][8]  = $character[4][1]  = $character[4][2]
	    = $character[4][3]  = $character[4][4]  = $character[4][5]
	    = $character[4][6]  = $character[4][7]  = $character[4][8]
	    = $character[5][2]  = $character[5][3]  = $character[5][4]
	    = $character[5][5]  = $character[5][6]  = $character[5][7]
	    = $character[6][3]  = $character[6][4]  = $character[6][5]
	    = $character[6][6]  = $character[7][3]  = $character[7][4]
	    = $character[7][5]  = $character[7][6]  = $character[8][3]
	    = $character[8][4]  = $character[8][5]  = $character[8][6]
	    = $character[9][3]  = $character[9][4]  = $character[9][5]
	    = $character[9][6]  = $character[10][3] = $character[10][4]
	    = $character[10][5] = $character[10][6] = $character[11][3]
	    = $character[11][4] = $character[11][5] = $character[11][6]
	    = $character[12][3] = $character[12][4] = $character[12][5]
	    = $character[12][6] = $character[13][3] = $character[13][4]
	    = $character[13][5] = $character[13][6] = $character[14][2]
	    = $character[14][3] = $character[14][4] = $character[14][5]
	    = $character[14][6] = $character[14][7] = $character[15][1]
	    = $character[15][2] = $character[15][3] = $character[15][4]
	    = $character[15][5] = $character[15][6] = $character[15][7]
	    = $character[15][8] = $character[16][1] = $character[16][2]
	    = $character[16][3] = $character[16][4] = $character[16][5]
	    = $character[16][6] = $character[16][7] = $character[16][8] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]  = $character[2][5]  = $character[2][6]
	    = $character[2][7]  = $character[2][8]  = $character[2][9]
	    = $character[3][0]  = $character[3][9]  = $character[4][0]
	    = $character[4][9]  = $character[5][0]  = $character[5][1]
	    = $character[5][8]  = $character[5][9]  = $character[6][2]
	    = $character[6][7]  = $character[7][2]  = $character[7][7]
	    = $character[8][2]  = $character[8][7]  = $character[9][2]
	    = $character[9][7]  = $character[10][2] = $character[10][7]
	    = $character[11][2] = $character[11][7] = $character[12][2]
	    = $character[12][7] = $character[13][2] = $character[13][7]
	    = $character[14][0] = $character[14][1] = $character[14][8]
	    = $character[14][9] = $character[15][0] = $character[15][9]
	    = $character[16][0] = $character[16][9] = $character[17][0]
	    = $character[17][1] = $character[17][2] = $character[17][3]
	    = $character[17][4] = $character[17][5] = $character[17][6]
	    = $character[17][7] = $character[17][8] = $character[17][9] = 'I';
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(21);
	$character[2][10] = $character[2][11] = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[2][17]  = $character[2][18]
	    = $character[2][19]  = $character[2][20]  = $character[3][10]
	    = $character[3][20]  = $character[4][10]  = $character[4][20]
	    = $character[5][10]  = $character[5][11]  = $character[5][19]
	    = $character[5][20]  = $character[6][12]  = $character[6][18]
	    = $character[7][12]  = $character[7][18]  = $character[8][12]
	    = $character[8][18]  = $character[9][12]  = $character[10][12]
	    = $character[10][18] = $character[11][0]  = $character[11][1]
	    = $character[11][2]  = $character[11][3]  = $character[11][4]
	    = $character[11][5]  = $character[11][6]  = $character[11][12]
	    = $character[11][18] = $character[12][0]  = $character[12][6]
	    = $character[12][12] = $character[12][18] = $character[13][0]
	    = $character[13][7]  = $character[13][11] = $character[13][18]
	    = $character[14][0]  = $character[14][8]  = $character[14][9]
	    = $character[14][10] = $character[14][18] = $character[15][1]
	    = $character[15][2]  = $character[15][16] = $character[15][17]
	    = $character[16][3]  = $character[16][4]  = $character[16][14]
	    = $character[16][15] = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = 'J';
	$character[3][11] = $character[3][12] = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[3][19]
	    = $character[4][11]  = $character[4][12]  = $character[4][13]
	    = $character[4][14]  = $character[4][15]  = $character[4][16]
	    = $character[4][17]  = $character[4][18]  = $character[4][19]
	    = $character[5][12]  = $character[5][13]  = $character[5][14]
	    = $character[5][15]  = $character[5][16]  = $character[5][17]
	    = $character[5][18]  = $character[6][13]  = $character[6][14]
	    = $character[6][15]  = $character[6][16]  = $character[6][17]
	    = $character[7][13]  = $character[7][14]  = $character[7][15]
	    = $character[7][16]  = $character[7][17]  = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[9][13]  = $character[9][14]
	    = $character[9][15]  = $character[9][16]  = $character[9][17]
	    = $character[10][13] = $character[10][14] = $character[10][15]
	    = $character[10][16] = $character[10][17] = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[12][1]  = $character[12][2]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][12]
	    = $character[13][13] = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[13][17] = $character[14][1]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][11] = $character[14][12] = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[14][16]
	    = $character[14][17] = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = $character[16][13] = ':';
	$character[9][18] = 'j';
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(20);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][13]
	    = $character[2][14]  = $character[2][15]  = $character[2][16]
	    = $character[2][17]  = $character[2][18]  = $character[2][19]
	    = $character[3][0]   = $character[3][8]   = $character[3][13]
	    = $character[3][19]  = $character[4][0]   = $character[4][8]
	    = $character[4][13]  = $character[4][19]  = $character[5][0]
	    = $character[5][8]   = $character[5][12]  = $character[5][19]
	    = $character[6][0]   = $character[6][1]   = $character[6][8]
	    = $character[6][11]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[7][2]   = $character[7][8]
	    = $character[7][10]  = $character[7][16]  = $character[8][2]
	    = $character[8][9]   = $character[8][15]  = $character[9][2]
	    = $character[9][14]  = $character[10][2]  = $character[10][14]
	    = $character[11][2]  = $character[11][9]  = $character[11][15]
	    = $character[12][2]  = $character[12][8]  = $character[12][10]
	    = $character[12][16] = $character[13][0]  = $character[13][1]
	    = $character[13][8]  = $character[13][11] = $character[13][17]
	    = $character[13][18] = $character[13][19] = $character[14][0]
	    = $character[14][8]  = $character[14][12] = $character[14][19]
	    = $character[15][0]  = $character[15][8]  = $character[15][13]
	    = $character[15][19] = $character[16][0]  = $character[16][8]
	    = $character[16][13] = $character[16][19] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16]
	    = $character[17][17] = $character[17][18] = $character[17][19] = 'K';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[4][7]
	    = $character[4][14]  = $character[4][15]  = $character[4][16]
	    = $character[4][17]  = $character[4][18]  = $character[5][1]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[5][7]
	    = $character[5][13]  = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[5][18]
	    = $character[6][2]   = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][7]
	    = $character[6][12]  = $character[6][13]  = $character[6][14]
	    = $character[6][15]  = $character[6][16]  = $character[7][3]
	    = $character[7][4]   = $character[7][5]   = $character[7][6]
	    = $character[7][7]   = $character[7][11]  = $character[7][12]
	    = $character[7][13]  = $character[7][14]  = $character[7][15]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][10]  = $character[8][11]  = $character[8][12]
	    = $character[8][13]  = $character[8][14]  = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[9][6]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][7]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[10][12] = $character[10][13]
	    = $character[11][3]  = $character[11][4]  = $character[11][5]
	    = $character[11][6]  = $character[11][7]  = $character[11][8]
	    = $character[11][10] = $character[11][11] = $character[11][12]
	    = $character[11][13] = $character[11][14] = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][6]
	    = $character[12][7]  = $character[12][11] = $character[12][12]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][7]
	    = $character[13][12] = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[14][1]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][17] = $character[14][18]
	    = $character[15][1]  = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][14] = $character[15][15]
	    = $character[15][16] = $character[15][17] = $character[15][18]
	    = $character[16][1]  = $character[16][2]  = $character[16][3]
	    = $character[16][4]  = $character[16][5]  = $character[16][6]
	    = $character[16][7]  = $character[16][14] = $character[16][15]
	    = $character[16][16] = $character[16][17] = $character[16][18] = ':';
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(24);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[4][7]
	    = $character[4][8]   = $character[4][9]   = $character[5][2]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[5][7]   = $character[5][8]
	    = $character[6][3]   = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[6][7]   = $character[7][3]
	    = $character[7][4]   = $character[7][5]   = $character[7][6]
	    = $character[7][7]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[10][3]
	    = $character[10][4]  = $character[10][5]  = $character[10][6]
	    = $character[10][7]  = $character[11][3]  = $character[11][4]
	    = $character[11][5]  = $character[11][6]  = $character[11][7]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][6]  = $character[12][7]  = $character[13][3]
	    = $character[13][4]  = $character[13][5]  = $character[13][6]
	    = $character[13][7]  = $character[14][2]  = $character[14][3]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][7]  = $character[14][8]  = $character[14][18]
	    = $character[14][19] = $character[14][20] = $character[14][21]
	    = $character[14][22] = $character[15][1]  = $character[15][2]
	    = $character[15][3]  = $character[15][4]  = $character[15][5]
	    = $character[15][6]  = $character[15][7]  = $character[15][8]
	    = $character[15][9]  = $character[15][10] = $character[15][11]
	    = $character[15][12] = $character[15][13] = $character[15][14]
	    = $character[15][15] = $character[15][16] = $character[15][17]
	    = $character[15][18] = $character[15][19] = $character[15][20]
	    = $character[15][21] = $character[15][22] = $character[16][1]
	    = $character[16][2]  = $character[16][3]  = $character[16][4]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[16][16]
	    = $character[16][17] = $character[16][18] = $character[16][19]
	    = $character[16][20] = $character[16][21] = $character[16][22] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[3][0]   = $character[3][10]
	    = $character[4][0]   = $character[4][10]  = $character[5][0]
	    = $character[5][1]   = $character[5][9]   = $character[5][10]
	    = $character[6][2]   = $character[6][8]   = $character[7][2]
	    = $character[7][8]   = $character[8][2]   = $character[8][8]
	    = $character[9][2]   = $character[9][8]   = $character[10][2]
	    = $character[10][8]  = $character[11][2]  = $character[11][8]
	    = $character[12][2]  = $character[12][8]  = $character[13][2]
	    = $character[13][8]  = $character[13][18] = $character[13][19]
	    = $character[13][20] = $character[13][21] = $character[13][22]
	    = $character[13][23] = $character[14][0]  = $character[14][1]
	    = $character[14][9]  = $character[14][10] = $character[14][11]
	    = $character[14][12] = $character[14][13] = $character[14][14]
	    = $character[14][15] = $character[14][16] = $character[14][17]
	    = $character[14][23] = $character[15][0]  = $character[15][23]
	    = $character[16][0]  = $character[16][23] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][14] = $character[17][15]
	    = $character[17][16] = $character[17][17] = $character[17][18]
	    = $character[17][19] = $character[17][20] = $character[17][21]
	    = $character[17][22] = $character[17][23] = 'L';
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(31);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][23]  = $character[3][24]  = $character[3][25]
	    = $character[3][26]  = $character[3][27]  = $character[3][28]
	    = $character[3][29]  = $character[4][1]   = $character[4][2]
	    = $character[4][3]   = $character[4][4]   = $character[4][5]
	    = $character[4][6]   = $character[4][7]   = $character[4][8]
	    = $character[4][22]  = $character[4][23]  = $character[4][24]
	    = $character[4][25]  = $character[4][26]  = $character[4][27]
	    = $character[4][28]  = $character[4][29]  = $character[5][1]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[5][7]
	    = $character[5][8]   = $character[5][9]   = $character[5][21]
	    = $character[5][22]  = $character[5][23]  = $character[5][24]
	    = $character[5][25]  = $character[5][26]  = $character[5][27]
	    = $character[5][28]  = $character[5][29]  = $character[6][1]
	    = $character[6][2]   = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][7]
	    = $character[6][8]   = $character[6][9]   = $character[6][10]
	    = $character[6][20]  = $character[6][21]  = $character[6][22]
	    = $character[6][23]  = $character[6][24]  = $character[6][25]
	    = $character[6][26]  = $character[6][27]  = $character[6][28]
	    = $character[6][29]  = $character[7][1]   = $character[7][2]
	    = $character[7][3]   = $character[7][4]   = $character[7][5]
	    = $character[7][6]   = $character[7][7]   = $character[7][8]
	    = $character[7][9]   = $character[7][10]  = $character[7][11]
	    = $character[7][19]  = $character[7][20]  = $character[7][21]
	    = $character[7][22]  = $character[7][23]  = $character[7][24]
	    = $character[7][25]  = $character[7][26]  = $character[7][27]
	    = $character[7][28]  = $character[7][29]  = $character[8][1]
	    = $character[8][2]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][18]  = $character[8][19]
	    = $character[8][20]  = $character[8][21]  = $character[8][23]
	    = $character[8][24]  = $character[8][25]  = $character[8][26]
	    = $character[8][27]  = $character[8][28]  = $character[8][29]
	    = $character[9][1]   = $character[9][2]   = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[9][6]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][17]  = $character[9][18]
	    = $character[9][19]  = $character[9][20]  = $character[9][24]
	    = $character[9][25]  = $character[9][26]  = $character[9][27]
	    = $character[9][28]  = $character[9][29]  = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][11]
	    = $character[10][12] = $character[10][13] = $character[10][14]
	    = $character[10][16] = $character[10][17] = $character[10][18]
	    = $character[10][19] = $character[10][24] = $character[10][25]
	    = $character[10][26] = $character[10][27] = $character[10][28]
	    = $character[10][29] = $character[11][1]  = $character[11][2]
	    = $character[11][3]  = $character[11][4]  = $character[11][5]
	    = $character[11][6]  = $character[11][12] = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[11][18] = $character[11][24]
	    = $character[11][25] = $character[11][26] = $character[11][27]
	    = $character[11][28] = $character[11][29] = $character[12][1]
	    = $character[12][2]  = $character[12][3]  = $character[12][4]
	    = $character[12][5]  = $character[12][6]  = $character[12][13]
	    = $character[12][14] = $character[12][15] = $character[12][16]
	    = $character[12][17] = $character[12][24] = $character[12][25]
	    = $character[12][26] = $character[12][27] = $character[12][28]
	    = $character[12][29] = $character[13][1]  = $character[13][2]
	    = $character[13][3]  = $character[13][4]  = $character[13][5]
	    = $character[13][6]  = $character[13][24] = $character[13][25]
	    = $character[13][26] = $character[13][27] = $character[13][28]
	    = $character[13][29] = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][24] = $character[14][25]
	    = $character[14][26] = $character[14][27] = $character[14][28]
	    = $character[14][29] = $character[15][1]  = $character[15][2]
	    = $character[15][3]  = $character[15][4]  = $character[15][5]
	    = $character[15][6]  = $character[15][24] = $character[15][25]
	    = $character[15][26] = $character[15][27] = $character[15][28]
	    = $character[15][29] = $character[16][1]  = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][24] = $character[16][25]
	    = $character[16][26] = $character[16][27] = $character[16][28]
	    = $character[16][29] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][23]  = $character[2][24]
	    = $character[2][25]  = $character[2][26]  = $character[2][27]
	    = $character[2][28]  = $character[2][29]  = $character[2][30]
	    = $character[3][0]   = $character[3][8]   = $character[3][22]
	    = $character[3][30]  = $character[4][0]   = $character[4][9]
	    = $character[4][21]  = $character[4][30]  = $character[5][0]
	    = $character[5][10]  = $character[5][20]  = $character[5][30]
	    = $character[6][0]   = $character[6][11]  = $character[6][19]
	    = $character[6][30]  = $character[7][0]   = $character[7][12]
	    = $character[7][18]  = $character[7][30]  = $character[8][0]
	    = $character[8][8]   = $character[8][13]  = $character[8][17]
	    = $character[8][22]  = $character[8][30]  = $character[9][0]
	    = $character[9][7]   = $character[9][9]   = $character[9][14]
	    = $character[9][16]  = $character[9][21]  = $character[9][23]
	    = $character[9][30]  = $character[10][0]  = $character[10][7]
	    = $character[10][10] = $character[10][15] = $character[10][20]
	    = $character[10][23] = $character[10][30] = $character[11][0]
	    = $character[11][7]  = $character[11][11] = $character[11][19]
	    = $character[11][23] = $character[11][30] = $character[12][0]
	    = $character[12][7]  = $character[12][12] = $character[12][18]
	    = $character[12][23] = $character[12][30] = $character[13][0]
	    = $character[13][7]  = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[13][23] = $character[13][30] = $character[14][0]
	    = $character[14][7]  = $character[14][23] = $character[14][30]
	    = $character[15][0]  = $character[15][7]  = $character[15][23]
	    = $character[15][30] = $character[16][0]  = $character[16][7]
	    = $character[16][23] = $character[16][30] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][23] = $character[17][24]
	    = $character[17][25] = $character[17][26] = $character[17][27]
	    = $character[17][28] = $character[17][29] = $character[17][30] = 'M';
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(24);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][16]  = $character[2][17]
	    = $character[2][18]  = $character[2][19]  = $character[2][20]
	    = $character[2][21]  = $character[2][22]  = $character[2][23]
	    = $character[3][0]   = $character[3][8]   = $character[3][16]
	    = $character[3][23]  = $character[4][0]   = $character[4][9]
	    = $character[4][16]  = $character[4][23]  = $character[5][0]
	    = $character[5][10]  = $character[5][16]  = $character[5][23]
	    = $character[6][0]   = $character[6][11]  = $character[6][16]
	    = $character[6][23]  = $character[7][0]   = $character[7][12]
	    = $character[7][16]  = $character[7][23]  = $character[8][0]
	    = $character[8][8]   = $character[8][13]  = $character[8][16]
	    = $character[8][23]  = $character[9][0]   = $character[9][7]
	    = $character[9][9]   = $character[9][14]  = $character[9][16]
	    = $character[9][23]  = $character[10][0]  = $character[10][7]
	    = $character[10][10] = $character[10][15] = $character[10][23]
	    = $character[11][0]  = $character[11][7]  = $character[11][11]
	    = $character[11][23] = $character[12][0]  = $character[12][7]
	    = $character[12][12] = $character[12][23] = $character[13][0]
	    = $character[13][7]  = $character[13][13] = $character[13][23]
	    = $character[14][0]  = $character[14][7]  = $character[14][14]
	    = $character[14][23] = $character[15][0]  = $character[15][7]
	    = $character[15][15] = $character[15][23] = $character[16][0]
	    = $character[16][7]  = $character[16][16] = $character[16][23]
	    = $character[17][0]  = $character[17][1]  = $character[17][2]
	    = $character[17][3]  = $character[17][4]  = $character[17][5]
	    = $character[17][6]  = $character[17][7]  = $character[17][17]
	    = $character[17][18] = $character[17][19] = $character[17][20]
	    = $character[17][21] = $character[17][22] = $character[17][23] = 'N';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][17]  = $character[3][18]  = $character[3][19]
	    = $character[3][20]  = $character[3][21]  = $character[3][22]
	    = $character[4][1]   = $character[4][2]   = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][6]
	    = $character[4][7]   = $character[4][8]   = $character[4][17]
	    = $character[4][18]  = $character[4][19]  = $character[4][20]
	    = $character[4][21]  = $character[4][22]  = $character[5][1]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[5][7]
	    = $character[5][8]   = $character[5][9]   = $character[5][17]
	    = $character[5][18]  = $character[5][19]  = $character[5][20]
	    = $character[5][21]  = $character[5][22]  = $character[6][1]
	    = $character[6][2]   = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][7]
	    = $character[6][8]   = $character[6][9]   = $character[6][10]
	    = $character[6][17]  = $character[6][18]  = $character[6][19]
	    = $character[6][20]  = $character[6][21]  = $character[6][22]
	    = $character[7][1]   = $character[7][2]   = $character[7][3]
	    = $character[7][4]   = $character[7][5]   = $character[7][6]
	    = $character[7][7]   = $character[7][8]   = $character[7][9]
	    = $character[7][10]  = $character[7][11]  = $character[7][17]
	    = $character[7][18]  = $character[7][19]  = $character[7][20]
	    = $character[7][21]  = $character[7][22]  = $character[8][1]
	    = $character[8][2]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][17]  = $character[8][18]
	    = $character[8][19]  = $character[8][20]  = $character[8][21]
	    = $character[8][22]  = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][10]  = $character[9][11]
	    = $character[9][12]  = $character[9][13]  = $character[9][17]
	    = $character[9][18]  = $character[9][19]  = $character[9][20]
	    = $character[9][21]  = $character[9][22]  = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][11]
	    = $character[10][12] = $character[10][13] = $character[10][14]
	    = $character[10][16] = $character[10][17] = $character[10][18]
	    = $character[10][19] = $character[10][20] = $character[10][21]
	    = $character[10][22] = $character[11][1]  = $character[11][2]
	    = $character[11][3]  = $character[11][4]  = $character[11][5]
	    = $character[11][6]  = $character[11][12] = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[11][18] = $character[11][19]
	    = $character[11][20] = $character[11][21] = $character[11][22]
	    = $character[12][1]  = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][6]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[12][18]
	    = $character[12][19] = $character[12][20] = $character[12][21]
	    = $character[12][22] = $character[13][1]  = $character[13][2]
	    = $character[13][3]  = $character[13][4]  = $character[13][5]
	    = $character[13][6]  = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[13][17] = $character[13][18]
	    = $character[13][19] = $character[13][20] = $character[13][21]
	    = $character[13][22] = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][15] = $character[14][16]
	    = $character[14][17] = $character[14][18] = $character[14][19]
	    = $character[14][20] = $character[14][21] = $character[14][22]
	    = $character[15][1]  = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][16] = $character[15][17] = $character[15][18]
	    = $character[15][19] = $character[15][20] = $character[15][21]
	    = $character[15][22] = $character[16][1]  = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][17] = $character[16][18]
	    = $character[16][19] = $character[16][20] = $character[16][21]
	    = $character[16][22] = ':';
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(19);
	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][8]
	    = $character[2][9]   = $character[2][10]  = $character[2][11]
	    = $character[2][12]  = $character[2][13]  = $character[3][3]
	    = $character[3][4]   = $character[3][14]  = $character[3][15]
	    = $character[4][1]   = $character[4][2]   = $character[4][16]
	    = $character[4][17]  = $character[5][0]   = $character[5][8]
	    = $character[5][9]   = $character[5][10]  = $character[5][18]
	    = $character[6][0]   = $character[6][7]   = $character[6][11]
	    = $character[6][18]  = $character[7][0]   = $character[7][6]
	    = $character[7][12]  = $character[7][18]  = $character[8][0]
	    = $character[8][6]   = $character[8][12]  = $character[8][18]
	    = $character[9][0]   = $character[9][6]   = $character[9][12]
	    = $character[9][18]  = $character[10][0]  = $character[10][6]
	    = $character[10][12] = $character[10][18] = $character[11][0]
	    = $character[11][6]  = $character[11][12] = $character[11][18]
	    = $character[12][0]  = $character[12][6]  = $character[12][12]
	    = $character[12][18] = $character[13][0]  = $character[13][7]
	    = $character[13][11] = $character[13][18] = $character[14][0]
	    = $character[14][8]  = $character[14][9]  = $character[14][10]
	    = $character[14][18] = $character[15][1]  = $character[15][2]
	    = $character[15][16] = $character[15][17] = $character[16][3]
	    = $character[16][4]  = $character[16][14] = $character[16][15]
	    = $character[17][5]  = $character[17][6]  = $character[17][7]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][12] = $character[17][13] = 'O';
	$character[3][5] = $character[3][6] = $character[3][7] = $character[3][8]
	    = $character[3][9]   = $character[3][10]  = $character[3][11]
	    = $character[3][12]  = $character[3][13]  = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][6]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[4][12]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[5][1]   = $character[5][2]   = $character[5][3]
	    = $character[5][4]   = $character[5][5]   = $character[5][6]
	    = $character[5][7]   = $character[5][11]  = $character[5][12]
	    = $character[5][13]  = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[6][1]
	    = $character[6][2]   = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][12]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[7][1]
	    = $character[7][2]   = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[7][13]  = $character[7][14]
	    = $character[7][15]  = $character[7][16]  = $character[7][17]
	    = $character[8][1]   = $character[8][2]   = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[10][17]
	    = $character[11][1]  = $character[11][2]  = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[12][1]  = $character[12][2]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][12]
	    = $character[13][13] = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[13][17] = $character[14][1]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][11] = $character[14][12] = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[14][16]
	    = $character[14][17] = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = $character[16][13] = ':';
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(20);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[3][0]   = $character[3][17]
	    = $character[4][0]   = $character[4][7]   = $character[4][8]
	    = $character[4][9]   = $character[4][10]  = $character[4][11]
	    = $character[4][12]  = $character[4][18]  = $character[5][0]
	    = $character[5][1]   = $character[5][7]   = $character[5][13]
	    = $character[5][19]  = $character[6][2]   = $character[6][7]
	    = $character[6][13]  = $character[6][19]  = $character[7][2]
	    = $character[7][7]   = $character[7][13]  = $character[7][19]
	    = $character[8][2]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][18]  = $character[9][2]
	    = $character[9][16]  = $character[9][17]  = $character[10][2]
	    = $character[10][7]  = $character[10][8]  = $character[10][9]
	    = $character[10][10] = $character[10][11] = $character[10][12]
	    = $character[10][13] = $character[10][14] = $character[10][15]
	    = $character[11][2]  = $character[11][7]  = $character[12][2]
	    = $character[12][7]  = $character[13][2]  = $character[13][7]
	    = $character[14][0]  = $character[14][1]  = $character[14][8]
	    = $character[14][9]  = $character[15][0]  = $character[15][9]
	    = $character[16][0]  = $character[16][9]  = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9] = 'P';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]  = $character[3][6]  = $character[3][7]
	    = $character[3][8]  = $character[3][9]  = $character[3][10]
	    = $character[3][11] = $character[3][12] = $character[3][13]
	    = $character[3][14] = $character[3][15] = $character[3][16]
	    = $character[4][1]  = $character[4][2]  = $character[4][3]
	    = $character[4][4]  = $character[4][5]  = $character[4][6]
	    = $character[4][13] = $character[4][14] = $character[4][15]
	    = $character[4][16] = $character[4][17] = $character[5][2]
	    = $character[5][3]  = $character[5][4]  = $character[5][5]
	    = $character[5][6]  = $character[5][14] = $character[5][15]
	    = $character[5][16] = $character[5][17] = $character[5][18]
	    = $character[6][3]  = $character[6][4]  = $character[6][5]
	    = $character[6][6]  = $character[6][14] = $character[6][15]
	    = $character[6][16] = $character[6][17] = $character[6][18]
	    = $character[7][3]  = $character[7][4]  = $character[7][5]
	    = $character[7][6]  = $character[7][14] = $character[7][15]
	    = $character[7][16] = $character[7][17] = $character[7][18]
	    = $character[8][3]  = $character[8][4]  = $character[8][5]
	    = $character[8][6]  = $character[8][13] = $character[8][14]
	    = $character[8][15] = $character[8][16] = $character[8][17]
	    = $character[9][3]  = $character[9][4]  = $character[9][5]
	    = $character[9][6]  = $character[9][7]  = $character[9][8]
	    = $character[9][9]  = $character[9][10] = $character[9][11]
	    = $character[9][12] = $character[9][13] = $character[9][14]
	    = $character[9][15] = $character[10][3] = $character[10][4]
	    = $character[10][5] = $character[10][6] = $character[11][3]
	    = $character[11][4] = $character[11][5] = $character[11][6]
	    = $character[12][3] = $character[12][4] = $character[12][5]
	    = $character[12][6] = $character[13][3] = $character[13][4]
	    = $character[13][5] = $character[13][6] = $character[14][2]
	    = $character[14][3] = $character[14][4] = $character[14][5]
	    = $character[14][6] = $character[14][7] = $character[15][1]
	    = $character[15][2] = $character[15][3] = $character[15][4]
	    = $character[15][5] = $character[15][6] = $character[15][7]
	    = $character[15][8] = $character[16][1] = $character[16][2]
	    = $character[16][3] = $character[16][4] = $character[16][5]
	    = $character[16][6] = $character[16][7] = $character[16][8] = ':';
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(20);
	$character[3][5] = $character[3][6] = $character[3][7] = $character[3][8]
	    = $character[3][9]   = $character[3][10]  = $character[3][11]
	    = $character[3][12]  = $character[3][13]  = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][6]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[4][12]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[5][1]   = $character[5][2]   = $character[5][3]
	    = $character[5][4]   = $character[5][5]   = $character[5][6]
	    = $character[5][7]   = $character[5][11]  = $character[5][12]
	    = $character[5][13]  = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[6][1]
	    = $character[6][2]   = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][12]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[7][1]
	    = $character[7][2]   = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[7][13]  = $character[7][14]
	    = $character[7][15]  = $character[7][16]  = $character[7][17]
	    = $character[8][1]   = $character[8][2]   = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[10][17]
	    = $character[11][1]  = $character[11][2]  = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[12][1]  = $character[12][2]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][10]
	    = $character[13][11] = $character[13][12] = $character[13][13]
	    = $character[13][14] = $character[13][15] = $character[13][16]
	    = $character[13][17] = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][7]  = $character[14][10]
	    = $character[14][11] = $character[14][12] = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[14][16]
	    = $character[14][17] = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16]
	    = $character[18][14] = $character[18][15] = $character[18][16]
	    = $character[18][17] = $character[18][18] = ':';
	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][8]
	    = $character[2][9]   = $character[2][10]  = $character[2][11]
	    = $character[2][12]  = $character[2][13]  = $character[3][3]
	    = $character[3][4]   = $character[3][14]  = $character[3][15]
	    = $character[4][1]   = $character[4][2]   = $character[4][16]
	    = $character[4][17]  = $character[5][0]   = $character[5][8]
	    = $character[5][9]   = $character[5][10]  = $character[5][18]
	    = $character[6][0]   = $character[6][11]  = $character[6][18]
	    = $character[7][0]   = $character[7][12]  = $character[7][18]
	    = $character[8][0]   = $character[8][12]  = $character[8][18]
	    = $character[9][0]   = $character[9][12]  = $character[9][18]
	    = $character[10][0]  = $character[10][12] = $character[10][18]
	    = $character[11][0]  = $character[11][12] = $character[11][18]
	    = $character[12][0]  = $character[12][9]  = $character[12][10]
	    = $character[12][11] = $character[12][12] = $character[12][18]
	    = $character[13][0]  = $character[13][9]  = $character[13][18]
	    = $character[14][0]  = $character[14][8]  = $character[14][9]
	    = $character[14][18] = $character[15][1]  = $character[15][2]
	    = $character[15][17] = $character[16][3]  = $character[16][4]
	    = $character[16][16] = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][17] = $character[17][18] = $character[18][13]
	    = $character[18][19] = $character[19][14] = $character[19][15]
	    = $character[19][16] = $character[19][17] = $character[19][18]
	    = $character[19][19] = 'Q';
	$character[6][7] = $character[7][6] = $character[8][6] = $character[9][6]
	    = $character[10][6] = $character[11][6] = $character[12][6]
	    = $character[13][7] = 'O';
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(20);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[3][0]   = $character[3][17]
	    = $character[4][0]   = $character[4][7]   = $character[4][8]
	    = $character[4][9]   = $character[4][10]  = $character[4][11]
	    = $character[4][12]  = $character[4][18]  = $character[5][0]
	    = $character[5][1]   = $character[5][7]   = $character[5][13]
	    = $character[5][19]  = $character[6][2]   = $character[6][7]
	    = $character[6][13]  = $character[6][19]  = $character[7][2]
	    = $character[7][7]   = $character[7][13]  = $character[7][19]
	    = $character[8][2]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][18]  = $character[9][2]
	    = $character[9][16]  = $character[9][17]  = $character[10][2]
	    = $character[10][7]  = $character[10][8]  = $character[10][9]
	    = $character[10][10] = $character[10][11] = $character[10][12]
	    = $character[10][18] = $character[11][2]  = $character[11][7]
	    = $character[11][13] = $character[11][19] = $character[12][2]
	    = $character[12][7]  = $character[12][13] = $character[12][19]
	    = $character[13][2]  = $character[13][7]  = $character[13][13]
	    = $character[13][19] = $character[14][0]  = $character[14][1]
	    = $character[14][7]  = $character[14][13] = $character[14][19]
	    = $character[15][0]  = $character[15][7]  = $character[15][13]
	    = $character[15][19] = $character[16][0]  = $character[16][7]
	    = $character[16][13] = $character[16][19] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][13] = $character[17][14]
	    = $character[17][15] = $character[17][16] = $character[17][17]
	    = $character[17][18] = $character[17][19] = 'R';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[4][1]   = $character[4][2]   = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][6]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[4][16]  = $character[4][17]  = $character[5][2]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[5][18]
	    = $character[6][3]   = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[7][3]   = $character[7][4]   = $character[7][5]
	    = $character[7][6]   = $character[7][14]  = $character[7][15]
	    = $character[7][16]  = $character[7][17]  = $character[7][18]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[8][16]  = $character[8][17]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][9]   = $character[9][10]  = $character[9][11]
	    = $character[9][12]  = $character[9][13]  = $character[9][14]
	    = $character[9][15]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][13]
	    = $character[10][14] = $character[10][15] = $character[10][16]
	    = $character[10][17] = $character[11][3]  = $character[11][4]
	    = $character[11][5]  = $character[11][6]  = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[12][3]  = $character[12][4]
	    = $character[12][5]  = $character[12][6]  = $character[12][14]
	    = $character[12][15] = $character[12][16] = $character[12][17]
	    = $character[12][18] = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[13][18] = $character[14][2]  = $character[14][3]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][14] = $character[14][15] = $character[14][16]
	    = $character[14][17] = $character[14][18] = $character[15][1]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][14]
	    = $character[15][15] = $character[15][16] = $character[15][17]
	    = $character[15][18] = $character[16][1]  = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][14] = $character[16][15]
	    = $character[16][16] = $character[16][17] = $character[16][18] = ':';
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(19);
	$character[2][3] = $character[2][4] = $character[2][5] = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[2][17]  = $character[3][1]
	    = $character[3][2]   = $character[3][18]  = $character[4][0]
	    = $character[4][6]   = $character[4][7]   = $character[4][8]
	    = $character[4][9]   = $character[4][10]  = $character[4][11]
	    = $character[4][18]  = $character[5][0]   = $character[5][6]
	    = $character[5][12]  = $character[5][13]  = $character[5][14]
	    = $character[5][15]  = $character[5][16]  = $character[5][17]
	    = $character[5][18]  = $character[6][0]   = $character[6][6]
	    = $character[7][0]   = $character[7][6]   = $character[8][1]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[9][2]   = $character[9][3]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][15]
	    = $character[10][16] = $character[11][7]  = $character[11][8]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[11][12] = $character[11][17] = $character[12][12]
	    = $character[12][18] = $character[13][12] = $character[13][18]
	    = $character[14][0]  = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][12] = $character[14][18]
	    = $character[15][0]  = $character[15][7]  = $character[15][8]
	    = $character[15][9]  = $character[15][10] = $character[15][11]
	    = $character[15][12] = $character[15][18] = $character[16][0]
	    = $character[16][16] = $character[16][17] = $character[17][1]
	    = $character[17][2]  = $character[17][3]  = $character[17][4]
	    = $character[17][5]  = $character[17][6]  = $character[17][7]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][15] = 'S';
	$character[3][3] = $character[3][4] = $character[3][5] = $character[3][6]
	    = $character[3][7]   = $character[3][8]   = $character[3][9]
	    = $character[3][10]  = $character[3][11]  = $character[3][12]
	    = $character[3][13]  = $character[3][14]  = $character[3][15]
	    = $character[3][16]  = $character[3][17]  = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][12]  = $character[4][13]
	    = $character[4][14]  = $character[4][15]  = $character[4][16]
	    = $character[4][17]  = $character[5][1]   = $character[5][2]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[6][1]   = $character[6][2]   = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[7][1]
	    = $character[7][2]   = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[8][2]   = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[9][4]
	    = $character[9][5]   = $character[9][6]   = $character[9][7]
	    = $character[9][8]   = $character[9][9]   = $character[10][7]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[10][12] = $character[10][13]
	    = $character[10][14] = $character[11][13] = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[12][13]
	    = $character[12][14] = $character[12][15] = $character[12][16]
	    = $character[12][17] = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][17] = $character[15][1]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[15][17] = $character[16][1]  = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = $character[16][13] = $character[16][14]
	    = $character[16][15] = ':';
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(23);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[2][17]  = $character[2][18]
	    = $character[2][19]  = $character[2][20]  = $character[2][21]
	    = $character[2][22]  = $character[3][0]   = $character[3][22]
	    = $character[4][0]   = $character[4][22]  = $character[5][0]
	    = $character[5][6]   = $character[5][7]   = $character[5][15]
	    = $character[5][16]  = $character[5][22]  = $character[6][0]
	    = $character[6][1]   = $character[6][2]   = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][8]
	    = $character[6][14]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[6][20]  = $character[6][21]
	    = $character[6][22]  = $character[7][8]   = $character[7][14]
	    = $character[8][8]   = $character[8][14]  = $character[9][8]
	    = $character[9][14]  = $character[10][8]  = $character[10][14]
	    = $character[11][8]  = $character[11][14] = $character[12][8]
	    = $character[12][14] = $character[13][8]  = $character[13][14]
	    = $character[14][6]  = $character[14][7]  = $character[14][15]
	    = $character[14][16] = $character[15][6]  = $character[15][16]
	    = $character[16][6]  = $character[16][16] = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][14] = $character[17][15]
	    = $character[17][16] = 'T';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[3][19]
	    = $character[3][20]  = $character[3][21]  = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[4][7]
	    = $character[4][8]   = $character[4][9]   = $character[4][10]
	    = $character[4][11]  = $character[4][12]  = $character[4][13]
	    = $character[4][14]  = $character[4][15]  = $character[4][16]
	    = $character[4][17]  = $character[4][18]  = $character[4][19]
	    = $character[4][20]  = $character[4][21]  = $character[5][1]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][8]   = $character[5][9]
	    = $character[5][10]  = $character[5][11]  = $character[5][12]
	    = $character[5][13]  = $character[5][14]  = $character[5][17]
	    = $character[5][18]  = $character[5][19]  = $character[5][20]
	    = $character[5][21]  = $character[6][9]   = $character[6][10]
	    = $character[6][11]  = $character[6][12]  = $character[6][13]
	    = $character[7][9]   = $character[7][10]  = $character[7][11]
	    = $character[7][12]  = $character[7][13]  = $character[8][9]
	    = $character[8][10]  = $character[8][11]  = $character[8][12]
	    = $character[8][13]  = $character[9][9]   = $character[9][10]
	    = $character[9][11]  = $character[9][12]  = $character[9][13]
	    = $character[10][9]  = $character[10][10] = $character[10][11]
	    = $character[10][12] = $character[10][13] = $character[11][9]
	    = $character[11][10] = $character[11][11] = $character[11][12]
	    = $character[11][13] = $character[12][9]  = $character[12][10]
	    = $character[12][11] = $character[12][12] = $character[12][13]
	    = $character[13][9]  = $character[13][10] = $character[13][11]
	    = $character[13][12] = $character[13][13] = $character[14][8]
	    = $character[14][9]  = $character[14][10] = $character[14][11]
	    = $character[14][12] = $character[14][13] = $character[14][14]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[16][7]  = $character[16][8]  = $character[16][9]
	    = $character[16][10] = $character[16][11] = $character[16][12]
	    = $character[16][13] = $character[16][14] = $character[16][15] = ':';
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(21);
	$character[7][7] = $character[7][13] = $character[8][7]
	    = $character[8][13]  = $character[9][7]   = $character[9][13]
	    = $character[10][7]  = $character[10][13] = $character[11][7]
	    = $character[11][13] = $character[12][7]  = $character[12][13] = 'D';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][14]
	    = $character[3][15]  = $character[3][16]  = $character[3][17]
	    = $character[3][18]  = $character[3][19]  = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[4][14]
	    = $character[4][15]  = $character[4][16]  = $character[4][17]
	    = $character[4][18]  = $character[4][19]  = $character[5][2]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[5][18]
	    = $character[6][2]   = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][14]
	    = $character[6][15]  = $character[6][16]  = $character[6][17]
	    = $character[6][18]  = $character[7][2]   = $character[7][3]
	    = $character[7][4]   = $character[7][5]   = $character[7][6]
	    = $character[7][14]  = $character[7][15]  = $character[7][16]
	    = $character[7][17]  = $character[7][18]  = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][14]  = $character[8][15]
	    = $character[8][16]  = $character[8][17]  = $character[8][18]
	    = $character[9][2]   = $character[9][3]   = $character[9][4]
	    = $character[9][5]   = $character[9][6]   = $character[9][14]
	    = $character[9][15]  = $character[9][16]  = $character[9][17]
	    = $character[9][18]  = $character[10][2]  = $character[10][3]
	    = $character[10][4]  = $character[10][5]  = $character[10][6]
	    = $character[10][14] = $character[10][15] = $character[10][16]
	    = $character[10][17] = $character[10][18] = $character[11][2]
	    = $character[11][3]  = $character[11][4]  = $character[11][5]
	    = $character[11][6]  = $character[11][14] = $character[11][15]
	    = $character[11][16] = $character[11][17] = $character[11][18]
	    = $character[12][2]  = $character[12][3]  = $character[12][4]
	    = $character[12][5]  = $character[12][6]  = $character[12][14]
	    = $character[12][15] = $character[12][16] = $character[12][17]
	    = $character[12][18] = $character[13][2]  = $character[13][3]
	    = $character[13][4]  = $character[13][5]  = $character[13][6]
	    = $character[13][7]  = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[13][18] = $character[14][2]  = $character[14][3]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][7]  = $character[14][8]  = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][17] = $character[14][18]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[15][16] = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][13]  = $character[2][14]
	    = $character[2][15]  = $character[2][16]  = $character[2][17]
	    = $character[2][18]  = $character[2][19]  = $character[2][20]
	    = $character[3][0]   = $character[3][7]   = $character[3][13]
	    = $character[3][20]  = $character[4][0]   = $character[4][7]
	    = $character[4][13]  = $character[4][20]  = $character[5][0]
	    = $character[5][1]   = $character[5][7]   = $character[5][13]
	    = $character[5][19]  = $character[5][20]  = $character[6][1]
	    = $character[6][7]   = $character[6][13]  = $character[6][19]
	    = $character[7][1]   = $character[7][19]  = $character[8][1]
	    = $character[8][19]  = $character[9][1]   = $character[9][19]
	    = $character[10][1]  = $character[10][19] = $character[11][1]
	    = $character[11][19] = $character[12][1]  = $character[12][19]
	    = $character[13][1]  = $character[13][8]  = $character[13][12]
	    = $character[13][19] = $character[14][1]  = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][19]
	    = $character[15][2]  = $character[15][3]  = $character[15][17]
	    = $character[15][18] = $character[16][4]  = $character[16][5]
	    = $character[16][15] = $character[16][16] = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][14] = 'U';
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(27);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][20]
	    = $character[3][21]  = $character[3][22]  = $character[3][23]
	    = $character[3][24]  = $character[3][25]  = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[4][20]
	    = $character[4][21]  = $character[4][22]  = $character[4][23]
	    = $character[4][24]  = $character[4][25]  = $character[5][1]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[5][20]
	    = $character[5][21]  = $character[5][22]  = $character[5][23]
	    = $character[5][24]  = $character[5][25]  = $character[6][2]
	    = $character[6][3]   = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[6][20]  = $character[6][21]
	    = $character[6][22]  = $character[6][23]  = $character[6][24]
	    = $character[7][3]   = $character[7][4]   = $character[7][5]
	    = $character[7][6]   = $character[7][7]   = $character[7][19]
	    = $character[7][20]  = $character[7][21]  = $character[7][22]
	    = $character[7][23]  = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][18]  = $character[8][19]  = $character[8][20]
	    = $character[8][21]  = $character[8][22]  = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][9]   = $character[9][17]  = $character[9][18]
	    = $character[9][19]  = $character[9][20]  = $character[9][21]
	    = $character[10][6]  = $character[10][7]  = $character[10][8]
	    = $character[10][9]  = $character[10][10] = $character[10][16]
	    = $character[10][17] = $character[10][18] = $character[10][19]
	    = $character[10][20] = $character[11][7]  = $character[11][8]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[11][19] = $character[12][8]
	    = $character[12][9]  = $character[12][10] = $character[12][11]
	    = $character[12][12] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[12][18]
	    = $character[13][9]  = $character[13][10] = $character[13][11]
	    = $character[13][12] = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[16][12] = $character[16][13] = $character[16][14] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][19]  = $character[2][20]
	    = $character[2][21]  = $character[2][22]  = $character[2][23]
	    = $character[2][24]  = $character[2][25]  = $character[2][26]
	    = $character[3][0]   = $character[3][7]   = $character[3][19]
	    = $character[3][26]  = $character[4][0]   = $character[4][7]
	    = $character[4][19]  = $character[4][26]  = $character[5][0]
	    = $character[5][7]   = $character[5][19]  = $character[5][26]
	    = $character[6][1]   = $character[6][7]   = $character[6][19]
	    = $character[6][25]  = $character[7][2]   = $character[7][8]
	    = $character[7][18]  = $character[7][24]  = $character[8][3]
	    = $character[8][9]   = $character[8][17]  = $character[8][23]
	    = $character[9][4]   = $character[9][10]  = $character[9][16]
	    = $character[9][22]  = $character[10][5]  = $character[10][11]
	    = $character[10][15] = $character[10][21] = $character[11][6]
	    = $character[11][12] = $character[11][14] = $character[11][20]
	    = $character[12][7]  = $character[12][13] = $character[12][19]
	    = $character[13][8]  = $character[13][18] = $character[14][9]
	    = $character[14][17] = $character[15][10] = $character[15][16]
	    = $character[16][11] = $character[16][15] = $character[17][12]
	    = $character[17][13] = $character[17][14] = 'V';
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(43);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][36]
	    = $character[3][37]  = $character[3][38]  = $character[3][39]
	    = $character[3][40]  = $character[3][41]  = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[4][36]
	    = $character[4][37]  = $character[4][38]  = $character[4][39]
	    = $character[4][40]  = $character[4][41]  = $character[5][1]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[5][36]
	    = $character[5][37]  = $character[5][38]  = $character[5][39]
	    = $character[5][40]  = $character[5][41]  = $character[6][2]
	    = $character[6][3]   = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[6][36]  = $character[6][37]
	    = $character[6][38]  = $character[6][39]  = $character[6][40]
	    = $character[7][3]   = $character[7][4]   = $character[7][5]
	    = $character[7][6]   = $character[7][7]   = $character[7][19]
	    = $character[7][20]  = $character[7][21]  = $character[7][22]
	    = $character[7][23]  = $character[7][35]  = $character[7][36]
	    = $character[7][37]  = $character[7][38]  = $character[7][39]
	    = $character[8][4]   = $character[8][5]   = $character[8][6]
	    = $character[8][7]   = $character[8][8]   = $character[8][18]
	    = $character[8][19]  = $character[8][20]  = $character[8][21]
	    = $character[8][22]  = $character[8][23]  = $character[8][24]
	    = $character[8][34]  = $character[8][35]  = $character[8][36]
	    = $character[8][37]  = $character[8][38]  = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][9]   = $character[9][17]  = $character[9][18]
	    = $character[9][19]  = $character[9][20]  = $character[9][21]
	    = $character[9][22]  = $character[9][23]  = $character[9][24]
	    = $character[9][25]  = $character[9][33]  = $character[9][34]
	    = $character[9][35]  = $character[9][36]  = $character[9][37]
	    = $character[10][6]  = $character[10][7]  = $character[10][8]
	    = $character[10][9]  = $character[10][10] = $character[10][16]
	    = $character[10][17] = $character[10][18] = $character[10][19]
	    = $character[10][20] = $character[10][22] = $character[10][23]
	    = $character[10][24] = $character[10][25] = $character[10][26]
	    = $character[10][32] = $character[10][33] = $character[10][34]
	    = $character[10][35] = $character[10][36] = $character[11][7]
	    = $character[11][8]  = $character[11][9]  = $character[11][10]
	    = $character[11][11] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[11][18] = $character[11][19]
	    = $character[11][23] = $character[11][24] = $character[11][25]
	    = $character[11][26] = $character[11][27] = $character[11][31]
	    = $character[11][32] = $character[11][33] = $character[11][34]
	    = $character[11][35] = $character[12][8]  = $character[12][9]
	    = $character[12][10] = $character[12][11] = $character[12][12]
	    = $character[12][14] = $character[12][15] = $character[12][16]
	    = $character[12][17] = $character[12][18] = $character[12][24]
	    = $character[12][25] = $character[12][26] = $character[12][27]
	    = $character[12][28] = $character[12][30] = $character[12][31]
	    = $character[12][32] = $character[12][33] = $character[12][34]
	    = $character[13][9]  = $character[13][10] = $character[13][11]
	    = $character[13][12] = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[13][25] = $character[13][26] = $character[13][27]
	    = $character[13][28] = $character[13][29] = $character[13][30]
	    = $character[13][31] = $character[13][32] = $character[13][33]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][26] = $character[14][27]
	    = $character[14][28] = $character[14][29] = $character[14][30]
	    = $character[14][31] = $character[14][32] = $character[15][11]
	    = $character[15][12] = $character[15][13] = $character[15][14]
	    = $character[15][15] = $character[15][27] = $character[15][28]
	    = $character[15][29] = $character[15][30] = $character[15][31]
	    = $character[16][12] = $character[16][13] = $character[16][14]
	    = $character[16][28] = $character[16][29] = $character[16][30] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][35]  = $character[2][36]
	    = $character[2][37]  = $character[2][38]  = $character[2][39]
	    = $character[2][40]  = $character[2][41]  = $character[2][42]
	    = $character[3][0]   = $character[3][7]   = $character[3][35]
	    = $character[3][42]  = $character[4][0]   = $character[4][7]
	    = $character[4][35]  = $character[4][42]  = $character[5][0]
	    = $character[5][7]   = $character[5][35]  = $character[5][42]
	    = $character[6][1]   = $character[6][7]   = $character[6][19]
	    = $character[6][20]  = $character[6][21]  = $character[6][22]
	    = $character[6][23]  = $character[6][35]  = $character[6][41]
	    = $character[7][2]   = $character[7][8]   = $character[7][18]
	    = $character[7][24]  = $character[7][34]  = $character[7][40]
	    = $character[8][3]   = $character[8][9]   = $character[8][17]
	    = $character[8][25]  = $character[8][33]  = $character[8][39]
	    = $character[9][4]   = $character[9][10]  = $character[9][16]
	    = $character[9][26]  = $character[9][32]  = $character[9][38]
	    = $character[10][5]  = $character[10][11] = $character[10][15]
	    = $character[10][21] = $character[10][27] = $character[10][31]
	    = $character[10][37] = $character[11][6]  = $character[11][12]
	    = $character[11][14] = $character[11][20] = $character[11][22]
	    = $character[11][28] = $character[11][30] = $character[11][36]
	    = $character[12][7]  = $character[12][13] = $character[12][19]
	    = $character[12][23] = $character[12][29] = $character[12][35]
	    = $character[13][8]  = $character[13][18] = $character[13][24]
	    = $character[13][34] = $character[14][9]  = $character[14][17]
	    = $character[14][25] = $character[14][33] = $character[15][10]
	    = $character[15][16] = $character[15][26] = $character[15][32]
	    = $character[16][11] = $character[16][15] = $character[16][27]
	    = $character[16][31] = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][28] = $character[17][29]
	    = $character[17][30] = 'W';
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(21);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[3][19]
	    = $character[4][1]   = $character[4][2]   = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][15]
	    = $character[4][16]  = $character[4][17]  = $character[4][18]
	    = $character[4][19]  = $character[5][1]   = $character[5][2]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[5][18]
	    = $character[5][19]  = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][7]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[7][4]
	    = $character[7][5]   = $character[7][6]   = $character[7][7]
	    = $character[7][8]   = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[7][16]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[9][6]   = $character[9][7]
	    = $character[9][8]   = $character[9][9]   = $character[9][10]
	    = $character[9][11]  = $character[9][12]  = $character[9][13]
	    = $character[9][14]  = $character[10][6]  = $character[10][7]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[10][12] = $character[10][13]
	    = $character[10][14] = $character[11][5]  = $character[11][6]
	    = $character[11][7]  = $character[11][8]  = $character[11][9]
	    = $character[11][11] = $character[11][12] = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[12][4]
	    = $character[12][5]  = $character[12][6]  = $character[12][7]
	    = $character[12][8]  = $character[12][12] = $character[12][13]
	    = $character[12][14] = $character[12][15] = $character[12][16]
	    = $character[13][3]  = $character[13][4]  = $character[13][5]
	    = $character[13][6]  = $character[13][7]  = $character[13][13]
	    = $character[13][14] = $character[13][15] = $character[13][16]
	    = $character[13][17] = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][17] = $character[14][18]
	    = $character[14][19] = $character[15][1]  = $character[15][2]
	    = $character[15][3]  = $character[15][4]  = $character[15][5]
	    = $character[15][15] = $character[15][16] = $character[15][17]
	    = $character[15][18] = $character[15][19] = $character[16][1]
	    = $character[16][2]  = $character[16][3]  = $character[16][4]
	    = $character[16][5]  = $character[16][15] = $character[16][16]
	    = $character[16][17] = $character[16][18] = $character[16][19] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][14]  = $character[2][15]  = $character[2][16]
	    = $character[2][17]  = $character[2][18]  = $character[2][19]
	    = $character[2][20]  = $character[3][0]   = $character[3][6]
	    = $character[3][14]  = $character[3][20]  = $character[4][0]
	    = $character[4][6]   = $character[4][14]  = $character[4][20]
	    = $character[5][0]   = $character[5][7]   = $character[5][13]
	    = $character[5][20]  = $character[6][0]   = $character[6][1]
	    = $character[6][2]   = $character[6][8]   = $character[6][12]
	    = $character[6][18]  = $character[6][19]  = $character[6][20]
	    = $character[7][3]   = $character[7][9]   = $character[7][11]
	    = $character[7][17]  = $character[8][4]   = $character[8][10]
	    = $character[8][16]  = $character[9][5]   = $character[9][15]
	    = $character[10][5]  = $character[10][15] = $character[11][4]
	    = $character[11][10] = $character[11][16] = $character[12][3]
	    = $character[12][9]  = $character[12][11] = $character[12][17]
	    = $character[13][0]  = $character[13][1]  = $character[13][2]
	    = $character[13][8]  = $character[13][12] = $character[13][18]
	    = $character[13][19] = $character[13][20] = $character[14][0]
	    = $character[14][7]  = $character[14][13] = $character[14][20]
	    = $character[15][0]  = $character[15][6]  = $character[15][14]
	    = $character[15][20] = $character[16][0]  = $character[16][6]
	    = $character[16][14] = $character[16][20] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][14] = $character[17][15] = $character[17][16]
	    = $character[17][17] = $character[17][18] = $character[17][19]
	    = $character[17][20] = 'X';
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(21);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][14]  = $character[2][15]  = $character[2][16]
	    = $character[2][17]  = $character[2][18]  = $character[2][19]
	    = $character[2][20]  = $character[3][0]   = $character[3][6]
	    = $character[3][14]  = $character[3][20]  = $character[4][0]
	    = $character[4][6]   = $character[4][14]  = $character[4][20]
	    = $character[5][0]   = $character[5][7]   = $character[5][13]
	    = $character[5][20]  = $character[6][0]   = $character[6][1]
	    = $character[6][2]   = $character[6][8]   = $character[6][12]
	    = $character[6][18]  = $character[6][19]  = $character[6][20]
	    = $character[7][3]   = $character[7][9]   = $character[7][11]
	    = $character[7][17]  = $character[8][4]   = $character[8][10]
	    = $character[8][16]  = $character[9][5]   = $character[9][15]
	    = $character[10][6]  = $character[10][14] = $character[11][7]
	    = $character[11][13] = $character[12][7]  = $character[12][13]
	    = $character[13][7]  = $character[13][13] = $character[14][7]
	    = $character[14][13] = $character[15][4]  = $character[15][5]
	    = $character[15][6]  = $character[15][7]  = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[16][4]  = $character[16][16] = $character[17][4]
	    = $character[17][5]  = $character[17][6]  = $character[17][7]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16] = 'Y';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[3][19]
	    = $character[4][1]   = $character[4][2]   = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][15]
	    = $character[4][16]  = $character[4][17]  = $character[4][18]
	    = $character[4][19]  = $character[5][1]   = $character[5][2]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[5][18]
	    = $character[5][19]  = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][7]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[7][4]
	    = $character[7][5]   = $character[7][6]   = $character[7][7]
	    = $character[7][8]   = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[7][16]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[9][6]   = $character[9][7]
	    = $character[9][8]   = $character[9][9]   = $character[9][10]
	    = $character[9][11]  = $character[9][12]  = $character[9][13]
	    = $character[9][14]  = $character[10][7]  = $character[10][8]
	    = $character[10][9]  = $character[10][10] = $character[10][11]
	    = $character[10][12] = $character[10][13] = $character[11][8]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[11][12] = $character[12][8]  = $character[12][9]
	    = $character[12][10] = $character[12][11] = $character[12][12]
	    = $character[13][8]  = $character[13][9]  = $character[13][10]
	    = $character[13][11] = $character[13][12] = $character[14][8]
	    = $character[14][9]  = $character[14][10] = $character[14][11]
	    = $character[14][12] = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = ':';
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(19);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[2][17]  = $character[2][18]
	    = $character[3][0]   = $character[3][18]  = $character[4][0]
	    = $character[4][18]  = $character[5][0]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[5][7]
	    = $character[5][8]   = $character[5][9]   = $character[5][10]
	    = $character[5][11]  = $character[5][17]  = $character[6][0]
	    = $character[6][1]   = $character[6][2]   = $character[6][3]
	    = $character[6][4]   = $character[6][10]  = $character[6][16]
	    = $character[7][8]   = $character[7][14]  = $character[8][7]
	    = $character[8][13]  = $character[9][6]   = $character[9][12]
	    = $character[10][5]  = $character[10][11] = $character[11][4]
	    = $character[11][10] = $character[12][3]  = $character[12][9]
	    = $character[13][0]  = $character[13][1]  = $character[13][2]
	    = $character[13][8]  = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[13][17] = $character[13][18]
	    = $character[14][0]  = $character[14][7]  = $character[14][8]
	    = $character[14][9]  = $character[14][10] = $character[14][11]
	    = $character[14][12] = $character[14][13] = $character[14][14]
	    = $character[14][18] = $character[15][0]  = $character[15][18]
	    = $character[16][0]  = $character[16][18] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][14] = $character[17][15]
	    = $character[17][16] = $character[17][17] = $character[17][18] = 'Z';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[4][1]   = $character[4][2]
	    = $character[4][3]   = $character[4][4]   = $character[4][5]
	    = $character[4][6]   = $character[4][7]   = $character[4][8]
	    = $character[4][9]   = $character[4][10]  = $character[4][11]
	    = $character[4][12]  = $character[4][13]  = $character[4][14]
	    = $character[4][15]  = $character[4][16]  = $character[4][17]
	    = $character[5][1]   = $character[5][2]   = $character[5][3]
	    = $character[5][12]  = $character[5][13]  = $character[5][14]
	    = $character[5][15]  = $character[5][16]  = $character[6][11]
	    = $character[6][12]  = $character[6][13]  = $character[6][14]
	    = $character[6][15]  = $character[7][9]   = $character[7][10]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[8][8]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][12]  = $character[9][7]
	    = $character[9][8]   = $character[9][9]   = $character[9][10]
	    = $character[9][11]  = $character[10][6]  = $character[10][7]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[11][5]  = $character[11][6]  = $character[11][7]
	    = $character[11][8]  = $character[11][9]  = $character[12][4]
	    = $character[12][5]  = $character[12][6]  = $character[12][7]
	    = $character[12][8]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][7]
	    = $character[14][1]  = $character[14][2]  = $character[14][3]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][15] = $character[14][16] = $character[14][17]
	    = $character[15][1]  = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[15][16] = $character[15][17] = $character[16][1]
	    = $character[16][2]  = $character[16][3]  = $character[16][4]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[16][16]
	    = $character[16][17] = ':';
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(18);
	$character[6][2] = $character[6][3] = $character[6][4] = $character[6][5]
	    = $character[6][6]   = $character[6][7]   = $character[6][8]
	    = $character[6][9]   = $character[6][10]  = $character[6][11]
	    = $character[6][12]  = $character[6][13]  = $character[6][14]
	    = $character[7][2]   = $character[7][15]  = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][16]
	    = $character[9][11]  = $character[9][16]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][7]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][16] = $character[11][2]  = $character[11][3]
	    = $character[11][16] = $character[12][1]  = $character[12][6]
	    = $character[12][7]  = $character[12][8]  = $character[12][9]
	    = $character[12][16] = $character[13][0]  = $character[13][5]
	    = $character[13][10] = $character[13][16] = $character[14][0]
	    = $character[14][5]  = $character[14][10] = $character[14][16]
	    = $character[15][0]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][16]
	    = $character[16][1]  = $character[16][12] = $character[16][13]
	    = $character[16][17] = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][14]
	    = $character[17][15] = $character[17][16] = $character[17][17] = 'a';
	$character[7][3] = $character[7][4] = $character[7][5] = $character[7][6]
	    = $character[7][7]   = $character[7][8]   = $character[7][9]
	    = $character[7][10]  = $character[7][11]  = $character[7][12]
	    = $character[7][13]  = $character[7][14]  = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[9][12]  = $character[9][13]
	    = $character[9][14]  = $character[9][15]  = $character[10][11]
	    = $character[10][12] = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[11][4]  = $character[11][5]
	    = $character[11][6]  = $character[11][7]  = $character[11][8]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[11][12] = $character[11][13] = $character[11][14]
	    = $character[11][15] = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][10]
	    = $character[12][11] = $character[12][12] = $character[12][13]
	    = $character[12][14] = $character[12][15] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][11] = $character[13][12] = $character[13][13]
	    = $character[13][14] = $character[13][15] = $character[14][1]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][11] = $character[14][12] = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[15][1]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][10] = $character[15][11]
	    = $character[15][12] = $character[15][13] = $character[15][14]
	    = $character[15][15] = $character[16][2]  = $character[16][3]
	    = $character[16][4]  = $character[16][5]  = $character[16][6]
	    = $character[16][7]  = $character[16][8]  = $character[16][9]
	    = $character[16][10] = $character[16][11] = $character[16][14]
	    = $character[16][15] = $character[16][16] = ':';
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(20);
	$character[2][1] = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5]   = $character[2][6]   = $character[3][1]
	    = $character[3][2]   = $character[3][3]   = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[5][2]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[6][2]   = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][6]
	    = $character[7][2]   = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[7][6]   = $character[7][7]
	    = $character[7][8]   = $character[7][9]   = $character[7][10]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[8][16]  = $character[8][17]
	    = $character[9][2]   = $character[9][3]   = $character[9][4]
	    = $character[9][5]   = $character[9][6]   = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[9][18]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][13]
	    = $character[10][14] = $character[10][15] = $character[10][16]
	    = $character[10][17] = $character[10][18] = $character[11][2]
	    = $character[11][3]  = $character[11][4]  = $character[11][5]
	    = $character[11][6]  = $character[11][14] = $character[11][15]
	    = $character[11][16] = $character[11][17] = $character[11][18]
	    = $character[12][2]  = $character[12][3]  = $character[12][4]
	    = $character[12][5]  = $character[12][6]  = $character[12][14]
	    = $character[12][15] = $character[12][16] = $character[12][17]
	    = $character[12][18] = $character[13][2]  = $character[13][3]
	    = $character[13][4]  = $character[13][5]  = $character[13][6]
	    = $character[13][14] = $character[13][15] = $character[13][16]
	    = $character[13][17] = $character[13][18] = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][13] = $character[14][14]
	    = $character[14][15] = $character[14][16] = $character[14][17]
	    = $character[14][18] = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[15][16] = $character[15][17] = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = $character[16][13] = $character[16][14]
	    = $character[16][15] = $character[16][16] = ':';
	$character[1][0] = $character[1][1] = $character[1][2] = $character[1][3]
	    = $character[1][4]   = $character[1][5]   = $character[1][6]
	    = $character[1][7]   = $character[2][0]   = $character[2][7]
	    = $character[3][0]   = $character[3][7]   = $character[4][0]
	    = $character[4][7]   = $character[5][1]   = $character[5][7]
	    = $character[6][1]   = $character[6][7]   = $character[6][8]
	    = $character[6][9]   = $character[6][10]  = $character[6][11]
	    = $character[6][12]  = $character[6][13]  = $character[6][14]
	    = $character[6][15]  = $character[7][1]   = $character[7][16]
	    = $character[7][17]  = $character[8][1]   = $character[8][18]
	    = $character[9][1]   = $character[9][7]   = $character[9][8]
	    = $character[9][9]   = $character[9][10]  = $character[9][11]
	    = $character[9][19]  = $character[10][1]  = $character[10][7]
	    = $character[10][12] = $character[10][19] = $character[11][1]
	    = $character[11][7]  = $character[11][13] = $character[11][19]
	    = $character[12][1]  = $character[12][7]  = $character[12][13]
	    = $character[12][19] = $character[13][1]  = $character[13][7]
	    = $character[13][13] = $character[13][19] = $character[14][1]
	    = $character[14][7]  = $character[14][8]  = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][19] = $character[15][1]  = $character[15][18]
	    = $character[16][1]  = $character[16][17] = $character[17][1]
	    = $character[17][2]  = $character[17][3]  = $character[17][4]
	    = $character[17][5]  = $character[17][6]  = $character[17][7]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16] = 'b';
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(20);
	$character[6][4] = $character[6][5] = $character[6][6] = $character[6][7]
	    = $character[6][8]   = $character[6][9]   = $character[6][10]
	    = $character[6][11]  = $character[6][12]  = $character[6][13]
	    = $character[6][14]  = $character[6][15]  = $character[6][16]
	    = $character[6][17]  = $character[6][18]  = $character[6][19]
	    = $character[7][2]   = $character[7][3]   = $character[7][19]
	    = $character[8][1]   = $character[8][19]  = $character[9][0]
	    = $character[9][8]   = $character[9][9]   = $character[9][10]
	    = $character[9][11]  = $character[9][12]  = $character[9][13]
	    = $character[9][19]  = $character[10][0]  = $character[10][7]
	    = $character[10][13] = $character[10][14] = $character[10][15]
	    = $character[10][16] = $character[10][17] = $character[10][18]
	    = $character[10][19] = $character[11][0]  = $character[11][6]
	    = $character[12][0]  = $character[12][6]  = $character[13][0]
	    = $character[13][7]  = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[13][18] = $character[13][19] = $character[14][0]
	    = $character[14][8]  = $character[14][9]  = $character[14][10]
	    = $character[14][11] = $character[14][12] = $character[14][13]
	    = $character[14][19] = $character[15][1]  = $character[15][19]
	    = $character[16][2]  = $character[16][3]  = $character[16][19]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][14] = $character[17][15]
	    = $character[17][16] = $character[17][17] = $character[17][18]
	    = $character[17][19] = 'c';
	$character[7][4] = $character[7][5] = $character[7][6] = $character[7][7]
	    = $character[7][8]   = $character[7][9]   = $character[7][10]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[7][16]
	    = $character[7][17]  = $character[7][18]  = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[8][16]  = $character[8][17]
	    = $character[8][18]  = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][14]
	    = $character[9][15]  = $character[9][16]  = $character[9][17]
	    = $character[9][18]  = $character[10][1]  = $character[10][2]
	    = $character[10][3]  = $character[10][4]  = $character[10][5]
	    = $character[10][6]  = $character[11][1]  = $character[11][2]
	    = $character[11][3]  = $character[11][4]  = $character[11][5]
	    = $character[12][1]  = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[14][1]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][14] = $character[14][15] = $character[14][16]
	    = $character[14][17] = $character[14][18] = $character[15][2]
	    = $character[15][3]  = $character[15][4]  = $character[15][5]
	    = $character[15][6]  = $character[15][7]  = $character[15][8]
	    = $character[15][9]  = $character[15][10] = $character[15][11]
	    = $character[15][12] = $character[15][13] = $character[15][14]
	    = $character[15][15] = $character[15][16] = $character[15][17]
	    = $character[15][18] = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = $character[16][13] = $character[16][14]
	    = $character[16][15] = $character[16][16] = $character[16][17]
	    = $character[16][18] = ':';
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(20);
	$character[2][13] = $character[2][14] = $character[2][15]
	    = $character[2][16]  = $character[2][17]  = $character[2][18]
	    = $character[3][13]  = $character[3][14]  = $character[3][15]
	    = $character[3][16]  = $character[3][17]  = $character[3][18]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[4][16]  = $character[4][17]  = $character[4][18]
	    = $character[5][13]  = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[6][13]
	    = $character[6][14]  = $character[6][15]  = $character[6][16]
	    = $character[6][17]  = $character[7][4]   = $character[7][5]
	    = $character[7][6]   = $character[7][7]   = $character[7][8]
	    = $character[7][9]   = $character[7][10]  = $character[7][11]
	    = $character[7][12]  = $character[7][13]  = $character[7][14]
	    = $character[7][15]  = $character[7][16]  = $character[7][17]
	    = $character[8][2]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][12]  = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][13]
	    = $character[9][14]  = $character[9][15]  = $character[9][16]
	    = $character[9][17]  = $character[10][1]  = $character[10][2]
	    = $character[10][3]  = $character[10][4]  = $character[10][5]
	    = $character[10][6]  = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[10][17]
	    = $character[11][1]  = $character[11][2]  = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[12][1]  = $character[12][2]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[14][1]  = $character[14][2]  = $character[14][3]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][12] = $character[14][13] = $character[14][14]
	    = $character[14][15] = $character[14][16] = $character[14][17]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[15][17] = $character[15][18] = $character[16][3]
	    = $character[16][4]  = $character[16][5]  = $character[16][6]
	    = $character[16][7]  = $character[16][8]  = $character[16][9]
	    = $character[16][10] = $character[16][11] = $character[16][15]
	    = $character[16][16] = $character[16][17] = $character[16][18] = ':';
	$character[1][12] = $character[1][13] = $character[1][14]
	    = $character[1][15]  = $character[1][16]  = $character[1][17]
	    = $character[1][18]  = $character[1][19]  = $character[2][12]
	    = $character[2][19]  = $character[3][12]  = $character[3][19]
	    = $character[4][12]  = $character[4][19]  = $character[5][12]
	    = $character[5][18]  = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[6][7]   = $character[6][8]
	    = $character[6][9]   = $character[6][10]  = $character[6][11]
	    = $character[6][12]  = $character[6][18]  = $character[7][2]
	    = $character[7][3]   = $character[7][18]  = $character[8][1]
	    = $character[8][18]  = $character[9][0]   = $character[9][8]
	    = $character[9][9]   = $character[9][10]  = $character[9][11]
	    = $character[9][12]  = $character[9][18]  = $character[10][0]
	    = $character[10][7]  = $character[10][12] = $character[10][18]
	    = $character[11][0]  = $character[11][6]  = $character[11][12]
	    = $character[11][18] = $character[12][0]  = $character[12][6]
	    = $character[12][12] = $character[12][18] = $character[13][0]
	    = $character[13][6]  = $character[13][12] = $character[13][18]
	    = $character[14][0]  = $character[14][7]  = $character[14][8]
	    = $character[14][9]  = $character[14][10] = $character[14][11]
	    = $character[14][18] = $character[14][19] = $character[15][1]
	    = $character[15][19] = $character[16][2]  = $character[16][12]
	    = $character[16][13] = $character[16][14] = $character[16][19]
	    = $character[17][3]  = $character[17][4]  = $character[17][5]
	    = $character[17][6]  = $character[17][7]  = $character[17][8]
	    = $character[17][9]  = $character[17][10] = $character[17][11]
	    = $character[17][15] = $character[17][16] = $character[17][17]
	    = $character[17][18] = $character[17][19] = 'd';
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(20);
	$character[7][4] = $character[7][5] = $character[7][6] = $character[7][7]
	    = $character[7][8]   = $character[7][9]   = $character[7][10]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[9][18]
	    = $character[10][1]  = $character[10][2]  = $character[10][3]
	    = $character[10][4]  = $character[10][5]  = $character[10][6]
	    = $character[10][7]  = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[10][17]
	    = $character[10][18] = $character[11][1]  = $character[11][2]
	    = $character[11][3]  = $character[11][4]  = $character[11][5]
	    = $character[11][6]  = $character[11][7]  = $character[11][8]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[11][12] = $character[11][13] = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[12][1]  = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][6]
	    = $character[13][1]  = $character[13][2]  = $character[13][3]
	    = $character[13][4]  = $character[13][5]  = $character[13][6]
	    = $character[13][7]  = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][7]  = $character[14][8]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[16][4]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[16][16] = ':';
	$character[6][4] = $character[6][5] = $character[6][6] = $character[6][7]
	    = $character[6][8]   = $character[6][9]   = $character[6][10]
	    = $character[6][11]  = $character[6][12]  = $character[6][13]
	    = $character[6][14]  = $character[6][15]  = $character[7][2]
	    = $character[7][3]   = $character[7][16]  = $character[7][17]
	    = $character[8][1]   = $character[8][8]   = $character[8][9]
	    = $character[8][10]  = $character[8][11]  = $character[8][12]
	    = $character[8][18]  = $character[8][19]  = $character[9][0]
	    = $character[9][7]   = $character[9][13]  = $character[9][19]
	    = $character[10][0]  = $character[10][8]  = $character[10][9]
	    = $character[10][10] = $character[10][11] = $character[10][12]
	    = $character[10][19] = $character[11][0]  = $character[11][18]
	    = $character[12][0]  = $character[12][7]  = $character[12][8]
	    = $character[12][9]  = $character[12][10] = $character[12][11]
	    = $character[12][12] = $character[12][13] = $character[12][14]
	    = $character[12][15] = $character[12][16] = $character[12][17]
	    = $character[13][0]  = $character[13][8]  = $character[14][0]
	    = $character[14][9]  = $character[15][1]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[15][17] = $character[16][2]  = $character[16][3]
	    = $character[16][17] = $character[17][4]  = $character[17][5]
	    = $character[17][6]  = $character[17][7]  = $character[17][8]
	    = $character[17][9]  = $character[17][10] = $character[17][11]
	    = $character[17][12] = $character[17][13] = $character[17][14]
	    = $character[17][15] = $character[17][16] = $character[17][17] = 'e';
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(22);
	$character[3][4] = $character[3][5] = $character[3][6] = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[3][19]
	    = $character[4][3]   = $character[4][4]   = $character[4][5]
	    = $character[4][6]   = $character[4][7]   = $character[4][8]
	    = $character[4][9]   = $character[4][10]  = $character[4][11]
	    = $character[4][12]  = $character[4][13]  = $character[4][14]
	    = $character[4][15]  = $character[4][16]  = $character[4][17]
	    = $character[4][18]  = $character[4][19]  = $character[4][20]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[5][7]   = $character[5][8]
	    = $character[5][16]  = $character[5][17]  = $character[5][18]
	    = $character[5][19]  = $character[5][20]  = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][6]
	    = $character[6][7]   = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[7][6]   = $character[7][7]
	    = $character[8][2]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][8]   = $character[9][2]   = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[9][6]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[10][2]  = $character[10][3]
	    = $character[10][4]  = $character[10][5]  = $character[10][6]
	    = $character[10][7]  = $character[10][8]  = $character[10][9]
	    = $character[10][10] = $character[10][11] = $character[10][12]
	    = $character[10][13] = $character[11][2]  = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][6]
	    = $character[11][7]  = $character[11][8]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][6]
	    = $character[12][7]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][7]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][8]  = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8] = ':';
	$character[2][4] = $character[2][5] = $character[2][6] = $character[2][7]
	    = $character[2][8]   = $character[2][9]   = $character[2][10]
	    = $character[2][11]  = $character[2][12]  = $character[2][13]
	    = $character[2][14]  = $character[2][15]  = $character[2][16]
	    = $character[2][17]  = $character[2][18]  = $character[2][19]
	    = $character[3][3]   = $character[3][20]  = $character[4][2]
	    = $character[4][21]  = $character[5][2]   = $character[5][9]
	    = $character[5][10]  = $character[5][11]  = $character[5][12]
	    = $character[5][13]  = $character[5][14]  = $character[5][15]
	    = $character[5][21]  = $character[6][2]   = $character[6][8]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[6][20]  = $character[6][21]
	    = $character[7][2]   = $character[7][8]   = $character[8][1]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[9][1]   = $character[9][14]  = $character[10][1]
	    = $character[10][14] = $character[11][1]  = $character[11][9]
	    = $character[11][10] = $character[11][11] = $character[11][12]
	    = $character[11][13] = $character[11][14] = $character[12][2]
	    = $character[12][8]  = $character[13][2]  = $character[13][8]
	    = $character[14][1]  = $character[14][9]  = $character[15][1]
	    = $character[15][9]  = $character[16][1]  = $character[16][9]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9] = 'f';
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(20);
	$character[7][3] = $character[7][4] = $character[7][5] = $character[7][6]
	    = $character[7][7]   = $character[7][8]   = $character[7][9]
	    = $character[7][10]  = $character[7][11]  = $character[7][15]
	    = $character[7][16]  = $character[7][17]  = $character[7][18]
	    = $character[8][2]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][12]  = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[8][18]  = $character[9][1]
	    = $character[9][2]   = $character[9][3]   = $character[9][4]
	    = $character[9][5]   = $character[9][6]   = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[10][17]
	    = $character[11][1]  = $character[11][2]  = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[12][1]  = $character[12][2]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][13]
	    = $character[13][14] = $character[13][15] = $character[13][16]
	    = $character[13][17] = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][7]  = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[14][16]
	    = $character[14][17] = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[15][16] = $character[15][17] = $character[16][4]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[16][16]
	    = $character[16][17] = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16]
	    = $character[17][17] = $character[18][13] = $character[18][14]
	    = $character[18][15] = $character[18][16] = $character[18][17]
	    = $character[19][13] = $character[19][14] = $character[19][15]
	    = $character[19][16] = $character[19][17] = $character[20][1]
	    = $character[20][2]  = $character[20][3]  = $character[20][4]
	    = $character[20][5]  = $character[20][13] = $character[20][14]
	    = $character[20][15] = $character[20][16] = $character[20][17]
	    = $character[21][2]  = $character[21][3]  = $character[21][4]
	    = $character[21][5]  = $character[21][6]  = $character[21][7]
	    = $character[21][11] = $character[21][12] = $character[21][13]
	    = $character[21][14] = $character[21][15] = $character[21][16]
	    = $character[21][17] = $character[22][4]  = $character[22][5]
	    = $character[22][6]  = $character[22][7]  = $character[22][8]
	    = $character[22][9]  = $character[22][10] = $character[22][11]
	    = $character[22][12] = $character[22][13] = $character[22][14]
	    = $character[22][15] = $character[22][16] = $character[23][7]
	    = $character[23][8]  = $character[23][9]  = $character[23][10]
	    = $character[23][11] = $character[23][12] = ':';
	$character[6][3] = $character[6][4] = $character[6][5] = $character[6][6]
	    = $character[6][7]   = $character[6][8]   = $character[6][9]
	    = $character[6][10]  = $character[6][11]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[7][2]   = $character[7][12]
	    = $character[7][13]  = $character[7][14]  = $character[7][19]
	    = $character[8][1]   = $character[8][19]  = $character[9][0]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][18]
	    = $character[9][19]  = $character[10][0]  = $character[10][6]
	    = $character[10][12] = $character[10][18] = $character[11][0]
	    = $character[11][6]  = $character[11][12] = $character[11][18]
	    = $character[12][0]  = $character[12][6]  = $character[12][12]
	    = $character[12][18] = $character[13][0]  = $character[13][7]
	    = $character[13][12] = $character[13][18] = $character[14][0]
	    = $character[14][8]  = $character[14][9]  = $character[14][10]
	    = $character[14][11] = $character[14][12] = $character[14][18]
	    = $character[15][1]  = $character[15][18] = $character[16][2]
	    = $character[16][3]  = $character[16][18] = $character[17][4]
	    = $character[17][5]  = $character[17][6]  = $character[17][7]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][18] = $character[18][12]
	    = $character[18][18] = $character[19][0]  = $character[19][1]
	    = $character[19][2]  = $character[19][3]  = $character[19][4]
	    = $character[19][5]  = $character[19][12] = $character[19][18]
	    = $character[20][0]  = $character[20][6]  = $character[20][7]
	    = $character[20][11] = $character[20][12] = $character[20][18]
	    = $character[21][1]  = $character[21][8]  = $character[21][9]
	    = $character[21][10] = $character[21][18] = $character[22][2]
	    = $character[22][3]  = $character[22][17] = $character[23][4]
	    = $character[23][5]  = $character[23][6]  = $character[23][13]
	    = $character[23][14] = $character[23][15] = $character[24][7]
	    = $character[24][8]  = $character[24][9]  = $character[24][10]
	    = $character[24][11] = $character[24][12] = 'g';
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(20);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[3][0]   = $character[3][6]   = $character[4][0]
	    = $character[4][6]   = $character[5][0]   = $character[5][6]
	    = $character[6][1]   = $character[6][6]   = $character[6][8]
	    = $character[6][9]   = $character[6][10]  = $character[6][11]
	    = $character[6][12]  = $character[7][1]   = $character[7][6]
	    = $character[7][7]   = $character[7][13]  = $character[7][14]
	    = $character[7][15]  = $character[8][1]   = $character[8][16]
	    = $character[8][17]  = $character[9][1]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][18]
	    = $character[10][1]  = $character[10][8]  = $character[10][12]
	    = $character[10][19] = $character[11][1]  = $character[11][7]
	    = $character[11][13] = $character[11][19] = $character[12][1]
	    = $character[12][7]  = $character[12][13] = $character[12][19]
	    = $character[13][1]  = $character[13][7]  = $character[13][13]
	    = $character[13][19] = $character[14][1]  = $character[14][7]
	    = $character[14][13] = $character[14][19] = $character[15][1]
	    = $character[15][7]  = $character[15][13] = $character[15][19]
	    = $character[16][1]  = $character[16][7]  = $character[16][13]
	    = $character[16][19] = $character[17][1]  = $character[17][2]
	    = $character[17][3]  = $character[17][4]  = $character[17][5]
	    = $character[17][6]  = $character[17][7]  = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16]
	    = $character[17][17] = $character[17][18] = $character[17][19] = 'h';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[4][1]   = $character[4][2]
	    = $character[4][3]   = $character[4][4]   = $character[4][5]
	    = $character[5][1]   = $character[5][2]   = $character[5][3]
	    = $character[5][4]   = $character[5][5]   = $character[6][2]
	    = $character[6][3]   = $character[6][4]   = $character[6][5]
	    = $character[7][2]   = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[7][8]   = $character[7][9]
	    = $character[7][10]  = $character[7][11]  = $character[7][12]
	    = $character[8][2]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][12]  = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][12]  = $character[9][13]  = $character[9][14]
	    = $character[9][15]  = $character[9][16]  = $character[9][17]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][7]
	    = $character[10][13] = $character[10][14] = $character[10][15]
	    = $character[10][16] = $character[10][17] = $character[10][18]
	    = $character[11][2]  = $character[11][3]  = $character[11][4]
	    = $character[11][5]  = $character[11][6]  = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][6]
	    = $character[12][14] = $character[12][15] = $character[12][16]
	    = $character[12][17] = $character[12][18] = $character[13][2]
	    = $character[13][3]  = $character[13][4]  = $character[13][5]
	    = $character[13][6]  = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[13][17] = $character[13][18]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][14]
	    = $character[14][15] = $character[14][16] = $character[14][17]
	    = $character[14][18] = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[15][17] = $character[15][18] = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][14] = $character[16][15]
	    = $character[16][16] = $character[16][17] = $character[16][18] = ':';
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(8);
	$character[2][2] = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[3][1]  = $character[3][6]  = $character[4][2]
	    = $character[4][3]  = $character[4][4]  = $character[4][5]
	    = $character[6][0]  = $character[6][1]  = $character[6][2]
	    = $character[6][3]  = $character[6][4]  = $character[6][5]
	    = $character[6][6]  = $character[7][0]  = $character[7][6]
	    = $character[8][1]  = $character[8][6]  = $character[9][1]
	    = $character[9][6]  = $character[10][1] = $character[10][6]
	    = $character[11][1] = $character[11][6] = $character[12][1]
	    = $character[12][6] = $character[13][1] = $character[13][6]
	    = $character[14][0] = $character[14][7] = $character[15][0]
	    = $character[15][7] = $character[16][0] = $character[16][7]
	    = $character[17][0] = $character[17][1] = $character[17][2]
	    = $character[17][3] = $character[17][4] = $character[17][5]
	    = $character[17][6] = $character[17][7] = 'i';
	$character[3][2] = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[7][1]  = $character[7][2]  = $character[7][3]
	    = $character[7][4]  = $character[7][5]  = $character[8][2]
	    = $character[8][3]  = $character[8][4]  = $character[8][5]
	    = $character[9][2]  = $character[9][3]  = $character[9][4]
	    = $character[9][5]  = $character[10][2] = $character[10][3]
	    = $character[10][4] = $character[10][5] = $character[11][2]
	    = $character[11][3] = $character[11][4] = $character[11][5]
	    = $character[12][2] = $character[12][3] = $character[12][4]
	    = $character[12][5] = $character[13][2] = $character[13][3]
	    = $character[13][4] = $character[13][5] = $character[14][1]
	    = $character[14][2] = $character[14][3] = $character[14][4]
	    = $character[14][5] = $character[14][6] = $character[15][1]
	    = $character[15][2] = $character[15][3] = $character[15][4]
	    = $character[15][5] = $character[15][6] = $character[16][1]
	    = $character[16][2] = $character[16][3] = $character[16][4]
	    = $character[16][5] = $character[16][6] = ':';
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(18);
	$character[3][13] = $character[3][14] = $character[3][15]
	    = $character[3][16]  = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[7][16]
	    = $character[8][13]  = $character[8][14]  = $character[8][15]
	    = $character[8][16]  = $character[9][13]  = $character[9][14]
	    = $character[9][15]  = $character[9][16]  = $character[10][13]
	    = $character[10][14] = $character[10][15] = $character[10][16]
	    = $character[11][13] = $character[11][14] = $character[11][15]
	    = $character[11][16] = $character[12][13] = $character[12][14]
	    = $character[12][15] = $character[12][16] = $character[13][13]
	    = $character[13][14] = $character[13][15] = $character[13][16]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[15][13] = $character[15][14]
	    = $character[15][15] = $character[15][16] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[16][16]
	    = $character[17][13] = $character[17][14] = $character[17][15]
	    = $character[17][16] = $character[18][13] = $character[18][14]
	    = $character[18][15] = $character[18][16] = $character[19][13]
	    = $character[19][14] = $character[19][15] = $character[19][16]
	    = $character[20][2]  = $character[20][3]  = $character[20][4]
	    = $character[20][5]  = $character[20][12] = $character[20][13]
	    = $character[20][14] = $character[20][15] = $character[20][16]
	    = $character[21][2]  = $character[21][3]  = $character[21][4]
	    = $character[21][5]  = $character[21][6]  = $character[21][7]
	    = $character[21][11] = $character[21][12] = $character[21][13]
	    = $character[21][14] = $character[21][15] = $character[21][16]
	    = $character[22][4]  = $character[22][5]  = $character[22][6]
	    = $character[22][7]  = $character[22][8]  = $character[22][9]
	    = $character[22][10] = $character[22][11] = $character[22][12]
	    = $character[22][13] = $character[22][14] = $character[22][15]
	    = $character[23][7]  = $character[23][8]  = $character[23][9]
	    = $character[23][10] = $character[23][11] = $character[23][12] = ':';
	$character[2][13] = $character[2][14] = $character[2][15]
	    = $character[2][16]  = $character[3][12]  = $character[3][17]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[4][16]  = $character[6][11]  = $character[6][12]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[7][11]
	    = $character[7][17]  = $character[8][12]  = $character[8][17]
	    = $character[9][12]  = $character[9][17]  = $character[10][12]
	    = $character[10][17] = $character[11][12] = $character[11][17]
	    = $character[12][12] = $character[12][17] = $character[13][12]
	    = $character[13][17] = $character[14][12] = $character[14][17]
	    = $character[15][12] = $character[15][17] = $character[16][12]
	    = $character[16][17] = $character[17][12] = $character[17][17]
	    = $character[18][12] = $character[18][17] = $character[19][2]
	    = $character[19][3]  = $character[19][4]  = $character[19][5]
	    = $character[19][12] = $character[19][17] = $character[20][1]
	    = $character[20][6]  = $character[20][7]  = $character[20][11]
	    = $character[20][17] = $character[21][1]  = $character[21][8]
	    = $character[21][9]  = $character[21][10] = $character[21][17]
	    = $character[22][2]  = $character[22][3]  = $character[22][16]
	    = $character[23][4]  = $character[23][5]  = $character[23][6]
	    = $character[23][13] = $character[23][14] = $character[23][15]
	    = $character[24][7]  = $character[24][8]  = $character[24][9]
	    = $character[24][10] = $character[24][11] = $character[24][12] = 'j';
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(19);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[5][1]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[6][2]
	    = $character[6][3]   = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[7][2]   = $character[7][3]
	    = $character[7][4]   = $character[7][5]   = $character[7][6]
	    = $character[7][12]  = $character[7][13]  = $character[7][14]
	    = $character[7][15]  = $character[7][16]  = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][11]  = $character[8][12]
	    = $character[8][13]  = $character[8][14]  = $character[8][15]
	    = $character[9][2]   = $character[9][3]   = $character[9][4]
	    = $character[9][5]   = $character[9][6]   = $character[9][10]
	    = $character[9][11]  = $character[9][12]  = $character[9][13]
	    = $character[9][14]  = $character[10][2]  = $character[10][3]
	    = $character[10][4]  = $character[10][5]  = $character[10][6]
	    = $character[10][7]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[10][12] = $character[10][13]
	    = $character[11][2]  = $character[11][3]  = $character[11][4]
	    = $character[11][5]  = $character[11][6]  = $character[11][7]
	    = $character[11][8]  = $character[11][9]  = $character[11][10]
	    = $character[11][11] = $character[11][12] = $character[12][2]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][6]  = $character[12][7]  = $character[12][8]
	    = $character[12][9]  = $character[12][10] = $character[12][11]
	    = $character[12][12] = $character[13][2]  = $character[13][3]
	    = $character[13][4]  = $character[13][5]  = $character[13][6]
	    = $character[13][7]  = $character[13][9]  = $character[13][10]
	    = $character[13][11] = $character[13][12] = $character[13][13]
	    = $character[14][1]  = $character[14][2]  = $character[14][3]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[15][1]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][11]
	    = $character[15][12] = $character[15][13] = $character[15][14]
	    = $character[15][15] = $character[16][1]  = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[16][16] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[3][0]   = $character[3][7]
	    = $character[4][0]   = $character[4][7]   = $character[5][0]
	    = $character[5][7]   = $character[6][1]   = $character[6][7]
	    = $character[6][12]  = $character[6][13]  = $character[6][14]
	    = $character[6][15]  = $character[6][16]  = $character[6][17]
	    = $character[6][18]  = $character[7][1]   = $character[7][7]
	    = $character[7][11]  = $character[7][17]  = $character[8][1]
	    = $character[8][7]   = $character[8][10]  = $character[8][16]
	    = $character[9][1]   = $character[9][7]   = $character[9][9]
	    = $character[9][15]  = $character[10][1]  = $character[10][8]
	    = $character[10][14] = $character[11][1]  = $character[11][13]
	    = $character[12][1]  = $character[12][13] = $character[13][1]
	    = $character[13][8]  = $character[13][14] = $character[14][0]
	    = $character[14][7]  = $character[14][9]  = $character[14][15]
	    = $character[15][0]  = $character[15][7]  = $character[15][10]
	    = $character[15][16] = $character[16][0]  = $character[16][7]
	    = $character[16][11] = $character[16][17] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16]
	    = $character[17][17] = $character[17][18] = 'k';
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(8);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]  = $character[4][1]  = $character[4][2]
	    = $character[4][3]  = $character[4][4]  = $character[4][5]
	    = $character[5][1]  = $character[5][2]  = $character[5][3]
	    = $character[5][4]  = $character[5][5]  = $character[6][2]
	    = $character[6][3]  = $character[6][4]  = $character[6][5]
	    = $character[7][2]  = $character[7][3]  = $character[7][4]
	    = $character[7][5]  = $character[8][2]  = $character[8][3]
	    = $character[8][4]  = $character[8][5]  = $character[9][2]
	    = $character[9][3]  = $character[9][4]  = $character[9][5]
	    = $character[10][2] = $character[10][3] = $character[10][4]
	    = $character[10][5] = $character[11][2] = $character[11][3]
	    = $character[11][4] = $character[11][5] = $character[12][2]
	    = $character[12][3] = $character[12][4] = $character[12][5]
	    = $character[13][2] = $character[13][3] = $character[13][4]
	    = $character[13][5] = $character[14][1] = $character[14][2]
	    = $character[14][3] = $character[14][4] = $character[14][5]
	    = $character[14][6] = $character[15][1] = $character[15][2]
	    = $character[15][3] = $character[15][4] = $character[15][5]
	    = $character[15][6] = $character[16][1] = $character[16][2]
	    = $character[16][3] = $character[16][4] = $character[16][5]
	    = $character[16][6] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]  = $character[2][5]  = $character[2][6]
	    = $character[3][0]  = $character[3][6]  = $character[4][0]
	    = $character[4][6]  = $character[5][0]  = $character[5][6]
	    = $character[6][1]  = $character[6][6]  = $character[7][1]
	    = $character[7][6]  = $character[8][1]  = $character[8][6]
	    = $character[9][1]  = $character[9][6]  = $character[10][1]
	    = $character[10][6] = $character[11][1] = $character[11][6]
	    = $character[12][1] = $character[12][6] = $character[13][1]
	    = $character[13][6] = $character[14][0] = $character[14][7]
	    = $character[15][0] = $character[15][7] = $character[16][0]
	    = $character[16][7] = $character[17][0] = $character[17][1]
	    = $character[17][2] = $character[17][3] = $character[17][4]
	    = $character[17][5] = $character[17][6] = $character[17][7] = 'l';
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(24);
	$character[6][3] = $character[6][4] = $character[6][5] = $character[6][6]
	    = $character[6][7]   = $character[6][8]   = $character[6][9]
	    = $character[6][14]  = $character[6][15]  = $character[6][16]
	    = $character[6][17]  = $character[6][18]  = $character[6][19]
	    = $character[6][20]  = $character[7][1]   = $character[7][2]
	    = $character[7][10]  = $character[7][13]  = $character[7][21]
	    = $character[7][22]  = $character[8][0]   = $character[8][11]
	    = $character[8][12]  = $character[8][23]  = $character[9][0]
	    = $character[9][23]  = $character[10][0]  = $character[10][6]
	    = $character[10][7]  = $character[10][8]  = $character[10][15]
	    = $character[10][16] = $character[10][17] = $character[10][23]
	    = $character[11][0]  = $character[11][5]  = $character[11][9]
	    = $character[11][14] = $character[11][18] = $character[11][23]
	    = $character[12][0]  = $character[12][5]  = $character[12][9]
	    = $character[12][14] = $character[12][18] = $character[12][23]
	    = $character[13][0]  = $character[13][5]  = $character[13][9]
	    = $character[13][14] = $character[13][18] = $character[13][23]
	    = $character[14][0]  = $character[14][5]  = $character[14][9]
	    = $character[14][14] = $character[14][18] = $character[14][23]
	    = $character[15][0]  = $character[15][5]  = $character[15][9]
	    = $character[15][14] = $character[15][18] = $character[15][23]
	    = $character[16][0]  = $character[16][5]  = $character[16][9]
	    = $character[16][14] = $character[16][18] = $character[16][23]
	    = $character[17][0]  = $character[17][1]  = $character[17][2]
	    = $character[17][3]  = $character[17][4]  = $character[17][5]
	    = $character[17][9]  = $character[17][10] = $character[17][11]
	    = $character[17][12] = $character[17][13] = $character[17][14]
	    = $character[17][18] = $character[17][19] = $character[17][20]
	    = $character[17][21] = $character[17][22] = $character[17][23] = 'm';
	$character[7][3] = $character[7][4] = $character[7][5] = $character[7][6]
	    = $character[7][7]   = $character[7][8]   = $character[7][9]
	    = $character[7][14]  = $character[7][15]  = $character[7][16]
	    = $character[7][17]  = $character[7][18]  = $character[7][19]
	    = $character[7][20]  = $character[8][1]   = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[8][18]  = $character[8][19]
	    = $character[8][20]  = $character[8][21]  = $character[8][22]
	    = $character[9][1]   = $character[9][2]   = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[9][6]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[9][18]
	    = $character[9][19]  = $character[9][20]  = $character[9][21]
	    = $character[9][22]  = $character[10][1]  = $character[10][2]
	    = $character[10][3]  = $character[10][4]  = $character[10][5]
	    = $character[10][9]  = $character[10][10] = $character[10][11]
	    = $character[10][12] = $character[10][13] = $character[10][14]
	    = $character[10][18] = $character[10][19] = $character[10][20]
	    = $character[10][21] = $character[10][22] = $character[11][1]
	    = $character[11][2]  = $character[11][3]  = $character[11][4]
	    = $character[11][10] = $character[11][11] = $character[11][12]
	    = $character[11][13] = $character[11][19] = $character[11][20]
	    = $character[11][21] = $character[11][22] = $character[12][1]
	    = $character[12][2]  = $character[12][3]  = $character[12][4]
	    = $character[12][10] = $character[12][11] = $character[12][12]
	    = $character[12][13] = $character[12][19] = $character[12][20]
	    = $character[12][21] = $character[12][22] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][10] = $character[13][11] = $character[13][12]
	    = $character[13][13] = $character[13][19] = $character[13][20]
	    = $character[13][21] = $character[13][22] = $character[14][1]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][19] = $character[14][20]
	    = $character[14][21] = $character[14][22] = $character[15][1]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][19] = $character[15][20]
	    = $character[15][21] = $character[15][22] = $character[16][1]
	    = $character[16][2]  = $character[16][3]  = $character[16][4]
	    = $character[16][10] = $character[16][11] = $character[16][12]
	    = $character[16][13] = $character[16][19] = $character[16][20]
	    = $character[16][21] = $character[16][22] = ':';
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(18);
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3]
	    = $character[6][6]   = $character[6][7]   = $character[6][8]
	    = $character[6][9]   = $character[6][10]  = $character[6][11]
	    = $character[6][12]  = $character[6][13]  = $character[7][0]
	    = $character[7][4]   = $character[7][5]   = $character[7][14]
	    = $character[7][15]  = $character[8][0]   = $character[8][15]
	    = $character[8][16]  = $character[9][0]   = $character[9][1]
	    = $character[9][17]  = $character[10][2]  = $character[10][8]
	    = $character[10][9]  = $character[10][10] = $character[10][11]
	    = $character[10][17] = $character[11][2]  = $character[11][7]
	    = $character[11][12] = $character[11][17] = $character[12][2]
	    = $character[12][7]  = $character[12][12] = $character[12][17]
	    = $character[13][2]  = $character[13][7]  = $character[13][12]
	    = $character[13][17] = $character[14][2]  = $character[14][7]
	    = $character[14][12] = $character[14][17] = $character[15][2]
	    = $character[15][7]  = $character[15][12] = $character[15][17]
	    = $character[16][2]  = $character[16][7]  = $character[16][12]
	    = $character[16][17] = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16]
	    = $character[17][17] = 'n';
	$character[7][1] = $character[7][2] = $character[7][3] = $character[7][6]
	    = $character[7][7]   = $character[7][8]   = $character[7][9]
	    = $character[7][10]  = $character[7][11]  = $character[7][12]
	    = $character[7][13]  = $character[8][1]   = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[9][2]   = $character[9][3]   = $character[9][4]
	    = $character[9][5]   = $character[9][6]   = $character[9][7]
	    = $character[9][8]   = $character[9][9]   = $character[9][10]
	    = $character[9][11]  = $character[9][12]  = $character[9][13]
	    = $character[9][14]  = $character[9][15]  = $character[9][16]
	    = $character[10][3]  = $character[10][4]  = $character[10][5]
	    = $character[10][6]  = $character[10][7]  = $character[10][12]
	    = $character[10][13] = $character[10][14] = $character[10][15]
	    = $character[10][16] = $character[11][3]  = $character[11][4]
	    = $character[11][5]  = $character[11][6]  = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][6]  = $character[12][13] = $character[12][14]
	    = $character[12][15] = $character[12][16] = $character[13][3]
	    = $character[13][4]  = $character[13][5]  = $character[13][6]
	    = $character[13][13] = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[14][16]
	    = $character[15][3]  = $character[15][4]  = $character[15][5]
	    = $character[15][6]  = $character[15][13] = $character[15][14]
	    = $character[15][15] = $character[15][16] = $character[16][3]
	    = $character[16][4]  = $character[16][5]  = $character[16][6]
	    = $character[16][13] = $character[16][14] = $character[16][15]
	    = $character[16][16] = ':';
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(17);
	$character[7][3] = $character[7][4] = $character[7][5] = $character[7][6]
	    = $character[7][7]   = $character[7][8]   = $character[7][9]
	    = $character[7][10]  = $character[7][11]  = $character[7][12]
	    = $character[7][13]  = $character[8][1]   = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][11]  = $character[9][12]  = $character[9][13]
	    = $character[9][14]  = $character[9][15]  = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][12] = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[11][1]  = $character[11][2]
	    = $character[11][3]  = $character[11][4]  = $character[11][12]
	    = $character[11][13] = $character[11][14] = $character[11][15]
	    = $character[12][1]  = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][12] = $character[12][13]
	    = $character[12][14] = $character[12][15] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][12] = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][11] = $character[14][12] = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[15][1]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[16][3]
	    = $character[16][4]  = $character[16][5]  = $character[16][6]
	    = $character[16][7]  = $character[16][8]  = $character[16][9]
	    = $character[16][10] = $character[16][11] = $character[16][12]
	    = $character[16][13] = ':';
	$character[6][3] = $character[6][4] = $character[6][5] = $character[6][6]
	    = $character[6][7]   = $character[6][8]   = $character[6][9]
	    = $character[6][10]  = $character[6][11]  = $character[6][12]
	    = $character[6][13]  = $character[7][1]   = $character[7][2]
	    = $character[7][14]  = $character[7][15]  = $character[8][0]
	    = $character[8][16]  = $character[9][0]   = $character[9][6]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][16]  = $character[10][0]
	    = $character[10][5]  = $character[10][11] = $character[10][16]
	    = $character[11][0]  = $character[11][5]  = $character[11][11]
	    = $character[11][16] = $character[12][0]  = $character[12][5]
	    = $character[12][11] = $character[12][16] = $character[13][0]
	    = $character[13][5]  = $character[13][11] = $character[13][16]
	    = $character[14][0]  = $character[14][6]  = $character[14][7]
	    = $character[14][8]  = $character[14][9]  = $character[14][10]
	    = $character[14][16] = $character[15][0]  = $character[15][16]
	    = $character[16][1]  = $character[16][2]  = $character[16][14]
	    = $character[16][15] = $character[17][3]  = $character[17][4]
	    = $character[17][5]  = $character[17][6]  = $character[17][7]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][12] = $character[17][13] = 'o';
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(20);
	$character[7][1] = $character[7][2] = $character[7][3] = $character[7][4]
	    = $character[7][8]   = $character[7][9]   = $character[7][10]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[7][16]
	    = $character[8][1]   = $character[8][2]   = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[8][6]
	    = $character[8][7]   = $character[8][8]   = $character[8][9]
	    = $character[8][10]  = $character[8][11]  = $character[8][12]
	    = $character[8][13]  = $character[8][14]  = $character[8][15]
	    = $character[8][16]  = $character[8][17]  = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][13]
	    = $character[9][14]  = $character[9][15]  = $character[9][16]
	    = $character[9][17]  = $character[9][18]  = $character[10][2]
	    = $character[10][3]  = $character[10][4]  = $character[10][5]
	    = $character[10][6]  = $character[10][14] = $character[10][15]
	    = $character[10][16] = $character[10][17] = $character[10][18]
	    = $character[11][2]  = $character[11][3]  = $character[11][4]
	    = $character[11][5]  = $character[11][6]  = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][6]
	    = $character[12][14] = $character[12][15] = $character[12][16]
	    = $character[12][17] = $character[12][18] = $character[13][2]
	    = $character[13][3]  = $character[13][4]  = $character[13][5]
	    = $character[13][6]  = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][17]
	    = $character[13][18] = $character[14][2]  = $character[14][3]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][12] = $character[14][13] = $character[14][14]
	    = $character[14][15] = $character[14][16] = $character[14][17]
	    = $character[14][18] = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[15][16] = $character[15][17] = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = $character[16][13] = $character[16][14]
	    = $character[16][15] = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[18][2]  = $character[18][3]
	    = $character[18][4]  = $character[18][5]  = $character[18][6]
	    = $character[19][2]  = $character[19][3]  = $character[19][4]
	    = $character[19][5]  = $character[19][6]  = $character[20][1]
	    = $character[20][2]  = $character[20][3]  = $character[20][4]
	    = $character[20][5]  = $character[20][6]  = $character[20][7]
	    = $character[21][1]  = $character[21][2]  = $character[21][3]
	    = $character[21][4]  = $character[21][5]  = $character[21][6]
	    = $character[21][7]  = $character[22][1]  = $character[22][2]
	    = $character[22][3]  = $character[22][4]  = $character[22][5]
	    = $character[22][6]  = $character[22][7]  = ':';
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3]
	    = $character[6][4]   = $character[6][8]   = $character[6][9]
	    = $character[6][10]  = $character[6][11]  = $character[6][12]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[7][0]   = $character[7][5]
	    = $character[7][6]   = $character[7][7]   = $character[7][17]
	    = $character[8][0]   = $character[8][18]  = $character[9][0]
	    = $character[9][1]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][19]  = $character[10][1]  = $character[10][7]
	    = $character[10][13] = $character[10][19] = $character[11][1]
	    = $character[11][7]  = $character[11][13] = $character[11][19]
	    = $character[12][1]  = $character[12][7]  = $character[12][13]
	    = $character[12][19] = $character[13][1]  = $character[13][7]
	    = $character[13][12] = $character[13][19] = $character[14][1]
	    = $character[14][7]  = $character[14][8]  = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][19]
	    = $character[15][1]  = $character[15][18] = $character[16][1]
	    = $character[16][16] = $character[16][17] = $character[17][1]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[18][1]
	    = $character[18][7]  = $character[19][1]  = $character[19][7]
	    = $character[20][0]  = $character[20][8]  = $character[21][0]
	    = $character[21][8]  = $character[22][0]  = $character[22][8]
	    = $character[23][0]  = $character[23][1]  = $character[23][2]
	    = $character[23][3]  = $character[23][4]  = $character[23][5]
	    = $character[23][6]  = $character[23][7]  = $character[23][8] = 'p';
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(20);
	$character[7][3] = $character[7][4] = $character[7][5] = $character[7][6]
	    = $character[7][7]   = $character[7][8]   = $character[7][9]
	    = $character[7][10]  = $character[7][11]  = $character[7][15]
	    = $character[7][16]  = $character[7][17]  = $character[7][18]
	    = $character[8][2]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][12]  = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[8][18]  = $character[9][1]
	    = $character[9][2]   = $character[9][3]   = $character[9][4]
	    = $character[9][5]   = $character[9][6]   = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[10][17]
	    = $character[11][1]  = $character[11][2]  = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[12][1]  = $character[12][2]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][13]
	    = $character[13][14] = $character[13][15] = $character[13][16]
	    = $character[13][17] = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][7]  = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[14][16]
	    = $character[14][17] = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[15][16] = $character[15][17] = $character[16][4]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[16][16]
	    = $character[16][17] = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16]
	    = $character[17][17] = $character[18][13] = $character[18][14]
	    = $character[18][15] = $character[18][16] = $character[18][17]
	    = $character[19][13] = $character[19][14] = $character[19][15]
	    = $character[19][16] = $character[19][17] = $character[20][12]
	    = $character[20][13] = $character[20][14] = $character[20][15]
	    = $character[20][16] = $character[20][17] = $character[20][18]
	    = $character[21][12] = $character[21][13] = $character[21][14]
	    = $character[21][15] = $character[21][16] = $character[21][17]
	    = $character[21][18] = $character[22][12] = $character[22][13]
	    = $character[22][14] = $character[22][15] = $character[22][16]
	    = $character[22][17] = $character[22][18] = ':';
	$character[6][3] = $character[6][4] = $character[6][5] = $character[6][6]
	    = $character[6][7]   = $character[6][8]   = $character[6][9]
	    = $character[6][10]  = $character[6][11]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[7][2]   = $character[7][12]
	    = $character[7][13]  = $character[7][14]  = $character[7][19]
	    = $character[8][1]   = $character[8][19]  = $character[9][0]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][18]
	    = $character[9][19]  = $character[10][0]  = $character[10][6]
	    = $character[10][12] = $character[10][18] = $character[11][0]
	    = $character[11][6]  = $character[11][12] = $character[11][18]
	    = $character[12][0]  = $character[12][6]  = $character[12][12]
	    = $character[12][18] = $character[13][0]  = $character[13][7]
	    = $character[13][12] = $character[13][18] = $character[14][0]
	    = $character[14][8]  = $character[14][9]  = $character[14][10]
	    = $character[14][11] = $character[14][12] = $character[14][18]
	    = $character[15][1]  = $character[15][18] = $character[16][2]
	    = $character[16][3]  = $character[16][18] = $character[17][4]
	    = $character[17][5]  = $character[17][6]  = $character[17][7]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][18] = $character[18][12]
	    = $character[18][18] = $character[19][12] = $character[19][18]
	    = $character[20][11] = $character[20][19] = $character[21][11]
	    = $character[21][19] = $character[22][11] = $character[22][19]
	    = $character[23][11] = $character[23][12] = $character[23][13]
	    = $character[23][14] = $character[23][15] = $character[23][16]
	    = $character[23][17] = $character[23][18] = $character[23][19] = 'q';
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(20);
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3]
	    = $character[6][4]   = $character[6][8]   = $character[6][9]
	    = $character[6][10]  = $character[6][11]  = $character[6][12]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[7][0]   = $character[7][5]
	    = $character[7][6]   = $character[7][7]   = $character[7][17]
	    = $character[8][0]   = $character[8][18]  = $character[9][0]
	    = $character[9][1]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][19]  = $character[10][1]  = $character[10][7]
	    = $character[10][13] = $character[10][19] = $character[11][1]
	    = $character[11][7]  = $character[11][13] = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[11][19] = $character[12][1]
	    = $character[12][7]  = $character[13][1]  = $character[13][7]
	    = $character[14][1]  = $character[14][7]  = $character[15][1]
	    = $character[15][7]  = $character[16][1]  = $character[16][7]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = 'r';
	$character[7][1] = $character[7][2] = $character[7][3] = $character[7][4]
	    = $character[7][8]   = $character[7][9]   = $character[7][10]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[7][16]
	    = $character[8][1]   = $character[8][2]   = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[8][6]
	    = $character[8][7]   = $character[8][8]   = $character[8][9]
	    = $character[8][10]  = $character[8][11]  = $character[8][12]
	    = $character[8][13]  = $character[8][14]  = $character[8][15]
	    = $character[8][16]  = $character[8][17]  = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][13]
	    = $character[9][14]  = $character[9][15]  = $character[9][16]
	    = $character[9][17]  = $character[9][18]  = $character[10][2]
	    = $character[10][3]  = $character[10][4]  = $character[10][5]
	    = $character[10][6]  = $character[10][14] = $character[10][15]
	    = $character[10][16] = $character[10][17] = $character[10][18]
	    = $character[11][2]  = $character[11][3]  = $character[11][4]
	    = $character[11][5]  = $character[11][6]  = $character[12][2]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][6]  = $character[13][2]  = $character[13][3]
	    = $character[13][4]  = $character[13][5]  = $character[13][6]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[15][2]
	    = $character[15][3]  = $character[15][4]  = $character[15][5]
	    = $character[15][6]  = $character[16][2]  = $character[16][3]
	    = $character[16][4]  = $character[16][5]  = $character[16][6] = ':';
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(17);
	$character[6][4] = $character[6][5] = $character[6][6] = $character[6][7]
	    = $character[6][8]   = $character[6][9]   = $character[6][10]
	    = $character[6][11]  = $character[6][12]  = $character[6][13]
	    = $character[7][2]   = $character[7][3]   = $character[7][14]
	    = $character[8][0]   = $character[8][1]   = $character[8][15]
	    = $character[9][0]   = $character[9][7]   = $character[9][8]
	    = $character[9][9]   = $character[9][10]  = $character[9][16]
	    = $character[10][1]  = $character[10][7]  = $character[10][10]
	    = $character[10][11] = $character[10][12] = $character[10][13]
	    = $character[10][14] = $character[10][15] = $character[11][3]
	    = $character[11][10] = $character[12][6]  = $character[12][13]
	    = $character[13][0]  = $character[13][1]  = $character[13][2]
	    = $character[13][3]  = $character[13][4]  = $character[13][5]
	    = $character[13][9]  = $character[13][15] = $character[14][0]
	    = $character[14][6]  = $character[14][7]  = $character[14][8]
	    = $character[14][9]  = $character[14][16] = $character[15][0]
	    = $character[15][15] = $character[16][1]  = $character[16][13]
	    = $character[16][14] = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12] = 's';
	$character[7][4] = $character[7][5] = $character[7][6] = $character[7][7]
	    = $character[7][8]   = $character[7][9]   = $character[7][10]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[8][2]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][12]  = $character[8][13]
	    = $character[8][14]  = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[11][4]
	    = $character[11][5]  = $character[11][6]  = $character[11][7]
	    = $character[11][8]  = $character[11][9]  = $character[12][7]
	    = $character[12][8]  = $character[12][9]  = $character[12][10]
	    = $character[12][11] = $character[12][12] = $character[13][10]
	    = $character[13][11] = $character[13][12] = $character[13][13]
	    = $character[13][14] = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[15][1]  = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = ':';
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(23);
	$character[2][9] = $character[2][10] = $character[2][11]
	    = $character[2][12]  = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][12]  = $character[4][6]
	    = $character[4][12]  = $character[5][6]   = $character[5][12]
	    = $character[6][0]   = $character[6][1]   = $character[6][2]
	    = $character[6][3]   = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[6][12]  = $character[6][13]
	    = $character[6][14]  = $character[6][15]  = $character[6][16]
	    = $character[6][17]  = $character[6][18]  = $character[7][0]
	    = $character[7][18]  = $character[8][0]   = $character[8][18]
	    = $character[9][0]   = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[9][18]
	    = $character[10][6]  = $character[10][12] = $character[11][6]
	    = $character[11][12] = $character[12][6]  = $character[12][12]
	    = $character[13][6]  = $character[13][12] = $character[13][17]
	    = $character[13][18] = $character[13][19] = $character[13][20]
	    = $character[13][21] = $character[13][22] = $character[14][6]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][22] = $character[15][6]
	    = $character[15][7]  = $character[15][22] = $character[16][8]
	    = $character[16][9]  = $character[16][21] = $character[16][22]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][14] = $character[17][15]
	    = $character[17][16] = $character[17][17] = $character[17][18]
	    = $character[17][19] = $character[17][20] = 't';
	$character[3][9] = $character[3][10] = $character[3][11]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[5][7]
	    = $character[5][8]   = $character[5][9]   = $character[5][10]
	    = $character[5][11]  = $character[6][7]   = $character[6][8]
	    = $character[6][9]   = $character[6][10]  = $character[6][11]
	    = $character[7][1]   = $character[7][2]   = $character[7][3]
	    = $character[7][4]   = $character[7][5]   = $character[7][6]
	    = $character[7][7]   = $character[7][8]   = $character[7][9]
	    = $character[7][10]  = $character[7][11]  = $character[7][12]
	    = $character[7][13]  = $character[7][14]  = $character[7][15]
	    = $character[7][16]  = $character[7][17]  = $character[8][1]
	    = $character[8][2]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][12]  = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[9][6]   = $character[9][7]
	    = $character[9][8]   = $character[9][9]   = $character[9][10]
	    = $character[9][11]  = $character[9][12]  = $character[10][7]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[11][7]  = $character[11][8]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[12][7]  = $character[12][8]  = $character[12][9]
	    = $character[12][10] = $character[12][11] = $character[13][7]
	    = $character[13][8]  = $character[13][9]  = $character[13][10]
	    = $character[13][11] = $character[14][7]  = $character[14][8]
	    = $character[14][9]  = $character[14][10] = $character[14][11]
	    = $character[14][12] = $character[14][17] = $character[14][18]
	    = $character[14][19] = $character[14][20] = $character[14][21]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[15][17] = $character[15][18] = $character[15][19]
	    = $character[15][20] = $character[15][21] = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[16][16]
	    = $character[16][17] = $character[16][18] = $character[16][19]
	    = $character[16][20] = ':';
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(18);
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][10]
	    = $character[6][11]  = $character[6][12]  = $character[6][13]
	    = $character[6][14]  = $character[6][15]  = $character[7][0]
	    = $character[7][5]   = $character[7][10]  = $character[7][15]
	    = $character[8][0]   = $character[8][5]   = $character[8][10]
	    = $character[8][15]  = $character[9][0]   = $character[9][5]
	    = $character[9][10]  = $character[9][15]  = $character[10][0]
	    = $character[10][5]  = $character[10][10] = $character[10][15]
	    = $character[11][0]  = $character[11][5]  = $character[11][10]
	    = $character[11][15] = $character[12][0]  = $character[12][5]
	    = $character[12][10] = $character[12][15] = $character[13][0]
	    = $character[13][6]  = $character[13][7]  = $character[13][8]
	    = $character[13][9]  = $character[13][15] = $character[14][0]
	    = $character[14][16] = $character[14][17] = $character[15][1]
	    = $character[15][17] = $character[16][2]  = $character[16][3]
	    = $character[16][12] = $character[16][13] = $character[16][17]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][14]
	    = $character[17][15] = $character[17][16] = $character[17][17] = 'u';
	$character[7][1] = $character[7][2] = $character[7][3] = $character[7][4]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[8][1]   = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[9][1]   = $character[9][2]   = $character[9][3]
	    = $character[9][4]   = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][11] = $character[10][12] = $character[10][13]
	    = $character[10][14] = $character[11][1]  = $character[11][2]
	    = $character[11][3]  = $character[11][4]  = $character[11][11]
	    = $character[11][12] = $character[11][13] = $character[11][14]
	    = $character[12][1]  = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][11] = $character[12][12]
	    = $character[12][13] = $character[12][14] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][10] = $character[13][11]
	    = $character[13][12] = $character[13][13] = $character[13][14]
	    = $character[14][1]  = $character[14][2]  = $character[14][3]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][7]  = $character[14][8]  = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[15][2]  = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[16][4]  = $character[16][5]  = $character[16][6]
	    = $character[16][7]  = $character[16][8]  = $character[16][9]
	    = $character[16][10] = $character[16][11] = $character[16][14]
	    = $character[16][15] = $character[16][16] = ':';
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(25);
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][6]
	    = $character[6][18]  = $character[6][19]  = $character[6][20]
	    = $character[6][21]  = $character[6][22]  = $character[6][23]
	    = $character[6][24]  = $character[7][1]   = $character[7][7]
	    = $character[7][17]  = $character[7][23]  = $character[8][2]
	    = $character[8][8]   = $character[8][16]  = $character[8][22]
	    = $character[9][3]   = $character[9][9]   = $character[9][15]
	    = $character[9][21]  = $character[10][4]  = $character[10][10]
	    = $character[10][14] = $character[10][20] = $character[11][5]
	    = $character[11][11] = $character[11][13] = $character[11][19]
	    = $character[12][6]  = $character[12][12] = $character[12][18]
	    = $character[13][7]  = $character[13][17] = $character[14][8]
	    = $character[14][16] = $character[15][9]  = $character[15][15]
	    = $character[16][10] = $character[16][14] = $character[17][11]
	    = $character[17][12] = $character[17][13] = 'v';
	$character[7][2] = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6]   = $character[7][18]  = $character[7][19]
	    = $character[7][20]  = $character[7][21]  = $character[7][22]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][17]
	    = $character[8][18]  = $character[8][19]  = $character[8][20]
	    = $character[8][21]  = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][16]  = $character[9][17]  = $character[9][18]
	    = $character[9][19]  = $character[9][20]  = $character[10][5]
	    = $character[10][6]  = $character[10][7]  = $character[10][8]
	    = $character[10][9]  = $character[10][15] = $character[10][16]
	    = $character[10][17] = $character[10][18] = $character[10][19]
	    = $character[11][6]  = $character[11][7]  = $character[11][8]
	    = $character[11][9]  = $character[11][10] = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[12][7]  = $character[12][8]
	    = $character[12][9]  = $character[12][10] = $character[12][11]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[13][8]
	    = $character[13][9]  = $character[13][10] = $character[13][11]
	    = $character[13][12] = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[16][11]
	    = $character[16][12] = $character[16][13] = ':';
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(41);
	$character[7][2] = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6]   = $character[7][18]  = $character[7][19]
	    = $character[7][20]  = $character[7][21]  = $character[7][22]
	    = $character[7][34]  = $character[7][35]  = $character[7][36]
	    = $character[7][37]  = $character[7][38]  = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[8][6]
	    = $character[8][7]   = $character[8][17]  = $character[8][18]
	    = $character[8][19]  = $character[8][20]  = $character[8][21]
	    = $character[8][22]  = $character[8][23]  = $character[8][33]
	    = $character[8][34]  = $character[8][35]  = $character[8][36]
	    = $character[8][37]  = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][16]  = $character[9][17]  = $character[9][18]
	    = $character[9][19]  = $character[9][20]  = $character[9][21]
	    = $character[9][22]  = $character[9][23]  = $character[9][24]
	    = $character[9][32]  = $character[9][33]  = $character[9][34]
	    = $character[9][35]  = $character[9][36]  = $character[10][5]
	    = $character[10][6]  = $character[10][7]  = $character[10][8]
	    = $character[10][9]  = $character[10][15] = $character[10][16]
	    = $character[10][17] = $character[10][18] = $character[10][19]
	    = $character[10][21] = $character[10][22] = $character[10][23]
	    = $character[10][24] = $character[10][25] = $character[10][31]
	    = $character[10][32] = $character[10][33] = $character[10][34]
	    = $character[10][35] = $character[11][6]  = $character[11][7]
	    = $character[11][8]  = $character[11][9]  = $character[11][10]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[11][18] = $character[11][22]
	    = $character[11][23] = $character[11][24] = $character[11][25]
	    = $character[11][26] = $character[11][30] = $character[11][31]
	    = $character[11][32] = $character[11][33] = $character[11][34]
	    = $character[12][7]  = $character[12][8]  = $character[12][9]
	    = $character[12][10] = $character[12][11] = $character[12][13]
	    = $character[12][14] = $character[12][15] = $character[12][16]
	    = $character[12][17] = $character[12][23] = $character[12][24]
	    = $character[12][25] = $character[12][26] = $character[12][27]
	    = $character[12][29] = $character[12][30] = $character[12][31]
	    = $character[12][32] = $character[12][33] = $character[13][8]
	    = $character[13][9]  = $character[13][10] = $character[13][11]
	    = $character[13][12] = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[13][24]
	    = $character[13][25] = $character[13][26] = $character[13][27]
	    = $character[13][28] = $character[13][29] = $character[13][30]
	    = $character[13][31] = $character[13][32] = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][25] = $character[14][26] = $character[14][27]
	    = $character[14][28] = $character[14][29] = $character[14][30]
	    = $character[14][31] = $character[15][10] = $character[15][11]
	    = $character[15][12] = $character[15][13] = $character[15][14]
	    = $character[15][26] = $character[15][27] = $character[15][28]
	    = $character[15][29] = $character[15][30] = $character[16][11]
	    = $character[16][12] = $character[16][13] = $character[16][27]
	    = $character[16][28] = $character[16][29] = ':';
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][6]
	    = $character[6][18]  = $character[6][19]  = $character[6][20]
	    = $character[6][21]  = $character[6][22]  = $character[6][34]
	    = $character[6][35]  = $character[6][36]  = $character[6][37]
	    = $character[6][38]  = $character[6][39]  = $character[6][40]
	    = $character[7][1]   = $character[7][7]   = $character[7][17]
	    = $character[7][23]  = $character[7][33]  = $character[7][39]
	    = $character[8][2]   = $character[8][8]   = $character[8][16]
	    = $character[8][24]  = $character[8][32]  = $character[8][38]
	    = $character[9][3]   = $character[9][9]   = $character[9][15]
	    = $character[9][25]  = $character[9][31]  = $character[9][37]
	    = $character[10][4]  = $character[10][10] = $character[10][14]
	    = $character[10][20] = $character[10][26] = $character[10][30]
	    = $character[10][36] = $character[11][5]  = $character[11][11]
	    = $character[11][13] = $character[11][19] = $character[11][21]
	    = $character[11][27] = $character[11][29] = $character[11][35]
	    = $character[12][6]  = $character[12][12] = $character[12][18]
	    = $character[12][22] = $character[12][28] = $character[12][34]
	    = $character[13][7]  = $character[13][17] = $character[13][23]
	    = $character[13][33] = $character[14][8]  = $character[14][16]
	    = $character[14][24] = $character[14][32] = $character[15][9]
	    = $character[15][15] = $character[15][25] = $character[15][31]
	    = $character[16][10] = $character[16][14] = $character[16][26]
	    = $character[16][30] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][27] = $character[17][28]
	    = $character[17][29] = 'w';
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(20);
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][6]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[6][18]
	    = $character[6][19]  = $character[7][1]   = $character[7][7]
	    = $character[7][12]  = $character[7][18]  = $character[8][2]
	    = $character[8][8]   = $character[8][11]  = $character[8][17]
	    = $character[9][3]   = $character[9][9]   = $character[9][10]
	    = $character[9][16]  = $character[10][4]  = $character[10][15]
	    = $character[11][5]  = $character[11][14] = $character[12][5]
	    = $character[12][14] = $character[13][4]  = $character[13][15]
	    = $character[14][3]  = $character[14][9]  = $character[14][10]
	    = $character[14][16] = $character[15][2]  = $character[15][8]
	    = $character[15][11] = $character[15][17] = $character[16][1]
	    = $character[16][7]  = $character[16][12] = $character[16][18]
	    = $character[17][0]  = $character[17][1]  = $character[17][2]
	    = $character[17][3]  = $character[17][4]  = $character[17][5]
	    = $character[17][6]  = $character[17][13] = $character[17][14]
	    = $character[17][15] = $character[17][16] = $character[17][17]
	    = $character[17][18] = $character[17][19] = 'x';
	$character[7][2] = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6]   = $character[7][13]  = $character[7][14]
	    = $character[7][15]  = $character[7][16]  = $character[7][17]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][12]
	    = $character[8][13]  = $character[8][14]  = $character[8][15]
	    = $character[8][16]  = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][11]  = $character[9][12]  = $character[9][13]
	    = $character[9][14]  = $character[9][15]  = $character[10][5]
	    = $character[10][6]  = $character[10][7]  = $character[10][8]
	    = $character[10][9]  = $character[10][10] = $character[10][11]
	    = $character[10][12] = $character[10][13] = $character[10][14]
	    = $character[11][6]  = $character[11][7]  = $character[11][8]
	    = $character[11][9]  = $character[11][10] = $character[11][11]
	    = $character[11][12] = $character[11][13] = $character[12][6]
	    = $character[12][7]  = $character[12][8]  = $character[12][9]
	    = $character[12][10] = $character[12][11] = $character[12][12]
	    = $character[12][13] = $character[13][5]  = $character[13][6]
	    = $character[13][7]  = $character[13][8]  = $character[13][9]
	    = $character[13][10] = $character[13][11] = $character[13][12]
	    = $character[13][13] = $character[13][14] = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][8]  = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[15][3]  = $character[15][4]  = $character[15][5]
	    = $character[15][6]  = $character[15][7]  = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[15][16] = $character[16][2]  = $character[16][3]
	    = $character[16][4]  = $character[16][5]  = $character[16][6]
	    = $character[16][13] = $character[16][14] = $character[16][15]
	    = $character[16][16] = $character[16][17] = ':';
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(25);
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][6]
	    = $character[6][18]  = $character[6][19]  = $character[6][20]
	    = $character[6][21]  = $character[6][22]  = $character[6][23]
	    = $character[6][24]  = $character[7][1]   = $character[7][7]
	    = $character[7][17]  = $character[7][23]  = $character[8][2]
	    = $character[8][8]   = $character[8][16]  = $character[8][22]
	    = $character[9][3]   = $character[9][9]   = $character[9][15]
	    = $character[9][21]  = $character[10][4]  = $character[10][10]
	    = $character[10][14] = $character[10][20] = $character[11][5]
	    = $character[11][11] = $character[11][13] = $character[11][19]
	    = $character[12][6]  = $character[12][12] = $character[12][18]
	    = $character[13][7]  = $character[13][17] = $character[14][8]
	    = $character[14][16] = $character[15][9]  = $character[15][15]
	    = $character[16][8]  = $character[16][14] = $character[17][7]
	    = $character[17][13] = $character[18][6]  = $character[18][12]
	    = $character[19][5]  = $character[19][11] = $character[20][4]
	    = $character[20][10] = $character[21][3]  = $character[21][9]
	    = $character[22][2]  = $character[22][3]  = $character[22][4]
	    = $character[22][5]  = $character[22][6]  = $character[22][7]
	    = $character[22][8]  = 'y';
	$character[7][2] = $character[7][3] = $character[7][4] = $character[7][5]
	    = $character[7][6]   = $character[7][18]  = $character[7][19]
	    = $character[7][20]  = $character[7][21]  = $character[7][22]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][17]
	    = $character[8][18]  = $character[8][19]  = $character[8][20]
	    = $character[8][21]  = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][16]  = $character[9][17]  = $character[9][18]
	    = $character[9][19]  = $character[9][20]  = $character[10][5]
	    = $character[10][6]  = $character[10][7]  = $character[10][8]
	    = $character[10][9]  = $character[10][15] = $character[10][16]
	    = $character[10][17] = $character[10][18] = $character[10][19]
	    = $character[11][6]  = $character[11][7]  = $character[11][8]
	    = $character[11][9]  = $character[11][10] = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[11][18] = $character[12][7]  = $character[12][8]
	    = $character[12][9]  = $character[12][10] = $character[12][11]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[13][8]
	    = $character[13][9]  = $character[13][10] = $character[13][11]
	    = $character[13][12] = $character[13][13] = $character[13][14]
	    = $character[13][15] = $character[13][16] = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[16][9]
	    = $character[16][10] = $character[16][11] = $character[16][12]
	    = $character[16][13] = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[18][7]  = $character[18][8]  = $character[18][9]
	    = $character[18][10] = $character[18][11] = $character[19][6]
	    = $character[19][7]  = $character[19][8]  = $character[19][9]
	    = $character[19][10] = $character[20][5]  = $character[20][6]
	    = $character[20][7]  = $character[20][8]  = $character[20][9]
	    = $character[21][4]  = $character[21][5]  = $character[21][6]
	    = $character[21][7]  = $character[21][8]  = ':';
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(17);
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][6]
	    = $character[6][7]   = $character[6][8]   = $character[6][9]
	    = $character[6][10]  = $character[6][11]  = $character[6][12]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[7][0]   = $character[7][16]
	    = $character[8][0]   = $character[8][15]  = $character[9][0]
	    = $character[9][1]   = $character[9][2]   = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[9][6]
	    = $character[9][7]   = $character[9][14]  = $character[10][6]
	    = $character[10][13] = $character[11][5]  = $character[11][12]
	    = $character[12][4]  = $character[12][11] = $character[13][3]
	    = $character[13][10] = $character[14][2]  = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[15][1]  = $character[15][16]
	    = $character[16][0]  = $character[16][16] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = $character[17][12]
	    = $character[17][13] = $character[17][14] = $character[17][15]
	    = $character[17][16] = 'z';
	$character[7][1] = $character[7][2] = $character[7][3] = $character[7][4]
	    = $character[7][5]   = $character[7][6]   = $character[7][7]
	    = $character[7][8]   = $character[7][9]   = $character[7][10]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[8][1]
	    = $character[8][2]   = $character[8][3]   = $character[8][4]
	    = $character[8][5]   = $character[8][6]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][12]  = $character[8][13]
	    = $character[8][14]  = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[10][7]  = $character[10][8]
	    = $character[10][9]  = $character[10][10] = $character[10][11]
	    = $character[10][12] = $character[11][6]  = $character[11][7]
	    = $character[11][8]  = $character[11][9]  = $character[11][10]
	    = $character[11][11] = $character[12][5]  = $character[12][6]
	    = $character[12][7]  = $character[12][8]  = $character[12][9]
	    = $character[12][10] = $character[13][4]  = $character[13][5]
	    = $character[13][6]  = $character[13][7]  = $character[13][8]
	    = $character[13][9]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][8]  = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[16][1]  = $character[16][2]  = $character[16][3]
	    = $character[16][4]  = $character[16][5]  = $character[16][6]
	    = $character[16][7]  = $character[16][8]  = $character[16][9]
	    = $character[16][10] = $character[16][11] = $character[16][12]
	    = $character[16][13] = $character[16][14] = $character[16][15] = ':';
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(19);
	$character[3][5] = $character[3][6] = $character[3][7] = $character[3][8]
	    = $character[3][9]   = $character[3][10]  = $character[3][11]
	    = $character[3][12]  = $character[3][13]  = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][6]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[4][12]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[5][1]   = $character[5][2]   = $character[5][3]
	    = $character[5][4]   = $character[5][5]   = $character[5][6]
	    = $character[5][7]   = $character[5][11]  = $character[5][12]
	    = $character[5][13]  = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[6][1]
	    = $character[6][2]   = $character[6][3]   = $character[6][4]
	    = $character[6][5]   = $character[6][6]   = $character[6][12]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[7][1]
	    = $character[7][2]   = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[7][13]  = $character[7][14]
	    = $character[7][15]  = $character[7][16]  = $character[7][17]
	    = $character[8][1]   = $character[8][2]   = $character[8][3]
	    = $character[8][4]   = $character[8][5]   = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[9][16]  = $character[9][17]  = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[10][17]
	    = $character[11][1]  = $character[11][2]  = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[12][1]  = $character[12][2]
	    = $character[12][3]  = $character[12][4]  = $character[12][5]
	    = $character[12][13] = $character[12][14] = $character[12][15]
	    = $character[12][16] = $character[12][17] = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[13][6]  = $character[13][12]
	    = $character[13][13] = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[13][17] = $character[14][1]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][7]
	    = $character[14][11] = $character[14][12] = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[14][16]
	    = $character[14][17] = $character[15][3]  = $character[15][4]
	    = $character[15][5]  = $character[15][6]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = $character[16][13] = ':';
	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][8]
	    = $character[2][9]   = $character[2][10]  = $character[2][11]
	    = $character[2][12]  = $character[2][13]  = $character[3][3]
	    = $character[3][4]   = $character[3][14]  = $character[3][15]
	    = $character[4][1]   = $character[4][2]   = $character[4][16]
	    = $character[4][17]  = $character[5][0]   = $character[5][8]
	    = $character[5][9]   = $character[5][10]  = $character[5][18]
	    = $character[6][0]   = $character[6][7]   = $character[6][11]
	    = $character[6][18]  = $character[7][0]   = $character[7][6]
	    = $character[7][12]  = $character[7][18]  = $character[8][0]
	    = $character[8][6]   = $character[8][12]  = $character[8][18]
	    = $character[9][0]   = $character[9][6]   = $character[9][8]
	    = $character[9][9]   = $character[9][10]  = $character[9][12]
	    = $character[9][18]  = $character[10][0]  = $character[10][6]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][12] = $character[10][18] = $character[11][0]
	    = $character[11][6]  = $character[11][12] = $character[11][18]
	    = $character[12][0]  = $character[12][6]  = $character[12][12]
	    = $character[12][18] = $character[13][0]  = $character[13][7]
	    = $character[13][11] = $character[13][18] = $character[14][0]
	    = $character[14][8]  = $character[14][9]  = $character[14][10]
	    = $character[14][18] = $character[15][1]  = $character[15][2]
	    = $character[15][16] = $character[15][17] = $character[16][3]
	    = $character[16][4]  = $character[16][14] = $character[16][15]
	    = $character[17][5]  = $character[17][6]  = $character[17][7]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][12] = $character[17][13] = '0';
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(12);
	$character[3][2] = $character[3][3] = $character[3][4] = $character[3][5]
	    = $character[3][6]  = $character[3][7]   = $character[4][1]
	    = $character[4][2]  = $character[4][3]   = $character[4][4]
	    = $character[4][5]  = $character[4][6]   = $character[4][7]
	    = $character[5][3]  = $character[5][4]   = $character[5][5]
	    = $character[5][6]  = $character[5][7]   = $character[6][4]
	    = $character[6][5]  = $character[6][6]   = $character[6][7]
	    = $character[7][4]  = $character[7][5]   = $character[7][6]
	    = $character[7][7]  = $character[8][4]   = $character[8][5]
	    = $character[8][6]  = $character[8][7]   = $character[9][4]
	    = $character[9][5]  = $character[9][6]   = $character[9][7]
	    = $character[10][4] = $character[10][5]  = $character[10][6]
	    = $character[10][7] = $character[11][4]  = $character[11][5]
	    = $character[11][6] = $character[11][7]  = $character[12][4]
	    = $character[12][5] = $character[12][6]  = $character[12][7]
	    = $character[13][4] = $character[13][5]  = $character[13][6]
	    = $character[13][7] = $character[14][3]  = $character[14][4]
	    = $character[14][5] = $character[14][6]  = $character[14][7]
	    = $character[14][8] = $character[15][1]  = $character[15][2]
	    = $character[15][3] = $character[15][4]  = $character[15][5]
	    = $character[15][6] = $character[15][7]  = $character[15][8]
	    = $character[15][9] = $character[15][10] = $character[16][1]
	    = $character[16][2] = $character[16][3]  = $character[16][4]
	    = $character[16][5] = $character[16][6]  = $character[16][7]
	    = $character[16][8] = $character[16][9]  = $character[16][10] = ':';
	$character[2][2] = $character[2][3] = $character[2][4] = $character[2][5]
	    = $character[2][6]   = $character[2][7]   = $character[2][8]
	    = $character[3][1]   = $character[3][8]   = $character[4][0]
	    = $character[4][8]   = $character[5][0]   = $character[5][1]
	    = $character[5][2]   = $character[5][8]   = $character[6][3]
	    = $character[6][8]   = $character[7][3]   = $character[7][8]
	    = $character[8][3]   = $character[8][8]   = $character[9][3]
	    = $character[10][3]  = $character[11][3]  = $character[12][3]
	    = $character[13][3]  = $character[14][0]  = $character[14][1]
	    = $character[14][2]  = $character[14][9]  = $character[14][10]
	    = $character[14][11] = $character[15][0]  = $character[15][11]
	    = $character[16][0]  = $character[16][11] = $character[17][0]
	    = $character[17][1]  = $character[17][2]  = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = $character[17][11] = '1';
	$character[9][8] = $character[10][8] = $character[11][8]
	    = $character[12][8] = $character[13][8] = 'l';
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(20);
	$character[2][1] = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5]   = $character[2][6]   = $character[2][7]
	    = $character[2][8]   = $character[2][9]   = $character[2][10]
	    = $character[2][11]  = $character[2][12]  = $character[2][13]
	    = $character[2][14]  = $character[2][15]  = $character[3][0]
	    = $character[3][16]  = $character[3][17]  = $character[4][0]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[4][12]
	    = $character[4][18]  = $character[5][0]   = $character[5][1]
	    = $character[5][2]   = $character[5][3]   = $character[5][4]
	    = $character[5][5]   = $character[5][6]   = $character[5][12]
	    = $character[5][18]  = $character[6][12]  = $character[6][18]
	    = $character[7][12]  = $character[7][18]  = $character[8][9]
	    = $character[8][10]  = $character[8][11]  = $character[8][12]
	    = $character[8][17]  = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][15]  = $character[9][16]  = $character[10][2]
	    = $character[10][3]  = $character[10][12] = $character[10][13]
	    = $character[10][14] = $character[11][1]  = $character[11][7]
	    = $character[11][8]  = $character[11][9]  = $character[11][10]
	    = $character[11][11] = $character[12][0]  = $character[12][6]
	    = $character[13][0]  = $character[13][6]  = $character[14][0]
	    = $character[14][6]  = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][17] = $character[14][18]
	    = $character[14][19] = $character[15][0]  = $character[15][7]
	    = $character[15][8]  = $character[15][9]  = $character[15][10]
	    = $character[15][11] = $character[15][12] = $character[15][13]
	    = $character[15][19] = $character[16][0]  = $character[16][19]
	    = $character[17][0]  = $character[17][1]  = $character[17][2]
	    = $character[17][3]  = $character[17][4]  = $character[17][5]
	    = $character[17][6]  = $character[17][7]  = $character[17][8]
	    = $character[17][9]  = $character[17][10] = $character[17][11]
	    = $character[17][12] = $character[17][13] = $character[17][14]
	    = $character[17][15] = $character[17][16] = $character[17][17]
	    = $character[17][18] = $character[17][19] = '2';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[4][13]
	    = $character[4][14]  = $character[4][15]  = $character[4][16]
	    = $character[4][17]  = $character[5][13]  = $character[5][14]
	    = $character[5][15]  = $character[5][16]  = $character[5][17]
	    = $character[6][13]  = $character[6][14]  = $character[6][15]
	    = $character[6][16]  = $character[6][17]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[7][16]
	    = $character[7][17]  = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[8][16]  = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][7]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[11][2]  = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][6]
	    = $character[12][1]  = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[13][1]
	    = $character[13][2]  = $character[13][3]  = $character[13][4]
	    = $character[13][5]  = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[15][1]  = $character[15][2]  = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[15][17] = $character[15][18] = $character[16][1]
	    = $character[16][2]  = $character[16][3]  = $character[16][4]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13]
	    = $character[16][14] = $character[16][15] = $character[16][16]
	    = $character[16][17] = $character[16][18] = ':';
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(19);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[4][12]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[4][16]  = $character[4][17]  = $character[5][13]
	    = $character[5][14]  = $character[5][15]  = $character[5][16]
	    = $character[5][17]  = $character[6][13]  = $character[6][14]
	    = $character[6][15]  = $character[6][16]  = $character[6][17]
	    = $character[7][13]  = $character[7][14]  = $character[7][15]
	    = $character[7][16]  = $character[7][17]  = $character[8][12]
	    = $character[8][13]  = $character[8][14]  = $character[8][15]
	    = $character[8][16]  = $character[9][5]   = $character[9][6]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[10][12] = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[12][13] = $character[12][14]
	    = $character[12][15] = $character[12][16] = $character[12][17]
	    = $character[13][13] = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[13][17] = $character[14][13]
	    = $character[14][14] = $character[14][15] = $character[14][16]
	    = $character[14][17] = $character[15][1]  = $character[15][2]
	    = $character[15][3]  = $character[15][4]  = $character[15][5]
	    = $character[15][6]  = $character[15][12] = $character[15][13]
	    = $character[15][14] = $character[15][15] = $character[15][16]
	    = $character[15][17] = $character[16][1]  = $character[16][2]
	    = $character[16][3]  = $character[16][4]  = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = $character[16][13] = $character[16][14]
	    = $character[16][15] = ':';
	$character[2][1] = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5]   = $character[2][6]   = $character[2][7]
	    = $character[2][8]   = $character[2][9]   = $character[2][10]
	    = $character[2][11]  = $character[2][12]  = $character[2][13]
	    = $character[2][14]  = $character[2][15]  = $character[3][0]
	    = $character[3][16]  = $character[3][17]  = $character[4][0]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[4][18]
	    = $character[5][0]   = $character[5][1]   = $character[5][2]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[5][6]   = $character[5][12]  = $character[5][18]
	    = $character[6][12]  = $character[6][18]  = $character[7][12]
	    = $character[7][18]  = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][17]  = $character[9][4]   = $character[9][16]
	    = $character[10][4]  = $character[10][5]  = $character[10][6]
	    = $character[10][7]  = $character[10][8]  = $character[10][9]
	    = $character[10][10] = $character[10][11] = $character[10][17]
	    = $character[11][12] = $character[11][18] = $character[12][12]
	    = $character[12][18] = $character[13][12] = $character[13][18]
	    = $character[14][0]  = $character[14][1]  = $character[14][2]
	    = $character[14][3]  = $character[14][4]  = $character[14][5]
	    = $character[14][6]  = $character[14][12] = $character[14][18]
	    = $character[15][0]  = $character[15][7]  = $character[15][8]
	    = $character[15][9]  = $character[15][10] = $character[15][11]
	    = $character[15][18] = $character[16][0]  = $character[16][16]
	    = $character[16][17] = $character[17][1]  = $character[17][2]
	    = $character[17][3]  = $character[17][4]  = $character[17][5]
	    = $character[17][6]  = $character[17][7]  = $character[17][8]
	    = $character[17][9]  = $character[17][10] = $character[17][11]
	    = $character[17][12] = $character[17][13] = $character[17][14]
	    = $character[17][15] = '3';
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(18);
	$character[2][7] = $character[2][8] = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[3][6]   = $character[3][15]  = $character[4][5]
	    = $character[4][15]  = $character[5][4]   = $character[5][9]
	    = $character[5][10]  = $character[5][15]  = $character[6][3]
	    = $character[6][8]   = $character[6][10]  = $character[6][15]
	    = $character[7][2]   = $character[7][7]   = $character[7][10]
	    = $character[7][15]  = $character[8][1]   = $character[8][6]
	    = $character[8][10]  = $character[8][15]  = $character[9][0]
	    = $character[9][5]   = $character[9][6]   = $character[9][7]
	    = $character[9][8]   = $character[9][9]   = $character[9][10]
	    = $character[9][15]  = $character[9][16]  = $character[9][17]
	    = $character[10][0]  = $character[10][17] = $character[11][0]
	    = $character[11][1]  = $character[11][2]  = $character[11][3]
	    = $character[11][4]  = $character[11][5]  = $character[11][6]
	    = $character[11][7]  = $character[11][8]  = $character[11][9]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[12][10] = $character[12][15] = $character[13][10]
	    = $character[13][15] = $character[14][10] = $character[14][15]
	    = $character[15][8]  = $character[15][9]  = $character[15][16]
	    = $character[15][17] = $character[16][8]  = $character[16][17]
	    = $character[17][8]  = $character[17][9]  = $character[17][10]
	    = $character[17][11] = $character[17][12] = $character[17][13]
	    = $character[17][14] = $character[17][15] = $character[17][16]
	    = $character[17][17] = '4';
	$character[3][7] = $character[3][8] = $character[3][9]
	    = $character[3][10]  = $character[3][11]  = $character[3][12]
	    = $character[3][13]  = $character[3][14]  = $character[4][6]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[4][12]
	    = $character[4][13]  = $character[4][14]  = $character[5][5]
	    = $character[5][6]   = $character[5][7]   = $character[5][8]
	    = $character[5][11]  = $character[5][12]  = $character[5][13]
	    = $character[5][14]  = $character[6][4]   = $character[6][5]
	    = $character[6][6]   = $character[6][7]   = $character[6][11]
	    = $character[6][12]  = $character[6][13]  = $character[6][14]
	    = $character[7][3]   = $character[7][4]   = $character[7][5]
	    = $character[7][6]   = $character[7][11]  = $character[7][12]
	    = $character[7][13]  = $character[7][14]  = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][11]  = $character[8][12]  = $character[8][13]
	    = $character[8][14]  = $character[9][1]   = $character[9][2]
	    = $character[9][3]   = $character[9][4]   = $character[9][11]
	    = $character[9][12]  = $character[9][13]  = $character[9][14]
	    = $character[10][1]  = $character[10][2]  = $character[10][3]
	    = $character[10][4]  = $character[10][5]  = $character[10][6]
	    = $character[10][7]  = $character[10][8]  = $character[10][9]
	    = $character[10][10] = $character[10][11] = $character[10][12]
	    = $character[10][13] = $character[10][14] = $character[10][15]
	    = $character[10][16] = $character[11][10] = $character[11][11]
	    = $character[11][12] = $character[11][13] = $character[11][14]
	    = $character[12][11] = $character[12][12] = $character[12][13]
	    = $character[12][14] = $character[13][11] = $character[13][12]
	    = $character[13][13] = $character[13][14] = $character[14][11]
	    = $character[14][12] = $character[14][13] = $character[14][14]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[16][9]  = $character[16][10] = $character[16][11]
	    = $character[16][12] = $character[16][13] = $character[16][14]
	    = $character[16][15] = $character[16][16] = ':';
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(19);
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[2][17]  = $character[3][0]
	    = $character[3][17]  = $character[4][0]   = $character[4][17]
	    = $character[5][0]   = $character[5][6]   = $character[5][7]
	    = $character[5][8]   = $character[5][9]   = $character[5][10]
	    = $character[5][11]  = $character[5][12]  = $character[5][13]
	    = $character[5][14]  = $character[5][15]  = $character[5][16]
	    = $character[5][17]  = $character[6][0]   = $character[6][6]
	    = $character[7][0]   = $character[7][6]   = $character[8][0]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[8][9]   = $character[8][10]  = $character[8][11]
	    = $character[8][12]  = $character[8][13]  = $character[8][14]
	    = $character[8][15]  = $character[9][0]   = $character[9][16]
	    = $character[10][0]  = $character[10][1]  = $character[10][2]
	    = $character[10][3]  = $character[10][4]  = $character[10][5]
	    = $character[10][6]  = $character[10][7]  = $character[10][8]
	    = $character[10][9]  = $character[10][10] = $character[10][11]
	    = $character[10][17] = $character[11][12] = $character[11][18]
	    = $character[12][12] = $character[12][18] = $character[13][0]
	    = $character[13][1]  = $character[13][2]  = $character[13][3]
	    = $character[13][4]  = $character[13][5]  = $character[13][6]
	    = $character[13][12] = $character[13][18] = $character[14][0]
	    = $character[14][7]  = $character[14][8]  = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][18]
	    = $character[15][1]  = $character[15][2]  = $character[15][16]
	    = $character[15][17] = $character[16][3]  = $character[16][4]
	    = $character[16][14] = $character[16][15] = $character[17][5]
	    = $character[17][6]  = $character[17][7]  = $character[17][8]
	    = $character[17][9]  = $character[17][10] = $character[17][11]
	    = $character[17][12] = $character[17][13] = '5';
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[4][1]   = $character[4][2]   = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][6]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[4][12]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[4][16]  = $character[5][1]   = $character[5][2]
	    = $character[5][3]   = $character[5][4]   = $character[5][5]
	    = $character[6][1]   = $character[6][2]   = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[7][1]
	    = $character[7][2]   = $character[7][3]   = $character[7][4]
	    = $character[7][5]   = $character[8][1]   = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[9][1]   = $character[9][2]   = $character[9][3]
	    = $character[9][4]   = $character[9][5]   = $character[9][6]
	    = $character[9][7]   = $character[9][8]   = $character[9][9]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[9][15]
	    = $character[10][12] = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[11][17] = $character[12][13] = $character[12][14]
	    = $character[12][15] = $character[12][16] = $character[12][17]
	    = $character[13][13] = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[13][17] = $character[14][1]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][17] = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13] = ':';
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(19);
	$character[2][8] = $character[2][9] = $character[2][10]
	    = $character[2][11]  = $character[2][12]  = $character[2][13]
	    = $character[2][14]  = $character[2][15]  = $character[3][7]
	    = $character[3][14]  = $character[4][6]   = $character[4][13]
	    = $character[5][5]   = $character[5][12]  = $character[6][4]
	    = $character[6][11]  = $character[7][3]   = $character[7][10]
	    = $character[8][2]   = $character[8][9]   = $character[9][1]
	    = $character[9][10]  = $character[9][11]  = $character[9][12]
	    = $character[9][13]  = $character[9][14]  = $character[10][0]
	    = $character[10][15] = $character[10][16] = $character[11][0]
	    = $character[11][7]  = $character[11][8]  = $character[11][9]
	    = $character[11][10] = $character[11][11] = $character[11][17]
	    = $character[12][0]  = $character[12][6]  = $character[12][12]
	    = $character[12][18] = $character[13][0]  = $character[13][6]
	    = $character[13][12] = $character[13][18] = $character[14][0]
	    = $character[14][7]  = $character[14][8]  = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][18]
	    = $character[15][1]  = $character[15][2]  = $character[15][16]
	    = $character[15][17] = $character[16][3]  = $character[16][4]
	    = $character[16][14] = $character[16][15] = $character[17][5]
	    = $character[17][6]  = $character[17][7]  = $character[17][8]
	    = $character[17][9]  = $character[17][10] = $character[17][11]
	    = $character[17][12] = $character[17][13] = '6';
	$character[3][8] = $character[3][9] = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[4][12]
	    = $character[5][6]   = $character[5][7]   = $character[5][8]
	    = $character[5][9]   = $character[5][10]  = $character[5][11]
	    = $character[6][5]   = $character[6][6]   = $character[6][7]
	    = $character[6][8]   = $character[6][9]   = $character[6][10]
	    = $character[7][4]   = $character[7][5]   = $character[7][6]
	    = $character[7][7]   = $character[7][8]   = $character[7][9]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][7]   = $character[8][8]
	    = $character[9][2]   = $character[9][3]   = $character[9][4]
	    = $character[9][5]   = $character[9][6]   = $character[9][7]
	    = $character[9][8]   = $character[9][9]   = $character[10][1]
	    = $character[10][2]  = $character[10][3]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][7]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[10][12] = $character[10][13]
	    = $character[10][14] = $character[11][1]  = $character[11][2]
	    = $character[11][3]  = $character[11][4]  = $character[11][5]
	    = $character[11][6]  = $character[11][12] = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[11][16]
	    = $character[12][1]  = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][13]
	    = $character[12][14] = $character[12][15] = $character[12][16]
	    = $character[12][17] = $character[13][1]  = $character[13][2]
	    = $character[13][3]  = $character[13][4]  = $character[13][5]
	    = $character[13][13] = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[13][17] = $character[14][1]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][17] = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13] = ':';
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(20);
	$character[3][1] = $character[3][2] = $character[3][3] = $character[3][4]
	    = $character[3][5]   = $character[3][6]   = $character[3][7]
	    = $character[3][8]   = $character[3][9]   = $character[3][10]
	    = $character[3][11]  = $character[3][12]  = $character[3][13]
	    = $character[3][14]  = $character[3][15]  = $character[3][16]
	    = $character[3][17]  = $character[3][18]  = $character[4][1]
	    = $character[4][2]   = $character[4][3]   = $character[4][4]
	    = $character[4][5]   = $character[4][6]   = $character[4][7]
	    = $character[4][8]   = $character[4][9]   = $character[4][10]
	    = $character[4][11]  = $character[4][12]  = $character[4][13]
	    = $character[4][14]  = $character[4][15]  = $character[4][16]
	    = $character[4][17]  = $character[4][18]  = $character[5][12]
	    = $character[5][13]  = $character[5][14]  = $character[5][15]
	    = $character[5][16]  = $character[5][17]  = $character[5][18]
	    = $character[6][12]  = $character[6][13]  = $character[6][14]
	    = $character[6][15]  = $character[6][16]  = $character[6][17]
	    = $character[7][11]  = $character[7][12]  = $character[7][13]
	    = $character[7][14]  = $character[7][15]  = $character[7][16]
	    = $character[8][10]  = $character[8][11]  = $character[8][12]
	    = $character[8][13]  = $character[8][14]  = $character[8][15]
	    = $character[9][9]   = $character[9][10]  = $character[9][11]
	    = $character[9][12]  = $character[9][13]  = $character[9][14]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[10][12] = $character[10][13]
	    = $character[11][7]  = $character[11][8]  = $character[11][9]
	    = $character[11][10] = $character[11][11] = $character[11][12]
	    = $character[12][6]  = $character[12][7]  = $character[12][8]
	    = $character[12][9]  = $character[12][10] = $character[12][11]
	    = $character[13][5]  = $character[13][6]  = $character[13][7]
	    = $character[13][8]  = $character[13][9]  = $character[13][10]
	    = $character[14][4]  = $character[14][5]  = $character[14][6]
	    = $character[14][7]  = $character[14][8]  = $character[14][9]
	    = $character[15][3]  = $character[15][4]  = $character[15][5]
	    = $character[15][6]  = $character[15][7]  = $character[15][8]
	    = $character[16][2]  = $character[16][3]  = $character[16][4]
	    = $character[16][5]  = $character[16][6]  = $character[16][7] = ':';
	$character[2][0] = $character[2][1] = $character[2][2] = $character[2][3]
	    = $character[2][4]   = $character[2][5]   = $character[2][6]
	    = $character[2][7]   = $character[2][8]   = $character[2][9]
	    = $character[2][10]  = $character[2][11]  = $character[2][12]
	    = $character[2][13]  = $character[2][14]  = $character[2][15]
	    = $character[2][16]  = $character[2][17]  = $character[2][18]
	    = $character[2][19]  = $character[3][0]   = $character[3][19]
	    = $character[4][0]   = $character[4][19]  = $character[5][0]
	    = $character[5][1]   = $character[5][2]   = $character[5][3]
	    = $character[5][4]   = $character[5][5]   = $character[5][6]
	    = $character[5][7]   = $character[5][8]   = $character[5][9]
	    = $character[5][10]  = $character[5][11]  = $character[5][19]
	    = $character[6][11]  = $character[6][18]  = $character[7][10]
	    = $character[7][17]  = $character[8][9]   = $character[8][16]
	    = $character[9][8]   = $character[9][15]  = $character[10][7]
	    = $character[10][14] = $character[11][6]  = $character[11][13]
	    = $character[12][5]  = $character[12][12] = $character[13][4]
	    = $character[13][11] = $character[14][3]  = $character[14][10]
	    = $character[15][2]  = $character[15][9]  = $character[16][1]
	    = $character[16][8]  = $character[17][0]  = $character[17][1]
	    = $character[17][2]  = $character[17][3]  = $character[17][4]
	    = $character[17][5]  = $character[17][6]  = $character[17][7] = '7';
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(19);
	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][8]
	    = $character[2][9]   = $character[2][10]  = $character[2][11]
	    = $character[2][12]  = $character[2][13]  = $character[3][3]
	    = $character[3][4]   = $character[3][14]  = $character[3][15]
	    = $character[4][1]   = $character[4][2]   = $character[4][16]
	    = $character[4][17]  = $character[5][0]   = $character[5][7]
	    = $character[5][8]   = $character[5][9]   = $character[5][10]
	    = $character[5][11]  = $character[5][18]  = $character[6][0]
	    = $character[6][6]   = $character[6][12]  = $character[6][18]
	    = $character[7][0]   = $character[7][6]   = $character[7][12]
	    = $character[7][18]  = $character[8][1]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][17]  = $character[9][2]
	    = $character[9][16]  = $character[10][1]  = $character[10][7]
	    = $character[10][8]  = $character[10][9]  = $character[10][10]
	    = $character[10][11] = $character[10][17] = $character[11][0]
	    = $character[11][6]  = $character[11][12] = $character[11][18]
	    = $character[12][0]  = $character[12][6]  = $character[12][12]
	    = $character[12][18] = $character[13][0]  = $character[13][6]
	    = $character[13][12] = $character[13][18] = $character[14][0]
	    = $character[14][7]  = $character[14][8]  = $character[14][9]
	    = $character[14][10] = $character[14][11] = $character[14][18]
	    = $character[15][1]  = $character[15][2]  = $character[15][16]
	    = $character[15][17] = $character[16][3]  = $character[16][4]
	    = $character[16][14] = $character[16][15] = $character[17][5]
	    = $character[17][6]  = $character[17][7]  = $character[17][8]
	    = $character[17][9]  = $character[17][10] = $character[17][11]
	    = $character[17][12] = $character[17][13] = '8';
	$character[3][5] = $character[3][6] = $character[3][7] = $character[3][8]
	    = $character[3][9]   = $character[3][10]  = $character[3][11]
	    = $character[3][12]  = $character[3][13]  = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][6]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[4][12]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[5][1]   = $character[5][2]   = $character[5][3]
	    = $character[5][4]   = $character[5][5]   = $character[5][6]
	    = $character[5][12]  = $character[5][13]  = $character[5][14]
	    = $character[5][15]  = $character[5][16]  = $character[5][17]
	    = $character[6][1]   = $character[6][2]   = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][13]
	    = $character[6][14]  = $character[6][15]  = $character[6][16]
	    = $character[6][17]  = $character[7][1]   = $character[7][2]
	    = $character[7][3]   = $character[7][4]   = $character[7][5]
	    = $character[7][13]  = $character[7][14]  = $character[7][15]
	    = $character[7][16]  = $character[7][17]  = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][12]  = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[9][3]   = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][9]   = $character[9][10]  = $character[9][11]
	    = $character[9][12]  = $character[9][13]  = $character[9][14]
	    = $character[9][15]  = $character[10][2]  = $character[10][3]
	    = $character[10][4]  = $character[10][5]  = $character[10][6]
	    = $character[10][12] = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[11][1]
	    = $character[11][2]  = $character[11][3]  = $character[11][4]
	    = $character[11][5]  = $character[11][13] = $character[11][14]
	    = $character[11][15] = $character[11][16] = $character[11][17]
	    = $character[12][1]  = $character[12][2]  = $character[12][3]
	    = $character[12][4]  = $character[12][5]  = $character[12][13]
	    = $character[12][14] = $character[12][15] = $character[12][16]
	    = $character[12][17] = $character[13][1]  = $character[13][2]
	    = $character[13][3]  = $character[13][4]  = $character[13][5]
	    = $character[13][13] = $character[13][14] = $character[13][15]
	    = $character[13][16] = $character[13][17] = $character[14][1]
	    = $character[14][2]  = $character[14][3]  = $character[14][4]
	    = $character[14][5]  = $character[14][6]  = $character[14][12]
	    = $character[14][13] = $character[14][14] = $character[14][15]
	    = $character[14][16] = $character[14][17] = $character[15][3]
	    = $character[15][4]  = $character[15][5]  = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[15][12]
	    = $character[15][13] = $character[15][14] = $character[15][15]
	    = $character[16][5]  = $character[16][6]  = $character[16][7]
	    = $character[16][8]  = $character[16][9]  = $character[16][10]
	    = $character[16][11] = $character[16][12] = $character[16][13] = ':';
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(19);
	$character[2][5] = $character[2][6] = $character[2][7] = $character[2][8]
	    = $character[2][9]   = $character[2][10]  = $character[2][11]
	    = $character[2][12]  = $character[2][13]  = $character[3][3]
	    = $character[3][4]   = $character[3][14]  = $character[3][15]
	    = $character[4][1]   = $character[4][2]   = $character[4][16]
	    = $character[4][17]  = $character[5][0]   = $character[5][7]
	    = $character[5][8]   = $character[5][9]   = $character[5][10]
	    = $character[5][11]  = $character[5][18]  = $character[6][0]
	    = $character[6][6]   = $character[6][12]  = $character[6][18]
	    = $character[7][0]   = $character[7][6]   = $character[7][12]
	    = $character[7][18]  = $character[8][1]   = $character[8][7]
	    = $character[8][8]   = $character[8][9]   = $character[8][10]
	    = $character[8][11]  = $character[8][18]  = $character[9][2]
	    = $character[9][3]   = $character[9][18]  = $character[10][4]
	    = $character[10][5]  = $character[10][6]  = $character[10][7]
	    = $character[10][8]  = $character[10][17] = $character[11][9]
	    = $character[11][16] = $character[12][8]  = $character[12][15]
	    = $character[13][7]  = $character[13][14] = $character[14][6]
	    = $character[14][13] = $character[15][5]  = $character[15][12]
	    = $character[16][4]  = $character[16][11] = $character[17][3]
	    = $character[17][4]  = $character[17][5]  = $character[17][6]
	    = $character[17][7]  = $character[17][8]  = $character[17][9]
	    = $character[17][10] = '9';
	$character[3][5] = $character[3][6] = $character[3][7] = $character[3][8]
	    = $character[3][9]   = $character[3][10]  = $character[3][11]
	    = $character[3][12]  = $character[3][13]  = $character[4][3]
	    = $character[4][4]   = $character[4][5]   = $character[4][6]
	    = $character[4][7]   = $character[4][8]   = $character[4][9]
	    = $character[4][10]  = $character[4][11]  = $character[4][12]
	    = $character[4][13]  = $character[4][14]  = $character[4][15]
	    = $character[5][1]   = $character[5][2]   = $character[5][3]
	    = $character[5][4]   = $character[5][5]   = $character[5][6]
	    = $character[5][12]  = $character[5][13]  = $character[5][14]
	    = $character[5][15]  = $character[5][16]  = $character[5][17]
	    = $character[6][1]   = $character[6][2]   = $character[6][3]
	    = $character[6][4]   = $character[6][5]   = $character[6][13]
	    = $character[6][14]  = $character[6][15]  = $character[6][16]
	    = $character[6][17]  = $character[7][1]   = $character[7][2]
	    = $character[7][3]   = $character[7][4]   = $character[7][5]
	    = $character[7][13]  = $character[7][14]  = $character[7][15]
	    = $character[7][16]  = $character[7][17]  = $character[8][2]
	    = $character[8][3]   = $character[8][4]   = $character[8][5]
	    = $character[8][6]   = $character[8][12]  = $character[8][13]
	    = $character[8][14]  = $character[8][15]  = $character[8][16]
	    = $character[8][17]  = $character[9][4]   = $character[9][5]
	    = $character[9][6]   = $character[9][7]   = $character[9][8]
	    = $character[9][9]   = $character[9][10]  = $character[9][11]
	    = $character[9][12]  = $character[9][13]  = $character[9][14]
	    = $character[9][15]  = $character[9][16]  = $character[9][17]
	    = $character[10][9]  = $character[10][10] = $character[10][11]
	    = $character[10][12] = $character[10][13] = $character[10][14]
	    = $character[10][15] = $character[10][16] = $character[11][10]
	    = $character[11][11] = $character[11][12] = $character[11][13]
	    = $character[11][14] = $character[11][15] = $character[12][9]
	    = $character[12][10] = $character[12][11] = $character[12][12]
	    = $character[12][13] = $character[12][14] = $character[13][8]
	    = $character[13][9]  = $character[13][10] = $character[13][11]
	    = $character[13][12] = $character[13][13] = $character[14][7]
	    = $character[14][8]  = $character[14][9]  = $character[14][10]
	    = $character[14][11] = $character[14][12] = $character[15][6]
	    = $character[15][7]  = $character[15][8]  = $character[15][9]
	    = $character[15][10] = $character[15][11] = $character[16][5]
	    = $character[16][6]  = $character[16][7]  = $character[16][8]
	    = $character[16][9]  = $character[16][10] = ':';
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Doh - Doh font

=head1 VERSION

Version 0.15

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use Ascii::Text::Font::Doh;

	my $foo = Ascii::Text::Font::Doh->new();

	...

=head1 SUBROUTINES/METHODS

=head2 character_A

                                 
	                                 
	               AAA               
	              A:::A              
	             A:::::A             
	            A:::::::A            
	           A:::::::::A           
	          A:::::A:::::A          
	         A:::::A A:::::A         
	        A:::::A   A:::::A        
	       A:::::A     A:::::A       
	      A:::::AAAAAAAAA:::::A      
	     A:::::::::::::::::::::A     
	    A:::::AAAAAAAAAAAAA:::::A    
	   A:::::A             A:::::A   
	  A:::::A               A:::::A  
	 A:::::A                 A:::::A 
	AAAAAAA                   AAAAAAA
	                                 
	                                 
	                                 
	                                 
	                                 
	                                 
	                                 

=head2 character_B

                    
	                    
	BBBBBBBBBBBBBBBBB   
	B::::::::::::::::B  
	B::::::BBBBBB:::::B 
	BB:::::B     B:::::B
	  B::::B     B:::::B
	  B::::B     B:::::B
	  B::::BBBBBB:::::B 
	  B:::::::::::::BB  
	  B::::BBBBBB:::::B 
	  B::::B     B:::::B
	  B::::B     B:::::B
	  B::::B     B:::::B
	BB:::::BBBBBB::::::B
	B:::::::::::::::::B 
	B::::::::::::::::B  
	BBBBBBBBBBBBBBBBB   
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_C

                     
	                     
	        CCCCCCCCCCCCC
	     CCC::::::::::::C
	   CC:::::::::::::::C
	  C:::::CCCCCCCC::::C
	 C:::::C       CCCCCC
	C:::::C              
	C:::::C              
	C:::::C              
	C:::::C              
	C:::::C              
	C:::::C              
	 C:::::C       CCCCCC
	  C:::::CCCCCCCC::::C
	   CC:::::::::::::::C
	     CCC::::::::::::C
	        CCCCCCCCCCCCC
	                     
	                     
	                     
	                     
	                     
	                     
	                     

=head2 character_D

                     
	                     
	DDDDDDDDDDDDD        
	D::::::::::::DDD     
	D:::::::::::::::DD   
	DDD:::::DDDDD:::::D  
	  D:::::D    D:::::D 
	  D:::::D     D:::::D
	  D:::::D     D:::::D
	  D:::::D     D:::::D
	  D:::::D     D:::::D
	  D:::::D     D:::::D
	  D:::::D     D:::::D
	  D:::::D    D:::::D 
	DDD:::::DDDDD:::::D  
	D:::::::::::::::DD   
	D::::::::::::DDD     
	DDDDDDDDDDDDD        
	                     
	                     
	                     
	                     
	                     
	                     
	                     

=head2 character_E

                      
	                      
	EEEEEEEEEEEEEEEEEEEEEE
	E::::::::::::::::::::E
	E::::::::::::::::::::E
	EE::::::EEEEEEEEE::::E
	  E:::::E       EEEEEE
	  E:::::E             
	  E::::::EEEEEEEEEE   
	  E:::::::::::::::E   
	  E:::::::::::::::E   
	  E::::::EEEEEEEEEE   
	  E:::::E             
	  E:::::E       EEEEEE
	EE::::::EEEEEEEE:::::E
	E::::::::::::::::::::E
	E::::::::::::::::::::E
	EEEEEEEEEEEEEEEEEEEEEE
	                      
	                      
	                      
	                      
	                      
	                      
	                      

=head2 character_F

                      
	                      
	FFFFFFFFFFFFFFFFFFFFFF
	F::::::::::::::::::::F
	F::::::::::::::::::::F
	FF::::::FFFFFFFFF::::F
	  F:::::F       FFFFFF
	  F:::::F             
	  F::::::FFFFFFFFFF   
	  F:::::::::::::::F   
	  F:::::::::::::::F   
	  F::::::FFFFFFFFFF   
	  F:::::F             
	  F:::::F             
	FF:::::::FF           
	F::::::::FF           
	F::::::::FF           
	FFFFFFFFFFF           
	                      
	                      
	                      
	                      
	                      
	                      
	                      

=head2 character_G

                     
	                     
	        GGGGGGGGGGGGG
	     GGG::::::::::::G
	   GG:::::::::::::::G
	  G:::::GGGGGGGG::::G
	 G:::::G       GGGGGG
	G:::::G              
	G:::::G              
	G:::::G    GGGGGGGGGG
	G:::::G    G::::::::G
	G:::::G    GGGGG::::G
	G:::::G        G::::G
	 G:::::G       G::::G
	  G:::::GGGGGGGG::::G
	   GG:::::::::::::::G
	     GGG::::::GGG:::G
	        GGGGGG   GGGG
	                     
	                     
	                     
	                     
	                     
	                     
	                     

=head2 character_H

                       
	                       
	HHHHHHHHH     HHHHHHHHH
	H:::::::H     H:::::::H
	H:::::::H     H:::::::H
	HH::::::H     H::::::HH
	  H:::::H     H:::::H  
	  H:::::H     H:::::H  
	  H::::::HHHHH::::::H  
	  H:::::::::::::::::H  
	  H:::::::::::::::::H  
	  H::::::HHHHH::::::H  
	  H:::::H     H:::::H  
	  H:::::H     H:::::H  
	HH::::::H     H::::::HH
	H:::::::H     H:::::::H
	H:::::::H     H:::::::H
	HHHHHHHHH     HHHHHHHHH
	                       
	                       
	                       
	                       
	                       
	                       
	                       

=head2 character_I

          
	          
	IIIIIIIIII
	I::::::::I
	I::::::::I
	II::::::II
	  I::::I  
	  I::::I  
	  I::::I  
	  I::::I  
	  I::::I  
	  I::::I  
	  I::::I  
	  I::::I  
	II::::::II
	I::::::::I
	I::::::::I
	IIIIIIIIII
	          
	          
	          
	          
	          
	          
	          

=head2 character_J

                     
	                     
	          JJJJJJJJJJJ
	          J:::::::::J
	          J:::::::::J
	          JJ:::::::JJ
	            J:::::J  
	            J:::::J  
	            J:::::J  
	            J:::::j  
	            J:::::J  
	JJJJJJJ     J:::::J  
	J:::::J     J:::::J  
	J::::::J   J::::::J  
	J:::::::JJJ:::::::J  
	 JJ:::::::::::::JJ   
	   JJ:::::::::JJ     
	     JJJJJJJJJ       
	                     
	                     
	                     
	                     
	                     
	                     
	                     

=head2 character_K

                    
	                    
	KKKKKKKKK    KKKKKKK
	K:::::::K    K:::::K
	K:::::::K    K:::::K
	K:::::::K   K::::::K
	KK::::::K  K:::::KKK
	  K:::::K K:::::K   
	  K::::::K:::::K    
	  K:::::::::::K     
	  K:::::::::::K     
	  K::::::K:::::K    
	  K:::::K K:::::K   
	KK::::::K  K:::::KKK
	K:::::::K   K::::::K
	K:::::::K    K:::::K
	K:::::::K    K:::::K
	KKKKKKKKK    KKKKKKK
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_L

                        
	                        
	LLLLLLLLLLL             
	L:::::::::L             
	L:::::::::L             
	LL:::::::LL             
	  L:::::L               
	  L:::::L               
	  L:::::L               
	  L:::::L               
	  L:::::L               
	  L:::::L               
	  L:::::L               
	  L:::::L         LLLLLL
	LL:::::::LLLLLLLLL:::::L
	L::::::::::::::::::::::L
	L::::::::::::::::::::::L
	LLLLLLLLLLLLLLLLLLLLLLLL
	                        
	                        
	                        
	                        
	                        
	                        
	                        

=head2 character_M

                               
	                               
	MMMMMMMM               MMMMMMMM
	M:::::::M             M:::::::M
	M::::::::M           M::::::::M
	M:::::::::M         M:::::::::M
	M::::::::::M       M::::::::::M
	M:::::::::::M     M:::::::::::M
	M:::::::M::::M   M::::M:::::::M
	M::::::M M::::M M::::M M::::::M
	M::::::M  M::::M::::M  M::::::M
	M::::::M   M:::::::M   M::::::M
	M::::::M    M:::::M    M::::::M
	M::::::M     MMMMM     M::::::M
	M::::::M               M::::::M
	M::::::M               M::::::M
	M::::::M               M::::::M
	MMMMMMMM               MMMMMMMM
	                               
	                               
	                               
	                               
	                               
	                               
	                               

=head2 character_N

                        
	                        
	NNNNNNNN        NNNNNNNN
	N:::::::N       N::::::N
	N::::::::N      N::::::N
	N:::::::::N     N::::::N
	N::::::::::N    N::::::N
	N:::::::::::N   N::::::N
	N:::::::N::::N  N::::::N
	N::::::N N::::N N::::::N
	N::::::N  N::::N:::::::N
	N::::::N   N:::::::::::N
	N::::::N    N::::::::::N
	N::::::N     N:::::::::N
	N::::::N      N::::::::N
	N::::::N       N:::::::N
	N::::::N        N::::::N
	NNNNNNNN         NNNNNNN
	                        
	                        
	                        
	                        
	                        
	                        
	                        

=head2 character_O

                   
	                   
	     OOOOOOOOO     
	   OO:::::::::OO   
	 OO:::::::::::::OO 
	O:::::::OOO:::::::O
	O::::::O   O::::::O
	O:::::O     O:::::O
	O:::::O     O:::::O
	O:::::O     O:::::O
	O:::::O     O:::::O
	O:::::O     O:::::O
	O:::::O     O:::::O
	O::::::O   O::::::O
	O:::::::OOO:::::::O
	 OO:::::::::::::OO 
	   OO:::::::::OO   
	     OOOOOOOOO     
	                   
	                   
	                   
	                   
	                   
	                   
	                   

=head2 character_P

                    
	                    
	PPPPPPPPPPPPPPPPP   
	P::::::::::::::::P  
	P::::::PPPPPP:::::P 
	PP:::::P     P:::::P
	  P::::P     P:::::P
	  P::::P     P:::::P
	  P::::PPPPPP:::::P 
	  P:::::::::::::PP  
	  P::::PPPPPPPPP    
	  P::::P            
	  P::::P            
	  P::::P            
	PP::::::PP          
	P::::::::P          
	P::::::::P          
	PPPPPPPPPP          
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_Q

                    
	                    
	     QQQQQQQQQ      
	   QQ:::::::::QQ    
	 QQ:::::::::::::QQ  
	Q:::::::QQQ:::::::Q 
	Q::::::O   Q::::::Q 
	Q:::::O     Q:::::Q 
	Q:::::O     Q:::::Q 
	Q:::::O     Q:::::Q 
	Q:::::O     Q:::::Q 
	Q:::::O     Q:::::Q 
	Q:::::O  QQQQ:::::Q 
	Q::::::O Q::::::::Q 
	Q:::::::QQ::::::::Q 
	 QQ::::::::::::::Q  
	   QQ:::::::::::Q   
	     QQQQQQQQ::::QQ 
	             Q:::::Q
	              QQQQQQ
	                    
	                    
	                    
	                    
	                    

=head2 character_R

                    
	                    
	RRRRRRRRRRRRRRRRR   
	R::::::::::::::::R  
	R::::::RRRRRR:::::R 
	RR:::::R     R:::::R
	  R::::R     R:::::R
	  R::::R     R:::::R
	  R::::RRRRRR:::::R 
	  R:::::::::::::RR  
	  R::::RRRRRR:::::R 
	  R::::R     R:::::R
	  R::::R     R:::::R
	  R::::R     R:::::R
	RR:::::R     R:::::R
	R::::::R     R:::::R
	R::::::R     R:::::R
	RRRRRRRR     RRRRRRR
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_S

                   
	                   
	   SSSSSSSSSSSSSSS 
	 SS:::::::::::::::S
	S:::::SSSSSS::::::S
	S:::::S     SSSSSSS
	S:::::S            
	S:::::S            
	 S::::SSSS         
	  SS::::::SSSSS    
	    SSS::::::::SS  
	       SSSSSS::::S 
	            S:::::S
	            S:::::S
	SSSSSSS     S:::::S
	S::::::SSSSSS:::::S
	S:::::::::::::::SS 
	 SSSSSSSSSSSSSSS   
	                   
	                   
	                   
	                   
	                   
	                   
	                   

=head2 character_T

                       
	                       
	TTTTTTTTTTTTTTTTTTTTTTT
	T:::::::::::::::::::::T
	T:::::::::::::::::::::T
	T:::::TT:::::::TT:::::T
	TTTTTT  T:::::T  TTTTTT
	        T:::::T        
	        T:::::T        
	        T:::::T        
	        T:::::T        
	        T:::::T        
	        T:::::T        
	        T:::::T        
	      TT:::::::TT      
	      T:::::::::T      
	      T:::::::::T      
	      TTTTTTTTTTT      
	                       
	                       
	                       
	                       
	                       
	                       
	                       

=head2 character_U

                     
	                     
	UUUUUUUU     UUUUUUUU
	U::::::U     U::::::U
	U::::::U     U::::::U
	UU:::::U     U:::::UU
	 U:::::U     U:::::U 
	 U:::::D     D:::::U 
	 U:::::D     D:::::U 
	 U:::::D     D:::::U 
	 U:::::D     D:::::U 
	 U:::::D     D:::::U 
	 U:::::D     D:::::U 
	 U::::::U   U::::::U 
	 U:::::::UUU:::::::U 
	  UU:::::::::::::UU  
	    UU:::::::::UU    
	      UUUUUUUUU      
	                     
	                     
	                     
	                     
	                     
	                     
	                     

=head2 character_V

                           
	                           
	VVVVVVVV           VVVVVVVV
	V::::::V           V::::::V
	V::::::V           V::::::V
	V::::::V           V::::::V
	 V:::::V           V:::::V 
	  V:::::V         V:::::V  
	   V:::::V       V:::::V   
	    V:::::V     V:::::V    
	     V:::::V   V:::::V     
	      V:::::V V:::::V      
	       V:::::V:::::V       
	        V:::::::::V        
	         V:::::::V         
	          V:::::V          
	           V:::V           
	            VVV            
	                           
	                           
	                           
	                           
	                           
	                           
	                           

=head2 character_W

                                           
	                                           
	WWWWWWWW                           WWWWWWWW
	W::::::W                           W::::::W
	W::::::W                           W::::::W
	W::::::W                           W::::::W
	 W:::::W           WWWWW           W:::::W 
	  W:::::W         W:::::W         W:::::W  
	   W:::::W       W:::::::W       W:::::W   
	    W:::::W     W:::::::::W     W:::::W    
	     W:::::W   W:::::W:::::W   W:::::W     
	      W:::::W W:::::W W:::::W W:::::W      
	       W:::::W:::::W   W:::::W:::::W       
	        W:::::::::W     W:::::::::W        
	         W:::::::W       W:::::::W         
	          W:::::W         W:::::W          
	           W:::W           W:::W           
	            WWW             WWW            
	                                           
	                                           
	                                           
	                                           
	                                           
	                                           
	                                           

=head2 character_X

                     
	                     
	XXXXXXX       XXXXXXX
	X:::::X       X:::::X
	X:::::X       X:::::X
	X::::::X     X::::::X
	XXX:::::X   X:::::XXX
	   X:::::X X:::::X   
	    X:::::X:::::X    
	     X:::::::::X     
	     X:::::::::X     
	    X:::::X:::::X    
	   X:::::X X:::::X   
	XXX:::::X   X:::::XXX
	X::::::X     X::::::X
	X:::::X       X:::::X
	X:::::X       X:::::X
	XXXXXXX       XXXXXXX
	                     
	                     
	                     
	                     
	                     
	                     
	                     

=head2 character_Y

                     
	                     
	YYYYYYY       YYYYYYY
	Y:::::Y       Y:::::Y
	Y:::::Y       Y:::::Y
	Y::::::Y     Y::::::Y
	YYY:::::Y   Y:::::YYY
	   Y:::::Y Y:::::Y   
	    Y:::::Y:::::Y    
	     Y:::::::::Y     
	      Y:::::::Y      
	       Y:::::Y       
	       Y:::::Y       
	       Y:::::Y       
	       Y:::::Y       
	    YYYY:::::YYYY    
	    Y:::::::::::Y    
	    YYYYYYYYYYYYY    
	                     
	                     
	                     
	                     
	                     
	                     
	                     

=head2 character_Z

                   
	                   
	ZZZZZZZZZZZZZZZZZZZ
	Z:::::::::::::::::Z
	Z:::::::::::::::::Z
	Z:::ZZZZZZZZ:::::Z 
	ZZZZZ     Z:::::Z  
	        Z:::::Z    
	       Z:::::Z     
	      Z:::::Z      
	     Z:::::Z       
	    Z:::::Z        
	   Z:::::Z         
	ZZZ:::::Z     ZZZZZ
	Z::::::ZZZZZZZZ:::Z
	Z:::::::::::::::::Z
	Z:::::::::::::::::Z
	ZZZZZZZZZZZZZZZZZZZ
	                   
	                   
	                   
	                   
	                   
	                   
	                   

=head2 character_a

                  
	                  
	                  
	                  
	                  
	                  
	  aaaaaaaaaaaaa   
	  a::::::::::::a  
	  aaaaaaaaa:::::a 
	           a::::a 
	    aaaaaaa:::::a 
	  aa::::::::::::a 
	 a::::aaaa::::::a 
	a::::a    a:::::a 
	a::::a    a:::::a 
	a:::::aaaa::::::a 
	 a::::::::::aa:::a
	  aaaaaaaaaa  aaaa
	                  
	                  
	                  
	                  
	                  
	                  
	                  

=head2 character_b

                    
	bbbbbbbb            
	b::::::b            
	b::::::b            
	b::::::b            
	 b:::::b            
	 b:::::bbbbbbbbb    
	 b::::::::::::::bb  
	 b::::::::::::::::b 
	 b:::::bbbbb:::::::b
	 b:::::b    b::::::b
	 b:::::b     b:::::b
	 b:::::b     b:::::b
	 b:::::b     b:::::b
	 b:::::bbbbbb::::::b
	 b::::::::::::::::b 
	 b:::::::::::::::b  
	 bbbbbbbbbbbbbbbb   
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_c

                    
	                    
	                    
	                    
	                    
	                    
	    cccccccccccccccc
	  cc:::::::::::::::c
	 c:::::::::::::::::c
	c:::::::cccccc:::::c
	c::::::c     ccccccc
	c:::::c             
	c:::::c             
	c::::::c     ccccccc
	c:::::::cccccc:::::c
	 c:::::::::::::::::c
	  cc:::::::::::::::c
	    cccccccccccccccc
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_d

                    
	            dddddddd
	            d::::::d
	            d::::::d
	            d::::::d
	            d:::::d 
	    ddddddddd:::::d 
	  dd::::::::::::::d 
	 d::::::::::::::::d 
	d:::::::ddddd:::::d 
	d::::::d    d:::::d 
	d:::::d     d:::::d 
	d:::::d     d:::::d 
	d:::::d     d:::::d 
	d::::::ddddd::::::dd
	 d:::::::::::::::::d
	  d:::::::::ddd::::d
	   ddddddddd   ddddd
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_e

                    
	                    
	                    
	                    
	                    
	                    
	    eeeeeeeeeeee    
	  ee::::::::::::ee  
	 e::::::eeeee:::::ee
	e::::::e     e:::::e
	e:::::::eeeee::::::e
	e:::::::::::::::::e 
	e::::::eeeeeeeeeee  
	e:::::::e           
	e::::::::e          
	 e::::::::eeeeeeee  
	  ee:::::::::::::e  
	    eeeeeeeeeeeeee  
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_f

                      
	                      
	    ffffffffffffffff  
	   f::::::::::::::::f 
	  f::::::::::::::::::f
	  f::::::fffffff:::::f
	  f:::::f       ffffff
	  f:::::f             
	 f:::::::ffffff       
	 f::::::::::::f       
	 f::::::::::::f       
	 f:::::::ffffff       
	  f:::::f             
	  f:::::f             
	 f:::::::f            
	 f:::::::f            
	 f:::::::f            
	 fffffffff            
	                      
	                      
	                      
	                      
	                      
	                      
	                      

=head2 character_g

                    
	                    
	                    
	                    
	                    
	                    
	   ggggggggg   ggggg
	  g:::::::::ggg::::g
	 g:::::::::::::::::g
	g::::::ggggg::::::gg
	g:::::g     g:::::g 
	g:::::g     g:::::g 
	g:::::g     g:::::g 
	g::::::g    g:::::g 
	g:::::::ggggg:::::g 
	 g::::::::::::::::g 
	  gg::::::::::::::g 
	    gggggggg::::::g 
	            g:::::g 
	gggggg      g:::::g 
	g:::::gg   gg:::::g 
	 g::::::ggg:::::::g 
	  gg:::::::::::::g  
	    ggg::::::ggg    
	       gggggg       

=head2 character_h

                    
	                    
	hhhhhhh             
	h:::::h             
	h:::::h             
	h:::::h             
	 h::::h hhhhh       
	 h::::hh:::::hhh    
	 h::::::::::::::hh  
	 h:::::::hhh::::::h 
	 h::::::h   h::::::h
	 h:::::h     h:::::h
	 h:::::h     h:::::h
	 h:::::h     h:::::h
	 h:::::h     h:::::h
	 h:::::h     h:::::h
	 h:::::h     h:::::h
	 hhhhhhh     hhhhhhh
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_i

        
	        
	  iiii  
	 i::::i 
	  iiii  
	        
	iiiiiii 
	i:::::i 
	 i::::i 
	 i::::i 
	 i::::i 
	 i::::i 
	 i::::i 
	 i::::i 
	i::::::i
	i::::::i
	i::::::i
	iiiiiiii
	        
	        
	        
	        
	        
	        
	        

=head2 character_j

                  
	                  
	             jjjj 
	            j::::j
	             jjjj 
	                  
	           jjjjjjj
	           j:::::j
	            j::::j
	            j::::j
	            j::::j
	            j::::j
	            j::::j
	            j::::j
	            j::::j
	            j::::j
	            j::::j
	            j::::j
	            j::::j
	  jjjj      j::::j
	 j::::jj   j:::::j
	 j::::::jjj::::::j
	  jj::::::::::::j 
	    jjj::::::jjj  
	       jjjjjj     

=head2 character_k

                   
	                   
	kkkkkkkk           
	k::::::k           
	k::::::k           
	k::::::k           
	 k:::::k    kkkkkkk
	 k:::::k   k:::::k 
	 k:::::k  k:::::k  
	 k:::::k k:::::k   
	 k::::::k:::::k    
	 k:::::::::::k     
	 k:::::::::::k     
	 k::::::k:::::k    
	k::::::k k:::::k   
	k::::::k  k:::::k  
	k::::::k   k:::::k 
	kkkkkkkk    kkkkkkk
	                   
	                   
	                   
	                   
	                   
	                   
	                   

=head2 character_l

        
	        
	lllllll 
	l:::::l 
	l:::::l 
	l:::::l 
	 l::::l 
	 l::::l 
	 l::::l 
	 l::::l 
	 l::::l 
	 l::::l 
	 l::::l 
	 l::::l 
	l::::::l
	l::::::l
	l::::::l
	llllllll
	        
	        
	        
	        
	        
	        
	        

=head2 character_m

                        
	                        
	                        
	                        
	                        
	                        
	   mmmmmmm    mmmmmmm   
	 mm:::::::m  m:::::::mm 
	m::::::::::mm::::::::::m
	m::::::::::::::::::::::m
	m:::::mmm::::::mmm:::::m
	m::::m   m::::m   m::::m
	m::::m   m::::m   m::::m
	m::::m   m::::m   m::::m
	m::::m   m::::m   m::::m
	m::::m   m::::m   m::::m
	m::::m   m::::m   m::::m
	mmmmmm   mmmmmm   mmmmmm
	                        
	                        
	                        
	                        
	                        
	                        
	                        

=head2 character_n

                  
	                  
	                  
	                  
	                  
	                  
	nnnn  nnnnnnnn    
	n:::nn::::::::nn  
	n::::::::::::::nn 
	nn:::::::::::::::n
	  n:::::nnnn:::::n
	  n::::n    n::::n
	  n::::n    n::::n
	  n::::n    n::::n
	  n::::n    n::::n
	  n::::n    n::::n
	  n::::n    n::::n
	  nnnnnn    nnnnnn
	                  
	                  
	                  
	                  
	                  
	                  
	                  

=head2 character_o

                 
	                 
	                 
	                 
	                 
	                 
	   ooooooooooo   
	 oo:::::::::::oo 
	o:::::::::::::::o
	o:::::ooooo:::::o
	o::::o     o::::o
	o::::o     o::::o
	o::::o     o::::o
	o::::o     o::::o
	o:::::ooooo:::::o
	o:::::::::::::::o
	 oo:::::::::::oo 
	   ooooooooooo   
	                 
	                 
	                 
	                 
	                 
	                 
	                 

=head2 character_p

                    
	                    
	                    
	                    
	                    
	                    
	ppppp   ppppppppp   
	p::::ppp:::::::::p  
	p:::::::::::::::::p 
	pp::::::ppppp::::::p
	 p:::::p     p:::::p
	 p:::::p     p:::::p
	 p:::::p     p:::::p
	 p:::::p    p::::::p
	 p:::::ppppp:::::::p
	 p::::::::::::::::p 
	 p::::::::::::::pp  
	 p::::::pppppppp    
	 p:::::p            
	 p:::::p            
	p:::::::p           
	p:::::::p           
	p:::::::p           
	ppppppppp           
	                    

=head2 character_q

                    
	                    
	                    
	                    
	                    
	                    
	   qqqqqqqqq   qqqqq
	  q:::::::::qqq::::q
	 q:::::::::::::::::q
	q::::::qqqqq::::::qq
	q:::::q     q:::::q 
	q:::::q     q:::::q 
	q:::::q     q:::::q 
	q::::::q    q:::::q 
	q:::::::qqqqq:::::q 
	 q::::::::::::::::q 
	  qq::::::::::::::q 
	    qqqqqqqq::::::q 
	            q:::::q 
	            q:::::q 
	           q:::::::q
	           q:::::::q
	           q:::::::q
	           qqqqqqqqq
	                    

=head2 character_r

                    
	                    
	                    
	                    
	                    
	                    
	rrrrr   rrrrrrrrr   
	r::::rrr:::::::::r  
	r:::::::::::::::::r 
	rr::::::rrrrr::::::r
	 r:::::r     r:::::r
	 r:::::r     rrrrrrr
	 r:::::r            
	 r:::::r            
	 r:::::r            
	 r:::::r            
	 r:::::r            
	 rrrrrrr            
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_s

                 
	                 
	                 
	                 
	                 
	                 
	    ssssssssss   
	  ss::::::::::s  
	ss:::::::::::::s 
	s::::::ssss:::::s
	 s:::::s  ssssss 
	   s::::::s      
	      s::::::s   
	ssssss   s:::::s 
	s:::::ssss::::::s
	s::::::::::::::s 
	 s:::::::::::ss  
	  sssssssssss    
	                 
	                 
	                 
	                 
	                 
	                 
	                 

=head2 character_t

                       
	                       
	         tttt          
	      ttt:::t          
	      t:::::t          
	      t:::::t          
	ttttttt:::::ttttttt    
	t:::::::::::::::::t    
	t:::::::::::::::::t    
	tttttt:::::::tttttt    
	      t:::::t          
	      t:::::t          
	      t:::::t          
	      t:::::t    tttttt
	      t::::::tttt:::::t
	      tt::::::::::::::t
	        tt:::::::::::tt
	          ttttttttttt  
	                       
	                       
	                       
	                       
	                       
	                       
	                       

=head2 character_u

                  
	                  
	                  
	                  
	                  
	                  
	uuuuuu    uuuuuu  
	u::::u    u::::u  
	u::::u    u::::u  
	u::::u    u::::u  
	u::::u    u::::u  
	u::::u    u::::u  
	u::::u    u::::u  
	u:::::uuuu:::::u  
	u:::::::::::::::uu
	 u:::::::::::::::u
	  uu::::::::uu:::u
	    uuuuuuuu  uuuu
	                  
	                  
	                  
	                  
	                  
	                  
	                  

=head2 character_v

                         
	                         
	                         
	                         
	                         
	                         
	vvvvvvv           vvvvvvv
	 v:::::v         v:::::v 
	  v:::::v       v:::::v  
	   v:::::v     v:::::v   
	    v:::::v   v:::::v    
	     v:::::v v:::::v     
	      v:::::v:::::v      
	       v:::::::::v       
	        v:::::::v        
	         v:::::v         
	          v:::v          
	           vvv           
	                         
	                         
	                         
	                         
	                         
	                         
	                         

=head2 character_w

                                         
	                                         
	                                         
	                                         
	                                         
	                                         
	wwwwwww           wwwww           wwwwwww
	 w:::::w         w:::::w         w:::::w 
	  w:::::w       w:::::::w       w:::::w  
	   w:::::w     w:::::::::w     w:::::w   
	    w:::::w   w:::::w:::::w   w:::::w    
	     w:::::w w:::::w w:::::w w:::::w     
	      w:::::w:::::w   w:::::w:::::w      
	       w:::::::::w     w:::::::::w       
	        w:::::::w       w:::::::w        
	         w:::::w         w:::::w         
	          w:::w           w:::w          
	           www             www           
	                                         
	                                         
	                                         
	                                         
	                                         
	                                         
	                                         

=head2 character_x

                    
	                    
	                    
	                    
	                    
	                    
	xxxxxxx      xxxxxxx
	 x:::::x    x:::::x 
	  x:::::x  x:::::x  
	   x:::::xx:::::x   
	    x::::::::::x    
	     x::::::::x     
	     x::::::::x     
	    x::::::::::x    
	   x:::::xx:::::x   
	  x:::::x  x:::::x  
	 x:::::x    x:::::x 
	xxxxxxx      xxxxxxx
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_y

                         
	                         
	                         
	                         
	                         
	                         
	yyyyyyy           yyyyyyy
	 y:::::y         y:::::y 
	  y:::::y       y:::::y  
	   y:::::y     y:::::y   
	    y:::::y   y:::::y    
	     y:::::y y:::::y     
	      y:::::y:::::y      
	       y:::::::::y       
	        y:::::::y        
	         y:::::y         
	        y:::::y          
	       y:::::y           
	      y:::::y            
	     y:::::y             
	    y:::::y              
	   y:::::y               
	  yyyyyyy                
	                         
	                         

=head2 character_z

                 
	                 
	                 
	                 
	                 
	                 
	zzzzzzzzzzzzzzzzz
	z:::::::::::::::z
	z::::::::::::::z 
	zzzzzzzz::::::z  
	      z::::::z   
	     z::::::z    
	    z::::::z     
	   z::::::z      
	  z::::::zzzzzzzz
	 z::::::::::::::z
	z:::::::::::::::z
	zzzzzzzzzzzzzzzzz
	                 
	                 
	                 
	                 
	                 
	                 
	                 

=head2 character_0

                   
	                   
	     000000000     
	   00:::::::::00   
	 00:::::::::::::00 
	0:::::::000:::::::0
	0::::::0   0::::::0
	0:::::0     0:::::0
	0:::::0     0:::::0
	0:::::0 000 0:::::0
	0:::::0 000 0:::::0
	0:::::0     0:::::0
	0:::::0     0:::::0
	0::::::0   0::::::0
	0:::::::000:::::::0
	 00:::::::::::::00 
	   00:::::::::00   
	     000000000     
	                   
	                   
	                   
	                   
	                   
	                   
	                   

=head2 character_1

            
	            
	  1111111   
	 1::::::1   
	1:::::::1   
	111:::::1   
	   1::::1   
	   1::::1   
	   1::::1   
	   1::::l   
	   1::::l   
	   1::::l   
	   1::::l   
	   1::::l   
	111::::::111
	1::::::::::1
	1::::::::::1
	111111111111
	            
	            
	            
	            
	            
	            
	            

=head2 character_2

                    
	                    
	 222222222222222    
	2:::::::::::::::22  
	2::::::222222:::::2 
	2222222     2:::::2 
	            2:::::2 
	            2:::::2 
	         2222::::2  
	    22222::::::22   
	  22::::::::222     
	 2:::::22222        
	2:::::2             
	2:::::2             
	2:::::2       222222
	2::::::2222222:::::2
	2::::::::::::::::::2
	22222222222222222222
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_3

                   
	                   
	 333333333333333   
	3:::::::::::::::33 
	3::::::33333::::::3
	3333333     3:::::3
	            3:::::3
	            3:::::3
	    33333333:::::3 
	    3:::::::::::3  
	    33333333:::::3 
	            3:::::3
	            3:::::3
	            3:::::3
	3333333     3:::::3
	3::::::33333::::::3
	3:::::::::::::::33 
	 333333333333333   
	                   
	                   
	                   
	                   
	                   
	                   
	                   

=head2 character_4

                  
	                  
	       444444444  
	      4::::::::4  
	     4:::::::::4  
	    4::::44::::4  
	   4::::4 4::::4  
	  4::::4  4::::4  
	 4::::4   4::::4  
	4::::444444::::444
	4::::::::::::::::4
	4444444444:::::444
	          4::::4  
	          4::::4  
	          4::::4  
	        44::::::44
	        4::::::::4
	        4444444444
	                  
	                  
	                  
	                  
	                  
	                  
	                  

=head2 character_5

                   
	                   
	555555555555555555 
	5::::::::::::::::5 
	5::::::::::::::::5 
	5:::::555555555555 
	5:::::5            
	5:::::5            
	5:::::5555555555   
	5:::::::::::::::5  
	555555555555:::::5 
	            5:::::5
	            5:::::5
	5555555     5:::::5
	5::::::55555::::::5
	 55:::::::::::::55 
	   55:::::::::55   
	     555555555     
	                   
	                   
	                   
	                   
	                   
	                   
	                   

=head2 character_6

                   
	                   
	        66666666   
	       6::::::6    
	      6::::::6     
	     6::::::6      
	    6::::::6       
	   6::::::6        
	  6::::::6         
	 6::::::::66666    
	6::::::::::::::66  
	6::::::66666:::::6 
	6:::::6     6:::::6
	6:::::6     6:::::6
	6::::::66666::::::6
	 66:::::::::::::66 
	   66:::::::::66   
	     666666666     
	                   
	                   
	                   
	                   
	                   
	                   
	                   

=head2 character_7

                    
	                    
	77777777777777777777
	7::::::::::::::::::7
	7::::::::::::::::::7
	777777777777:::::::7
	           7::::::7 
	          7::::::7  
	         7::::::7   
	        7::::::7    
	       7::::::7     
	      7::::::7      
	     7::::::7       
	    7::::::7        
	   7::::::7         
	  7::::::7          
	 7::::::7           
	77777777            
	                    
	                    
	                    
	                    
	                    
	                    
	                    

=head2 character_8

                   
	                   
	     888888888     
	   88:::::::::88   
	 88:::::::::::::88 
	8::::::88888::::::8
	8:::::8     8:::::8
	8:::::8     8:::::8
	 8:::::88888:::::8 
	  8:::::::::::::8  
	 8:::::88888:::::8 
	8:::::8     8:::::8
	8:::::8     8:::::8
	8:::::8     8:::::8
	8::::::88888::::::8
	 88:::::::::::::88 
	   88:::::::::88   
	     888888888     
	                   
	                   
	                   
	                   
	                   
	                   
	                   

=head2 character_9

                   
	                   
	     999999999     
	   99:::::::::99   
	 99:::::::::::::99 
	9::::::99999::::::9
	9:::::9     9:::::9
	9:::::9     9:::::9
	 9:::::99999::::::9
	  99::::::::::::::9
	    99999::::::::9 
	         9::::::9  
	        9::::::9   
	       9::::::9    
	      9::::::9     
	     9::::::9      
	    9::::::9       
	   99999999        
	                   
	                   
	                   
	                   
	                   
	                   
	                   

=head1 EXTENDS

=head2 Ascii::Text::Font



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::doh at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Doh>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Doh

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Doh>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Doh>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Doh>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Doh>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
