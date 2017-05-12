=head1 NAME

Chess::Game::MoveListEntry - a read-only class containing move data, used by
L<Chess::Game::MoveList> to record a game.

=head1 SYNOPSIS

$entry = Chess::Game::MoveListEntry->new(1, $pawn, "e2", "e4", 0);
$one = $entry->get_move_num();
$pawn = $entry->get_piece();
$e2 = $entry->get_start_square();
$e4 = $entry->get_dest_square();
$false = $entry->is_capture();
$false = $entry->is_short_castle();
$false = $entry->is_long_castle();
$false = $entry->is_en_passant();

=head1 DESCRIPTION

The Chess module provides a framework for writing chess programs with Perl.
This class forms part of that framework, containing object data about a single
move.

=head1 METHODS

=head2 Construction

=item new()

Constructs a new MoveListEntry with the provided parameters. Requires four
scalar parameters containing move number, piece, start square and destination
square. Optionally takes a fifth parameter containing flags for the entry.
The following flags are recognized (but there are no exported constants for
them):

    MOVE_CAPTURE == 0x01
    MOVE_CASTLE_SHORT == 0x02
    MOVE_CASTLE_LONG == 0x04
    MOVE_EN_PASSANT == 0x08

    $entry = Chess::Game::MoveListEntry->new(1, $pawn, "e2", "e4", 0);

=head2 Class methods

There are no class methods for this class.

=head2 Object methods

=item get_move_num()

Takes no parameters. Returns the move number this entry was constructed with.

=item get_piece()

Takes no parameters. Returns the piece reference this entry was constructed
with.

=item get_start_square()

Takes no parameters. Returns the start square this entry was constructed with.

=item get_dest_square()

Takes no parameters. Returns the destination square this entry was constructed
with.

=item is_capture()

Takes no parameters. Returns true if the entry was recorded as a capture

=item is_short_castle()

Takes no parameters. Returns true if the entry was recorded as a short
(kingside) castle.

=item is_long_castle()

Takes no parameters. Returns true if the entry was recorded as a long
(queenside) castle.

=item is_en_passant()

Takes no parameters. Returns true if the entry was recorded as an 'en passant'
capture. L</"is_capture()"> will also return true in this case.

=head1 DIAGNOSTICS

=item Invalid Chess::Game::MoveListEntry reference

The program uses a reference to a MoveListEntry that was not obtained by
calling L</"new()">. Ensure that all MoveListEntries in the program were
obtained either in this fashion, or through the container class,
L<Chess::Game::MoveList>, and that the reference refers to a defined value.

=head1 BUGS

Please report any bugs to the author.

=head1 AUTHOR

Brian Richardson <bjr@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2005 Brian Richardson. All rights reserved. This module is
Free Software. It may be modified and redistributed under the same terms as
Perl itself.

=cut
package Chess::Game::MoveListEntry;

use Carp;
use strict;

use constant OBJECT_FIELDS => (
    move_num => 0,
    piece_ref => undef,
    from_sq => '',
    dest_sq => '', 
    flags => 0x0,
    promoted_to => undef
);

# Chess::Game uses these flags as well
use constant MOVE_CAPTURE => 0x01;
use constant MOVE_CASTLE_SHORT => 0x02;
use constant MOVE_CASTLE_LONG => 0x04;
use constant MOVE_EN_PASSANT => 0x08;
use constant MOVE_PROMOTE => 0x10;

{
    my @_move_list_entries = ( );
    my %_object_fields = OBJECT_FIELDS;

    sub _get_entry {
	my ($i) = @_;
	return $_move_list_entries[$i];
    }

    sub new {
	my ($caller, $move_num, $r_piece, $from, $dest, $flags) = @_;
	my $class = ref($caller) || $caller;
	my $obj_data = { %_object_fields };
	$obj_data->{move_num} = $move_num;
	croak "Invalid Chess::Piece reference" unless ($r_piece);
	$obj_data->{piece_ref} = $r_piece;
	$obj_data->{from_sq} = $from;
	$obj_data->{dest_sq} = $dest;
	$obj_data->{flags} = defined($flags) ? $flags & 0x1f : 0x0;
	push @_move_list_entries, $obj_data;
	my $i = $#_move_list_entries;
	return bless \$i, $class;
    }

    sub clone {
	my ($self) = @_;
	my $class = ref($self) || croak "Invalid Chess::Game::MoveListEntry reference";
	my $obj_data = { %{$_move_list_entries[$$self]} } || croak "Invalid Chess:Game::MoveListEntry reference";
	if (my $r_piece = $obj_data->{piece_ref}) {
	    $r_piece = $r_piece->clone() if ($r_piece->can('clone'));
	    $obj_data->{piece_ref} = $r_piece;
	}
	push @_move_list_entries, $obj_data;
	my $i = $#_move_list_entries;
	return bless \$i, $class;
    }

    sub DESTROY {
	my ($self) = @_;
	$_move_list_entries[$$self] = undef if (ref($self));
    }
}

sub get_move_num {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless ($obj_data);
    return $obj_data->{move_num}; 
}

sub get_piece {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless ($obj_data);
    return $obj_data->{piece_ref}; 
}

sub get_start_square {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless ($obj_data);
    return $obj_data->{from_sq}; 
}

sub get_dest_square {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless ($obj_data);
    return $obj_data->{dest_sq}; 
}

sub is_capture {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    return $obj_data->{flags} & MOVE_CAPTURE;
}

sub is_short_castle {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    return $obj_data->{flags} & MOVE_CASTLE_SHORT;
}

sub is_long_castle {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    return $obj_data->{flags} & MOVE_CASTLE_LONG;
}

sub is_en_passant {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    return $obj_data->{flags} & MOVE_EN_PASSANT;
}

sub is_promotion {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    return $obj_data->{flags} & MOVE_PROMOTE;
}

sub get_promoted_to {
    my ($self) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    return $obj_data->{promoted_to};
}

sub set_promoted_to {
    my ($self, $new_piece) = @_;
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    my $obj_data = _get_entry($$self);
    croak "Invalid Chess::Game::MoveListEntry reference" unless (ref($self));
    $obj_data->{promoted_to} = $new_piece;
}

1;
