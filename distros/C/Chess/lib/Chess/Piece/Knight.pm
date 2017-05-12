=head1 NAME

Chess::Piece::Knight - an object representing a knight in a game of chess

=head1 SYNOPSIS

    $knight = Chess::Piece::Knight->new("g1", "white", 
                                        "White King's knight");
    $true = $knight->can_reach("f3");
    $true = $knight->can_reach("e2");
    $false = $knight->can_reach("g3");

=head1 DESCRIPTION

The Chess module provides a framework for writing chess programs with Perl.
This class forms part of the framework, representing a knight in a 
L<Chess::Game>.

=head1 METHODS

=over 4

=head2 Construction

=item new()

Constructs a new Chess::Piece::Knight. Requires two scalar parameters
containing the initial square and color for this piece. Optionally takes a
third scalar parameter containing a description of this piece.

    $knight = Chess::Piece::Knight->new("g1", "white");
    $knight = Chess::Piece::Knight->new("g8", "black", 
                                        "Black King's knight");

=head2 Class methods

There are no class methods for this class.

=head2 Object methods

=item reachable_squares()

Overrides base class version. Returns a list of squares that this pawn can
reach from its current position. See L<Chess::Piece/"reachable_squares()">
for more details on this method.

=back

=head1 DIAGNOSTICS

This subclass of L<Chess::Piece> does not generate any warning messages by
itself. Please see L<DIAGNOSTICS in Chess::Piece|Chess::Piece/"DIAGNOSTICS">
or L<DIAGNOSTICS in Chess::Board|Chess::Board/"DIAGNOSTICS"> for possible
error messages your program may produce.

=head1 BUGS

Please report any bugs to the author.

=head1 AUTHOR

Brian Richardson <bjr@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2005 Brian Richardson. All rights reserved. This module
is Free Software. It may be modified and redistributed under the same terms
as Perl itself.

=cut
package Chess::Piece::Knight;

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
    my $tsq = Chess::Board->add_vert_distance($csq, 2);
    my @squares = ( );
    if (defined($tsq)) {
	my $sq = Chess::Board->square_right_of($tsq);
	push @squares, $sq if (defined($sq));
	$sq = Chess::Board->square_left_of($tsq);
	push @squares, $sq if (defined($sq));
    }
    $tsq = Chess::Board->add_vert_distance($csq, -2);
    if (defined($tsq)) {
	my $sq = Chess::Board->square_right_of($tsq);
	push @squares, $sq if (defined($sq));
	$sq = Chess::Board->square_left_of($tsq);
	push @squares, $sq if (defined($sq));
    }
    $tsq = Chess::Board->add_horz_distance($csq, 2);
    if (defined($tsq)) {
	my $sq = Chess::Board->square_up_from($tsq);
	push @squares, $sq if (defined($sq));
	$sq = Chess::Board->square_down_from($tsq);
	push @squares, $sq if (defined($sq));
    }
    $tsq = Chess::Board->add_horz_distance($csq, -2);
    if (defined($tsq)) {
	my $sq = Chess::Board->square_up_from($tsq);
	push @squares, $sq if (defined($sq));
	$sq = Chess::Board->square_down_from($tsq);
	push @squares, $sq if (defined($sq));
    }
    return @squares;
}

1;
