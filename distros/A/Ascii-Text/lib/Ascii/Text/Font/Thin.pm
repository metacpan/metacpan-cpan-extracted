package Ascii::Text::Font::Thin;
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
	my (@character) = $_[0]->default_character(5);
	return \@character;
};

function character_A => sub {
	my @character = $_[0]->default_character(6);
	$character[4][0] = "\`";
	$character[4][4] = "\'";
	$character[2][0] = $character[2][4] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[2][1]
	    = $character[2][2] = $character[2][3] = "\-";
	$character[1][4] = "\.";
	$character[1][0] = "\,";
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(6);
	$character[1][4] = $character[2][4] = "\.";
	$character[1][0] = "\,";
	$character[4][0] = "\`";
	$character[2][0] = $character[3][0] = $character[3][4] = "\|";
	$character[4][4] = "\'";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = $character[3][0] = "\|";
	$character[4][4] = "\'";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[4][0] = "\`";
	$character[1][4] = "\.";
	$character[1][0] = "\,";
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = $character[2][4] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[4][3] = "\'";
	$character[1][1] = $character[1][2] = $character[4][1] = $character[4][2]
	    = "\-";
	$character[4][0] = "\`";
	$character[1][3] = "\.";
	$character[1][0] = "\,";
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(6);
	$character[1][1] = $character[1][2] = $character[1][3] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[4][4] = "\'";
	$character[2][0] = $character[3][0] = "\|";
	$character[4][0] = "\`";
	$character[1][0] = "\,";
	$character[1][4] = "\.";
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(6);
	$character[4][0] = "\`";
	$character[1][1] = $character[1][2] = $character[1][3] = "\-";
	$character[2][0] = $character[3][0] = "\|";
	$character[1][0] = "\,";
	$character[1][4] = $character[2][3] = "\.";
	$character[2][1] = $character[2][2] = "_";
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(6);
	$character[2][3] = "_";
	$character[1][4] = $character[2][4] = "\.";
	$character[1][0] = "\,";
	$character[2][0] = $character[3][0] = $character[3][4] = "\|";
	$character[4][4] = "\'";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[4][0] = "\`";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][4] = $character[2][0] = $character[2][4]
	    = $character[3][0] = $character[3][4] = "\|";
	$character[4][4] = "\'";
	$character[2][1] = $character[2][2] = $character[2][3] = "\-";
	$character[4][0] = "\`";
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(2);
	$character[1][0] = $character[2][0] = $character[3][0] = "\|";
	$character[4][0] = "\`";
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(6);
	$character[4][0] = "\`";
	$character[4][1] = $character[4][2] = $character[4][3] = "\-";
	$character[4][4] = "\'";
	$character[1][4] = $character[2][4] = $character[3][4] = "\|";
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[2][0] = $character[3][0] = "\|";
	$character[4][0] = $character[4][4] = "\`";
	$character[2][1] = $character[2][2] = "_";
	$character[1][4] = $character[2][3] = "\/";
	$character[3][3] = "\\";
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(6);
	$character[4][1] = $character[4][2] = $character[4][3] = "\-";
	$character[4][4] = "\'";
	$character[1][0] = $character[2][0] = $character[3][0] = "\|";
	$character[4][0] = "\`";
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = "\,";
	$character[1][2] = $character[1][4] = "\.";
	$character[4][0] = "\`";
	$character[1][1] = $character[1][3] = "\-";
	$character[4][2] = $character[4][4] = "\'";
	$character[2][0] = $character[2][2] = $character[2][4] = $character[3][0]
	    = $character[3][2] = $character[3][4] = "\|";
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = $character[2][4] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[4][4] = "\'";
	$character[4][0] = $character[4][3] = "\`";
	$character[1][4] = "\.";
	$character[2][1] = $character[3][2] = "\\";
	$character[1][0] = "\,";
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = "\,";
	$character[1][4] = "\.";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[4][4] = "\'";
	$character[2][0] = $character[2][4] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[4][0] = "\`";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = "\,";
	$character[1][4] = "\.";
	$character[4][0] = "\`";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[2][1]
	    = $character[2][2] = $character[2][3] = "\-";
	$character[2][0] = $character[3][0] = "\|";
	$character[2][4] = "\'";
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(6);
	$character[1][4] = "\.";
	$character[1][0] = "\,";
	$character[4][4] = "\\";
	$character[2][0] = $character[2][4] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[4][0] = "\`";
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(6);
	$character[3][3] = "\\";
	$character[1][0] = "\,";
	$character[1][4] = "\.";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[2][1]
	    = $character[2][2] = $character[2][3] = "\-";
	$character[2][0] = $character[3][0] = "\|";
	$character[2][4] = "\'";
	$character[4][0] = $character[4][4] = "\`";
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(6);
	$character[1][1] = $character[1][2] = $character[1][3] = $character[2][1]
	    = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[4][4] = "\'";
	$character[3][4] = "\|";
	$character[2][0] = $character[4][0] = "\`";
	$character[1][0] = "\,";
	$character[1][4] = $character[2][4] = "\.";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][1] = $character[1][3] = $character[1][4]
	    = "\-";
	$character[2][2] = $character[3][2] = "\|";
	$character[4][2] = "\`";
	$character[1][2] = "\.";
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = $character[2][4] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[4][4] = "\'";
	$character[4][1] = $character[4][2] = $character[4][3] = "\-";
	$character[4][0] = "\`";
	$character[1][0] = $character[1][4] = "\.";
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(7);
	$character[4][3] = "\'";
	$character[2][0] = $character[2][5] = "\|";
	$character[4][2] = "\`";
	$character[3][4] = "\/";
	$character[3][1] = "\\";
	$character[1][5] = "\,";
	$character[1][0] = "\.";
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(6);
	$character[4][0] = "\`";
	$character[2][0] = $character[2][2] = $character[2][4] = $character[3][0]
	    = $character[3][2] = $character[3][4] = "\|";
	$character[4][2] = $character[4][4] = "\'";
	$character[4][1] = $character[4][3] = "\-";
	$character[1][0] = $character[1][2] = $character[1][4] = "\.";
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(5);
	$character[4][0] = "\'";
	$character[3][0] = $character[3][3] = "\|";
	$character[4][3] = "\`";
	$character[2][2] = "\<";
	$character[1][3] = "\,";
	$character[1][0] = "\.";
	$character[2][1] = "\>";
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(6);
	$character[1][4] = "\.";
	$character[1][0] = "\,";
	$character[2][0] = $character[2][4] = $character[4][2] = "\|";
	$character[3][4] = "\'";
	$character[3][1] = $character[3][2] = $character[3][3] = "\-";
	$character[3][0] = $character[5][2] = "\`";
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[1][4] = "\,";
	$character[2][1] = "\.";
	$character[1][1] = $character[1][2] = $character[1][3] = $character[2][2]
	    = $character[4][1] = $character[4][2] = $character[4][3] = "\-";
	$character[3][0] = "\|";
	$character[2][3] = $character[4][4] = "\'";
	$character[4][0] = "\`";
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(6);
	$character[2][4] = "\.";
	$character[2][0] = $character[3][0] = "\,";
	$character[4][0] = "\`";
	$character[4][4] = "\^";
	$character[3][4] = "\|";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(6);
	$character[2][4] = "\.";
	$character[1][0] = $character[2][0] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[4][4] = "\'";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[4][0] = "\`";
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(6);
	$character[4][0] = "\`";
	$character[3][0] = "\|";
	$character[4][4] = "\'";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[2][4] = "\.";
	$character[2][0] = "\,";
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = "\,";
	$character[4][0] = "\`";
	$character[1][4] = $character[2][4] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[4][4] = "\'";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(6);
	$character[3][0] = "\|";
	$character[3][4] = $character[4][4] = "\'";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[4][0] = "\`";
	$character[2][4] = "\.";
	$character[2][0] = "\,";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(6);
	$character[1][4] = $character[2][3] = "\.";
	$character[1][0] = "\,";
	$character[2][1] = $character[2][2] = "_";
	$character[4][0] = "\`";
	$character[2][0] = $character[3][0] = "\|";
	$character[1][1] = $character[1][2] = $character[1][3] = "\-";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = "\,";
	$character[2][4] = "\.";
	$character[4][0] = $character[5][0] = "\`";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = $character[5][1]
	    = $character[5][2] = $character[5][3] = "\-";
	$character[5][4] = "\'";
	$character[3][0] = $character[3][4] = $character[4][4] = "\|";
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(6);
	$character[2][4] = "\.";
	$character[1][0] = $character[2][0] = $character[3][0] = $character[3][4]
	    = "\|";
	$character[4][4] = "\'";
	$character[2][1] = $character[2][2] = $character[2][3] = "\-";
	$character[4][0] = "\`";
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(2);
	$character[1][0] = "o";
	$character[2][0] = "\.";
	$character[3][0] = "\|";
	$character[4][0] = "\`";
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(6);
	$character[5][0] = "\`";
	$character[5][1] = $character[5][2] = $character[5][3] = "\-";
	$character[5][4] = "\'";
	$character[3][4] = $character[4][4] = "\|";
	$character[2][4] = "\.";
	$character[1][4] = "o";
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(6);
	$character[4][0] = $character[4][4] = "\`";
	$character[1][0] = $character[2][0] = $character[3][0] = "\|";
	$character[3][3] = "\\";
	$character[2][1] = $character[2][2] = "_";
	$character[2][3] = "\/";
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[2][0] = $character[3][0] = "\|";
	$character[4][4] = "\'";
	$character[4][1] = $character[4][2] = $character[4][3] = "\-";
	$character[4][0] = "\`";
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(6);
	$character[2][2] = $character[2][4] = "\.";
	$character[2][0] = "\,";
	$character[4][0] = "\`";
	$character[3][0] = $character[3][2] = $character[3][4] = "\|";
	$character[4][2] = $character[4][4] = "\'";
	$character[2][1] = $character[2][3] = "\-";
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = "\,";
	$character[2][4] = "\.";
	$character[4][0] = "\`";
	$character[2][1] = $character[2][2] = $character[2][3] = "\-";
	$character[4][4] = "\'";
	$character[3][0] = $character[3][4] = "\|";
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = "\,";
	$character[2][4] = "\.";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[4][4] = "\'";
	$character[3][0] = $character[3][4] = "\|";
	$character[4][0] = "\`";
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(6);
	$character[3][0] = $character[3][4] = $character[4][0] = $character[5][0]
	    = "\|";
	$character[4][4] = "\'";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[2][4] = "\.";
	$character[2][0] = "\,";
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = "\,";
	$character[2][4] = "\.";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[3][0] = $character[3][4] = $character[4][4] = $character[5][4]
	    = "\|";
	$character[4][0] = "\`";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = "\,";
	$character[2][4] = "\.";
	$character[2][1] = $character[2][2] = $character[2][3] = "\-";
	$character[3][0] = "\|";
	$character[4][0] = "\`";
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(6);
	$character[4][4] = "\'";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[3][1]
	    = $character[3][2] = $character[3][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[3][0] = $character[4][0] = "\`";
	$character[2][4] = $character[3][4] = "\.";
	$character[2][0] = "\,";
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[2][0] = $character[3][0] = "\|";
	$character[4][4] = "\'";
	$character[2][1] = $character[2][2] = $character[2][3] = $character[4][1]
	    = $character[4][2] = $character[4][3] = "\-";
	$character[4][0] = "\`";
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(6);
	$character[4][1] = $character[4][2] = $character[4][3] = "\-";
	$character[4][4] = "\'";
	$character[3][0] = $character[3][4] = "\|";
	$character[4][0] = "\`";
	$character[2][0] = $character[2][4] = "\.";
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(7);
	$character[4][3] = "\'";
	$character[4][2] = "\`";
	$character[3][4] = "\/";
	$character[2][0] = "\.";
	$character[3][1] = "\\";
	$character[2][5] = "\,";
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(6);
	$character[2][0] = $character[2][2] = $character[2][4] = "\.";
	$character[4][0] = "\`";
	$character[3][0] = $character[3][2] = $character[3][4] = "\|";
	$character[4][2] = $character[4][4] = "\'";
	$character[4][1] = $character[4][3] = "\-";
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(5);
	$character[3][2] = "\<";
	$character[2][3] = "\,";
	$character[2][0] = "\.";
	$character[3][1] = "\>";
	$character[4][0] = "\'";
	$character[4][3] = "\`";
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(6);
	$character[2][4] = "\.";
	$character[2][0] = "\,";
	$character[3][0] = $character[3][4] = $character[4][4] = "\|";
	$character[5][4] = "\'";
	$character[4][1] = $character[4][2] = $character[4][3] = $character[5][1]
	    = $character[5][2] = $character[5][3] = "\-";
	$character[4][0] = $character[5][0] = "\`";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(6);
	$character[2][1] = $character[2][2] = $character[2][3] = $character[3][2]
	    = $character[4][1] = $character[4][2] = $character[4][3] = "\-";
	$character[3][3] = $character[4][0] = $character[4][4] = "\'";
	$character[2][0] = $character[2][4] = "\,";
	$character[3][1] = "\.";
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = $character[1][2] = $character[4][1] = $character[4][2]
	    = "\-";
	$character[4][3] = "\'";
	$character[2][0] = $character[2][3] = $character[3][0] = $character[3][3]
	    = "\|";
	$character[4][0] = "\`";
	$character[1][0] = "\,";
	$character[1][3] = "\.";
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(4);
	$character[4][2] = "\`";
	$character[1][1] = "\'";
	$character[1][2] = $character[2][2] = $character[3][2] = "\|";
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(5);
	$character[4][0] = "\`";
	$character[1][1] = $character[1][2] = $character[2][1] = $character[2][2]
	    = $character[4][1] = $character[4][2] = "\-";
	$character[2][3] = $character[4][3] = "\'";
	$character[3][0] = "\|";
	$character[1][0] = $character[2][0] = "\,";
	$character[1][3] = "\.";
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(5);
	$character[4][0] = "\`";
	$character[2][3] = $character[3][3] = "\|";
	$character[4][3] = "\'";
	$character[1][1] = $character[1][2] = $character[2][2] = $character[4][1]
	    = $character[4][2] = "\-";
	$character[1][3] = "\.";
	$character[1][0] = "\,";
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(5);
	$character[1][0] = $character[1][3] = $character[2][3] = $character[3][3]
	    = "\|";
	$character[2][1] = $character[2][2] = "\-";
	$character[2][0] = $character[4][3] = "\`";
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(5);
	$character[1][3] = $character[2][3] = "\.";
	$character[3][3] = "\|";
	$character[4][3] = "\'";
	$character[1][0] = $character[1][1] = $character[1][2] = $character[2][1]
	    = $character[2][2] = $character[4][1] = $character[4][2] = "\-";
	$character[2][0] = $character[4][0] = "\`";
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(5);
	$character[2][0] = $character[3][0] = $character[3][3] = "\|";
	$character[4][3] = "\'";
	$character[1][1] = $character[1][2] = $character[2][1] = $character[2][2]
	    = $character[4][1] = $character[4][2] = "\-";
	$character[4][0] = "\`";
	$character[1][3] = $character[2][3] = "\.";
	$character[1][0] = "\,";
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(5);
	$character[1][3] = "\.";
	$character[2][3] = "\/";
	$character[3][2] = $character[4][2] = "\|";
	$character[1][0] = $character[1][1] = $character[1][2] = "\-";
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(5);
	$character[3][0] = $character[3][3] = "\|";
	$character[4][3] = "\'";
	$character[1][1] = $character[1][2] = $character[2][1] = $character[2][2]
	    = $character[4][1] = $character[4][2] = "\-";
	$character[4][0] = "\`";
	$character[1][3] = $character[2][3] = "\.";
	$character[1][0] = $character[2][0] = "\,";
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(5);
	$character[2][0] = "\`";
	$character[2][3] = $character[3][3] = "\|";
	$character[4][3] = "\'";
	$character[1][1] = $character[1][2] = "\-";
	$character[1][3] = "\.";
	$character[1][0] = "\,";
	$character[2][1] = $character[2][2] = "_";
	$character[5][0] = "\
";
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Thin - Thin Font

=head1 VERSION

Version 0.21

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
	
	use Ascii::Text::Font::Thin;

	my $foo = Ascii::Text::Font::Thin->new();

	...

=head1 EXTENDS

=head2 Ascii::Text::Font

=head1 SUBROUTINES/METHODS

=head2 space

=head2 character_A

	     
	,---.
	|---|
	|   |
	`   '
	     

=head2 character_B

	     
	,---.
	|---.
	|   |
	`---'
	     

=head2 character_C

	     
	,---.
	|    
	|    
	`---'
	     

=head2 character_D

	     
	,--. 
	|   |
	|   |
	`--' 
	     

=head2 character_E

	     
	,---.
	|--- 
	|    
	`---'
	     

=head2 character_F

	     
	,---.
	|__. 
	|    
	`    
	     

=head2 character_G

	     
	,---.
	|  _.
	|   |
	`---'
	     

=head2 character_H

	     
	|   |
	|---|
	|   |
	`   '
	     

=head2 character_I

	 
	|
	|
	|
	`
	 

=head2 character_J

	     
	    |
	    |
	    |
	`---'
	     

=head2 character_K

	     
	|   /
	|__/ 
	|  \ 
	`   `
	     

=head2 character_L

	     
	|    
	|    
	|    
	`---'
	     

=head2 character_M

	     
	,-.-.
	| | |
	| | |
	` ' '
	     

=head2 character_N

	     
	,   .
	|\  |
	| \ |
	`  `'
	     

=head2 character_O

	     
	,---.
	|   |
	|   |
	`---'
	     

=head2 character_P

	     
	,---.
	|---'
	|    
	`    
	     

=head2 character_Q

	     
	,---.
	|   |
	|   |
	`---\
	     

=head2 character_R

	     
	,---.
	|---'
	|  \ 
	`   `
	     

=head2 character_S

	     
	,---.
	`---.
	    |
	`---'
	     

=head2 character_T

	     
	--.--
	  |  
	  |  
	  `  
	     

=head2 character_U

	     
	.   .
	|   |
	|   |
	`---'
	     

=head2 character_V

	      
	.    ,
	|    |
	 \  / 
	  `'  
	      

=head2 character_W

	     
	. . .
	| | |
	| | |
	`-'-'
	     

=head2 character_X

	    
	.  ,
	 >< 
	|  |
	'  `
	    

=head2 character_Y

	     
	,   .
	|   |
	`---'
	  |  
	  `  

=head2 character_Z

	     
	,---,
	 .-' 
	|    
	`---'
	     

=head2 character_a

	     
	     
	,---.
	,---|
	`---^
	     

=head2 character_b

	     
	|    
	|---.
	|   |
	`---'
	     

=head2 character_c

	     
	     
	,---.
	|    
	`---'
	     

=head2 character_d

	     
	    |
	,---|
	|   |
	`---'
	     

=head2 character_e

	     
	     
	,---.
	|---'
	`---'
	     

=head2 character_f

	     
	,---.
	|__. 
	|    
	`    
	     

=head2 character_g

	     
	     
	,---.
	|   |
	`---|
	`---'

=head2 character_h

	     
	|    
	|---.
	|   |
	`   '
	     

=head2 character_i

	 
	o
	.
	|
	`
	 

=head2 character_j

	     
	    o
	    .
	    |
	    |
	`---'

=head2 character_k

	     
	|    
	|__/ 
	|  \ 
	`   `
	     

=head2 character_l

	     
	|    
	|    
	|    
	`---'
	     

=head2 character_m

	     
	     
	,-.-.
	| | |
	` ' '
	     

=head2 character_n

	     
	     
	,---.
	|   |
	`   '
	     

=head2 character_o

	     
	     
	,---.
	|   |
	`---'
	     

=head2 character_p

	     
	     
	,---.
	|   |
	|---'
	|    

=head2 character_q

	     
	     
	,---.
	|   |
	`---|
	    |

=head2 character_r

	     
	     
	,---.
	|    
	`    
	     

=head2 character_s

	     
	     
	,---.
	`---.
	`---'
	     

=head2 character_t

	     
	|    
	|--- 
	|    
	`---'
	     

=head2 character_u

	     
	     
	.   .
	|   |
	`---'
	     

=head2 character_v

	      
	      
	.    ,
	 \  / 
	  `'  
	      

=head2 character_w

	     
	     
	. . .
	| | |
	`-'-'
	     

=head2 character_x

	    
	    
	.  ,
	 >< 
	'  `
	    

=head2 character_y

	     
	     
	,   .
	|   |
	`---|
	`---'

=head2 character_z

	     
	     
	,---,
	 .-' 
	'---'
	     

=head2 character_0

	    
	,--.
	|  |
	|  |
	`--'
	    

=head2 character_1

	   
	 '|
	  |
	  |
	  `
	   

=head2 character_2

	    
	,--.
	,--'
	|   
	`--'
	    

=head2 character_3

	    
	,--.
	  -|
	   |
	`--'
	    

=head2 character_4

	    
	|  |
	`--|
	   |
	   `
	    

=head2 character_5

	    
	---.
	`--.
	   |
	`--'
	    

=head2 character_6

	    
	,--.
	|--.
	|  |
	`--'
	    

=head2 character_7

	    
	---.
	   /
	  | 
	  | 
	    

=head2 character_8

	    
	,--.
	,--.
	|  |
	`--'
	    

=head2 character_9

	    
	,--.
	`__|
	   |
	   '
	


=head1 PROPERTY

=head2 character_height



=head1 AUTHOR

AUTHOR, C<< <EMAIL> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii::text::font::thin at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Font-Thin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Font::Thin

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Font-Thin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ascii-Text-Font-Thin>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ascii-Text-Font-Thin>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Font-Thin>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by AUTHOR.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
