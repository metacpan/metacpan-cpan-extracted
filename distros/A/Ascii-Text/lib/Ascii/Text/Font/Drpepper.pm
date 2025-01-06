package Ascii::Text::Font::Drpepper;

use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable => 0,
	writable => 0,
	value => 5
);

function character_A => sub {
	my @character = $_[0]->default_character(5);

        $character[1][0] = $character[1][4] = $character[2][0] = $character[2][4] = $character[3][0] = $character[3][2] = $character[3][4] = '|';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[3][1] = $character[3][3] = '_';
        $character[1][2] = '.';

	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[0][4] = $character[1][1] = $character[1][3] = $character[2][1] = $character[2][3] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = $character[2][0] = $character[3][0] = '|';
        $character[1][2] = $character[2][2] = '.';
        $character[1][4] = '>';
        $character[2][4] = '\\';
        $character[3][4] = '/';
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(5);
        $character[0][0] = $character[0][4] = $character[1][1] = $character[1][2] = $character[2][1] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[1][3] = $character[2][3] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = $character[2][0] = '|';
        $character[1][4] = '>';
        $character[2][2] = '<';
        $character[3][0] = '`';
        $character[3][4] = '/';
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[0][4] = $character[1][1] = $character[1][3] = $character[2][1] = $character[2][3] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = $character[2][0] = $character[2][2] = $character[2][4] = $character[3][0] = '|';
        $character[1][2] = '.';
        $character[1][4] = '\\';
        $character[3][4] = '/';
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(5);
        $character[0][0] = $character[0][4] = $character[1][1] = $character[2][1] = $character[2][4] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[1][2] = $character[1][3] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = $character[2][0] = $character[3][0] = '|';
        $character[1][4] = $character[2][3] = $character[3][4] = '>';
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[0][2] = $character[0][3] = $character[1][2] = $character[1][3] = $character[2][2] = $character[3][1] = '_';
        $character[1][0] = $character[2][0] = $character[3][0] = $character[3][2] = '|';
        $character[1][4] = $character[2][3] = '>';
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][3] = $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] =  '_';
	$character[1][0] = "/";
	$character[1][4] = '>';
	$character[2][0] = "|";
	$character[2][2] = "<";
	$character[2][4] = $character[3][5] = "/";
	$character[2][5] = "\\";
	$character[3][0] = "`";
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(5);
        $character[1][0] = $character[1][2] = $character[1][4] = $character[2][0] = $character[2][4] = $character[3][0] = $character[3][2] = $character[3][4] = '|';
        $character[0][1] = $character[0][3] = $character[3][1] = $character[3][3] = '_';
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(3);
        $character[0][0] = $character[0][2] = $character[1][1] = $character[2][1] = $character[4][0] = $character[4][1] = $character[4][2] = ' ';
        $character[0][1] = $character[3][1] = '_';
        $character[1][0] = $character[1][2] = $character[2][0] = $character[2][2] = $character[3][0] = $character[3][2] = '|';
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(5);
        $character[1][1] = $character[1][3] = $character[2][1] = $character[2][3] = '|';
        $character[2][0] = $character[3][1] = $character[3][2] = $character[0][2] = '_';
        $character[3][0] = '\\';
        $character[3][3] = '/';
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[0][3] = $character[0][4] = $character[3][1] = $character[3][3] = '_';
        $character[1][0] = $character[2][0] = $character[3][0] = '|';
        $character[1][2] = $character[1][4] = '/';
        $character[2][3] = $character[3][2] = $character[3][4] = '\\';
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = $character[1][2] = $character[2][0] = $character[2][2] = $character[3][0] = $character[3][4] = '|';
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(7);
        $character[0][1] = $character[0][2] = $character[0][4] = $character[0][5] = $character[3][1] = $character[3][3] = $character[3][5] = '_';
        $character[1][0] = $character[2][0] = $character[2][6] = $character[3][0] = $character[3][2] = $character[3][4] = $character[3][6] = '|';
        $character[1][3] = $character[1][6] = '\\';
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1]  = $character[0][3] = $character[3][1] = $character[3][3]  = '_';
        $character[1][0] = $character[2][0] = $character[3][0] =$character[1][4]=$character[2][4]=$character[3][4] = '|';
        $character[1][2] = $character[3][2] = '\\';
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[3][1] = $character[3][2] = $character[3][3] = "_";
	$character[1][0] = $character[1][4] = $character[2][0] = $character[2][2] = $character[2][4] = "|";
	$character[1][2] = ".";
	$character[3][0] = "`";
	$character[3][4] = "'";
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(5);
        $character[0][0] = $character[0][4] = $character[1][1] = $character[1][3] = $character[2][1] = $character[2][2] = $character[3][3] = $character[3][4] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] =  $character[2][3] = $character[3][1] = '_';
        $character[1][0] = $character[2][0] = $character[3][0] = $character[3][2] = '|';
        $character[1][2] = '.';
        $character[1][4] = '\\';
        $character[2][4] = '/';
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(5);
        $character[0][0] = $character[0][4] = $character[1][1] = $character[1][3] = $character[2][1] = $character[2][3] = $character[4][0] = $character[4][1] = $character[4][2] = $character[4][3] = $character[4][4] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = $character[1][4] = $character[2][0] = $character[2][2] = $character[2][4] = '|';
        $character[1][2] = '.';
        $character[3][0] = '`';
        $character[3][4] = '\\';
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[0][2] = $character[0][3] = $character[3][1] = $character[3][3] = '_';
        $character[1][0] = $character[2][0] = $character[3][0] = '|';
        $character[1][2] = '.';
        $character[1][4] = $character[3][2] = $character[3][4] = '\\';
        $character[2][4] = '/';
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[0][2] = $character[1][2] = $character[1][1] = $character[3][2] = $character[3][1] = $character[2][1] = $character[0][3] = $character[1][3] = $character[3][3] = $character[2][2] = '_';
        $character[3][4] = $character[1][0] = '/';
        $character[1][4] = '>';
        $character[3][0] = '<';
        $character[2][0] = $character[2][4] = "\\";
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[0][2] = $character[0][3] = $character[1][1] = $character[1][3] = $character[3][2] = '_';
        $character[1][0] = $character[1][4] = $character[2][1] = $character[2][3] = $character[3][1] = $character[3][3] = '|';
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][3] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[1][4] = $character[1][2] = $character[2][0] = $character[2][4] = '|';
	$character[2][2] = $character[3][4] = '\'';
	$character[3][0] = '`';
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[0][3] = $character[3][1] = $character[3][2] = '_';
        $character[1][0] = $character[1][2] = $character[1][4] = $character[2][0] = $character[2][4] = $character[3][0] = '|';
        $character[2][2] = '\'';
        $character[3][3] = '/';
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][3] = $character[0][5] = $character[3][1] = $character[3][2] = $character[3][4] = '_';
        $character[1][0] = $character[1][2] = $character[1][4] = $character[1][6] = $character[2][0] = $character[2][2] = $character[2][4] = $character[2][6] = $character[3][0] = '|';
        $character[3][3] = $character[3][5] = '/';

	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[3][0] = $character[0][4] = $character[3][3] = '_';
        $character[1][0] = $character[1][2] = $character[2][1] = $character[2][3] = $character[3][2] = $character[3][4] = '\\';
        $character[1][3] = $character[3][1] = '/';
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[0][3] = $character[3][2] = '_';
        $character[1][0] = $character[1][2] = $character[1][4] = $character[3][1] = $character[3][3] = '|';
        $character[2][4] = '/';
        $character[2][0] = '\\';
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(5);
        $character[0][0] = $character[1][2] = $character[1][3] = $character[2][0] = $character[2][2] = $character[2][4] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][1] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = $character[3][4] = '|';
        $character[1][4] = $character[2][1] = $character[2][3] = $character[3][0] = '/';
	return \@character;
};

function character_a => sub {
	my @character = $_[0]->default_character(5);
        $character[1][1] = $character[1][2] = $character[1][3] = $character[2][1] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[2][0] = $character[3][0] = '<';
        $character[2][2] = '>';
        $character[2][4] = $character[3][4] = '|';

	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[1][3] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = $character[1][2] = $character[2][0] = $character[3][0] = '|';
        $character[2][2] = '.';
        $character[2][4] = '\\';
        $character[3][4] = '/';
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(5);
        $character[1][1] = $character[1][2] = $character[1][3] = $character[3][1] = $character[3][3] = '_';
        $character[2][2] = $character[3][2] = '|';
        $character[3][0] = '\\';
        $character[3][4] = '.';
        $character[2][4] = '\'';
        $character[2][0] = '/';
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(5);
        $character[0][3] = $character[3][1] = $character[3][2] = $character[1][1] = $character[3][3] = '_';
        $character[1][2] = $character[3][4] = $character[2][4] = $character[1][4] = '|';
        $character[2][2] = '.';
        $character[2][0] = '/';
        $character[3][0] = '\\';
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = $character[1][2] = $character[1][3] = $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[2][0] = "/";
	$character[2][2] = $character[3][4] = ".";
	$character[2][4] = ">";
	$character[3][0] = "\\";
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[3][1] =  "_";
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2] = $character[3][0] = $character[3][2] = "|";
	$character[1][4] = "'";
	$character[2][3] = "-";
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(5);
        $character[1][1] = $character[1][2] = $character[1][3] = $character[4][1] = $character[4][2] = $character[4][3] = $character[3][1] = '_';
        $character[2][4] = $character[3][4] = '|';
        $character[2][2] = $character[3][2] = '.';
        $character[3][0] = '\\';
        $character[2][0] = '/';
        $character[4][0] = '<';
        $character[4][4] = '\'';
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(5);
        $character[1][0] = $character[2][0] = $character[3][0] = $character[1][2] = $character[2][4] = $character[3][2] = $character[3][4] = '|';
        $character[0][1] = $character[1][3] = $character[3][1] = $character[3][3] = '_';
        $character[2][2] = '.';
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(3);
        $character[0][0] = $character[0][2] = $character[2][1] = ' ';
        $character[0][1] = $character[1][1] = $character[3][1] = '_';
        $character[1][0] = '<';
        $character[1][2] = '>';
        $character[2][0] = $character[2][2] = $character[3][0] = $character[3][2] = '|';
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(4);
        $character[2][1] = $character[2][3] = $character[3][1] = $character[3][3] = '|';
        $character[0][2] = $character[1][2] = $character[4][1] = $character[4][2] = '_';
        $character[4][0] = $character[1][1] = '<';
        $character[4][3] = '\'';
        $character[1][3] = '>';
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[3][1] = $character[3][3] = $character[1][3] = $character[1][4] = '_';
	$character[1][0] = $character[1][2] = $character[2][0] = $character[3][0] = '|';
	$character[2][2] = $character[2][4] = '/';
	$character[3][2] = $character[3][4] = '\\';
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(3);
        $character[0][1] = $character[3][1] = '_';
        $character[1][0] = $character[2][0] = $character[3][0] = $character[1][2] = $character[2][2] = $character[3][2] = '|';
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(7);
	$character[1][0]='.';
	$character[1][1]=$character[1][3]=$character[1][5]=$character[3][1]=$character[3][3]=$character[3][5]='_';
	$character[2][0]=$character[3][0]=$character[2][6]=$character[3][6]=$character[3][2]=$character[3][4]=$character[3][0]=$character[3][6]='|';
	$character[2][2]=$character[2][4]='\'';
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(5);
        $character[1][0] = '.';
        $character[1][1] = $character[1][3] = $character[3][1] = $character[3][3] = '_';
        $character[1][2] = $character[1][4] = $character[2][1] = $character[2][3] = ' ';
        $character[2][0] = $character[2][4] = $character[3][0] = $character[3][2] = $character[3][4] = '|';
        $character[2][2] = '\'';	
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(5);
        $character[1][1] = $character[1][2] = $character[1][3] = $character[3][3] = $character[3][1] = $character[3][2] = '_';
        $character[2][0] = $character[3][4] = '/';
        $character[2][4] = $character[3][0] = '\\';
        $character[2][2] = '.';
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(5);
        $character[1][1] = $character[1][2] = $character[3][3] = $character[1][3] = $character[4][1] = '_';
        $character[2][0] = $character[4][0] = $character[4][2] = $character[3][0] = '|';
        $character[2][2] = '.';
        $character[2][4] = '\\';
        $character[3][4] = '/';
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(5);
	$character[1][1] = $character[1][2] = $character[1][3] = $character[3][1] = $character[4][3] = '_';
	$character[2][0] = "/";
	$character[2][2] = ".";
	$character[2][4] = $character[3][4] = $character[4][4] = $character[4][2] = "|";
	$character[3][0] = "\\";
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(5);
        $character[1][1] = $character[1][3] = $character[2][3] = $character[3][1] = '_';
        $character[2][0] = $character[3][0] = $character[3][2] = '|';
        $character[2][4] = '>';
        $character[2][2] = '\'';  
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(5);
        $character[1][1] = $character[1][2] = $character[1][3] = $character[2][1] = $character[3][1] = $character[3][2] = '_';
        $character[2][0] = $character[2][3] = '<';
        $character[2][2] = '-';
        $character[3][0] = $character[3][3] = '/';
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(5);
        $character[0][2] = $character[1][0] = $character[1][4] = $character[3][2] = '_';
        $character[1][1] = $character[1][3] = $character[2][1] = $character[2][3] = $character[3][1] = $character[3][3] = '|';
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(5);
        $character[2][0] = $character[2][2] = $character[2][4] = $character[3][4] = '|';
        $character[3][0] = '`';
        $character[1][1] = $character[3][1] = $character[3][2] = $character[1][3] = $character[3][3] = '_';
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(5);
        $character[1][1] = $character[3][1] = $character[3][2] = $character[1][3] = '_';
        $character[2][0] = $character[2][2] = $character[2][4] = $character[3][0] = '|';
        $character[3][3] = '/';
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(7);
	$character[1][1]=$character[1][3]=$character[1][5]=$character[3][1]=$character[3][2]=$character[3][4]= '_';
	$character[3][0]=$character[2][0]=$character[2][2]=$character[2][4]=$character[2][6]= '|';
	$character[3][3]=$character[3][5]='/';  
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(4);
        $character[1][0] = $character[1][1] = $character[3][2] = '_';
        $character[2][0] = $character[2][2] = $character[3][1] = $character[3][3] = '\\';
        $character[2][3] = $character[3][0] = '/';
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(5);

	$character[1][1] = $character[1][3] = $character[3][1] = $character[4][1] = $character[4][2] = $character[4][3] = "_";	
	$character[2][0] = $character[2][2] = $character[2][4] = $character[3][4] = "|";
	$character[3][0] = "`";
	$character[3][2] = ".";
	$character[4][0] = "<";
	$character[4][4] = "'";
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(4);
        $character[1][1] = $character[3][1] = $character[3][2] = $character[3][3] = $character[1][2] = $character[1][3] = '_';
        $character[3][0] = $character[2][1] = $character[2][3] = '/';
        $character[1][0] = '.';
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(5);
        $character[0][0] = $character[0][4] = $character[1][1] = $character[1][2] = $character[1][3] = $character[2][1] = $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[2][2] = '/';
        $character[1][0] = $character[2][0] = $character[1][4] = $character[2][4] = '|';
        $character[3][0] = '`';
        $character[3][4] = '\'';
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(3);
        $character[0][1] = $character[3][1] = '_';
        $character[1][0] = '/';
        $character[1][2] = $character[2][0] = $character[2][2] = $character[3][0] = $character[3][2] = '|';
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[0][2] = $character[0][3] = $character[1][1] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = $character[3][0] = '<';
        $character[1][4] = $character[3][4] = '>';
        $character[2][1] = $character[2][3] = '/';
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(5);
        $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][1] = $character[1][2] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = $character[2][1] = $character[3][0] = '<';
        $character[1][4] = $character[3][4] = '/';
        $character[2][4] = '\\';
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(5);
        $character[0][0] = $character[0][1] = $character[0][4] = $character[0][5] = $character[1][0] = $character[1][3] = $character[1][5] = $character[2][2] = $character[2][3] = $character[3][0] = $character[3][1] = $character[3][5] = ' ';
        $character[0][2] = $character[0][3] = $character[2][1] = $character[3][3] = '_';
        $character[1][1] = $character[2][0] = '/';
        $character[1][2] = $character[2][4] = '.';
        $character[1][4] = $character[2][5] = $character[3][2] = $character[3][4] = '|';
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3]=$character[1][2]=$character[1][3]=$character[2][1]=$character[2][2]=$character[3][1]=$character[3][2]=$character[3][3]='_';

	$character[1][0]=$character[1][4]=$character[3][0]='|';
	$character[2][0] = $character[2][4]=  '\\';
	$character[3][4]= '/';
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][2] = $character[1][3] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[2][0] = '|';
	$character[1][4] = '>';
	$character[3][0]  = "\\";
	$character[3][4] = '/';
	$character[2][2] = '.';
	$character[2][4] = '\\';
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(5);
        $character[0][0] = $character[0][4] = $character[1][2] = $character[1][3] = $character[2][0] = $character[2][2] = $character[2][4] = $character[3][3] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[1][1] = $character[3][1] = '_';
        $character[1][0] = $character[1][4] = '|';
        $character[2][1] = $character[2][3] = $character[3][0] = $character[3][2] = '/';
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(5);
        $character[0][0] = $character[0][4] = $character[1][1] = $character[1][3] = $character[2][1] = $character[2][3] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
        $character[1][0] = '<';
        $character[1][2] = $character[2][2] = '.';
        $character[1][4] = '>';
        $character[2][0] = $character[3][4] = '/';
        $character[2][4] = $character[3][0] = '\\';
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(7);
        $character[0][0] = $character[0][4] = $character[1][1] = $character[1][3] = $character[2][2] = $character[2][3] = $character[3][0] = $character[3][4] = $character[4][0] = $character[4][1] = $character[4][2] = $character[4][3] = $character[4][4] = ' ';
        $character[0][1] = $character[0][2] = $character[0][3] = $character[2][1] = $character[3][2] = '_';
        $character[1][0] = $character[1][4] = '|';
        $character[1][2] = '.';
        $character[2][0] = '`';
        $character[2][4] = $character[3][1] = $character[3][3] = '/';
	return \@character;
};

function space => sub {
	my @character = $_[0]->default_character(7);
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Drpepper - Drpepper font

=head1 VERSION

Version 0.20

=cut

=head1 SYNOPSIS

	use Ascii::Text::Font::Drpepper;

	my $font = Ascii::Text::Font::Drpepper->new();

	$font->character_A;

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Ascii::Text::Font::Drpepper object.

	my $font = Ascii::Text::Font::Drpepper->new();

=head2 character_A

         ___
        | . |
        |   |
        |_|_|


=head2 character_B

         ___
        | . >
        | . \
        |___/


=head2 character_C

         ___
        |  _>
        | <__
        `___/


=head2 character_D

         ___
        | . \
        | | |
        |___/


=head2 character_E

         ___
        | __>
        | _>
        |___>


=head2 character_F

         ___
        | __>
        | _>
        |_|


=head2 character_G

         ___
        /  _>
        | <_/\
        `____/


=head2 character_H

         _ _
        | | |
        |   |
        |_|_|


=head2 character_I

         _
        | |
        | |
        |_|


=head2 character_J

          _
         | |
        _| |
        \__/


=head2 character_K

         _ __
        | / /
        |  \
        |_\_\


=head2 character_L

         _
        | |
        | |_
        |___|


=head2 character_M

         __ __
        |  \  \
        |     |
        |_|_|_|


=head2 character_N

         _ _
        | \ |
        |   |
        |_\_|


=head2 character_O

         ___
        | . |
        | | |
        `___'


=head2 character_P

         ___
        | . \
        |  _/
        |_|


=head2 character_Q

         ___
        | . |
        | | |
        `___\


=head2 character_R

         ___
        | . \
        |   /
        |_\_\


=head2 character_S

         ___
        /___>
        \__ \
        <___/


=head2 character_T

         ___
        |_ _|
         | |
         |_|


=head2 character_U

         _ _
        | | |
        | ' |
        `___'


=head2 character_V

         _ _
        | | |
        | ' |
        |__/


=head2 character_W

         _ _ _
        | | | |
        | | | |
        |__/_/


=head2 character_X

         _  _
        \ \/
         \ \
        _/\_\


=head2 character_Y

         _ _
        | | |
        \   /
         |_|


=head2 character_Z

         ____
        |_  /
         / /
        /___|


=head2 character_a


         ___
        <_> |
        <___|


=head2 character_b

         _
        | |_
        | . \
        |___/


=head2 character_c


         ___
        / | '
        \_|_.


=head2 character_d

           _
         _| |
        / . |
        \___|


=head2 character_e


         ___
        / ._>
        \___.


=head2 character_f

         ___
        | | '
        | |-
        |_|


=head2 character_g


         ___
        / . |
        \_. |
        <___'

=head2 character_h

         _
        | |_
        | . |
        |_|_|


=head2 character_i

         _
        <_>
        | |
        |_|


=head2 character_j

          _
         <_>
         | |
         | |
        <__'

=head2 character_k

         _
        | |__
        | / /
        |_\_\


=head2 character_l

         _
        | |
        | |
        |_|


=head2 character_m

        ._ _ _
        | ' ' |
        |_|_|_|


=head2 character_n

        ._ _
        | ' |
        |_|_|


=head2 character_o

         ___
        / . \
        \___/


=head2 character_p

         ___
        | . \
        |  _/
        |_|

=head2 character_q

         ___
        / . |
        \_  |
          |_|

=head2 character_r

         _ _
        | '_>
        |_|

=head2 character_s

         ___
        <_-<
        /__/

=head2 character_t

          _
        _| |_
         | |
         |_|

=head2 character_u

         _ _
        | | |
        `___|

=head2 character_v

         _ _
        | | |
        |__/

=head2 character_w

         _ _ _
        | | | |
        |__/_/

=head2 character_x

        __
        \ \/
        /\_\

=head2 character_y

         _ _
        | | |
        `_. |
        <___'

=head2 character_z

        .___
         / /
        /___

=head2 character_0

         ___
        |   |
        | / |
        `___'

=head2 character_1

         _
        / |
        | |
        |_|

=head2 character_2

         ___
        <_  >
         / /
        <___>

=head2 character_3

         ____
        <__ /
         <_ \
        <___/

=head2 character_4

          __
         /. |
        /_  .|
          |_|

=head2 character_5

         ___
        | __|
        \__ \
        |___/

=head2 character_6

         ___
        | __>
        | . \
        \___/

=head2 character_7

         ___
        |_  |
         / /
        /_/

=head2 character_8

         ___
        < . >
        / . \
        \___/

=head2 character_9

         ___
        | . |
        `_  /
         /_/
       
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



