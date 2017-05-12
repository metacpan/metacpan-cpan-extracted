=head1 NAME

Chess::Piece::Bishop - an object representation of a bishop in a game of chess

=head1 SYNOPSIS

    $bishop = Chess::Piece::Bishop->new("f1", "white", 
                                        "White King's bishop");
    $true = $bishop->can_reach("c4");
    $true = $bishop->can_reach("h3");
    $false = $bishop->can_reach("d4");

=head1 DESCRIPTION

The Chess module provides a framework for writing chess programs with Perl.
This class forms part of that framework, representing a bishop in a
L<Chess::Game>.

=head1 METHODS

=head2 Construction

=item new()

Constructs a new Chess::Piece::Bishop. Requires two scalar parameters 
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
package Chess::Piece::Bishop;

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
    my $hdist = abs(Chess::Board->horz_distance("a1", $csq));
    my $vdist = abs(Chess::Board->vert_distance("a1", $csq));
    my $dist = $hdist > $vdist ? $vdist : $hdist;
    my $sq = Chess::Board->add_horz_distance($csq, -$dist);
    $sq = Chess::Board->add_vert_distance($sq, -$dist);
    my @squares = ( );
    push @squares, Chess::Board->squares_in_line($csq, $sq);
    $hdist = abs(Chess::Board->horz_distance("h1", $csq));
    $vdist = abs(Chess::Board->vert_distance("h1", $csq));
    $dist = $hdist > $vdist ? $vdist : $hdist;
    $sq = Chess::Board->add_horz_distance($csq, $dist);
    $sq = Chess::Board->add_vert_distance($sq, -$dist);
    push @squares, Chess::Board->squares_in_line($csq, $sq);
    $hdist = abs(Chess::Board->horz_distance("a8", $csq));
    $vdist = abs(Chess::Board->vert_distance("a8", $csq));
    $dist = $hdist > $vdist ? $vdist : $hdist;
    $sq = Chess::Board->add_horz_distance($csq, -$dist);
    $sq = Chess::Board->add_vert_distance($sq, $dist);
    push @squares, Chess::Board->squares_in_line($csq, $sq);
    $hdist = abs(Chess::Board->horz_distance("h8", $csq));
    $vdist = abs(Chess::Board->vert_distance("h8", $csq));
    $dist = $hdist > $vdist ? $vdist : $hdist;
    $sq = Chess::Board->add_horz_distance($csq, $dist);
    $sq = Chess::Board->add_vert_distance($sq, $dist);
    push @squares, Chess::Board->squares_in_line($csq, $sq);
    @squares = grep !/^$csq$/, @squares;
    return @squares;
}

1;
