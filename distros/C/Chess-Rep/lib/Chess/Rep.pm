package Chess::Rep;

use strict;

use POSIX;

our $VERSION = '0.8';

use constant ({
    CASTLE_W_OO  => 1,
    CASTLE_W_OOO => 2,
    CASTLE_B_OO  => 4,
    CASTLE_B_OOO => 8,
    PIECE_TO_ID => {
        p => 0x01,              # black pawn
        n => 0x02,              # black knight
        k => 0x04,              # black king
        b => 0x08,              # black bishop
        r => 0x10,              # black rook
        q => 0x20,              # black queen
        P => 0x81,              # white pawn
        N => 0x82,              # white knight
        K => 0x84,              # white king
        B => 0x88,              # white bishop
        R => 0x90,              # white rook
        Q => 0xA0,              # white queen
    },
    ID_TO_PIECE => [
        undef,                  # 0
        'p',                    # 1
        'n',                    # 2
        undef,                  # 3
        'k',                    # 4
        undef,                  # 5
        undef,                  # 6
        undef,                  # 7
        'b',                    # 8
        undef,                  # 9
        undef,                  # 10
        undef,                  # 11
        undef,                  # 12
        undef,                  # 13
        undef,                  # 14
        undef,                  # 15
        'r',                    # 16
        undef,                  # 17
        undef,                  # 18
        undef,                  # 19
        undef,                  # 20
        undef,                  # 21
        undef,                  # 22
        undef,                  # 23
        undef,                  # 24
        undef,                  # 25
        undef,                  # 26
        undef,                  # 27
        undef,                  # 28
        undef,                  # 29
        undef,                  # 30
        undef,                  # 31
        'q',                    # 32
    ],
    FEN_STANDARD => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
});

use Exporter 'import';

our %EXPORT_TAGS = (
    castle => [
        qw( CASTLE_W_OO
            CASTLE_W_OOO
            CASTLE_B_OO
            CASTLE_B_OOO
      )],
    other => [
        qw( PIECE_TO_ID
            ID_TO_PIECE
            FEN_STANDARD
      )],
);

{
    my %seen;

    push @{$EXPORT_TAGS{all}},
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}

Exporter::export_ok_tags('castle');
Exporter::export_ok_tags('all');

my @MOVES_N = (31, 33, 14, 18, -18, -14, -33, -31);
my @MOVES_B = (15, 17, -15, -17);
my @MOVES_R = (1, 16, -16, -1);
my @MOVES_K = (@MOVES_B, @MOVES_R);

=head1 NAME

Chess::Rep - represent chess positions, generate list of legal moves, parse moves in various formats.

The name stands for "Chess Representation", basically meaning that
this module won't actually play chess -- it just helps you represent
the board and validate the moves according to the laws of chess.  It
also generates a set of all valid moves for the color to play.

=head1 SYNOPSIS

  my $pos = Chess::Rep->new;
  print $pos->get_fen;

  # use any decent notation to describe moves
  # the parser will read pretty much anything which isn't ambiguous

  $pos->go_move('e4');
  $pos->go_move('e7e5');
  $pos->go_move('Bc4');
  $pos->go_move('Nc8-C6');
  $pos->go_move('Qf3');
  $pos->go_move('d6');
  $pos->go_move('F3-F7');

  if ($pos->status->{check}) {
    print("CHECK\n");
  }

  if ($pos->status->{mate}) {
    print("MATE\n");
  }

  if ($pos->status->{stalemate}) {
    print("STALEMATE\n");
  }

  # reset position from FEN

  $pos->set_from_fen('r1b1k1nr/pp1ppppp/8/2pP4/3b4/8/PPP1PqPP/RNBQKBNR w KQkq - 0 1');
  my $status = $pos->status;

  my $moves = $status->{moves}; # there's only one move, E1-D2
  print Chess::Rep::get_field_id($moves->[0]{from}) . '-' .
        Chess::Rep::get_field_id($moves->[0]{to});

  print $status->{check};   # 1
  print $status->{mate};
  print $status->{stalemate};

=head1 REPRESENTATION

=head2 Pieces and colors

As of version B<0.4>, a piece is represented as a byte, as follows:

        p => 0x01  # black pawn
        n => 0x02  # black knight
        k => 0x04  # black king
        b => 0x08  # black bishop
        r => 0x10  # black rook
        q => 0x20  # black queen
        P => 0x81  # white pawn
        N => 0x82  # white knight
        K => 0x84  # white king
        B => 0x88  # white bishop
        R => 0x90  # white rook
        Q => 0xA0  # white queen

This representation is incompatible with older versions, which were
representing a piece as a char.  Performance is the main reason for
this change.  For example, in order to test if a piece is king
(regardless the color) we now do:

    $p & 0x04

while in versions prior to 0.4 we needed to do:

    lc $p eq 'k'

Similarly, if we wanted to check if a piece is a queen or a bishop, in
previous version we had:

    lc $p eq 'q' || lc $p eq 'b'

while in the new version we do:

    $p & 0x28

which is considerably faster.  (if you wonder why the difference
between 0.03 milliseconds and 0.01 milliseconds matters all that much,
try writing a chess engine).

To determine the color of a piece, AND with 0x80 (zero means a black
piece, 0x80 is white piece).  In previous version we needed to do uc
$p eq $p, a lot slower.

=head2 Position

The diagram is represented in the "0x88 notation" (see [2]) -- an
array of 128 elements, of which only 64 are used.  An index in this
array maps directly to a row, col in the chess board like this:

    my ($row, $col) = (1, 4); # E2
    my $index = $row << 4 | $col;  ( = 0x14)

Valid row and col numbers are 0..7 (so they have bit 4 unset),
therefore it's easy to detect when an index is offboard by AND with
0x88.  Read [2] for more detailed description of this representation.

=head2 Some terms used in this doc

Following, when I refer to a field "index", I really mean an index in
the position array, which can be 0..127.  Using get_index() you can
compute an index from a field ID.

By field ID I mean a field in standard notation, i.e. 'e4' (case
insensitive).

When I refer to row / col, I mean a number 0..7.  Field A1 corresponds
to row = 0 and col = 0, and has index 0x00.  Field H7 has row = 7, col
= 7 and index 0x77.

Internally this object works with field indexes.

=cut

=head1 OBJECT METHODS

=head2 new($fen)

Constructor.  Pass a FEN string if you want to initialize to a certain
position.  Otherwise it will be initialized with the standard starting
position.

=cut

sub new {
    my ($class, $fen) = @_;
    my $self = {};
    bless $self, $class;
    $self->set_from_fen($fen || FEN_STANDARD);
    return $self;
}

=head2 reset()

Resets the object to standard start position.

=cut

sub reset {
    shift->set_from_fen(FEN_STANDARD);
}

=head2 set_from_fen($fen)

Reset this object to a position described in FEN notation.

=cut

sub set_from_fen {
    my ($self, $fen) = @_;
    $self->_reset;
    my @data = split(/\s+/, $fen);
    my ($board, $to_move, $castle, $enpa, $halfmove, $fullmove) = @data;
    my @board = reverse(split(/\//, $board));
    for my $row (0..7) {
        my $data = $board[$row];
        my $col = 0;
        while (length $data > 0) {
            my $p = substr($data, 0, 1, '');
            my $id = PIECE_TO_ID->{$p};
            if ($id) {
                $self->set_piece_at_index(get_index_from_row_col($row, $col++), $id);
            } elsif ($p =~ /[1-8]/) {
                $col += $p;
            } else {
                die "Error parsing FEN position: $fen";
            }
        }
    }
    my $c = 0;
    $c |= CASTLE_W_OO  if index($castle, 'K') >= 0;
    $c |= CASTLE_W_OOO if index($castle, 'Q') >= 0;
    $c |= CASTLE_B_OO  if index($castle, 'k') >= 0;
    $c |= CASTLE_B_OOO if index($castle, 'q') >= 0;
    $self->{castle} = $c;
    if (lc $to_move eq 'w') {
        $self->{to_move} = 0x80;
    } elsif (lc $to_move eq 'b') {
        $self->{to_move} = 0;
    } else {
        $self->{to_move} = undef;
    }
    $self->{enpa} = $enpa ne '-' ? get_index($enpa) : 0;
    $self->{fullmove} = $fullmove;
    $self->{halfmove} = $halfmove;
    $self->compute_valid_moves;
}

=head2 get_fen()

Returns the current position in standard FEN notation.

=cut

sub get_fen {
    my ($self, $short) = @_;
    my @a;
    for (my $row = 8; --$row >= 0;) {
        my $str = '';
        my $empty = 0;
        for my $col (0..7) {
            my $p = $self->get_piece_at_index(get_index_from_row_col($row, $col));
            if ($p) {
                $p = ($p & 0x80) ? uc ID_TO_PIECE->[$p & 0x3F] : ID_TO_PIECE->[$p];
                $str .= $empty
                  if $empty;
                $empty = 0;
                $str .= $p;
            } else {
                ++$empty;
            }
        }
        $str .= $empty
          if $empty;
        push @a, $str;
    }
    my $pos = join('/', @a);
    @a = ( $pos );
    $a[1] = $self->{to_move} ? 'w' : 'b';
    my $castle = $self->{castle};
    my $c = '';
    $c .= 'K' if $castle & CASTLE_W_OO;
    $c .= 'Q' if $castle & CASTLE_W_OOO;
    $c .= 'k' if $castle & CASTLE_B_OO;
    $c .= 'q' if $castle & CASTLE_B_OOO;
    $a[2] = $c || '-';
    $a[3] = $self->{enpa} ? lc get_field_id($self->{enpa}) : '-';
    if (!$short) {
        $a[4] = $self->{halfmove};
        $a[5] = $self->{fullmove};
    }
    return join(' ', @a);
}

=head2 status()

Returns the status of the current position.  The status is
automatically computed whenever the position is changed with
set_from_fen() or go_move().  The return valus is a hash as follows:

  {
    moves      => \@array_of_all_legal_moves,
    pieces     => \@array_of_pieces_to_move,
    hash_moves => \%hash_of_all_legal_moves,
    type_moves => \%hash_of_moves_by_type_and_target_field,
    check      => 1 if king is in check, undef otherwise,
    mate       => 1 if position is mate, undef otherwise,
    stalemate  => 1 if position is stalemate, undef otherwise
  }

The last three are obvious -- simple boolean indicators that describe
the position state.  The first three are:

=over

=item * B<moves>

An array of all the legal moves.  A move is represented as a hash
containing:

  {
    from  => $index_of_origin_field,
    to    => $index_of_target_field,
    piece => $id_of_the_moved_piece
  }

=item * B<hash_moves>

A hash table containing as keys all legal moves, in the form
"$from_index:$to_index".  For example, should E2-E4 be the single
legal move, then this hash would be:

  {
    '35-55' => 1
  }

=item * B<type_moves>

Again a hash table that maps target fields to piece types.  For
example, if you want to determine all white bishops that can move on
field C4 (index 58), you can do the following:

  my $a = $self->status->{type_moves}{58}{0x88};

@$a now contains the indexes of the fields that currently hold white
bishops that are allowed to move on C4.

This hash is mainly useful when we interpret standard algebraic
notation.

=back

=cut

sub status {
    return shift->{status};
}

sub _reset {
    my ($self) = @_;
    my @a = (0) x 128;
    $self->{pos} = \@a;
    $self->{castle} = CASTLE_W_OO | CASTLE_W_OOO | CASTLE_B_OO | CASTLE_B_OOO;
    $self->{has_castled} = 0;
    $self->{to_move} = 0x80; # white
    $self->{enpa} = 0;
    $self->{halfmove} = 0;
    $self->{fullmove} = 0;
    $self->{status} = undef;
}

=head2 set_piece_at($where, $piece)

Sets the piece at the given position.  $where can be:

  - a full index conforming to our representation
  - a standard field ID (i.e. 'e2')

The following are equivalent:

  $self->set_piece_at(0x14, 'P');
  $self->set_piece_at('e2', 'P');

Piece can be a piece ID as per our internal representation, or a piece
name such as 'P', 'B', etc.

This function does not rebuild the valid moves hashes so if you call
status() you'll get wrong results.  After you setup the position
manually using this function (same applies for set_piece_at_index())
you need to call $self->compute_valid_moves().

=cut

sub set_piece_at {
    my ($self, $index, $p) = @_;
    if ($p =~ /^[pnbrqk]$/i) {
        $p = PIECE_TO_ID->{$p};
    }
    if ($index =~ /^[a-h]/oi) {
        $index = get_index($index);
    }
    my $old = $self->{pos}[$index];
    $self->{pos}[$index] = $p;
    return $old;
}

=head2 set_piece_at_index($index, $p)

Sets the piece at the given index to $p.  Returns the old piece.  It's
similar to the function above, but faster as it only works with field
indexes.

=cut

sub set_piece_at_index {
    my ($self, $index, $p) = @_;
    my $old = $self->{pos}[$index];
    $self->{pos}[$index] = $p;
    return $old;
}

=head2 get_piece_at($where, $col)

Returns the piece at the given position.  $where can be:

  - a full index conforming to our representation
  - a 0..7 row number (in which case $col is required)
  - a standard field ID (i.e. 'e2')

The following are equivalent:

  $self->get_piece_at('e2');
  $self->get_piece_at(0x14);
  $self->get_piece_at(1, 4);

If you call this function in array context, it will return the index
of the field as well; this is useful if you don't pass a computed
index:

  ($piece, $index) = $self->get_piece_at('e2');
  # now $piece is 'P' and $index is 0x14

=cut

sub get_piece_at {
    my ($self, $index, $col) = @_;
    if (defined $col) {
        $index = get_index($index, $col);
    } elsif ($index =~ /^[a-h]/oi) {
        $index = get_index($index);
    }
    my $p = $self->{pos}[$index];
    return ($p, $index)
      if wantarray;
    return $p;
}

=head2 get_piece_at_index($index)

Similar to the above function, this one is faster if you know for sure
that you pass an $index to it.  That is, it won't support $row, $col
or field IDs, it only does field indexes.

  $self->get_piece_at_index(0x14)
    == $self->get_piece_at(1, 4)
    == $self->get_piece_at('e2')
    == $self->get_piece_at(0x14)

=cut

sub get_piece_at_index {
    return shift->{pos}[shift];
}

=head2 to_move()

Returns (and optionally sets if you pass an argument) the color to
move.  Colors are 0 (black) or 1 (white).

=cut

sub to_move {
    my $self = shift;
    if (@_) {
        $self->{to_move} = $_[0] ? 0x80 : 0;
    }
    return $self->{to_move};
}

=head2 go_move($move)

Updates the position with the given move.  The parser is very
forgiving; it understands a wide range of move formats:

  e4, e2e4, exf5, e:f5, e4xf5, e4f5, Nc3, b1c3, b1-c3,
  a8=Q, a7a8q#, a7-a8=q#, a8Q, etc.

After the move is executed, the position status is recomputed and you
can access it calling $self->status.  Also, the turn is changed
internally (see L<to_move()>).

This method returns a hash containing detailed information about this
move.  For example, for "axb8=Q" it will return:

  {
    from        => 'A7'
    from_index  => 0x60
    from_row    => 6
    from_col    => 0
    to          => 'B8'
    to_index    => 0x71
    to_row      => 7
    to_col      => 1
    piece       => 'P'
    promote     => 'Q'
    san         => 'axb8=Q'
  }

Of course, the exact same hash would be returned for "a7b8q",
"A7-b8=Q", "b8Q".  This method parses a move that can be given in a
variety of formats, and returns a canonical representation of it
(including a canonical SAN notation which should be understood by any
conformant parser on the planet).

=cut

sub go_move {
    my ($self, $move) = @_;
    my ($from, $from_index, $to, $to_index, $piece);

    my $color = $self->{to_move};
    my $col;
    my $row;
    my $promote;

    my $orig_move = $move;

    if (index($move, 'O-O-O') == 0) {
        $move = $color ? 'E1C1' : 'E8C8';
    } elsif (index($move, 'O-O') == 0) {
        $move = $color ? 'E1G1' : 'E8G8';
    }

    if ($move =~ s/^([PNBRQK])//) {
        $piece = lc $1;
    }

    if ($move =~ s/^([a-h][1-8])[:x-]?([a-h][1-8])//i) { # great, no ambiguities

        ($from, $to) = ($1, $2);

    } elsif ($move =~ s/^([a-h])[:x-]?([a-h][1-8])//i) {

        $col = ord(uc $1) - 65;
        $to = $2;

    } elsif ($move =~ s/^([1-8])[:x-]?([a-h][1-8])//i) {

        $row = ord($1) - 49;
        $to = $2;

    } elsif ($move =~ s/^[:x-]?([a-h][1-8])//i) {

        $to = $1;

    } else {

        die("Could not parse move: $orig_move");

    }

    if ($move =~ s/^=?([RNBQ])//i) {
        $promote = uc $1;
    }

    if ($piece) {
        $piece = PIECE_TO_ID->{$piece};
    } else {
        if (!$from) {
            $piece = 1;         # black pawn
        } else {
            ($piece, $from_index) = $self->get_piece_at($from);
            if (!$piece) {
                die("Illegal move: $orig_move (field $from is empty)");
            }
        }
    }

    $piece |= $color;           # apply color

    if (!$to) {
        die("Can't parse move: $orig_move (missing target field)");
    }

    $to_index = get_index($to);

    # all moves that a piece of type $piece can make to field $to_index
    my $tpmove = $self->{status}{type_moves}{$to_index}{$piece};

    if (!$tpmove || !@$tpmove) {
        die("Illegal move: $orig_move");
    }

    if (!$from) {
        # print Data::Dumper::Dumper($tpmove), "\n";
        if (@$tpmove == 1) {
            # unambiguous
            $from_index = $tpmove->[0];
        } else {
            foreach my $origin (@$tpmove) {
                my ($t_row, $t_col) = get_row_col($origin);
                if (defined($row) && $row == $t_row) {
                    $from_index = $origin;
                    last;
                } elsif (defined($col) && $col == $t_col) {
                    $from_index = $origin;
                    last;
                }
            }
        }
        if (defined $from_index) {
            $from = get_field_id($from_index);
        } else {
            die("Ambiguous move: $orig_move");
        }
    } else {
        die "Illegal move: $orig_move!\n"
          unless ( defined $from_index && grep $_ == $from_index, @$tpmove );
    }

    unless (defined $from_index) {
        $from_index = get_index($from);
    }

    $from = uc $from;
    $to = uc $to;

    my ($from_row, $from_col) = get_row_col($from_index);
    my ($to_row, $to_col) = get_row_col($to_index);

    # execute move

    my $prev_enpa = $self->{enpa};
    $self->{enpa} = 0;

    my $is_capture = 0;
    my $san;                    # compute canonical notation
    my $is_pawn = $piece & 0x01;

  SPECIAL: {
        # 1. if it's castling, we have to move the rook
        if ($piece & 0x04) {    # is king?
            if ($from_index == 0x04 && $to_index == 0x06) {
                $san = 'O-O';
                $self->{has_castled} |= CASTLE_W_OO;
                $self->_move_piece(0x07, 0x05);
                last SPECIAL;
            } elsif ($from_index == 0x74 && $to_index == 0x76) {
                $san = 'O-O';
                $self->{has_castled} |= CASTLE_B_OO;
                $self->_move_piece(0x77, 0x75);
                last SPECIAL;
            } elsif ($from_index == 0x04 && $to_index == 0x02) {
                $san = 'O-O-O';
                $self->{has_castled} |= CASTLE_W_OOO;
                $self->_move_piece(0x00, 0x03);
                last SPECIAL;
            } elsif ($from_index == 0x74 && $to_index == 0x72) {
                $san = 'O-O-O';
                $self->{has_castled} |= CASTLE_B_OOO;
                $self->_move_piece(0x70, 0x73);
                last SPECIAL;
            }
        }

        # 2. is it en_passant?
        if ($is_pawn) {
            if ($from_col != $to_col && $prev_enpa && $prev_enpa == $to_index) {
                $self->set_piece_at_index(get_index_from_row_col($from_row, $to_col), 0);
                $is_capture = 1;
                last SPECIAL;
            }
            if (abs($from_row - $to_row) == 2) {
                $self->{enpa} = get_index_from_row_col(($from_row + $to_row) / 2, $from_col);
            }
        }
    }

    {
        my $promote_id;
        if ($promote) {
            $promote_id = PIECE_TO_ID->{lc $promote} | $color;
        }
        my $tmp = $self->_move_piece($from_index, $to_index, $promote_id);
        $is_capture ||= $tmp;
    }
    $self->{to_move} ^= 0x80;

    if ($self->{to_move}) {
        ++$self->{fullmove};
    }

    if (!$is_pawn && !$is_capture) {
        ++$self->{halfmove};
    } else {
        $self->{halfmove} = 0;
    }

    my $status = $self->compute_valid_moves;

    if (!$san) {
        $san = $is_pawn ? '' : uc ID_TO_PIECE->[$piece & 0x3F];
        $san .= lc (substr($from,0,1)) if ($is_pawn and $is_capture);

        my ($ambiguous, $rank_ambiguous, $file_ambiguous) = (0, 0, 0);
        foreach my $origin (@$tpmove) {
            if ($origin != $from_index) {
                $ambiguous = 1;
                $file_ambiguous |= (($origin & 0x07) == ($from_index & 0x07));
                $rank_ambiguous |= (($origin & 0x70) == ($from_index & 0x70));
            }
        }
        # The capture by a pawn has already been dis-abmigousized above
        if ($ambiguous and !($is_pawn and $is_capture)) {
            if ($rank_ambiguous and $file_ambiguous) {
                $san .= lc (substr($from,0,2));
            } else {
                if ($file_ambiguous) {
                    $san .= lc (substr($from,1,1));
                } else {
                    $san .= lc (substr($from,0,1));
                }
            }
        }
        if ($is_capture) {
            $san .= 'x';
        }
        $san .= lc $to;
        $san .= "=$promote"
          if $promote;
    }

    if ($status->{mate}) {
        $san .= '#';
    } elsif ($status->{check}) {
        $san .= '+';
    }

    # _debug("$orig_move \t\t\t $san");

    return {
        from       => lc $from,
        from_index => $from_index,
        from_row   => $from_row,
        from_col   => $from_col,
        to         => lc $to,
        to_index   => $to_index,
        to_row     => $to_row,
        to_col     => $to_col,
        piece      => $piece,
        promote    => $promote,
        san        => $san,
    };
}

sub _move_piece {
    my ($self, $from, $to, $promote) = @_;
    my $p = $self->set_piece_at_index($from, 0);
    if ($p & 0x04) {            # is king?
        if ($p & 0x80) {
            $self->{castle} = $self->{castle} | CASTLE_W_OOO ^ CASTLE_W_OOO;
            $self->{castle} = $self->{castle} | CASTLE_W_OO ^ CASTLE_W_OO;
        } else {
            $self->{castle} = $self->{castle} | CASTLE_B_OOO ^ CASTLE_B_OOO;
            $self->{castle} = $self->{castle} | CASTLE_B_OO ^ CASTLE_B_OO;
        }
    }
    if ($from == 0x00 || $to == 0x00) {
        $self->{castle} = $self->{castle} | CASTLE_W_OOO ^ CASTLE_W_OOO;
    }
    if ($from == 0x70 || $to == 0x70) {
        $self->{castle} = $self->{castle} | CASTLE_B_OOO ^ CASTLE_B_OOO;
    }
    if ($from == 0x07 || $to == 0x07) {
        $self->{castle} = $self->{castle} | CASTLE_W_OO ^ CASTLE_W_OO;
    }
    if ($from == 0x77 || $to == 0x77) {
        $self->{castle} = $self->{castle} | CASTLE_B_OO ^ CASTLE_B_OO;
    }
    $self->set_piece_at_index($to, $promote || $p);
}

=head2 compute_valid_moves()

Rebuild the valid moves hashes that are returned by $self->status()
for the current position.  You need to call this function when you
manually interfere with the position, such as when you use
set_piece_at() or set_piece_at_index() in order to setup the position.

=cut

sub compute_valid_moves {
    my ($self) = @_;

    my @pieces;
    my $king;
    my $op_color = $self->{to_move} ^ 0x80;

    for my $row (0..7) {
        for my $col (0..7) {
            my $i = get_index_from_row_col($row, $col);
            my $p = $self->get_piece_at_index($i);
            if ($p) {
                if (($p & 0x80) == $self->{to_move}) {
                    push @pieces, {
                        from => $i,
                        piece => $p,
                    };
                    if ($p & 0x04) {
                        # remember king position
                        $king = $i;
                    }
                }
            }
        }
    }

    if (defined $king) {
        $self->{in_check} = $self->is_attacked($king, $op_color);
    }

    my @all_moves;
    my %hash_moves;
    my %type_moves;

    foreach my $p (@pieces) {
        my $from = $p->{from};
        my $moves = $self->_get_allowed_moves($from);
        my $piece = $p->{piece};
        my @valid_moves;
        if (defined $king) {
            my $is_king = $from == $king;
            my $try_move = {
                from  => $from,
                piece => $piece,
            };
            @valid_moves = grep {
                $try_move->{to} = $_,
                  !$self->is_attacked($is_king ? $_ : $king, $op_color, $try_move);
            } @$moves;
        } else {
            @valid_moves = @$moves;
        }
        # _debug("Found moves for $piece");
        $p->{to} = \@valid_moves;
        push @all_moves, (map {
            my $to = $_ & 0xFF;
            $hash_moves{"$from-$to"} = 1;
            my $a = ($type_moves{$to} ||= {});
            my $b = ($a->{$piece} ||= []);
            push @$b, $from;
            { from => $from, to => $to, piece => $piece }
        } @valid_moves);
    }

    # _debug(Data::Dumper::Dumper($self));

    return $self->{status} = {
        moves      => \@all_moves,
        pieces     => \@pieces,
        hash_moves => \%hash_moves,
        type_moves => \%type_moves,
        check      => $self->{in_check},
        mate       => $self->{in_check} && !@all_moves,
        stalemate  => !$self->{in_check} && !@all_moves,
    };
}

=head2 is_attacked($index, $color, $try_move)

Checks if the field specified by $index is under attack by a piece of
the specified $color.

$try_move is optional; if passed it must be a hash of the following
form:

  { from  => $from_index,
    to    => $to_index,
    piece => $piece }

In this case, the method will take the given move into account.  This
is useful in order to test moves in compute_valid_moves(), as we need
to filter out moves that leave the king in check.

=cut

sub is_attacked {
    my ($self, $i, $opponent_color, $try_move) = @_;

    # _debug("Checking if " . get_field_id($i) . " is attacked");

    $opponent_color = $self->{to_move} ^ 0x80
      unless defined $opponent_color;

    my $test = sub {
        my ($type, $i) = @_;
        return 1
          if $i & 0x88;
        my $p;
        my $pos = $self->{pos};
        if ($try_move) {
            my ($from, $to, $piece) = ($try_move->{from}, $try_move->{to}, $try_move->{piece});
            if ($i == $from) {
                $p = 0;
            } elsif ($i == $to) {
                $p = $piece;
            } elsif ($self->{enpa} # en-passant field defined
                       && ($piece & 0x01) # pawn
                         && $to == $self->{enpa} # trying en-passant move
                           && ($i == (($from & 0x70) | ($to & 0x07))) # captured piece field inquired
                       ) {
                # emulate en-passant (clear captured piece field)
                $p = 0;
            } else {
                $p = $pos->[$i];
            }
        } else {
            $p = $pos->[$i];
        }
        if ($p && ($p & $type) && ($p & 0x80) == $opponent_color) {
            die 1;
        }
        return $p;
    };

    eval {

        # check pawns
        # _debug("... checking opponent pawns");
        if ($opponent_color) {
            $test->(0x01, $i - 15);
            $test->(0x01, $i - 17);
        } else {
            $test->(0x01, $i + 15);
            $test->(0x01, $i + 17);
        }

        # check knights
        # _debug("... checking opponent knights");
        for my $step (@MOVES_N) {
            $test->(0x02, $i + $step);
        }

        # check bishops or queens
        # _debug("... checking opponent bishops");
        for my $step (@MOVES_B) {
            my $j = $i;
            do { $j += $step }
              while (!$test->(0x28, $j));
        }

        # check rooks or queens
        # _debug("... checking opponent rooks or queens");
        for my $step (@MOVES_R) {
            my $j = $i;
            do { $j += $step }
              while (!$test->(0x30, $j));
        }

        # _debug("... checking opponent king");
        for my $step (@MOVES_K) {
            $test->(0x04, $i + $step);
        }

    };

    return $@ ? 1 : 0;
}

sub _get_allowed_moves {
    my ($self, $index) = @_;
    my $p = uc ID_TO_PIECE->[$self->get_piece_at_index($index) & 0x3F];
    my $method = "_get_allowed_${p}_moves";
    return $self->$method($index);
}

sub _add_if_valid {
    my ($self, $moves, $from, $to) = @_;

    return undef
      if $to & 0x88;

    my $what = $self->get_piece_at_index($to);

    my $p = $self->get_piece_at_index($from);
    my $color = $p & 0x80;

    if (($p & 0x04) && $self->is_attacked($to)) {
        return undef;
    }

    if (!$what) {
        if ($p & 0x01) {
            if (abs(($from & 0x07) - ($to & 0x07)) == 1) {
                if ($self->{enpa} && $to == $self->{enpa}) { # check en passant
                    push @$moves, $to;
                    return $to;
                }
                return undef; # must take to move this way
            }
        }
        push @$moves, $to;
        return $to;
    }

    if (($what & 0x80) != $color) {
        if (($p & 0x01) && (($from & 0x07) == ($to & 0x07))) {
            return undef;   # pawns can't take this way
        }
        # _debug("Adding capture: $p " . get_field_id($from) . "-" . get_field_id($to));
        push @$moves, $to;
        return $to;
    }

    return undef;
}

sub _get_allowed_P_moves {
    my ($self, $index, $moves) = @_;
    $moves ||= [];
    my $color = $self->get_piece_at_index($index) & 0x80;
    my $step = $color ? 16 : -16;
    my $not_moved = ($index & 0xF0) == ($color ? 0x10 : 0x60);
    if (defined $self->_add_if_valid($moves, $index, $index + $step) && $not_moved) {
        $self->_add_if_valid($moves, $index, $index + 2 * $step);
    }
    $self->_add_if_valid($moves, $index, $index + ($color ? 17 : -15));
    $self->_add_if_valid($moves, $index, $index + ($color ? 15 : -17));
    # print Data::Dumper::Dumper($moves);
    return $moves;
}

sub _get_allowed_N_moves {
    my ($self, $index, $moves) = @_;
    $moves ||= [];
    for my $step (@MOVES_N) {
        $self->_add_if_valid($moves, $index, $index + $step);
    }
    return $moves;
}

sub _get_allowed_R_moves {
    my ($self, $index, $moves) = @_;
    $moves ||= [];
    for my $step (@MOVES_R) {
        my $i = $index;
        while (defined $self->_add_if_valid($moves, $index, $i += $step)) {
            last if $self->get_piece_at_index($i);
        }
    }
    return $moves;
}

sub _get_allowed_B_moves {
    my ($self, $index, $moves) = @_;
    $moves ||= [];
    for my $step (@MOVES_B) {
        my $i = $index;
        while (defined $self->_add_if_valid($moves, $index, $i += $step)) {
            last if $self->get_piece_at_index($i);
        }
    }
    return $moves;
}

sub _get_allowed_Q_moves {
    my ($self, $index, $moves) = @_;
    $moves ||= [];
    $self->_get_allowed_R_moves($index, $moves);
    $self->_get_allowed_B_moves($index, $moves);
    return $moves;
}

sub _get_allowed_K_moves {
    my ($self, $index, $moves) = @_;
    $moves ||= [];
    my $color = $self->get_piece_at_index($index) & 0x80;

    for my $step (@MOVES_K) {
        if (defined $self->_add_if_valid($moves, $index, $index + $step)) {
            if ($step == 1 &&
                  !$self->{in_check} && $self->can_castle($color, 0) &&
                    !$self->get_piece_at_index($index + 1) &&
                      !$self->get_piece_at_index($index + 2)) {
                # kingside castling possible
                $self->_add_if_valid($moves, $index, $index + 2);
            } elsif ($step == -1 &&
                       !$self->{in_check} && $self->can_castle($color, 1) &&
                         !$self->get_piece_at_index($index - 1) &&
                           !$self->get_piece_at_index($index - 2) &&
                             !$self->get_piece_at_index($index - 3)) {
                # queenside castling possible
                $self->_add_if_valid($moves, $index, $index - 2);
            }
        }
    }

    return $moves;
}

=head2 can_castle($color, $ooo)

Return true if the given $color can castle kingside (if $ooo is false)
or queenside (if you pass $ooo true).

=cut

sub can_castle {
    my ($self, $color, $ooo) = @_;
    if ($color) {
        return $self->{castle} & ($ooo ? CASTLE_W_OOO : CASTLE_W_OO);
    } else {
        return $self->{castle} & ($ooo ? CASTLE_B_OOO : CASTLE_B_OO);
    }
}

=head2 has_castled($color)

Returns true (non-zero) if the specified color has castled, or false
(zero) otherwise.  If the answer to this question is unknown (which
can happen if we initialize the Chess::Rep object from an arbitrary
position) then it returns undef.

=cut

sub has_castled {
    my ($self, $color) = @_;
    if (defined $self->{has_castled}) {
        if ($color) {
            return $self->{has_castled} & (CASTLE_W_OO | CASTLE_W_OOO);
        } else {
            return $self->{has_castled} & (CASTLE_B_OO | CASTLE_B_OOO);
        }
    }
    return undef;
}

=head2 piece_color($piece)

You can call this both as an object method, or standalone.  It returns
the color of the specified $piece, which must be in the established
encoding.  Example:

  Chess::Rep::piece_color(0x81) --> 0x80 (white (pawn))
  Chess::Rep::piece_color(0x04) --> 0 (black (king))
  $self->piece_color('e2') --> 0x80 (white (standard start position))

If you call it as a method, the argument B<must> be a field specifier
(either full index or field ID) rather than a piece.

=cut

sub piece_color {
    my $p = shift;
    $p = $p->get_piece_at(shift)
      if ref $p;
    return $p & 0x80;
}

=head2 get_index($row, $col)

Static function.  Computes the full index for the given $row and $col
(which must be in 0..7).

Additionally, you can pass a field ID instead (and omit $col).

Examples:

  Chess::Rep::get_index(2, 4) --> 45
  Chess::Rep::get_index('e3') --> 45

=cut

sub get_index {
    my ($row, $col) = @_;
    ($row, $col) = get_row_col($row)
      unless defined $col;
    return ($row << 4) | $col;
}

=head2 get_index_from_row_col($row, $col)

This does the same as the above function, but it won't support a field
ID (i.e. 'e3').  You have to pass it a row and col (which are 0..7)
and it simply returns ($row << 4) | $col.  It's faster than the above
when you don't really need support for field IDs.

=cut

sub get_index_from_row_col {
    my ($row, $col) = @_;
    return ($row << 4) | $col;
}

=head2 get_field_id($index)

Returns the ID of the field specified by the given index.

  Chess::Rep::get_field_id(45) --> 'e3'
  Chess::Rep::get_field_id('f4') --> 'f4' (quite pointless)

=cut

sub get_field_id {
    my ($row, $col) = @_;
    ($row, $col) = get_row_col($row)
      unless defined $col;
    return pack('CC', $col + 65, $row + 49);
}

=head2 get_row_col($where)

Returns a list of two values -- the $row and $col of the specified
field.  They are in 0..7.

  Chess::Rep::get_row_col('e3') --> (2, 4)
  Chess::Rep::get_row_col(45) --> (2, 4)

=cut

sub get_row_col {
    my ($id) = @_;
    if ($id =~ /^[a-h]/oi) {
        my ($col, $row) = unpack('CC', uc $id);
        return (
            $row - 49,
            $col - 65,
        );
    } else {
        return (
            ($id & 0x70) >> 4,
            $id & 0x07,
        );
    }
}

=head2 dump_pos()

Object method.  Returns a string with the current position (in a form
more readable than standard FEN).  It's only useful for debugging.

=cut

sub dump_pos {
    my ($self) = @_;
    my $fen = $self->get_fen;
    my @a = split(/ /, $fen);
    $fen = shift @a;
    $fen =~ s/([1-8])/' 'x$1/ge;
    $fen =~ s{([^/])}{|$1}g;
    $fen =~ s/\//|\n|-+-+-+-+-+-+-+-|\n/g;
    $fen .= '|';
    return $fen;
}

sub _debug {
    print STDERR join(' / ', @_), "\n";
}

=head1 LINKS

 [1] SAN ("Standard Algebraic Notation") is the most popular notation
     for chess moves.

     http://en.wikipedia.org/wiki/Algebraic_chess_notation

 [2] Ideas for representing a chess board in memory.

     http://www.cis.uab.edu/hyatt/boardrep.html

=head1 AUTHOR

Mihai Bazon, <mihai.bazon@gmail.com>
    http://www.dynarchlib.com/
    http://www.bazon.net/mishoo/

This module was developed for Dynarch Chess --
L<http://chess.dynarch.com/en.html>

=head1 COPYRIGHT

Copyright (c) Mihai Bazon 2008.  All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

1;
