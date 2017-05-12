=head1 NAME

Chess::Game::MoveList - a specialized list class for recording the moves of a
L<Chess::Game>

=head1 SYNOPSIS

    $movelist = Chess::Game::MoveList->new("white", "black");
    $wpawn = Chess::Game::Pawn->new("e2", "white");
    $entry = $movelist->add_move($wpawn, "e2", "e4");
    $true = $entry->get_piece() eq $entry;
    $bpawn = Chess::Game::Pawn->new("e7", "black");
    $entry = $movelist->add_move($bpawn, "e7", "e6");
    $entry = $movelist->add_move($wpawn, "e4", "e5");
    @del_entries = $movelist->delete_move(1, "white"); # delete the list
    $true = $entries[0]->get_piece() eq $wpawn;
    $true = $entries[0]->get_dest_square() eq "e4";
    $true = $entries[1]->get_piece() eq $bpawn;
    $true = $entries[1]->get_dest_square() eq "e6";

=head1 DESCRIPTION

The Chess module provides a framework for writing chess programs with Perl.
This class forms part of that framework, recording a log of all moves during
a L<Chess::Game> in such a fashion that the list can be used to undo moves
that have been made.

=head1 METHODS

=head2 Construction

=item new()

Creates a new Chess::Game::MoveList. Takes two scalar parameters containing the
names of the two players. These names will be used as a key for calls to
L</"get_move()"> and L</"delete_move()">.

    $movelist = Chess::Game::MoveList("white", "black");

=head2 Class methods

=head2 Object methods

=item clone()

Creates a new Chess::MoveList based on an existing one. Returns a new list
with identical contents, but can be manipulated separately of the original.

    $clone = $movelist->clone();

=item get_move_num()

Takes no parameters. Returns the current move number of the game. Numbering
is identical to numbering in a regular chess game. The move number does not
increment until the first player's next turn.

    $move_num = $movelist->get_move_num();

=item get_last_moved()

Takes no parameters. Returns the name of the player who last moved. It will
be one of the values passed to L</"new()"> and can be used as a key to
L</"get_move()"> and L</"delete_move()">.

    $last_moved = $movelist->get_last_moved();

=item get_move()

Takes two scalar parameters containing the move number and the name of the
player to get the move for. Returns a blessed L<Chess::Game::MoveListEntry>
with the particulars for that move, or C<undef> if that move wasn't found.

    $entry = $movelist->get_move(1, "white"); # pawn to king's four, perhaps?

=item get_all_moves()

Takes an optional scalar parameter specifying which player to return a list
of moves for. Returns an array of all the entries for moves made by that
player. If the player is not specified, returns a two-element array containing
references to the first player's and second player's lists respectively.

    @wmoves = $movelist->get_all_moves("white");
    @bmoves = $movelist->get_all_moves("black");
    ($wmoves, $bmoves) = $movelist->get_all_moves();

=item add_move()

Takes three scalar parameters containing a reference to the piece being moved,
the square it is being moved from, and square it is being moved to. Returns
a blessed L<Chess::Game::MoveListEntry> containing the particulars for that
move.

    $entry = $movelist->add_move($pawn, "e2", "e4");

=item delete_move()

Takes no parameters. Returns the last move to be made, if there is one, and
then deletes it. The MoveList is now in exactly the same state as prior to
the last move being made.

    $entry = $movelist->delete_move();

=head1 DIAGNOSTICS

=item Invalid Chess::Game::MoveList reference

The program contains a reference to a Chess::Game::MoveList object not
obtained through L</"new()"> or L</"clone()">. Ensure that all such references
were obtained properly, and that the reference refers to a defined value.

=item Chess::Game::MoveList player entries must be unique keys

L</"new()"> requires that the two arguments can be used as hash keys. Ensure
that the call to new contains two defined, unique keys as player names.

=item Invalid move number

The program contains a call to a method requiring a move number, and passes in
a move number of 0 or less. Move numbering starts at 1 to be consistent with
a standard chess game.

=head1 BUGS

Please report any bugs to the author.

=head1 AUTHOR

Brian Richardson <bjr@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2005 Brian Richardson. All rights reserved. This module is
Free Software. It may be modified and redistributed under the same terms as
Perl itself.

=cut
package Chess::Game::MoveList;

use Chess::Game::MoveListEntry;
use Carp;
use strict;

use constant OBJECT_DATA => (
    move_num => 0,
    players => undef,
    last_moved => undef,
    list => undef
);

{
    my %_object_data = OBJECT_DATA;
    my @_move_lists = ( );
    my $_last_moved = undef;

    sub _get_move_list {
	my ($i) = @_;
	return $_move_lists[$i];
    }

    sub new {
	my ($caller, $player1, $player2) = @_;
	my $class = ref($caller) || $caller;
	if (!defined($player1 && $player2) or $player1 eq $player2) {
	    croak "Chess::Game::MoveList player labels must be unique keys";
	}
	my $obj_data = { %_object_data };
	$obj_data->{players} = [ $player1, $player2 ];
	$obj_data->{list} = { $player1 => [ ], $player2 => [ ] };
	push @_move_lists, $obj_data;
	my $i = $#_move_lists;
	return bless \$i, $class;
    }

    sub clone {
	my ($self) = @_;
	my $class = ref($self) || croak "Invalid Chess::Game::MoveList reference";
	my $r_move_list = $_move_lists[$$self];
	croak "Invalid Chess::Game::MoveList reference" unless ($r_move_list);
	my $obj_data = { %_object_data };
	$obj_data->{players} = [ @{$r_move_list->{players}} ];
	my $player1 = $obj_data->{players}[0];
	my $player2 = $obj_data->{players}[1];
	foreach my $entry (@{$r_move_list->{list}{$player1}}) {
	    push @{$obj_data->{list}{$player1}}, $entry->clone();
	}
	foreach my $entry (@{$r_move_list->{$player2}}) {
	    push @{$obj_data->{list}{$player2}}, $entry->clone();
	}
	push @_move_lists, $obj_data;
	my $i = $#_move_lists;
	return bless \$i, $class;
    }

    sub DESTROY {
	my ($self) = @_;
	$_move_lists[$$self] = undef if (ref($self));
    }
}

sub get_move_num {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveList reference" unless (ref($self));
    my $obj_data = _get_move_list($$self);
    croak "Invalid Chess::Game::MoveList reference" unless ($obj_data);
    return $obj_data->{move_num} + 1;
}

sub get_last_moved {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveList reference" unless (ref($self));
    my $obj_data = _get_move_list($$self);
    croak "Invalid Chess::Game::MoveList reference" unless ($obj_data);
    my $last_moved = $obj_data->{last_moved};
    return undef unless defined($last_moved);
    return $obj_data->{players}[$last_moved];
}

sub get_players {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveList reference" unless (ref($self));
    my $obj_data = _get_move_list_ref($$self);
    croak "Invalid Chess::Game::MoveList reference" unless ($obj_data);
    return @{$obj_data->{players}};
}

sub get_move {
    my ($self, $move_num, $player) = @_;
    croak "Invalid Chess::Game::MoveList reference" unless (ref($self));
    my $obj_data = _get_move_list($$self);
    croak "Invalid Chess::Game::MoveList reference" unless ($obj_data);
    return undef unless (defined($player));
    return undef unless (grep /^$player$/, @{$obj_data->{players}});
    return $obj_data->{list}{$player}[$move_num - 1];
}

sub get_all_moves {
    my ($self, $player) = @_;
    croak "Invalid Chess::Game::MoveList reference" unless (ref($self));
    my $obj_data = _get_move_list($$self);
    croak "Invalid Chess::Game::MoveList reference" unless ($obj_data);
    return undef if (defined($player) and !grep /^$player$/, @{$obj_data->{players}});
    if (defined($player)) {
	return @{$obj_data->{list}{$player}};
    }
    else {
	my $key1 = $obj_data->{players}[0];
	my $key2 = $obj_data->{players}[1];
	my @moves = ([ @{$obj_data->{list}{$key1}} ], [ @{$obj_data->{list}{$key2}} ]);
	return @moves;
    }
}

sub add_move {
    my ($self, $piece, $sq1, $sq2, $flags) = @_;
    croak "Invalid Chess::Game::MoveList reference" unless (ref($self));
    my $obj_data = _get_move_list($$self);
    croak "Invalid Chess::Game::MoveList reference" unless ($obj_data);
    my $move_num = $obj_data->{move_num};
    my $last_moved = $obj_data->{last_moved};
    my $turn = (defined($last_moved) && ($last_moved == 0)) ? 1 : 0;
    if (defined($last_moved)) {
	$move_num++ if ($turn == 0);
    }
    else {
	$move_num = 0;
    }
    my $player = $obj_data->{players}[$turn];
    my $entry = Chess::Game::MoveListEntry->new($move_num + 1, $piece, $sq1, $sq2, $flags);
    my $move_list_ref = $obj_data->{list}{$player};
    $move_list_ref->[$move_num] = $entry;
    $obj_data->{last_moved} = $turn;
    $obj_data->{move_num} = $move_num;
    return $entry;
}

sub delete_move {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveList reference" unless (ref($self));
    my $obj_data = _get_move_list($$self);
    croak "Invalid Chess::Game::MoveList reference" unless ($obj_data);
    my $last_moved = $obj_data->{last_moved};
    return undef unless (defined($last_moved));
    my $curr_move = $obj_data->{move_num};
    my $player = $obj_data->{players}[$last_moved];
    my $entry = $obj_data->{list}{$player}[$curr_move];
    delete $obj_data->{list}{$player}[$curr_move];
    $obj_data->{last_moved} = $last_moved ? 0 : 1;
    if ($last_moved == 0) {
	if ($curr_move == 0) {
    	    $obj_data->{last_moved} = undef;
	}
	else {
	    $obj_data->{move_num}--;
	}
    }
    return $entry;
}

1;
