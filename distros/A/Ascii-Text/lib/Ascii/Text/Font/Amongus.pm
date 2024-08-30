package Ascii::Text::Font::Amongus;

use Moo;

extends 'Ascii::Text::Font';

has character_height => (
	is => 'ro',
	default => sub { 4 }
);

sub character_A {
	my @character = $_[0]->default_character(8);
	$character[0][3] = $character[0][4] = $character[1][3] = $character[1][4] = $character[2][3] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][5] = $character[3][6] = '_';
	$character[1][2] = $character[2][1] = '/';
	$character[1][5] = $character[2][6] = '\\';
	$character[3][0] = $character[2][2] = $character[3][4] = '(';
	$character[2][5] = $character[3][3] = $character[3][7] = ')';
	return \@character;
}

sub character_B {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[2][1] = ')';
	$character[1][5] = '\\';
	$character[2][5] = '<';
	$character[3][5] = '/';
	return \@character;
}

sub character_C {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[1][4] = $character[2][3] = $character[2][4] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][5] = $character[3][5] = ')';
	$character[2][0] = $character[2][2] = '(';
	$character[1][1] = '/';
	$character[3][1] = '\\';
	return \@character;
}

sub character_D {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][4] = $character[0][2] = $character[0][3] = $character[1][3] = $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = $character[2][2] = '(';
	$character[2][1] = $character[2][4] = $character[2][6] = ')';
	$character[1][5] = '\\';
	$character[3][5] = '/';
	return \@character;
}

sub character_E {
	my @character = $_[0]->default_character(6);
	$character[1][0] = $character[3][0] = '(';
	$character[1][5] = $character[2][1] = $character[2][4] = $character[3][5] = ')';
	$character[1][2] = $character[1][3] = $character[1][4] = $character[2][2] = $character[2][3] = $character[3][2] = $character[3][3] = $character[3][4] = $character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = '_';
	return \@character;
}

sub character_F {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][2] = $character[1][3] = $character[1][4] = $character[2][2] = $character[2][3] = $character[3][1] = $character[3][2] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[1][5] = $character[2][1] = $character[2][4] = $character[3][3] = ')';
	return \@character;
}

sub character_G {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[1][4] = $character[2][3] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[2][0] = $character[2][2] = '(';
	$character[1][5] = ')';
	$character[1][1] = $character[3][5] = '/';
	$character[3][1] = '\\';
	$character[2][4] = '-';
	$character[2][5] = '.';
	return \@character;
}

sub character_H {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][5] = $character[1][3] = $character[2][3] = $character[3][1] = $character[3][5] = '_';
	$character[1][0] = $character[1][4] = $character[2][5] = $character[3][0] = $character[3][4] = '(';
	$character[1][2] = $character[1][6] = $character[2][1] = $character[3][2] = $character[3][6] = ')';
	return \@character;
}

sub character_I {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][1] = $character[1][4] = $character[2][1] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = $character[2][3] = '(';
	$character[1][5] = $character[3][5] = $character[2][2] = ')';
	return \@character;
}

sub character_J {
	my @character = $_[0]->default_character(7);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[1][2] = $character[1][5] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][1] = $character[2][4] = '(';
	$character[1][6] = $character[2][3] = $character[3][5] = ')';
	$character[2][0] = '.';
	$character[2][1] = '-';
	$character[3][0] = '\\';
	return \@character;
}

sub character_K {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][4] = $character[3][1] = $character[3][4] = '_';
	$character[1][0] = $character[2][4] = $character[3][0] = '(';
	$character[1][2] = $character[1][5] = $character[2][1] = $character[3][2] = $character[3][5] = ')';
	$character[1][3] = '/';
	$character[3][3] = '\\';
	return \@character;
}

sub character_L {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[2][3] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[2][2] = $character[3][0] = '(';
	$character[1][3] = $character[2][1] = $character[3][5] = ')';
	return \@character;
}

sub character_M {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][5] = $character[0][6] = $character[3][1] = $character[3][6] = '_';
	$character[1][0] = $character[2][6] = $character[3][0] = '(';
	$character[1][7] = $character[2][1] = $character[3][7] = ')';
	$character[1][3] = $character[3][3] = $character[3][5] = '\\';
	$character[1][4] = $character[3][2] = $character[3][4] = '/';
	return \@character;
}

sub character_N {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][4] = $character[3][1] = $character[3][4] = '_';
	$character[1][0] = $character[1][3] = $character[2][4] = $character[3][0] = '(';
	$character[1][5] = $character[2][1] = $character[3][2] = $character[3][5] = ')';
	$character[1][2] = $character[3][3] = '\\';
	return \@character;
}

sub character_O {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = $character[3][5] = $character[1][3] = $character[2][3] = '_';
	$character[1][0] = $character[3][0] = $character[2][2] = $character[2][5] = '(';
	$character[1][6] = $character[2][1] = $character[2][4] = $character[3][6] = ')';
	return \@character;
}

sub character_P {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[2][2] = $character[2][3] = $character[2][4] = $character[3][1] = $character[3][2] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[2][1] = $character[3][3] = ')';
	$character[1][5] = '\\';
	$character[2][5] = '/';
	return \@character;
}

sub character_Q {
	my @character = $_[0]->default_character(7);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[0][5] = $character[3][1] = $character[3][2] = $character[3][3] = $character[1][3] = $character[2][3] = '_';
	$character[1][0] = $character[3][0] = $character[2][2] = $character[2][5] = '(';
	$character[1][6] = $character[2][1] = $character[2][4] = ')';
	$character[3][4] = '/';
	$character[3][5] = $character[3][6] = '\\';
	return \@character;
}

sub character_R {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][3] = $character[3][1] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[2][1] = $character[3][2] = $character[3][5] = ')';
	$character[3][3] = $character[1][5] = '\\';
	$character[2][5] = '/';
	return \@character;
}

sub character_S {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][2] = $character[1][3] = $character[2][1] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[3][4] = '/';
	$character[1][1] = $character[2][3] = ' ';
	$character[2][0] = $character[2][4] = '\\';
	$character[1][4] = ')';
	$character[3][0] = '(';
	return \@character;
}

sub character_T {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][1] = $character[1][4] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[2][3] = $character[3][1] = '(';
	$character[1][5] = $character[2][2] = $character[3][4] = ')';
	return \@character;
}

sub character_U {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][2] = $character[0][5] = $character[0][6] = $character[2][3] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = $character[3][5] = $character[3][6] = '_';
	$character[1][0] = $character[1][4] = $character[2][2] = $character[2][6] = $character[3][0] = '(';
	$character[1][3] = $character[1][7] = $character[2][1] = $character[2][5] = $character[3][7] = ')';
	return \@character;
}

sub character_V {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][4] = '_';
	$character[1][2] = $character[2][1] = $character[3][2] = '\\';
	$character[1][0] = '(';
	$character[1][3] = $character[2][4] = $character[3][3] = '/';
	$character[1][5] = ')';
	return \@character;
}

sub character_W {
	my @character = $_[0]->default_character(8);
	$character[0][1] = $character[0][6] = $character[3][1] = $character[3][2] = $character[3][5] = $character[3][6] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[1][7] = $character[3][7] = ')';
	$character[1][3] = $character[1][5] = $character[3][3] = '/';
	$character[1][2] = $character[1][4] = $character[3][4] = '\\';
	$character[2][1] = ')';
	$character[2][6] = '(';
	return \@character;
}

sub character_X {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][4] = $character[3][1] = $character[3][4] = '_';
	$character[1][0] = $character[2][4] = $character[3][0] = '(';
	$character[1][2] = $character[3][3] = '\\';
	$character[1][3] = $character[3][2] = '/';
	$character[1][5] = $character[2][1] = $character[3][5] = ')';
	return \@character;
}

sub character_Y {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][4] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[3][1] = '(';
	$character[1][5] = $character[3][4] = ')';
	$character[1][2] = $character[2][1] = '\\';
	$character[1][3] = $character[2][4] = '/';
	return \@character;
}

sub character_Z {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[0][4] = $character[1][1] = $character[2][4] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[1][5] = $character[3][5] = ')';
	$character[2][1] = $character[2][3] = '/';
	return \@character;
}

sub character_a { $_[0]->character_A }

sub character_b { $_[0]->character_B }

sub character_c { $_[0]->character_C }

sub character_d { $_[0]->character_D }

sub character_e { $_[0]->character_E }

sub character_f { $_[0]->character_F }

sub character_g { $_[0]->character_G }

sub character_h { $_[0]->character_H }

sub character_i { $_[0]->character_I }

sub character_j { $_[0]->character_J }

sub character_k { $_[0]->character_K }

sub character_l { $_[0]->character_L }

sub character_m { $_[0]->character_M }

sub character_n { $_[0]->character_N }

sub character_o { $_[0]->character_O }

sub character_p { $_[0]->character_P }

sub character_q { $_[0]->character_Q }

sub character_r { $_[0]->character_R }

sub character_s { $_[0]->character_S }

sub character_t { $_[0]->character_T }

sub character_u { $_[0]->character_U }

sub character_v { $_[0]->character_V }

sub character_w { $_[0]->character_W }

sub character_x { $_[0]->character_X }

sub character_y { $_[0]->character_Y }

sub character_z { $_[0]->character_Z }

sub character_0 {
	my @character = $_[0]->default_character(7);
	$character[0][2] = $character[0][3] = $character[0][4] = $character[3][2] = $character[3][3] = $character[3][4] = $character[1][3] = $character[2][3] = '_';
	$character[1][1] = $character[3][5] = '/';
	$character[1][5] = $character[3][1] = '\\';
	$character[2][0] = $character[2][2] = '(';
	$character[2][4] = $character[2][6] = ')';
	return \@character;
}

sub character_1 {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[3][1] = $character[3][2] = '_';
	$character[1][0] = '/';
	$character[1][3] = $character[2][1] = $character[3][3] = ')';
	$character[2][2] = $character[3][0] = '(';
	return \@character;
}

sub character_2 {
	my @character = $_[0]->default_character(6);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][1] = $character[1][2] = $character[2][3] = $character[3][1] = $character[3][2] = $character[3][3] = $character[3][4] = '_';
	$character[1][0] = $character[3][0] = '(';
	$character[2][1] = $character[2][4] = '/';
	$character[1][4] = '\\';
	$character[3][5] = ')';
	return \@character;
}

sub character_3 {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][1] = $character[1][2] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[3][0] = $character[2][1] = '(';
	$character[3][4] = '/';
	$character[2][4] = '\\';
	$character[1][4] = ')';
	return \@character;
}

sub character_4 {
	my @character = $_[0]->default_character(6);
	$character[0][2] = $character[0][3] = $character[2][4] = $character[2][1] = $character[3][3] = '_';
	$character[2][0] = $character[3][2] = '(';
	$character[1][1] = '/';
	$character[1][4] = '|';
	$character[1][2] = '.';
	$character[2][5] = $character[3][4] = ')';
	return \@character;
}

sub character_5 {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][2] = $character[1][3] = $character[2][1] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[1][0] = $character[2][0] = '|';
	$character[1][4] = ')';
	$character[3][0] = '(';
	$character[2][4] = '\\';
	$character[3][4] = '/';
	return \@character;
}

sub character_6 {
	my @character = $_[0]->default_character(5);
	$character[0][2] = $character[2][2] = '_';
	$character[1][1] = $character[2][0] = $character[3][4] = '/';
	$character[3][0] = $character[2][4] = '\\';
	$character[1][3] = ')';
	$character[3][1] = $character[3][2] = $character[3][3] = '_';
	return \@character;
}

sub character_7 {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][1] = $character[1][2] = $character[3][1] = '_';
	$character[2][1] = $character[2][3] = $character[3][2] = '/';
	$character[1][0] = $character[3][0] = '(';
	$character[1][4] = ')';
	return \@character;
}

sub character_8 {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] = $character[1][2] = $character[2][2] = $character[3][1] = $character[3][2] = $character[3][3] = '_';
	$character[2][0] = $character[3][4] = '/';
	$character[2][4] = $character[3][0] = '\\';
	$character[1][0] = '(';
	$character[1][4] = ')';
	return \@character;
}

sub character_9 {
	my @character = $_[0]->default_character(5);
	$character[0][1] = $character[0][2] = $character[0][3] =  $character[1][2] =  $character[2][1] =  $character[3][2] = '_';
	$character[1][0] = $character[2][4] =  $character[3][3] = '/';
	$character[1][4] =  $character[2][0] = '\\';
	$character[3][1] = '(';
	return \@character;
}

sub space {
	my @character = $_[0]->default_character(6);
	return \@character;
}

1;

__END__

=head1 NAME

Ascii::Text::Font::Amongus - Amongus font

=head1 VERSION

Version 0.04

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



