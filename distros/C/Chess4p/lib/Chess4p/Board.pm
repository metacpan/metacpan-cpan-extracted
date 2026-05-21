package Chess4p::Board;

use v5.36;

use Carp;
use List::Util qw( max );

use Scalar::Util qw(reftype refaddr);

use Chess4p;

use Chess4p::Common qw(:all);

use overload ('""', => 'ascii');


my $BB_EMPTY = 0;

my $BB_ALL_64;
my $BB_FILE_A;
my $BB_FILE_B;
my $BB_FILE_C;
my $BB_FILE_D;
my $BB_FILE_E;
my $BB_FILE_F;
my $BB_FILE_G;
my $BB_FILE_H;
{
    no warnings "portable";
    $BB_ALL_64 = 0xffff_ffff_ffff_ffff;
    $BB_FILE_A = 0x0101_0101_0101_0101 << FILE_A;
    $BB_FILE_B = 0x0101_0101_0101_0101 << FILE_B;
    $BB_FILE_C = 0x0101_0101_0101_0101 << FILE_C;
    $BB_FILE_D = 0x0101_0101_0101_0101 << FILE_D;
    $BB_FILE_E = 0x0101_0101_0101_0101 << FILE_E;    
    $BB_FILE_F = 0x0101_0101_0101_0101 << FILE_F;
    $BB_FILE_G = 0x0101_0101_0101_0101 << FILE_G;
    $BB_FILE_H = 0x0101_0101_0101_0101 << FILE_H;    
}
my @BB_FILES = ($BB_FILE_A, $BB_FILE_B, $BB_FILE_C, $BB_FILE_D, $BB_FILE_E, $BB_FILE_F, $BB_FILE_G, $BB_FILE_H);

my $BB_RANK_1 = 0xff << (8 * RANK_1);
my $BB_RANK_2 = 0xff << (8 * RANK_2);
my $BB_RANK_3 = 0xff << (8 * RANK_3);
my $BB_RANK_4 = 0xff << (8 * RANK_4);
my $BB_RANK_5 = 0xff << (8 * RANK_5);
my $BB_RANK_6 = 0xff << (8 * RANK_6);
my $BB_RANK_7 = 0xff << (8 * RANK_7);
my $BB_RANK_8 = 0xff << (8 * RANK_8);
my @BB_RANKS = ($BB_RANK_1, $BB_RANK_2, $BB_RANK_3, $BB_RANK_4, $BB_RANK_5, $BB_RANK_6, $BB_RANK_7, $BB_RANK_8);

my $BB_BACKRANKS = $BB_RANK_1 | $BB_RANK_8;

# Each has a single 0-bit at position 0..63, corresponding to  a1-h1, a2-h2, ..., a8-h8
my @BB_0_PER_SQUARE = map { ~(1 << $_) } 0..63;

# Each has a single 1-bit at position 0..63, corresponding to  a1-h1, a2-h2, ..., a8-h8
my @BB_1_PER_SQUARE = map { 1 << $_ } 0..63;

my $BB_E1 = $BB_1_PER_SQUARE[E1];
my $BB_E8 = $BB_1_PER_SQUARE[E8];


sub _square_mirror { ## no critic (Subroutines::RequireArgUnpacking)
    # mirrors the square vertically
    $_[0] ^ 0x38;
}

my @SQUARES_180 = map { _square_mirror($_) } 0..63;

my @BB_KNIGHT_ATTACKS;
for my $sqr (A1 .. H8) {
    # tabulate knight attacks from each square
    $BB_KNIGHT_ATTACKS[$sqr] = _step_attacks($sqr, [17, 15, 10, 6, -17, -15, -10, -6]);
}

my @BB_KING_ATTACKS;
for my $sqr (A1 .. H8) {
    # tabulate king attacks from each square
    $BB_KING_ATTACKS[$sqr] = _step_attacks($sqr, [9, 8, 7, 1, -9, -8, -7, -1]);
}

my @BB_PAWN_ATTACKS_w;
my @BB_PAWN_ATTACKS_b;
for my $sqr (A1 .. H8) {
    # tabulate pawn attacks from each square for each side
    # note that edge squares need to be tabulated too, even
    # when there are no attacks from there, to avoid accessing
    # undefined values in e.g. castling move gen.
    $BB_PAWN_ATTACKS_w[$sqr] = _step_attacks($sqr, [7, 9]);
    $BB_PAWN_ATTACKS_b[$sqr] = _step_attacks($sqr, [-7, -9]);    
}


### Free functions

sub _opponent_piece { ## no critic (Subroutines::RequireArgUnpacking)
    # argument must be a piece type not EMPTY or undef
    return BK if $_[0] == WK;
    return BQ if $_[0] == WQ;
    return BR if $_[0] == WR;
    return BB if $_[0] == WB;
    return BN if $_[0] == WN;
    return BP if $_[0] == WP;

    return WK if $_[0] == BK;
    return WQ if $_[0] == BQ;
    return WR if $_[0] == BR;
    return WB if $_[0] == BB;
    return WN if $_[0] == BN;
    return WP if $_[0] == BP;
}

sub _make_bb { ## no critic (Subroutines::RequireArgUnpacking)
    # make a bitboard from a list of squares
    # useful for testing
    my $result = 0;
    for (@_) {
        $result |= $BB_1_PER_SQUARE[$_];
    }
    $result;
}

sub _print_bb { ## no critic (Subroutines::RequireArgUnpacking)
    # bitboard as a string
    # useful for debugging
    my $bb = $_[0];
    my $result;
    for my $sqr (@SQUARES_180) {
        my $mask = $BB_1_PER_SQUARE[$sqr];
        if ($bb & $mask) {
            $result .= "1";
        }
        else {
            $result .= ".";
        }
        unless ($mask & $BB_FILE_H) {
            $result .= " ";
        }
        else {
            $result .= "\n" unless $sqr == H1;
        }
    }
    $result;
}

sub _flip_vertical { ## no critic (Subroutines::RequireArgUnpacking)
    # https://www.chessprogramming.org/Flipping_Mirroring_and_Rotating#FlipVertically
    my $bb = $_[0];
    no warnings "portable";
    $bb = (($bb >> 8) & 0x00ff_00ff_00ff_00ff) | (($bb & 0x00ff_00ff_00ff_00ff) << 8);
    $bb = (($bb >> 16) & 0x0000_ffff_0000_ffff) | (($bb & 0x0000_ffff_0000_ffff) << 16);
    $bb = ($bb >> 32) | (($bb & 0x0000_0000_ffff_ffff) << 32);
    return $bb
}
  
sub _carry_rippler_iter {
    # iterate over subsets of a bitboard
    my ($mask) = @_;
    my $subset = $BB_EMPTY;
    my $done   = 0;

    return sub {
        return undef if $done;
        my $out = $subset;
        $subset = ($subset - $mask) & $mask;  # carry-rippler step
        $done = 1 if $subset == 0;            # stop after we've generated all subsets
        return $out;
    };
}

sub _step_attacks { ## no critic (Subroutines::RequireArgUnpacking)
    my $sqr = $_[0];
    my $deltas = $_[1]; # ref
    my $occupied = $_[2];
    _sliding_attacks($sqr, $deltas, $BB_ALL_64);
}

sub _sliding_attacks { ## no critic (Subroutines::RequireArgUnpacking)
    my $sqr = $_[0];
    my $deltas = $_[1]; # ref
    my $occupied = $_[2];
    my $result = $BB_EMPTY;

    for my $delta (@$deltas) {
        my $s = $sqr;
        while (1) {
            $s += $delta;
            last unless ($s >= 0 && $s < 64);
            last if (_square_distance($s, $s - $delta) > 2);
            $result = $result | $BB_1_PER_SQUARE[$s];
            last if $occupied & $BB_1_PER_SQUARE[$s];
        }
    }

    $result;
}

sub _square { ## no critic (Subroutines::RequireArgUnpacking)
    # Get square number by file and rank index.
    my $file_index = $_[0];
    my $rank_index = $_[1];
    $rank_index * 8 + $file_index;
}

sub _square_file { ## no critic (Subroutines::RequireArgUnpacking)
    my $sqr = $_[0];
    $sqr & 7;
}

sub _square_rank { ## no critic (Subroutines::RequireArgUnpacking)
    my $sqr = $_[0];
    $sqr >> 3
}

sub _square_distance { ## no critic (Subroutines::RequireArgUnpacking)
    # number of king steps from a to b
    my $sqr_a = $_[0];
    my $sqr_b = $_[1];
    max(abs(_square_file($sqr_a) - _square_file($sqr_b)), abs(_square_rank($sqr_a) - _square_rank($sqr_b)))
}

sub _shift_down { ## no critic (Subroutines::RequireArgUnpacking)
    my $bb = $_[0];
    $bb >> 8;
}

sub _shift_up { ## no critic (Subroutines::RequireArgUnpacking)
    my $bb = $_[0];
    ($bb << 8) & $BB_ALL_64;
}

sub _edges { ## no critic (Subroutines::RequireArgUnpacking)
    my $sqr = $_[0];
    return ((($BB_RANK_1 | $BB_RANK_8) & ~$BB_RANKS[_square_rank($sqr) ]) |
            (($BB_FILE_A | $BB_FILE_H) & ~$BB_FILES[_square_file($sqr)]));
}

sub _attack_table {
    # for pre-computed attack tables
    my ($deltas) = @_;
    my @mask_table;
    my @attack_table;

    for my $square (A1..H8) {
        my %attacks;
        my $mask = _sliding_attacks($square, $deltas, 0) & ~_edges($square);
        my $next = _carry_rippler_iter($mask);
        while (defined(my $subset = $next->())) {
            $attacks{$subset} = _sliding_attacks($square, $deltas, $subset);
        }
        push @attack_table, \%attacks;
        push @mask_table,   $mask;
    }

    return (\@mask_table, \@attack_table);
}


my ($BB_DIAG_MASKS, $BB_DIAG_ATTACKS) = _attack_table([-9, -7, 7, 9]);
my ($BB_FILE_MASKS, $BB_FILE_ATTACKS) = _attack_table([-8, 8]);
my ($BB_RANK_MASKS, $BB_RANK_ATTACKS) = _attack_table([-1, 1]);


sub _rays {
    my @rays;
    for (my $a = 0; $a < @BB_0_PER_SQUARE; $a++) {
        my $bb_a = $BB_1_PER_SQUARE[$a];
        my @rays_row;
        for (my $b = 0; $b < @BB_0_PER_SQUARE; $b++) {
            my $bb_b = $BB_1_PER_SQUARE[$b];
            if ($BB_DIAG_ATTACKS->[$a]{0} & $bb_b) {
                push @rays_row, $BB_DIAG_ATTACKS->[$a]{0} & $BB_DIAG_ATTACKS->[$b]{0} | $bb_a | $bb_b;
            }
            elsif ($BB_RANK_ATTACKS->[$a]{0} & $bb_b) {
                push @rays_row, $BB_RANK_ATTACKS->[$a]{0} | $bb_a;
            }
            elsif ($BB_FILE_ATTACKS->[$a]{0} & $bb_b) {
                push @rays_row, $BB_FILE_ATTACKS->[$a]{0} | $bb_a;
            }
            else {
                push @rays_row, $BB_EMPTY;
            }
        }
        push @rays, \@rays_row;
    }
    \@rays;
}

my $BB_RAYS = _rays();

sub _ray {
    my ($a, $b) = @_;
    my $aref = $BB_RAYS->[$a];
    $aref->[$b];
}

sub _between {
    my ($a, $b) = @_;
    my $aref = $BB_RAYS->[$a];
    my $bb = $aref->[$b] & (($BB_ALL_64 << $a) ^ ($BB_ALL_64 << $b));
    $bb & ($bb - 1);
}

sub _msb {
    my ($x) = @_;
    return -1 if $x == 0;
    my $pos = 0;
    ## no critic (ValuesAndExpressions::ProhibitCommaSeparatedStatements)
    $pos += 32, $x >>= 32 if $x >> 32; 
    $pos += 16, $x >>= 16 if $x >> 16;
    $pos +=  8, $x >>=  8 if $x >>  8;
    $pos +=  4, $x >>=  4 if $x >>  4;
    $pos +=  2, $x >>=  2 if $x >>  2;
    $pos +=  1            if $x >>  1;
    return $pos;
}

sub _lsb {
    my ($x) = @_;
    _msb($x & -$x);
}


# FEN characters
my @fen_chars = qw(. P N B R Q K p n b r q k);

# FEN char -> Piece
my %fen_chars_to_piece_code = (
                               r => BR, n => BN, b => BB, q => BQ, k => BK, p => BP,
                               P => WP, R => WR, N => WN, B => WB, Q => WQ, K => WK,
                              );


### Private instance methods

sub _clean_castling_rights {
    # returns bitboard with the corner squares set if the
    # rook on that square can potentially castle.
    # the given castling rights may be reduced, depending on the position
    my $pos = shift;
    my $white_castling = $pos->{castling_rights} & $pos->{bb}{WR()};
    my $black_castling = $pos->{castling_rights} & $pos->{bb}{BR()};

    unless ($pos->{bb}{WK()} & $BB_1_PER_SQUARE[E1()]) {
        $white_castling = 0;
    }
    unless ($pos->{bb}{BK()} & $BB_1_PER_SQUARE[E8()]) {
        $black_castling = 0;
    }

    return $white_castling | $black_castling;
}


sub _valid_ep_square {
    # return e.p. square if valid, else undef
    my $pos = shift;
    return undef unless $pos->{ep_square};

    my $ep_rank;
    my $pawn_mask; # a pawn - that made the last move - must be at this square
    my $seventh_rank_mask; # the square that must have been left empty by the last move
    if ($pos->{to_move} eq 'w') {
        $ep_rank = RANK_6;
        $pawn_mask       = _shift_down($BB_1_PER_SQUARE[$pos->{ep_square}]);
        $seventh_rank_mask = _shift_up($BB_1_PER_SQUARE[$pos->{ep_square}]);
    }
    else {
        $ep_rank = RANK_3;
        $pawn_mask           = _shift_up($BB_1_PER_SQUARE[$pos->{ep_square}]);
        $seventh_rank_mask = _shift_down($BB_1_PER_SQUARE[$pos->{ep_square}]);        
    }
    # e.p. square must be on 3rd / 6th rank
    if (_square_rank($pos->{ep_square}) != $ep_rank) {
        return undef;
    }
    # require a pawn that moved past the e.p square
    if ($pos->{to_move} eq 'w' && !($pos->{bb}{BP()} & $pawn_mask)) {
        return undef;
    }
    if ($pos->{to_move} eq 'b' && !($pos->{bb}{WP()} & $pawn_mask)) {
        return undef;
    }
    # e.p. square must be empty
    if ($pos->{bb}{all} & $BB_1_PER_SQUARE[$pos->{ep_square}]) {
        return undef;
    }
    # square that was just emptied by the last move
    if ($pos->{bb}{all} & $seventh_rank_mask) {
        return undef;
    }
    # OK
    return $pos->{ep_square};
}

# The de Bruijn BitScan in Benchmark against the naive implementation:
#       Rate  Old  New
# Old 78.5/s   -- -46%
# New  145/s  84%   --

my @INDEX32 = (
     0,  1, 28,  2, 29, 14, 24,  3,
    30, 22, 20, 15, 25, 17,  4,  8,
    31, 27, 13, 23, 21, 19, 16,  7,
    26, 12, 18,  6, 11,  5, 10,  9,
);

my $DEBRUIJN32 = 0x077CB531;
my $MASK32     = 0xFFFF_FFFF;

sub _pop_lsb_index {
    my ($bbref) = @_;

    my ($lo, $hi) = unpack('L<L<', pack('Q<', $$bbref));

    return -1 if $lo == 0 && $hi == 0;

    if ($lo != 0) {
        my $lsb = $lo & -$lo;
        $lo ^= $lsb;

        $$bbref = unpack('Q<', pack('L<L<', $lo, $hi));

        return $INDEX32[
            (($lsb * $DEBRUIJN32) & $MASK32) >> 27
        ];
    }
    else {
        my $lsb = $hi & -$hi;
        $hi ^= $lsb;

        $$bbref = unpack('Q<', pack('L<L<', $lo, $hi));

        return 32 + $INDEX32[
            (($lsb * $DEBRUIJN32) & $MASK32) >> 27
        ];
    }
}

# use for looping over set bits = squares
sub _pop_lsb_index_old { ## no critic (Subroutines::RequireArgUnpacking)
    # The argument is a reference to a bitboard scalar
    return -1 if ${$_[0]} == 0;

    # isolate least significant 1 bit
    my $lsb = ${$_[0]} & (-${$_[0]});

    # remove it
    ${$_[0]} = ${$_[0]} ^ $lsb;

    # position of the lsb
    # simplest portable approach: count trailing zeros with a loop
    my $i = 0;
    while (($lsb >> $i) != 1) {
        $i++;
    }
    return $i;
}

sub _bb_count_1s {
    my ($pos, $pcs) = @_;

    my $bbref = $pos->{bb}{$pcs};
    my $bb = $bbref;
    return 0 if $bb == 0;

    # make a copy
    my $lsb = $bb;

    # count 1's
    my $count = 0;
    if ($lsb % 2 != 0) {
        $count++;
    }
    while (($lsb = ($lsb >> 1)) > 0) {
        if ($lsb % 2 != 0) {
            $count++;
        }
    }
    return $count;
}

sub _occupied {
    my ($pos, $side) = @_;
    return $pos->{bb}{$side};
}

sub _opponent { ## no critic (Subroutines::RequireArgUnpacking)
    return $_[0]->{to_move} eq 'w' ? 'b' : 'w';
}

sub _get_attackers {
    # get the attackers from side on square
    my ($pos, $side, $square, $occupied) = @_;

    my $attackers = $BB_KING_ATTACKS[$square] & ($side eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()});
    $attackers |= $BB_KNIGHT_ATTACKS[$square] & ($side eq 'w' ? $pos->{bb}{WN()} : $pos->{bb}{BN()});
    $attackers |= $BB_PAWN_ATTACKS_b[$square] & $pos->{bb}{WP()} if $side eq 'w';
    $attackers |= $BB_PAWN_ATTACKS_w[$square] & $pos->{bb}{BP()} if $side eq 'b';

    $occupied //= $pos->{bb}{all};
    
    my $rank_pieces = $BB_RANK_MASKS->[$square] & $occupied;
    my $file_pieces = $BB_FILE_MASKS->[$square] & $occupied;
    my $diag_pieces = $BB_DIAG_MASKS->[$square] & $occupied;

    my $queens_and_rooks   =  ($side eq 'w' ? $pos->{bb}{WR()} | $pos->{bb}{WQ()} : $pos->{bb}{BR()} | $pos->{bb}{BQ()});
    my $queens_and_bishops =  ($side eq 'w' ? $pos->{bb}{WB()} | $pos->{bb}{WQ()} : $pos->{bb}{BB()} | $pos->{bb}{BQ()});
    
    $attackers |= $BB_RANK_ATTACKS->[$square]{$rank_pieces} & $queens_and_rooks;
    $attackers |= $BB_FILE_ATTACKS->[$square]{$file_pieces} & $queens_and_rooks;
    $attackers |= $BB_DIAG_ATTACKS->[$square]{$diag_pieces} & $queens_and_bishops;        
    
    return $attackers;
}

sub _attacked_for_king {
    # return true iff any of the squares in bb are attacked by the side NOT to move
    my ($pos, $bb, $occupied) = @_;
    my $_bb = $bb;
    while ($_bb) {
        my $sqr = _pop_lsb_index(\$_bb);
        if ($pos->_get_attackers($pos->_opponent(), $sqr, $occupied)) {
            return 1;
        }
    }
    return 0;
}

sub _generate_castling_moves {
    my $pos = shift;
    my $result = shift; # array ref to which moves will be added
    my $bb_from_filter = shift;
    my $bb_to_filter = shift;

    my $side = $pos->{to_move};
    my $bb_backrank = ($side eq 'w' ? $BB_RANK_1 : $BB_RANK_8);
    my $king = ($side eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()});
    $king &= $bb_from_filter;

    return unless $king;
    
    my $bb_c = $BB_FILE_C & $bb_backrank;
    my $bb_d = $BB_FILE_D & $bb_backrank;
    my $bb_f = $BB_FILE_F & $bb_backrank;
    my $bb_g = $BB_FILE_G & $bb_backrank;

    my $bb_candidates = $pos->_clean_castling_rights() & $bb_backrank & $bb_to_filter;
    while ($bb_candidates) {
        my $candi = _pop_lsb_index(\$bb_candidates);
        my $rook = $BB_1_PER_SQUARE[$candi];
        my $q_side = $rook < $king;
        my $king_to = ($q_side ? $bb_c : $bb_g);
        my $rook_to = ($q_side ? $bb_d : $bb_f);
        my $king_path = _between(_msb($king), _msb($king_to));
        my $rook_path = _between($candi, _msb($rook_to));

        unless ( ($king ^ $rook ^ $pos->{bb}{all}) & ($king_path | $rook_path | $king_to | $rook_to)
                 || ($pos->_attacked_for_king($king_path | $king, $king ^ $pos->{bb}{all}))
                 || ($pos->_attacked_for_king($king_to, $king ^ $rook ^ $rook_to ^ $pos->{bb}{all})) ) {
            my $from = _msb($king);
            if ($from == E1 && $pos->{bb}{WK()} & $BB_E1) {
                push (@$result, Chess4p::Move->new(E1, G1)) if $candi == H1;
                push (@$result, Chess4p::Move->new(E1, C1)) if $candi == A1;
            }
            elsif ($from == E8 && $pos->{bb}{BK()} & $BB_E8) {
                push (@$result, Chess4p::Move->new(E8, G8)) if $candi == H8;
                push (@$result, Chess4p::Move->new(E8, C8)) if $candi == A8;
            }
        }
    }
}

sub _ep_skewered {
    # Handle the special case where the king would be in check if the
    # pawn and its capturer both disappear from the rank.
    # E.g. Kd5, Pe5 vs. pf5, rh5.
    # capturer = from square of the e.p.-capturing pawn.
    # Vertical skewers of the captured pawn are not possible.
    # Pins on the capturer are not handled elsewhere.
    my ($pos, $king, $capturer) = @_;
    croak "check for skewered e.p. done without e.p. square" unless $pos->{ep_square};

    my $last_double = $pos->{ep_square} + ($pos->{to_move} eq 'w' ? -8 : 8);
    my $occupancy = $pos->{bb}{all} & $BB_0_PER_SQUARE[$last_double] & $BB_0_PER_SQUARE[$capturer]
                  | $BB_1_PER_SQUARE[$pos->{ep_square}];

    # Horizontal attack on the fifth or fourth rank.
    my $horizontal_attackers;
    if ($pos->{to_move} eq 'w') {
        $horizontal_attackers = $pos->{bb}{BQ()} | $pos->{bb}{BR()};
    }
    else {
        $horizontal_attackers = $pos->{bb}{WQ()} | $pos->{bb}{WR()};
    }
    return 1 if ($BB_RANK_ATTACKS->[$king]{$occupancy & $BB_RANK_MASKS->[$king]} & $horizontal_attackers);

    # Diagonal skewers. These are not actually possible in a real game,
    # because if the latest double pawn move covers a diagonal attack,
    # then the other side would have been in check already.
    my $diagonal_attackers;
    if ($pos->{to_move} eq 'w') {
        $diagonal_attackers = $pos->{bb}{BQ()} | $pos->{bb}{BB()};
    }
    else {
        $diagonal_attackers = $pos->{bb}{WQ()} | $pos->{bb}{WB()};
    }
    return 1 if ($BB_DIAG_ATTACKS->[$king]{$occupancy & $BB_DIAG_MASKS->[$king]} & $diagonal_attackers);

    return 0;
}

sub _is_ep_move {
    my ($pos, $move) = @_;

    return 0 unless $pos->{ep_square};
    
    # Check if the given (pseudo-legal) move is an e.p. capture.
    my $pawns = $pos->{bb}{WP()} | $pos->{bb}{BP()};
    my $diff = abs($move->to() - $move->from());

    return ($pos->{ep_square} == $move->to() &&
            ($pawns & $BB_1_PER_SQUARE[$move->from()]) &&
            ($diff == 7 || $diff == 9) &&
            !($pos->{bb}{all} & $BB_1_PER_SQUARE[$move->to()]));
}

sub _pin_mask {
    my ($pos, $side, $square) = @_;
    
    my $king = $side eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()};
    $king = _msb($king);
    return $BB_ALL_64 if not $king;

    my $square_mask = $BB_1_PER_SQUARE[$square];
    my $rooks_queens   = $side eq 'w' ? $pos->{bb}{BR()} | $pos->{bb}{BQ()} : $pos->{bb}{WR()} | $pos->{bb}{WQ()};
    my $bishops_queens = $side eq 'w' ? $pos->{bb}{BB()} | $pos->{bb}{BQ()} : $pos->{bb}{WB()} | $pos->{bb}{WQ()};    

    for my $pair (
                  [$BB_FILE_ATTACKS, $rooks_queens],
                  [$BB_RANK_ATTACKS, $rooks_queens],
                  [$BB_DIAG_ATTACKS, $bishops_queens]
                 ) {
        my ($attacks, $sliders) = @$pair;
        my $rays = $attacks->[$king]{0};
        if ($rays & $square_mask) {
            my $snipers = $rays & $sliders & ($side eq 'w' ? $pos->{bb}{'b'} : $pos->{bb}{'w'});
            while ($snipers) {
                my $sniper = _pop_lsb_index(\$snipers);
                my $occupied_with_square = $pos->{bb}{all} | $square_mask;
                my $mask = _between($sniper, $king) & $occupied_with_square;
                return _ray($king, $sniper) if $mask == $square_mask;
            }
        }
    }
    
    return $BB_ALL_64;
}

sub _is_safe {
    # is the move safe?
    # it's assumed that if the king was in check before the move, then the move evades that check
    my ($pos, $king, $blockers, $from, $to) = @_;
    if ($from == $king) {
        # castling
        return 1 if _square_distance($from, $to) > 1;
        return 1 if $pos->_get_attackers($pos->_opponent(), $to) == $BB_EMPTY;
        return 0; # $to is attacked by opponent
    }
    elsif ($pos->_is_ep_move(Chess4p::Move->new($from, $to))) {
        my $result = $pos->_pin_mask($pos->{to_move}, $from) & $BB_1_PER_SQUARE[$to];
        return $result && !$pos->_ep_skewered($king, $from);
    }
    else {
        return 1 unless $blockers & $BB_1_PER_SQUARE[$from]; # the piece was not blocking a check -> YES
        return 1 if _ray($from, $to) & $BB_1_PER_SQUARE[$king]; # the blocker keeps blocking -> YES
        return 0; # it's a blocker, and this move would unblock -> NO
    }
}

sub _is_zeroing {
    # Check if given pseudo-legal move is capture or pawn move
    my ($pos, $move) = @_;
    my $touched = $BB_1_PER_SQUARE[$move->from()] ^ $BB_1_PER_SQUARE[$move->to()];
    my $pawns = $pos->{to_move} eq 'w' ? $pos->{bb}{WP()} : $pos->{bb}{BP()};
    $touched & $pawns || $touched & $pos->_occupied($pos->_opponent());
}

sub _debug_state {
    # use for testing
    my $pos = shift;
    my $out = join '',
      map { defined $_ ? $_ : 'undef' }
      $pos->{ep_square},
      $pos->{to_move},
      $pos->{castling_rights},
      $pos->{halfmove_clock},
      $pos->{fullmove_number},
      $pos->{bb}{all},
      $pos->{bb}{'w'},
      $pos->{bb}{'b'};
    for my $pcs (WP .. BK) {
        $out .= $pos->{bb}{$pcs} // 'undef';
    }
    my $sz = 0;
    $sz = @{$pos->{stack}} if $pos->{stack};
    $out .= $sz;
    $sz = 0;
    $sz = @{$pos->{move_stack}} if $pos->{move_stack};
    $out .= $sz;
    $out;
}

sub _transform_bitboards {
    my ($pos, $func) = @_;
    for my $p (WP .. BK) {
        $pos->{bb}{$p} = &$func($pos->{bb}{$p});
    }
    $pos->{bb}{'w'} = &$func($pos->{bb}{'w'});
    $pos->{bb}{'b'} = &$func($pos->{bb}{'b'});    
    $pos->{bb}{all}   = &$func($pos->{bb}{all});
    $pos->{castling_rights} = &$func($pos->{castling_rights});
}

  
### Constructors

sub _new {
    my ($class, $pos) = @_;
    return bless $pos, $class;
}

sub empty {
    my ($class) = @_;

    my $pos = {};
    $pos->{to_move} = 'w';
    $pos->{castling_rights} = $BB_EMPTY;
    $pos->{halfmove_clock}  = 0;
    $pos->{fullmove_number} = 1;
    $pos->{stack} = ();
    $pos->{move_stack} = ();

    for my $pcs (WP .. BK) {
        $pos->{bb}{$pcs} = 0;
    }
    $pos->{bb}{'w'} = 0;
    $pos->{bb}{'b'} = 0;
    $pos->{bb}{all} = 0;
    
    return $class->_new($pos);
}

sub fromFen {
    my ($class, $fen) = @_;

    my $pos = {};

    # init bb's
    for my $p (WP .. BK) {
        $pos->{bb}{$p} = 0;
    }
    $pos->{bb}{'w'} = 0;
    $pos->{bb}{'b'} = 0;
    $pos->{bb}{all} = 0;

    $fen //= 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

    my @parts = split / /, $fen;

    my @rows = split "/", $parts[0];

    if ($#rows != 7) {
        # missing rows - pad with empty squares
        for (0 .. 6 - $#rows) {
            push @rows, "8";
        }
    }

    $pos->{to_move} = $parts[1] // 'w';

    $pos->{castling_rights} = $BB_EMPTY;
    if (defined $parts[2]) {
        $pos->{castling_rights} |= $BB_1_PER_SQUARE[H1] if $parts[2] =~ /K/;
        $pos->{castling_rights} |= $BB_1_PER_SQUARE[A1] if $parts[2] =~ /Q/;
        $pos->{castling_rights} |= $BB_1_PER_SQUARE[H8] if $parts[2] =~ /k/;        
        $pos->{castling_rights} |= $BB_1_PER_SQUARE[A8] if $parts[2] =~ /q/;
    }

    if (defined $parts[2]) {
        if ($parts[3] eq '-') {
            $pos->{ep_square} = undef;
        } else {
            $pos->{ep_square} = $square_numbers{$parts[3]};
        }
    }

    $pos->{halfmove_clock}  = $parts[4] // 0;
    $pos->{fullmove_number} = $parts[5] // 1;
        
    for my $row (0 .. $#rows) { # 8th row first in, Q before K
        my $i = 64 - (($row + 1) * 8);
        my @items = split //, $rows[$row];
        for my $col (0 .. $#items) {
            if ($items[$col] =~ /(\d+)/) {
                # empty squares
                for my $j (1 .. $1) {
                    $i++;
                }
            } else {
                my $mask = $BB_1_PER_SQUARE[$i];
                my $pcs = $fen_chars_to_piece_code{$items[$col]}; 
                $pos->{bb}{$pcs} |= $mask;
                # update other bb's
                if ($pcs <= 6) {
                    $pos->{bb}{'w'} |= $mask;
                    $pos->{bb}{all} |= $mask;
                } else {
                    $pos->{bb}{'b'} |= $mask;
                    $pos->{bb}{all} |= $mask;
                }
                $i++;
            }
        }
    }

    $pos->{stack} = ();
    $pos->{move_stack} = ();

    return $class->_new($pos);
}

sub copyOf {
    my ($class, $other) = @_;

    my $pos = {};

    # init bb's
    for my $p (WP .. BK) {
        $pos->{bb}{$p} = $other->{bb}{$p};
    }
    $pos->{bb}{'w'} = $other->{bb}{'w'};
    $pos->{bb}{'b'} = $other->{bb}{'b'};
    $pos->{bb}{all} = $other->{bb}{all};

    $pos->{to_move} = $other->{to_move};
    $pos->{ep_square} = $other->{ep_square};
    $pos->{castling_rights} = $other->{castling_rights};
    $pos->{halfmove_clock} = $other->{halfmove_clock};
    $pos->{fullmove_number} = $other->{fullmove_number};

    # clone state stack
    $pos->{stack} = ();
    for my $state (@{$other->{stack}}) {
        my %bitboards;
        for my $key (keys %{$state->{bitboards}}) {
            $bitboards{$key} = $state->{bitboards}{$key};
        }
        my %state_cp = (to_move => $state->{to_move},
                        castling_rights => $state->{castling_rights},
                        halfmove_clock => $state->{halfmove_clock},
                        fullmove_number => $state->{fullmove_number},
                        bitboards => \%bitboards,
                        ep_square => $state->{ep_square},
                       );
        push @{$pos->{stack}}, \%state_cp;
    }

    # clone move stack
    $pos->{move_stack} = ();
    for my $move (@{$other->{move_stack}}) {
        push @{$pos->{move_stack}}, $move;
    }

    return $class->_new($pos);      
}


### Public instance methods

sub to_move {
    my $pos = shift;
    return $pos->{to_move};
}

sub kingside_castling_right {   ## no critic (Subroutines::RequireArgUnpacking)
    my $pos = $_[0];
    if ($_[1] eq 'w') {
        return 1 if $pos->{castling_rights} & $BB_1_PER_SQUARE[H1];
    } else {
        return 1 if $pos->{castling_rights} & $BB_1_PER_SQUARE[H8];
    }
}

sub queenside_castling_right {  ## no critic (Subroutines::RequireArgUnpacking)
    my $pos = $_[0];
    if ($_[1] eq 'w') {
        return 1 if $pos->{castling_rights} & $BB_1_PER_SQUARE[A1];
    } else {
        return 1 if $pos->{castling_rights} & $BB_1_PER_SQUARE[A8];
    }
}

sub ep_square {
    my $pos = shift;
    return $pos->{ep_square};
}

sub fullmove_number {
    my $pos = shift;
    return $pos->{fullmove_number};
}

sub halfmove_clock {
    my $pos = shift;
    return $pos->{halfmove_clock};
}

sub ascii {
    my $pos = shift;
    my $result = "";
    for my $sqr (@SQUARES_180) {
        my $pcs = $pos->piece_at($sqr);
        $result .= $pcs;
        if ($BB_1_PER_SQUARE[$sqr] & $BB_FILE_H) {
            $result .= "\n" unless $sqr == H1;
        }
        else {
            $result .= " ";
        }
    }
    return $result;
}

sub fen {
    my $pos = shift;
    my $result = "";
    my $empties = 0;
    for my $sqr (@SQUARES_180) {
        my $pcs = $pos->piece_at($sqr);
        if ($pcs eq '.') {
            $empties++;
        }
        else {
            if ($empties) {
                $result .= $empties;
                $empties = 0;
            }
            $result .= $pcs;
        }
        if ($BB_1_PER_SQUARE[$sqr] & $BB_FILE_H) {
            if ($empties) {
                $result .= $empties;
                $empties = 0;
            }
            $result .= '/' unless $sqr == H1;
        }
    }

    my $castling = ($pos->kingside_castling_right('w')  ? 'K' : '')
      .($pos->queenside_castling_right('w') ? 'Q' : '')
      .($pos->kingside_castling_right('b')  ? 'k' : '')
      .($pos->queenside_castling_right('b') ? 'q' : '')
      ;
    
    $castling = '-' unless $castling;

    my $ep = $pos->{ep_square} || '-';
    $ep = $square_names{$ep} unless $ep eq '-';

    my $hmvc = $pos->{halfmove_clock}  // 0;
    my $fmvn = $pos->{fullmove_number} // 1;

    $result .= " $pos->{to_move} $castling $ep $hmvc $fmvn";
    
    return $result;
}

sub piece_at {
    my ($pos, $sqr) = @_;
    my $pcs = $pos->_piece_type_at($sqr);
    return $fen_chars[$pcs];
}

sub _piece_type_at {
    my ($pos, $sqr) = @_;
    my $mask = $BB_1_PER_SQUARE[$sqr];
    unless ($pos->{bb}{all} & $mask) {
        return EMPTY;
    }
    for my $p (WP .. BK) {
        return $p if $pos->{bb}{$p} & $mask;
    }
    die "Not supposed to come here ever";
}

sub set_piece_at {
    my ($pos, $sqr, $pcs) = @_;
    $pos->remove_piece_at($sqr);
    my $mask = $BB_1_PER_SQUARE[$sqr];
    $pos->{bb}{$pcs} |= $mask;

    # update other bb's
    if ($pcs <= 6) {
        $pos->{bb}{'w'} |= $mask;
        $pos->{bb}{all} |= $mask;
    }
    else {
        $pos->{bb}{'b'} |= $mask;
        $pos->{bb}{all} |= $mask;
    }
}

sub remove_piece_at {
    my ($pos, $sqr) = @_;
    my $pcs = $pos->_piece_type_at($sqr);
    return EMPTY if $pcs == EMPTY;

    # set 0 in bb for that square
    my $mask = $BB_0_PER_SQUARE[$sqr];
    $pos->{bb}{$pcs} &= $mask;

    # update other bb's
    if ($pcs <= 6) {
        $pos->{bb}{'w'} &= $mask;
        $pos->{bb}{all} &= $mask;
    }
    else {
        $pos->{bb}{'b'} &= $mask;
        $pos->{bb}{all} &= $mask;
    }

    return $pcs;
}

sub errors {
    my $pos = shift;

    if ($pos->{bb}{WK()} == 0) {
        return "WK missing";
    }
    if ($pos->{bb}{BK()} == 0) {
        return "BK missing";
    }
    if ($pos->_bb_count_1s(WK()) > 1) {
        return "Too many WKs";
    }
    if ($pos->_bb_count_1s(BK()) > 1) {
        return "Too many BKs";
    }
    if ($pos->_bb_count_1s(WP()) > 8) {
        return "Too many WPs";
    }
    if ($pos->_bb_count_1s(BP()) > 8) {
        return "Too many BPs";
    }
    if ($pos->_bb_count_1s('w') > 16) {
        return "Too many White stones";
    }
    if ($pos->_bb_count_1s('b') > 16) {
        return "Too many Black stones";
    }
    if (($pos->{bb}{WP()} | $pos->{bb}{BP()}) & ($BB_RANK_1 | $BB_RANK_8)) {
        return "Pawns on back rank";
    }
    if ($pos->_was_into_check()) {
        return "Self in check";
    }

    my $valid_ep_sqr = $pos->_valid_ep_square();
    if ($pos->{ep_square}) {
        if (! defined $valid_ep_sqr) {
            return "Invalid e.p. square: $pos->{ep_square}, but calculation disagreed.";
        }
        elsif ($valid_ep_sqr != $pos->{ep_square}) {
            return "Invalid e.p. square: $pos->{ep_square} vs. $valid_ep_sqr";
        }
    }

    if ($pos->{castling_rights} != $pos->_clean_castling_rights()) {
        return "Invalid castling rights";
    }

    # OK
    return undef;
}

sub _pseudo_legal_moves_iter {
    # iterator for pseudo-legal moves
    # optionally filtered by bitboard
    my $pos = shift;
    my $from_bb_filter = shift;
    my $to_bb_filter   = shift;
    $from_bb_filter //= $BB_ALL_64;
    $to_bb_filter   //= $BB_ALL_64;
    # closure state
    my $ep_capturers;
    if ($pos->{ep_square}) {
        if ($to_bb_filter & $BB_1_PER_SQUARE[$pos->{ep_square}] & ~$pos->{bb}{all}) { # empty target square
            $ep_capturers = $pos->{to_move} eq 'w'
                            ? $pos->{bb}{WP()} & $BB_PAWN_ATTACKS_b[$pos->{ep_square}] & $BB_RANK_5 
                            : $pos->{bb}{BP()} & $BB_PAWN_ATTACKS_w[$pos->{ep_square}] & $BB_RANK_4;
            $ep_capturers &= $from_bb_filter;
        }
    }
    my $pawn_capturers = $pos->{to_move} eq 'w' ? $pos->{bb}{WP()} : $pos->{bb}{BP()};
    $pawn_capturers &= $from_bb_filter;
    my $targets;
    my $_sq;
    if ($pawn_capturers) {
        $_sq = _pop_lsb_index(\$pawn_capturers);
        $targets = $pos->{to_move} eq 'w'
          ? $BB_PAWN_ATTACKS_w[$_sq] & $pos->{bb}{'b'}
          : $BB_PAWN_ATTACKS_b[$_sq] & $pos->{bb}{'w'};
        $targets &= $to_bb_filter;
    }
    my $promo_index = 0;
    my $promo_from;
    my $promo_to;
    my @promo = qw (Q R B N);
    # 'to' squares:
    my $single_moves = undef;
    my $double_moves = undef;
    if ($pos->{to_move} eq 'w') {
        $single_moves = ($from_bb_filter & $pos->{bb}{WP()}) << 8 & ~$pos->{bb}{all};
        $double_moves = $single_moves << 8 & ~$pos->{bb}{all} & $BB_RANK_4;
    }
    else {
        $single_moves = ($from_bb_filter & $pos->{bb}{BP()}) >> 8 & ~$pos->{bb}{all};
        $double_moves = $single_moves >> 8 & ~$pos->{bb}{all} & $BB_RANK_5;
    }
    $single_moves &= $to_bb_filter;
    $double_moves &= $to_bb_filter;

    my @castling_moves;
    $pos->_generate_castling_moves(\@castling_moves, $from_bb_filter, $to_bb_filter);

    # non-pawn moves
    # work_bits is a bitboard of potential from-squares
    my $work_bits =  $pos->{to_move} eq 'w' ? $pos->{bb}{'w'} & ~$pos->{bb}{WP()} : $pos->{bb}{'b'} & ~$pos->{bb}{BP()};
    $work_bits &= $from_bb_filter;
    my $attack_bits = 0;
    my $sq;
    my $pcs;

    return sub {
        if ($promo_index > 0 && $promo_index < 4) {
            my $result = Chess4p::Move->new($promo_from, $promo_to, $promo[$promo_index++]);
            $promo_index = 0 if $promo_index == 4; # in case of 2 capturing targets on 1st/8th rank
            return $result;
        }
        if ($ep_capturers) {
            my $sq = _pop_lsb_index(\$ep_capturers);
            return Chess4p::Move->new($sq, $pos->{ep_square});
        }

        while ($pawn_capturers && !$targets) {
            # try for a capturer with any target...
            $_sq = _pop_lsb_index(\$pawn_capturers);
            $targets = $pos->{to_move} eq 'w'
              ? $BB_PAWN_ATTACKS_w[$_sq] & $pos->{bb}{'b'}
              : $BB_PAWN_ATTACKS_b[$_sq] & $pos->{bb}{'w'};
            $targets &= $to_bb_filter;
        }
        
        if ($pawn_capturers || $targets) {
            my $to = _pop_lsb_index(\$targets);                
            my $rk = _square_rank($to);
            if ($rk == RANK_1 || $rk == RANK_8) {
                $promo_from = $_sq;
                $promo_to = $to;
                # promo_index needs to handle two-way capture!
                return Chess4p::Move->new($promo_from, $promo_to, $promo[$promo_index++]);
            } else {
                return Chess4p::Move->new($_sq, $to);
            }
        }
        if ($single_moves) {
            my $to = _pop_lsb_index(\$single_moves);
            my $sq = $pos->{to_move} eq 'w' ? $to - 8 : $to + 8;
            my $rk = _square_rank($to);
            if ($rk == RANK_1 || $rk == RANK_8) {
                $promo_from = $sq;
                $promo_to = $to;
                return Chess4p::Move->new($promo_from, $promo_to, $promo[$promo_index++]);
            } else {
                return Chess4p::Move->new($sq, $to);
            }
        }
        if ($double_moves) {
            my $to = _pop_lsb_index(\$double_moves);
            my $sq = $pos->{to_move} eq 'w' ? $to - 16 : $to + 16;
            return Chess4p::Move->new($sq, $to);
        }
        
        while ($work_bits || $attack_bits) {
#            say ">>>>>WORK-BITS:\n"._print_bb($work_bits);
            if (!$attack_bits) {
                $sq  = _pop_lsb_index(\$work_bits);
                $pcs = $pos->_piece_type_at($sq);
                if ($pcs == WN || $pcs == BN) {
                    $attack_bits = $BB_KNIGHT_ATTACKS[$sq];
                } elsif ($pcs == WK || $pcs == BK) {
                    $attack_bits = $BB_KING_ATTACKS[$sq];
                } elsif ($pcs == WB || $pcs == BB) {
                    $attack_bits = $BB_DIAG_ATTACKS->[$sq]{$BB_DIAG_MASKS->[$sq] & $pos->{bb}{all}};
                } elsif ($pcs == WR || $pcs == BR) {
                    $attack_bits  = $BB_RANK_ATTACKS->[$sq]{$BB_RANK_MASKS->[$sq] & $pos->{bb}{all}};
                    $attack_bits |= $BB_FILE_ATTACKS->[$sq]{$BB_FILE_MASKS->[$sq] & $pos->{bb}{all}};
                } elsif ($pcs == WQ || $pcs == BQ) {
                    $attack_bits  = $BB_RANK_ATTACKS->[$sq]{$BB_RANK_MASKS->[$sq] & $pos->{bb}{all}};
                    $attack_bits |= $BB_FILE_ATTACKS->[$sq]{$BB_FILE_MASKS->[$sq] & $pos->{bb}{all}};
                    $attack_bits |= $BB_DIAG_ATTACKS->[$sq]{$BB_DIAG_MASKS->[$sq] & $pos->{bb}{all}};
                }
                $attack_bits &= $to_bb_filter;
            }
            while ($attack_bits) {
                my $to = _pop_lsb_index(\$attack_bits);
                my $pcs_to = $pos->_piece_type_at($to);
                if ($pcs_to == EMPTY || ($pos->{to_move} eq 'w' ? $pcs_to >= 7 : $pcs_to < 7)) {
                    # not own stone - we can go there
                    return Chess4p::Move->new($sq, $to);
                }
            }
        }

        if (my $any = pop(@castling_moves)) {
            return $any;
        }

        return undef;
    }
}

sub _pseudo_legal_ep_iter {
    my ($pos, $from_mask, $to_mask) = @_;
    $from_mask //= $BB_ALL_64;
    $to_mask   //= $BB_ALL_64;
    my $capturers = $BB_EMPTY;
    my $ep_sqr = $pos->{ep_square};
    if ($ep_sqr) {
        unless ($pos->{bb}{all} & $BB_1_PER_SQUARE[$ep_sqr]) {
            # e.p. square is free
            if ($to_mask & $BB_1_PER_SQUARE[$ep_sqr]) {
                # e.p. square matches the mask
                $capturers = $pos->{to_move} eq 'w'
                  ? $pos->{bb}{WP()} & $BB_PAWN_ATTACKS_b[$ep_sqr] & $BB_RANK_5 
                  : $pos->{bb}{BP()} & $BB_PAWN_ATTACKS_w[$ep_sqr] & $BB_RANK_4;
                $capturers &= $from_mask;
            }
        }
    }

    return sub {
        while ($capturers) {
            my $sq = _pop_lsb_index(\$capturers);
            return Chess4p::Move->new($sq, $pos->{ep_square});
        }
        return undef;
    }
}

sub _evasions_iter {
    my ($pos, $king, $checkers, $from_bb_filter, $to_bb_filter) = @_;
    $from_bb_filter //= $BB_ALL_64;
    $to_bb_filter   //= $BB_ALL_64;
    my $sliders = $checkers & ($pos->{bb}{WQ()} | $pos->{bb}{BQ()} | ($pos->{bb}{WR()}) | ($pos->{bb}{BR()}) | ($pos->{bb}{WB()}) | ($pos->{bb}{BB()}) );
    my $attacked = $BB_EMPTY;
    my $one_checker = _msb($checkers);
    my $target;
    my $ep_iter;
    if ($BB_1_PER_SQUARE[$one_checker] == $checkers) {
        # a single checker
        # target squares: block or capture the checker
        $target = _between($king, $one_checker) | $checkers;
        if ($pos->{ep_square}) {
            unless ($BB_1_PER_SQUARE[$pos->{ep_square}] & $target) {
                my $last_double = $pos->{ep_square};
                $last_double -= 8 if $pos->{to_move} eq 'w';
                $last_double += 8 if $pos->{to_move} eq 'b';
                if ($last_double == $one_checker) {
                    $ep_iter = $pos->_pseudo_legal_ep_iter($from_bb_filter, $to_bb_filter);
                }
            }
        }
    }
    my $block_iter;
    if ($target) {
        # set up iterator
        # note that when used from SAN output, the filters are used (the from filter may be 0 actually)
        $block_iter = $pos->_pseudo_legal_moves_iter(~_make_bb($king) & $from_bb_filter, $target & $to_bb_filter);
    }
    while ($sliders) {
        my $checker = _pop_lsb_index(\$sliders);
        $attacked |= _ray($king, $checker) & $BB_0_PER_SQUARE[$checker];
    }
    my $our_stones = $pos->{bb}{$pos->{to_move}};
    # bitboard for the king's flight squares
    my $move_away_bb = 0;
    if ($from_bb_filter & $BB_1_PER_SQUARE[$king]) {
        # note that from-filter may be empty, when used from SAN output code (for the disambiguation check)
        $move_away_bb = $BB_KING_ATTACKS[$king] & ~$attacked & ~$our_stones & $to_bb_filter;        
    }
    
    return sub {
        while ($move_away_bb) {
            my $sq = _pop_lsb_index(\$move_away_bb);
            return Chess4p::Move->new($king, $sq);
        }
        if ($target) {
            while (defined(my $m = $block_iter->())) {
                return $m;
            }
        }
        if ($ep_iter) {
            while (defined(my $m = $ep_iter->())) {
                return $m;
            }
        }
        return undef;
    }
}

sub _slider_blockers {
    my ($pos, $king) = @_;
    my $opponent = $pos->_opponent();
    my $rooks_queens =   $opponent eq 'w' ? $pos->{bb}{WQ()} : $pos->{bb}{BQ()};
    $rooks_queens |=     $opponent eq 'w' ? $pos->{bb}{WR()} : $pos->{bb}{BR()};
    my $bishops_queens = $opponent eq 'w' ? $pos->{bb}{WQ()} : $pos->{bb}{BQ()};
    $bishops_queens |=   $opponent eq 'w' ? $pos->{bb}{WB()} : $pos->{bb}{BB()};
    my $snipers = (($BB_RANK_ATTACKS->[$king]{0} & $rooks_queens) |
                   ($BB_FILE_ATTACKS->[$king]{0} & $rooks_queens) |
                   ($BB_DIAG_ATTACKS->[$king]{0} & $bishops_queens));
    my $blockers = $BB_EMPTY;
    while ($snipers) {
        my $sq = _pop_lsb_index(\$snipers);
        # bb is the blocking stones
        my $bb = _between($king, $sq) & $pos->{bb}{all};
        # Add to blockers if exactly one piece in-between.
        if ($bb && ($BB_1_PER_SQUARE[_msb($bb)] == $bb)) {
            $blockers |= $bb;
        }
    }
    $blockers;
}

sub _was_into_check {
    my ($pos) = @_;
    my $s = $pos->{to_move};
    return 0 unless $s;
    my $king = $s eq 'w' ? $pos->{bb}{BK()} : $pos->{bb}{WK()};
    $king = _msb($king);
    return $king && $pos->_get_attackers($s, $king);
}

sub _push_random_move {
    # make a legal move chosen at random.
    # if no legal move exists, do nothing
    # return 1 if a move was made
    my ($pos) = @_;
    my $moves_ref = $pos->legal_moves();
    return 0 unless @$moves_ref;
    my $i = rand(@$moves_ref);
    $pos->push_move($moves_ref->[$i]);
    return 1;
}

sub legal_moves_iter {
    # iterate over legal moves from board position
    my ($pos, $from_bb_filter, $to_bb_filter) = @_;
    $from_bb_filter //= $BB_ALL_64;
    $to_bb_filter   //= $BB_ALL_64;
    my $moves_iter = $pos->_pseudo_legal_moves_iter($from_bb_filter, $to_bb_filter);
    
    my $side = $pos->{to_move};
    my $opponent = $side eq 'w' ? 'b' : 'w';
    my $king = $side eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()};
    $king = _msb($king);
    my $blockers = $pos->_slider_blockers($king);
    my $checkers = $pos->_get_attackers($opponent, $king);
    my $evasions_iter = $pos->_evasions_iter($king, $checkers, $from_bb_filter, $to_bb_filter);

    return sub {
        if ($checkers) {
            while (defined(my $m = $evasions_iter->())) {
                if ($pos->_is_safe($king, $blockers, $m->{from}, $m->{to})) {
                    return $m;
                }
            }
        }
        else {
            while (defined(my $m = $moves_iter->())) {
                if ($pos->_is_safe($king, $blockers, $m->{from}, $m->{to})) {
                    return $m;
                }
            }
        }
        return undef;
    }
}

sub legal_moves {
    my $pos = shift;
    my @result;
    my $moves_iter = $pos->legal_moves_iter();
    while (defined(my $m = $moves_iter->())) {
        push (@result, $m);
    }
    \@result;
}

sub push_move_uci {
    my ($pos, $move) = @_;
    my $from = $square_numbers{substr($move, 0, 2)};
    my $to   = $square_numbers{substr($move, 2, 2)};
    my $promoted;
    $promoted = uc(substr($move, 4)) if length($move) > 4;
    $pos->push_move(Chess4p::Move->new($from, $to, $promoted));
}

sub push_move_san {
    my ($pos, $san) = @_;
    my $move = $pos->parse_san($san);
    $pos->push_move($move);
}

sub push_move {
    my ($pos, $move) = @_;
    $pos->{castling_rights} = $pos->_clean_castling_rights();
    push (@{$pos->{move_stack}}, $move);

    my %bitboards;
    for my $key (keys %{$pos->{bb}}) {
        $bitboards{$key} = $pos->{bb}{$key};
    }
    my %state = (to_move => $pos->{to_move},
                 castling_rights => $pos->{castling_rights},
                 halfmove_clock => $pos->{halfmove_clock},
                 fullmove_number => $pos->{fullmove_number},
                 bitboards => \%bitboards,
                 ep_square => $pos->{ep_square},
                );
    push (@{$pos->{stack}}, \%state);
    
    my $ep_square = $pos->{ep_square};
    $pos->{ep_square} = undef;
    $pos->{halfmove_clock}++;
    $pos->{fullmove_number}++ if $pos->{to_move} eq 'b';
    unless ($move) {
        # null move - swap turns and reset en passant square.
        $pos->{to_move} = $pos->_opponent();
        return;
    }
    # reset halfmove clock if needed
    $pos->{halfmove_clock} = 0 if $pos->_is_zeroing($move);
    my $from_bb = $BB_1_PER_SQUARE[$move->from()];
    my $to_bb = $BB_1_PER_SQUARE[$move->to()];
    my $pcs = $pos->remove_piece_at($move->from());
    croak "push needs a pseudo-legal move, but got $move" unless $pcs;
    my $capture_sqr  = $move->to();
    my $captured_pcs = $pos->piece_at($capture_sqr);

    # Update castling rights
    $pos->{castling_rights} &= ~$to_bb & ~$from_bb;
    if (($pcs == WK || $pcs == BK)) { # && ! promoted
        $pos->{castling_rights} &= ~$BB_RANK_1 if $pos->{to_move} eq 'w';
        $pos->{castling_rights} &= ~$BB_RANK_8 if $pos->{to_move} eq 'b';
    }
    # special pawn moves
    if ($pcs == WP || $pcs == BP) {
        my $diff = $move->to() - $move->from();
        if ($diff == 16 && _square_rank($move->from()) == RANK_2) {
            $pos->{ep_square} = $move->from() + 8;
        }
        elsif ($diff == -16 && _square_rank($move->from()) == RANK_7) {
            $pos->{ep_square} = $move->from() - 8;
        }
        elsif (defined $ep_square && $move->to() == $ep_square && $captured_pcs eq '.' && (abs($diff) == 7 || abs($diff) == 9)) {
            # remove pawn captured e.p.
            my $down = $pos->{to_move} eq 'w' ? -8 : 8;
            $capture_sqr = $move->to() + $down;
            $captured_pcs = $pos->remove_piece_at($capture_sqr);
        }
    }
    if ($move->promotion()) {
        if ($pos->{to_move} eq 'w') {
            $pcs = $fen_chars_to_piece_code{$move->promotion()};
        }
        else {
            $pcs = $fen_chars_to_piece_code{lc($move->promotion())};
        }
    }
    # castling
    my $castling = ($pcs == WK || $pcs == BK) && _square_distance($move->from(), $move->to()) > 1;
    if ($castling) {
        my $a_side = _square_file($move->to()) < _square_file($move->from());
        $pos->remove_piece_at($move->from());
        # TODO
        # the king is not allowed to capture with castling, so next line should be removable?
        # (python-chess)
        $pos->remove_piece_at($move->to());
        ## no critic (ValuesAndExpressions::ProhibitCommaSeparatedStatements)
        if ($a_side) {
            $pos->set_piece_at(C1, WK), $pos->set_piece_at(D1, WR), $pos->remove_piece_at(A1) if $pos->{to_move} eq 'w';
            $pos->set_piece_at(C8, BK), $pos->set_piece_at(D8, BR), $pos->remove_piece_at(A8) if $pos->{to_move} eq 'b';
        }
        else {
            $pos->set_piece_at(G1, WK), $pos->set_piece_at(F1, WR), $pos->remove_piece_at(H1) if $pos->{to_move} eq 'w';
            $pos->set_piece_at(G8, BK), $pos->set_piece_at(F8, BR), $pos->remove_piece_at(H8) if $pos->{to_move} eq 'b';
        }
    }
    else {
        $pos->set_piece_at($move->to(), $pcs);
    }
    # swap turn
    $pos->{to_move} = $pos->_opponent();
}

sub pop_move {
    my ($pos) = @_;
    return unless defined $pos->{move_stack} && @{$pos->{move_stack}};
    my $move = pop @{$pos->{move_stack}};
    my $href = pop @{$pos->{stack}};
    $pos->{to_move} = $href->{to_move};
    $pos->{castling_rights} = $href->{castling_rights};
    $pos->{halfmove_clock} = $href->{halfmove_clock};
    $pos->{fullmove_number} = $href->{fullmove_number};
    $pos->{bb} = $href->{bitboards};
    $pos->{ep_square} = $href->{ep_square};
    return $move;
}

sub apply_mirror {
    my ($pos) = @_;

    $pos->_transform_bitboards(\&_flip_vertical);

    # invert colours
    for my $p (WP .. WK) {
        ($pos->{bb}{$p}, $pos->{bb}{_opponent_piece($p)}) = ($pos->{bb}{_opponent_piece($p)}, $pos->{bb}{$p});
    }
    ($pos->{bb}{'w'}, $pos->{bb}{'b'}) = ($pos->{bb}{'b'}, $pos->{bb}{'w'});

    # mirror remaining properties
    $pos->{to_move} = $pos->_opponent();
    $pos->{ep_square} = _square_mirror($pos->{ep_square}) if $pos->{ep_square};

    $pos->{move_stack} = ();
    $pos->{stack} = ();
}

sub _pieces_mask {
    my ($pos, $piece_char) = @_;
    if ($pos->{to_move} eq 'w') {
        return $pos->{bb}{WN()} if $piece_char eq 'N';
        return $pos->{bb}{WB()} if $piece_char eq 'B';        
        return $pos->{bb}{WR()} if $piece_char eq 'R';
        return $pos->{bb}{WQ()} if $piece_char eq 'Q';
        return $pos->{bb}{WK()} if $piece_char eq 'K';        
        croak "Wrong piece type: $piece_char";
    }
    else {
        return $pos->{bb}{BN()} if $piece_char eq 'N';
        return $pos->{bb}{BB()} if $piece_char eq 'B';        
        return $pos->{bb}{BR()} if $piece_char eq 'R';
        return $pos->{bb}{BQ()} if $piece_char eq 'Q';
        return $pos->{bb}{BK()} if $piece_char eq 'K';        
        croak "Wrong piece type: $piece_char";
    }
}

sub parse_san {
    my ($pos, $san) = @_;

    if ($san =~ /^O-O-O/ || $san =~ /^0-0-0/) {
        my @castling_moves;
        $pos->_generate_castling_moves(\@castling_moves, $BB_ALL_64, $BB_ALL_64);
        for my $move (@castling_moves) {
            return $move if $move && ( _square_file($move->to()) < _square_file($move->from()) );
        }
        croak "Illegal san (long castling) for $san in ".$pos->fen();
    }
    elsif ($san =~ /^O-O/ || $san =~ /^0-0/) {
        my @castling_moves;
        $pos->_generate_castling_moves(\@castling_moves, $BB_ALL_64, $BB_ALL_64);
        for my $move (@castling_moves) {
            return $move if $move && ( _square_file($move->to()) > _square_file($move->from()) );
        }
        croak "Illegal san (short castling) for $san in ".$pos->fen();
    }

    if ($san =~ /^([NBKRQ])?([a-h])?([1-8])?[-x]?([a-h][1-8])=?([nbrqkNBRQK])?[\+#]?\z/o)  {
        my $to = $square_numbers{$4};
        my $occupied = $pos->{bb}{$pos->{to_move}};
        my $to_mask = $BB_1_PER_SQUARE[$to] & ~$occupied;
        my $promotion = $5;
        my $from_mask = $BB_ALL_64;
        my $from_file;
        my $from_rank;
        
        if ($2) {
            $from_file = $file_numbers{$2};
            $from_mask &= $BB_FILES[$from_file];
        }

        if ($3) {
            $from_rank = $rank_numbers{$3};
            $from_mask &= $BB_RANKS[$from_rank];
        }

        if ($1) {
            $from_mask &= $pos->_pieces_mask($1);
        }
        elsif (defined $from_file && defined $from_rank) {
            # Allow fully specified moves, even if they are not pawn moves,
            # including castling moves.
            my $move = $pos->_find_move(_square($from_file, $from_rank), $to, $promotion);
            if ( uc($move->promotion() // '') eq uc($promotion // '') ) {
                return $move;
            }
            else {
                croak "Missing promotion piece type: $san in ".$pos->fen();
            }
        }
        else {
            $from_mask &= $pos->{to_move} eq 'w' ? $pos->{bb}{WP()} : $pos->{bb}{BP()};
            # Do not allow pawn captures, if file is not specified
            $from_mask &= $BB_FILES[_square_file($to)] unless defined $from_file;
        }

        my $matched_move;

        # say ">>>>FROM-MASK:\n"._print_bb($from_mask);
        # say ">>>>>>TO-MASK:\n"._print_bb($to_mask);
        
        my $moves_iter = $pos->legal_moves_iter($from_mask, $to_mask);
        while (defined(my $move = $moves_iter->())) {
            next if ($move->promotion() // '') ne ($promotion // '');
            croak "Ambiguous san: $san, matched both $matched_move and $move in ".$pos->fen().
              "\nwith from mask:\n"._print_bb($from_mask). "\nand to mask:\n"._print_bb($to_mask)
              if $matched_move;
            $matched_move = $move;
        }

        croak "Illegal san: $san in ".$pos->fen() unless $matched_move;

        return $matched_move;

    }
    else {
        # Null move
        return undef
          if $san eq '--'
          || $san eq 'Z0'
          || $san eq '0000'
          || $san eq '@@@@';
        croak "Illegal san (maybe null move?): $san in ".$pos->fen();
    }
}

sub _find_move {
    my ($pos, $from_sqr, $to_sqr, $promotion) = @_;
    unless ($promotion) {
        # by default, promote to queen
        my $bb_pawns = $pos->{to_move} eq 'w' ? $pos->{bb}{WP()} : $pos->{bb}{BP()};
        if ($bb_pawns & $BB_1_PER_SQUARE[$from_sqr] && $BB_1_PER_SQUARE[$to_sqr] & $BB_BACKRANKS) {
            $promotion = 'Q';
        }
    }
    my $move = Chess4p::Move->new($from_sqr, $to_sqr, $promotion);
    croak "No matching legal move for $move in ".$pos->fen() unless $pos->_is_legal($move);
    return $move;
}

sub _is_into_check {
    my ($pos, $move) = @_;
    my $king_bb = $pos->{to_move} eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()};
    my $king_sqr = _msb($king_bb);
    my $checkers = $pos->_get_attackers($pos->_opponent(), $king_sqr);
    if ($checkers) {
        # Already in check - look if it is an evasion.
        my $evasions_iter = $pos->_evasions_iter($king_sqr, $checkers, $BB_1_PER_SQUARE[$move->from()], $BB_1_PER_SQUARE[$move->to()]);
        my $found = 0;
        while (defined(my $m = $evasions_iter->())) {
            ## no critic (ValuesAndExpressions::ProhibitCommaSeparatedStatements)            
            $found = 1, last
              if $m->to() == $move->to()
              && $m->from() == $move->from()
              && uc($m->promotion() // '') eq uc($move->promotion() // '');
        }
        return 1 unless $found;
    }
    return not $pos->_is_safe($king_sqr, $pos->_slider_blockers($king_sqr), $move->from(), $move->to());
}

sub _is_pseudo_legal {
    my ($pos, $move) = @_;
    
    # Null moves are not pseudo-legal.
    return 0 unless $move;

    my $pcs = $pos->_piece_type_at($move->from());
    # Source square must not be vacant.
    return 0 unless $pcs;

    my $from_mask = $BB_1_PER_SQUARE[$move->from()];
    my $to_mask   = $BB_1_PER_SQUARE[$move->to()];    
    my $occupied = $pos->{bb}{$pos->{to_move}};

    # side to move must occupy the from square
    return 0 unless $occupied & $from_mask;

    # can't capture own stone
    return 0 if $occupied & $to_mask;

    if ($move->promotion()) {
        # only pawns can promote
        return 0 if $pcs != WP && $pcs != BP;
        # promotion only on the backrank
        return 0 if $pos->{to_move} eq 'w' && _square_rank($move->to()) != RANK_8;
        return 0 if $pos->{to_move} eq 'b' && _square_rank($move->to()) != RANK_1;        
    }

    if ($pcs == WK || $pcs == BK) {
        my @castling_moves;
        $pos->_generate_castling_moves(\@castling_moves, $BB_ALL_64, $BB_ALL_64);
        for my $mv (@castling_moves) {
            return 1 if $move->from() == $mv->from() && $move->to() == $mv->to();
        }
    }

    # Pawns
    if ($pcs == WP || $pcs == BP) {
        my $moves_iter = $pos->_pseudo_legal_moves_iter($from_mask, $to_mask);
        while (defined(my $m = $moves_iter->())) {
            return 1
              if $m->to() == $move->to()
              && $m->from() == $move->from()
              && uc($m->promotion() // '') eq uc($move->promotion() // '');
        }
        return 0;
    }

    # Pieces
    return $pos->_attacks_mask($move->from()) & $to_mask;
}

sub _attacks_mask {
    # what is attacked from square
    my ($pos, $sqr) = @_;
    my $bb_sqr = $BB_1_PER_SQUARE[$sqr];
    my $pcs = $pos->_piece_type_at($sqr);
    if ($pcs == WP) {
        return $BB_PAWN_ATTACKS_w[$sqr];
    }
    elsif ($pcs == BP) {
        return $BB_PAWN_ATTACKS_b[$sqr];
    }
    elsif ($pcs == WN || $pcs == BN) {
        return $BB_KNIGHT_ATTACKS[$sqr];
    }
    elsif ($pcs == WK || $pcs == BK) {
        return $BB_KING_ATTACKS[$sqr];
    }
    else {
        my $attacks = 0;
        if ($pcs == WB || $pcs == BB || $pcs == WQ || $pcs == BQ) {
            $attacks = $BB_DIAG_ATTACKS->[$sqr]{$BB_DIAG_MASKS->[$sqr] & $pos->{bb}{all}};
        }
        if ($pcs == WR || $pcs == BR || $pcs == WQ || $pcs == BQ) {
            $attacks |= ( $BB_RANK_ATTACKS->[$sqr]{$BB_RANK_MASKS->[$sqr] & $pos->{bb}{all}}
                        | $BB_FILE_ATTACKS->[$sqr]{$BB_FILE_MASKS->[$sqr] & $pos->{bb}{all}} ) ;
        }
        return $attacks;
    }
}

sub _is_legal {
    my ($pos, $move) = @_;
    return $pos->_is_pseudo_legal($move) && !$pos->_is_into_check($move);
    # slower, but less complex:
    # my $legal_moves = $pos->legal_moves();
    # for my $mv (@$legal_moves) {
    #     return 1 if $mv->from() == $move->from() && $mv->to() == $move->to();
    # }
}

sub san {
    my ($pos, $move) = @_;
    return $pos->_algebraic($move);
}

sub _algebraic {
    my ($pos, $move) = @_;
    my $result = $pos->_algebraic_and_push($move);
    $pos->pop_move();
    $result;
}

sub _algebraic_and_push {
    my ($pos, $move) = @_;
    my $san = $pos->_algebraic_without_suffix($move);
    # Look ahead for check or checkmate.
    $pos->push_move($move);
    my $check = $pos->_is_check();
    my $mate;
    if ($check) {
        my $moves_iter = $pos->legal_moves_iter();
        $mate = 1 unless $moves_iter->();
    }
    return "$san#" if $mate;
    return "$san+" if $check;
    return $san;
}

sub _algebraic_without_suffix {
    my ($pos, $move) = @_;
    # Null move
    return '--' unless $move;
    # castling
    if ($pos->_is_castling($move)) {
        return 'O-O-O' if _square_file($move->to()) < _square_file($move->from());
        return 'O-O';
    }
    my $pcs = $pos->_piece_type_at($move->from());
    croak "san() expect legal move or null, but got $move in ".$pos->fen() unless $pcs;
    my $capture = $pos->_is_capture($move);
    my $result;
    if ($pcs != WP && $pcs != BP) {
        $result = uc($fen_chars[$pcs]);
#        say ">>>>>>>>>>>>>$result";
        # Get ambiguous move candidates.
        # Relevant candidates: not exactly the current move,
        # but to the same square.
        my $others = 0;
        my $from_mask = $pos->{bb}{$pcs};
        $from_mask &= $BB_0_PER_SQUARE[$move->from()];
        my $to_mask = $BB_1_PER_SQUARE[$move->to()];
#        say ">>>>>>>>>>>>>from-mask:\n". _print_bb($from_mask);
#        say ">>>>>>>>>>>>>>>to-mask:\n". _print_bb($to_mask);        
        my $legal_moves_iter = $pos->legal_moves_iter($from_mask, $to_mask);
        while (defined (my $m = $legal_moves_iter->())) {
            $others |= $BB_1_PER_SQUARE[$m->from()];
        }
        if ($others) {
            # Disambiguate
            my ($row, $col) = (0, 0);
            if ($others & $BB_RANKS[_square_rank($move->from())]) {
                $col = 1;
            }
            if ($others & $BB_FILES[_square_file($move->from())]) {
                $row = 1;
            }
            else {
                $col = 1;
            }
            $result .= $file_names{_square_file($move->from())} if $col;
            $result .= $rank_names{_square_rank($move->from())} if $row;            
        }
    }
    elsif ($capture) {
        $result .= $file_names{_square_file($move->from())};
    }

    $result .= 'x' if $capture;

    # Destination square
    $result .= $square_names{$move->to()};

    # Promotion.
    if ($move->promotion()) {
        $result .= '=' . uc($move->promotion());
    }

    $result;
}

sub _is_check {
    # Test if side to move is in check.
    my $pos = shift;
    my $king_sqr = _msb($pos->{to_move} eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()});
    return $pos->_get_attackers($pos->_opponent(), $king_sqr);
}

sub _is_castling {
    my ($pos, $move) = @_;
    my $king_bb = $pos->{to_move} eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()};
    if ($king_bb & $BB_1_PER_SQUARE[$move->from()]) {
        my $diff = _square_file($move->from()) - _square_file($move->to());
        return abs($diff) > 1;
    }
    return 0;
}

sub _is_capture {
    my ($pos, $move) = @_;
    my $touched = $BB_1_PER_SQUARE[$move->from()] ^ $BB_1_PER_SQUARE[$move->to()];
    my $occupied = $pos->{bb}{$pos->_opponent()};
    ($touched & $occupied) || $pos->_is_en_passant($move);
}

sub _is_en_passant {
    my ($pos, $move) = @_;
    my $pawns = $pos->{to_move} eq 'w' ? $pos->{bb}{WP()} : $pos->{bb}{BP()};
    my $abs_diff = abs($move->to() - $move->from());
    return $pos->{ep_square}
      && $pos->{ep_square} == $move->to()
      && $BB_1_PER_SQUARE[$move->from()] & $pawns
      && ($abs_diff == 7 || $abs_diff == 9)
      && !($pos->{bb}{all} & $BB_1_PER_SQUARE[$move->to()]);
}

sub ply {
    my $pos = shift;
    return 2 * ($pos->fullmove_number() - 1) + ($pos->{to_move} eq 'b');
}




1;

__END__

=encoding utf8

=head1 NAME

Board - Chess board class

=head1 SYNOPSIS

The below is just a small sample, and far from extensive.

For more elaborate examples, see the prototypes directory in the Git repo.

    use Board;

    my $board = Board->fromFen($fen);

    print $board->ascii();

    my $move = $board->parse_move_san('e4');

    $board->push_move($move);

    $board->pop_move();



=head1 DESCRIPTION

Board provides Board objects, with features including

=over 4

=item *

Construction from FEN

=item *

FEN output

=item *

Generate legal moves

=item *

SAN input / output

=item *

Making moves to update the board, and going back again ('unmaking' the moves).

=item *

Mirror the board vertically.

Other kinds of mirrors and rotation may be added in later versions.

=item *

Get other properties of the board position

=back



=head1 METHODS


=over 4



=item fromFen($fen)

Constructor.
Create a Board from a FEN string (Forsyth–Edwards Notation).
If the input $fen is empty, use the conventional start position.

=item empty()

Constructor.
Create an empty Board.

=item copyOf($board)

Copy constructor.
Create a Board as a copy of the input Board.

=item fen()

Get the FEN for this board position.

=item errors()

Return undef if position is valid.
Otherwise, a string describing the error.

=item ascii()

Write the board as ASCII.

=item legal_moves_iter()

Get an iterator over the legal moves from this position.

=item legal_moves()

Get legal moves from this position.

=item to_move()

Return the side to move.

=item parse_san($san)

Parse a SAN string with this board as the context.
Return the legal move specified by the SAN string, if such a move
can be uniquely determined.
Croak if no such unique legal move can be determined.

=item push_move($move)

Update with the given *move* and push it to the move
Moves are not checked for legality. It is the caller's
responsibility to ensure that the move is at least pseudo-legal or
a null move.
Null moves just increment the move counters, switch turns and forfeit
en passant capturing.

=item push_move_san($san)

Assuming the input is a valid move in SAN notation, will push the move.
Croak if not a valid move.
See push_move($move).

=item push_move_uci($uci)

Assuming the input is a valid move in UCI notation, will push the move.
See push_move($move).

=item pop_move()

Restore previous position and return last move from stack.
If move stack is empty, no-op and return undef.

=item piece_at($square)

Get the piece at given square.

=item remove_piece_at($square)

Remove the piece at given square.
If square is empty, does nothing.

=item set_piece_at($square, $piece)

Put given piece/pawn on given square.
Any existing piece/pawn on that square is removed.

=item kingside_castling_right($side)

Is kingside castling allowed for the given side?

$side = 'w' or 'b'

=item queenside_castling_right($side)

Is queenside castling allowed for the given side?

$side = 'w' or 'b'

=item ep_square()

En passant capture square, or undef if N/A

=item fullmove_number()

Counts move pairs. Starts at 1, increments after every
Black move.

=item halfmove_clock()

Number of ply since last capture or pawn move.

=item apply_mirror()

Mirror this board vertically.

=item san($move)

Get the Standard Algebraic Notation of the given move in the context
of this position.

=item ply()

Get number of half-moves since start of game.


=back


=head1 AUTHOR

Ejner Borgbjerg

=head1 LICENSE

Perl Artistic License, GPL

=cut
