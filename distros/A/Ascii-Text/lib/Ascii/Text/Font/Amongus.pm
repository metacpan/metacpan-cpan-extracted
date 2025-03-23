package Ascii::Text::Font::Amongus;

use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable => 0,
	writable => 0,
	value => 4,
);

function character_A => sub {
	my @character = $_[0]->default_character(8);
	$character[0][3] = $character[0][4] = $character[1][3] = $character[1][4] = $character[2][3] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][5] = $character[3][6] = '_';
	$character[1][2] = $character[2][1] = '/';
	$character[1][5] = $character[2][6] = '\\';
	$character[3][0] = $character[2][2] = $character[3][4] = '(';
	$character[2][5] = $character[3][3] = $character[3][7] = ')';
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[2][1] = ')';
	$character[1][5] = '\\';
	$character[2][5] = '<';
	$character[3][5] = '/';
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[1][4] = $character[2][3] = $character[2][4] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][5] = $character[3][5] = ')';
	$character[2][0] = $character[2][2] = '(';
	$character[1][1] = '/';
	$character[3][1] = '\\';
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][4] = $character[0][2] = $character[0][3] = $character[1][3] = $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = $character[2][2] = '(';
	$character[2][1] = $character[2][4] = $character[2][6] = ')';
	$character[1][5] = '\\';
	$character[3][5] = '/';
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[3][0] = '(';
	$character[1][5] = $character[2][1] = $character[2][4] = $character[3][5] = ')';
	$character[1][2] = $character[1][3] = $character[1][4] = $character[2][2] = $character[2][3] = $character[3][2] = $character[3][3] = $character[3][4] = $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = '_';
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][2] = $character[1][3] = $character[1][4] = $character[2][2] = $character[2][3] = $character[3][1] = $character[3][2] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[1][5] = $character[2][1] = $character[2][4] = $character[3][3] = ')';
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[1][4] = $character[2][3] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[2][0] = $character[2][2] = '(';
	$character[1][5] = ')';
	$character[1][1] = $character[3][5] = '/';
	$character[3][1] = '\\';
	$character[2][4] = '-';
	$character[2][5] = '.';
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][5] = $character[1][3] = $character[2][3] = $character[3][1] = $character[3][5] = '_';
	$character[1][0] = $character[1][4] = $character[2][5] = $character[3][0] = $character[3][4] = '(';
	$character[1][2] = $character[1][6] = $character[2][1] = $character[3][2] = $character[3][6] = ')';
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][1] = $character[1][4] = $character[2][1] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = $character[2][3] = '(';
	$character[1][5] = $character[3][5] = $character[2][2] = ')';
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(7);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][2] = $character[1][5] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][1] = $character[2][4] = '(';
	$character[1][6] = $character[2][3] = $character[3][5] = ')';
	$character[2][0] = '.';
	$character[2][1] = '-';
	$character[3][0] = '\\';
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][4] = $character[3][1] = $character[3][4] = '_';
	$character[1][0] = $character[2][4] = $character[3][0] = '(';
	$character[1][2] = $character[1][5] = $character[2][1] = $character[3][2] = $character[3][5] = ')';
	$character[1][3] = '/';
	$character[3][3] = '\\';
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[2][3] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[2][2] = $character[3][0] = '(';
	$character[1][3] = $character[2][1] = $character[3][5] = ')';
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][5] = $character[0][6] = $character[3][1] = $character[3][6] = '_';
	$character[1][0] = $character[2][6] = $character[3][0] = '(';
	$character[1][7] = $character[2][1] = $character[3][7] = ')';
	$character[1][3] = $character[3][3] = $character[3][5] = '\\';
	$character[1][4] = $character[3][2] = $character[3][4] = '/';
	return \@character;
};

function character_N => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][4] = $character[3][1] = $character[3][4] = '_';
	$character[1][0] = $character[1][3] = $character[2][4] = $character[3][0] = '(';
	$character[1][5] = $character[2][1] = $character[3][2] = $character[3][5] = ')';
	$character[1][2] = $character[3][3] = '\\';
	return \@character;
};

function character_O => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = $character[3][5] = $character[1][3] = $character[2][3] = '_';
	$character[1][0] = $character[3][0] = $character[2][2] = $character[2][5] = '(';
	$character[1][6] = $character[2][1] = $character[2][4] = $character[3][6] = ')';
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[2][2] = $character[2][3] = $character[2][4] = $character[3][1] = $character[3][2] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[2][1] = $character[3][3] = ')';
	$character[1][5] = '\\';
	$character[2][5] = '/';
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[3][1] = $character[3][2] = $character[3][3] = $character[1][3] = $character[2][3] = '_';
	$character[1][0] = $character[3][0] = $character[2][2] = $character[2][5] = '(';
	$character[1][6] = $character[2][1] = $character[2][4] = ')';
	$character[3][4] = '/';
	$character[3][5] = $character[3][6] = '\\';
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[3][1] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[2][1] = $character[3][2] = $character[3][5] = ')';
	$character[3][3] = $character[1][5] = '\\';
	$character[2][5] = '/';
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][2] = $character[1][3] = $character[2][1] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[3][4] = '/';
	$character[1][1] = $character[2][3] = ' ';
	$character[2][0] = $character[2][4] = '\\';
	$character[1][4] = ')';
	$character[3][0] = '(';
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][1] = $character[1][4] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[2][3] = $character[3][1] = '(';
	$character[1][5] = $character[2][2] = $character[3][4] = ')';
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][5] = $character[0][6] = $character[2][3] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = $character[3][5] = $character[3][6] = '_';
	$character[1][0] = $character[1][4] = $character[2][2] = $character[2][6] = $character[3][0] = '(';
	$character[1][3] = $character[1][7] = $character[2][1] = $character[2][5] = $character[3][7] = ')';
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][4] = '_';
	$character[1][2] = $character[2][1] = $character[3][2] = '\\';
	$character[1][0] = '(';
	$character[1][3] = $character[2][4] = $character[3][3] = '/';
	$character[1][5] = ')';
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][6] = $character[3][1] = $character[3][2] = $character[3][5] = $character[3][6] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[1][7] = $character[3][7] = ')';
	$character[1][3] = $character[1][5] = $character[3][3] = '/';
	$character[1][2] = $character[1][4] = $character[3][4] = '\\';
	$character[2][1] = ')';
	$character[2][6] = '(';
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][4] = $character[3][1] = $character[3][4] = '_';
	$character[1][0] = $character[2][4] = $character[3][0] = '(';
	$character[1][2] = $character[3][3] = '\\';
	$character[1][3] = $character[3][2] = '/';
	$character[1][5] = $character[2][1] = $character[3][5] = ')';
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][4] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[3][1] = '(';
	$character[1][5] = $character[3][4] = ')';
	$character[1][2] = $character[2][1] = '\\';
	$character[1][3] = $character[2][4] = '/';
	return \@character;
};

function character_Z => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][1] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[1][5] = $character[3][5] = ')';
	$character[2][1] = $character[2][3] = '/';
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
	my @character = $_[0]->default_character(7);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[3][2] = $character[3][3] = $character[3][4] = $character[1][3] = $character[2][3] = '_';
	$character[1][1] = $character[3][5] = '/';
	$character[1][5] = $character[3][1] = '\\';
	$character[2][0] = $character[2][2] = '(';
	$character[2][4] = $character[2][6] = ')';
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[3][1] = $character[3][2] = '_';
	$character[1][0] = '/';
	$character[1][3] = $character[2][1] = $character[3][3] = ')';
	$character[2][2] = $character[3][0] = '(';
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][1] = $character[1][2] = $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[2][1] = $character[2][4] = '/';
	$character[1][4] = '\\';
	$character[3][5] = ')';
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][1] = $character[1][2] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[3][0] = $character[2][1] = '(';
	$character[3][4] = '/';
	$character[2][4] = '\\';
	$character[1][4] = ')';
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[0][3] = $character[2][4] = $character[2][1] = $character[3][3] = '_';
	$character[2][0] = $character[3][2] = '(';
	$character[1][1] = '/';
	$character[1][4] = '|';
	$character[1][2] = '.';
	$character[2][5] = $character[3][4] = ')';
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][2] = $character[1][3] = $character[2][1] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[2][0] = '|';
	$character[1][4] = ')';
	$character[3][0] = '(';
	$character[2][4] = '\\';
	$character[3][4] = '/';
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][2] = $character[2][2] = '_';
	$character[1][1] = $character[2][0] = $character[3][4] = '/';
	$character[3][0] = $character[2][4] = '\\';
	$character[1][3] = ')';
	$character[3][1] = $character[3][2] = $character[3][3] = '_';
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][1] = $character[1][2] = $character[3][1] = '_';
	$character[2][1] = $character[2][3] = $character[3][2] = '/';
	$character[1][0] = $character[3][0] = '(';
	$character[1][4] = ')';
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][2] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[2][0] = $character[3][4] = '/';
	$character[2][4] = $character[3][0] = '\\';
	$character[1][0] = '(';
	$character[1][4] = ')';
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] =  $character[1][2] =  $character[2][1] =  $character[3][2] = '_';
	$character[1][0] = $character[2][4] =  $character[3][3] = '/';
	$character[1][4] =  $character[2][0] = '\\';
	$character[3][1] = '(';
	return \@character;
};

function space => sub {
	my @character = $_[0]->default_character(6);
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Amongus - Amongus font

=head1 VERSION

Version 0.21

=cut

=head1 SYNOPSIS

	use Ascii::Text::Font::Amongus;

	my $font = Ascii::Text::Font::Amongus->new();

	$font->character_A;

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Ascii::Text::Font::Amongus object.

	my $font = Ascii::Text::Font::Amongus->new();

=head2 character_A

	   __   
	  /__\  
	 /(__)\ 
	(__)(__)

=head2 character_B

	 ____ 
	(  _ \
	 ) _ <
	(____/

=head2 character_C

	  ___ 
	 / __)
	( (__ 
	 \___)

=head2 character_D

	 ____  
	(  _ \ 
	 )(_) )
	(____/ 

=head2 character_E

	 ____ 
	( ___)
	 )__) 
	(____)

=head2 character_F

	 ____ 
	( ___)
	 )__) 
	(__)  

=head2 character_G

	  ___ 
	 / __)
	( (_-.
	 \___/

=head2 character_H

	 _   _ 
	( )_( )
	 ) _ ( 
	(_) (_)

=head2 character_I

	 ____ 
	(_  _)
	 _)(_ 
	(____)

=head2 character_J

	  ____ 
	 (_  _)
	.-_)(  
	\____) 

=head2 character_K

	 _  _ 
	( )/ )
	 )  ( 
	(_)\_)

=head2 character_L

	 __   
	(  )  
	 )(__ 
	(____)

=head2 character_M

	 __  __ 
	(  \/  )
	 )    ( 
	(_/\/\_)


=head2 character_N

	 _  _ 
	( \( )
	 )  ( 
	(_)\_)

=head2 character_O

	 _____ 
	(  _  )
	 )(_)( 
	(_____)

=head2 character_P

	 ____ 
	(  _ \
	 )___/
	(__)

=head2 character_Q

	 _____ 
	(  _  )
	 )(_)( 
	(___/\\

=head2 character_R

	 ____ 
	(  _ \
	 )   /
	(_)\_)

=head2 character_S

	 ___ 
	/ __)
	\__ \
	(___/

=head2 character_T

	 ____ 
	(_  _)
	  )(  
	 (__) 

=head2 character_U

	 __  __ 
	(  )(  )
	 )(__)( 
	(______)

=head2 character_V

	 _  _ 
	( \/ )
	 \  / 
	  \/

=head2 character_W

	 _    _ 
	( \/\/ )
	 )    ( 
	(__/\__)

=head2 character_X

	 _  _ 
	( \/ )
	 )  ( 
	(_/\_)

=head2 character_Y

	 _  _ 
	( \/ )
	 \  / 
	 (__)

=head2 character_Z

	 ____ 
	(_   )
	 / /_ 
	(____)


=head2 character_a

	   __   
	  /__\  
	 /(__)\ 
	(__)(__)

=head2 character_b

	 ____ 
	(  _ \
	 ) _ <
	(____/

=head2 character_c

	  ___ 
	 / __)
	( (__ 
	 \___)

=head2 character_d

	 ____  
	(  _ \ 
	 )(_) )
	(____/ 

=head2 character_e

	 ____ 
	( ___)
	 )__) 
	(____)

=head2 character_f

	 ____ 
	( ___)
	 )__) 
	(__)  

=head2 character_g

	  ___ 
	 / __)
	( (_-.
	 \___/

=head2 character_h

	 _   _ 
	( )_( )
	 ) _ ( 
	(_) (_)

=head2 character_i

	 ____ 
	(_  _)
	 _)(_ 
	(____)

=head2 character_j

	  ____ 
	 (_  _)
	.-_)(  
	\____) 

=head2 character_k

	 _  _ 
	( )/ )
	 )  ( 
	(_)\_)

=head2 character_l

	 __   
	(  )  
	 )(__ 
	(____)

=head2 character_m

	 __  __ 
	(  \/  )
	 )    ( 
	(_/\/\_)


=head2 character_n

	 _  _ 
	( \( )
	 )  ( 
	(_)\_)

=head2 character_o

	 _____ 
	(  _  )
	 )(_)( 
	(_____)

=head2 character_p

	 ____ 
	(  _ \
	 )___/
	(__)

=head2 character_q

	 _____ 
	(  _  )
	 )(_)( 
	(___/\\

=head2 character_r

	 ____ 
	(  _ \
	 )   /
	(_)\_)

=head2 character_s

	 ___ 
	/ __)
	\__ \
	(___/

=head2 character_t

	 ____ 
	(_  _)
	  )(  
	 (__) 

=head2 character_u

	 __  __ 
	(  )(  )
	 )(__)( 
	(______)

=head2 character_v

	 _  _ 
	( \/ )
	 \  / 
	  \/

=head2 character_w

	 _    _ 
	( \/\/ )
	 )    ( 
	(__/\__)

=head2 character_x

	 _  _ 
	( \/ )
	 )  ( 
	(_/\_)

=head2 character_y

	 _  _ 
	( \/ )
	 \  / 
	 (__)

=head2 character_z

	 ____ 
	(_   )
	 / /_ 
	(____)


=head2 character_0
	  ___  
	 / _ \ 
	( (_) )
	 \___/ 

=head2 character_1

	 __ 
	/  )
	 )( 
	(__)

=head2 character_2

	 ___  
	(__ \ 
	 / _/ 
	(____)

=head2 character_3

	 ___ 
	(__ )
	 (_ \
	(___/

=head2 character_4

	  __  
	 /. | 
	(_  _)
	  (_) 

=head2 character_5

	 ___ 
	| __)
	|__ \
	(___/

=head2 character_6

	  _  
	 / ) 
	/ _ \
	\___/

=head2 character_7

	 ___ 
	(__ )
	 / / 
	(_/ 
       
=head2 character_8

	 ___ 
	( _ )
	/ _ \
	\___/

=head2 character_9

	 ___ 
	/ _ \
	\_  /
	 (_/ 
       
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



