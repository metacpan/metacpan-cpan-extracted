package Ascii::Text::Font::Straight;

use Moo;

extends 'Ascii::Text::Font';

has character_height => (
	is => 'ro',
	default => sub { 4 }
);

sub character_A {
	my @character = $_[0]->default_character(4);
	$character[1][1] = $character[2][0] = '/';
	$character[1][2] = $character[2][3] = '\\';
	$character[2][1] = $character[2][2] = '-';
	return \@character;
}

sub character_B {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][3] = ' ';
	$character[2][1] = $character[2][2] = $character[1][1] = $character[1][2] = $character[0][1] = $character[0][2] = '_';
	$character[2][0] = $character[1][0] = '|';
	$character[2][3] = $character[1][3] = ')';
	return \@character;
}

sub character_C {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[1][1] = $character[1][2] = $character[1][3] = $character[0][3] = $character[2][3] = ' ';
	$character[0][1] = $character[0][2] = '_';
	$character[1][0] = '/';
	$character[2][0] = '\\';
	$character[2][1] = $character[2][2] = '_';
	return \@character;
}

sub character_D {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][3] = $character[1][1] = $character[1][2] = ' ';
	$character[0][1] = $character[0][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = $character[2][0] = '|';
	$character[1][3] = '\\';
	$character[2][3] = '/';
	return \@character;
}

sub character_E {
	my @character = $_[0]->default_character(3);
	$character[0][1] = $character[0][2] = '_';
	$character[1][0] = $character[2][0] = '|';
	$character[1][1] = $character[2][1] = $character[2][2] = '_';
	return \@character;
}

sub character_F {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[2][0] = '|';
	$character[0][1] = $character[0][2] = $character[1][1] = '_';
	return \@character;
}

sub character_G {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[1][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = '/';
	$character[2][0] = '\\';
	$character[2][3] = ')';
	return \@character;
}

sub character_H {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[1][3] = '|';
	$character[2][0] = $character[2][3] = '|';
	$character[1][1] = $character[1][2] = '_';
	return \@character;
}

sub character_I {
	my @character = $_[0]->default_character(1);
	$character[1][0] = $character[2][0] = '|';
	return \@character;
}

sub character_J {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[1][1] = ' ';
	$character[2][0] = $character[2][1] = '_';
	$character[2][2] = ')';
	$character[1][2] = '|';
	return \@character;
}

sub character_K {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[2][0] = '|';
	$character[1][1] = '_';
	$character[1][2] = '/';
	$character[2][2] = '\\';
	$character[2][1] = ' ';
	return \@character;
}

sub character_L {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[2][0] = '|';
	$character[2][1] = $character[2][2] = '_';
	return \@character;
}

sub character_M {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[2][0] = $character[1][3] = $character[2][3] = '|';
	$character[1][1] = '\\';
	$character[1][2] = '/';
	return \@character;
}

sub character_N {
	my @character = $_[0]->default_character(4);
	$character[1][0] = '|';
	$character[1][1] = '\\';
	$character[1][2] = ' ';
	$character[1][3] = '|';
	$character[2][0] = '|';
	$character[2][1] = ' ';
	$character[2][2] = '\\';
	$character[2][3] = '|';
	return \@character;
}

sub character_O {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = $character[2][3] = '/';
	$character[2][0] = $character[1][3] = '\\';
	return \@character;
}

sub character_P {
	my @character = $_[0]->default_character(4);
	$character[0][0] = ' ', $character[0][1] = $character[0][2] = '_';
	$character[1][0] = '|', $character[1][1] = $character[1][2] = '_', $character[1][3] = ')';
	$character[2][0] = '|', $character[2][1] = $character[2][2] = ' ';
	return \@character;
}

sub character_Q {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[2][1] = '_';
	$character[1][0] = $character[2][3] = '/';
	$character[2][0] = $character[1][3] = $character[2][2] = '\\';
	return \@character;
}

sub character_R {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[1][1] = $character[1][2] = '_';
	$character[1][0] = $character[2][0] = '|';
	$character[2][2] = '\\';
	$character[1][3] = ')';
	return \@character;
}

sub character_S {
	my @character = $_[0]->default_character(3);
	$character[1][1] = $character[0][1] = $character[0][2] = $character[2][0] = $character[2][1] = '_';
	$character[1][0] = '(';
	$character[2][2] = ')';
	return \@character;
}

sub character_T {
	my @character = $_[0]->default_character(3);
	$character[0][0] = $character[0][1] = $character[0][2] = '_';
	$character[1][1] = $character[2][1] = '|';
	return \@character;
}

sub character_U {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[2][3] = '/';
	$character[1][3] = $character[2][0] = '\\';
	$character[2][1] = $character[2][2] = '_';
	return \@character;
}

sub character_V {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[2][1] = '\\';
	$character[1][3] = $character[2][2] = '/';
	return \@character;
}

sub character_W {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[1][3] = $character[2][0] = $character[2][3] = '|';
	$character[1][1] = $character[1][2] = ' ';
	$character[2][1] = '/';
	$character[2][2] = '\\';
	return \@character;
}

sub character_X {
	my @character = $_[0]->default_character(3);
	$character[0][0] = $character[2][2] = '\\';
	$character[0][2] = $character[2][0] = '/';
	$character[1][1] = '-';
	return \@character;
}

sub character_Y {
	my @character = $_[0]->default_character(3);
	$character[0][0] = '\\';
	$character[0][2] = '/';
	$character[1][1] = '-';
	$character[2][1] = '|';
	return \@character;
}

sub character_Z {
	my @character = $_[0]->default_character(3);
	$character[0][0] = '_';
	$character[0][1] = '_';
	$character[0][2] = '_';
	$character[1][2] = '/';
	$character[1][1] = '_';
	$character[1][0] = ' ';
	$character[2][0] = '/';
	$character[2][1] = '_';
	$character[2][2] = '_';
	return \@character;
}

sub character_a {
	my @character = $_[0]->default_character(3);
	$character[1][1] = '_';
	$character[2][0] = '(';
	$character[2][1] = '_';
	$character[2][2] = '|';
	return \@character;
}

sub character_b {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[2][0] = '|';
	$character[1][1] = $character[2][1] = '_';
	$character[2][2] = ')';
	return \@character;
}

sub character_c {
	my @character = $_[0]->default_character(2);
	$character[1][0] = ' ';
	$character[2][0] = '(';
	$character[1][1] = $character[2][1] = '_';
	return \@character;
}

sub character_d {
	my @character = $_[0]->default_character(3);
	$character[1][2] = '|';
	$character[1][1] = '_';
	$character[2][0] = '(';
	$character[2][2] = '|';
	$character[2][1] = '_';
	return \@character;
}

sub character_e {
	my @character = $_[0]->default_character(2);
	$character[1][1] = '_';
	$character[2][0] = '(';
	$character[2][1] = '-';
	return \@character;
}

sub character_f {
	my @character = $_[0]->default_character(2);
	$character[0][1] = '_';
	$character[1][0] = '(';
	$character[1][1] = '_';
	$character[2][0] = '|';
	return \@character;
}

sub character_g {
	my @character = $_[0]->default_character(3);
	$character[1][1] = $character[2][1] = $character[3][0] = '_';
	$character[2][2] = ')';
	$character[2][0] = '(';
	$character[3][1] = '/';
	return \@character;
}

sub character_h {
	my @character = $_[0]->default_character(3);
	$character[1][0] = '|';
	$character[1][1] = '_';
	$character[2][0] = '|';
	$character[2][2] = ')';
	return \@character;
}

sub character_i {
	my @character = $_[0]->default_character(1);
	$character[1][0] = '.';
	$character[2][0] = '|';
	return \@character;
}

sub character_j {
	my @character = $_[0]->default_character(2);
	$character[1][1] = '.';
	$character[2][1] = '|';
	$character[3][1] = '/';
	return \@character;
}

sub character_k {
	my @character = $_[0]->default_character(2);
	$character[1][0] = $character[2][0] = '|';
	$character[2][1] = '(';
	return \@character;
}

sub character_l {
	my @character = $_[0]->default_character(1);
  	$character[1][0] = '|';
	$character[2][0] = '|';
	return \@character;
}

sub character_m {
	my @character = $_[0]->default_character(4);
	$character[1][1] = '_';
	$character[2][0] = '|';
	$character[2][2] = '|';
	$character[1][2] = '_';
	$character[2][3] = ')'; 
	return \@character;
}

sub character_n {
	my @character = $_[0]->default_character(3);
	$character[1][1] = '_';
	$character[2][0] = '|';
	$character[2][2] = ')';
	return \@character;
}

sub character_o {
	my @character = $_[0]->default_character(3);
	$character[1][1] = $character[2][1] = '_';
	$character[2][0] = '(';
	$character[2][2] = ')';
	return \@character;
}

sub character_p {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[2][0] = '|';
	$character[0][1] = $character[1][1] = '_';
	$character[1][2] = ')';
	return \@character;
}

sub character_q {
	my @character = $_[0]->default_character(4);
	$character[1][2] = '_';
	$character[2][1] = '(';
	$character[2][2] = '_';
	$character[2][3] = $character[3][3] = '|';
	return \@character;
}

sub character_r {
	my @character = $_[0]->default_character(2);
	$character[1][1] = '_';
	$character[2][0] = '|';
	return \@character;
}

sub character_s {
	my @character = $_[0]->default_character(2);
	$character[1][1] = '_';
	$character[2][0] = '_';
	$character[2][1] = ')';
	return \@character;
}

sub character_t {
	my @character = $_[0]->default_character(2);
	$character[1][0] = $character[2][0] = '|';
	$character[1][1] = $character[2][1] = '_';
	return \@character;
}

sub character_u {
	my @character = $_[0]->default_character(3);
	$character[2][0] = '|';
	$character[2][1] = '_';
	$character[2][2] = '|';
	return \@character;
}

sub character_v {
	my @character = $_[0]->default_character(3);
	$character[2][0] = '\\';
	$character[2][1] = '/';
	return \@character;
}

sub character_w {
	my @character = $_[0]->default_character(3);
	$character[2][0] = '\\';
	$character[2][1] = ')';
	$character[2][2] = '/';
	return \@character;
}

sub character_x {
	my @character = $_[0]->default_character(2);
	$character[2][0] = ')';
	$character[2][1] = '(';
	return \@character;
}

sub character_y {
	my @character = $_[0]->default_character(2);
	$character[1][0] = '\\';
	$character[1][1] = '/';
	$character[2][0] = '/';
	return \@character;
}

sub character_z {
	my @character = $_[0]->default_character(4);
	$character[1][1] = '_';
	$character[2][1] = '/';
	$character[2][2] = '_';
	$character[3][3] = ' ';
	return \@character;
}

sub character_0 {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][3] = $character[1][1] = $character[1][2] = ' ';
	$character[0][1] = $character[0][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = $character[2][3] = $character[1][3] = $character[2][0] = '|';
	return \@character;
}

sub character_1 {
	my @character = $_[0]->default_character(3);
	$character[1][1] = '/';
	$character[1][2] = $character[2][2] = '|';
	return \@character;
}

sub character_2 {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[2][2] = $character[2][3] = $character[1][2] = '_';
	$character[1][3] = ')';
	$character[2][1] = '/';
	return \@character;
}

sub character_3 {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[2][1] = $character[2][2] = $character[1][2] = '_';
	$character[1][3] = $character[2][3] = ')';
	return \@character;
}

sub character_4 {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3] = ' ';
	$character[1][1] = $character[1][2] = '_';
	$character[1][0] = $character[1][3] = $character[2][3] = '|';
	return \@character;
}

sub character_5 {
	my @character = $_[0]->default_character(4);
	$character[0][1] = '_';
	$character[0][2] = '_';
	$character[1][0] = '|';
	$character[1][1] = '_';
	$character[2][2] = ')';
	$character[2][0] = $character[2][1] = '_';
	return \@character;
}

sub character_6 {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[1][1] = $character[1][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = '/';
	$character[2][0] = '\\';
	$character[2][3] = ')';
	return \@character;
}

sub character_7 {
	my @character = $_[0]->default_character(4);
	$character[0][0] = '_';
	$character[0][1] = '_';
	$character[0][2] = '_';
	$character[1][2] = '/';
	$character[2][1] = '/';
	return \@character;
}

sub character_8 {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[1][1] = $character[1][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = $character[2][0] = '(';
	$character[1][3] = $character[2][3] = ')';
	return \@character;
}

sub character_9 {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[1][1] = $character[1][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = '(';
	$character[2][3] = '/';
	$character[1][3] = '\\';
	return \@character;
}

sub space {
	my @character = $_[0]->default_character(3);
	return \@character;
}

1;

__END__

=head1 NAME

Ascii::Text::Font::Straight - Straight font

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use Ascii::Text::Font::Straight;

	my $font = Ascii::Text::Font::Straight->new();

	$font->character_A;

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Ascii::Text::Font::Straight object.

	my $font = Ascii::Text::Font::Straight->new();

=head2 character_A

	 /\
	/--\

=head2 character_B

	 __
	|__)
	|__)

=head2 character_C

	 __
	/
	\__

=head2 character_D

	 __
	|  \
	|__/

=head2 character_E

	 __
	|_
	|__

=head2 character_F

	 __
	|_
	|


=head2 character_G

	 __
	/ _
	\__)


=head2 character_H

	|__|
	|  |

=head2 character_I

	|
	|

=head2 character_J

	  |
	__)

=head2 character_K

	|_/
	| \

=head2 character_L

	|
	|__

=head2 character_M

	|\/|
	|  |

=head2 character_N

	|\ |
	| \|

=head2 character_O

	 __
	/  \
	\__/

=head2 character_P

	 __
	|__)
	|

=head2 character_Q

	 __
	/  \
	\_\/

=head2 character_R

	 __
	|__)
	| \

=head2 character_S

	 __
	(_
	__)

=head2 character_T

	___
	 |
	 |

=head2 character_U

	/  \
	\__/

=head2 character_V

	\  /
	 \/

=head2 character_W

	|  |
	|/\|

=head2 character_X

	\_/
	/ \

=head2 character_Y

	\_/
	 |

=head2 character_Z

	___
	 _/
	/__

=head2 character_a

	 _
	(_|

=head2 character_b

	|_
	|_)

=head2 character_c

	 _
	(_

=head2 character_d

	 _|
	(_|

=head2 character_e

	 _
	(-

=head2 character_f

	 _
	(_
	|

=head2 character_g

	 _
	(_)
	_/

=head2 character_h

	|_
	| )

=head2 character_i

	.
	|

=head2 character_j

	.
	|
	/

=head2 character_k

	|
	|(

=head2 character_l

	|
	|

=head2 character_m

	 _
	|||

=head2 character_n

	 _
	| )

=head2 character_o

	 _
	(_)

=head2 character_p

	 _
	|_)
	|

=head2 character_q

	 _
	(_|
	  |

=head2 character_r

	 _
	|

=head2 character_s

	 _
	_)

=head2 character_t

	|_
	|_

=head2 character_u

	|_|

=head2 character_v

	\/

=head2 character_w

	\)/

=head2 character_x

	)(

=head2 character_y

	\/
	/

=head2 character_z

	_
	/_

=head2 character_0

	  __
	 /  \
	 \__/

=head2 character_1

	 /|
	  |

=head2 character_2

	 __
	  _)
	 /__

=head2 character_3

	 __
	  _)
	 __)

=head2 character_4

	|__|
	   |

=head2 character_5

	  __
	 |_
	 __)

=head2 character_6

	  __
	 /__
	 \__)


=head2 character_7

	 ___
	   /
	  /
       
=head2 character_8

	  __
	 (__)
	 (__)

=head2 character_9
 
	  __
	 (__\
	  __/
	       
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



