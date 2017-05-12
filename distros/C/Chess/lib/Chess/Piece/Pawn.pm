=head1 NAME

Chess::Piece::Pawn - a class representing a pawn in a chess game

=head1 SYNOPSIS

    $pawn = Chess::Piece::Pawn->new("e2", "White King's pawn");
    $true = $pawn->can_reach("e4");
    $true = $pawn->can_reach("e3");
    $true = $pawn->can_reach("f3");
    $false = $pawn->can_reach("e5");
    $queen = $pawn->promote("queen");

=head1 DESCRIPTION

The Chess module provides a framework for writing chess programs with Perl.
This class is part of that framework, representing a pawn in a
L<Chess::Game>.

=head1 METHODS

=head2 Construction

=over 4

=item new()

Constructs a new Chess::Piece::Pawn. Requires a two scalar parameters
containing the square on which the pawn is to be constucted and its color, 
Optionally takes a third parameter containing a text description of the pawn.

    $pawn = Chess::Piece::Pawn->new("d2", "white");
    $pawn = Chess::Piece::Pawn->new("e2", "white", 
                                    "White King's pawn");

=head2 Class methods

There are no class methods for this class.

=head2 Object methods

=item reachable_squares()

Overrides base class version. Returns a list of squares that this pawn can
reach from its current position. See L<Chess::Piece/"reachable_squares()">
for more details on this method.

=item promote()

Takes a parameter containing the type of piece to promote to. Returns itself
blessed as that type of piece. Returns undef and produces a warning (see
L</"DIAGNOSTICS"> if the piece is not one of 'bishop', 'knight', 'queen' or
'rook'.

=head1 DIAGNOSTICS

=over 4

=item Can't promote a pawn to a 'king'

You may only promote a pawn to a 'bishop', 'knight', 'queen' or 'rook'.

=back

=head1 BUGS

Please report any bugs to the author.

=head1 AUTHOR

Brian Richardson <bjr@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2005 Brian Richardson. All rights reserved. This module
is Free Software. It may be modified and redistributed under the same terms as
Perl itself.

=cut
package Chess::Piece::Pawn;

use Chess::Piece;
use Chess::Board;
use base 'Chess::Piece';
use Carp;
use strict;

sub new {
    my ($caller, $sq, $color, $desc) = @_;
    my $class = ref($caller) || $caller;
    my $self = $caller->SUPER::new($sq, $color, $desc);
    return bless $self, $class;
}

sub reachable_squares {
    my ($self) = @_;
    my $color = $self->get_player();
    my $csq = $self->get_current_square();
    my $tsq1;
    my @squares = ( );
    if ($color eq 'white') {
	$tsq1 = Chess::Board->square_up_from($csq) if defined($csq);
    }
    else {
	$tsq1 = Chess::Board->square_down_from($csq) if defined($csq);
    }
    push @squares, $tsq1 if defined($tsq1);
    my $tsq2;
    if ($color eq 'white') {
	$tsq2 = Chess::Board->square_up_from($tsq1) if defined($tsq1);
    }
    else {
	$tsq2 = Chess::Board->square_down_from($tsq1) if defined($tsq1);
    }
    push @squares, $tsq2 if (!$self->moved() and defined($tsq2));
    $tsq2 = Chess::Board->square_left_of($tsq1) if defined($tsq1);
    push @squares, $tsq2 if (defined($tsq2));
    $tsq2 = Chess::Board->square_right_of($tsq1) if defined($tsq1);
    push @squares, $tsq2 if (defined($tsq2));
    return @squares;
}

sub promote {
    my ($self, $new_rank) = @_;
    unless (lc($new_rank) eq 'bishop' || lc($new_rank) eq 'knight' ||
            lc($new_rank) eq 'rook' || lc($new_rank) eq 'queen') {
	carp "Can't promote a pawn to a '$new_rank'";
	return undef;
    }
    return bless $self, ('Chess::Piece::' . ucfirst($new_rank));
}

1;
