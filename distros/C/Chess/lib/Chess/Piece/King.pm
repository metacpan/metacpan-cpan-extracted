=head1 NAME

Chess::Piece::King - an object representation of a king in a game of chess

=head1 SYNOPSIS

    $king = Chess::Piece::King->new("e1", "white", "White King");
    $true = $king->can_reach("d1");
    $true = $king->can_reach("f1");
    $true = $king->can_reach("d2");
    $true = $king->can_reach("e2");
    $true = $king->can_reach("f2");
    $true = $king->can_reach("g1"); # O-O
    $king->set_moved(1);
    $false = $king->can_reach("g1");
    $false = $king->can_reach("d4");
    $king->set_captured(1); # dies with message
    $king->set_checkmated(1); # use this instead
    if ($king->checkmated()) {
	# game over...
    }

=head1 DESCRIPTION

The Chess module provides a framework for writing chess programs with Perl.
This class forms part of that framework, representing a bishop in a
L<Chess::Game>.

=head1 METHODS

=head2 Construction

=item new()

Constructs a new Chess::Piece::King. Requires two scalar parameters 
containing the initial square and color of the piece. Optionally takes a 
third parameter containing a description of the piece.

=head2 Class methods

There are no class methods for this class.

=head2 Object methods

=item can_reach()

Overrides base class version. Returns a list of squares that this pawn can
reach from its current position. See L<Chess::Piece/"reachable_squares()">
for more details on this method.

=item checkmated()

Takes no parameters. Returns true if the checkmated flag has been set for this
king (as determined by L</"set_checkmated()">.

=item set_checkmated()

Takes a single scalar parameter containing a boolean value. Sets the checkmated
property of this king to that value.

=head1 DIAGNOSTICS

=item "King cannot be captured. Use set_checkmated() instead"

The program contains a call to Chess::Piece::King::set_captured. This
method has been overridden to croak, as the rules don't allow for capturing
the king. See L</"set_checkmated()">.

=item "Invalid Chess::Piece::King reference"

The program contains a reference to a Chess::Piece::King that was not
obtained through L</"new()"> or L<Chess::Piece/"clone()">. Ensure that the
program obtains the reference correctly, and that it does not refer to
an undefined value.

=head1 BUGS

Please report any bugs to the author.

=head1 AUTHOR

Brian Richardson <bjr@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2005 Brian Richardson. All rights reserved. This module is
Free Software. It may be modified and redistributed under the same terms as
Perl itself.

=cut
package Chess::Piece::King;

use Chess::Board;
use Chess::Piece;
use base 'Chess::Piece';
use Carp;
use strict;

sub captured {
    croak "King can't be captured";
}

sub set_captured {
    croak "King can't be captured";
}

sub reachable_squares {
    my ($self) = @_;
    my $csq = $self->get_current_square();
    my @squares = ( );
    my $sq1 = Chess::Board->square_left_of($csq);
    if (defined($sq1)) {
	push @squares, $sq1;
	my $sq2 = Chess::Board->square_up_from($sq1);
	push @squares, $sq2 if (defined($sq2));
	$sq2 = Chess::Board->square_down_from($sq1);
	push @squares, $sq2 if (defined($sq2));
    }
    $sq1 = Chess::Board->square_right_of($csq);
    if (defined($sq1)) {
	push @squares, $sq1;
	my $sq2 = Chess::Board->square_up_from($sq1);
	push @squares, $sq2 if (defined($sq2));
	$sq2 = Chess::Board->square_down_from($sq1);
	push @squares, $sq2 if (defined($sq2));
    }
    $sq1 = Chess::Board->square_up_from($csq);
    push @squares, $sq1 if (defined($sq1));
    $sq1 = Chess::Board->square_down_from($csq);
    push @squares, $sq1 if (defined($sq1));
    $sq1 = Chess::Board->add_horz_distance($csq, 2);
    push @squares, $sq1 if (defined($sq1) and !$self->moved());
    $sq1 = Chess::Board->add_horz_distance($csq, -2);
    push @squares, $sq1 if (defined($sq1) and !$self->moved());
    return @squares;
}

1;
