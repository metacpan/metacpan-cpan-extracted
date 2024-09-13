package Ascii::Text::Font::Slsscript;
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
	my (@character) = $_[0]->default_character(6);
	return \@character;
};

function character_A => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = $character[2][1] = $character[2][4] = $character[3][0]
	    = "\/";
	$character[2][2] = $character[2][3] = "\-";
	$character[3][3] = "\(";
	$character[0][3] = $character[0][4] = $character[3][4] = "_";
	$character[1][5] = "\)";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(6);
	$character[1][5] = "\)";
	$character[0][3] = $character[0][4] = $character[3][1] = $character[3][2]
	    = $character[3][3] = $character[3][5] = "_";
	$character[2][4] = "\<";
	$character[2][2] = $character[2][3] = "\-";
	$character[1][2] = $character[2][1] = $character[3][0] = $character[3][4]
	    = "\/";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(6);
	$character[3][0] = "\(";
	$character[1][5] = "\)";
	$character[0][3] = $character[0][4] = $character[3][1] = $character[3][2]
	    = "_";
	$character[1][2] = $character[2][1] = $character[3][3] = "\/";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = $character[2][1] = $character[2][4] = $character[3][0]
	    = $character[3][3] = "\/";
	$character[1][5] = "\)";
	$character[0][3] = $character[0][4] = $character[3][1] = $character[3][2]
	    = $character[3][4] = "_";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = $character[2][1] = "\/";
	$character[0][3] = $character[0][4] = $character[3][1] = $character[3][2]
	    = $character[3][3] = "_";
	$character[3][0] = "\(";
	$character[1][5] = "\`";
	$character[3][4] = "\,";
	$character[2][2] = $character[2][3] = "\-";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(8);
	$character[1][4] = $character[2][3] = $character[3][2] = "\/";
	$character[1][7] = "\'";
	$character[0][3] = $character[0][4] = $character[0][5] = $character[0][6]
	    = $character[0][7] = $character[3][1] = "_";
	$character[3][0] = "\(";
	$character[2][2] = $character[2][4] = "\-";
	$character[2][1] = $character[2][5] = "\,";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(7);
	$character[0][3] = "\)";
	$character[1][5] = "\'";
	$character[3][1] = $character[3][2] = $character[3][5] = "_";
	$character[0][2] = "\(";
	$character[1][3] = "\`";
	$character[0][6] = "\,";
	$character[3][4] = "\<";
	$character[1][4] = $character[3][3] = "\-";
	$character[1][2] = $character[2][1] = $character[2][5] = $character[3][0]
	    = "\/";
	$character[1][6] = "\|";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(7);
	$character[3][3] = "\(";
	$character[0][1] = $character[3][4] = "_";
	$character[1][0] = "\'";
	$character[1][2] = "\)";
	$character[0][6] = "\,";
	$character[2][2] = $character[2][3] = "\-";
	$character[1][5] = $character[2][1] = $character[2][4] = $character[3][0]
	    = "\/";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(7);
	$character[2][0] = "\,";
	$character[3][1] = $character[3][5] = "\\";
	$character[2][1] = $character[2][2] = $character[2][3] = "\-";
	$character[1][6] = "\)";
	$character[0][5] = $character[3][2] = $character[3][6] = "_";
	$character[2][5] = $character[3][3] = "\/";
	$character[1][4] = $character[2][4] = "\|";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(6);
	$character[4][0] = "\<";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[2][2]
	    = $character[2][3] = $character[2][5] = $character[4][1] = "_";
	$character[1][5] = "\>";
	$character[1][1] = "\(";
	$character[2][4] = $character[3][1] = $character[3][3] = $character[4][2]
	    = "\/";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(6);
	$character[2][3] = "\<";
	$character[0][5] = "\,";
	$character[2][2] = "\-";
	$character[0][1] = "_";
	$character[1][2] = $character[3][4] = "\)";
	$character[1][0] = "\'";
	$character[1][4] = $character[2][1] = $character[3][0] = "\/";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(4);
	$character[0][3] = $character[1][1] = $character[3][1] = $character[3][2]
	    = $character[3][3] = "_";
	$character[1][2] = $character[1][3] = $character[2][1] = $character[3][0]
	    = "\/";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][3] = $character[0][5] = $character[3][5]
	    = "_";
	$character[1][2] = $character[1][4] = $character[1][6] = "\)";
	$character[1][0] = $character[3][2] = "\'";
	$character[3][4] = "\(";
	$character[2][1] = $character[2][3] = $character[2][5] = $character[3][0]
	    = "\/";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][3] = $character[0][4] = $character[3][4]
	    = "_";
	$character[1][2] = $character[1][5] = "\)";
	$character[1][0] = "\'";
	$character[3][3] = "\(";
	$character[2][1] = $character[2][4] = $character[3][0] = "\/";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(6);
	$character[3][0] = "\(";
	$character[0][3] = $character[0][4] = $character[3][1] = $character[3][2]
	    = "_";
	$character[1][4] = "\'";
	$character[1][5] = "\)";
	$character[1][2] = $character[2][1] = $character[2][4] = $character[3][3]
	    = "\/";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = $character[1][5] = "\)";
	$character[1][0] = $character[2][4] = "\'";
	$character[0][1] = $character[0][3] = $character[0][4] = "_";
	$character[2][2] = $character[2][3] = "\-";
	$character[2][1] = $character[3][0] = "\/";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = $character[2][1] = $character[2][4] = $character[3][3]
	    = "\/";
	$character[3][2] = "\\";
	$character[1][5] = "\)";
	$character[0][3] = $character[0][4] = $character[3][1] = "_";
	$character[3][0] = "\(";
	$character[4][3] = "\`";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[2][4] = "\'";
	$character[1][2] = $character[1][5] = "\)";
	$character[0][1] = $character[0][3] = $character[0][4] = $character[3][4]
	    = "_";
	$character[3][3] = "\\";
	$character[2][2] = $character[2][3] = "\-";
	$character[2][1] = $character[3][0] = "\/";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(6);
	$character[0][2] = "\(";
	$character[0][3] = $character[2][4] = "\)";
	$character[3][1] = $character[3][2] = $character[3][4] = $character[3][5]
	    = "_";
	$character[1][3] = "\\";
	$character[1][2] = $character[2][1] = $character[3][0] = $character[3][3]
	    = "\/";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(8);
	$character[2][1] = $character[2][2] = "\-";
	$character[3][0] = "\(";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5]
	    = $character[0][6] = $character[0][7] = $character[3][1] = "_";
	$character[1][4] = $character[2][3] = $character[3][2] = "\/";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(8);
	$character[3][0] = "\(";
	$character[1][0] = "\'";
	$character[1][2] = "\)";
	$character[0][1] = $character[0][6] = $character[0][7] = $character[3][1]
	    = $character[3][2] = "_";
	$character[1][5] = $character[2][1] = $character[2][4] = $character[3][3]
	    = "\/";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(7);
	$character[1][5] = $character[2][4] = $character[3][3] = "\/";
	$character[0][1] = $character[0][6] = "_";
	$character[1][0] = "\'";
	$character[1][2] = "\)";
	$character[2][1] = "\(";
	$character[3][2] = "\\";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][7] = $character[3][1] = $character[3][3]
	    = "_";
	$character[1][2] = "\)";
	$character[1][0] = "\'";
	$character[3][0] = $character[3][2] = "\(";
	$character[1][6] = $character[2][1] = $character[2][3] = $character[2][5]
	    = $character[3][4] = "\/";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(6);
	$character[2][3] = "X";
	$character[1][0] = "\'";
	$character[0][1] = $character[3][5] = "_";
	$character[1][2] = $character[3][4] = "\\";
	$character[0][5] = "\,";
	$character[1][4] = $character[3][2] = "\/";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(7);
	$character[1][5] = $character[2][1] = $character[2][4] = $character[3][3]
	    = $character[4][1] = $character[4][2] = $character[5][1] = "\/";
	$character[0][1] = $character[3][1] = $character[3][2] = $character[3][4]
	    = "_";
	$character[1][0] = "\'";
	$character[1][2] = "\)";
	$character[3][0] = $character[5][0] = "\(";
	$character[0][6] = "\,";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(3);
	$character[1][2] = $character[2][1] = $character[3][0] = "\/";
	$character[0][0] = $character[0][1] = $character[0][2] = $character[3][1]
	    = $character[3][2] = "_";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(5);
	$character[2][1] = $character[2][2] = $character[3][1] = $character[3][4]
	    = "_";
	$character[3][0] = "\(";
	$character[2][3] = "\.";
	$character[3][2] = "\/";
	$character[3][3] = "\|";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(4);
	$character[3][2] = "\)";
	$character[2][2] = $character[2][3] = $character[3][1] = "_";
	$character[1][2] = $character[2][1] = $character[3][0] = "\/";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(3);
	$character[2][1] = $character[3][1] = $character[3][2] = "_";
	$character[2][2] = "\.";
	$character[3][0] = "\(";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(5);
	$character[1][4] = $character[2][3] = $character[3][2] = "\/";
	$character[3][0] = "\(";
	$character[2][1] = $character[2][2] = $character[3][1] = $character[3][3]
	    = "_";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(3);
	$character[3][0] = "\<";
	$character[2][1] = $character[3][2] = "_";
	$character[3][1] = "\/";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(6);
	$character[1][5] = "\)";
	$character[3][4] = "_";
	$character[4][2] = "\>";
	$character[5][0] = "\<";
	$character[1][4] = $character[2][3] = $character[2][4] = $character[3][2]
	    = $character[3][3] = $character[4][1] = $character[5][1] = "\/";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(4);
	$character[3][0] = "\(";
	$character[2][1] = $character[3][1] = $character[3][3] = "_";
	$character[3][2] = "\)";
	$character[2][2] = "\,";
	$character[4][2] = $character[5][0] = "\|";
	$character[4][1] = $character[5][1] = "\/";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(4);
	$character[1][2] = $character[2][1] = $character[3][0] = $character[3][2]
	    = "\/";
	$character[2][2] = $character[3][3] = "_";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(2);
	$character[2][1] = "o";
	$character[3][0] = "\<";
	$character[3][1] = "_";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(5);
	$character[5][0] = "\-";
	$character[2][4] = "o";
	$character[3][4] = "_";
	$character[5][1] = "\'";
	$character[3][3] = $character[4][2] = "\/";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(4);
	$character[1][2] = $character[2][1] = $character[3][0] = "\/";
	$character[2][2] = $character[3][3] = "_";
	$character[3][2] = "\<";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(4);
	$character[1][2] = $character[1][3] = $character[2][1] = $character[2][2]
	    = $character[3][1] = "\/";
	$character[3][0] = "\<";
	$character[0][3] = $character[3][2] = "_";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(8);
	$character[2][1] = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[2][5] = $character[2][6] = $character[3][7] = "_";
	$character[3][6] = "\<";
	$character[3][0] = $character[3][2] = $character[3][4] = "\/";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(6);
	$character[3][0] = $character[3][2] = "\/";
	$character[3][4] = "\<";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[2][4]
	    = $character[3][5] = "_";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(3);
	$character[2][1] = $character[2][2] = $character[3][1] = "_";
	$character[3][2] = "\)";
	$character[3][0] = "\(";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(6);
	$character[2][3] = $character[3][3] = $character[3][5] = "_";
	$character[5][0] = "\'";
	$character[3][4] = "\)";
	$character[3][2] = $character[4][1] = "\/";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(4);
	$character[2][1] = $character[3][1] = $character[3][3] = "_";
	$character[3][2] = "\)";
	$character[4][2] = "\>";
	$character[3][0] = "\(";
	$character[2][2] = "\,";
	$character[4][1] = $character[5][1] = "\/";
	$character[5][0] = "\|";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(4);
	$character[3][2] = "\(";
	$character[2][1] = $character[2][2] = $character[3][3] = "_";
	$character[3][0] = "\/";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(4);
	$character[3][2] = "\)";
	$character[2][1] = $character[3][1] = $character[3][3] = "_";
	$character[3][0] = "\/";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(4);
	$character[1][1] = $character[1][3] = $character[3][1] = $character[3][2]
	    = "_";
	$character[3][0] = "\<";
	$character[1][2] = $character[2][1] = "\/";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(4);
	$character[2][1] = $character[2][3] = "\.";
	$character[3][0] = "\(";
	$character[3][1] = $character[3][3] = "_";
	$character[3][2] = "\/";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(3);
	$character[2][2] = "_";
	$character[2][0] = "\,";
	$character[3][0] = "\\";
	$character[3][1] = "\/";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(6);
	$character[3][1] = $character[3][3] = $character[3][5] = "_";
	$character[3][0] = $character[3][2] = "\(";
	$character[2][1] = $character[2][3] = $character[2][5] = "\,";
	$character[3][4] = "\/";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(5);
	$character[3][0] = $character[3][2] = "\/";
	$character[2][2] = "\.";
	$character[2][1] = $character[3][4] = "_";
	$character[3][3] = "\\";
	$character[2][3] = "\,";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(6);
	$character[3][0] = $character[3][4] = $character[4][3] = "\/";
	$character[2][5] = "\,";
	$character[3][2] = "\(";
	$character[2][1] = $character[2][2] = $character[3][3] = $character[3][5]
	    = "_";
	$character[5][2] = "\'";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(5);
	$character[2][1] = $character[2][2] = $character[3][4] = "_";
	$character[2][3] = "\.";
	$character[4][2] = "\(";
	$character[3][0] = "\/";
	$character[3][3] = $character[4][3] = "\|";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(6);
	$character[1][2] = $character[2][1] = $character[2][4] = $character[3][3]
	    = "\/";
	$character[1][5] = "\)";
	$character[0][3] = $character[0][4] = $character[3][1] = $character[3][2]
	    = "_";
	$character[3][0] = "\(";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(3);
	$character[0][2] = "_";
	$character[1][2] = $character[2][1] = $character[3][0] = "\/";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(6);
	$character[2][2] = $character[2][3] = "\-";
	$character[0][3] = $character[0][4] = $character[3][1] = $character[3][2]
	    = "_";
	$character[1][5] = "\)";
	$character[2][4] = "\'";
	$character[2][1] = "\.";
	$character[3][0] = "\(";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(6);
	$character[2][4] = $character[3][3] = "\/";
	$character[2][3] = "\-";
	$character[1][5] = "\)";
	$character[0][3] = $character[0][4] = $character[3][0] = $character[3][1]
	    = $character[3][2] = "_";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(5);
	$character[2][0] = "\'";
	$character[2][1] = $character[2][2] = "\-";
	$character[1][1] = $character[1][4] = $character[2][3] = $character[3][2]
	    = "\/";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = "\/";
	$character[2][1] = $character[2][2] = "\-";
	$character[2][0] = "\'";
	$character[3][3] = "\)";
	$character[0][2] = $character[0][3] = $character[0][4] = $character[3][0]
	    = $character[3][1] = $character[3][2] = "_";
	$character[2][3] = "\.";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(4);
	$character[3][0] = "\(";
	$character[2][2] = $character[3][1] = $character[3][2] = "_";
	$character[3][3] = "\)";
	$character[1][2] = $character[2][1] = "\/";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(3);
	$character[0][0] = $character[0][1] = $character[0][2] = "_";
	$character[2][0] = $character[2][2] = "\-";
	$character[1][2] = $character[2][1] = $character[3][0] = "\/";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = $character[3][0] = "\(";
	$character[2][1] = "\.";
	$character[0][2] = $character[0][3] = $character[3][1] = $character[3][2]
	    = "_";
	$character[2][3] = "\'";
	$character[1][4] = $character[3][3] = "\)";
	$character[2][2] = "\/";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(4);
	$character[1][0] = "\(";
	$character[1][3] = "\)";
	$character[0][1] = $character[0][2] = $character[1][1] = $character[1][2]
	    = "_";
	$character[2][2] = $character[3][1] = "\/";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Slsscript - Slsscript Font

=head1 VERSION

Version 0.15

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	
	use Ascii::Text::Font::Slsscript;

	my $foo = Ascii::Text::Font::Slsscript->new();

	...

=head1 EXTENDS

=head2 Ascii::Text::Font

=head1 SUBROUTINES/METHODS

=head2 space

=head2 character_A

	   __ 
	  /  )
	 /--/ 
	/  (_ 
	      
	      

=head2 character_B

	   __ 
	  /  )
	 /--< 
	/___/_
	      
	      

=head2 character_C

	   __ 
	  /  )
	 /    
	(__/  
	      
	      

=head2 character_D

	   __ 
	  /  )
	 /  / 
	/__/_ 
	      
	      

=head2 character_E

	   __ 
	  /  `
	 /--  
	(___, 
	      
	      

=head2 character_F

	   _____
	    /  '
	 ,-/-,  
	(_/     
	        
	        

=head2 character_G

	  ()  ,
	  /`-'|
	 /   / 
	/__-<_ 
	       
	       

=head2 character_H

	 _    ,
	' )  / 
	 /--/  
	/  (_  
	       
	       

=head2 character_I

	     _ 
	    | )
	,---|/ 
	 \_/ \_
	       
	       

=head2 character_J

	  ___ 
	 (   >
	  __/_
	 / /  
	<_/   
	      

=head2 character_K

	 _   ,
	' ) / 
	 /-<  
	/   ) 
	      
	      

=head2 character_L

	   _
	 _//
	 /  
	/___
	    
	    

=head2 character_M

	 _ _ _ 
	' ) ) )
	 / / / 
	/ ' (_ 
	       
	       

=head2 character_N

	 _ __ 
	' )  )
	 /  / 
	/  (_ 
	      
	      

=head2 character_O

	   __ 
	  / ')
	 /  / 
	(__/  
	      
	      

=head2 character_P

	 _ __ 
	' )  )
	 /--' 
	/     
	      
	      

=head2 character_Q

	   __ 
	  /  )
	 /  / 
	(_\/  
	   `  
	      

=head2 character_R

	 _ __ 
	' )  )
	 /--' 
	/  \_ 
	      
	      

=head2 character_S

	  ()  
	  /\  
	 /  ) 
	/__/__
	      
	      

=head2 character_T

	  ______
	    /   
	 --/    
	(_/     
	        
	        

=head2 character_U

	 _    __
	' )  /  
	 /  /   
	(__/    
	        
	        

=head2 character_V

	 _    _
	' )  / 
	 (  /  
	  \/   
	       
	       

=head2 character_W

	 _     _
	' )   / 
	 / / /  
	(_(_/   
	        
	        

=head2 character_X

	 _   ,
	' \ / 
	   X  
	  / \_
	      
	      

=head2 character_Y

	 _    ,
	' )  / 
	 /  /  
	(__/_  
	 //    
	(/     

=head2 character_Z

	___
	  /
	 / 
	/__
	   
	   

=head2 character_a

	     
	     
	 __. 
	(_/|_
	     
	     

=head2 character_b

	    
	  / 
	 /__
	/_) 
	    
	    

=head2 character_c

	   
	   
	 _.
	(__
	   
	   

=head2 character_d

	     
	    /
	 __/ 
	(_/_ 
	     
	     

=head2 character_e

	   
	   
	 _ 
	</_
	   
	   

=head2 character_f

	      
	    /)
	   // 
	  //_ 
	 />   
	</    

=head2 character_g

	    
	    
	 _, 
	(_)_
	 /| 
	|/  

=head2 character_h

	    
	  / 
	 /_ 
	/ /_
	    
	    

=head2 character_i

	  
	  
	 o
	<_
	  
	  

=head2 character_j

	     
	     
	    o
	   /_
	  /  
	-'   

=head2 character_k

	    
	  / 
	 /_ 
	/ <_
	    
	    

=head2 character_l

	   _
	  //
	 // 
	</_ 
	    
	    

=head2 character_m

	        
	        
	 ______ 
	/ / / <_
	        
	        

=head2 character_n

	      
	      
	 ____ 
	/ / <_
	      
	      

=head2 character_o

	   
	   
	 __
	(_)
	   
	   

=head2 character_p

	      
	      
	   _  
	  /_)_
	 /    
	'     

=head2 character_q

	    
	    
	 _, 
	(_)_
	 /> 
	|/  

=head2 character_r

	    
	    
	 __ 
	/ (_
	    
	    

=head2 character_s

	    
	    
	 _  
	/_)_
	    
	    

=head2 character_t

	    
	 _/_
	 /  
	<__ 
	    
	    

=head2 character_u

	    
	    
	 . .
	(_/_
	    
	    

=head2 character_v

	   
	   
	, _
	\/ 
	   
	   

=head2 character_w

	      
	      
	 , , ,
	(_(_/_
	      
	      

=head2 character_x

	     
	     
	 _., 
	/ /\_
	     
	     

=head2 character_y

	      
	      
	 __  ,
	/ (_/_
	   /  
	  '   

=head2 character_z

	     
	     
	 __. 
	/  |_
	  (| 
	     

=head2 character_0

	   __ 
	  /  )
	 /  / 
	(__/  
	      
	      

=head2 character_1

	  _
	  /
	 / 
	/  
	   
	   

=head2 character_2

	   __ 
	     )
	 .--' 
	(__   
	      
	      

=head2 character_3

	   __ 
	     )
	   -/ 
	___/  
	      
	      

=head2 character_4

	     
	 /  /
	'--/ 
	  /  
	     
	     

=head2 character_5

	  ___
	 /   
	'--. 
	___) 
	     
	     

=head2 character_6

	    
	  / 
	 /_ 
	(__)
	    
	    

=head2 character_7

	___
	  /
	-/-
	/  
	   
	   

=head2 character_8

	  __ 
	 (  )
	 ./' 
	(__) 
	     
	     

=head2 character_9

	 __ 
	(__)
	  / 
	 /  
	    
	    

=head1 PROPERTY

=head2 character_height



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::slsscript at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Slsscript>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Slsscript

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Slsscript>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Slsscript>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Slsscript>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Slsscript>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
