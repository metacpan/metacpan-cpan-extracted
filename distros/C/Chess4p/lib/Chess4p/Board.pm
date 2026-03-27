# -*- mode: cperl -*-
package Chess4p::Board;

use v5.36;

use Carp;
use List::Util qw( max );

use Scalar::Util qw(reftype refaddr);

use Chess4p;

use Chess4p::Common qw(FILE_A FILE_B FILE_C FILE_D
                     FILE_E FILE_F FILE_G FILE_H
                     RANK_1 RANK_2 RANK_3 RANK_4
                     RANK_5 RANK_6 RANK_7 RANK_8
                     A1 B1 C1 D1 E1 F1 G1 H1
                     A2 B2 C2 D2 E2 F2 G2 H2
                     A3 B3 C3 D3 E3 F3 G3 H3
                     A4 B4 C4 D4 E4 F4 G4 H4
                     A5 B5 C5 D5 E5 F5 G5 H5
                     A6 B6 C6 D6 E6 F6 G6 H6
                     A7 B7 C7 D7 E7 F7 G7 H7
                     A8 B8 C8 D8 E8 F8 G8 H8
                     EMPTY WP WN WB WR WQ WK
                     BP BN BB BR BQ BK
                     %square_names
                     %square_numbers
                   );

use overload ('""', => 'ascii');


my $bb_empty = 0;

my $bb_all;
my $bb_file_a;
my $bb_file_b;
my $bb_file_c;
my $bb_file_d;
my $bb_file_e;
my $bb_file_f;
my $bb_file_g;
my $bb_file_h;
{
    no warnings "portable";
    $bb_all = 0xffff_ffff_ffff_ffff;
    $bb_file_a = 0x0101_0101_0101_0101 << FILE_A;
    $bb_file_b = 0x0101_0101_0101_0101 << FILE_B;
    $bb_file_c = 0x0101_0101_0101_0101 << FILE_C;
    $bb_file_d = 0x0101_0101_0101_0101 << FILE_D;
    $bb_file_e = 0x0101_0101_0101_0101 << FILE_E;    
    $bb_file_f = 0x0101_0101_0101_0101 << FILE_F;
    $bb_file_g = 0x0101_0101_0101_0101 << FILE_G;
    $bb_file_h = 0x0101_0101_0101_0101 << FILE_H;    
}
my @bb_files = ($bb_file_a, $bb_file_b, $bb_file_c, $bb_file_d, $bb_file_e, $bb_file_f, $bb_file_g, $bb_file_h);

my $bb_rank_1 = 0xff << (8 * RANK_1);
my $bb_rank_2 = 0xff << (8 * RANK_2);
my $bb_rank_3 = 0xff << (8 * RANK_3);
my $bb_rank_4 = 0xff << (8 * RANK_4);
my $bb_rank_5 = 0xff << (8 * RANK_5);
my $bb_rank_6 = 0xff << (8 * RANK_6);
my $bb_rank_7 = 0xff << (8 * RANK_7);
my $bb_rank_8 = 0xff << (8 * RANK_8);
my @bb_ranks = ($bb_rank_1, $bb_rank_2, $bb_rank_3, $bb_rank_4, $bb_rank_5, $bb_rank_6, $bb_rank_7, $bb_rank_8);

# Each has a single 0-bit at position 0..63, corresponding to  a1-h1, a2-h2, ..., a8-h8
my @bb_squares = map { ~(1 << $_) } 0..63;

my $bb_e1 = ~$bb_squares[E1];
my $bb_e8 = ~$bb_squares[E8];


sub _square_mirror { ## no critic (Subroutines::RequireArgUnpacking)
    # mirrors the square vertically
    $_[0] ^ 0x38;
}

my @squares_180 = map { _square_mirror($_) } 0..63;

my @bb_knight_attacks;
for my $sqr (A1 .. H8) {
    # tabulate knight attacks from each square
    $bb_knight_attacks[$sqr] = _step_attacks($sqr, [17, 15, 10, 6, -17, -15, -10, -6]);
}

my @bb_king_attacks;
for my $sqr (A1 .. H8) {
    # tabulate king attacks from each square
    $bb_king_attacks[$sqr] = _step_attacks($sqr, [9, 8, 7, 1, -9, -8, -7, -1]);
}

my @bb_pawn_attacks_w;
my @bb_pawn_attacks_b;
for my $sqr (A1 .. H8) {
    # tabulate pawn attacks from each square for each side
    # note that edge squares need to be tabulated too, even
    # when there are no attacks from there, to avoid accessing
    # undefined values in e.g. castling move gen.
    $bb_pawn_attacks_w[$sqr] = _step_attacks($sqr, [7, 9]);
    $bb_pawn_attacks_b[$sqr] = _step_attacks($sqr, [-7, -9]);    
}


### Free functions

sub _make_bb { ## no critic (Subroutines::RequireArgUnpacking)
    # make a bitboard from a list of squares
    # useful for testing
    my $result = 0;
    for (@_) {
        $result |= ~$bb_squares[$_];
    }
    $result;
}

sub _print_bb { ## no critic (Subroutines::RequireArgUnpacking)
    # bitboard as a string
    # useful for debugging
    my $bb = $_[0];
    my $result;
    for my $sqr (@squares_180) {
        my $mask = ~$bb_squares[$sqr];
        if ($bb & $mask) {
            $result .= "1";
        }
        else {
            $result .= ".";
        }
        unless ($mask & $bb_file_h) {
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
    # portable
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
    my $subset = $bb_empty;
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
    _sliding_attacks($sqr, $deltas, $bb_all);
}

sub _sliding_attacks { ## no critic (Subroutines::RequireArgUnpacking)
    my $sqr = $_[0];
    my $deltas = $_[1]; # ref
    my $occupied = $_[2];
    my $result = $bb_empty;

    for my $delta (@$deltas) {
        my $s = $sqr;
        while (1) {
            $s += $delta;
            last unless ($s >= 0 && $s < 64);
            last if (_square_distance($s, $s - $delta) > 2);
            $result = $result | ~$bb_squares[$s];
            last if $occupied & ~$bb_squares[$s];
        }
    }

    $result;
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
    ($bb << 8) & $bb_all;
}

sub _edges { ## no critic (Subroutines::RequireArgUnpacking)
    my $sqr = $_[0];
    return ((($bb_rank_1 | $bb_rank_8) & ~$bb_ranks[_square_rank($sqr) ]) |
            (($bb_file_a | $bb_file_h) & ~$bb_files[_square_file($sqr)]));
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
    for (my $a = 0; $a < @bb_squares; $a++) {
        my $bb_a = ~$bb_squares[$a];
        my @rays_row;
        for (my $b = 0; $b < @bb_squares; $b++) {
            my $bb_b = ~$bb_squares[$b];
            if ($$BB_DIAG_ATTACKS[$a]->{0} & $bb_b) {
                push @rays_row, $$BB_DIAG_ATTACKS[$a]->{0} & $$BB_DIAG_ATTACKS[$b]->{0} | $bb_a | $bb_b;
            }
            elsif ($$BB_RANK_ATTACKS[$a]->{0} & $bb_b) {
                push @rays_row, $$BB_RANK_ATTACKS[$a]->{0} | $bb_a;
            }
            elsif ($$BB_FILE_ATTACKS[$a]->{0} & $bb_b) {
                push @rays_row, $$BB_FILE_ATTACKS[$a]->{0} | $bb_a;
            }
            else {
                push @rays_row, $bb_empty;
            }
        }
        push @rays, \@rays_row;
    }
    \@rays;
}

my $BB_RAYS = _rays();

sub _ray {
    my ($a, $b) = @_;
    my $aref = $$BB_RAYS[$a];
    $$aref[$b];
}

sub _between {
    my ($a, $b) = @_;
    my $aref = $$BB_RAYS[$a];
    my $bb = $$aref[$b] & (($bb_all << $a) ^ ($bb_all << $b));
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
                               r => BR, n => BN, b => BB, q => BQ, k => BK,  p => BP,
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

    unless ($pos->{bb}{WK()} & ~$bb_squares[E1()]) {
        $white_castling = 0;
    }
    unless ($pos->{bb}{BK()} & ~$bb_squares[E8()]) {
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
        $pawn_mask       = _shift_down($bb_squares[$pos->{ep_square}]);
        $seventh_rank_mask = _shift_up($bb_squares[$pos->{ep_square}]);
    }
    else {
        $ep_rank = RANK_3;
        $pawn_mask           = _shift_up($bb_squares[$pos->{ep_square}]);
        $seventh_rank_mask = _shift_down($bb_squares[$pos->{ep_square}]);        
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
    if ($pos->{bb}{all} & $bb_squares[$pos->{ep_square}]) {
        return undef;
    }
    # square that was just emptied by the last move
    if ($pos->{bb}{all} & $seventh_rank_mask) {
        return undef;
    }
    # OK
    return $pos->{ep_square};
}

sub _build_bitboards_from_table {
    #  bb goes from a1-h1, a2-h2, ..., a8-h8
    my $pos = shift;
    
    for my $p (WP .. BK) {
        $pos->{bb}{$p} = 0;
    }
    for my $sq (0..63) {
        my $pc = $pos->{table}[$sq];
        next if $pc == EMPTY;
        $pos->{bb}{$pc} |= 1 << ($sq);
    }
    
    $pos->{bb}{White} = 0;
    $pos->{bb}{Black} = 0;
    for my $p (WP .. WK) {
        $pos->{bb}{White} |=  $pos->{bb}{$p};
    }
    for my $p (BP .. BK) {
        $pos->{bb}{Black} |=  $pos->{bb}{$p};
    }
    $pos->{bb}{all} = $pos->{bb}{White}
                    | $pos->{bb}{Black};
}

# use for looping over set bits = squares
sub _pop_lsb_index {
    my (undef, $bbref) = @_;

    my $bb = $$bbref;
    return -1 if $bb == 0;

    # isolate least significant 1 bit
    my $lsb = $bb & (-$bb);

    # remove it
    $$bbref = $bb ^ $lsb;

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
    return $pos->{to_move} eq 'w' ? $pos->{bb}{White} : $pos->{bb}{Black};
}

sub _opponent { ## no critic (Subroutines::RequireArgUnpacking)
    return $_[0]->{to_move} eq 'w' ? 'b' : 'w';
}

# a debugging aid, use from unit tests
sub _check_consistency {
    my $pos = shift;

    # keys = squares, values = pieces
    my %h_table;
    my %h_bb;

    for my $pcs (WP .. BK) {
        my $i = 0;
        while ($i <= 63) {
            if ($pcs == $pos->{table}[$i]) {
                $h_table{$i} = $pcs;
            }
            $i++;
        }
        my $work_bits = $pos->{bb}{$pcs};
        #_print_bb($work_bits);
        while ($work_bits) {
            my $sq = $pos->_pop_lsb_index(\$work_bits);
            $h_bb{$sq} = $pcs;
        }
    }

    my $bb_size = keys %h_bb;
    my $tb_size = keys %h_table;
    
    if ($bb_size != $tb_size) {
        warn "bitboard has $bb_size elements, table has $tb_size elements";
        warn "table: " . join (',', sort keys %h_table);
        warn "bitboard:" . join (',', sort keys %h_bb);    
        return 0;
    }
    
    for my $key (keys %h_table) {
        if (not exists $h_bb{$key}) {
            warn "Square $key found in table but not in bitboard";
            return 0;
        } elsif ($h_table{$key} != $h_bb{$key}) {
            warn "Square $key points to $h_table{$key} in table but to $h_bb{$key} in bitboard";
            return 0;
        }
    }

    return 1;
}

sub _get_attackers {
    # get the attackers from side on square
    my ($pos, $side, $square, $occupied) = @_;

    my $attackers = $bb_king_attacks[$square] & ($side eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()});
    $attackers |= $bb_knight_attacks[$square] & ($side eq 'w' ? $pos->{bb}{WN()} : $pos->{bb}{BN()});
    $attackers |= $bb_pawn_attacks_b[$square] & $pos->{bb}{WP()} if $side eq 'w';
    $attackers |= $bb_pawn_attacks_w[$square] & $pos->{bb}{BP()} if $side eq 'b';

    $occupied //= $pos->{bb}{all};
    
    my $rank_pieces = $$BB_RANK_MASKS[$square] & $occupied;
    my $file_pieces = $$BB_FILE_MASKS[$square] & $occupied;
    my $diag_pieces = $$BB_DIAG_MASKS[$square] & $occupied;

    my $queens_and_rooks   =  ($side eq 'w' ? $pos->{bb}{WR()} | $pos->{bb}{WQ()} : $pos->{bb}{BR()} | $pos->{bb}{BQ()});
    my $queens_and_bishops =  ($side eq 'w' ? $pos->{bb}{WB()} | $pos->{bb}{WQ()} : $pos->{bb}{BB()} | $pos->{bb}{BQ()});
    
    $attackers |= $$BB_RANK_ATTACKS[$square]->{$rank_pieces} & $queens_and_rooks;
    $attackers |= $$BB_FILE_ATTACKS[$square]->{$file_pieces} & $queens_and_rooks;
    $attackers |= $$BB_DIAG_ATTACKS[$square]->{$diag_pieces} & $queens_and_bishops;        
    
    return $attackers;
}

sub _attacked_for_king {
    # return true iff any of the squares in bb are attacked by the side NOT to move
    my ($pos, $bb, $occupied) = @_;
    my $_bb = $bb;
    while ($_bb) {
        my $sq = $pos->_pop_lsb_index(\$_bb);
        my $side = ($pos->{to_move} eq 'w' ? 'b' : 'w');
        if ($pos->_get_attackers($side, $sq, $occupied)) {
            return 1;
        }
    }
    return 0;
}

sub _generate_castling_moves {
    my $pos = shift;
    my $result = shift; # array ref to which moves will be added
    my $from_bb_filter = shift;
    my $to_bb_filter = shift;

    my $side = $pos->{to_move};
    my $backrank = ($side eq 'w' ? $bb_rank_1 : $bb_rank_8);
    my $king = ($side eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()});
    $king &= $from_bb_filter;

    return unless $king;
    
    my $bb_c = $bb_file_c & $backrank;
    my $bb_d = $bb_file_d & $backrank;
    my $bb_f = $bb_file_f & $backrank;
    my $bb_g = $bb_file_g & $backrank;

    my $candidates = $pos->_clean_castling_rights() & $backrank;
    while ($candidates) {
        my $candi = $pos->_pop_lsb_index(\$candidates);
        my $rook = ~$bb_squares[$candi];
        my $q_side = $rook < $king;
        my $king_to = ($q_side ? $bb_c : $bb_g);
        my $rook_to = ($q_side ? $bb_d : $bb_f);
        my $king_path = _between(_msb($king), _msb($king_to));
        my $rook_path = _between($candi, _msb($rook_to));

        unless ( ($king ^ $rook ^ $pos->{bb}{all}) & ($king_path | $rook_path | $king_to | $rook_to)
                 || ($pos->_attacked_for_king($king_path | $king, $king ^ $pos->{bb}{all}))
                 || ($pos->_attacked_for_king($king_to, $king ^ $rook ^ $rook_to ^ $pos->{bb}{all})) ) {
            my $from = _msb($king);
            if ($from == E1 && $pos->{bb}{WK()} & $bb_e1) {
                push (@$result, Chess4p::Move->new(E1, G1)) if $candi == H1;
                push (@$result, Chess4p::Move->new(E1, C1)) if $candi == A1;
            }
            elsif ($from == E8 && $pos->{bb}{BK()} & $bb_e8) {
                push (@$result, Chess4p::Move->new(E8, G8)) if $candi == H8;
                push (@$result, Chess4p::Move->new(E8, C8)) if $candi == A8;
            }
        }
    }
}

sub _ep_skewered {
    # Handle the special case where the king would be in check if the
    # pawn and its capturer both disappear from the rank.
    # capturer = from square of the e.p.-capturing pawn.
    # Vertical skewers of the captured pawn are not possible.
    # Pins on the capturer are not handled elsewhere.
    my ($pos, $king, $capturer) = @_;
    croak "check for skewered e.p. done without e.p. square" unless $pos->{ep_square};

    my $last_double = $pos->{ep_square} + ($pos->{to_move} eq 'w' ? -8 : 8);
    my $occupancy = $pos->{bb}{all} & $bb_squares[$last_double] & $bb_squares[$capturer]
                  | ~$bb_squares[$pos->{ep_square}];

    # Horizontal attack on the fifth or fourth rank.
    my $horizontal_attackers;
    if ($pos->{to_move} eq 'w') {
        $horizontal_attackers = $pos->{bb}{BQ()} | $pos->{bb}{BR()};
    }
    else {
        $horizontal_attackers = $pos->{bb}{WQ()} | $pos->{bb}{WR()};
    }
    return 1 if ($$BB_RANK_ATTACKS[$king]->{$occupancy & $$BB_RANK_MASKS[$king]} & $horizontal_attackers);

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
    return 1 if ($$BB_DIAG_ATTACKS[$king]->{$occupancy & $$BB_DIAG_MASKS[$king]} & $diagonal_attackers);

    return 0;
}

sub _is_ep_move {
    my ($pos, $move) = @_;

    return 0 unless $pos->{ep_square};
    
    # Check if the given (pseudo-legal) move is an e.p. capture.
    my $pawns = $pos->{bb}{WP()} | $pos->{bb}{BP()};
    my $diff = abs($move->to() - $move->from());

    return ($pos->{ep_square} == $move->to() &&
            ($pawns & ~$bb_squares[$move->from()]) &&
            ($diff == 7 || $diff == 9) &&
            !($pos->{bb}{all} & ~$bb_squares[$move->to()]));
}

sub _pin_mask {
    my ($pos, $side, $square) = @_;
    
    my $king = $side eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()};
    $king = _msb($king);
    return $bb_all if not $king;

    my $square_mask = ~$bb_squares[$square];
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
            my $snipers = $rays & $sliders & ($side eq 'w' ? $pos->{bb}{Black} : $pos->{bb}{White});
            while ($snipers) {
                my $sniper = $pos->_pop_lsb_index(\$snipers);
                my $occupied_with_square = $pos->{bb}{all} | $square_mask;
                my $mask = _between($sniper, $king) & $occupied_with_square;
                return _ray($king, $sniper) if $mask == $square_mask;
            }
        }
    }
    
    return $bb_all;
}

sub _is_safe {
    # is the move safe?
    # it's assumed that if the king was in check before the move, then the move evades that check
    my ($pos, $king, $blockers, $from, $to) = @_;
    if ($from == $king) {
        # castling
        my $opponent = $pos->{to_move} eq 'w' ? 'b' : 'w';
        return 1 if _square_distance($from, $to) > 1;
        return 1 if $pos->_get_attackers($opponent, $to) == $bb_empty;
        return 0; # $to is attacked by opponent
    }
    elsif ($pos->_is_ep_move(Chess4p::Move->new($from, $to))) {
        my $result = $pos->_pin_mask($pos->{to_move}, $from) & ~$bb_squares[$to];
        return $result && !$pos->_ep_skewered($king, $from);
    }
    else {
        return 1 unless $blockers & ~$bb_squares[$from]; # the piece was not blocking a check -> YES
        return 1 if _ray($from, $to) & ~$bb_squares[$king]; # the blocker keeps blocking -> YES
        return 0; # it's a blocker, and this move would unblock -> NO
    }
}

sub _is_zeroing {
    # Check if given pseudo-legal move is capture or pawn move
    my ($pos, $move) = @_;
    my $touched = ~$bb_squares[$move->from()] ^ ~$bb_squares[$move->to()];
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
      $pos->{bb}{White},
      $pos->{bb}{Black};
    for my $pcs (WP .. BK) {
        $out .= $pos->{bb}{$pcs} // 'undef';
    }
    for my $sqr (A1 .. H8) {
        $out .= $pos->{table}[$sqr];
    }
    my $sz = 0;
    $sz = @{$pos->{stack}} if $pos->{stack};
    $out .= $sz;
    $sz = 0;
    $sz = @{$pos->{move_stack}} if $pos->{move_stack};
    $out .= $sz;
    $out;
}

  
### Constructors

sub _new {
    my ($class, $pos) = @_;
    return bless $pos, $class;
}

sub empty {
    my ($class) = @_;

    my $pos = {};
    $pos->{table} = [ (EMPTY) x 64 ];
    $pos->{to_move} = 'w';
    $pos->{castling_rights} = $bb_empty;
    $pos->{halfmove_clock}  = 0;
    $pos->{fullmove_number} = 1;
    $pos->{stack} = ();
    $pos->{move_stack} = ();

    _build_bitboards_from_table($pos);
    
    return $class->_new($pos);
}

sub fromFen {
    my ($class, $fen) = @_;

    my $pos = {};

    if (not defined $fen) {
        # default position
        # table goes from a1-h1, a2-h2, ..., a8-h8
        $pos->{table} = [WR,WN,WB,WQ,WK,WB,WN,WR,
                         (WP) x 8, (EMPTY) x 32, (BP) x 8,
                         BR,BN,BB,BQ,BK,BB,BN,BR
                        ];
        $pos->{to_move} = 'w';
        $pos->{castling_rights} = ~$bb_squares[A1] | ~$bb_squares[H1] | ~$bb_squares[A8] | ~$bb_squares[H8];
        $pos->{halfmove_clock}  = 0;
        $pos->{fullmove_number} = 1;
    }
    else {
        my @parts = split / /, $fen;

        my @rows = split "/", $parts[0];

        if ($#rows != 7) {
            # missing rows - pad with empty squares
            for (0 .. 6 - $#rows) {
                push @rows, "8";
            }
        }

        $pos->{to_move} = $parts[1];

        $pos->{castling_rights} = $bb_empty;
        if (defined $parts[2]) {
            $pos->{castling_rights} |= ~$bb_squares[H1] if $parts[2] =~ /K/;
            $pos->{castling_rights} |= ~$bb_squares[A1] if $parts[2] =~ /Q/;
            $pos->{castling_rights} |= ~$bb_squares[H8] if $parts[2] =~ /k/;        
            $pos->{castling_rights} |= ~$bb_squares[A8] if $parts[2] =~ /q/;
        }

        if (defined $parts[2]) {
            if ($parts[3] eq '-') {
                $pos->{ep_square} = undef;
            } else {
                $pos->{ep_square} = $square_numbers{$parts[3]};
            }
        }

        $pos->{halfmove_clock}  = $parts[4];
        $pos->{fullmove_number} = $parts[5];
        
        for my $row (0 .. $#rows) { # 8th row first in, Q before K
            my $i = 64 - (($row + 1) * 8);
            my @items = split //, $rows[$row];
            for my $col (0 .. $#items) {
                if ($items[$col] =~ /(\d+)/) {
                    # empty squares
                    for my $j (1 .. $1) {
                        $pos->{table}[$i++] = EMPTY;
                    }
                } else {
                    $pos->{table}[$i++] = $fen_chars_to_piece_code{$items[$col]};
                }
            }
        }
    }

    $pos->{stack} = ();
    $pos->{move_stack} = ();

    _build_bitboards_from_table($pos);
    
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
        return $pos->{castling_rights} & ~$bb_squares[H1];
    } else {
        return $pos->{castling_rights} & ~$bb_squares[H8];
    }
}

sub queenside_castling_right {  ## no critic (Subroutines::RequireArgUnpacking)
    my $pos = $_[0];
    if ($_[1] eq 'w') {
        return $pos->{castling_rights} & ~$bb_squares[A1];
    } else {
        return $pos->{castling_rights} & ~$bb_squares[A8];
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
    for (my $row = 7; $row >= 0; $row--) {
        for (my $col = 0; $col <= 7; $col++) {
            my $i = $row * 8 + $col;
            if ($pos->{table}[$i] == EMPTY) {
                $result .= ".";
            } else {
                $result .= "$fen_chars[$pos->{table}[$i]]";
            }
            if ($col < 7) {
                $result .= " ";
            }
        }
        if ($row > 0) {
            $result .= "\n";
        }
    }
    return $result;
}

sub fen {
    my $pos = shift;
    my $result = "";
    my $empties = 0;
    for my $sqr (@squares_180) {
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
        if (~$bb_squares[$sqr] & $bb_file_h) {
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

    $result .= " $pos->{to_move} $castling $ep $pos->{halfmove_clock} $pos->{fullmove_number}";
    
    return $result;
}

sub piece_at {
    my ($pos, $i) = @_;
    return $fen_chars[$pos->{table}[$i]];
}

sub set_piece_at {
    my ($pos, $sqr, $pcs) = @_;
    $pos->remove_piece_at($sqr);
    $pos->{table}[$sqr] = $pcs;
    my $mask = ~$bb_squares[$sqr];
    $pos->{bb}{$pcs} |= $mask;

    # update other bb's
    if ($pcs <= 6) {
        $pos->{bb}{White} |= $mask;
        $pos->{bb}{all}   |= $mask;
    }
    else {
        $pos->{bb}{Black} |= $mask;
        $pos->{bb}{all}   |= $mask;
    }
}

sub remove_piece_at {
    my ($pos, $sqr) = @_;
    my $pcs = $pos->{table}[$sqr];
    return EMPTY if $pcs == EMPTY;

    # set 0 in bb for that square
    my $mask = $bb_squares[$sqr];
    $pos->{bb}{$pcs} &= $mask;

    # clear square in table too
    $pos->{table}[$sqr] = EMPTY;

    # update other bb's
    if ($pcs <= 6) {
        $pos->{bb}{White} &= $mask;
        $pos->{bb}{all}   &= $mask;
    }
    else {
        $pos->{bb}{Black} &= $mask;
        $pos->{bb}{all}   &= $mask;
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
    if ($pos->_bb_count_1s('White') > 16) {
        return "Too many White stones";
    }
    if ($pos->_bb_count_1s('Black') > 16) {
        return "Too many Black stones";
    }
    if (($pos->{bb}{WP()} | $pos->{bb}{BP()}) & ($bb_rank_1 | $bb_rank_8)) {
        return "Pawns on back rank";
    }
    if ($pos->_was_into_check()) {
        return "Self in check";
    }

    my $valid_ep_sqr = $pos->_valid_ep_square();
    if ($pos->{ep_square}) {
        if (! defined $valid_ep_sqr || $valid_ep_sqr != $pos->{ep_square}) {
            return "Invalid e.p. square";
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
    my $to_bb_filter = shift;
    $from_bb_filter //= $bb_all;
    $to_bb_filter //= $bb_all;
    # closure state
    my $ep_capturers;
    if ($pos->{ep_square}) {
        if ($bb_squares[$pos->{ep_square}] & ~$pos->{bb}{all}) { # empty target square
            $ep_capturers = $pos->{to_move} eq 'w'
                            ? $pos->{bb}{WP()} & $bb_pawn_attacks_b[$pos->{ep_square}] & $bb_rank_5 
                            : $pos->{bb}{BP()} & $bb_pawn_attacks_w[$pos->{ep_square}] & $bb_rank_4;
        }
    }
    my $pawn_capturers = $pos->{to_move} eq 'w' ? $pos->{bb}{WP()} : $pos->{bb}{BP()};
    my $targets;
    my $_sq;
    if ($pawn_capturers) {
        $_sq = $pos->_pop_lsb_index(\$pawn_capturers);
        $targets = $pos->{to_move} eq 'w' ? $bb_pawn_attacks_w[$_sq] & $pos->{bb}{Black} : $bb_pawn_attacks_b[$_sq] & $pos->{bb}{White};
        $targets &= $to_bb_filter;
    }
    my $promo_index = 0;
    my $promo_from;
    my $promo_to;
    my @promo = qw (Q R B N);
    my $single_moves = undef;
    my $double_moves = undef;
    if ($pos->{to_move} eq 'w') {
        $single_moves = $pos->{bb}{WP()} << 8 & ~$pos->{bb}{all};
        $double_moves = $single_moves << 8 & ~$pos->{bb}{all} & $bb_rank_4;
    }
    else {
        $single_moves = $pos->{bb}{BP()} >> 8 & ~$pos->{bb}{all};
        $double_moves = $single_moves >> 8 & ~$pos->{bb}{all} & $bb_rank_5;
    }
    $single_moves &= $to_bb_filter;
    $double_moves &= $to_bb_filter;

    my @castling_moves;
    $pos->_generate_castling_moves(\@castling_moves, $from_bb_filter, $to_bb_filter);

    # non-pawn moves
    # work_bits is a bitboard of potential from-squares
    my $work_bits =  $pos->{to_move} eq 'w' ? $pos->{bb}{White} & ~$pos->{bb}{WP()} : $pos->{bb}{Black} & ~$pos->{bb}{BP()};
    $work_bits &= $from_bb_filter;
    my $attack_bits;
    my $sq;
    my $pcs;

    return sub {
        if ($promo_index > 0 && $promo_index < 4) {
            my $result = Chess4p::Move->new($promo_from, $promo_to, $promo[$promo_index++]);
            $promo_index = 0 if $promo_index == 4; # in case of 2 capturing targets on 1st/8th rank
            return $result;
        }
        if ($ep_capturers) {
            my $sq = $pos->_pop_lsb_index(\$ep_capturers);
            return Chess4p::Move->new($sq, $pos->{ep_square});
        }

        while ($pawn_capturers && !$targets) {
            # try for a capturer with any target...
            $_sq = $pos->_pop_lsb_index(\$pawn_capturers);
            $targets = $pos->{to_move} eq 'w' ? $bb_pawn_attacks_w[$_sq] & $pos->{bb}{Black} : $bb_pawn_attacks_b[$_sq] & $pos->{bb}{White};
            $targets &= $to_bb_filter;
        }
        
        if ($pawn_capturers || $targets) {
            my $to = $pos->_pop_lsb_index(\$targets);                
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
            my $to = $pos->_pop_lsb_index(\$single_moves);
            my $sq = $pos->{to_move} eq 'w' ? $to - 8 : $to + 8;
            my $rk = _square_rank($to);
            if ($rk == RANK_1 || $rk == RANK_8) {
                $promo_from = $sq;#$_sq;
                $promo_to = $to;
                return Chess4p::Move->new($promo_from, $promo_to, $promo[$promo_index++]);
            } else {
                return Chess4p::Move->new($sq, $to);
            }
        }
        if ($double_moves) {
            my $to = $pos->_pop_lsb_index(\$double_moves);
            my $sq = $pos->{to_move} eq 'w' ? $to - 16 : $to + 16;
            return Chess4p::Move->new($sq, $to);
        }
        
        while ($work_bits || $attack_bits) {
            if (!$attack_bits) {
                $sq  = $pos->_pop_lsb_index(\$work_bits);
                $pcs = $pos->{table}[$sq];
                if ($pcs == WN || $pcs == BN) {
                    $attack_bits = $bb_knight_attacks[$sq];
                } elsif ($pcs == WK || $pcs == BK) {
                    $attack_bits = $bb_king_attacks[$sq];
                } elsif ($pcs == WB || $pcs == BB) {
                    $attack_bits = $$BB_DIAG_ATTACKS[$sq]->{$$BB_DIAG_MASKS[$sq] & $pos->{bb}{all}};
                } elsif ($pcs == WR || $pcs == BR) {
                    $attack_bits  = $$BB_RANK_ATTACKS[$sq]->{$$BB_RANK_MASKS[$sq] & $pos->{bb}{all}};
                    $attack_bits |= $$BB_FILE_ATTACKS[$sq]->{$$BB_FILE_MASKS[$sq] & $pos->{bb}{all}};
                } elsif ($pcs == WQ || $pcs == BQ) {
                    $attack_bits  = $$BB_RANK_ATTACKS[$sq]->{$$BB_RANK_MASKS[$sq] & $pos->{bb}{all}};
                    $attack_bits |= $$BB_FILE_ATTACKS[$sq]->{$$BB_FILE_MASKS[$sq] & $pos->{bb}{all}};
                    $attack_bits |= $$BB_DIAG_ATTACKS[$sq]->{$$BB_DIAG_MASKS[$sq] & $pos->{bb}{all}};
                }
                $attack_bits &= $to_bb_filter;
            }
            while ($attack_bits) {
                my $to = $pos->_pop_lsb_index(\$attack_bits);
                if ($pos->{table}[$to] == EMPTY || ($pos->{to_move} eq 'w' ? $pos->{table}[$to] >= 7 : $pos->{table}[$to] < 7)) {
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

sub _evasions_iter {
    my ($pos, $king, $checkers) = @_;
    my $sliders = $checkers & ($pos->{bb}{WQ()} | $pos->{bb}{BQ()} | ($pos->{bb}{WR()}) | ($pos->{bb}{BR()}) | ($pos->{bb}{WB()}) | ($pos->{bb}{BB()}) );
    my $attacked = $bb_empty;
    my $one_checker = _msb($checkers);
    my $target;
    if (~$bb_squares[$one_checker] == $checkers) {
        # a single checker
        # target squares: block or capture the checker
        $target = _between($king, $one_checker) | $checkers;          
    }
    my $block_iter;
    if ($target) {
        # set up iterator
        $block_iter = $pos->_pseudo_legal_moves_iter(~_make_bb($king), $target);
    }
    while ($sliders) {
        my $checker = $pos->_pop_lsb_index(\$sliders);
        $attacked |= _ray($king, $checker) & $bb_squares[$checker];
    }
    my $our_stones = ($pos->{to_move} eq 'w' ? $pos->{bb}{White} : $pos->{bb}{Black});
    # bitboard for the king's flight squares
    my $move_away_bb = $bb_king_attacks[$king] & ~$attacked & ~$our_stones;
    
    return sub {
        while ($move_away_bb) {
            my $sq = $pos->_pop_lsb_index(\$move_away_bb);
            return Chess4p::Move->new($king, $sq);
        }
        if ($target) {
            while (defined(my $m = $block_iter->())) {
                return $m;
            }
        }
        return undef;
    }
}

sub _slider_blockers {
    my ($pos, $king) = @_;
    my $opponent = $pos->{to_move} eq 'w' ? 'b' : 'w';
    my $rooks_queens =   $opponent eq 'w' ? $pos->{bb}{WQ()} : $pos->{bb}{BQ()};
    $rooks_queens |=     $opponent eq 'w' ? $pos->{bb}{WR()} : $pos->{bb}{BR()};
    my $bishops_queens = $opponent eq 'w' ? $pos->{bb}{WQ()} : $pos->{bb}{BQ()};
    $bishops_queens |=   $opponent eq 'w' ? $pos->{bb}{WB()} : $pos->{bb}{BB()};
    my $snipers = (($$BB_RANK_ATTACKS[$king]->{0} & $rooks_queens) |
                   ($$BB_FILE_ATTACKS[$king]->{0} & $rooks_queens) |
                   ($$BB_DIAG_ATTACKS[$king]->{0} & $bishops_queens));
    my $blockers = $bb_empty;
    while ($snipers) {
        my $sq = $pos->_pop_lsb_index(\$snipers);
        # bb is the blocking stones
        my $bb = _between($king, $sq) & $pos->{bb}{all};
        # Add to blockers if exactly one piece in-between.
        if ($bb && (~$bb_squares[_msb($bb)] == $bb)) {
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
    my ($pos) = @_;
    my $moves_iter = $pos->_pseudo_legal_moves_iter();
    
    my $side = $pos->{to_move};
    my $opponent = $side eq 'w' ? 'b' : 'w';
    my $king = $side eq 'w' ? $pos->{bb}{WK()} : $pos->{bb}{BK()};
    $king = _msb($king);
    my $blockers = $pos->_slider_blockers($king);
    my $checkers = $pos->_get_attackers($opponent, $king);
    my $evasions_iter = $pos->_evasions_iter($king, $checkers);

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

sub push_move {
    my ($pos, $move) = @_;
    $pos->{castling_rights} = $pos->_clean_castling_rights();
    push (@{$pos->{move_stack}}, $move);
    my @table;
    for my $sqr (A1..H8) {
        $table[$sqr] = $pos->{table}[$sqr];
    }
    my %bitboards;
    $bitboards{WK()} = $pos->{bb}{WK()};
    $bitboards{WQ()} = $pos->{bb}{WQ()};
    $bitboards{WR()} = $pos->{bb}{WR()};
    $bitboards{WB()} = $pos->{bb}{WB()};
    $bitboards{WN()} = $pos->{bb}{WN()};
    $bitboards{WP()} = $pos->{bb}{WP()};
    $bitboards{BK()} = $pos->{bb}{BK()};
    $bitboards{BQ()} = $pos->{bb}{BQ()};
    $bitboards{BR()} = $pos->{bb}{BR()};
    $bitboards{BB()} = $pos->{bb}{BB()};
    $bitboards{BN()} = $pos->{bb}{BN()};
    $bitboards{BP()} = $pos->{bb}{BP()};
    $bitboards{White} = $pos->{bb}{White};
    $bitboards{Black} = $pos->{bb}{Black};
    $bitboards{all} = $pos->{bb}{all};    
    
    my %state = (to_move => $pos->{to_move},
                 castling_rights => $pos->{castling_rights},
                 halfmove_clock => $pos->{halfmove_clock},
                 fullmove_number => $pos->{fullmove_number},
                 bitboards => \%bitboards,
                 table => \@table,
                 ep_square => $pos->{ep_square},
                );
    push (@{$pos->{stack}}, \%state);
    my $ep_square = $pos->{ep_square};
    $pos->{ep_square} = undef;
    $pos->{halfmove_clock}++;
    $pos->{fullmove_number}++ if $pos->{to_move} eq 'b';
    unless ($move) {
        # null move - swap turns and reset en passant square.
        $pos->{to_move} = $pos->{to_move} eq 'w' ? 'b' : 'w';
        return;
    }
    # reset halfmove clock if needed
    $pos->{halfmove_clock} = 0 if $pos->_is_zeroing($move);
    my $from_bb = ~$bb_squares[$move->from()];
    my $to_bb = ~$bb_squares[$move->to()];
    # promoted = pos->promoted & from_bb
    my $pcs = $pos->remove_piece_at($move->from());
    croak "push needs a pseudo-legal move, but got $move" unless $pcs;
    my $capture_sqr  = $move->to();
    my $captured_pcs = $pos->piece_at($capture_sqr);
    # NNN eq   '.' for empty !!
    # TODO maybe that should be changed

    # Update castling rights
    $pos->{castling_rights} &= ~$to_bb & ~$from_bb;
    if (($pcs == WK || $pcs == BK)) { # && ! promoted
        $pos->{castling_rights} &= ~$bb_rank_1 if $pos->{to_move} eq 'w';
        $pos->{castling_rights} &= ~$bb_rank_8 if $pos->{to_move} eq 'b';
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
        #        promoted = 1;
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
    my $move = pop @{$pos->{move_stack}};
    my $href = pop @{$pos->{stack}};
    $pos->{to_move} = $href->{to_move};
    $pos->{castling_rights} = $href->{castling_rights};
    $pos->{halfmove_clock} = $href->{halfmove_clock};
    $pos->{fullmove_number} = $href->{fullmove_number};
    $pos->{bb} = $href->{bitboards};
    $pos->{table} = $href->{table};
    $pos->{ep_square} = $href->{ep_square};
    return $move;
}

sub apply_mirror {
    my ($pos) = @_;
    for my $sqr (A1 .. H4) {
        my $sqr_m = _square_mirror($sqr);
        ($pos->{table}[$sqr], $pos->{table}[$sqr_m]) = ($pos->{table}[$sqr_m], $pos->{table}[$sqr]);
    }
    for my $sqr (A1 .. H8) {
        if ($pos->{table}[$sqr] == BP) {
            $pos->{table}[$sqr] = WP;
        }
        elsif ($pos->{table}[$sqr] == WP) {
            $pos->{table}[$sqr] = BP;
        }
        elsif ($pos->{table}[$sqr] == WK) {
            $pos->{table}[$sqr] = BK;
        }
        elsif ($pos->{table}[$sqr] == BK) {
            $pos->{table}[$sqr] = WK;
        }
        elsif ($pos->{table}[$sqr] == WQ) {
            $pos->{table}[$sqr] = BQ;
        }
        elsif ($pos->{table}[$sqr] == BQ) {
            $pos->{table}[$sqr] = WQ;
        }
        elsif ($pos->{table}[$sqr] == WN) {
            $pos->{table}[$sqr] = BN;
        }
        elsif ($pos->{table}[$sqr] == BN) {
            $pos->{table}[$sqr] = WN;
        }
        elsif ($pos->{table}[$sqr] == WR) {
            $pos->{table}[$sqr] = BR;
        }
        elsif ($pos->{table}[$sqr] == BR) {
            $pos->{table}[$sqr] = WR;
        }
        elsif ($pos->{table}[$sqr] == WB) {
            $pos->{table}[$sqr] = BB;
        }
        elsif ($pos->{table}[$sqr] == BB) {
            $pos->{table}[$sqr] = WB;
        }
    }
    $pos->{to_move} = $pos->_opponent();
    $pos->{castling_rights} = _flip_vertical($pos->{castling_rights});
    $pos->{ep_square} = _square_mirror($pos->{ep_square}) if $pos->{ep_square};

    # TODO
    # use _flip_vertical when table is ditched later

    _build_bitboards_from_table($pos);

    # TODO
    # decide whether to clear move stack and state stack
}



1;

__END__

=encoding utf8

=head1 NAME

Board - Chess board class

=head1 SYNOPSIS

    use Board;

    my $board = Board->fromFen($fen);

    print $board->ascii();

=head1 DESCRIPTION

Board provides Board objects.

=head1 METHODS


=head2 fromFen($fen)

Constructor.
Create a Board from a FEN string (Forsyth–Edwards Notation).
If the input $fen is empty, use the conventional start position.

=head2 empty()

Constructor.
Create an empty Board.

=head2 fen()

Get the FEN for this board position.

=head2 errors()

Return undef if position is valid.
Otherwise, a string describing the error.

=head2 ascii()

Write the board as ASCII.

=head2 legal_moves_iter()

Get an iterator over the legal moves from this position.

=head2 legal_moves()

Get legal moves from this position.

=head2 push_move($move)

Update with the given *move* and push it to the move
Moves are not checked for legality. It is the caller's
responsibility to ensure that the move is at least pseudo-legal or
a null move.
Null moves just increment the move counters, switch turns and forfeit
en passant capturing.

=head2 pop_move()

Restore previous position and return last move from stack.
If move stack is empty, no-op and return undef.

=head2 piece_at($square)

Get the piece at given square.

=head2 remove_piece_at($square)

Remove the piece at given square.
If square is empty, does nothing.

=head2 set_piece_at($square, $piece)

Put given piece/pawn on given square.
Any existing piece/pawn on that square is removed.

=head2 kingside_castling_right($side)

Is kingside castling allowed for the given side?

$side = 'w' or 'b'

=head2 queenside_castling_right($side)

Is queenside castling allowed for the given side?

$side = 'w' or 'b'

=head2 ep_square()

En passant capture square, or undef if N/A

=head2 fullmove_number()

Counts move pairs. Starts at 1, increments after every
Black move.

=head2 halfmove_clock()

Number of ply since last capture or pawn move.

=head2 apply_mirror()

Mirror this board vertically.


=head1 AUTHOR

Ejner Borgbjerg

=head1 LICENSE

Perl Artistic License, GPL

=cut
