=head1 NAME

Chess::Board - an object representation of a chessboard

=head1 SYNOPSIS

    $light = Chess::Board->get_color('h1');
    $dark = Chess::Board->get_color('a1');
    $e3 = Chess::Board->square_down_from('e4');
    $e5 = Chess::Board->square_up_from('e4');
    $d4 = Chess::Board->square_left_of('e4');
    $f4 = Chess::Board->square_right_of('e4');
    $board = Chess::Board->new();
    $is_valid = Chess::Board->square_is_valid($sq);
    if ($is_valid) {
	$board->set_piece_at($sq, $piece);
	$clone = $board->clone();
	$piece = $clone->get_piece_at($sq);
	$clone->set_piece_at($sq, undef);
	$clone->set_piece_at(Chess::Board->square_up_from($sq), $piece);
    }

=head1 DESCRIPTION

The Chess module provides a framework for writing Chess programs with Perl.

This class forms part of the framework, but it could also be used by
itself, even to put objects that aren't subclasses of L<Chess::Piece> on it.

=head1 METHODS

=head2 Construction

=over 4

=item new()

Takes no arguments. Returns a blessed Chess::Board object reference. This
reference can be used to call any of the methods listed in L</"Object methods">.

    $board = Chess::Board->new();

See also L</"clone()"> to construct a new Chess::Board from an existing one.

=back

=head2 Class methods

=over 4

=item square_is_valid()

Takes a single scalar parameter with the square to be tested. Returns true if
the given square falls within the range a1-h8. Returns false otherwise.
It is case-insensitive, though all functions that return squares will return 
lower-case.

    if (Chess::Board->square_is_valid($sq)) {
         # call method requiring valid square
    }

=item get_color_of()

Takes a single scalar parameter containing the square whose color is requested.
Returns a scalar containing either of the strings 'light' or 'dark'. Returns
C<undef> and prints a warning to STDERR (see L</"DIAGNOSTICS">) if the
square is not valid.

    $light = Chess::Board->get_color_of("h1");
    $dark = Chess::Board->get_color_of("a1");

=item square_left_of()

Takes a single scalar parameter containing the square right of the requested
square. Returns a string containing the square left of the parameter. Returns
C<undef> and prints a warning to STDERR (see L</"DIAGNOSTICS">) if the
square is not valid. Returns undef (but doesn't print a warning) if there is
no square left of the given square.

    $d4 = Chess::Board->square_left_of("e4");

=item square_right_of()

Takes a single scalar parameter containing the square left of the requested
square. Returns a string containing the square right of the parameter. Returns
C<undef> and prints a warning to STDERR (see L</"DIAGNOSTICS">) if the
square is not valid. Returns undef (but doesn't print a warning) if there is
no square right of the given square.

    $f4 = Chess::Board->square_left_of("e4");

=item square_up_from()

Takes a single scalar parameter containing the square down from the requested
square. Returns a string containing the square up from the parameter. Returns
C<undef> and prints a warning to STDERR (see L</"DIAGNOSTICS">) if the
square is not valid. Returns undef (but doesn't print a warning) if there is
no square up from the given square.

    $e5 = Chess::Board->square_up_from("e4");

=item square_down_from()

Takes a single scalar parameter containing the square up from the requested
square. Returns a string containing the square down from the parameter. Returns
C<undef> and prints a warning to STDERR (see L</"DIAGNOSTICS">) if the
square is not valid. Returns undef (but doesn't print a warning) if there is
no square down from the given square.

    $e3 = Chess::Board->square_down_from("e4");

=item horz_distance()

Takes a single scalar parameter containing the square to calculate distance
from. Returns the horizontal distance in squares between the two points.

=item vert_distance()

Takes a single scalar parameter containing the square to calculate distance
from. Returns the vertical distance in squares between the two points.

=item squares_in_line()

Takes two scalar parameters containing two distinct endpoints in a line.
Returns a list of scalars in lower-case with an entry for each square in that
line, or C<undef> if the two endpoints do not define a line. In the case where
both squares are the same, will return a list containing that square.

=back

=head2 Object methods

=over 4

=item clone()

Takes no arguments. Returns a blessed Chess::Board object reference which is
identical to the caller object. However, it is a I<deep copy> which allows
the clone()'d object to be manipulated separately of the caller object.

=item line_is_open()

Takes two scalar arguments, valid squares defining the endpoints of a line
on the Chess::Board. Returns true if there are no pieces on either of the
endpoints, or on any of the intervening squares. Returns false if the line
is blocked by one or more pieces, and C<undef> if the two squares do not
define endpoints of a line. In the case where both squares are equal, will
return true if the square is empty and false otherwise.

=item get_piece_at()

Takes a single scalar argument containing the square to retrieve the piece
from. Returns a scalar representing the piece on that square, or C<undef> if 
there is none. Returns C<undef> and prints a warning to STDERR (See
L</"DIAGNOSTICS">) if the provided square is not valid.

=item set_piece_at()

Takes two scalar arguments: the square whose piece to set, and a scalar
representing the piece to place there. Usually this will be a subclass of
C<Chess::Piece>, but could be something else if the board is being used
stand-alone. See L<Chess::Piece/"DESCRIPTION"> for more information on
using other things as pieces. Sets the piece at that square if the square is
valid, and prints a warning to STDERR (see L</"DIAGNOSTICS">) otherwise.

=back

=head1 DIAGNOSTICS

=over 4

=item 'q9' is not a valid square

The function which generated this message was called with a square outside
the range a1-h8, causing it to return C<undef>. Use the class method 
L</"square_is_valid()"> to validate the square before passing it to any
method requiring a valid square.

=item Invalid Chess::Board reference

The function which generated this message was passed an invalid Chess::Board
reference. Make sure that the function call is passing a reference obtained
either from a call to L</"new()"> or to L</"clone()">, and that the reference 
refers to a defined value.

=item Can't modify this board. Use Chess::Board->new() instead.

The program contains a reference to a Chess::Board that wasn't obtained through
a call to L</"new()"> or L</"clone()">. Make sure that all references have
been obtained through these methods.

=back

=head1 BUGS

Please report any bugs to the author.

=head1 AUTHOR

Brian Richardson <bjr@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2005 Brian Richardson. All rights reserved. This module is
Free Software. It may be modified and redistributed under the same terms as
Perl itself.

=cut
package Chess::Board;

use Carp;
use strict;

use constant IDX_EMPTY_BOARD => -1;

{
    my $_r_empty_board = _init_empty_board();
    my $_r_empty_board_arr;
    my @_boards = ( );

    sub _init_empty_board {
	for (my $y = 0; $y < 8; $y++) {
	    my $color = $y % 2 ? 'light' : 'dark';
	    for (my $x = 0; $x < 8; $x += 2) {
		$_r_empty_board_arr->[$y][$x] = { color => $color, 
		                            piece => undef };
		$color = ($color eq 'light' ? 'dark' : 'light');
		$_r_empty_board_arr->[$y][$x+1] = { color => $color, 
		                              piece => undef };
		$color = ($color eq 'light' ? 'dark' : 'light');
	    }
	}
	my $i = IDX_EMPTY_BOARD;
	return bless \$i, 'Chess::Board';
    }

    sub _get_board_array_ref {
	my ($i) = @_;
	return $_r_empty_board_arr if ($i == IDX_EMPTY_BOARD);
	return $_boards[$i];
    }

    sub new {
       	return $_r_empty_board->clone();
    }

    sub clone {
       	my ($clonee) = @_;
	my $class = ref($clonee) || croak "Invalid Chess::Board reference";
	my $r_board_arr = _get_board_array_ref($$clonee);
	croak "Invalid Chess::Board reference" unless ($r_board_arr);
	my $obj_data;
	for (my $y = 0; $y < 8; $y++) {
	    for (my $x = 0; $x < 8; $x++) {
		my $color = $r_board_arr->[$y][$x]{color};
		my $piece = $r_board_arr->[$y][$x]{piece};
		$piece = $piece->clone() if (defined($piece) && 
		                             $piece->can('clone'));
		$obj_data->[$y][$x] = { color => $color,
			    		piece => $piece };
	    }
	}
	push @_boards, $obj_data;
	my $i = $#_boards;
	return bless \$i, $class;
    }

    sub DESTROY {
	my ($caller) = @_;
        $_boards[$$caller] = undef if (defined($caller) && $$caller >= 0);
    }
}

sub _get_square_coords {
    my ($sq) = @_;
    if (!Chess::Board->square_is_valid($sq)) {
	carp "'$sq' is not a valid square";
	return undef;
    }
    my $x = ord(lc substr($sq, 0, 1)) - ord('a');
    my $y = substr($sq, 1, 1) - 1;
    return ($x, $y);
}

sub _coords_to_square {
    my ($x, $y) = @_;
    my $sq = chr(ord('a') + $x) . ($y + 1);
    return $sq;
}

sub square_is_valid {
    my (undef, $sq) = @_;
    return $sq =~ /^[A-Ha-h][1-8]$/;
}

sub get_color_of {
    my (undef, $sq) = @_;
    my $r_board_arr = _get_board_array_ref(IDX_EMPTY_BOARD);
    my ($x, $y) = _get_square_coords($sq);
    if (defined($x) && defined($y)) {
	return $r_board_arr->[$y][$x]{color};
    }
    else {
	return undef;
    }
}

sub add_horz_distance {
    my (undef, $sq, $dist) = @_;
    my ($x, $y) = _get_square_coords($sq);
    return undef unless (defined($x) && defined($y));
    $x += $dist;
    return undef unless (($x >= 0) && ($x <= 7));
    $sq = _coords_to_square($x, $y);
    return $sq;
}

sub add_vert_distance {
    my (undef, $sq, $dist) = @_;
    my ($x, $y) = _get_square_coords($sq);
    return undef unless (defined($x) && defined($y));
    $y += $dist;
    return undef unless (($y >= 0) && ($y <= 7));
    $sq = _coords_to_square($x, $y);
    return $sq;
}

sub horz_distance {
    my (undef, $sq1, $sq2) = @_;
    my ($x1, $y1) = _get_square_coords($sq1);
    my ($x2, $y2) = _get_square_coords($sq2);
    return $x2 - $x1;
}

sub vert_distance {
    my (undef, $sq1, $sq2) = @_;
    my ($x1, $y1) = _get_square_coords($sq1);
    my ($x2, $y2) = _get_square_coords($sq2);
    return $y2 - $y1;
}

sub square_left_of {
    my (undef, $sq) = @_;
    return Chess::Board->add_horz_distance($sq, -1);
}

sub square_right_of {
    my (undef, $sq) = @_;
    return Chess::Board->add_horz_distance($sq, 1);
}

sub square_down_from {
    my (undef, $sq) = @_;
    return Chess::Board->add_vert_distance($sq, -1);
}

sub square_up_from {
    my (undef, $sq) = @_;
    return Chess::Board->add_vert_distance($sq, 1);
}

sub squares_in_line {
    my (undef, $sq1, $sq2) = @_;
    my ($x1, $y1) = _get_square_coords($sq1);
    my ($x2, $y2) = _get_square_coords($sq2);
    my $hdist = abs($x2 - $x1);
    my $vdist = abs($y2 - $y1);
    return undef unless ($hdist == 0 || $vdist == 0 || $hdist == $vdist);
    return ($sq1) unless($hdist || $vdist);
    my $hdelta = $hdist ? $hdist / ($x2 - $x1) : 0;
    my $vdelta = $vdist ? $vdist / ($y2 - $y1) : 0;
    my @squares;
    my $sq = $sq1;
    push @squares, $sq;
    if ($vdist and $hdelta == 0) {
	for (my $i = 0; $i < $vdist; $i++) {
	    $sq = $vdelta > 0 ? Chess::Board->square_up_from($sq) :
	                        Chess::Board->square_down_from($sq);
	    push @squares, $sq;
	}
    }
    elsif ($hdist and $vdelta == 0) {
	for (my $i = 0; $i < $hdist; $i++) {
	    $sq = $hdelta > 0 ? Chess::Board->square_right_of($sq) :
		  		Chess::Board->square_left_of($sq);
	    push @squares, $sq;
	}
    }
    elsif ($hdist == $vdist) {
	for (my $i = 0; $i < $hdist; $i++) {
	    my $tsq = $hdelta > 0 ? Chess::Board->square_right_of($sq) :
	                            Chess::Board->square_left_of($sq);
	    $sq = $vdelta > 0 ? Chess::Board->square_up_from($tsq) :
	                        Chess::Board->square_down_from($tsq);
	    push @squares, $sq;
	}
    }
    return @squares;
}

sub get_piece_at {
    my ($self, $sq) = @_;
    if (!Chess::Board->square_is_valid($sq)) {
	carp "'$sq' is not a valid square";
	return undef;
    }
    my ($x, $y) = _get_square_coords($sq);
    croak "Invalid Chess::Board reference" unless (ref($self));
    return undef if $$self == IDX_EMPTY_BOARD;
    my $r_board_arr = _get_board_array_ref($$self);
    croak "Invalid Chess::Board reference" unless (defined($r_board_arr));
    return $r_board_arr->[$y][$x]{piece};
}

sub set_piece_at {
    my ($self, $sq, $piece) = @_;
    if (!Chess::Board->square_is_valid($sq)) {
	carp "'$sq' is not a valid square";
	return undef;
    }
    my ($x, $y) = _get_square_coords($sq);
    croak "Invalid Chess::Board reference" unless (ref($self));
    if ($$self == IDX_EMPTY_BOARD) {
	carp "Can't modify this board. Use Chess::Board->new() instead";
	return;
    }
    my $r_board_arr = _get_board_array_ref($$self);
    croak "Invalid Chess::Board reference" unless (defined($r_board_arr));
    $r_board_arr->[$y][$x]{piece} = $piece;
}

sub line_is_open {
    my ($self, $sq1, $sq2) = @_;
    if (!Chess::Board->square_is_valid($sq1) || !Chess::Board->square_is_valid($sq2)) {
	carp "'$sq1' is not a valid square";
	return undef;
    }
    croak "Invalid Chess::Board reference" unless (ref($self));
    return 1 if $$self == IDX_EMPTY_BOARD;
    my ($x1, $y1) = _get_square_coords($sq1);
    my ($x2, $y2) = _get_square_coords($sq2);
    my $hdist = abs($x2 - $x1);
    my $vdist = abs($y2 - $y1);
    return undef unless ($hdist == 0 || $vdist == 0 || $hdist == $vdist);
    my $hdelta = $hdist ? $hdist / ($x2 - $x1) : 0;
    my $vdelta = $vdist ? $vdist / ($y2 - $y1) : 0;
    my $xcurr = $x1;
    my $ycurr = $y1;
    my $r_board_arr = _get_board_array_ref($$self);
    croak "Invalid Chess::Board reference" unless (defined($r_board_arr));
    if (($hdist == 0) && ($hdist == $vdist)) {
	return 0 if (defined($r_board_arr->[$ycurr][$xcurr]{piece}));
	return 1;
    }
    while (($xcurr != $x2) || ($ycurr != $y2)) {
	return 0 if (defined($r_board_arr->[$ycurr][$xcurr]{piece}));
	$xcurr += $hdelta;
	$ycurr += $vdelta;
    }
    return 1;
}

1;
