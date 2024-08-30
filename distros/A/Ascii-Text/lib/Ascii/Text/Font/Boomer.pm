package Ascii::Text::Font::Boomer;

use Moo;

extends 'Ascii::Text::Font';

has character_height => (
	is => 'ro',
	default => sub { 8 }
);

sub character_A {
	my @character = $_[0]->default_character(7);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[2][3] = $character[3][3] = $character[5][1] = $character[5][5] = '_';
	$character[1][1] = $character[2][0] = $character[2][2] = $character[5][6] = '/';
	$character[1][5] = $character[2][4] = $character[2][6] = $character[5][0] = '\\';
	$character[3][0] = $character[3][6] = $character[4][0] = $character[4][2] = $character[4][4] = $character[4][6] = $character[5][2] = $character[5][4] = '|';
	return \@character;
}

sub character_B {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][2] = $character[1][3] = $character[1][4] = $character[2][3] = $character[3][2] = $character[3][3] = $character[3][4] = $character[5][1] = $character[5][2] = $character[5][3] = $character[5][4] = $character[4][3] = '_';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[2][2] = $character[4][2] = '|';
	$character[1][6] = $character[3][6] = $character[5][0] = '\\';
	$character[2][4] = $character[2][6] = $character[4][6] = $character[5][5] = $character[4][4] = '/';
	return \@character;
}

sub character_C {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[1][1] = $character[1][2] = $character[1][5] = $character[2][1] = $character[2][3] = $character[2][4] = $character[3][1] = $character[3][3] = $character[3][4] = $character[3][5] = $character[3][6] = $character[4][1] = $character[5][1] = $character[6][0] = $character[6][1] = $character[6][2] = $character[6][3] = $character[6][4] = $character[6][5] = $character[6][6] = ' ';
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[1][3] = $character[1][4] = $character[4][3] = $character[4][4] = $character[5][2] = $character[5][3] = $character[5][4] = $character[5][5] = '_';
	$character[2][0] = $character[3][0] = $character[3][2] = $character[4][0] = '|';
	$character[1][0] = $character[2][2] = $character[2][6] = $character[4][5] = $character[5][6] = '/';

	$character[1][6] = $character[2][5] = $character[4][2] = $character[4][6] = $character[5][1] = '\\';
	return \@character;
}

sub character_D {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[5][1] = $character[1][3] = $character[5][2] = $character[5][3] = '_';
	$character[4][3] = $character[4][5] = $character[5][4] = '/';
	$character[1][6] = '\\';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[2][2] = $character[3][2] = $character[4][2] = $character[2][4] = $character[3][4] = $character[2][6] = $character[3][6] = '|';
	return \@character;
}

sub character_E {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][5] = $character[1][1] = $character[1][2] = $character[2][1] = $character[2][2] = $character[3][1] = $character[3][2] = $character[4][1] = $character[4][2] = ' ';
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = $character[2][3] = $character[2][4] = $character[3][3] = $character[3][4] = $character[4][3] = $character[4][4] = $character[4][5] = $character[5][1] = $character[5][2] = $character[5][3] = $character[5][4] = $character[5][5] = '_';
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2] = $character[3][0] = $character[3][5] = $character[4][0] = $character[4][2] = '|';
	$character[5][0] = '\\';
	$character[5][5] = '/';
	return \@character;
}

sub character_F {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[1][1] = $character[1][2] = $character[2][1] = $character[2][2] = $character[3][1] = $character[3][2] = $character[4][1] = $character[4][2] = ' ';
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = $character[1][4] = $character[1][5] = $character[2][3] = $character[3][3] = $character[5][1] = '_';
	$character[1][0] = $character[1][5] = $character[2][0] = $character[2][2] = $character[3][0] = $character[3][4] = $character[4][0] = $character[4][2] = $character[5][2] = '|';
	$character[5][0] = '\\';
	return \@character;
}

sub character_G {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = $character[1][4] = $character[4][3] = $character[5][2] = $character[5][3] = $character[5][4] = $character[5][5] = $character[3][4] = $character[3][5] = '_';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[2][2] = $character[3][2] = $character[4][2] = '|';
	$character[1][6] = $character[2][5] = $character[4][4] = $character[4][6] = $character[5][1] = '\\';
	$character[2][6] = $character[5][6] = '/';
	return \@character;
}

sub character_H {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][5] = $character[3][3] = $character[2][3] = $character[5][1] = $character[5][5] = '_';
	$character[1][0] = $character[1][2] = $character[1][4] = $character[1][6] = $character[2][0] = $character[2][2] = $character[2][4] = $character[2][6] = $character[3][0] = $character[3][6] = $character[4][0] = $character[4][2] = $character[4][4] = $character[4][6] = $character[5][2] = $character[5][4] = '|';
	$character[5][0] = '\\';
	$character[5][6] = '/';
	$character[5][0] = '\\';
	$character[5][6] = '/';
	return \@character;
}

sub character_I {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][6] = $character[1][2] = $character[1][3] = $character[1][4] = $character[2][0] = $character[2][1] = $character[2][3] = $character[2][5] = $character[2][6] = $character[3][0] = $character[3][1] = $character[3][3] = $character[3][5] = $character[3][6] = $character[4][0] = $character[4][1] = $character[4][3] = $character[4][6] = $character[5][0] = $character[5][6] = ' ';
	$character[1][0] = $character[1][6] = $character[2][2] = $character[2][4] = $character[3][2] = $character[3][4] = $character[4][2] = $character[4][4] = '|';
	$character[5][5] = '/';
	$character[5][1] = '\\';
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][1] = $character[1][5] = $character[4][1] = $character[4][5] = $character[5][2] = $character[5][3] = $character[5][4] = '_';
	return \@character;
}

sub character_J {
	my @character = $_[0]->default_character(7);
       $character[0][0] = $character[0][1] = $character[0][2] = $character[0][6] = $character[1][0] = $character[1][1] = $character[1][4] = $character[1][5] = $character[2][0] = $character[2][1] = $character[2][2] = $character[2][3] = $character[2][5] = $character[3][0] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][5] = $character[4][5] = $character[5][6] = ' ';
	$character[1][2] = $character[1][6] = $character[2][4] = $character[2][6] = $character[3][4] = $character[3][6] = '|';
	$character[4][0] = $character[4][4] = $character[4][6] = $character[5][5] = '/';
	$character[4][1] = $character[5][0] = '\\';
	$character[4][2] = $character[4][3] = $character[5][1] = $character[5][2] = $character[5][3] = $character[5][4] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = '_';
	return \@character;
}

sub character_K {
	my @character = $_[0]->default_character(7);
	$character[0][6] = $character[0][1] = $character[0][5] = $character[5][1] = $character[5][5] = '_';
	$character[1][4] = $character[1][6] = $character[2][5] = $character[2][3] = $character[5][6] = '/';
	$character[3][5] = $character[4][6] = $character[4][3] = $character[5][4] = $character[5][0] = '\\';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[1][2] = $character[2][2] = $character[4][2] = $character[5][2] = '|';
	return \@character;
}

sub character_L {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[4][3] = $character[4][4] = $character[4][5] = $character[5][1] = $character[5][2] = $character[5][3] = $character[5][4] = $character[5][5] = '_';
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2] = $character[3][0] = $character[3][2] = $character[4][0] = $character[4][2] = '|';
	$character[5][0] = '\\';
	$character[5][5] = '/';
	return \@character;
}

sub character_M {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][5] = $character[0][6] = $character[0][7] = $character[5][1] = $character[5][6] = '_';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[3][2] = $character[4][2] = $character[5][2] = $character[3][5] = $character[4][5] = $character[5][5] = $character[1][7] = $character[2][7] = $character[3][7] = $character[4][7] = '|';
	$character[2][2] = $character[2][5] = '.';
	$character[1][3] = $character[3][3] = $character[5][0] = '\\';
	$character[1][4] = $character[3][4] = $character[5][7] = '/';
	return \@character;
}

sub character_N {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][5] = $character[5][1] = $character[5][5] = '_';
	$character[1][2] = $character[2][3] = $character[4][3] = $character[5][0] = $character[5][4] = '\\';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[4][2] = $character[5][2] = $character[1][4] = $character[2][4] = $character[1][6] = $character[2][6] = $character[3][6] = $character[4][6] = '|';
	$character[5][6] = '/';
	$character[3][2] = '.';
	$character[3][4] = '`';
	return \@character;
}

sub character_O {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2] = $character[2][4] = $character[2][6] = $character[3][0] = $character[3][2] = $character[3][4] = $character[3][6] = '|';
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = $character[4][3] = $character[5][2] = $character[5][3] = $character[5][4] = '_';
	$character[4][0] = $character[4][2] = $character[5][1] = '\\';
	$character[4][4] = $character[4][6] = $character[5][5] = '/';
	return \@character;
}

sub character_P {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][2] = $character[1][3] = $character[1][4] = $character[2][3] = $character[3][3] = $character[3][4] = $character[5][1] = '_';
	$character[2][4] = $character[2][6] = $character[3][5] = '/';
	$character[1][6] = $character[5][0] = '\\';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[2][2] = $character[4][2] = $character[5][2] = '|';
	return \@character;
}

sub character_Q {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[1][1] = $character[1][2] = $character[1][4] = $character[1][5] = $character[2][1] = $character[2][3] = $character[2][5] = $character[3][1] = $character[3][3] = $character[3][5] = $character[4][1] = $character[4][5] = $character[5][0] = ' ';
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = $character[5][2] = $character[5][5] = '_';
	$character[4][0] = $character[4][2] = $character[5][1] = $character[5][4] = $character[5][6] = '\\';
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2] = $character[2][4] = $character[2][6] = $character[3][0] = $character[3][2] = $character[3][4] = $character[3][6] = '|';
	$character[4][4] = '\'';
	$character[4][3] = $character[4][6] = $character[5][3] = '/';
	return \@character;
}

sub character_R {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][2] = $character[1][3] = $character[1][4] = $character[5][1] = $character[5][5] = $character[2][3] = '_';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[2][2] = $character[4][2] = $character[5][2] = $character[5][6] = '|';
	$character[1][6] = $character[4][5] = $character[4][3] = $character[5][0] = $character[5][4] = '\\';
	$character[2][4] = $character[2][6] = $character[3][5] = '/';
	return \@character;
}

sub character_S {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = $character[1][4] = $character[1][5] = $character[4][2] = $character[4][3] = $character[5][1] = $character[5][2] = $character[5][3] = $character[5][4] = '_';
	$character[2][0] = $character[3][6] = $character[4][1] = $character[5][0] = '\\';
	$character[1][0] = $character[4][0] = $character[4][4] = $character[4][6] = $character[5][5] = '/';
	$character[1][6] = '|';
	$character[2][2] = $character[3][1] = '`';
	$character[2][5] = $character[3][4] = '.';
	$character[2][3] = $character[2][4] = $character[3][2] = $character[3][3] = '-';
	return \@character;
}

sub character_T {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][6] = $character[1][2] = $character[1][3] = $character[1][4] = $character[2][0] = $character[2][1] = $character[2][3] = $character[2][5] = $character[2][6] = $character[3][0] = $character[3][1] = $character[3][3] = $character[3][5] = $character[3][6] = $character[4][0] = $character[4][1] = $character[4][3] = $character[4][5] = $character[4][6] = $character[5][0] = $character[5][1] = $character[5][3] = $character[5][5] = $character[5][6] = ' ';
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][1] = $character[1][5] = $character[5][3] = '_';
	$character[1][0] = $character[1][6] = $character[2][2] = $character[2][4] = $character[3][2] = $character[3][4] = $character[4][2] = $character[4][4] = '|';
	$character[5][4] = '/';
	$character[5][2] = '\\';
	return \@character;
}

sub character_U {
	my @character = $_[0]->default_character(7);
	$character[1][0] = $character[1][2] = $character[1][4] = $character[1][6] = $character[2][0] = $character[2][2] = $character[2][4] = $character[2][6] = $character[3][0] = $character[3][2] = $character[3][4] = $character[3][6] = $character[4][0] = $character[4][2] = $character[4][4] = $character[4][6] = '|';
	$character[0][1] = $character[0][5] = $character[4][3] = $character[5][2] = $character[5][3] = $character[5][4] = '_';
	$character[5][1] = '\\';
	$character[5][5] = '/';
	return \@character;
}

sub character_V {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][5] = $character[4][3] = $character[5][2] = $character[5][3] = $character[5][4] = '_';
	$character[1][0] = $character[1][2] = $character[1][4] = $character[1][6] = $character[2][0] = $character[2][2] = $character[2][4] = $character[2][6] = $character[3][0] = $character[3][2] = $character[3][4] = $character[3][6] = '|';
	$character[4][0] = $character[4][2] = $character[5][1] = '\\';
	$character[4][4] = $character[4][6] = $character[5][5] = '/';
	return \@character;
}

sub character_W {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][6] = '_';
	$character[1][0] = $character[1][2] = $character[1][5] = $character[1][7] = $character[2][0] = $character[2][2] = $character[2][5] = $character[2][7] = $character[3][0] = $character[3][2] = $character[3][5] = $character[3][7] = '|';
	$character[3][4] = $character[4][4] = $character[4][0] = $character[5][1] = $character[5][5] = '\\';
	$character[3][3] = $character[4][3] = $character[4][7] = $character[5][2] = $character[5][6] = '/';
	return \@character;
}

sub character_X {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[0][5] = $character[0][6] = '_';
	$character[1][0] = $character[1][2] = $character[2][1] = $character[3][5] = $character[4][4] = $character[4][6] = $character[5][5] = $character[5][0] = '\\';
	$character[1][4] = $character[1][6] = $character[2][5] = $character[3][1] = $character[4][0] = $character[4][2] = $character[5][1] = $character[5][6] = '/';
	$character[2][3] = 'v';
	$character[4][3] = '^';
	return \@character;
}

sub character_Y {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[0][5] = $character[0][6] = $character[5][3] = '_';
	$character[1][4] = $character[1][6] = $character[2][5] = $character[5][4] = $character[3][4] = '/';
	$character[1][0] = $character[1][2] = $character[3][2] = $character[5][2] = $character[2][1] = '\\';
	$character[2][3] = 'v';
	$character[4][2] = $character[4][4] = '|';
	return \@character;
}

sub character_Z {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[1][1] = $character[1][2] = $character[1][3] = $character[4][5] = $character[4][6] = $character[4][4] = $character[5][1] = $character[5][2] = $character[5][3] = $character[5][4] = $character[5][5] = '_';
	$character[2][3] = $character[2][5] = $character[1][6] = $character[3][2] = $character[3][4] = $character[4][1] = $character[4][3] = $character[5][6] = '/';
	$character[5][0] = '\\';
	$character[1][0] = '|';
	return \@character;
}

sub character_a {
	my @character = $_[0]->default_character(7);
	$character[2][2] = $character[2][3] = $character[2][5] = '_';
	$character[3][1] = '/';
	$character[3][3] = '_';
	$character[3][4] = '`';
	$character[3][6] = '|';
	$character[4][0] = '|';
	$character[4][2] = '(';
	$character[4][3] = '_';
	$character[4][4] = '|';
	$character[4][6] = '|';
	$character[5][1] = '\\';
	$character[5][2] = '_';
	$character[5][3] = '_';
	$character[5][4] = ',';
	$character[5][5] = '_';
	$character[5][6] = '|';
	return \@character;
}

sub character_b {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[5][1] = $character[5][3] = $character[5][4] = $character[2][3] = $character[2][4] = $character[3][3] = $character[4][3] = '_';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[1][2] = $character[2][2] = $character[4][2] = $character[4][6] = '|';
	$character[4][4] = ')';
	$character[5][2] = '.';
	$character[3][2] = '\'';
	$character[3][5] = '\\';
	$character[5][5] = '/';
	return \@character;
}

sub character_c {
	my @character = $_[0]->default_character(6);
	$character[2][2] = $character[2][3] = $character[2][4] = $character[5][2] = $character[5][3] = $character[5][4] = $character[3][3] = $character[3][4] = $character[4][3] = $character[4][4] = '_';
	$character[3][1] = '/';
	$character[4][0] = '|';
	$character[4][2] = '(';
	$character[5][1] = '\\';
	$character[3][5] = $character[5][5] = '|';
	return \@character;
}

sub character_d {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][6] = $character[1][0] = $character[1][1] = $character[1][2] = $character[1][3] = $character[1][5] = $character[2][0] = $character[2][1] = $character[2][2] = $character[2][3] = $character[2][5] = ' ';
	$character[0][5] = $character[2][2] = $character[2][3] = $character[3][3] = $character[4][3] = $character[5][2] = $character[5][3] = $character[5][5] = '_';
	$character[1][4] = $character[1][6] = $character[2][4] = $character[2][6] = $character[3][6] = $character[4][0] = $character[4][4] = $character[4][6] = $character[5][6] = '|';
	$character[4][2] = '(';
	$character[5][4] = ',';
	$character[3][4] = '`';
	$character[5][1] = '\\';
	$character[3][1] = '/';
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][6] = $character[1][0] = $character[1][1] = $character[1][2] = $character[1][3] = $character[1][5] = $character[2][0] = $character[2][1] = $character[2][2] = $character[2][3] = $character[2][5] = ' ';
	$character[0][5] = $character[2][2] = $character[2][3] = $character[3][3] = $character[4][3] = $character[5][2] = $character[5][3] = $character[5][5] = '_';
	$character[1][4] = $character[1][6] = $character[2][4] = $character[2][6] = $character[3][6] = $character[4][0] = $character[4][4] = $character[4][6] = $character[5][6] = '|';
	$character[4][2] = '(';
	$character[5][4] = ',';
	$character[3][4] = '`';
	$character[5][1] = '\\';
	$character[3][1] = '/';
	return \@character;
}

sub character_e {
	my @character = $_[0]->default_character(6);
	$character[2][2] = $character[2][3] = $character[2][4] = $character[5][2] = $character[5][3] = $character[5][4] = $character[4][3] = $character[4][4] = $character[3][3] = '_';
	$character[3][5] = $character[5][1] = '\\';
	$character[4][0] = $character[5][5] = '|';
	$character[3][1] = $character[4][5] = '/';
	return \@character;
}

sub character_f {
	my @character = $_[0]->default_character(5);
	$character[0][3] = $character[0][4] = $character[1][3] = $character[2][3] = $character[3][3] = $character[5][1] = '_';
	$character[1][4] = $character[2][0] = $character[2][2] = $character[3][0] = $character[3][4] =
	$character[4][0] = $character[4][2] = $character[5][0] = $character[5][2] = '|';
	$character[1][1] = '/';
	return \@character;
}

sub character_g {
	my @character = $_[0]->default_character(7);
	$character[2][0] = $character[2][1] = $character[2][4] = $character[2][6] = $character[3][0] = $character[3][2] = $character[3][4] = $character[3][5] = $character[4][1] = $character[4][5] = $character[5][0] = $character[5][5] = $character[6][0] = $character[6][1] = $character[6][5] = $character[7][0] = $character[7][6] = ' ';
	$character[2][2] = $character[2][3] = $character[2][5] = $character[3][3] = $character[4][3] = $character[5][2] = $character[5][3] = $character[6][2] = $character[6][3] = $character[7][2] = $character[7][3] = $character[7][4] = '_';
	$character[3][6] = $character[4][0] = $character[4][4] = $character[4][6] = $character[5][6] = $character[6][6] = $character[7][1] = '|';
	$character[3][1] = $character[6][4] = $character[7][5] = '/';
	$character[5][1] = '\\';
	$character[3][4] = '`';
	$character[5][4] = ',';
	$character[4][2] = '(';
	return \@character;
}

sub character_h {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[5][1] = $character[5][5] = $character[2][3] = $character[2][4] = $character[3][3] = '_';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[5][0] = $character[1][2] = $character[2][2] = $character[4][2] = $character[5][2] = $character[4][4] = $character[5][4] = $character[4][6] = $character[5][6] = '|';
	$character[3][5] = '\\';
	return \@character;
}

sub character_i {
	my @character = $_[0]->default_character(3);
	$character[0][1] = $character[1][1] = $character[2][1] = $character[5][1] = '_';
	$character[3][2] = $character[4][2] = $character[5][2] = $character[3][0] = $character[4][0] = $character[5][0] = '|';
	$character[1][0] = '(';
	$character[1][2] = ')';
	return \@character;
}

sub character_j {
	my @character = $_[0]->default_character(5);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[1][0] = $character[1][1] = $character[2][0] = $character[2][1] = $character[2][2] = $character[3][0] = $character[3][1] = $character[3][3] = $character[4][0] = $character[4][1] = $character[4][3] = $character[5][0] = $character[5][3] = ' ';
	$character[0][3] = $character[1][3] = $character[2][3] = $character[6][1] = $character[7][1] = $character[7][2] = '_';
	$character[3][2] = $character[3][4] = $character[4][2] = $character[4][4] = $character[5][2] = $character[5][4] = $character[6][4] = $character[7][0] = '|';
	$character[6][2] = $character[7][3] = '/';
	$character[1][2] = '(';
	$character[1][4] = ')';
	return \@character;
}

sub character_k {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[2][4] = $character[2][5] = $character[5][1] = $character[5][4] = '_';
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2] = $character[3][0] = $character[3][2] = $character[4][0] = $character[5][0] = $character[5][2] = '|';
	$character[3][3] = $character[3][5] = '/';
	$character[4][4] = '<';
	$character[5][3] = $character[5][5] = '\\';
	return \@character;
}

sub character_l {
	my @character = $_[0]->default_character(3);
	$character[0][1] = $character[5][1] = '_';
	$character[1][0] = $character[2][0] = $character[3][0] = $character[4][0] = $character[1][2] = $character[2][2] = $character[3][2] = $character[4][2] = $character[5][0] = $character[5][2] = '|';
	return \@character;
}

sub character_m {
	my @character = $_[0]->default_character(11);
	$character[2][1] = $character[2][3] = $character[2][4] = $character[2][6] = $character[2][7] = $character[2][8] = $character[3][3] = $character[3][7] = $character[5][1] = $character[5][5] = $character[5][9] = '_';
	$character[2][0] = $character[2][2] = $character[2][5] = $character[2][9] = $character[3][1] = $character[4][1] = $character[4][3] = $character[4][5] = $character[4][7] = $character[4][9] = $character[5][3] = $character[5][7] = ' ';
	$character[3][0] = $character[4][0] = $character[5][0] = $character[4][2] = $character[5][2] = $character[4][4] = $character[5][4] = $character[4][6] = $character[5][6] = $character[4][8] = $character[5][8] = $character[4][10] = $character[5][10] = '|';
	$character[3][2] = '\'';
	$character[3][9] = '\\';
	$character[3][5] = '`';
	return \@character;
}

sub character_n {
	my @character = $_[0]->default_character(7);
	$character[2][1] = $character[2][3] = $character[2][4] = $character[4][3] = $character[4][5] = $character[4][4] = $character[3][3] = $character[5][5] = $character[5][1] = '_';
	$character[2][0] = $character[2][2] = $character[2][5] = $character[2][6] = $character[3][1] = $character[4][1] = $character[4][3] = $character[4][5] = ' ';
	$character[3][0] = $character[4][0] = $character[4][2] = $character[4][4] = $character[4][6] = $character[5][0] = $character[5][2] = $character[5][4] = $character[5][6] = '|';
	$character[3][2] = '\'';
	$character[3][5] = '\\';
	return \@character;
}

sub character_o {
	my @character = $_[0]->default_character(7);
	$character[2][2] = $character[2][3] = $character[2][4] = '_';
	$character[3][3] = '_';
	$character[3][1] = '/';
	$character[3][5] = '\\';
	$character[4][0] = $character[4][6] = '|';
	$character[4][2] = '(';
	$character[4][4] = ')';
	$character[4][3] = '_';
	$character[5][1] = '\\';
	$character[5][5] = '/';
	$character[5][2] = $character[5][3] = $character[5][4] = '_';
	return \@character;
}

sub character_p {
	my @character = $_[0]->default_character(7);
	$character[2][1] = $character[2][4] = $character[2][3]= $character[7][1] = '_';
	$character[3][3] = $character[4][3] = $character[5][3] = $character[5][4] = '_';
	$character[3][0] = $character[4][0] = $character[5][0] = $character[6][0] = '|';
	$character[7][0] = $character[4][2] = $character[6][2] = $character[7][2] = $character[4][6] = '|';
	$character[3][2] = '\'';
	$character[5][2] = '.';
	$character[4][4] = ')';
	$character[3][5] = '\\';
	$character[5][5] = '/';
	return \@character;
}

sub character_q {
	my @character = $_[0]->default_character(7);
	$character[2][2] = $character[2][5] = $character[2][3] = $character[7][5] = '_';
	$character[3][3] = $character[4][3] = $character[5][3] = $character[5][2] = '_';
	$character[4][0] = $character[4][4] = $character[6][4] = $character[7][6] = $character[7][4]='|';
	$character[3][6] = $character[4][6] = $character[5][6] = $character[6][6] = '|';
	$character[4][2] = '(';
	$character[5][1] = '\\';
	$character[3][1] = '/';
	$character[5][4] = ',';
	$character[3][4] = '`';
	return \@character;
}

sub character_r {
	my @character = $_[0]->default_character(5);
	$character[2][3]=$character[2][1] = $character[5][1] =  $character[3][3] = '_';
	$character[3][0]=$character[4][0] = $character[5][0] =$character[4][2] = $character[5][2] = $character[3][4] = '|';
	$character[3][2]='\'';
	return \@character;
}

sub character_s {
	my @character = $_[0]->default_character(5);
	$character[2][1] = $character[2][2] = $character[2][3] = '_';
	$character[3][0] = '/';
	$character[3][2] = $character[3][3] = '_';
	$character[3][4] = '|';
	$character[4][0] = '\\';
	$character[4][1] = $character[4][2] = '_';
	$character[4][4] = '\\';
	$character[5][0] = '|';
	$character[5][1] = $character[5][2] = $character[5][3] = '_';
	$character[5][4] = '/';
	return \@character;
}

sub character_t {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[2][3] = $character[3][2] = $character[3][3] = $character[4][3] = $character[5][2] = $character[5][3] = '_';
	$character[1][0] = $character[1][2] = $character[2][0] = $character[2][2] = $character[3][0] = $character[3][4] = $character[4][0] = $character[4][2] = $character[5][4] = '|';
	$character[5][1] = '\\';
	return \@character;
}

sub character_u {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = ' ';
	$character[1][0] = $character[1][1] = $character[1][2] = $character[1][3] = $character[1][4] = $character[1][5] = $character[1][6] = ' ';
	$character[2][0] = $character[2][2] = $character[2][3] = $character[2][6] = $character[5][0] = ' ';
	$character[3][1] = $character[3][3] = $character[3][5] = $character[4][1] = $character[4][5] = ' ';
	$character[6][0] = $character[6][1] = $character[6][2] = $character[6][3] = $character[6][4] = $character[6][5] = $character[6][6] = ' ';
	$character[3][0] = $character[4][0] = $character[3][2] = $character[4][2] = $character[3][4] = $character[4][4] = $character[3][6] = $character[4][6] = $character[5][6] = '|';
	$character[2][1] = $character[2][5] = $character[4][3] = $character[5][2] = $character[5][3] = $character[5][5] = '_';
	$character[5][1] = '\\';
	$character[5][4] = ',';
	return \@character;
}

sub character_v {
	my @character = $_[0]->default_character(7);
	$character[2][0] = $character[2][1] = $character[2][5] = $character[2][6] = $character[5][3] = '_';
	$character[3][0] = $character[3][2] = $character[4][1] = $character[5][2] = '\\';
	$character[3][4] = $character[3][6] = $character[4][5] = $character[5][4] = '/';
	$character[4][3] = 'V';
	return \@character;
}

sub character_w {
	my @character = $_[0]->default_character(10);
    	$character[2][0] = $character[2][1] = $character[2][8] = $character[2][9] = $character[5][3] = $character[5][6] = '_';
    	$character[3][0] = $character[3][2] = $character[3][5] = $character[4][1] = $character[5][2] = $character[5][5] ='\\';
    	$character[3][4] = $character[3][7] = $character[3][9] = $character[4][8] = $character[5][4] = $character[5][7] = '/';
    	$character[4][3] = $character[4][6] = 'V';
	return \@character;
}

sub character_x {
	my @character = $_[0]->default_character(6);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] =  ' ';
	$character[1][0] = $character[1][1] = $character[1][2] = $character[1][3] = $character[1][4] = $character[1][5] = ' ';
	$character[2][0] = $character[2][1] = $character[2][4] = $character[2][5] = $character[5][1] = $character[5][4] = '_';
	$character[3][1] = $character[3][4] = $character[4][0] = $character[4][2] = $character[4][3] = $character[4][5] = ' ';
	$character[3][0] = $character[3][2] = $character[5][3] = $character[5][5] = '\\';
	$character[3][3] = $character[3][5] = $character[5][0] = $character[5][2] = '/';
	$character[4][1] = '>';
	$character[4][4] = '<';
	return \@character;
}

sub character_y {
	my @character = $_[0]->default_character(7);
	$character[3][0]=$character[3][2]=$character[3][4]=$character[3][6]=$character[4][0]=$character[4][2]=$character[4][4]=$character[4][6]=$character[5][6]=$character[6][6]=$character[7][1]='|';
	$character[5][1]='\\';
	$character[2][1]=$character[2][5]=$character[4][3]=$character[5][2]=$character[5][3]=$character[6][3]=$character[6][2]=$character[7][4]=$character[7][3]=$character[7][2]='_';
	$character[6][4]=$character[7][5]='/';
	$character[5][4]=',';
	return \@character;
}

sub character_z {
	my @character = $_[0]->default_character(5);
	$character[2][0] = $character[3][2] = $character[3][3] = $character[4][0] = $character[4][2] = ' ';
	$character[2][1] = $character[2][2] = $character[2][3] = $character[2][4] = $character[3][1] = $character[5][1] = $character[5][2] = $character[5][3] = '_';
	$character[3][0] = $character[5][4] = '|';
	$character[3][4] = $character[4][1] = $character[4][3] = $character[5][0] = '/';
	return \@character;
}

sub character_0 {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = $character[4][3] = $character[5][2] = $character[5][3] = $character[5][4] = '_';
	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2] = $character[2][6] = $character[3][0] = $character[3][4] = $character[3][6] = $character[4][2] = '|';
	$character[2][4] = '\'';
	$character[4][0] = $character[5][1] = '\\';
	$character[2][3] = $character[3][3] = $character[4][4] = $character[4][6] = $character[5][5] = '/';
	return \@character;
}

sub character_1 {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] =$character[4][0]=$character[4][5]=$character[5][1]=$character[5][2]=$character[5][3]=$character[5][4]='_';
	$character[1][0]=$character[5][5]='/';
	$character[2][0]='`';
	$character[2][1]=$character[3][1]=$character[4][1]='|';
	$character[1][4]=$character[2][4]=$character[3][4]=$character[4][4]='|';
	$character[5][0]='\\';
	return \@character;
}

sub character_2 {
	my @character = $_[0]->default_character(7);
      	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][2] = $character[1][3] = $character[4][4] = $character[4][5] = $character[4][6] = $character[5][1] = $character[5][2] = $character[5][3] = $character[5][4] = $character[5][5] = '_';
	$character[1][0] = $character[2][3] = $character[2][5] = $character[3][2] = $character[3][4] = $character[4][1] = $character[4][3] = $character[5][6] = '/';
	$character[1][6] = $character[5][0] = '\\';
	$character[4][0] = '.';
	$character[2][0] = '`';
	$character[2][1] = $character[2][6] = '\'';
	return \@character;
}

sub character_3 {
	my @character = $_[0]->default_character(7);
	$character[0][0]=$character[0][6]=$character[1][5]=$character[2][0]=$character[2][1]=$character[2][2]=$character[2][3]=$character[2][5]=$character[3][0]=$character[3][1]=$character[3][2]=$character[3][3]=$character[3][5]=' ';
	$character[0][1]=$character[0][2]=$character[0][3]=$character[0][4]=$character[0][5]=$character[1][1]=$character[1][2]=$character[1][3]=$character[1][4]=$character[4][1]=$character[4][2]=$character[4][3]=$character[5][1]=$character[5][2]=$character[5][3]=$character[5][4]='_';
	$character[1][0]=$character[1][6]='|';
	$character[2][4]=$character[2][6]=$character[4][4]=$character[4][6]=$character[5][5]='/';
	$character[3][4]=$character[3][6]=$character[5][0]='\\';
	$character[4][0]='.';
	return \@character;
}

sub character_4 {
	my @character = $_[0]->default_character(7);
	$character[0][3] = $character[0][4] = $character[0][5] = $character[3][3] = $character[4][1] = $character[4][2] = $character[4][3] = $character[5][5] = '_';
	$character[1][6] = $character[2][6] = $character[3][6] = $character[4][6] = $character[2][4] = $character[3][4] = $character[5][4] = '|';
	$character[1][2] = $character[2][1] = $character[2][3] = $character[3][2] = $character[3][0] = $character[5][6] = '/';
	$character[4][0] = '\\';
	return \@character;
}

sub character_5 {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] 
	= $character[1][4] = $character[1][5] = $character[2][1] = $character[2][2] = $character[2][3] = $character[4][2]
	= $character[4][3] = $character[5][1] = $character[5][3] = $character[5][4] = '_';
	$character[1][0] = $character[1][6] = $character[2][0]  = '|';
	$character[2][5] = $character[3][4] = $character[3][6] = $character[4][1] = $character[5][0] = '\\';
	$character[4][0] = $character[4][4] = $character[4][6] = $character[5][5] = '/';
	return \@character;
}

sub character_6 {
	my @character = $_[0]->default_character(7);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = $character[1][4] = $character[1][5] = $character[2][3] = $character[2][4] = $character[2][5] = $character[3][3] = $character[3][4] = $character[3][2] = $character[5][1] = $character[5][2] = $character[5][3] = $character[5][4] = $character[5][5] = $character[4][3] = '_';
	$character[5][0] = '\\';
	$character[5][6] = '/';
	$character[4][2] = '\\';
	$character[4][4] = '/';
	$character[3][6] = '\\';
	$character[2][0] = $character[2][2] = '/';
	$character[1][1] = '/';
	$character[1][6] = $character[3][0] = $character[4][0] = $character[4][6] = '|';
	return \@character;
}

sub character_7 {
	my @character = $_[0]->default_character(7);
	$character[0][0] = $character[1][4] = $character[1][5] = $character[2][6] = $character[2][4] = $character[2][2] = $character[2][1] = $character[2][0] = $character[3][0] = $character[3][1] = $character[3][3] = $character[3][5] = $character[3][6] = $character[4][0] = $character[4][2] = $character[4][4] = $character[4][5] = $character[4][6] = $character[5][3] = $character[5][4] = $character[5][5] = $character[5][6] = $character[6][0] = $character[6][1] = $character[6][3] = $character[6][4] = $character[6][5] = $character[6][6] = ' ';
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[0][6] = $character[1][1] = $character[1][2] = $character[1][3] = $character[5][1] = '_';
	$character[1][0] = '|';
	$character[4][0] = '.';
	$character[5][0] = '\\';
	$character[1][6] = $character[2][3] = $character[2][5] = $character[3][2] = $character[3][4] = $character[4][1] = $character[4][3] = $character[5][2] = '/';
	$character[1][0] = '|';
	$character[4][0] = '.';
	$character[5][0] = '\\';
	$character[1][6] = $character[2][3] = $character[2][5] = $character[3][2] = $character[3][4] = $character[4][1] = $character[4][3] = $character[5][2] = '/';
	return \@character;
}

sub character_8 {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] = $character[3][3] = $character[4][3] = $character[5][1] = $character[5][2] = $character[5][3] = $character[5][4] = $character[5][5] = '_';
	$character[1][0] = $character[1][6] = $character[4][0] = $character[4][2] = $character[4][4] = $character[4][6] = '|';
	$character[2][1] = $character[3][5] = $character[5][0] = '\\';
	$character[2][5] = $character[3][1] = $character[5][6] = '/';
	$character[2][3] = 'V';
	return \@character;
}

sub character_9 {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][3] 
	= $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = $character[4][1] 
	= $character[4][2] = $character[4][3] = $character[5][1] = $character[5][2] = $character[5][3] = $character[5][4] 
	= $character[4][6] = '_';

	$character[1][0] = $character[1][6] = $character[2][0] = $character[2][2] = $character[2][4] = $character[2][6] = $character[3][6] = '|';

	$character[4][0] = '.';
	$character[4][4] = $character[4][6] = $character[5][5] = '/';
	$character[3][0] = $character[5][0] = '\\';
	return \@character;
}

sub space {
	my @character = $_[0]->default_character(7);
	return \@character;
}

1;

__END__

=head1 NAME

Ascii::Text::Font::Boomer - Boomer font

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use Ascii::Text::Font::Boomer;

	my $font = Ascii::Text::Font::Boomer->new();

	$font->character_A;

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Ascii::Text::Font::Boomer object.

	my $font = Ascii::Text::Font::Boomer->new();

=head2 character_A

	  ___
	 / _ \
	/ /_\ \
	|  _  |
	| | | |
	\_| |_/

=head2 character_B

	______
	| ___ \
	| |_/ /
	| ___ \
	| |_/ /
	\____/

=head2 character_C

	  _____
	/  __ \
	| /  \/
	| |
	| \__/\
	 \____/

=head2 character_D

	______
	|  _  \
	| | | |
	| | | |
	| |/ /
	|___/

=head2 character_E

	 _____
	|  ___|
	| |__  
	|  __| 
	| |___ 
	\____/ 

=head2 character_F

	 ______
	|  ___|
	| |_   
	|  _|  
	| |    
	\_| 

=head2 character_G

	 _____
	|  __ \
	| |  \/
	| | __ 
	| |_\ \
	 \____/

=head2 character_H

	 _   _ 
	| | | |
	| |_| | 
	|  _  | 
	| | | | 
	\_| |_/ 

=head2 character_I

	 _____
	|_   _|
	  | |  
	  | |  
	 _| |_ 
	 \___/ 

=head2 character_J

	   ___     
	  |_  |         
	    | |       
	    | |      
	/\__/ /       
	\____/      

=head2 character_K

	 _   __
	| | / /
	| |/ / 
	|    \ 
	| |\  \
	\_| \_/

=head2 character_L

	 _     
	| |    
	| |    
	| |    
	| |____
	\_____/

=head2 character_M


	___  ___
	|  \/  |
	| .  . |
	| |\/| |
	| |  | |
	\_|  |_/

=head2 character_N

	 _   _ 
	| \ | |
	|  \| |
	| . ` |
	| |\  |
	\_| \_/

=head2 character_O

	 _____ 
	|  _  |
	| | | |
	| | | |
	\ \_/ /
	 \___/ 

=head2 character_P

	______ 
	| ___ \
	| |_/ /
	|  __/ 
	| |    
	\_|    

=head2 character_Q

	 _____ 
	|  _  |
	| | | |
	| | | |
	\ \/' /
	 \_/\_\

=head2 character_R

	______ 
	| ___ \
	| |_/ /
	|    / 
	| |\ \ 
	\_| \_|

=head2 character_S

	 _____ 
	/  ___|
	\ `--. 
	 `--. \
	/\__/ /
	\____/ 

=head2 character_T

	 _____ 
	|_   _|
	  | |  
	  | |  
	  | |  
	  \_/  

=head2 character_U

	 _   _ 
	| | | |
	| | | |
	| | | |
	| |_| |
	 \___/ 

=head2 character_V

	 _   _ 
	| | | |
	| | | |
	| | | |
	\ \_/ /
	 \___/ 

=head2 character_W

	 _    _ 
	| |  | |
	| |  | |
	| |/\| |
	\  /\  /
	 \/  \/ 

=head2 character_X

	__   __
	\ \ / /
	 \ V / 
	 /   \ 
	/ /^\ \
	\/   \/

=head2 character_Y

	__   __
	\ \ / /
	 \ V / 
	  \ /  
	  | |  
	  \_/ 

=head2 character_Z

	 ______
	|___  /
	   / / 
	  / /  
	 / /___
	\_____/ 

=head2 character_a

	  __ _
	 / _` |
	| (_| |
	 \__,_|

=head2 character_b

	 _     
	| |    
	| |__  
	| '_ \ 
	| |_) |
	|_.__/ 

=head2 character_c

	  ___ 
	 / __|
	| (__ 
	 \___|

=head2 character_d

	     _ 
	    | |
	  __| |
	 / _` |
	| (_| |
	 \__,_|

=head2 character_e

	  ___ 
	 / _ \
	|  __/
	 \___|

=head2 character_f

	   __
	 / _|
	| |_ 
	|  _|
	| |  
	|_|  

=head2 character_g

	  __ _ 
	 / _` |
	| (_| |
	 \__, |
	  __/ |
	 |___/

=head2 character_h

	 _   
	| |    
	| |__  
	| '_ \ 
	| | | |
	|_| |_|

=head2 character_i

	 _ 
	(_)
	 _ 
	| |
	| |
	|_|

=head2 character_j

	   _ 
	  (_)
	   _ 
	  | |
	  | |
	  | |
	 _/ |
	|__/ 

=head2 character_k

	 _    
	| |   
	| | __
	| |/ /
	|   < 
	|_|\_\

=head2 character_l

	 _ 
	| |
	| |
	| |
	| |
	|_|

=head2 character_m

	 _ __ ___  
	| '_ ` _ \ 
	| | | | | |
	|_| |_| |_|

=head2 character_n

	 _ __  
	| '_ \ 
	| | | |
	|_| |_|

=head2 character_o

	  ___  
	 / _ \ 
	| (_) |
	 \___/ 

=head2 character_p

	 _ __  
	| '_ \ 
	| |_) |
	| .__/ 
	| |    
	|_|    

=head2 character_q

	  __ _ 
	 / _` |
	| (_| |
	 \__, |
	    | |
	    |_|

=head2 character_r

	 _ __ 
	| '__|
	| |   
	|_|   

=head2 character_s

	 ___ 
	/ __|
	\__ \
	|___/

=head2 character_t

	 _   
	| |  
	| |_ 
	| __|
	| |_ 
	 \__|

=head2 character_u

	 _   _ 
	| | | |
	| |_| |
	 \__,_|

=head2 character_v

	__   __
	\ \ / /
	 \ V / 
	  \_/  

=head2 character_w

	__      __
	\ \ /\ / /
	 \ V  V / 
	  \_/\_/  

=head2 character_x

	__  __
	\ \/ /
	 >  < 
	/_/\_\

=head2 character_y

	 _   _ 
	| | | |
	| |_| |
	 \__, |
	  __/ |
	 |___/ 

=head2 character_z

	 ____
	|_  /
	 / / 
	/___|

=head2 character_0

	 _____ 
	|  _  |
	| |/' |
	|  /| |
	\ |_/ /
	 \___/ 

=head2 character_1

	 __  
	/  | 
	`| | 
	 | | 
	_| |_
	\___/

=head2 character_2

	 _____ 
	/ __  \
	`' / /'
	  / /  
	./ /___
	\_____/

=head2 character_3

	 _____ 
	|____ |
	    / /
	    \ \
	.___/ /
	\____/ 

=head2 character_4

	   ___ 
	  /   |
	 / /| |
	/ /_| |
	\___  |
	    |_/

=head2 character_5

	 _____ 
	|  ___|
	|___ \ 
	    \ \
	/\__/ /
	\____/ 

=head2 character_6

	  ____ 
	 / ___|
	/ /___ 
	| ___ \
	| \_/ |
	\_____/

=head2 character_7

	 ______
	|___  /
	   / / 
	  / /  
	./ /   
	\_/    
       
=head2 character_8

	 _____ 
	|  _  |
	 \ V / 
	 / _ \ 
	| |_| |
	\_____/

=head2 character_9

	 _____ 
	|  _  |
	| |_| |
	\____ |
	.___/ /
	\____/ 

       
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



