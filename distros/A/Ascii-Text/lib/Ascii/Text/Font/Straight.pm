package Ascii::Text::Font::Straight;

use Rope;
use Rope::Autoload;

extends 'Ascii::Text::Font';

property character_height => (
	initable => 0,
	writeable => 0,
	value => 4
);

function character_A => sub {
	my @character = $_[0]->default_character(4);
	$character[1][1] = $character[2][0] = '/';
	$character[1][2] = $character[2][3] = '\\';
	$character[2][1] = $character[2][2] = '-';
	return \@character;
};

function character_B => sub {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][3] = ' ';
	$character[2][1] = $character[2][2] = $character[1][1] = $character[1][2] = $character[0][1] = $character[0][2] = '_';
	$character[2][0] = $character[1][0] = '|';
	$character[2][3] = $character[1][3] = ')';
	return \@character;
};

function character_C => sub {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[1][1] = $character[1][2] = $character[1][3] = $character[0][3] = $character[2][3] = ' ';
	$character[0][1] = $character[0][2] = '_';
	$character[1][0] = '/';
	$character[2][0] = '\\';
	$character[2][1] = $character[2][2] = '_';
	return \@character;
};

function character_D => sub {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][3] = $character[1][1] = $character[1][2] = ' ';
	$character[0][1] = $character[0][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = $character[2][0] = '|';
	$character[1][3] = '\\';
	$character[2][3] = '/';
	return \@character;
};

function character_E => sub {
	my @character = $_[0]->default_character(3);
	$character[0][1] = $character[0][2] = '_';
	$character[1][0] = $character[2][0] = '|';
	$character[1][1] = $character[2][1] = $character[2][2] = '_';
	return \@character;
};

function character_F => sub {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[2][0] = '|';
	$character[0][1] = $character[0][2] = $character[1][1] = '_';
	return \@character;
};

function character_G => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[1][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = '/';
	$character[2][0] = '\\';
	$character[2][3] = ')';
	return \@character;
};

function character_H => sub {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[1][3] = '|';
	$character[2][0] = $character[2][3] = '|';
	$character[1][1] = $character[1][2] = '_';
	return \@character;
};

function character_I => sub {
	my @character = $_[0]->default_character(1);
	$character[1][0] = $character[2][0] = '|';
	return \@character;
};

function character_J => sub {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[1][1] = ' ';
	$character[2][0] = $character[2][1] = '_';
	$character[2][2] = ')';
	$character[1][2] = '|';
	return \@character;
};

function character_K => sub {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[2][0] = '|';
	$character[1][1] = '_';
	$character[1][2] = '/';
	$character[2][2] = '\\';
	$character[2][1] = ' ';
	return \@character;
};

function character_L => sub {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[2][0] = '|';
	$character[2][1] = $character[2][2] = '_';
	return \@character;
};

function character_M => sub {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[2][0] = $character[1][3] = $character[2][3] = '|';
	$character[1][1] = '\\';
	$character[1][2] = '/';
	return \@character;
};

function character_N => sub {
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
};

function character_O => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = $character[2][3] = '/';
	$character[2][0] = $character[1][3] = '\\';
	return \@character;
};

function character_P => sub {
	my @character = $_[0]->default_character(4);
	$character[0][0] = ' ', $character[0][1] = $character[0][2] = '_';
	$character[1][0] = '|', $character[1][1] = $character[1][2] = '_', $character[1][3] = ')';
	$character[2][0] = '|', $character[2][1] = $character[2][2] = ' ';
	return \@character;
};

function character_Q => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[2][1] = '_';
	$character[1][0] = $character[2][3] = '/';
	$character[2][0] = $character[1][3] = $character[2][2] = '\\';
	return \@character;
};

function character_R => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[1][1] = $character[1][2] = '_';
	$character[1][0] = $character[2][0] = '|';
	$character[2][2] = '\\';
	$character[1][3] = ')';
	return \@character;
};

function character_S => sub {
	my @character = $_[0]->default_character(3);
	$character[1][1] = $character[0][1] = $character[0][2] = $character[2][0] = $character[2][1] = '_';
	$character[1][0] = '(';
	$character[2][2] = ')';
	return \@character;
};

function character_T => sub {
	my @character = $_[0]->default_character(3);
	$character[0][0] = $character[0][1] = $character[0][2] = '_';
	$character[1][1] = $character[2][1] = '|';
	return \@character;
};

function character_U => sub {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[2][3] = '/';
	$character[1][3] = $character[2][0] = '\\';
	$character[2][1] = $character[2][2] = '_';
	return \@character;
};

function character_V => sub {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[2][1] = '\\';
	$character[1][3] = $character[2][2] = '/';
	return \@character;
};

function character_W => sub {
	my @character = $_[0]->default_character(4);
	$character[1][0] = $character[1][3] = $character[2][0] = $character[2][3] = '|';
	$character[1][1] = $character[1][2] = ' ';
	$character[2][1] = '/';
	$character[2][2] = '\\';
	return \@character;
};

function character_X => sub {
	my @character = $_[0]->default_character(3);
	$character[0][0] = $character[2][2] = '\\';
	$character[0][2] = $character[2][0] = '/';
	$character[1][1] = '-';
	return \@character;
};

function character_Y => sub {
	my @character = $_[0]->default_character(3);
	$character[0][0] = '\\';
	$character[0][2] = '/';
	$character[1][1] = '-';
	$character[2][1] = '|';
	return \@character;
};

function character_Z => sub {
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
};

function character_a => sub {
	my @character = $_[0]->default_character(3);
	$character[1][1] = '_';
	$character[2][0] = '(';
	$character[2][1] = '_';
	$character[2][2] = '|';
	return \@character;
};

function character_b => sub {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[2][0] = '|';
	$character[1][1] = $character[2][1] = '_';
	$character[2][2] = ')';
	return \@character;
};

function character_c => sub {
	my @character = $_[0]->default_character(2);
	$character[1][0] = ' ';
	$character[2][0] = '(';
	$character[1][1] = $character[2][1] = '_';
	return \@character;
};

function character_d => sub {
	my @character = $_[0]->default_character(3);
	$character[1][2] = '|';
	$character[1][1] = '_';
	$character[2][0] = '(';
	$character[2][2] = '|';
	$character[2][1] = '_';
	return \@character;
};

function character_e => sub {
	my @character = $_[0]->default_character(2);
	$character[1][1] = '_';
	$character[2][0] = '(';
	$character[2][1] = '-';
	return \@character;
};

function character_f => sub {
	my @character = $_[0]->default_character(2);
	$character[0][1] = '_';
	$character[1][0] = '(';
	$character[1][1] = '_';
	$character[2][0] = '|';
	return \@character;
};

function character_g => sub {
	my @character = $_[0]->default_character(3);
	$character[1][1] = $character[2][1] = $character[3][0] = '_';
	$character[2][2] = ')';
	$character[2][0] = '(';
	$character[3][1] = '/';
	return \@character;
};

function character_h => sub {
	my @character = $_[0]->default_character(3);
	$character[1][0] = '|';
	$character[1][1] = '_';
	$character[2][0] = '|';
	$character[2][2] = ')';
	return \@character;
};

function character_i => sub {
	my @character = $_[0]->default_character(1);
	$character[1][0] = '.';
	$character[2][0] = '|';
	return \@character;
};

function character_j => sub {
	my @character = $_[0]->default_character(2);
	$character[1][1] = '.';
	$character[2][1] = '|';
	$character[3][1] = '/';
	return \@character;
};

function character_k => sub {
	my @character = $_[0]->default_character(2);
	$character[1][0] = $character[2][0] = '|';
	$character[2][1] = '(';
	return \@character;
};

function character_l => sub {
	my @character = $_[0]->default_character(1);
  	$character[1][0] = '|';
	$character[2][0] = '|';
	return \@character;
};

function character_m => sub {
	my @character = $_[0]->default_character(4);
	$character[1][1] = '_';
	$character[2][0] = '|';
	$character[2][2] = '|';
	$character[1][2] = '_';
	$character[2][3] = ')'; 
	return \@character;
};

function character_n => sub {
	my @character = $_[0]->default_character(3);
	$character[1][1] = '_';
	$character[2][0] = '|';
	$character[2][2] = ')';
	return \@character;
};

function character_o => sub {
	my @character = $_[0]->default_character(3);
	$character[1][1] = $character[2][1] = '_';
	$character[2][0] = '(';
	$character[2][2] = ')';
	return \@character;
};

function character_p => sub {
	my @character = $_[0]->default_character(3);
	$character[1][0] = $character[2][0] = '|';
	$character[0][1] = $character[1][1] = '_';
	$character[1][2] = ')';
	return \@character;
};

function character_q => sub {
	my @character = $_[0]->default_character(4);
	$character[1][2] = '_';
	$character[2][1] = '(';
	$character[2][2] = '_';
	$character[2][3] = $character[3][3] = '|';
	return \@character;
};

function character_r => sub {
	my @character = $_[0]->default_character(2);
	$character[1][1] = '_';
	$character[2][0] = '|';
	return \@character;
};

function character_s => sub {
	my @character = $_[0]->default_character(2);
	$character[1][1] = '_';
	$character[2][0] = '_';
	$character[2][1] = ')';
	return \@character;
};

function character_t => sub {
	my @character = $_[0]->default_character(2);
	$character[1][0] = $character[2][0] = '|';
	$character[1][1] = $character[2][1] = '_';
	return \@character;
};

function character_u => sub {
	my @character = $_[0]->default_character(3);
	$character[2][0] = '|';
	$character[2][1] = '_';
	$character[2][2] = '|';
	return \@character;
};

function character_v => sub {
	my @character = $_[0]->default_character(3);
	$character[2][0] = '\\';
	$character[2][1] = '/';
	return \@character;
};

function character_w => sub {
	my @character = $_[0]->default_character(3);
	$character[2][0] = '\\';
	$character[2][1] = ')';
	$character[2][2] = '/';
	return \@character;
};

function character_x => sub {
	my @character = $_[0]->default_character(2);
	$character[2][0] = ')';
	$character[2][1] = '(';
	return \@character;
};

function character_y => sub {
	my @character = $_[0]->default_character(2);
	$character[1][0] = '\\';
	$character[1][1] = '/';
	$character[2][0] = '/';
	return \@character;
};

function character_z => sub {
	my @character = $_[0]->default_character(4);
	$character[1][1] = '_';
	$character[2][1] = '/';
	$character[2][2] = '_';
	$character[3][3] = ' ';
	return \@character;
};

function character_0 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][3] = $character[1][1] = $character[1][2] = ' ';
	$character[0][1] = $character[0][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = $character[2][3] = $character[1][3] = $character[2][0] = '|';
	return \@character;
};

function character_1 => sub {
	my @character = $_[0]->default_character(3);
	$character[1][1] = '/';
	$character[1][2] = $character[2][2] = '|';
	return \@character;
};

function character_2 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[2][2] = $character[2][3] = $character[1][2] = '_';
	$character[1][3] = ')';
	$character[2][1] = '/';
	return \@character;
};

function character_3 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[2][1] = $character[2][2] = $character[1][2] = '_';
	$character[1][3] = $character[2][3] = ')';
	return \@character;
};

function character_4 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][0] = $character[0][1] = $character[0][2] = $character[0][3] = ' ';
	$character[1][1] = $character[1][2] = '_';
	$character[1][0] = $character[1][3] = $character[2][3] = '|';
	return \@character;
};

function character_5 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = '_';
	$character[0][2] = '_';
	$character[1][0] = '|';
	$character[1][1] = '_';
	$character[2][2] = ')';
	$character[2][0] = $character[2][1] = '_';
	return \@character;
};

function character_6 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[1][1] = $character[1][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = '/';
	$character[2][0] = '\\';
	$character[2][3] = ')';
	return \@character;
};

function character_7 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][0] = '_';
	$character[0][1] = '_';
	$character[0][2] = '_';
	$character[1][2] = '/';
	$character[2][1] = '/';
	return \@character;
};

function character_8 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[1][1] = $character[1][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = $character[2][0] = '(';
	$character[1][3] = $character[2][3] = ')';
	return \@character;
};

function character_9 => sub {
	my @character = $_[0]->default_character(4);
	$character[0][1] = $character[0][2] = $character[1][1] = $character[1][2] = $character[2][1] = $character[2][2] = '_';
	$character[1][0] = '(';
	$character[2][3] = '/';
	$character[1][3] = '\\';
	return \@character;
};

function space => sub {
	my @character = $_[0]->default_character(3);
	return \@character;
};

1;

__END__

=head1 NAME

Ascii::Text::Font::Straight - Straight font

=head1 VERSION

Version 0.16

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



