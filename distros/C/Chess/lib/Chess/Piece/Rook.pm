=head1 NAME

Chess::Piece::Rook - an object representation of a rook in a game of chess

=head1 SYNOPSIS

    $rook = Chess::Piece::Rook->new("a1", "white", 
                                    "White Queen's rook");
    $true = $rook->can_reach("h1");
    $true = $rook->can_reach("a8");
    $false = $rook->can_reach("d4");

=head1 DESCRIPTION

The Chess module provides a framework for writing chess programs with Perl.
This class forms part of that framework, representing a rook in a
L<Chess::Game>.

=head1 METHODS

=head2 Construction

=item new()

Constructs a new Chess::Piece::Rook. Requires two scalar parameters 
containing the initial square and color of the piece. Optionally takes a 
third parameter containing a description of the piece.

=head2 Class methods

There are no class methods for this class.

=head2 Object methods

=item reachable_squares()

Overrides base class version. Returns a list of squares that this pawn can
reach from its current position. See L<Chess::Piece/"reachable_squares()">
for more details on this method.

=head1 DIAGNOSTICS

This module produces no warning messages. See 
L<DIAGNOSTICS in Chess::Board|Chess::Board/"DIAGNOSTICS"> or
L<DIAGNOSTICS in Chess::Piece|Chess::Piece/"DIAGNOSTICS"> for possible
errors or warnings the program may produce.

=head1 BUGS

Please report any bugs to the author.

=head1 AUTHOR

Brian Richardson <bjr@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2005 Brian Richardson. All rights reserved. This module is
Free Software. It may be modified and redistributed under the same terms as
Perl itself.

=cut
package Chess::Piece::Rook;

use Chess::Board;
use Chess::Piece;
use base 'Chess::Piece';
use strict;

sub new {
    my ($caller, $sq, $color, $desc) = @_;
    my $class = ref($caller) || $caller;
    my $self = $caller->SUPER::new($sq, $color, $desc);
    return bless $self, $class;
}

sub reachable_squares {
    my ($self) = @_;
    my $csq = $self->get_current_square();
    my $x = Chess::Board->horz_distance("a4", $csq);
    my $y = Chess::Board->vert_distance("d1", $csq);
    my $row_start = 'a' . ($y + 1);
    my $row_end = 'h' . ($y + 1); 
    my $col_start = chr(ord('a') + $x) . '1';
    my $col_end = chr(ord('a') + $x) . '8';
    my @row = Chess::Board->squares_in_line($row_start, $row_end);
    my @col = Chess::Board->squares_in_line($col_start, $col_end);
    my @squares = (@row, @col);
    return grep !/^$csq$/, @squares;
}

1;
