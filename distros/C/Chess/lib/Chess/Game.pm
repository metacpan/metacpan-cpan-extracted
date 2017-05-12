=head1 NAME

Chess::Game - a class to record and validate the moves of a game of chess

=head1 SYNOPSIS

    use Chess::Game;

    $game = Chess::Game->new();
    $clone = $game->clone();
    $move = $game->make_move("e2", "e4");
    $move_c = $clone->make_move("e2", "e4");
    $true = ($move->get_piece() ne $move_c->get_piece());
    $move = $game->delete_move();
    ...
    while (!defined($result = $game->result())) {
	# get a move
	$move = $game->make_move($sq1, $sq2);
	if (!defined($move)) {
	    print $game->get_message();
	}
    }
    if ($result == 1) {
	print "White wins!\n";
    }
    elsif ($result == 0) {
	print "Draw!\n"
    }
    else {
	print "Black wins!\n";
    }

=head1 DESCRIPTION

The Chess module provides a framework for writing chess programs with Perl.
This class forms part of that framework, providing move validation for all
moves recorded using the Chess::Game class. The Game contains a
L<Chess::Board>, 32 L<Chess::Piece>s and a L<Chess::Game::MoveList>
that contains a series of L<Chess::Game::MoveListEntry>s that record the exact
state of the game as it progresses. Moves can be taken back one-at-a-time to
allow for simple movelist manipulation.

=head1 METHODS

=head2 Construction

=item new()

Takes two optional parameters containing optional names for the players. If
none are provided, the player names 'white' and 'black' are used. Creates a
new L<Chess::Board> and places 16 L<Chess::Pieces> per player and initializes
an empty L<Chess::Game::MoveList>.

=head2 Class methods

There are no class methods for this class.

=head2 Object methods

=item clone()

Takes no parameters. Returns a new blessed Chess::Game reference in an
identical state to the calling object, but which can be manipulated entirely
separately.

=item is_move_legal()

Takes two parameters containing the name of the square to move from and the 
name of the square to move to. They should be validated with 
L<Chess::Board/"square_is_valid()"> prior to calling. Returns true if the 
provided move is legal within the context of the current game.

=item make_move()

Takes two parameters containing the name of the square to move from and the
name of the square to move to. They should be validated with
L<Chess::Board/"square_is_valid()"> before calling. Optionally takes a third
parameter, which can be set to zero to indicate that no legality
checking should be done. B<In this case, flags indicating 'en passant' pawn
captures or castling will not be set!> Only by entirely validating the move
do these flags have any meaning. The default is to validate every move. Returns
a L<Chess::Game::MoveListEntry> representing the move just made.

=item get_message()

Takes no parameters. Returns the message containing the reason L</"make_move()">
or L</"is_move_legal()"> returned false, such as "Can't castle out of check".

=item delete_move()

Takes no parameters. Returns a L<Chess::Game::MoveListEntry> representing the
last move made, and sets the state of the game to what it was prior to the
returned move being made.

=item player_in_check()

Takes a single parameter containing the name of the player to consider. Returns
true if the named player is in check.

=item player_checkmated()

Takes a single parameter containing the name of the player to consider. Returns
true if the named player has been checkmated.

=item player_stalemated()

Takes a single parameter containing the name of the player to consider. Returns
true if the named player has been stalemated.

=item result()

Takes no parameters. Returns C<undef> as long as the game is in progress. When
a conclusion has been reached, returns 1 if the first player checkmated the
second player, 0 if either player has been stalemated, or -1 if the second
player checkmated the first player. Is not currently able to determine if the
game was drawn by a three-fold repetition of positions.

=item do_promotion()

Takes one parameters. If the last move was a promotion (as determined by a call
to L<Chess::Game::MoveListEntry/"is_promotion()">, then calling this function
will change the newly promoted pawn to the piece specified by the provided
parameter. Valid values are (case-insensitive) "bishop", "knight", "queen"
and "rook".

=head1 DIAGNOSTICS

=over 4

=item Invalid Chess::Game reference

The program contains a reference to a Chess::Game not obtained through
L</"new()"> or L</"clone()">. Ensure the program only uses these methods to
create Chess::Game references, and the the reference refers to a defined
value.

=item Invalid square 'q9'

The program made a call to make_move() or is_move_legal() with invalid squares.
Ensure that all variables containing squares are validated with
L<Chess::Board/"square_is_valid()">.

=back

=head1 BUGS

The framework is not currently able to determine when a game has been drawn
by three-fold repetition of position. Please report any other bugs to the
author.

=head1 AUTHOR

Brian Richardson <bjr@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2005 Brian Richardson. All rights reserved. This module is 
Free Software. It may be modified and redistributed under the same terms as 
Perl itself.

=cut
package Chess::Game;

use Chess::Board;
use Chess::Piece;
use Chess::Piece::Pawn;
use Chess::Piece::Knight;
use Chess::Piece::Bishop;
use Chess::Piece::Rook;
use Chess::Piece::Queen;
use Chess::Piece::King;
use Chess::Game::MoveList;
use Chess::Game::MoveListEntry;
use Carp;
use strict;

use constant OBJECT_DATA => (
    _player_has_moves => undef,
    _captures => undef,
    _kings => undef,
    board => undef,
    players => undef,
    movelist => undef,
    pieces => undef,
    message => ''
);

# same as Chess::Game::MoveListEntry
use constant MOVE_CAPTURE => 0x01;
use constant MOVE_CASTLE_SHORT => 0x02;
use constant MOVE_CASTLE_LONG => 0x04;
use constant MOVE_EN_PASSANT => 0x08;
use constant MOVE_PROMOTE => 0x10;

sub _add_pieces {
    my ($board, $type, $squares, $player, $pieces) = @_;
    foreach my $sq (@$squares) {
	my $fqn = 'Chess::Piece::' . ucfirst($type);
	my $piece = $fqn->new($sq, $player);
	$board->set_piece_at($sq, $piece);
	push @$pieces, $piece;
    }
}

{
    my @_games = ( );

    sub _get_game {
	my ($i) = @_;
	return $_games[$i];
    }

    sub new {
	my ($caller, $p1, $p2) = @_;
	my $class = ref($caller) || $caller;
	my $player1 = $p1 || "white";
	my $player2 = $p2 || "black";
	my %object_data = OBJECT_DATA;
	my $obj_data = { %object_data };
	my $board = Chess::Board->new();
	my %pieces = (  $player1 => [ ], $player2 => [ ] );
	my %captures = (  $player1 => { }, $player2 => { } );
	my %player_has_moves = ( $player1 => { 1 => 1 }, $player2 => { 1 => 1 } );
	_add_pieces($board, 'Rook', [ "a1", "h1" ], $player1, $pieces{$player1});
	_add_pieces($board, 'Rook', [ "a8", "h8" ], $player2, $pieces{$player2});
	_add_pieces($board, 'Knight', [ "b1", "g1" ], $player1, $pieces{$player1});
	_add_pieces($board, 'Knight', [ "b8", "g8" ], $player2, $pieces{$player2});
	_add_pieces($board, 'Bishop', [ "c1", "f1" ], $player1, $pieces{$player1});
	_add_pieces($board, 'Bishop', [ "c8", "f8" ], $player2, $pieces{$player2});
	_add_pieces($board, 'Queen', [ "d1" ], $player1, $pieces{$player1});
	_add_pieces($board, 'Queen', [ "d8" ], $player2, $pieces{$player2});
	_add_pieces($board, 'King', [ "e1" ], $player1, $pieces{$player1});
	push @{$obj_data->{_kings}}, $pieces{$player1}[-1];
	_add_pieces($board, 'King', [ "e8" ], $player2, $pieces{$player2});
	push @{$obj_data->{_kings}}, $pieces{$player2}[-1];
	my @pawn_row = Chess::Board->squares_in_line("a2", "h2");
	_add_pieces($board, 'Pawn', \@pawn_row, $player1, $pieces{$player1});
	@pawn_row = Chess::Board->squares_in_line("a7", "h7");
	_add_pieces($board, 'Pawn', \@pawn_row, $player2, $pieces{$player2});
	$obj_data->{_captures} = \%captures;
	$obj_data->{_player_has_moves} = \%player_has_moves;
	$obj_data->{board} = $board;
	$obj_data->{pieces} = \%pieces;
	$obj_data->{movelist} = Chess::Game::MoveList->new($player1, $player2);
	$obj_data->{players} = [ $player1, $player2 ];
	push @_games, $obj_data;
	my $i = $#_games;
	return bless \$i, $class;
    }

    sub clone {
	my ($self) = @_;
	my $class = ref($self) || croak "Invalid Chess::Game reference";
	my $obj_data = _get_game($$self);
	croak "Invalid Chess::Game reference" unless ($obj_data);
	my %object_data = OBJECT_DATA;
	my $new_obj = \%object_data;
	my $board = $obj_data->{board};
	my $clone = $board->clone();
	$new_obj->{board} = $clone;
	my $p1 = $obj_data->{players}[0];
	my $p2 = $obj_data->{players}[1];
	my %player_has_moves = ( $p1 => { 1 => 1 }, $p2 => { 1 => 1 } );
	$new_obj->{players} = [ $p1, $p2 ];
	my %pieces = (  $p1 => [ ], $p2 => [ ] );
	$new_obj->{pieces} = \%pieces;
	my %captures = ( $p1 => { }, $p2 => { } );
	$new_obj->{_captures} = \%captures;
	$new_obj->{_player_has_moves} = \%player_has_moves;
	my %old_to_new = ( );
	foreach my $old_piece (@{$obj_data->{pieces}{$p1}}) {
	    if ($old_piece->isa('Chess::Piece::King') or !$old_piece->captured()) {
		my $old_sq = $old_piece->get_current_square();
    		my $new_piece = $clone->get_piece_at($old_sq);
    		$old_to_new{$old_piece} = $new_piece;
    		push @{$new_obj->{pieces}{$p1}}, $new_piece;
		push @{$new_obj->{_kings}}, $new_piece if (defined($new_piece) and $new_piece->isa('Chess::Piece::King'));
	    }
	    else {
		foreach my $mn (keys %{$obj_data->{_captures}{$p2}}) {
	    	    my $capture = $obj_data->{_captures}{$p2}{$mn};
		    if ($capture eq $old_piece) {
    			$captures{$p2}{$mn} = $capture;
			$old_to_new{$old_piece} = $capture;
			push @{$new_obj->{pieces}{$p1}}, $capture
		    }
		}
	    }
	}
	foreach my $old_piece (@{$obj_data->{pieces}{$p2}}) {
	    if ($old_piece->isa('Chess::Piece::King') or !$old_piece->captured()) {
		my $old_sq = $old_piece->get_current_square();
    		my $new_piece = $clone->get_piece_at($old_sq);
    		$old_to_new{$old_piece} = $new_piece;
    		push @{$new_obj->{pieces}{$p2}}, $new_piece;
		push @{$new_obj->{_kings}}, $new_piece if (defined($new_piece) and $new_piece->isa('Chess::Piece::King'));
	    }
	    else {
		foreach my $mn (keys %{$obj_data->{_captures}{$p1}}) {
	    	    my $capture = $obj_data->{_captures}{$p1}{$mn};
		    if ($capture eq $old_piece) {
    			$captures{$p1}{$mn} = $capture;
			$old_to_new{$old_piece} = $capture;
			push @{$new_obj->{pieces}{$p2}}, $capture;
		    }
		}
	    }
	}
	my $movelist = $obj_data->{movelist};
	my $new_ml = Chess::Game::MoveList->new($p1, $p2);
	my ($p1_moves, $p2_moves) = $movelist->get_all_moves();
	for (my $i = 0; $i < @$p1_moves; $i++) {
	    my $p1_move = $p1_moves->[$i];
	    my $p2_move = $p2_moves->[$i];
	    my $piece = $old_to_new{$p1_move->get_piece()};
	    my $sq1 = $p1_move->get_start_square();
	    my $sq2 = $p1_move->get_dest_square();
	    my $flags = 0x0;
	    $flags |= MOVE_CAPTURE if ($p1_move->is_capture());
	    $flags |= MOVE_CASTLE_SHORT if ($p1_move->is_short_castle());
	    $flags |= MOVE_CASTLE_LONG if ($p1_move->is_long_castle());
	    $flags |= MOVE_EN_PASSANT if ($p1_move->is_en_passant());
	    $new_ml->add_move($piece, $sq1, $sq2, $flags);
	    if (defined $p2_move) {
		my $p2_piece = $old_to_new{$p2_move->get_piece()};
		my $p2_sq1 = $p2_move->get_start_square();
		my $p2_sq2 = $p2_move->get_dest_square();
		my $p2_flags = 0x0;
		$p2_flags |= MOVE_CAPTURE if ($p2_move->is_capture());
		$p2_flags |= MOVE_CASTLE_SHORT if ($p2_move->is_short_castle());
		$p2_flags |= MOVE_CASTLE_LONG if ($p2_move->is_long_castle());
		$p2_flags |= MOVE_EN_PASSANT if ($p2_move->is_en_passant());
		$new_ml->add_move($p2_piece, $p2_sq1, $p2_sq2, $p2_flags);
	    }
	}
	foreach my $movenum (keys %{$obj_data->{_player_has_moves}{$p1}}) {
	    $player_has_moves{$p1}{$movenum} = $obj_data->{_player_has_moves}{$p1}{$movenum};
	}
	foreach my $movenum (keys %{$obj_data->{_player_has_moves}{$p2}}) {
	    $player_has_moves{$p2}{$movenum} = $obj_data->{_player_has_moves}{$p2}{$movenum};
	}
	$new_obj->{movelist} = $new_ml;
	push @_games, $new_obj;
	my $i = $#_games;
	return bless \$i, $class;
    }
}

sub get_board {
    my ($self) = @_;
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    return $obj_data->{board};
}

sub get_pieces {
    my ($self, $player) = @_;
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    if (defined($player)) {
	return @{$obj_data->{pieces}{$player}};
    }
    else {
	my $player1 = $obj_data->{players}[0];
	my $player2 = $obj_data->{players}[1];
	return ($obj_data->{pieces}{$player1}, $obj_data->{pieces}{$player2});
    }
}

sub get_players {
    my ($self) = @_;
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    return @{$obj_data->{players}};
}

sub get_movelist {
    my ($self) = @_;
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    return $obj_data->{movelist};
}

sub get_message {
    my ($self) = @_;
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    my $msg = $obj_data->{message};
    $obj_data->{message} = '';
    return $msg;
}

sub get_capture {
    my ($self, $player, $movenum) = @_;
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    my $captures = $obj_data->{_captures};
    return $captures->{$player}{$movenum} if exists($captures->{$player}{$movenum});
}

sub _mark_threatened_kings {
    my ($obj_data) = @_;
    my $player1 = $obj_data->{players}[0];
    my $player2 = $obj_data->{players}[1];
    my @p1_pieces = @{$obj_data->{pieces}{$player1}};
    my @p2_pieces = @{$obj_data->{pieces}{$player2}};
    my $movelist = $obj_data->{movelist};
    my $p1_king = $obj_data->{_kings}[0];
    my $p2_king = $obj_data->{_kings}[1];
    my $board = $obj_data->{board};
    $p1_king->set_threatened(0);
    $p2_king->set_threatened(0);
    foreach my $p1_piece (@p1_pieces) {
	next if ($p1_piece->isa('Chess::Piece::King') or $p1_piece->captured());
	my $p1_sq = $p1_piece->get_current_square();
	my $p2_sq = $p2_king->get_current_square();
	next if (!$p1_piece->can_reach($p2_sq));
	if ($p1_piece->isa('Chess::Piece::Pawn')) {
	    next if (Chess::Board->horz_distance($p1_sq, $p2_sq) == 0);
	}
	elsif ($p1_piece->isa('Chess::Piece::King')) {
	    next if (Chess::Board->horz_distance($p1_sq, $p2_sq) == 2);
	}
	elsif (!$p1_piece->isa('Chess::Piece::Knight')) {
	    my $board_c = $board->clone();
	    $board_c->set_piece_at($p1_sq, undef);
	    $board_c->set_piece_at($p2_sq, undef);
	    next unless ($board_c->line_is_open($p1_sq, $p2_sq));
	}
	$p2_king->set_threatened(1);
    }
    foreach my $p2_piece (@p2_pieces) {
	next if ($p2_piece->isa('Chess::Piece::King') or $p2_piece->captured());
	my $p2_sq = $p2_piece->get_current_square();
	my $p1_sq = $p1_king->get_current_square();
	next if (!$p2_piece->can_reach($p1_sq));
	if ($p2_piece->isa('Chess::Piece::Pawn')) {
	    next if (Chess::Board->horz_distance($p1_sq, $p2_sq) == 0);
	}
	elsif ($p2_piece->isa('Chess::Piece::King')) {
	    next if (Chess::Board->horz_distance($p1_sq, $p2_sq) == 2);
	}
	elsif (!$p2_piece->isa('Chess::Piece::Knight')) {
	    my $board_c = $board->clone();
	    $board_c->set_piece_at($p1_sq, undef);
	    $board_c->set_piece_at($p2_sq, undef);
	    next unless ($board_c->line_is_open($p1_sq, $p2_sq));
	}
	$p1_king->set_threatened(1);
    }
}

sub _is_valid_en_passant {
    my ($obj_data, $piece, $sq1, $sq2) = @_;
    my $movelist = $obj_data->{movelist};
    my $movenum = $movelist->get_move_num();
    my $last_moved = $movelist->get_last_moved();
    my $move = $movelist->get_move($movenum, $last_moved);
    return 0 unless $move;
    my $piece2 = $move->get_piece();
    return 0 unless ($piece2->isa('Chess::Piece::Pawn'));
    my $player1 = $obj_data->{players}[0];
    my $player2 = $obj_data->{players}[1];
    my $p2_sq = $piece2->get_current_square();
    if ($piece2->get_player() eq $player1) {
	return 0 unless (Chess::Board->square_up_from($sq2) eq $p2_sq);
    }
    else {
	return 0 unless (Chess::Board->square_down_from($sq2) eq $p2_sq);
    }
    return 1;
}

sub _is_valid_short_castle {
    my ($obj_data, $piece, $sq1, $sq2) = @_;
    my $player1 = $obj_data->{players}[0];
    my $player2 = $obj_data->{players}[1];
    my $player = $piece->get_player();
    my $board = $obj_data->{board};
    my $tsq = $player eq $player1 ? "g1" : "g8";
    return 0 unless ($sq2 eq $tsq);
    unless (!$piece->moved()) {
	$obj_data->{message} = ucfirst($player) . "'s king has already moved";
	return 0;
    }
    my $rook;
    if ($player eq $player1) {
	$rook = $board->get_piece_at("h1");
    }
    else {
	$rook = $board->get_piece_at("h8");
    }
    unless (defined($rook) and !$rook->moved()) {
	$obj_data->{message} = ucfirst($player) . "'s kingside rook has already moved";
	return 0;
    }
    my $rook_sq = $player eq $player1 ? "h1" : "h8";
    my $king_sq = $player eq $player1 ? "e1" : "e8";
    my $board_c = $board->clone();
    $board_c->set_piece_at($king_sq, undef);
    $board_c->set_piece_at($rook_sq, undef);
    unless ($board_c->line_is_open($king_sq, $rook_sq)) {
	$obj_data->{message} = "There are pieces between " . ucfirst($player) . "'s king and rook";
	return 0;
    }
    return 1;
}

sub _is_valid_long_castle {
    my ($obj_data, $piece, $sq1, $sq2) = @_;
    my $player1 = $obj_data->{players}[0];
    my $player2 = $obj_data->{players}[1];
    my $player = $piece->get_player();
    my $board = $obj_data->{board};
    my $tsq = $player eq $player1 ? "c1" : "c8";
    return 0 unless ($sq2 eq $tsq);
    unless (!$piece->moved()) {
	$obj_data->{message} = ucfirst($player) . "'s king has already moved";
	return 0;
    }
    my $rook;
    if ($player eq $player1) {
	$rook = $board->get_piece_at("a1");
    }
    else {
	$rook = $board->get_piece_at("a8");
    }
    unless (defined($rook) and !$rook->moved()) {
	$obj_data->{message} = ucfirst($player) . "'s queenside rook has already moved";
	return 0;
    }
    my $rook_sq = $player eq $player1 ? "a1" : "a8";
    my $king_sq = $player eq $player1 ? "e1" : "e8";
    my $board_c = $board->clone();
    $board_c->set_piece_at($king_sq, undef);
    $board_c->set_piece_at($rook_sq, undef);
    unless ($board_c->line_is_open($king_sq, $rook_sq)) {
	$obj_data->{message} = "There are pieces between " . ucfirst($player) . "'s king and rook";
	return 0;
    }
    return 1;
}

sub is_move_legal {
    my ($self, $sq1, $sq2) = @_;
    unless (Chess::Board->square_is_valid($sq1)) {
	carp "Invalid square '$sq1'";
	return 0;
    }
    unless (Chess::Board->square_is_valid($sq2)) {
	carp "Invalid square '$sq2'";
	return 0;
    }
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    my $player1 = $obj_data->{players}[0];
    my $player2 = $obj_data->{players}[1];
    my $board = $obj_data->{board};
    my $piece = $board->get_piece_at($sq1);
    unless (defined($piece)) {
	carp "No piece at '$sq1'";
	return undef;
    }
    my $player = $piece->get_player();
    my $movelist = $obj_data->{movelist};
    my $last_moved = $movelist->get_last_moved();
    if ((defined($last_moved) and $last_moved eq $player) or
	(!defined($last_moved) and $player ne $player1)) {
	$obj_data->{message} = "Not your turn";
	return 0;
    }
    return 0 unless ($piece->can_reach($sq2));
    my $capture = $board->get_piece_at($sq2);
    if (defined($capture)) {
	unless ($capture->get_player() ne $player) {
	    $obj_data->{message} = "You can't capture your own piece";
	    return 0;
	}
	if ($piece->isa('Chess::Piece::Pawn')) {
	    unless (abs(Chess::Board->horz_distance($sq1, $sq2)) == 1) {
		$obj_data->{message} = "Pawns may only capture diagonally";
		return 0;
	    }
	}
	elsif ($piece->isa('Chess::Piece::King')) {
	    unless (abs(Chess::Board->horz_distance($sq1, $sq2)) < 2) {
		$obj_data->{message} = "You can't capture while castling";
		return 0;
	    }
	}
    }
    else {
	if ($piece->isa('Chess::Piece::Pawn')) {
	    my $ml = $obj_data->{movelist};
	    unless (Chess::Board->horz_distance($sq1, $sq2) == 0 or
	            _is_valid_en_passant($obj_data, $piece, $sq1, $sq2)) {
		$obj_data->{message} = "Pawns must capture on a diagonal move";
		return 0;
	    }
	}
    }
    my $valid_castle = 0;
    my $clone = $self->clone();
    my $r_clone = _get_game($$clone);
    my $king = $r_clone->{_kings}[($player eq $player1 ? 0 : 1)];
    if ($piece->isa('Chess::Piece::King')) {
	my $hdist = Chess::Board->horz_distance($sq1, $sq2);
	if (abs($hdist) == 2) {
	    _mark_threatened_kings($r_clone);
	    unless (!$king->threatened()) {
		$obj_data->{message} = "Can't castle out of check";
		return 0;
	    }
	    if ($hdist > 0) {
		return 0 unless (_is_valid_short_castle($obj_data, $piece, $sq1, $sq2));
		$valid_castle = MOVE_CASTLE_SHORT;
	    }
	    else {
		return 0 unless (_is_valid_long_castle($obj_data, $piece, $sq1, $sq2));
		$valid_castle = MOVE_CASTLE_LONG;
	    }
	}
    }
    elsif (!$piece->isa('Chess::Piece::Knight')) {
	my $board_c = $board->clone();
	$board_c->set_piece_at($sq1, undef);
	$board_c->set_piece_at($sq2, undef);
	unless ($board_c->line_is_open($sq1, $sq2)) {
	    $obj_data->{message} = "Line '$sq1' - '$sq2' is blocked";
	    return 0;
	}
    }
    if (!$valid_castle) {
	$clone->make_move($sq1, $sq2, 0);
	_mark_threatened_kings($r_clone);
	unless (!$king->threatened()) {
	    $obj_data->{message} = "Move leaves your king in check";
	    return 0;
	}
    }
    else {
	if ($valid_castle == MOVE_CASTLE_SHORT) {
	    my $tsq = Chess::Board->square_right_of($sq1);
    	    $clone->make_move($sq1, $tsq, 0);
	    _mark_threatened_kings($r_clone);
	    unless (!$king->threatened()) {
		$obj_data->{message} = "Can't castle through check";
		return 0;
	    }
	    $clone->make_move($tsq, $sq2, 0);
	    _mark_threatened_kings($r_clone);
	    unless (!$king->threatened()) {
		$obj_data->{message} = "Move leaves your king in check";
		return 0;
	    }
	}
	else {
	    my $tsq = Chess::Board->square_left_of($sq1);
	    $clone->make_move($sq1, $tsq, 0);
	    _mark_threatened_kings($r_clone);
	    unless (!$king->threatened()) {
		$obj_data->{message} = "Can't castle through check";
		return 0;
	    }
	    $clone->make_move($tsq, $sq2, 0);
	    _mark_threatened_kings($r_clone);
	    unless (!$king->threatened()) {
		$obj_data->{message} = "Move leaves your king in check";
		return 0;
	    }
	}
    }
    $obj_data->{message} = '';
    return 1;
}

sub make_move {
    my ($self, $sq1, $sq2, $validate) = @_;
    my $move;
    $validate = 1 unless (defined($validate));
    unless (Chess::Board->square_is_valid($sq1)) {
	carp "Invalid square '$sq1'";
	return undef;
    }
    unless (Chess::Board->square_is_valid($sq2)) {
	carp "Invalid square '$sq2'";
	return undef;
    }
    if ($validate) {
	return undef unless ($self->is_move_legal($sq1, $sq2));
    }
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    my $player1 = $obj_data->{players}[0];
    my $player2 = $obj_data->{players}[1];
    my $board = $obj_data->{board};
    my $piece = $board->get_piece_at($sq1);
    my $player = $piece->get_player();
    unless (defined($piece)) {
	carp "No piece at '$sq1'";
	return undef;
    }
    my $movelist = $obj_data->{movelist};
    my $capture = $board->get_piece_at($sq2);
    my $flags = 0x0;
    if ($validate && $piece->isa('Chess::Piece::Pawn')) {
	if ($player eq $player1) {
	    $flags |= MOVE_PROMOTE if (Chess::Board->vert_distance("d8", $sq2) == 0);
	}
	else {
	    $flags |= MOVE_PROMOTE if (Chess::Board->vert_distance("d1", $sq2) == 0);
	}
    }
    if (defined($capture)) {
	$flags |= MOVE_CAPTURE;
	$capture->set_captured(1);
	$board->set_piece_at($sq1, undef);
	$board->set_piece_at($sq2, $piece);
	$piece->set_current_square($sq2);
	$piece->set_moved(1);
	$move = $movelist->add_move($piece, $sq1, $sq2, $flags);
	my $movenum = $move->get_move_num();
	$obj_data->{_captures}{$player}{$movenum} = $capture;
    }
    else {
	if ($validate && $piece->isa('Chess::Piece::Pawn') && _is_valid_en_passant($obj_data, $piece, $sq1, $sq2)) {
	    my $last_moved = $movelist->get_last_moved();
	    $move = $movelist->get_move($movelist->get_move_num(), $last_moved);
	    $capture = $move->get_piece();
	    $flags |= MOVE_CAPTURE;
	    $flags |= MOVE_EN_PASSANT;
	    $capture->set_captured(1);
	    $board->set_piece_at($sq1, undef);
	    $board->set_piece_at($sq2, $piece);
	    $piece->set_current_square($sq2);
	    $move = $movelist->add_move($piece, $sq1, $sq2, $flags);
	    $obj_data->{_analyzed} = 0;
	    my $movenum = $move->get_move_num();
	    $piece->_set_firstmoved($movenum);
	    $obj_data->{_captures}{$player}{$movenum} = $capture;
	}
	else {
	    if ($validate && $piece->isa('Chess::Piece::King')) {
		$flags |= MOVE_CASTLE_SHORT if (_is_valid_short_castle($obj_data, $piece, $sq1, $sq2));
		$flags |= MOVE_CASTLE_LONG if (_is_valid_long_castle($obj_data, $piece, $sq1, $sq2));
	    }
	    if (($flags & MOVE_CASTLE_SHORT) || ($flags & MOVE_CASTLE_LONG)) {
		my ($rook_sq, $king_sq, $rook_sq_new, $king_sq_new);
		my ($rook, $king);
		if ($player eq $player1) {
		    $rook_sq = $flags & MOVE_CASTLE_SHORT ? "h1" : "a1";
		    $rook_sq_new = $flags & MOVE_CASTLE_SHORT ? "f1" : "d1";
		    $king_sq = "e1";
		    $king_sq_new = $flags & MOVE_CASTLE_SHORT ? "g1" : "c1";
		}
		else {
		    $rook_sq = $flags & MOVE_CASTLE_SHORT ? "h8" : "a8";
		    $rook_sq_new = $flags & MOVE_CASTLE_SHORT ? "f8" : "d8";
		    $king_sq = "e8";
		    $king_sq_new = $flags & MOVE_CASTLE_SHORT ? "g8" : "c8";
		}
		$king = $board->get_piece_at($king_sq);
		$rook = $board->get_piece_at($rook_sq);
		$board->set_piece_at($king_sq, undef);
		$board->set_piece_at($king_sq_new, $king);
		$king->set_current_square($king_sq_new);
		$king->set_moved(1);
		$board->set_piece_at($rook_sq, undef);
		$board->set_piece_at($rook_sq_new, $rook);
		$rook->set_current_square($rook_sq_new);
		$rook->set_moved(1);
	        $move = $movelist->add_move($piece, $sq1, $sq2, $flags);
		my $movenum = $move->get_move_num();
		$obj_data->{_analyzed} = 0;
		$king->_set_firstmoved($movenum);
		$rook->_set_firstmoved($movenum);
	    }
	    else {
		$board->set_piece_at($sq1, undef);
		$board->set_piece_at($sq2, $piece);
		$piece->set_current_square($sq2);
		$piece->set_moved(1);
		$move = $movelist->add_move($piece, $sq1, $sq2, $flags);
		my $movenum = $move->get_move_num();
		$piece->_set_firstmoved($movenum);
	    }
	}
    }
    return $move;
}

sub take_back_move {
    my ($self) = @_;
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    my $movelist = $obj_data->{movelist};
    my $board = $obj_data->{board};
    my $curr_player = $movelist->get_last_moved();
    my $player1 = $obj_data->{players}[0];
    my $move = $movelist->delete_move();
    if (defined($move)) {
	my $movenum = $move->get_move_num();
	my $piece = $move->get_piece();
	my $player = $piece->get_player();
	my $ssq = $move->get_start_square();
	my $dsq = $move->get_dest_square();
	if ($move->is_promotion()) {
	    bless $piece, 'Chess::Piece::Pawn';
	}
	if ($move->is_capture()) {
	    my $capture = $obj_data->{_captures}{$player}{$movenum};
	    if ($move->is_en_passant()) {
		if ($player eq $player1) {
		    $dsq = Chess::Board->square_down_from($dsq);
		}
		else {
		    $dsq = Chess::Board->square_up_from($dsq);
		}
	    }
	    $board->set_piece_at($dsq, $capture);
	    $capture->set_current_square($dsq);
	    $capture->set_captured(0); 
	    $board->set_piece_at($ssq, $piece);
	    $piece->set_current_square($ssq);
	    $piece->set_moved(0) if ($piece->_firstmoved() == $movenum);
	}
	elsif ($move->is_short_castle()) {
	    my $king_sq = $player eq $player1 ? "e1" : "e8";
	    my $rook_sq = $player eq $player1 ? "h1" : "h8";
	    my $king_curr_sq = $player eq $player1 ? "g1" : "g8";
	    my $rook_curr_sq = $player eq $player1 ? "f1" : "f8";
	    my $rook = $board->get_piece_at($rook_curr_sq);
	    $board->set_piece_at($king_curr_sq, undef);
	    $board->set_piece_at($rook_curr_sq, undef);
	    $board->set_piece_at($king_sq, $piece);
	    $board->set_piece_at($rook_sq, $rook);
	    $rook->set_current_square($rook_sq);
	    $piece->set_current_square($king_sq);
	    $rook->set_moved(0);
	    $piece->set_moved(0);
	}
	elsif ($move->is_long_castle()) {
	    my $king_sq = $player eq $player1 ? "e1" : "e8";
	    my $rook_sq = $player eq $player1 ? "a1" : "a8";
	    my $king_curr_sq = $player eq $player1 ? "c1" : "c8";
	    my $rook_curr_sq = $player eq $player1 ? "d1" : "d8";
	    my $rook = $board->get_piece_at($rook_curr_sq);
	    $board->set_piece_at($king_curr_sq, undef);
	    $board->set_piece_at($rook_curr_sq, undef);
	    $board->set_piece_at($king_sq, $piece);
	    $board->set_piece_at($rook_sq, $rook);
	    $rook->set_current_square($rook_sq);
	    $piece->set_current_square($king_sq);
	    $rook->set_moved(0);
	    $piece->set_moved(0);
	}
	else {
	    $board->set_piece_at($dsq, undef);
	    $board->set_piece_at($ssq, $piece);
	    $piece->set_current_square($ssq);
	    $piece->set_moved(0) if ($piece->_firstmoved() == $movenum);
	}
	delete $obj_data->{_player_has_moves}{$player}{$movenum};
    }
    return $move;
}

sub _player_has_moves {
    my ($self, $player) = @_;
    my $obj_data = _get_game($$self);
    my $movelist = $obj_data->{movelist};
    my $movenum = $movelist->get_move_num;
    if (exists($obj_data->{_player_has_moves}{$player}{$movenum})) {
	return $obj_data->{_player_has_moves}{$player}{$movenum};
    }
    foreach my $piece (@{$obj_data->{pieces}{$player}}) {
	next if (!$piece->isa('Chess::Piece::King') && $piece->captured());
	my @rsqs = $piece->reachable_squares();
	my $csq = $piece->get_current_square();
	foreach my $sq (@rsqs) {
	    if ($self->is_move_legal($csq, $sq)) {
		$obj_data->{_player_has_moves}{$player}{$movenum} = 1;
		return 1;
	    }
	}
    }
    $obj_data->{_player_has_moves}{$player}{$movenum} = 0;
    return 0;
}

sub do_promotion {
    my ($self, $new_piece) = @_;
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    my $board = $obj_data->{board};
    my $movelist = $obj_data->{movelist};
    my $movenum = $movelist->get_move_num();
    my $last_moved = $movelist->get_last_moved();
    my $move = $movelist->get_move($movenum, $last_moved);
    return unless $move->is_promotion();
    my $piece = $move->get_piece();
    my $csq = $piece->get_current_square();
    my $promoted = $piece->promote($new_piece);
    $board->set_piece_at($csq, $promoted);
    $move->set_promoted_to($new_piece);
}

sub player_in_check {
    my ($self, $player) = @_;
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    my $player1 = $obj_data->{players}[0];
    _mark_threatened_kings($obj_data);
    my $king = $obj_data->{_kings}[$player eq $player1 ? 0 : 1];
    return $king->threatened();
}

sub player_checkmated {
    my ($self, $player) = @_;
    return 0 unless ($self->player_in_check($player));
    if ($self->_player_has_moves($player)) {
	return 0;
    }
    else {
	return 1;
    }
}

sub player_stalemated {
    my ($self, $player) = @_;
    return 0 unless (!$self->player_in_check($player));
    if ($self->_player_has_moves($player)) {
	return 0;
    }
    else {
	return 1;
    }
}

sub result {
    my ($self) = @_;
    croak "Invalid Chess::Game reference" unless (ref($self));
    my $obj_data = _get_game($$self);
    croak "Invalid Chess::Game reference" unless ($obj_data);
    my $movelist = $obj_data->{movelist};
    my $last_moved = $movelist->get_last_moved();
    my $player1 = $obj_data->{players}[0];
    my $player2 = $obj_data->{players}[1];
    my $player = $last_moved eq $player1 ? $player2 : $player1;
    return undef if ($self->_player_has_moves($player));
    return 0 if ($self->player_stalemated($player));
    return 1 if ($self->player_checkmated($player) && $player eq $player2);
    return -1 if ($self->player_checkmated($player));
}

1;
