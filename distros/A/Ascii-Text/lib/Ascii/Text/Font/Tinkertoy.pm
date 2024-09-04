package Ascii::Text::Font::Tinkertoy;
use strict;
use warnings;
use Rope;
use Rope::Autoload;

# Tinker-toy by Wendell Hicken 11/93 (whicken@parasoft.com)

extends 'Ascii::Text::Font';

property character_height => (
	initable  => 0,
	writeable => 0,
	value     => 7
);

function space => sub {
	my (@character) = $_[0]->default_character(5);
	return \@character;
};

function character_A => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = "\/";
	$character[0][2] = "O";
	$character[3][0] = $character[3][4] = "\|";
	$character[1][3] = "\\";
	$character[2][0] = $character[2][4] = $character[4][0] = $character[4][4]
	    = "o";
	$character[2][1] = $character[2][2] = $character[2][3] = "\-";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = "O";
	$character[1][0] = $character[1][4] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[0][0] = $character[0][3] = $character[2][3] = $character[4][0]
	    = $character[4][3] = "o";
	$character[0][1] = $character[0][2] = $character[2][1] = $character[2][2]
	    = $character[4][1] = $character[4][2] = "\-";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(6);
	$character[1][1] = "\/";
	$character[2][0] = "O";
	$character[3][1] = "\\";
	$character[0][2] = $character[0][4] = $character[4][2] = $character[4][4]
	    = "o";
	$character[0][3] = $character[4][3] = "\-";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[2][0] = $character[3][0] = "\|";
	$character[3][3] = "\/";
	$character[2][4] = "O";
	$character[0][1] = $character[4][1] = "\-";
	$character[0][0] = $character[0][2] = $character[4][0] = $character[4][2]
	    = "o";
	$character[1][3] = "\\";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[2][1] = $character[4][1]
	    = $character[4][2] = "\-";
	$character[0][0] = $character[0][3] = $character[2][2] = $character[4][0]
	    = $character[4][3] = "o";
	$character[1][0] = $character[3][0] = "\|";
	$character[2][0] = "O";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[0][3] = $character[2][2] = $character[4][0]
	    = "o";
	$character[0][1] = $character[0][2] = $character[2][1] = "\-";
	$character[1][0] = $character[3][0] = "\|";
	$character[2][0] = "O";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][3] = $character[1][0] = $character[2][4]
	    = $character[3][0] = $character[4][1] = $character[4][3] = "o";
	$character[0][2] = $character[2][3] = $character[4][2] = "\-";
	$character[2][0] = $character[3][4] = "\|";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(5);
	$character[2][1] = $character[2][2] = "\-";
	$character[0][0] = $character[0][3] = $character[4][0] = $character[4][3]
	    = "o";
	$character[2][0] = $character[2][3] = "O";
	$character[1][0] = $character[1][3] = $character[3][0] = $character[3][3]
	    = "\|";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][3] = $character[4][1] = $character[4][3]
	    = "\-";
	$character[0][0] = $character[0][4] = $character[4][0] = $character[4][4]
	    = "o";
	$character[1][2] = $character[2][2] = $character[3][2] = "\|";
	$character[0][2] = $character[4][2] = "O";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(6);
	$character[4][2] = "\-";
	$character[0][4] = $character[3][4] = $character[4][1] = $character[4][3]
	    = "o";
	$character[3][0] = "\\";
	$character[1][4] = $character[2][4] = "\|";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[0][3] = $character[4][0] = $character[4][3]
	    = "o";
	$character[3][2] = "\\";
	$character[1][0] = $character[3][0] = "\|";
	$character[2][0] = $character[2][1] = "O";
	$character[1][2] = "\/";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[4][4] = "o";
	$character[4][1] = $character[4][2] = $character[4][3] = "\-";
	$character[4][0] = "O";
	$character[1][0] = $character[2][0] = $character[3][0] = "\|";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][4] = $character[4][0] = $character[4][4]
	    = "o";
	$character[1][1] = "\\";
	$character[1][0] = $character[1][4] = $character[2][0] = $character[2][4]
	    = $character[3][0] = $character[3][4] = "\|";
	$character[1][3] = "\/";
	$character[2][2] = "O";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][4] = $character[4][0] = $character[4][4]
	    = "o";
	$character[1][1] = $character[2][2] = $character[3][3] = "\\";
	$character[1][0] = $character[1][4] = $character[2][0] = $character[2][4]
	    = $character[3][0] = $character[3][4] = "\|";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = $character[2][4] = "\|";
	$character[0][2] = $character[4][2] = "\-";
	$character[0][1] = $character[0][3] = $character[1][0] = $character[1][4]
	    = $character[3][0] = $character[3][4] = $character[4][1]
	    = $character[4][3] = "o";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][3] = $character[2][3] = $character[4][0]
	    = "o";
	$character[0][1] = $character[0][2] = $character[2][1] = $character[2][2]
	    = "\-";
	$character[2][0] = "O";
	$character[1][0] = $character[1][4] = $character[3][0] = "\|";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][3] = $character[1][0] = $character[1][4]
	    = $character[3][0] = $character[4][1] = "o";
	$character[0][2] = $character[4][2] = "\-";
	$character[4][4] = "\\";
	$character[2][0] = $character[2][4] = "\|";
	$character[3][4] = $character[4][3] = "O";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = $character[2][2] = "O";
	$character[1][0] = $character[1][4] = $character[3][0] = "\|";
	$character[3][3] = "\\";
	$character[0][0] = $character[0][3] = $character[2][3] = $character[4][0]
	    = $character[4][4] = "o";
	$character[0][1] = $character[0][2] = $character[2][1] = "\-";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[2][2] = $character[4][1] = $character[4][2]
	    = "\-";
	$character[0][1] = $character[0][3] = $character[2][1] = $character[2][3]
	    = $character[4][0] = $character[4][3] = "o";
	$character[1][0] = $character[3][4] = "\|";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][4] = $character[4][2] = "o";
	$character[0][1] = $character[0][3] = "\-";
	$character[0][2] = "O";
	$character[1][2] = $character[2][2] = $character[3][2] = "\|";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][4] = $character[2][0] = $character[2][4]
	    = $character[3][0] = $character[3][4] = "\|";
	$character[4][2] = "\-";
	$character[0][0] = $character[0][4] = $character[4][1] = $character[4][3]
	    = "o";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(6);
	$character[3][3] = "\/";
	$character[1][0] = $character[1][4] = "\|";
	$character[3][1] = "\\";
	$character[0][0] = $character[0][4] = $character[2][0] = $character[2][4]
	    = $character[4][2] = "o";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(10);
	$character[1][0] = $character[1][8] = "\|";
	$character[3][3] = $character[3][7] = "\/";
	$character[0][0] = $character[0][8] = $character[2][0] = $character[2][4]
	    = $character[2][8] = $character[4][2] = $character[4][6] = "o";
	$character[3][1] = $character[3][5] = "\\";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(6);
	$character[1][3] = $character[3][1] = "\/";
	$character[2][2] = "O";
	$character[0][0] = $character[0][4] = $character[4][0] = $character[4][4]
	    = "o";
	$character[1][1] = $character[3][3] = "\\";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(6);
	$character[3][2] = "\|";
	$character[2][2] = "O";
	$character[1][3] = "\/";
	$character[0][0] = $character[0][4] = $character[4][2] = "o";
	$character[1][1] = "\\";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(6);
	$character[1][3] = $character[3][1] = "\/";
	$character[2][2] = "O";
	$character[0][1] = $character[0][2] = $character[0][3] = $character[2][1]
	    = $character[2][3] = $character[4][1] = $character[4][2]
	    = $character[4][3] = "\-";
	$character[0][0] = $character[0][4] = $character[4][0] = $character[4][4]
	    = "o";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(4);
	$character[3][0] = $character[3][2] = "\|";
	$character[4][1] = $character[4][3] = "\-";
	$character[2][1] = $character[2][2] = $character[4][0] = $character[4][2]
	    = "o";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(5);
	$character[2][0] = "O";
	$character[1][0] = $character[3][0] = $character[3][3] = "\|";
	$character[2][1] = $character[4][1] = "\-";
	$character[0][0] = $character[2][2] = $character[4][0] = $character[4][2]
	    = "o";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(5);
	$character[3][0] = "\|";
	$character[2][1] = $character[2][3] = $character[4][1] = $character[4][3]
	    = "o";
	$character[2][2] = $character[4][2] = "\-";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(5);
	$character[2][3] = "O";
	$character[1][3] = $character[3][0] = $character[3][3] = "\|";
	$character[2][2] = $character[4][2] = "\-";
	$character[0][3] = $character[2][1] = $character[4][1] = $character[4][3]
	    = "o";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(4);
	$character[2][0] = $character[2][2] = $character[4][0] = $character[4][2]
	    = "o";
	$character[2][1] = $character[3][1] = $character[4][1] = "\-";
	$character[3][0] = "\|";
	$character[3][2] = "\'";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][3] = $character[4][1] = "o";
	$character[0][2] = $character[2][0] = $character[2][2] = "\-";
	$character[2][1] = "O";
	$character[1][1] = $character[3][1] = "\|";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(5);
	$character[4][3] = "O";
	$character[3][0] = $character[3][3] = $character[5][3] = "\|";
	$character[2][0] = $character[2][3] = $character[4][0] = $character[6][0]
	    = $character[6][3] = "o";
	$character[2][1] = $character[2][2] = $character[4][1] = $character[4][2]
	    = $character[6][1] = $character[6][2] = "\-";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(5);
	$character[1][0] = $character[3][0] = $character[3][3] = "\|";
	$character[2][0] = "O";
	$character[2][1] = $character[2][2] = "\-";
	$character[0][0] = $character[2][3] = $character[4][0] = $character[4][3]
	    = "o";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(2);
	$character[3][0] = $character[4][0] = "\|";
	$character[1][0] = "o";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(6);
	$character[4][4] = "\|";
	$character[1][4] = $character[3][4] = $character[5][0] = $character[5][4]
	    = $character[6][1] = $character[6][3] = "o";
	$character[6][2] = "\-";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(5);
	$character[1][0] = $character[3][0] = "\|";
	$character[1][2] = "\/";
	$character[2][0] = $character[2][1] = "O";
	$character[0][0] = $character[4][0] = $character[4][3] = "o";
	$character[3][2] = "\\";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(2);
	$character[0][0] = $character[4][0] = "o";
	$character[1][0] = $character[2][0] = $character[3][0] = "\|";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(6);
	$character[2][1] = $character[2][3] = "\-";
	$character[2][0] = $character[2][4] = $character[4][0] = $character[4][2]
	    = $character[4][4] = "o";
	$character[2][2] = "O";
	$character[3][0] = $character[3][2] = $character[3][4] = "\|";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(5);
	$character[3][0] = $character[3][3] = "\|";
	$character[2][0] = $character[2][2] = $character[4][0] = $character[4][3]
	    = "o";
	$character[2][1] = "\-";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(4);
	$character[3][0] = $character[3][2] = "\|";
	$character[2][0] = $character[2][2] = $character[4][0] = $character[4][2]
	    = "o";
	$character[2][1] = $character[4][1] = "\-";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(5);
	$character[2][1] = $character[4][1] = "\-";
	$character[2][0] = $character[2][2] = $character[4][2] = $character[6][0]
	    = "o";
	$character[4][0] = "O";
	$character[3][0] = $character[3][3] = $character[5][0] = "\|";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(5);
	$character[3][0] = $character[3][3] = $character[5][3] = "\|";
	$character[4][3] = "O";
	$character[2][1] = $character[2][3] = $character[4][1] = $character[6][3]
	    = "o";
	$character[2][2] = $character[4][2] = "\-";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(4);
	$character[2][1] = "\-";
	$character[2][0] = $character[2][2] = $character[4][0] = "o";
	$character[3][0] = "\|";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(4);
	$character[3][1] = "\\";
	$character[2][1] = $character[4][1] = "\-";
	$character[2][0] = $character[2][2] = $character[4][0] = $character[4][2]
	    = "o";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(4);
	$character[1][1] = $character[3][1] = "\|";
	$character[2][0] = $character[2][2] = "\-";
	$character[0][1] = $character[2][1] = $character[4][1] = "o";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(5);
	$character[4][1] = $character[4][2] = "\-";
	$character[2][0] = $character[2][3] = $character[4][0] = $character[4][3]
	    = "o";
	$character[3][0] = $character[3][3] = "\|";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = $character[2][4] = $character[4][2] = "o";
	$character[3][1] = "\\";
	$character[3][3] = "\/";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(9);
	$character[2][0] = $character[2][4] = $character[2][8] = $character[4][2]
	    = $character[4][6] = "o";
	$character[3][1] = $character[3][5] = "\\";
	$character[3][3] = $character[3][7] = "\/";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(4);
	$character[3][1] = "o";
	$character[2][0] = $character[4][2] = "\\";
	$character[2][2] = $character[4][0] = "\/";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(5);
	$character[2][0] = $character[2][3] = $character[4][0] = $character[6][0]
	    = $character[6][3] = "o";
	$character[4][1] = $character[4][2] = $character[6][1] = $character[6][2]
	    = "\-";
	$character[4][3] = "O";
	$character[3][0] = $character[3][3] = $character[5][3] = "\|";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(4);
	$character[3][1] = "\/";
	$character[2][1] = $character[4][1] = "\-";
	$character[2][0] = $character[2][2] = $character[4][0] = $character[4][2]
	    = "o";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[4][2] = "\-";
	$character[0][1] = $character[0][3] = $character[1][0] = $character[1][4]
	    = $character[3][0] = $character[3][4] = $character[4][1]
	    = $character[4][3] = "o";
	$character[1][3] = $character[2][2] = $character[3][1] = "\/";
	$character[2][0] = $character[2][4] = "\|";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = $character[4][0] = $character[4][2] = $character[4][4]
	    = "o";
	$character[0][2] = "0";
	$character[4][1] = $character[4][3] = "\-";
	$character[1][2] = $character[2][2] = $character[3][2] = "\|";
	$character[1][1] = "\/";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[4][1] = $character[4][2]
	    = "\-";
	$character[1][0] = $character[1][3] = $character[4][0] = $character[4][3]
	    = "o";
	$character[2][2] = $character[3][1] = "\/";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[4][1] = "\-";
	$character[0][0] = $character[0][2] = $character[2][1] = $character[2][2]
	    = $character[4][0] = $character[4][2] = "o";
	$character[1][3] = $character[3][3] = "\|";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(5);
	$character[1][0] = $character[1][3] = $character[3][3] = "\|";
	$character[2][3] = "O";
	$character[2][1] = $character[2][2] = "\-";
	$character[0][0] = $character[0][3] = $character[2][0] = $character[4][3]
	    = "o";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[2][1] = $character[4][1]
	    = "\-";
	$character[0][0] = $character[0][3] = $character[2][0] = $character[2][2]
	    = $character[4][0] = $character[4][2] = "o";
	$character[1][0] = $character[3][3] = "\|";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(6);
	$character[3][4] = "\|";
	$character[2][0] = "O";
	$character[1][1] = "\/";
	$character[0][2] = $character[2][3] = $character[3][0] = $character[4][1]
	    = $character[4][3] = "o";
	$character[2][1] = $character[2][2] = $character[4][2] = "\-";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(6);
	$character[3][2] = "\|";
	$character[1][3] = "\/";
	$character[0][1] = $character[0][2] = $character[0][3] = "\-";
	$character[0][0] = $character[0][4] = $character[2][2] = $character[4][2]
	    = "o";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[2][2] = $character[4][2] = "\-";
	$character[0][1] = $character[0][3] = $character[2][1] = $character[2][3]
	    = $character[4][1] = $character[4][3] = "o";
	$character[1][0] = $character[1][4] = $character[3][0] = $character[3][4]
	    = "\|";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][3] = $character[1][4] = $character[2][1]
	    = $character[4][2] = "o";
	$character[0][2] = $character[2][2] = $character[2][3] = "\-";
	$character[1][0] = "\|";
	$character[2][4] = "O";
	$character[3][3] = "\/";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Tinkertoy - Tinkertoy Font

=head1 VERSION

Version 0.13

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	
	use Ascii::Text::Font::Tinkertoy;

	my $foo = Ascii::Text::Font::Tinkertoy->new();

	...

=head1 EXTENDS

=head2 Ascii::Text::Font

=head1 SUBROUTINES/METHODS

=head2 space

=head2 character_A

	  O  
	 / \ 
	o---o
	|   |
	o   o
	     
	     

=head2 character_B

	o--o  
	|   | 
	O--o  
	|   | 
	o--o  
	      
	      

=head2 character_C

	  o-o 
	 /    
	O     
	 \    
	  o-o 
	      
	      

=head2 character_D

	o-o   
	|  \  
	|   O 
	|  /  
	o-o   
	      
	      

=head2 character_E

	o--o 
	|    
	O-o  
	|    
	o--o 
	     
	     

=head2 character_F

	o--o 
	|    
	O-o  
	|    
	o    
	     
	     

=head2 character_G

	 o-o  
	o     
	|  -o 
	o   | 
	 o-o  
	      
	      

=head2 character_H

	o  o 
	|  | 
	O--O 
	|  | 
	o  o 
	     
	     

=head2 character_I

	o-O-o 
	  |   
	  |   
	  |   
	o-O-o 
	      
	      

=head2 character_J

	    o 
	    | 
	    | 
	\   o 
	 o-o  
	      
	      

=head2 character_K

	o  o 
	| /  
	OO   
	| \  
	o  o 
	     
	     

=head2 character_L

	o    
	|    
	|    
	|    
	O---o
	     
	     

=head2 character_M

	o   o 
	|\ /| 
	| O | 
	|   | 
	o   o 
	      
	      

=head2 character_N

	o   o 
	|\  | 
	| \ | 
	|  \| 
	o   o 
	      
	      

=head2 character_O

	 o-o  
	o   o 
	|   | 
	o   o 
	 o-o  
	      
	      

=head2 character_P

	o--o  
	|   | 
	O--o  
	|     
	o     
	      
	      

=head2 character_Q

	 o-o  
	o   o 
	|   | 
	o   O 
	 o-O\ 
	      
	      

=head2 character_R

	o--o  
	|   | 
	O-Oo  
	|  \  
	o   o 
	      
	      

=head2 character_S

	 o-o  
	|     
	 o-o  
	    | 
	o--o  
	      
	      

=head2 character_T

	o-O-o 
	  |   
	  |   
	  |   
	  o   
	      
	      

=head2 character_U

	o   o 
	|   | 
	|   | 
	|   | 
	 o-o  
	      
	      

=head2 character_V

	o   o 
	|   | 
	o   o 
	 \ /  
	  o   
	      
	      

=head2 character_W

	o       o 
	|       | 
	o   o   o 
	 \ / \ /  
	  o   o   
	          
	          

=head2 character_X

	o   o 
	 \ /  
	  O   
	 / \  
	o   o 
	      
	      

=head2 character_Y

	o   o 
	 \ /  
	  O   
	  |   
	  o   
	      
	      

=head2 character_Z

	o---o 
	   /  
	 -O-  
	 /    
	o---o 
	      
	      

=head2 character_a

	    
	    
	 oo 
	| | 
	o-o-
	    
	    

=head2 character_b

	o    
	|    
	O-o  
	|  | 
	o-o  
	     
	     

=head2 character_c

	     
	     
	 o-o 
	|    
	 o-o 
	     
	     

=head2 character_d

	   o 
	   | 
	 o-O 
	|  | 
	 o-o 
	     
	     

=head2 character_e

	    
	    
	o-o 
	|-' 
	o-o 
	    
	    

=head2 character_f

	 o-o
	 |  
	-O- 
	 |  
	 o  
	    
	    

=head2 character_g

	     
	     
	o--o 
	|  | 
	o--O 
	   | 
	o--o 

=head2 character_h

	o    
	|    
	O--o 
	|  | 
	o  o 
	     
	     

=head2 character_i

	  
	o 
	  
	| 
	| 
	  
	  

=head2 character_j

	      
	    o 
	      
	    o 
	    | 
	o   o 
	 o-o  

=head2 character_k

	o    
	| /  
	OO   
	| \  
	o  o 
	     
	     

=head2 character_l

	o 
	| 
	| 
	| 
	o 
	  
	  

=head2 character_m

	      
	      
	o-O-o 
	| | | 
	o o o 
	      
	      

=head2 character_n

	     
	     
	o-o  
	|  | 
	o  o 
	     
	     

=head2 character_o

	    
	    
	o-o 
	| | 
	o-o 
	    
	    

=head2 character_p

	     
	     
	o-o  
	|  | 
	O-o  
	|    
	o    

=head2 character_q

	     
	     
	 o-o 
	|  | 
	 o-O 
	   | 
	   o 

=head2 character_r

	    
	    
	o-o 
	|   
	o   
	    
	    

=head2 character_s

	    
	    
	o-o 
	 \  
	o-o 
	    
	    

=head2 character_t

	 o  
	 |  
	-o- 
	 |  
	 o  
	    
	    

=head2 character_u

	     
	     
	o  o 
	|  | 
	o--o 
	     
	     

=head2 character_v

	      
	      
	o   o 
	 \ /  
	  o   
	      
	      

=head2 character_w

	         
	         
	o   o   o
	 \ / \ / 
	  o   o  
	         
	         

=head2 character_x

	    
	    
	\ / 
	 o  
	/ \ 
	    
	    

=head2 character_y

	     
	     
	o  o 
	|  | 
	o--O 
	   | 
	o--o 

=head2 character_z

	    
	    
	o-o 
	 /  
	o-o 
	    
	    

=head2 character_0

	 o-o  
	o  /o 
	| / | 
	o/  o 
	 o-o  
	      
	      

=head2 character_1

	  0   
	 /|   
	o |   
	  |   
	o-o-o 
	      
	      

=head2 character_2

	 --  
	o  o 
	  /  
	 /   
	o--o 
	     
	     

=head2 character_3

	o-o  
	   | 
	 oo  
	   | 
	o-o  
	     
	     

=head2 character_4

	o  o 
	|  | 
	o--O 
	   | 
	   o 
	     
	     

=head2 character_5

	o--o 
	|    
	o-o  
	   | 
	o-o  
	     
	     

=head2 character_6

	  o   
	 /    
	O--o  
	o   | 
	 o-o  
	      
	      

=head2 character_7

	o---o 
	   /  
	  o   
	  |   
	  o   
	      
	      

=head2 character_8

	 o-o  
	|   | 
	 o-o  
	|   | 
	 o-o  
	      
	      

=head2 character_9

	 o-o  
	|   o 
	 o--O 
	   /  
	  o   
	      
	      

=head1 PROPERTY

=head2 character_height



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::tinkertoy at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Tinkertoy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Tinkertoy

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Tinkertoy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Tinkertoy>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Tinkertoy>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Tinkertoy>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
