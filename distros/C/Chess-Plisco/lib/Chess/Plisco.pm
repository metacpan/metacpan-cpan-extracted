#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Portions of this code have been ported from C code that has the following
# copyright notice:

# Copyright (C) 2007 Pradyumna Kannan.
#
# This code is provided 'as-is', without any express or implied warranty.
# In no event will the authors be held liable for any damages arising from
# the use of this code. Permission is granted to anyone to use this
# code for any purpose, including commercial applications, and to alter
# it and redistribute it freely, subject to the following restrictions:
# 
# 1. The origin of this code must not be misrepresented; you must not
# claim that you wrote the original code. If you use this code in a
# product, an acknowledgment in the product documentation would be
# appreciated but is not required.
# 
# 2. Altered source versions must be plainly marked as such, and must not be
# misrepresented as being the original code.
# 
# 3. This notice may not be removed or altered from any source distribution.

# Make Dist::Zilla happy.
# ABSTRACT: Representation of a chess position with move generator, legality checker etc.

# Welcome to the world of spaghetti code!  It is deliberately ugly because
# trying to avoid function/method call overhead is one of the major goals.
# In the future it may make sense to try to make the code more readable by
# more extensive use of Chess::Plisco::Macro.

package Chess::Plisco;
$Chess::Plisco::VERSION = '0.6';
use strict;
use integer;
no warnings qw(portable);
use overload '""' => sub { shift->toFEN };
no warnings qw(uninitialized);

use Locale::TextDomain qw('Chess-Plisco');
use Scalar::Util qw(reftype);
use Config;

# Macros from Chess::Plisco::Macro are already expanded here!

use base qw(Exporter);

# Colors.
use constant CP_WHITE => 0;
use constant CP_BLACK => 1;

# Piece constants.
use constant CP_NO_PIECE => 0;
use constant CP_PAWN => 1;
use constant CP_KNIGHT => 2;
use constant CP_BISHOP => 3;
use constant CP_ROOK => 4;
use constant CP_QUEEN => 5;
use constant CP_KING => 6;
use constant CP_PAWN_VALUE => 100;
use constant CP_KNIGHT_VALUE => 320;
use constant CP_BISHOP_VALUE => 330;
use constant CP_ROOK_VALUE => 500;
use constant CP_QUEEN_VALUE => 900;

# Accessor indices.  The layout is selected in such a way that piece types
# can be used directly as indices in order to get the corresponding bitboard,
# and getting the pieces for the side to move and the side not to move can
# be simplified by just adding the color or the negated color to the index
# of the white pieces.  This must not change in future versions!
use constant CP_POS_HALF_MOVES => 0;
use constant CP_POS_PAWNS => CP_PAWN;
use constant CP_POS_KNIGHTS => CP_KNIGHT;
use constant CP_POS_BISHOPS => CP_BISHOP;
use constant CP_POS_ROOKS => CP_ROOK;
use constant CP_POS_QUEENS => CP_QUEEN;
use constant CP_POS_KINGS => CP_KING;
use constant CP_POS_WHITE_PIECES => 7;
use constant CP_POS_BLACK_PIECES => CP_POS_WHITE_PIECES + CP_BLACK;
use constant CP_POS_HALF_MOVE_CLOCK => 9;
use constant CP_POS_INFO => 10;
use constant CP_POS_EVASION_SQUARES => 11;
use constant CP_POS_SIGNATURE => 12;
use constant CP_POS_REVERSIBLE_CLOCK => 13;
# 3 reserved slots.
use constant CP_POS_IN_CHECK => 17;

# How to evade a check?
use constant CP_EVASION_ALL => 0;
use constant CP_EVASION_CAPTURE => 1;
use constant CP_EVASION_KING_MOVE => 2;

# Board masks and shifts.
# Squares.
use constant CP_A1 => 0;
use constant CP_B1 => 1;
use constant CP_C1 => 2;
use constant CP_D1 => 3;
use constant CP_E1 => 4;
use constant CP_F1 => 5;
use constant CP_G1 => 6;
use constant CP_H1 => 7;
use constant CP_A2 => 8;
use constant CP_B2 => 9;
use constant CP_C2 => 10;
use constant CP_D2 => 11;
use constant CP_E2 => 12;
use constant CP_F2 => 13;
use constant CP_G2 => 14;
use constant CP_H2 => 15;
use constant CP_A3 => 16;
use constant CP_B3 => 17;
use constant CP_C3 => 18;
use constant CP_D3 => 19;
use constant CP_E3 => 20;
use constant CP_F3 => 21;
use constant CP_G3 => 22;
use constant CP_H3 => 23;
use constant CP_A4 => 24;
use constant CP_B4 => 25;
use constant CP_C4 => 26;
use constant CP_D4 => 27;
use constant CP_E4 => 28;
use constant CP_F4 => 29;
use constant CP_G4 => 30;
use constant CP_H4 => 31;
use constant CP_A5 => 32;
use constant CP_B5 => 33;
use constant CP_C5 => 34;
use constant CP_D5 => 35;
use constant CP_E5 => 36;
use constant CP_F5 => 37;
use constant CP_G5 => 38;
use constant CP_H5 => 39;
use constant CP_A6 => 40;
use constant CP_B6 => 41;
use constant CP_C6 => 42;
use constant CP_D6 => 43;
use constant CP_E6 => 44;
use constant CP_F6 => 45;
use constant CP_G6 => 46;
use constant CP_H6 => 47;
use constant CP_A7 => 48;
use constant CP_B7 => 49;
use constant CP_C7 => 50;
use constant CP_D7 => 51;
use constant CP_E7 => 52;
use constant CP_F7 => 53;
use constant CP_G7 => 54;
use constant CP_H7 => 55;
use constant CP_A8 => 56;
use constant CP_B8 => 57;
use constant CP_C8 => 58;
use constant CP_D8 => 59;
use constant CP_E8 => 60;
use constant CP_F8 => 61;
use constant CP_G8 => 62;
use constant CP_H8 => 63;

# Files.
use constant CP_A_MASK => 0x0101010101010101;
use constant CP_B_MASK => 0x0202020202020202;
use constant CP_C_MASK => 0x0404040404040404;
use constant CP_D_MASK => 0x0808080808080808;
use constant CP_E_MASK => 0x1010101010101010;
use constant CP_F_MASK => 0x2020202020202020;
use constant CP_G_MASK => 0x4040404040404040;
use constant CP_H_MASK => 0x8080808080808080;

# Ranks.
use constant CP_1_MASK => 0x00000000000000ff;
use constant CP_2_MASK => 0x000000000000ff00;
use constant CP_3_MASK => 0x0000000000ff0000;
use constant CP_4_MASK => 0x00000000ff000000;
use constant CP_5_MASK => 0x000000ff00000000;
use constant CP_6_MASK => 0x0000ff0000000000;
use constant CP_7_MASK => 0x00ff000000000000;
use constant CP_8_MASK => 0xff00000000000000;

use constant CP_FILE_A => (0);
use constant CP_FILE_B => (1);
use constant CP_FILE_C => (2);
use constant CP_FILE_D => (3);
use constant CP_FILE_E => (4);
use constant CP_FILE_F => (5);
use constant CP_FILE_G => (6);
use constant CP_FILE_H => (7);

use constant CP_RANK_1 => (0);
use constant CP_RANK_2 => (1);
use constant CP_RANK_3 => (2);
use constant CP_RANK_4 => (3);
use constant CP_RANK_5 => (4);
use constant CP_RANK_6 => (5);
use constant CP_RANK_7 => (6);
use constant CP_RANK_8 => (7);

use constant CP_WHITE_MASK => 0x5555555555555555;
use constant CP_BLACK_MASK => 0xaaaaaaaaaaaaaaaa;

use constant CP_PIECE_CHARS => [
	['', 'P', 'N', 'B', 'R', 'Q', 'K'],
	['', 'p', 'n', 'b', 'r', 'q', 'k'],
];

use constant CP_RANDOM_SEED => 0x415C0415C0415C0;
my $cp_random = CP_RANDOM_SEED;

my @pawn_aux_data = (
	# White.
	[
		# Mask for regular moves.
		~(CP_7_MASK | CP_8_MASK),
		# Mask for double moves.
		CP_2_MASK,
		# Promotion mask.
		CP_7_MASK,
		# Single step offset.
		8,
	],
	# Black.
	[
		# Mask for regular moves.
		~(CP_2_MASK | CP_1_MASK),
		# Mask for double moves.
		CP_7_MASK,
		# Promotion mask.
		CP_2_MASK,
		# Single step offset.
		-8,
	],
);

# Map ep squares to the mask of the pawn that gets removed.
my @ep_pawn_masks;

my @castling_aux_data = (
	# White.
	[
		# From shift.
		CP_E1,
		# From mask.
		(CP_E_MASK & CP_1_MASK),
		# King-side crossing square.
		(CP_F_MASK & CP_1_MASK),
		# King-side king's destination square.
		CP_G1,
		# Queen-side crossing mask.
		(CP_D_MASK & CP_1_MASK),
		# Queen-side king's destination square.
		CP_C1,
		# Queen-side rook crossing mask.
		(CP_B_MASK & CP_1_MASK),
	],
	# Black.
	[
		# From shift.
		CP_E8,
		# From mask.
		(CP_E_MASK & CP_8_MASK),
		# King-side crossing mask.
		(CP_F_MASK & CP_8_MASK),
		# King-side king's destination square.
		CP_G8,
		# Queen-side crossing mask.
		(CP_D_MASK & CP_8_MASK),
		# Queen-side king's destination square.
		CP_C8,
		# Queen-side rook crossing mask.
		(CP_B_MASK & CP_8_MASK),
	],
);

# These arrays map a bit shift offset to bitboards that the corresponding
# piece can attack from that square.  They are filled at compile-time at the
# end of this file.
my @king_attack_masks;
my @knight_attack_masks;

# These are for pawn single steps, double steps, and captures,
# first for white then for black.
my @pawn_masks;

# Two-dimensional array for determining common lines (diagonals or files/ranks).
my @common_lines;

# Information for castlings, part 1. Lookup by target square of the king, the
# move mask of the rook and the negative mask for the castling rights.
my @castling_rook_move_masks;

# Information for castlings, part 2. For a1, h1, a8, and h8 remove these
# castling rights.
my @castling_rights_rook_masks;

# Information for castlings, part 3. For the king destination squares c1, g1,
# c8, and g8, where does the rook move? Needed for moveGivesCheck().
my @castling_rook_to_mask;

# Change in material.  Looked up via a combined mask of color to move,
# captured and promotion piece.
my @material_deltas;

# This table is used in the static exchange evaluation in order to
# detect x-ray attacks. It gives a mask of all squares that will
# attack the destination square if a piece moves from the start square to the
# destination square. Example: The "obscured mask" of the bishop move "d3e6"
# is a bitboard with the squares "b1" and "c2" because a queen or bishop on one
# of these two squares will attack "e6", when the bishop moves there.
#
# FIXME! All multi-dimensional lookup tables that are using from and to as
# their index, should changed to just use the lower 12 bits of the move
# instead.  That saves us one array dereferencing.
my @obscured_masks;

my @zk_pieces;
my @zk_castling;
my @zk_ep_files;
my $zk_color;

my @zk_move_masks;

my @move_numbers;

my @magicmovesbdb;
my @magicmovesrdb;

my @magicmoves_r_magics;
my @magicmoves_r_mask;
my @magicmoves_b_magics;
my @magicmoves_b_mask;

use constant CP_MAGICMOVES_B_MAGICS => \@magicmoves_b_magics;
use constant CP_MAGICMOVES_R_MAGICS => \@magicmoves_r_magics;
use constant CP_MAGICMOVES_B_MASK => \@magicmoves_b_mask;
use constant CP_MAGICMOVES_R_MASK => \@magicmoves_r_mask;
use constant CP_MAGICMOVESBDB => \@magicmovesbdb;
use constant CP_MAGICMOVESRDB => \@magicmovesrdb;

my @piece_values = (0, CP_PAWN_VALUE, CP_KNIGHT_VALUE, CP_BISHOP_VALUE,
	CP_ROOK_VALUE, CP_QUEEN_VALUE);

# Do not remove this line!


sub new {
	my ($class, $fen) = @_;

	return $class->newFromFEN($fen) if defined $fen && length $fen;

	my $self = bless [], $class;
	$self->[CP_POS_WHITE_PIECES] = CP_1_MASK | CP_2_MASK;
	$self->[CP_POS_BLACK_PIECES] = CP_8_MASK | CP_7_MASK,
	$self->[CP_POS_KINGS] = (CP_1_MASK | CP_8_MASK) & CP_E_MASK;
	$self->[CP_POS_QUEENS] = (CP_D_MASK & CP_1_MASK)
			| (CP_D_MASK & CP_8_MASK);
	$self->[CP_POS_ROOKS] = ((CP_A_MASK | CP_H_MASK) & CP_1_MASK)
			| ((CP_A_MASK | CP_H_MASK) & CP_8_MASK);
	$self->[CP_POS_BISHOPS] = ((CP_C_MASK | CP_F_MASK) & CP_1_MASK)
			| ((CP_C_MASK | CP_F_MASK) & CP_8_MASK);
	$self->[CP_POS_KNIGHTS] = ((CP_B_MASK | CP_G_MASK) & CP_1_MASK)
			| ((CP_B_MASK | CP_G_MASK) & CP_8_MASK);
	$self->[CP_POS_PAWNS] = CP_2_MASK | CP_7_MASK;
	$self->[CP_POS_HALF_MOVE_CLOCK] = 0;
	$self->[CP_POS_REVERSIBLE_CLOCK] = 0;
	$self->[CP_POS_HALF_MOVES] = 0;

	my $info = 0;
	($info = ($info & ~(1 << 0)) | (1 << 0));
	($info = ($info & ~(1 << 1)) | (1 << 1));
	($info = ($info & ~(1 << 2)) | (1 << 2));
	($info = ($info & ~(1 << 3)) | (1 << 3));
	($info = ($info & ~(1 << 4)) | (CP_WHITE << 4));
	($info = ($info & ~(0x3f << 5)) | (0 << 5));
	$self->[CP_POS_INFO] = $info;
	
	$self->__updateZobristKey;
	(do {	my $c = (($info & (1 << 4)) >> 4);	my $kings = $self->[CP_POS_KINGS]		& ($c ? $self->[CP_POS_BLACK_PIECES] : $self->[CP_POS_WHITE_PIECES]);	my $king_shift = (do {	my $A = $kings - 1 - ((($kings - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	($info = ($info & ~(0x3f << 11)) | ($king_shift << 11));	my $checkers = $self->[CP_POS_IN_CHECK] = (do {	my $her_color = !$c;	my $her_pieces = $self->[CP_POS_WHITE_PIECES + $her_color];	my $occupancy = $self->[CP_POS_WHITE_PIECES + $c] | $her_pieces;	my $queens = $self->[CP_POS_QUEENS];	$her_pieces		& (($pawn_masks[$c]->[2]->[$king_shift] & $self->[CP_POS_PAWNS])			| ($knight_attack_masks[$king_shift] & $self->[CP_POS_KNIGHTS])			| ($king_attack_masks[$king_shift] & $self->[CP_POS_KINGS])			| (CP_MAGICMOVESBDB->[$king_shift][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$king_shift]) * CP_MAGICMOVES_B_MAGICS->[$king_shift]) >> 55) & ((1 << (64 - 55)) - 1)] & ($queens | $self->[CP_POS_BISHOPS]))			| (CP_MAGICMOVESRDB->[$king_shift][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$king_shift]) * CP_MAGICMOVES_R_MAGICS->[$king_shift]) >> 52) & ((1 << (64 - 52)) - 1)] & ($queens | $self->[CP_POS_ROOKS])));});	if ($checkers) {		if ($checkers & ($checkers - 1)) {			($info = ($info & ~(0x3 << 17)) | (CP_EVASION_KING_MOVE << 17));		} elsif ($checkers & ($self->[CP_POS_KNIGHTS] | ($self->[CP_POS_PAWNS]))) {			($info = ($info & ~(0x3 << 17)) | (CP_EVASION_CAPTURE << 17));			$self->[CP_POS_EVASION_SQUARES] = $checkers;		} else {			($info = ($info & ~(0x3 << 17)) | (CP_EVASION_ALL << 17));			my $piece_shift = (do {	my $A = $checkers - 1 - ((($checkers - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});			my ($attack_type, undef, $attack_ray) =				@{$common_lines[$king_shift]->[$piece_shift]};			if ($attack_ray) {				$self->[CP_POS_EVASION_SQUARES] = $attack_ray;			} else {				$self->[CP_POS_EVASION_SQUARES] = $checkers;			}		}	}	$self->[CP_POS_INFO] = $info;});
	
	return $self;
}

sub newFromFEN {
	my ($class, $fen) = @_;

	my ($pieces, $color, $castling, $ep_square, $hmc, $moveno)
			= split /[ \t]+/, $fen;
	$ep_square = '-' if !defined $ep_square;
	$hmc = 0 if !defined $hmc;
	$moveno = 1 if !defined $moveno;

	if (!(defined $pieces && defined $color && defined $castling)) {
		die __"Illegal FEN: Incomplete.\n";
	}

	my @ranks = split '/', $pieces;
	die __"Illegal FEN: FEN does not have exactly eight ranks.\n"
		if @ranks != 8;
	
	my $w_pieces = 0;
	my $b_pieces = 0;
	my $kings = 0;
	my $rooks = 0;
	my $knights = 0;
	my $bishops = 0;
	my $queens = 0;
	my $pawns = 0;

	my $material = 0;
	my $shift = 56;
	my $rankno = 7;
	foreach my $rank (@ranks) {
		my @chars = split '', $rank;
		foreach my $char (@chars) {
			if ('1' le $char && '8' ge $char) {
				$shift += $char;
				next;
			}

			my $mask = 1 << $shift;
			if ('P' eq $char) {
				$w_pieces |= $mask;
				$pawns |= $mask;
				$material += CP_PAWN_VALUE;
			} elsif ('p' eq $char) {
				$b_pieces |= $mask;
				$pawns |= $mask;
				$material -= CP_PAWN_VALUE;
			} elsif ('N' eq $char) {
				$w_pieces |= $mask;
				$knights |= $mask;
				$material += CP_KNIGHT_VALUE;
			} elsif ('n' eq $char) {
				$b_pieces |= $mask;
				$knights |= $mask;
				$material -= CP_KNIGHT_VALUE;
			} elsif ('B' eq $char) {
				$w_pieces |= $mask;
				$bishops |= $mask;
				$material += CP_BISHOP_VALUE;
			} elsif ('b' eq $char) {
				$b_pieces |= $mask;
				$bishops |= $mask;
				$material -= CP_BISHOP_VALUE;
			} elsif ('R' eq $char) {
				$w_pieces |= $mask;
				$rooks |= $mask;
				$material += CP_ROOK_VALUE;
			} elsif ('r' eq $char) {
				$b_pieces |= $mask;
				$rooks |= $mask;
				$material -= CP_ROOK_VALUE;
			} elsif ('Q' eq $char) {
				$w_pieces |= $mask;
				$queens |= $mask;
				$material += CP_QUEEN_VALUE;
			} elsif ('q' eq $char) {
				$b_pieces |= $mask;
				$queens |= $mask;
				$material -= CP_QUEEN_VALUE;
			} elsif ('K' eq $char) {
				$w_pieces |= $mask;
				$kings |= $mask;
			} elsif ('k' eq $char) {
				$b_pieces |= $mask;
				$kings |= $mask;
			} else {
				die __x("Illegal FEN: Illegal piece/number '{x}'.\n",
						x => $char);
			}
			++$shift;
		}

		if (($rankno-- << 3) + 8 != $shift) {
			die __x("Illegal FEN: Incomplete or overpopulated rank '{rank}'.\n",
				rank => $rank);
		}

		$shift -= 16;
	}

	my $popcount;

	{ my $_b = $w_pieces & $kings; for ($popcount = 0; $_b; ++$popcount) { $_b &= $_b - 1; } };
	if ($popcount != 1) {
		die __"Illegal FEN: White must have exactly one king.\n";
	}
	{ my $_b = $b_pieces & $kings; for ($popcount = 0; $_b; ++$popcount) { $_b &= $_b - 1; } };
	if ($popcount != 1) {
		die __"Illegal FEN: Black must have exactly one king.\n";
	}

	my $self = bless [], $class;

	$self->[CP_POS_WHITE_PIECES] = $w_pieces;
	$self->[CP_POS_BLACK_PIECES] = $b_pieces;
	$self->[CP_POS_KINGS] = $kings;
	$self->[CP_POS_QUEENS] = $queens;
	$self->[CP_POS_ROOKS] = $rooks;
	$self->[CP_POS_BISHOPS] = $bishops;
	$self->[CP_POS_KNIGHTS] = $knights;
	$self->[CP_POS_PAWNS] = $pawns;

	my $pos_info = 0;
	($pos_info = (($pos_info & 0x7fffffff) | ($material << 19)));

	if ('w' eq lc $color) {
		($pos_info = ($pos_info & ~(1 << 4)) | (CP_WHITE << 4));
	} elsif ('b' eq lc $color) {
		($pos_info = ($pos_info & ~(1 << 4)) | (CP_BLACK << 4));
	} else {
		die __x"Illegal FEN: Side to move is neither 'w' nor 'b'.\n";
	}

	if (!length $castling) {
		die __"Illegal FEN: Missing castling state.\n";
	}
	if ($castling !~ /^(?:-|K?Q?k?q?)/) {
		die __x("Illegal FEN: Illegal castling state '{state}'.\n",
				state => $castling);
	}

	my ($piece_type, $piece_color);

	($piece_type, $piece_color) = $self->pieceAtShift(CP_E1);
	if (!($piece_type && $piece_type == CP_KING && $piece_color == CP_WHITE)) {
		$castling =~ s/KQ//;
	}
	($piece_type, $piece_color) = $self->pieceAtShift(CP_E8);
	if (!($piece_type && $piece_type == CP_KING && $piece_color == CP_BLACK)) {
		$castling =~ s/kq//;
	}

	if ($castling =~ /K/) {
		($piece_type, $piece_color) = $self->pieceAtShift(CP_H1);
		if ($piece_type && $piece_type == CP_ROOK && $piece_color == CP_WHITE) {
			($pos_info = ($pos_info & ~(1 << 0)) | (1 << 0));
		}
	}
	if ($castling =~ /Q/) {
		($piece_type, $piece_color) = $self->pieceAtShift(CP_A1);
		if ($piece_type && $piece_type == CP_ROOK && $piece_color == CP_WHITE) {
			($pos_info = ($pos_info & ~(1 << 1)) | (1 << 1));
		}
	}
	if ($castling =~ /k/) {
		($piece_type, $piece_color) = $self->pieceAtShift(CP_H8);
		if ($piece_type && $piece_type == CP_ROOK && $piece_color == CP_BLACK) {
			($pos_info = ($pos_info & ~(1 << 2)) | (1 << 2));
		}
	}
	if ($castling =~ /q/) {
		($piece_type, $piece_color) = $self->pieceAtShift(CP_A8);
		if ($piece_type && $piece_type == CP_ROOK && $piece_color == CP_BLACK) {
			($pos_info = ($pos_info & ~(1 << 3)) | (1 << 3));
		}
	}

	my $to_move = (($pos_info & (1 << 4)) >> 4);
	if ('-' eq $ep_square) {
		($pos_info = ($pos_info & ~(0x3f << 5)) | (0 << 5));
	} elsif ($to_move == CP_WHITE && $ep_square =~ /^[a-h]6$/) {
		my $ep_shift = $self->squareToShift($ep_square);
		if ((1 << ($ep_shift - 8)) & $self->[CP_POS_BLACK_PIECES]
		    & $self->[CP_POS_PAWNS]) {
			($pos_info = ($pos_info & ~(0x3f << 5)) | ($self->squareToShift($ep_square) << 5));
		}
	} elsif ($to_move == CP_BLACK && $ep_square =~ /^[a-h]3$/) {
		my $ep_shift = $self->squareToShift($ep_square);
		if ((1 << ($ep_shift + 8)) & $self->[CP_POS_WHITE_PIECES]
		    & $self->[CP_POS_PAWNS]) {
			($pos_info = ($pos_info & ~(0x3f << 5)) | ($self->squareToShift($ep_square) << 5));
		}
	}

	$self->[CP_POS_INFO] = $pos_info;

	if ($hmc !~ /^0|[1-9][0-9]*$/) {
		$hmc = 0;
	}
	$self->[CP_POS_HALF_MOVE_CLOCK] = $self->[CP_POS_REVERSIBLE_CLOCK] = $hmc;

	if ($moveno !~ /^[1-9][0-9]*$/) {
		$moveno = 1;
	}

	if (((($self->[CP_POS_INFO] & (1 << 4)) >> 4)) == CP_WHITE) {
			$self->[CP_POS_HALF_MOVES] = ($moveno - 1) << 1;
	} else {
			$self->[CP_POS_HALF_MOVES] = (($moveno - 1) << 1) + 1;
	}

	$self->__updateZobristKey;
	(do {	my $c = (($pos_info & (1 << 4)) >> 4);	my $kings = $self->[CP_POS_KINGS]		& ($c ? $self->[CP_POS_BLACK_PIECES] : $self->[CP_POS_WHITE_PIECES]);	my $king_shift = (do {	my $A = $kings - 1 - ((($kings - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	($pos_info = ($pos_info & ~(0x3f << 11)) | ($king_shift << 11));	my $checkers = $self->[CP_POS_IN_CHECK] = (do {	my $her_color = !$c;	my $her_pieces = $self->[CP_POS_WHITE_PIECES + $her_color];	my $occupancy = $self->[CP_POS_WHITE_PIECES + $c] | $her_pieces;	my $queens = $self->[CP_POS_QUEENS];	$her_pieces		& (($pawn_masks[$c]->[2]->[$king_shift] & $self->[CP_POS_PAWNS])			| ($knight_attack_masks[$king_shift] & $self->[CP_POS_KNIGHTS])			| ($king_attack_masks[$king_shift] & $self->[CP_POS_KINGS])			| (CP_MAGICMOVESBDB->[$king_shift][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$king_shift]) * CP_MAGICMOVES_B_MAGICS->[$king_shift]) >> 55) & ((1 << (64 - 55)) - 1)] & ($queens | $self->[CP_POS_BISHOPS]))			| (CP_MAGICMOVESRDB->[$king_shift][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$king_shift]) * CP_MAGICMOVES_R_MAGICS->[$king_shift]) >> 52) & ((1 << (64 - 52)) - 1)] & ($queens | $self->[CP_POS_ROOKS])));});	if ($checkers) {		if ($checkers & ($checkers - 1)) {			($pos_info = ($pos_info & ~(0x3 << 17)) | (CP_EVASION_KING_MOVE << 17));		} elsif ($checkers & ($self->[CP_POS_KNIGHTS] | ($self->[CP_POS_PAWNS]))) {			($pos_info = ($pos_info & ~(0x3 << 17)) | (CP_EVASION_CAPTURE << 17));			$self->[CP_POS_EVASION_SQUARES] = $checkers;		} else {			($pos_info = ($pos_info & ~(0x3 << 17)) | (CP_EVASION_ALL << 17));			my $piece_shift = (do {	my $A = $checkers - 1 - ((($checkers - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});			my ($attack_type, undef, $attack_ray) =				@{$common_lines[$king_shift]->[$piece_shift]};			if ($attack_ray) {				$self->[CP_POS_EVASION_SQUARES] = $attack_ray;			} else {				$self->[CP_POS_EVASION_SQUARES] = $checkers;			}		}	}	$self->[CP_POS_INFO] = $pos_info;});

	return $self;
}

sub pseudoLegalMoves {
	my ($self) = @_;

	my $pos_info = $self->[CP_POS_INFO];
	my $to_move = (($pos_info & (1 << 4)) >> 4);
	my $my_pieces = $self->[CP_POS_WHITE_PIECES + $to_move];
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];
	my $occupancy = $my_pieces | $her_pieces;
	my $empty = ~$occupancy;

	my (@moves, $target_mask, $base_move);

	# Generate king moves.  We take advantage of the fact that there is always
	# exactly one king of each color on the board.  So there is no need for a
	# loop.
	my $king_mask = $my_pieces & $self->[CP_POS_KINGS];

	my $from = (do {	my $A = $king_mask - 1 - ((($king_mask - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

	$base_move = ($from << 6 | CP_KING << 15);

	$target_mask = ~$my_pieces & $king_attack_masks[$from];

	while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};

	my $in_check = $self->[CP_POS_IN_CHECK];
	return @moves if $in_check && CP_EVASION_KING_MOVE == (($pos_info & (0x3 << 17)) >> 17);

	# Generate castlings.
	# Mask out the castling rights for the side to move.
	my $castling_rights = ($pos_info >> ($to_move << 1)) & 0x3;
	if ($castling_rights) {
		my ($king_from, $king_from_mask, $king_side_crossing_mask,
			$king_side_dest_shift,
			$queen_side_crossing_mask, $queen_side_dest_shift,
			$queen_side_rook_crossing_mask)
			= @{$castling_aux_data[$to_move]};
		if ($king_mask & $king_from_mask) {
			if (($castling_rights & 0x1)
				&& !(((1 << $king_side_dest_shift) | $king_side_crossing_mask)
					& $occupancy)) {
				push @moves, ($king_from << 6 | CP_KING << 15)
					| $king_side_dest_shift;
			}
			if (($castling_rights & 0x2)
			    && (!(($queen_side_crossing_mask
			           | $queen_side_rook_crossing_mask
				       | (1 << $queen_side_dest_shift))
				      & $occupancy))) {
				push @moves, ($king_from << 6 | CP_KING << 15)
					| $queen_side_dest_shift;
			}
		}
	}

	# Generate knight moves.
	my $knight_mask = $my_pieces & $self->[CP_POS_KNIGHTS];
	while ($knight_mask) {
		my $from = (do {	my $B = $knight_mask & -$knight_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_KNIGHT << 15);
	
		$target_mask = ~$my_pieces & $knight_attack_masks[$from];

		while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};

		$knight_mask = (($knight_mask) & (($knight_mask) - 1));
	}

	# Generate bishop moves.
	my $bishop_mask = $my_pieces & $self->[CP_POS_BISHOPS];
	while ($bishop_mask) {
		my $from = (do {	my $B = $bishop_mask & -$bishop_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_BISHOP << 15);
	
		$target_mask = CP_MAGICMOVESBDB->[$from][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$from]) * CP_MAGICMOVES_B_MAGICS->[$from]) >> 55) & ((1 << (64 - 55)) - 1)] & ($empty | $her_pieces);

		while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};

		$bishop_mask = (($bishop_mask) & (($bishop_mask) - 1));
	}

	# Generate rook moves.
	my $rook_mask = $my_pieces & $self->[CP_POS_ROOKS];
	while ($rook_mask) {
		my $from = (do {	my $B = $rook_mask & -$rook_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_ROOK << 15);
	
		$target_mask = CP_MAGICMOVESRDB->[$from][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$from]) * CP_MAGICMOVES_R_MAGICS->[$from]) >> 52) & ((1 << (64 - 52)) - 1)] & ($empty | $her_pieces);

		while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};

		$rook_mask = (($rook_mask) & (($rook_mask) - 1));
	}

	# Generate queen moves.
	my $queen_mask = $my_pieces & $self->[CP_POS_QUEENS];
	while ($queen_mask) {
		my $from = (do {	my $B = $queen_mask & -$queen_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_QUEEN << 15);
	
		$target_mask = 
			(CP_MAGICMOVESRDB->[$from][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$from]) * CP_MAGICMOVES_R_MAGICS->[$from]) >> 52) & ((1 << (64 - 52)) - 1)]
				| CP_MAGICMOVESBDB->[$from][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$from]) * CP_MAGICMOVES_B_MAGICS->[$from]) >> 55) & ((1 << (64 - 55)) - 1)])
			& ($empty | $her_pieces);

		while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};

		$queen_mask = (($queen_mask) & (($queen_mask) - 1));
	}

	# Generate pawn moves.
	my ($regular_mask, $double_mask, $promotion_mask, $offset) =
		@{$pawn_aux_data[$to_move]};

	my ($pawn_single_masks, $pawn_double_masks, $pawn_capture_masks) = 
		@{$pawn_masks[$to_move]};

	my $pawns = $self->[CP_POS_PAWNS];

	my $pawn_mask;

	my $ep_shift = (($pos_info & (0x3f << 5)) >> 5);
	my $ep_target_mask = $ep_shift ? (1 << $ep_shift) : 0; 

	# Pawn single steps and captures w/o promotions.
	$pawn_mask = $my_pieces & $pawns & $regular_mask;
	while ($pawn_mask) {
		my $from = (do {	my $B = $pawn_mask & -$pawn_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_PAWN << 15);
		$target_mask = ($pawn_single_masks->[$from] & $empty)
			| ($pawn_capture_masks->[$from] & ($her_pieces | $ep_target_mask));
		while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};
		$pawn_mask = (($pawn_mask) & (($pawn_mask) - 1));
	}

	# Pawn double steps.
	$pawn_mask = $my_pieces & $pawns & $double_mask;
	while ($pawn_mask) {
		my $from = (do {	my $B = $pawn_mask & -$pawn_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		my $cross_mask = $pawn_single_masks->[$from] & $empty;

		if ($cross_mask) {
			$target_mask = $pawn_double_masks->[$from] & $empty;
			if ($target_mask) {
				my $to = $from + ($offset << 1);
				push @moves, ($from << 6) | $to | CP_PAWN << 15;
			}
		}
		$pawn_mask = (($pawn_mask) & (($pawn_mask) - 1));
	}

	# Pawn promotions including captures.
	$pawn_mask = $my_pieces & $pawns & ~$regular_mask;
	while ($pawn_mask) {
		my $from = (do {	my $B = $pawn_mask & -$pawn_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_PAWN << 15);
		$target_mask = ($pawn_single_masks->[$from] & $empty)
			| ($pawn_capture_masks->[$from] & ($her_pieces | $ep_target_mask));
		while ($target_mask) {	my $base_move = $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	push @moves,		$base_move | (CP_QUEEN << 12),		$base_move | (CP_ROOK << 12),		$base_move | (CP_BISHOP << 12),		$base_move | (CP_KNIGHT << 12);	$target_mask = (($target_mask) & (($target_mask) - 1));};
		$pawn_mask = (($pawn_mask) & (($pawn_mask) - 1));
	}

	return @moves;
}

sub pseudoLegalAttacks {
	my ($self) = @_;

	my $pos_info = $self->[CP_POS_INFO];
	my $to_move = (($pos_info & (1 << 4)) >> 4);
	my $my_pieces = $self->[CP_POS_WHITE_PIECES + $to_move];
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];
	my $occupancy = $my_pieces | $her_pieces;
	my $empty = ~$occupancy;

	my (@moves, $target_mask, $base_move);

	# Generate king moves.  We take advantage of the fact that there is always
	# exactly one king of each color on the board.  So there is no need for a
	# loop.
	my $king_mask = $my_pieces & $self->[CP_POS_KINGS];

	my $from = (do {	my $A = $king_mask - 1 - ((($king_mask - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

	$base_move = ($from << 6 | CP_KING << 15);

	$target_mask = $her_pieces & $king_attack_masks[$from];

	while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};

	# Generate knight moves.
	my $knight_mask = $my_pieces & $self->[CP_POS_KNIGHTS];
	while ($knight_mask) {
		my $from = (do {	my $B = $knight_mask & -$knight_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_KNIGHT << 15);
	
		$target_mask = $her_pieces & $knight_attack_masks[$from];

		while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};

		$knight_mask = (($knight_mask) & (($knight_mask) - 1));
	}

	# Generate bishop moves.
	my $bishop_mask = $my_pieces & $self->[CP_POS_BISHOPS];
	while ($bishop_mask) {
		my $from = (do {	my $B = $bishop_mask & -$bishop_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_BISHOP << 15);
	
		$target_mask = CP_MAGICMOVESBDB->[$from][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$from]) * CP_MAGICMOVES_B_MAGICS->[$from]) >> 55) & ((1 << (64 - 55)) - 1)] & $her_pieces;

		while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};

		$bishop_mask = (($bishop_mask) & (($bishop_mask) - 1));
	}

	# Generate rook moves.
	my $rook_mask = $my_pieces & $self->[CP_POS_ROOKS];
	while ($rook_mask) {
		my $from = (do {	my $B = $rook_mask & -$rook_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_ROOK << 15);
	
		$target_mask = CP_MAGICMOVESRDB->[$from][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$from]) * CP_MAGICMOVES_R_MAGICS->[$from]) >> 52) & ((1 << (64 - 52)) - 1)] & $her_pieces;

		while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};

		$rook_mask = (($rook_mask) & (($rook_mask) - 1));
	}

	# Generate queen moves.
	my $queen_mask = $my_pieces & $self->[CP_POS_QUEENS];
	while ($queen_mask) {
		my $from = (do {	my $B = $queen_mask & -$queen_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_QUEEN << 15);
	
		$target_mask = 
			(CP_MAGICMOVESRDB->[$from][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$from]) * CP_MAGICMOVES_R_MAGICS->[$from]) >> 52) & ((1 << (64 - 52)) - 1)]
				| CP_MAGICMOVESBDB->[$from][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$from]) * CP_MAGICMOVES_B_MAGICS->[$from]) >> 55) & ((1 << (64 - 55)) - 1)])
			& $her_pieces;

		while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};

		$queen_mask = (($queen_mask) & (($queen_mask) - 1));
	}

	# Generate pawn moves.
	my ($regular_mask, $double_mask, $promotion_mask, $offset) =
		@{$pawn_aux_data[$to_move]};

	my ($pawn_single_masks, $pawn_double_masks, $pawn_capture_masks) = 
		@{$pawn_masks[$to_move]};

	my $pawns = $self->[CP_POS_PAWNS];

	my $pawn_mask;

	my $ep_shift = (($pos_info & (0x3f << 5)) >> 5);
	my $ep_target_mask = $ep_shift ? (1 << $ep_shift) : 0; 

	# Pawn captures w/o promotions.
	$pawn_mask = $my_pieces & $pawns & $regular_mask;
	while ($pawn_mask) {
		my $from = (do {	my $B = $pawn_mask & -$pawn_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_PAWN << 15);
		$target_mask = ($pawn_capture_masks->[$from] & ($her_pieces | $ep_target_mask));
		while ($target_mask) {	push @moves, $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	$target_mask = (($target_mask) & (($target_mask) - 1));};
		$pawn_mask = (($pawn_mask) & (($pawn_mask) - 1));
	}

	# Pawn promotions including captures.
	$pawn_mask = $my_pieces & $pawns & ~$regular_mask;
	while ($pawn_mask) {
		my $from = (do {	my $B = $pawn_mask & -$pawn_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		$base_move = ($from << 6 | CP_PAWN << 15);
		$target_mask = ($pawn_single_masks->[$from] & $empty)
			| ($pawn_capture_masks->[$from] & ($her_pieces | $ep_target_mask));
		while ($target_mask) {	my $base_move = $base_move | (do {	my $B = $target_mask & -$target_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	push @moves,		$base_move | (CP_QUEEN << 12),		$base_move | (CP_ROOK << 12),		$base_move | (CP_BISHOP << 12),		$base_move | (CP_KNIGHT << 12);	$target_mask = (($target_mask) & (($target_mask) - 1));};
		$pawn_mask = (($pawn_mask) & (($pawn_mask) - 1));
	}

	return @moves;
}

# FIXME! Make this a macro!
sub __update {
	my ($self) = @_;

	# Update king's shift.
	my $pos_info = $self->[CP_POS_INFO];

	$self->[CP_POS_INFO] = $pos_info;
}

sub attacked {
	my ($self, $shift) = @_;

	return (do {	my $her_color = !((($self->[CP_POS_INFO] & (1 << 4)) >> 4));	my $her_pieces = $self->[CP_POS_WHITE_PIECES + $her_color];	my $occupancy = $self->[CP_POS_WHITE_PIECES + ((($self->[CP_POS_INFO] & (1 << 4)) >> 4))] | $her_pieces;	my $queens = $self->[CP_POS_QUEENS];	$her_pieces		& (($pawn_masks[((($self->[CP_POS_INFO] & (1 << 4)) >> 4))]->[2]->[$shift] & $self->[CP_POS_PAWNS])			| ($knight_attack_masks[$shift] & $self->[CP_POS_KNIGHTS])			| ($king_attack_masks[$shift] & $self->[CP_POS_KINGS])			| (CP_MAGICMOVESBDB->[$shift][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$shift]) * CP_MAGICMOVES_B_MAGICS->[$shift]) >> 55) & ((1 << (64 - 55)) - 1)] & ($queens | $self->[CP_POS_BISHOPS]))			| (CP_MAGICMOVESRDB->[$shift][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$shift]) * CP_MAGICMOVES_R_MAGICS->[$shift]) >> 52) & ((1 << (64 - 52)) - 1)] & ($queens | $self->[CP_POS_ROOKS])));});
}

sub moveAttacked {
	my ($self, $move) = @_;

	if ($move =~ /[a-z]/i) {
		$move = $self->parseMove($move) or return;
	}

	my ($from, $to) = ((($move >> 6) & 0x3f), (($move) & 0x3f));
	return (do {	my $my_color = ((($self->[CP_POS_INFO] & (1 << 4)) >> 4));	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$my_color];	my $occupancy = ($self->[CP_POS_WHITE_PIECES + $my_color] | $her_pieces) & ~(1 << $from);	my $queens = $self->[CP_POS_QUEENS];	$her_pieces		& (($pawn_masks[$my_color]->[2]->[$to] & $self->[CP_POS_PAWNS])			| ($knight_attack_masks[$to] & $self->[CP_POS_KNIGHTS])			| ($king_attack_masks[$to] & $self->[CP_POS_KINGS])			| (CP_MAGICMOVESBDB->[$to][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$to]) * CP_MAGICMOVES_B_MAGICS->[$to]) >> 55) & ((1 << (64 - 55)) - 1)] & ($queens | $self->[CP_POS_BISHOPS]))			| (CP_MAGICMOVESRDB->[$to][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$to]) * CP_MAGICMOVES_R_MAGICS->[$to]) >> 52) & ((1 << (64 - 52)) - 1)] & ($queens | $self->[CP_POS_ROOKS])));});
}

sub moveGivesCheck {
	my ($self, $move) = @_;

	# FIXME! Check that all of these variables are really needed at least twice!
	my $pos_info = $self->[CP_POS_INFO];
	my $from = (($move >> 6) & 0x3f);
	my $from_mask = 1 << $from;
	my $to = (($move) & 0x3f);
	my $to_mask = 1 << $to;

	my $piece = (($move >> 15) & 0x7);
	my $to_move = (($pos_info & (1 << 4)) >> 4);
	my $my_pieces = $self->[CP_POS_WHITE_PIECES + $to_move];
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];
	my $her_king_mask = $self->[CP_POS_KINGS] & $her_pieces;
	my $her_king_shift = (do {	my $A = $her_king_mask - 1 - ((($her_king_mask - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
	my $occupancy = $self->[CP_POS_WHITE_PIECES] | $self->[CP_POS_BLACK_PIECES];
	my $bsliders = $my_pieces
			& ($self->[CP_POS_BISHOPS] | $self->[CP_POS_QUEENS]);
	my $rsliders = $my_pieces
			& ($self->[CP_POS_ROOKS] | $self->[CP_POS_QUEENS]);
	my $ep_shift = (($pos_info & (0x3f << 5)) >> 5);
	if ($piece == CP_PAWN && $ep_shift && $to == $ep_shift) {
		# Remove the captured piece, as well.
		$from_mask |= $ep_pawn_masks[$ep_shift];
	}

	if (($piece == CP_PAWN)
	         && ($to_mask & $pawn_masks[!$to_move]->[2]->[$her_king_shift])) {
		return 1;
	} elsif (($piece == CP_KNIGHT)
	         && ($to_mask & $knight_attack_masks[$her_king_shift])) {
		# Direct knight check.
		return 1;
	} elsif (($piece == CP_BISHOP || $piece == CP_QUEEN)
	         && (CP_MAGICMOVESBDB->[$her_king_shift][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$her_king_shift]) * CP_MAGICMOVES_B_MAGICS->[$her_king_shift]) >> 55) & ((1 << (64 - 55)) - 1)] & $to_mask)) {
		# Direct bishop/queen check.
		return 1;
	} elsif (($piece == CP_ROOK || $piece == CP_QUEEN)
	         && (CP_MAGICMOVESRDB->[$her_king_shift][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$her_king_shift]) * CP_MAGICMOVES_R_MAGICS->[$her_king_shift]) >> 52) & ((1 << (64 - 52)) - 1)] & $to_mask)) {
		# Direct rook/queen check.
		return 1;
	} elsif ($piece == CP_KING && ((($from - $to) & 0x3) == 0x2)
		&& (CP_MAGICMOVESRDB->[$her_king_shift][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$her_king_shift]) * CP_MAGICMOVES_R_MAGICS->[$her_king_shift]) >> 52) & ((1 << (64 - 52)) - 1)] & $castling_rook_to_mask[$to])) {
		return 1;
	} elsif (CP_MAGICMOVESBDB->[$her_king_shift][(((($occupancy ^ $from_mask) & CP_MAGICMOVES_B_MASK->[$her_king_shift]) * CP_MAGICMOVES_B_MAGICS->[$her_king_shift]) >> 55) & ((1 << (64 - 55)) - 1)]
		& (($my_pieces & ($self->[CP_POS_BISHOPS] | $self->[CP_POS_QUEENS]) & ~$from_mask))) {
		return 1;
	} elsif (CP_MAGICMOVESRDB->[$her_king_shift][(((($occupancy ^ $from_mask) & CP_MAGICMOVES_R_MASK->[$her_king_shift]) * CP_MAGICMOVES_R_MAGICS->[$her_king_shift]) >> 52) & ((1 << (64 - 52)) - 1)]
		& (($my_pieces & ($self->[CP_POS_ROOKS] | $self->[CP_POS_QUEENS]) & ~$from_mask))) {
		return 1;
	}

	return;
}

sub movePinned {
	my ($self, $move) = @_;

	if ($move =~ /[a-z]/i) {
		$move = $self->parseMove($move) or return;
	}

	my $to_move = ((($self->[CP_POS_INFO] & (1 << 4)) >> 4));
	my $my_pieces = $self->[CP_POS_WHITE_PIECES + $to_move];
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];
	my ($from, $to) = ((($move >> 6) & 0x3f), (($move) & 0x3f));

	return ( do {	my $pinned;	my $king_ray = $common_lines[$from]->[((($self->[CP_POS_INFO] & (0x3f << 11)) >> 11))];	if ($king_ray) {		my ($is_rook, $ray_mask) = @$king_ray;		if (!((1 << $to) & $ray_mask)) {			if ($is_rook) {				my $rmagic = CP_MAGICMOVESRDB->[$from][((((($my_pieces | $her_pieces)) & CP_MAGICMOVES_R_MASK->[$from]) * CP_MAGICMOVES_R_MAGICS->[$from]) >> 52) & ((1 << (64 - 52)) - 1)] & $ray_mask;				$pinned = ($rmagic & (1 << ((($self->[CP_POS_INFO] & (0x3f << 11)) >> 11))))						&& ($rmagic & $her_pieces							& ($self->[CP_POS_QUEENS] | $self->[CP_POS_ROOKS]));			} else {				my $bmagic = CP_MAGICMOVESBDB->[$from][((((($my_pieces | $her_pieces)) & CP_MAGICMOVES_B_MASK->[$from]) * CP_MAGICMOVES_B_MAGICS->[$from]) >> 55) & ((1 << (64 - 55)) - 1)] & $ray_mask;				$pinned = ($bmagic & (1 << ((($self->[CP_POS_INFO] & (0x3f << 11)) >> 11))))						&& ($bmagic & $her_pieces							& ($self->[CP_POS_QUEENS] | $self->[CP_POS_BISHOPS]));			}		}	}	$pinned;});
}

sub moveEquivalent {
	my ($self, $m1, $m2) = @_;

	return (($m1 & 0x7fff) == ($m2 & 0x7fff));
}

sub moveSignificant {
	my ($self, $move) = @_;

	return ($move & 0x7fff);
}

sub doMove {
	my ($self, $move) = @_;

	my $pos_info = $self->[CP_POS_INFO];
	my ($from, $to, $promote, $piece) =
		((($move >> 6) & 0x3f), (($move) & 0x3f), (($move >> 12) & 0x7),
		 (($move >> 15) & 0x7));

	my $to_move = (($pos_info & (1 << 4)) >> 4);
	my $from_mask = 1 << $from;
	my $to_mask = 1 << $to;
	my $move_mask = (1 << $from) | $to_mask;
	my $king_shift = (($pos_info & (0x3f << 11)) >> 11);
	my $my_pieces = $self->[CP_POS_WHITE_PIECES + $to_move];
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];

	# A move can be illegal for these reasons:
	#
	# 1. The moving piece is pinned by a sliding piece and would expose our
	#    king to check.
	# 2. The king moves into check.
	# 3. The king crosses an attacked square while castling.
	# 4. A pawn captured en passant discovers a check.
	#
	# Checks number two and three are done below, and only for king moves.
	# Check number 4 is done below for en passant moves.
	return if ( do {	my $pinned;	my $king_ray = $common_lines[$from]->[$king_shift];	if ($king_ray) {		my ($is_rook, $ray_mask) = @$king_ray;		if (!((1 << $to) & $ray_mask)) {			if ($is_rook) {				my $rmagic = CP_MAGICMOVESRDB->[$from][((((($my_pieces | $her_pieces)) & CP_MAGICMOVES_R_MASK->[$from]) * CP_MAGICMOVES_R_MAGICS->[$from]) >> 52) & ((1 << (64 - 52)) - 1)] & $ray_mask;				$pinned = ($rmagic & (1 << $king_shift))						&& ($rmagic & $her_pieces							& ($self->[CP_POS_QUEENS] | $self->[CP_POS_ROOKS]));			} else {				my $bmagic = CP_MAGICMOVESBDB->[$from][((((($my_pieces | $her_pieces)) & CP_MAGICMOVES_B_MASK->[$from]) * CP_MAGICMOVES_B_MAGICS->[$from]) >> 55) & ((1 << (64 - 55)) - 1)] & $ray_mask;				$pinned = ($bmagic & (1 << $king_shift))						&& ($bmagic & $her_pieces							& ($self->[CP_POS_QUEENS] | $self->[CP_POS_BISHOPS]));			}		}	}	$pinned;});

	my $old_castling = my $new_castling = $pos_info & 0xf;
	my $in_check = $self->[CP_POS_IN_CHECK];
	my $ep_shift = (($pos_info & (0x3f << 5)) >> 5);
	my $zk_update = $ep_shift ? ($zk_ep_files[$ep_shift & 0x7]) : 0;

	if ($piece == CP_KING) {
		# Does the king move into check?
		return if (do {	my $my_color = ((($self->[CP_POS_INFO] & (1 << 4)) >> 4));	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$my_color];	my $occupancy = ($self->[CP_POS_WHITE_PIECES + $my_color] | $her_pieces) & ~(1 << $from);	my $queens = $self->[CP_POS_QUEENS];	$her_pieces		& (($pawn_masks[$my_color]->[2]->[$to] & $self->[CP_POS_PAWNS])			| ($knight_attack_masks[$to] & $self->[CP_POS_KNIGHTS])			| ($king_attack_masks[$to] & $self->[CP_POS_KINGS])			| (CP_MAGICMOVESBDB->[$to][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$to]) * CP_MAGICMOVES_B_MAGICS->[$to]) >> 55) & ((1 << (64 - 55)) - 1)] & ($queens | $self->[CP_POS_BISHOPS]))			| (CP_MAGICMOVESRDB->[$to][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$to]) * CP_MAGICMOVES_R_MAGICS->[$to]) >> 52) & ((1 << (64 - 52)) - 1)] & ($queens | $self->[CP_POS_ROOKS])));});

		# Castling?
		if ((($from - $to) & 0x3) == 0x2) {
			# Are we checked?
			return if $in_check;

			# Is the field that the king has to cross attacked?
			return if (do {	my $her_color = !$to_move;	my $her_pieces = $self->[CP_POS_WHITE_PIECES + $her_color];	my $occupancy = $self->[CP_POS_WHITE_PIECES + $to_move] | $her_pieces;	my $queens = $self->[CP_POS_QUEENS];	$her_pieces		& (($pawn_masks[$to_move]->[2]->[($from + $to) >> 1] & $self->[CP_POS_PAWNS])			| ($knight_attack_masks[($from + $to) >> 1] & $self->[CP_POS_KNIGHTS])			| ($king_attack_masks[($from + $to) >> 1] & $self->[CP_POS_KINGS])			| (CP_MAGICMOVESBDB->[($from + $to) >> 1][(((($occupancy) & CP_MAGICMOVES_B_MASK->[($from + $to) >> 1]) * CP_MAGICMOVES_B_MAGICS->[($from + $to) >> 1]) >> 55) & ((1 << (64 - 55)) - 1)] & ($queens | $self->[CP_POS_BISHOPS]))			| (CP_MAGICMOVESRDB->[($from + $to) >> 1][(((($occupancy) & CP_MAGICMOVES_R_MASK->[($from + $to) >> 1]) * CP_MAGICMOVES_R_MAGICS->[($from + $to) >> 1]) >> 52) & ((1 << (64 - 52)) - 1)] & ($queens | $self->[CP_POS_ROOKS])));});

			# The move is legal.  Move the rook.
			my $rook_move_mask = $castling_rook_move_masks[$to];
			$self->[CP_POS_ROOKS] ^= $rook_move_mask;
			$self->[CP_POS_WHITE_PIECES + $to_move] ^= $rook_move_mask;
		}

		# Remove the castling rights.
		$new_castling &= ~(0x3 << ($to_move << 1));
	} elsif ($in_check) {
		# Early exits for check.  First handle the case that the piece is
		# a pawn that gets captured en passant.
		if (!($self->[CP_POS_EVASION_SQUARES] & $to_mask)) {
			# Exception: En passant capture if the capture pawn is the one
			# that gives check.
			if (!($piece == CP_PAWN && $to == $ep_shift
			      && ($ep_pawn_masks[$ep_shift] & $in_check))) {
				return;
			}
		}
	}

	# Remove castling rights if a rook moves from its original square or it
	# gets captured.  We simplify that by simply checking whether either the
	# start or the destination square is a1, h1, a8, or h8.
	$new_castling &= $castling_rights_rook_masks[$from];
	$new_castling &= $castling_rights_rook_masks[$to];

	my @state = @$self[CP_POS_HALF_MOVE_CLOCK .. CP_POS_IN_CHECK];

	my ($captured, $zk_captured) = (CP_NO_PIECE, CP_NO_PIECE);
	my $captured_mask = 0;
	if ($to_mask & $her_pieces) {
		if ($to_mask & $self->[CP_POS_PAWNS]) {
			$captured = $zk_captured = CP_PAWN;
		} elsif ($to_mask & $self->[CP_POS_KNIGHTS]) {
			$captured = $zk_captured = CP_KNIGHT;
		} elsif ($to_mask & $self->[CP_POS_BISHOPS]) {
			$captured = $zk_captured = CP_BISHOP;
		} elsif ($to_mask & $self->[CP_POS_ROOKS]) {
			$captured = $zk_captured = CP_ROOK;
		} else {
			$captured = $zk_captured = CP_QUEEN;
		}
		$captured_mask = 1 << $to;
	}

	if ($piece == CP_PAWN) {
		# Check en passant.
		if ($ep_shift && $to == $ep_shift) {
			$captured_mask = $ep_pawn_masks[$ep_shift];

			# Removing the pawn may discover a check.
			my $occupancy = ($self->[CP_POS_WHITE_PIECES] | $self->[CP_POS_BLACK_PIECES])
					& ((~$move_mask) ^ $captured_mask);
			if (CP_MAGICMOVESBDB->[$king_shift][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$king_shift]) * CP_MAGICMOVES_B_MAGICS->[$king_shift]) >> 55) & ((1 << (64 - 55)) - 1)] & $her_pieces
				& ($self->[CP_POS_BISHOPS] | $self->[CP_POS_QUEENS])) {
				return;
			} elsif (CP_MAGICMOVESRDB->[$king_shift][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$king_shift]) * CP_MAGICMOVES_R_MAGICS->[$king_shift]) >> 52) & ((1 << (64 - 52)) - 1)] & $her_pieces
				& ($self->[CP_POS_ROOKS] | $self->[CP_POS_QUEENS])) {
				return;
			}
			
			$captured = CP_PAWN;
			$zk_captured = CP_KING; # This is interpreted as an ep capture.
		}
		$self->[CP_POS_HALF_MOVE_CLOCK]
				= $self->[CP_POS_REVERSIBLE_CLOCK] = 0;
		if ((!(($to - $from) & 0x9))) {
			($pos_info = ($pos_info & ~(0x3f << 5)) | (($from + (($to - $from) >> 1)) << 5));
		} else {
			($pos_info = ($pos_info & ~(0x3f << 5)) | (0 << 5));
		}
	} elsif ($her_pieces & $to_mask) {
		# No need to check for en passant because pawn moves reset the
		# half-move clock anyway.
		$self->[CP_POS_HALF_MOVE_CLOCK]
				= $self->[CP_POS_REVERSIBLE_CLOCK] = 0;
		($pos_info = ($pos_info & ~(0x3f << 5)) | (0 << 5));
	} elsif ($old_castling != $new_castling) {
		$self->[CP_POS_REVERSIBLE_CLOCK] = 0;
		++$self->[CP_POS_HALF_MOVE_CLOCK];
		($pos_info = ($pos_info & ~(0x3f << 5)) | (0 << 5));
	} else {
		++$self->[CP_POS_HALF_MOVE_CLOCK];
		++$self->[CP_POS_REVERSIBLE_CLOCK];
		($pos_info = ($pos_info & ~(0x3f << 5)) | (0 << 5));
	}

	# Move all pieces involved.
	if ($captured != CP_NO_PIECE) {
		$self->[CP_POS_WHITE_PIECES + !$to_move] ^= $captured_mask;
		$self->[$captured] ^= $captured_mask;
		(($move) = (($move) & ~0x1c0000) | (($captured) & 0x7) << 18);
	}

	$self->[CP_POS_WHITE_PIECES + $to_move] ^= $move_mask;
	$self->[$piece] ^= $move_mask;

	# It is better to overwrite the castling rights unconditionally because
	# it safes branches.  There is one edge case, where a pawn captures a
	# rook that is on its initial position.  In that case, the castling
	# rights may have to be updated.
	($pos_info = ($pos_info & ~0xf) | $new_castling);

	if ($promote) {
		$self->[CP_POS_PAWNS] ^= $to_mask;
		$self->[$promote] ^= $to_mask;
	}

	(($move) = (($move) & ~0x20_0000) | (($to_move) & 0x1) << 21);
	my @undo_info = ($move, $captured_mask, @state);

	++$self->[CP_POS_HALF_MOVES];
	($pos_info = ($pos_info & ~(1 << 4)) | (!$to_move << 4));

	# The material balance is stored in the most signicant bits.  It is
	# already left-shifted 19 bit in the lookup table so that we can
	# simply add it.
	$pos_info += $material_deltas[$to_move | ($promote << 1) | ($captured << 4)];

	my $signature = $state[CP_POS_SIGNATURE - CP_POS_HALF_MOVE_CLOCK];

	if ($old_castling != $new_castling) {
		$zk_update ^= $zk_castling[$old_castling]
			^ $zk_castling[$new_castling];
	}

	# For the signature lookup we have to replace the real captured piece
	# because it may be a king which is interpreted as a pawn captured en
	# passant.
	$signature ^= $zk_update
		^ $zk_move_masks[($zk_captured << 18) | ($move & 0x23_ffff)];

	$self->[CP_POS_SIGNATURE] = $signature;

	(do {	my $c = (($pos_info & (1 << 4)) >> 4);	my $kings = $self->[CP_POS_KINGS]		& ($c ? $self->[CP_POS_BLACK_PIECES] : $self->[CP_POS_WHITE_PIECES]);	my $king_shift = (do {	my $A = $kings - 1 - ((($kings - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});	($pos_info = ($pos_info & ~(0x3f << 11)) | ($king_shift << 11));	my $checkers = $self->[CP_POS_IN_CHECK] = (do {	my $her_color = !$c;	my $her_pieces = $self->[CP_POS_WHITE_PIECES + $her_color];	my $occupancy = $self->[CP_POS_WHITE_PIECES + $c] | $her_pieces;	my $queens = $self->[CP_POS_QUEENS];	$her_pieces		& (($pawn_masks[$c]->[2]->[$king_shift] & $self->[CP_POS_PAWNS])			| ($knight_attack_masks[$king_shift] & $self->[CP_POS_KNIGHTS])			| ($king_attack_masks[$king_shift] & $self->[CP_POS_KINGS])			| (CP_MAGICMOVESBDB->[$king_shift][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$king_shift]) * CP_MAGICMOVES_B_MAGICS->[$king_shift]) >> 55) & ((1 << (64 - 55)) - 1)] & ($queens | $self->[CP_POS_BISHOPS]))			| (CP_MAGICMOVESRDB->[$king_shift][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$king_shift]) * CP_MAGICMOVES_R_MAGICS->[$king_shift]) >> 52) & ((1 << (64 - 52)) - 1)] & ($queens | $self->[CP_POS_ROOKS])));});	if ($checkers) {		if ($checkers & ($checkers - 1)) {			($pos_info = ($pos_info & ~(0x3 << 17)) | (CP_EVASION_KING_MOVE << 17));		} elsif ($checkers & ($self->[CP_POS_KNIGHTS] | ($self->[CP_POS_PAWNS]))) {			($pos_info = ($pos_info & ~(0x3 << 17)) | (CP_EVASION_CAPTURE << 17));			$self->[CP_POS_EVASION_SQUARES] = $checkers;		} else {			($pos_info = ($pos_info & ~(0x3 << 17)) | (CP_EVASION_ALL << 17));			my $piece_shift = (do {	my $A = $checkers - 1 - ((($checkers - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});			my ($attack_type, undef, $attack_ray) =				@{$common_lines[$king_shift]->[$piece_shift]};			if ($attack_ray) {				$self->[CP_POS_EVASION_SQUARES] = $attack_ray;			} else {				$self->[CP_POS_EVASION_SQUARES] = $checkers;			}		}	}	$self->[CP_POS_INFO] = $pos_info;});

	return \@undo_info;
}

sub undoMove {
	my ($self, $undo_info) = @_;

	my ($move, $captured_mask, @state) = @$undo_info;

	my ($from, $to, $promote, $piece, $captured) =
		((($move >> 6) & 0x3f), (($move) & 0x3f), (($move >> 12) & 0x7),
		 (($move >> 15) & 0x7), (($move >> 18) & 0x7));

	my $move_mask = (1 << $from) | (1 << $to);
	my $to_move = !((($self->[CP_POS_INFO] & (1 << 4)) >> 4));

	# Castling?
	if ($piece == CP_KING && ((($from - $to) & 0x3) == 0x2)) {
		# Restore the rook.
		my $rook_move_mask = $castling_rook_move_masks[$to];

		$self->[CP_POS_WHITE_PIECES + $to_move] ^= $rook_move_mask;
		$self->[CP_POS_ROOKS] ^= $rook_move_mask;
	}

	$self->[CP_POS_WHITE_PIECES + $to_move ] ^= $move_mask;

	if ($promote) {
		my $remove_mask = 1 << $to;
		$self->[CP_POS_PAWNS] |= 1 << $from;
		$self->[$promote] ^= $remove_mask;
	} else {
		$self->[$piece] ^= $move_mask;
	}

	if ($captured) {
		$self->[CP_POS_WHITE_PIECES + !$to_move] |= $captured_mask;
		$self->[$captured] |= $captured_mask;
	}

	@$self[CP_POS_HALF_MOVE_CLOCK .. CP_POS_IN_CHECK] = @state;

	# FIXME! Copy as well?
	--($self->[CP_POS_HALF_MOVES]);
}

sub bMagic {
	my ($self, $shift, $occupancy) = @_;

	return CP_MAGICMOVESBDB->[$shift][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$shift]) * CP_MAGICMOVES_B_MAGICS->[$shift]) >> 55) & ((1 << (64 - 55)) - 1)];
}

sub rMagic {
	my ($self, $shift, $occupancy) = @_;

	return CP_MAGICMOVESRDB->[$shift][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$shift]) * CP_MAGICMOVES_R_MAGICS->[$shift]) >> 52) & ((1 << (64 - 52)) - 1)];
}

# Position info methods.
sub castlingRights {
	my ($self) = @_;

	return ($self->[CP_POS_INFO] & 0xf);
}

sub whiteKingSideCastlingRight {
	my ($self) = @_;

	return ($self->[CP_POS_INFO] & (1 << 0));
}

sub whiteQueenSideCastlingRight {
	my ($self) = @_;

	return ($self->[CP_POS_INFO] & (1 << 1));
}

sub blackKingSideCastlingRight {
	my ($self) = @_;

	return ($self->[CP_POS_INFO] & (1 << 2));
}

sub blackQueenSideCastlingRight {
	my ($self) = @_;

	return ($self->[CP_POS_INFO] & (1 << 3));
}

sub toMove {
	my ($self) = @_;

	return ((($self->[CP_POS_INFO] & (1 << 4)) >> 4));
}

sub enPassantShift {
	my ($self) = @_;

	return ((($self->[CP_POS_INFO] & (0x3f << 5)) >> 5));
}

sub kingShift {
	my ($self) = @_;

	return ((($self->[CP_POS_INFO] & (0x3f << 11)) >> 11));
}

sub evasion {
	my ($self) = @_;

	return ((($self->[CP_POS_INFO] & (0x3 << 17)) >> 17));
}

sub material {
	my ($self) = @_;

	return (($self->[CP_POS_INFO] >> 19));
}

# Move methods.
sub moveFrom {
	my (undef, $move) = @_;

	return (($move >> 6) & 0x3f);
}

sub moveSetFrom {
	my (undef, $move, $from) = @_;

	(($move) = (($move) & ~0xfc0) | (($from) & 0x3f) << 6);

	return $move;
}

sub moveTo {
	my (undef, $move) = @_;

	return (($move) & 0x3f);
}

sub moveSetTo {
	my (undef, $move, $to) = @_;

	(($move) = (($move) & ~0xfc0) | (($to) & 0x3f) << 6);

	return $move;
}

sub movePromote {
	my (undef, $move) = @_;

	return (($move >> 12) & 0x7);
}

sub moveSetPromote {
	my (undef, $move, $promote) = @_;

	(($move) = (($move) & ~0x7000) | (($promote) & 0x7) << 12);

	return $move;
}

sub movePiece {
	my (undef, $move) = @_;

	return (($move >> 15) & 0x7);
}

sub moveSetPiece {
	my (undef, $move, $piece) = @_;

	(($move) = (($move) & ~0x38000) | (($piece) & 0x7) << 15);

	return $move;
}

sub moveCaptured {
	my (undef, $move) = @_;

	return (($move >> 18) & 0x7);
}

sub moveSetCaptured {
	my (undef, $move, $piece) = @_;

	(($move) = (($move) & ~0x1c0000) | (($piece) & 0x7) << 18);

	return $move;
}

sub moveColor {
	my (undef, $move) = @_;

	return (($move >> 21) & 0x1);
}

sub moveSetColor {
	my (undef, $move, $color) = @_;

	(($move) = (($move) & ~0x20_0000) | (($color) & 0x1) << 21);

	return $move;
}

sub moveCoordinateNotation {
	my (undef, $move) = @_;

	return chr(97 + ((($move >> 6) & 0x3f) & 0x7)) . (1 + ((($move >> 6) & 0x3f) >> 3)) . chr(97 + ((($move) & 0x3f) & 0x7)) . (1 + ((($move) & 0x3f) >> 3)) . CP_PIECE_CHARS->[CP_BLACK]->[(($move >> 12) & 0x7)];
}

sub LAN {
	&moveCoordinateNotation;
}

sub SEE {
	my ($self, $move) = @_;

	my $to = (($move) & 0x3f);
	my $from = (($move >> 6) & 0x3f);
	my $not_from_mask = ~(1 << ($from));
	my $pos_info = $self->[CP_POS_INFO];
	my $ep_shift = (($pos_info & (0x3f << 5)) >> 5);
	my $move_is_ep = ($ep_shift && $to == $ep_shift
		&& (($move >> 15) & 0x7) == CP_PAWN);
	my $white = $self->[CP_POS_WHITE_PIECES];
	my $black = $self->[CP_POS_BLACK_PIECES];
	my $occupancy = $white | $black;

	# FIXME! This is possible without a branch.
	if ($move_is_ep) {
		$occupancy &= ~$ep_pawn_masks[$to];
	}

	my $to_mask = 1 << $to;
	my $maybe_promote = $to_mask & (CP_1_MASK | CP_8_MASK);
	my $shifted_pawn_value = ($maybe_promote
		? CP_QUEEN_VALUE - CP_PAWN_VALUE
		: CP_PAWN_VALUE) << 8;

	my (@white_attackers, @black_attackers, $mask);

	# Now generate all squares that are attacking the target square.  This is
	# done in order of piece value.  We silently assume here this relationship:
	#
	#   P < N <= B < R < Q (< K)
	#
	# But this does not seem to be any restriction.
	#
	# For each attack vector we store the piece value shifted 8 bits to the
	# right ORed with the from shift.

	my $pawns = $self->[CP_POS_PAWNS];
	# We have to use the opposite pawn masks because we want to get the
	# attacking squares of the target square, and not the attacked squares
	# of the start square.
	$mask = $pawn_masks[CP_BLACK]->[2]->[$to] & $pawns
		& $white & $not_from_mask;
	while ($mask) {
		my $afrom = (do {	my $B = $mask & -$mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @white_attackers, ($afrom | $shifted_pawn_value);
		$mask = (($mask) & (($mask) - 1));
	}
	$mask = $pawn_masks[CP_WHITE]->[2]->[$to] & $pawns
		& $black & $not_from_mask;
	while ($mask) {
		my $afrom = (do {	my $B = $mask & -$mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @black_attackers, ($afrom | $shifted_pawn_value);
		$mask = (($mask) & (($mask) - 1));
	}

	my $knights = $self->[CP_POS_KNIGHTS];
	my $shifted_knight_value = CP_KNIGHT_VALUE << 8;
	$mask = $knight_attack_masks[$to] & $knights & $white & $not_from_mask;
	while ($mask) {
		my $afrom = (do {	my $B = $mask & -$mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @white_attackers, ($afrom | $shifted_knight_value);
		$mask = (($mask) & (($mask) - 1));
	}
	$mask = $knight_attack_masks[$to] & $knights & $black & $not_from_mask;
	while ($mask) {
		my $afrom = (do {	my $B = $mask & -$mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @black_attackers, ($afrom | $shifted_knight_value);
		$mask = (($mask) & (($mask) - 1));
	}

	my $bishop_mask = CP_MAGICMOVESBDB->[$to][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$to]) * CP_MAGICMOVES_B_MAGICS->[$to]) >> 55) & ((1 << (64 - 55)) - 1)] & $not_from_mask;
	my $rook_mask = CP_MAGICMOVESRDB->[$to][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$to]) * CP_MAGICMOVES_R_MAGICS->[$to]) >> 52) & ((1 << (64 - 52)) - 1)] & $not_from_mask;
	my $queen_mask = $bishop_mask | $rook_mask;

	my $bishops = $self->[CP_POS_BISHOPS];
	my $shifted_bishop_value = CP_BISHOP_VALUE << 8;
	$mask = $bishop_mask & $bishops & $white;
	while ($mask) {
		my $afrom = (do {	my $B = $mask & -$mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @white_attackers, ($afrom | $shifted_bishop_value);
		$mask = (($mask) & (($mask) - 1));
	}
	$mask = $bishop_mask & $bishops & $black;
	while ($mask) {
		my $afrom = (do {	my $B = $mask & -$mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @black_attackers, ($afrom | $shifted_bishop_value);
		$mask = (($mask) & (($mask) - 1));
	}

	my $rooks = $self->[CP_POS_ROOKS];
	my $shifted_rook_value = CP_ROOK_VALUE << 8;
	$mask = $rook_mask & $rooks & $white;
	while ($mask) {
		my $afrom = (do {	my $B = $mask & -$mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @white_attackers, ($afrom | $shifted_rook_value);
		$mask = (($mask) & (($mask) - 1));
	}
	$mask = $rook_mask & $rooks & $black;
	while ($mask) {
		my $afrom = (do {	my $B = $mask & -$mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @black_attackers, ($afrom | $shifted_rook_value);
		$mask = (($mask) & (($mask) - 1));
	}

	my $queens = $self->[CP_POS_QUEENS];
	my $shifted_queen_value = CP_QUEEN_VALUE << 8;
	$mask = $queen_mask & $queens & $white;
	while ($mask) {
		my $afrom = (do {	my $B = $mask & -$mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @white_attackers, ($afrom | $shifted_queen_value);
		$mask = (($mask) & (($mask) - 1));
	}
	$mask = $queen_mask & $queens & $black;
	while ($mask) {
		my $afrom = (do {	my $B = $mask & -$mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @black_attackers, ($afrom | $shifted_queen_value);
		$mask = (($mask) & (($mask) - 1));
	}

	my $kings = $self->[CP_POS_KINGS];
	my $shifted_king_value = 9999 << 8;
	$mask = $king_attack_masks[$to] & $kings & $white;
	if ($mask) {
		my $afrom = (do {	my $A = $mask - 1 - ((($mask - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @white_attackers, ($afrom | $shifted_king_value);
	}
	$mask = $king_attack_masks[$to] & $kings & $black;
	if ($mask) {
		my $afrom = (do {	my $A = $mask - 1 - ((($mask - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});

		push @black_attackers, ($afrom | $shifted_king_value);
	}

	$occupancy &= $not_from_mask;

	my $promote = (($move >> 12) & 0x7);

	my $captured;
	if ($move_is_ep || ($to_mask & $pawns)) {
		$captured = CP_PAWN;
	} elsif ($to_mask & $knights) {
		$captured = CP_KNIGHT;
	} elsif ($to_mask & $bishops) {
		$captured = CP_BISHOP;
	} elsif ($to_mask & $rooks) {
		$captured = CP_ROOK;
	} elsif ($to_mask & $queens) {
		$captured = CP_QUEEN;
	} else {
		# For SEE purposes we have to assume that we do not underpromote.
		$captured = CP_NO_PIECE;
	}

	my $side_to_move = !((($self->[CP_POS_INFO] & (1 << 4)) >> 4));
	my @gain = ($piece_values[$captured]);
	my $attacker_value = $piece_values[(($move >> 15) & 0x7)];
	if ($promote) {
		$attacker_value = $piece_values[$promote];
		$gain[0] += $attacker_value - CP_PAWN_VALUE;
	}

	my $sliding_mask = $bishops | $rooks | $queens;
	my $sliding_rooks_mask = $rooks | $queens;
	my $sliding_bishops_mask = $bishops | $queens;
	my $depth = 0;
	my @attackers = (\@white_attackers, \@black_attackers);

	while (1) {
		++$depth;

		# FIXME! Rather remember the last gain in order to save an array
		# dereferencing.
		$gain[$depth] = $attacker_value - $gain[$depth - 1];

		# Add x-ray attackers.
		my $obscured_mask = $obscured_masks[$from]->[$to];
		if ($sliding_mask & $obscured_mask) {
			# This is the slow part.
			my $is_rook_move = (($from & 7) == ($to & 7))
				|| (($from & 56) == ($to & 56));
			my $piece;
			if ($is_rook_move && ($obscured_mask & $sliding_rooks_mask)) {
				$mask = $sliding_rooks_mask & CP_MAGICMOVESRDB->[$to][(((($occupancy) & CP_MAGICMOVES_R_MASK->[$to]) * CP_MAGICMOVES_R_MAGICS->[$to]) >> 52) & ((1 << (64 - 52)) - 1)];
				$piece = CP_ROOK;
			} elsif (!$is_rook_move && ($obscured_mask & $sliding_bishops_mask)) {
				$mask = $sliding_bishops_mask & CP_MAGICMOVESBDB->[$to][(((($occupancy) & CP_MAGICMOVES_B_MASK->[$to]) * CP_MAGICMOVES_B_MAGICS->[$to]) >> 55) & ((1 << (64 - 55)) - 1)];
				$piece = CP_BISHOP;
			}
			if ($obscured_mask & $mask) {
				my $piece_mask;

				if ($from > $to) {
					$piece_mask = (do {	my $B = $obscured_mask & $mask;	if ($B & 0x8000_0000_0000_0000) {		0x8000_0000_0000_0000;	} else {		$B |= $B >> 1;		$B |= $B >> 2;		$B |= $B >> 4;		$B |= $B >> 8;		$B |= $B >> 16;		$B |= $B >> 32;		$B - ($B >> 1);	}});
				} else {
					$piece_mask = (($obscured_mask & $mask) & -($obscured_mask & $mask));
				}
				if ($piece_mask) {
					my $color;
					if ($piece_mask & $white) {
						$color = CP_WHITE;
					} else {
						$color = CP_BLACK;
					}
					if ($piece_mask & $queens) {
						$piece = CP_QUEEN;
					}

					# Now insert the x-ray attacker into the list.  Since the
					# piece is encoded in the upper bytes, we can do a simple,
					# unmasked comparison.
					my $attackers_array = $attackers[$color];
					my $item = ($piece_values[$piece] << 8)
						| (do {	my $A = $piece_mask - 1 - ((($piece_mask - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
					unshift @$attackers_array, $item;
					foreach my $i (0.. @$attackers_array - 2) {
						last if $attackers_array->[$i] <= $attackers_array->[$i + 1];
						($attackers_array->[$i], $attackers_array->[$i+1])
							= ($attackers_array->[$i + 1], $attackers_array->[$i]);
					}
				}
			}
		}

		my $attacker_def = shift @{$attackers[$side_to_move]};
		if (!$attacker_def) {
			last;
		}

		$attacker_value = $attacker_def >> 8;
		$from = $attacker_def & 0xff;

		# Can we prune?
		if ((((-$gain[$depth - 1]) > ($gain[$depth])) ? (-$gain[$depth - 1]) : ($gain[$depth])) < 0) {
			last;
		}

		$occupancy -= (1 << $from);

		$side_to_move = !$side_to_move;
	}

	while (--$depth) {
		$gain[$depth - 1]= -((((-$gain[$depth - 1]) > ($gain[$depth])) ? (-$gain[$depth - 1]) : ($gain[$depth])));
	}

	return $gain[0];
}

sub parseMove {
	my ($self, $notation) = @_;

	my $move;

	if ($notation =~ /^([a-h][1-8])([a-h][1-8])([qrbn])?$/) {
		$move = $self->__parseUCIMove(map { lc $_ } ($1, $2, $3))
			or return;
	} else {
		$move = $self->__parseSAN($notation) or return;
	}

	my $piece;
	my $from_mask = 1 << ((($move >> 6) & 0x3f));
	if ($from_mask & $self->[CP_POS_PAWNS]) {
		$piece = CP_PAWN;
	} elsif ($from_mask & $self->[CP_POS_KNIGHTS]) {
		$piece = CP_KNIGHT;
	} elsif ($from_mask & $self->[CP_POS_BISHOPS]) {
		$piece = CP_BISHOP;
	} elsif ($from_mask & $self->[CP_POS_ROOKS]) {
		$piece = CP_ROOK;
	} elsif ($from_mask & $self->[CP_POS_QUEENS]) {
		$piece = CP_QUEEN;
	} elsif ($from_mask & $self->[CP_POS_KINGS]) {
		$piece = CP_KING;
	} else {
		require Carp;
		Carp::croak(__"Illegal move: start square is empty.\n");
	}

	(($move) = (($move) & ~0x38000) | (($piece) & 0x7) << 15);

	my $captured = CP_NO_PIECE;
	my $to_mask = 1 << ((($move) & 0x3f));
	if ($to_mask & $self->[CP_POS_PAWNS]) {
		$captured = CP_PAWN;
	} elsif ($to_mask & $self->[CP_POS_KNIGHTS]) {
		$captured = CP_KNIGHT;
	} elsif ($to_mask & $self->[CP_POS_BISHOPS]) {
		$captured = CP_BISHOP;
	} elsif ($to_mask & $self->[CP_POS_ROOKS]) {
		$captured = CP_ROOK;
	} elsif ($to_mask & $self->[CP_POS_QUEENS]) {
		$captured = CP_QUEEN;
	} elsif ($to_mask & $self->[CP_POS_KINGS]) {
		$captured = CP_KING;
	} elsif ($piece == CP_PAWN && $self->enPassantShift
	         && ((($move) & 0x3f)) == $self->enPassantShift) {
		$captured = CP_PAWN;
	}
	(($move) = (($move) & ~0x1c0000) | (($captured) & 0x7) << 18);

	(($move) = (($move) & ~0x20_0000) | (($self->toMove) & 0x1) << 21);

	return $move;
}

sub __parseUCIMove {
	my ($class, $from_square, $to_square, $promote) = @_;

	my $move = 0;
	my $from = $class->squareToShift($from_square);
	my $to = $class->squareToShift($to_square);

	return if $from < 0;
	return if $from > 63;
	return if $to < 0;
	return if $to > 63;

	(($move) = (($move) & ~0xfc0) | (($from) & 0x3f) << 6);
	(($move) = (($move) & ~0x3f) | (($to) & 0x3f));

	if ($promote) {
		my %pieces = (
			q => CP_QUEEN,
			r => CP_ROOK,
			b => CP_BISHOP,
			n => CP_KNIGHT,
		);

		(($move) = (($move) & ~0x7000) | (($pieces{lc $promote} or return) & 0x7) << 12);
	}

	return $move;
}

sub bitboardPopcount {
	my (undef, $bitboard) = @_;

	my $count;
	{ my $_b = $bitboard; for ($count = 0; $_b; ++$count) { $_b &= $_b - 1; } };

	return $count;
}

sub bitboardClearLeastSet {
	my (undef, $bitboard) = @_;

	return (($bitboard) & (($bitboard) - 1));
}

sub bitboardClearButLeastSet {
	my (undef, $bitboard) = @_;

	return (($bitboard) & -($bitboard));
}

sub bitboardCountIsolatedTrailingZbits {
	my (undef, $bitboard) = @_;

	return (do {	my $A = $bitboard - 1 - ((($bitboard - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
}

sub bitboardCountTrailingZbits {
	my (undef, $bitboard) = @_;

	return (do {	my $B = $bitboard & -$bitboard;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
}

sub bitboardMoreThanOneSet {
	my (undef, $bitboard) = @_;

	return ($bitboard && ($bitboard & ($bitboard - 1)));
}

sub insufficientMaterial {
	my ($self) = @_;

	# FIXME! Once we distinguish black and white material (should we?),
	# we can try to take an early exit here if any of the two sides has
	# more material than a bishop.

	# All of these are sufficient to mate.
	if ($self->[CP_POS_PAWNS] | $self->[CP_POS_ROOKS] | $self->[CP_POS_QUEENS]) {
		return;
	}

	# There is neither a queen nor a rook nor a pawn.  Two or more minor
	# pieces on one side can always mate.
	my $not_kings = ~$self->[CP_POS_KINGS];

	my $white = $self->[CP_POS_WHITE_PIECES];
	my $white_minor_pieces = $white & $not_kings;
	if (($white_minor_pieces && ($white_minor_pieces & ($white_minor_pieces - 1)))) {
		return;
	}

	my $black = $self->[CP_POS_BLACK_PIECES];
	my $black_minor_pieces = $black & $not_kings;
	if (($black_minor_pieces && ($black_minor_pieces & ($black_minor_pieces - 1)))) {
		return;
	}

	# One minor piece against a lone king cannot mate.
	if(!($white_minor_pieces && $black_minor_pieces)) {
		return 1;
	}

	# Both sides have exactly one minor piece.  The only combination that
	# is a draw is KBKB with bishops of different color.  That means, that
	# both sides can mate if a knight is on the board.
	if ($self->[CP_POS_KNIGHTS]) {
		return;
	}

	# Every side has one bishop.  It is not necessarily a draw, if they are
	# on different colored squares.
	my $bishops = $self->[CP_POS_BISHOPS];
	if (!!($white & $bishops & CP_WHITE_MASK)
	    != !!($black & $bishops & CP_BLACK_MASK)) {
		return;
	}

	return 1;
}

sub __updateZobristKey {
	my ($self) = @_;

	my $signature = 0;
	my $piece_mask;

	my ($pawns, $knights, $bishops, $rooks, $queens, $kings, $white, $black)
		= @{$self}[CP_POS_PAWNS .. CP_POS_BLACK_PIECES];

	$piece_mask = $pawns & $white;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_PAWN) << 7) | ((CP_WHITE) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $pawns & $black;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_PAWN) << 7) | ((CP_BLACK) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $knights & $white;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_KNIGHT) << 7) | ((CP_WHITE) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $knights & $black;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_KNIGHT) << 7) | ((CP_BLACK) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $bishops & $white;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_BISHOP) << 7) | ((CP_WHITE) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $bishops & $black;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_BISHOP) << 7) | ((CP_BLACK) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $rooks & $white;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_ROOK) << 7) | ((CP_WHITE) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $rooks & $black;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_ROOK) << 7) | ((CP_BLACK) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $queens & $white;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_QUEEN) << 7) | ((CP_WHITE) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $queens & $black;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_QUEEN) << 7) | ((CP_BLACK) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $kings & $white;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_KING) << 7) | ((CP_WHITE) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	$piece_mask = $kings & $black;
	while ($piece_mask) {
		my $shift = (do {	my $B = $piece_mask & -$piece_mask;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
		$signature ^= $zk_pieces[(((CP_KING) << 7) | ((CP_BLACK) << 6) | ($shift)) - 128];
		$piece_mask = (($piece_mask) & (($piece_mask) - 1));
	}

	my $pos_info = $self->[CP_POS_INFO];
	my $ep_shift = (($pos_info & (0x3f << 5)) >> 5);
	if ($ep_shift) {
		$signature ^= $zk_ep_files[$ep_shift & 0x7];
	}
	my $castling = $pos_info & 0xf;
	$signature ^= $zk_castling[$castling];

	if ((($pos_info & (1 << 4)) >> 4)) {
		$signature ^= $zk_color;
	}

	$self->[CP_POS_SIGNATURE] = $signature;

	return $signature;
}

sub __zobristKeyLookup {
	my ($self, $piece, $color, $shift) = @_;

	return $zk_pieces[((($piece) << 7) | (($color) << 6) | ($shift)) - 128];
}

sub __zobristKeyLookupByIndex {
	my ($self, $index) = @_;

	return $zk_pieces[$index];
}

sub __zobristKeyDump {
	my ($self) = @_;

	my $output = "Pieces\n======\n\n";
	for (my $i = 0; $i < 768; ++$i) {
		$output .= sprintf '% 4u:', $i;
		my $s = $i + 128;
		my $pc = $s >> 7;
		if ($pc && $pc <= CP_KING) {
			my $shift = $s & 63;
			my $co = ($s >> 6) & 1;
			my $square = $self->shiftToSquare($shift);
			my $piece_char = CP_PIECE_CHARS->[$co]->[$pc];
			$output .= "$piece_char:$square:";
		} else {
			$output .= '     ';
		}
		$output .= sprintf " 0x%016x (%d)\n", $zk_pieces[$i], $zk_pieces[$i];
	}

	$output .= "\nEn-Passant Files\n";
	$output .= "================\n\n";
	foreach my $file (CP_FILE_A .. CP_FILE_H) {
		my $char = chr($file + ord('a'));
		$output .= sprintf "$char: 0x%016x (%d)\n", $zk_ep_files[$file], $zk_ep_files[$file];
	}

	$output .= "\nCastling States\n";
	$output .= "===============\n\n";
	foreach my $castling (0 .. 15) {
		my $castle = '';
		if ($castling) {
			$castle .= 'K' if $castling & 0x1;
			$castle .= 'Q' if $castling & 0x2;
			$castle .= 'k' if $castling & 0x4;
			$castle .= 'q' if $castling & 0x8;
		} else {
			$castle = '-';
		}

		$output .= sprintf "% 2u:% 4s: 0x%016x (%d)\n", $castling, $castle, $zk_castling[$castling], $zk_castling[$castling];
	}

	$output .= "\nColor\n=====\n\n";
	$output .= sprintf "1:black: 0x%016x (%d)\n", $zk_color, $zk_color;

	return $output;
}

sub insufficientMaterial {
	my ($self) = @_;

	# FIXME! Once we distinguish black and white material (should we?),
	# we can try to take an early exit here if any of the two sides has
	# more material than a bishop.

	# All of these are sufficient to mate.
	if ($self->[CP_POS_PAWNS] | $self->[CP_POS_ROOKS] | $self->[CP_POS_QUEENS]) {
		return;
	}

	# There is neither a queen nor a rook nor a pawn.  Two or more minor
	# pieces on one side can always mate.
	my $not_kings = ~$self->[CP_POS_KINGS];

	my $white = $self->[CP_POS_WHITE_PIECES];
	my $white_minor_pieces = $white & $not_kings;
	if (($white_minor_pieces && ($white_minor_pieces & ($white_minor_pieces - 1)))) {
		return;
	}

	my $black = $self->[CP_POS_BLACK_PIECES];
	my $black_minor_pieces = $black & $not_kings;
	if (($black_minor_pieces && ($black_minor_pieces & ($black_minor_pieces - 1)))) {
		return;
	}

	# One minor piece against a lone king cannot mate.
	if(!($white_minor_pieces && $black_minor_pieces)) {
		return 1;
	}

	# Both sides have exactly one minor piece.  The only combination that
	# is a draw is KBKB with bishops of different color.  That means, that
	# both sides can mate if a knight is on the board.
	if ($self->[CP_POS_KNIGHTS]) {
		return;
	}

	# Every side has one bishop.  It is not necessarily a draw, if they are
	# on different colored squares.
	my $bishops = $self->[CP_POS_BISHOPS];
	if (!!($white & $bishops & CP_WHITE_MASK)
	    != !!($black & $bishops & CP_BLACK_MASK)) {
		return;
	}

	return 1;
}

# Do not remove this line!


my @export_accessors = qw(
	CP_POS_WHITE_PIECES CP_POS_BLACK_PIECES
	CP_POS_KINGS CP_POS_QUEENS
	CP_POS_ROOKS CP_POS_BISHOPS CP_POS_KNIGHTS CP_POS_PAWNS
	CP_POS_HALF_MOVE_CLOCK CP_POS_REVERSIBLE_CLOCK CP_POS_HALF_MOVES
	CP_POS_INFO CP_POS_SIGNATURE
	CP_POS_IN_CHECK CP_POS_EVASION_SQUARES
);

my @export_board = qw(
	CP_FILE_A CP_FILE_B CP_FILE_C CP_FILE_D
	CP_FILE_E CP_FILE_F CP_FILE_G CP_FILE_H
	CP_RANK_1 CP_RANK_2 CP_RANK_3 CP_RANK_4
	CP_RANK_5 CP_RANK_6 CP_RANK_7 CP_RANK_8
	CP_A1 CP_A2 CP_A3 CP_A4 CP_A5 CP_A6 CP_A7 CP_A8
	CP_B1 CP_B2 CP_B3 CP_B4 CP_B5 CP_B6 CP_B7 CP_B8
	CP_C1 CP_C2 CP_C3 CP_C4 CP_C5 CP_C6 CP_C7 CP_C8
	CP_D1 CP_D2 CP_D3 CP_D4 CP_D5 CP_D6 CP_D7 CP_D8
	CP_E1 CP_E2 CP_E3 CP_E4 CP_E5 CP_E6 CP_E7 CP_E8
	CP_F1 CP_F2 CP_F3 CP_F4 CP_F5 CP_F6 CP_F7 CP_F8
	CP_G1 CP_G2 CP_G3 CP_G4 CP_G5 CP_G6 CP_G7 CP_G8
	CP_H1 CP_H2 CP_H3 CP_H4 CP_H5 CP_H6 CP_H7 CP_H8
	CP_A_MASK CP_B_MASK CP_C_MASK CP_D_MASK
	CP_E_MASK CP_F_MASK CP_G_MASK CP_H_MASK
	CP_1_MASK CP_2_MASK CP_3_MASK CP_4_MASK
	CP_5_MASK CP_6_MASK CP_7_MASK CP_8_MASK
	CP_WHITE_MASK CP_BLACK_MASK
);

my @export_pieces = qw(
	CP_WHITE CP_BLACK
	CP_NO_PIECE CP_PAWN CP_KNIGHT CP_BISHOP CP_ROOK CP_QUEEN CP_KING
	CP_PAWN_VALUE CP_KNIGHT_VALUE CP_BISHOP_VALUE CP_ROOK_VALUE CP_QUEEN_VALUE
	CP_PIECE_CHARS
);

my @export_magicmoves = qw(
	CP_MAGICMOVES_B_MAGICS
	CP_MAGICMOVES_R_MAGICS
	CP_MAGICMOVES_B_MASK
	CP_MAGICMOVES_R_MASK
	CP_MAGICMOVESBDB
	CP_MAGICMOVESRDB
);

my @export_aux = qw(CP_INT_SIZE CP_CHAR_BIT CP_RANDOM_SEED);

our @EXPORT_OK = (@export_pieces, @export_board, @export_accessors,
		@export_magicmoves, @export_aux);

our %EXPORT_TAGS = (
	accessors => [@export_accessors],
	pieces => [@export_pieces],
	board => [@export_board],
	magicmoves => [@export_magicmoves],
	aux => [@export_aux],
	all => [@EXPORT_OK],
);

# Bit twiddling stuff.
use constant CP_INT_SIZE => $Config{ivsize};
use constant CP_CHAR_BIT => 8;

# Diagonals parallel to a1-h8.
use constant CP_A1A1_MASK => 0x0000000000000001;
use constant CP_B1A2_MASK => 0x0000000000000102;
use constant CP_C1A3_MASK => 0x0000000000010204;
use constant CP_D1A4_MASK => 0x0000000001020408;
use constant CP_E1A5_MASK => 0x0000000102040810;
use constant CP_F1A6_MASK => 0x0000010204081020;
use constant CP_G1A7_MASK => 0x0001020408102040;
use constant CP_H1A8_MASK => 0x0102040810204080;
use constant CP_H2B8_MASK => 0x0204081020408000;
use constant CP_H3C8_MASK => 0x0408102040800000;
use constant CP_H4D8_MASK => 0x0810204080000000;
use constant CP_H5E8_MASK => 0x1020408000000000;
use constant CP_H6F8_MASK => 0x2040800000000000;
use constant CP_H7G8_MASK => 0x4080000000000000;
use constant CP_H8H8_MASK => 0x8000000000000000;

# Diagonals parallel to h1-a8
use constant CP_H1H1_MASK => 0x0000000000000080;
use constant CP_H2G1_MASK => 0x0000000000008040;
use constant CP_H3F1_MASK => 0x0000000000804020;
use constant CP_H4E1_MASK => 0x0000000080402010;
use constant CP_H5D1_MASK => 0x0000008040201008;
use constant CP_H6C1_MASK => 0x0000804020100804;
use constant CP_H7B1_MASK => 0x0080402010080402;
use constant CP_H8A1_MASK => 0x8040201008040201;
use constant CP_G8A2_MASK => 0x4020100804020100;
use constant CP_F8A3_MASK => 0x2010080402010000;
use constant CP_E8A4_MASK => 0x1008040201000000;
use constant CP_D8A5_MASK => 0x0804020100000000;
use constant CP_C8A6_MASK => 0x0402010000000000;
use constant CP_B8A7_MASK => 0x0201000000000000;
use constant CP_A8A8_MASK => 0x0100000000000000;

# Diagonals parallel to a1-h8, the other way round.
use constant CP_A2B1_MASK => 0x0000000000000102;
use constant CP_A3C1_MASK => 0x0000000000010204;
use constant CP_A4D1_MASK => 0x0000000001020408;
use constant CP_A5E1_MASK => 0x0000000102040810;
use constant CP_A6F1_MASK => 0x0000010204081020;
use constant CP_A7G1_MASK => 0x0001020408102040;
use constant CP_A8H1_MASK => 0x0102040810204080;
use constant CP_B8H2_MASK => 0x0204081020408000;
use constant CP_C8H3_MASK => 0x0408102040800000;
use constant CP_D8H4_MASK => 0x0810204080000000;
use constant CP_E8H5_MASK => 0x1020408000000000;
use constant CP_F8H6_MASK => 0x2040800000000000;
use constant CP_G8H7_MASK => 0x4080000000000000;

# Diagonals parallel to h1-a8, the other way round.
use constant CP_G1H2_MASK => 0x0000000000008040;
use constant CP_F1H3_MASK => 0x0000000000804020;
use constant CP_E1H4_MASK => 0x0000000080402010;
use constant CP_D1H5_MASK => 0x0000008040201008;
use constant CP_C1H6_MASK => 0x0000804020100804;
use constant CP_B1H7_MASK => 0x0080402010080402;
use constant CP_A1H8_MASK => 0x8040201008040201;
use constant CP_A2G8_MASK => 0x4020100804020100;
use constant CP_A3F8_MASK => 0x2010080402010000;
use constant CP_A4E8_MASK => 0x1008040201000000;
use constant CP_A5D8_MASK => 0x0804020100000000;
use constant CP_A6C8_MASK => 0x0402010000000000;
use constant CP_A7B8_MASK => 0x0201000000000000;

@magicmoves_r_magics = (
	0x0080001020400080, 0x0040001000200040, 0x0080081000200080, 0x0080040800100080,
	0x0080020400080080, 0x0080010200040080, 0x0080008001000200, 0x0080002040800100,
	0x0000800020400080, 0x0000400020005000, 0x0000801000200080, 0x0000800800100080,
	0x0000800400080080, 0x0000800200040080, 0x0000800100020080, 0x0000800040800100,
	0x0000208000400080, 0x0000404000201000, 0x0000808010002000, 0x0000808008001000,
	0x0000808004000800, 0x0000808002000400, 0x0000010100020004, 0x0000020000408104,
	0x0000208080004000, 0x0000200040005000, 0x0000100080200080, 0x0000080080100080,
	0x0000040080080080, 0x0000020080040080, 0x0000010080800200, 0x0000800080004100,
	0x0000204000800080, 0x0000200040401000, 0x0000100080802000, 0x0000080080801000,
	0x0000040080800800, 0x0000020080800400, 0x0000020001010004, 0x0000800040800100,
	0x0000204000808000, 0x0000200040008080, 0x0000100020008080, 0x0000080010008080,
	0x0000040008008080, 0x0000020004008080, 0x0000010002008080, 0x0000004081020004,
	0x0000204000800080, 0x0000200040008080, 0x0000100020008080, 0x0000080010008080,
	0x0000040008008080, 0x0000020004008080, 0x0000800100020080, 0x0000800041000080,
	0x00FFFCDDFCED714A, 0x007FFCDDFCED714A, 0x003FFFCDFFD88096, 0x0000040810002101,
	0x0001000204080011, 0x0001000204000801, 0x0001000082000401, 0x0001FFFAABFAD1A2
);

@magicmoves_r_mask = (
	0x000101010101017E, 0x000202020202027C, 0x000404040404047A, 0x0008080808080876,
	0x001010101010106E, 0x002020202020205E, 0x004040404040403E, 0x008080808080807E,
	0x0001010101017E00, 0x0002020202027C00, 0x0004040404047A00, 0x0008080808087600,
	0x0010101010106E00, 0x0020202020205E00, 0x0040404040403E00, 0x0080808080807E00,
	0x00010101017E0100, 0x00020202027C0200, 0x00040404047A0400, 0x0008080808760800,
	0x00101010106E1000, 0x00202020205E2000, 0x00404040403E4000, 0x00808080807E8000,
	0x000101017E010100, 0x000202027C020200, 0x000404047A040400, 0x0008080876080800,
	0x001010106E101000, 0x002020205E202000, 0x004040403E404000, 0x008080807E808000,
	0x0001017E01010100, 0x0002027C02020200, 0x0004047A04040400, 0x0008087608080800,
	0x0010106E10101000, 0x0020205E20202000, 0x0040403E40404000, 0x0080807E80808000,
	0x00017E0101010100, 0x00027C0202020200, 0x00047A0404040400, 0x0008760808080800,
	0x00106E1010101000, 0x00205E2020202000, 0x00403E4040404000, 0x00807E8080808000,
	0x007E010101010100, 0x007C020202020200, 0x007A040404040400, 0x0076080808080800,
	0x006E101010101000, 0x005E202020202000, 0x003E404040404000, 0x007E808080808000,
	0x7E01010101010100, 0x7C02020202020200, 0x7A04040404040400, 0x7608080808080800,
	0x6E10101010101000, 0x5E20202020202000, 0x3E40404040404000, 0x7E80808080808000
);

@magicmoves_b_magics = (
	0x0002020202020200, 0x0002020202020000, 0x0004010202000000, 0x0004040080000000,
	0x0001104000000000, 0x0000821040000000, 0x0000410410400000, 0x0000104104104000,
	0x0000040404040400, 0x0000020202020200, 0x0000040102020000, 0x0000040400800000,
	0x0000011040000000, 0x0000008210400000, 0x0000004104104000, 0x0000002082082000,
	0x0004000808080800, 0x0002000404040400, 0x0001000202020200, 0x0000800802004000,
	0x0000800400A00000, 0x0000200100884000, 0x0000400082082000, 0x0000200041041000,
	0x0002080010101000, 0x0001040008080800, 0x0000208004010400, 0x0000404004010200,
	0x0000840000802000, 0x0000404002011000, 0x0000808001041000, 0x0000404000820800,
	0x0001041000202000, 0x0000820800101000, 0x0000104400080800, 0x0000020080080080,
	0x0000404040040100, 0x0000808100020100, 0x0001010100020800, 0x0000808080010400,
	0x0000820820004000, 0x0000410410002000, 0x0000082088001000, 0x0000002011000800,
	0x0000080100400400, 0x0001010101000200, 0x0002020202000400, 0x0001010101000200,
	0x0000410410400000, 0x0000208208200000, 0x0000002084100000, 0x0000000020880000,
	0x0000001002020000, 0x0000040408020000, 0x0004040404040000, 0x0002020202020000,
	0x0000104104104000, 0x0000002082082000, 0x0000000020841000, 0x0000000000208800,
	0x0000000010020200, 0x0000000404080200, 0x0000040404040400, 0x0002020202020200
);

@magicmoves_b_mask = (
	0x0040201008040200, 0x0000402010080400, 0x0000004020100A00, 0x0000000040221400,
	0x0000000002442800, 0x0000000204085000, 0x0000020408102000, 0x0002040810204000,
	0x0020100804020000, 0x0040201008040000, 0x00004020100A0000, 0x0000004022140000,
	0x0000000244280000, 0x0000020408500000, 0x0002040810200000, 0x0004081020400000,
	0x0010080402000200, 0x0020100804000400, 0x004020100A000A00, 0x0000402214001400,
	0x0000024428002800, 0x0002040850005000, 0x0004081020002000, 0x0008102040004000,
	0x0008040200020400, 0x0010080400040800, 0x0020100A000A1000, 0x0040221400142200,
	0x0002442800284400, 0x0004085000500800, 0x0008102000201000, 0x0010204000402000,
	0x0004020002040800, 0x0008040004081000, 0x00100A000A102000, 0x0022140014224000,
	0x0044280028440200, 0x0008500050080400, 0x0010200020100800, 0x0020400040201000,
	0x0002000204081000, 0x0004000408102000, 0x000A000A10204000, 0x0014001422400000,
	0x0028002844020000, 0x0050005008040200, 0x0020002010080400, 0x0040004020100800,
	0x0000020408102000, 0x0000040810204000, 0x00000A1020400000, 0x0000142240000000,
	0x0000284402000000, 0x0000500804020000, 0x0000201008040200, 0x0000402010080400,
	0x0002040810204000, 0x0004081020400000, 0x000A102040000000, 0x0014224000000000,
	0x0028440200000000, 0x0050080402000000, 0x0020100804020000, 0x0040201008040200
);

sub copy {
	my ($self) = @_;

	bless [@$self], ref $self;
}

sub whitePieces {
	shift->[CP_POS_WHITE_PIECES];
}

sub blackPieces {
	shift->[CP_POS_BLACK_PIECES];
}

sub kings {
	shift->[CP_POS_KINGS];
}

sub queens {
	shift->[CP_POS_QUEENS];
}

sub rooks {
	shift->[CP_POS_ROOKS];
}

sub bishops {
	shift->[CP_POS_BISHOPS];
}

sub knights {
	shift->[CP_POS_KNIGHTS];
}

sub pawns {
	shift->[CP_POS_PAWNS];
}

sub occupied {
	my ($self) = @_;

	return $self->[CP_POS_WHITE_PIECES] | $self->[CP_POS_BLACK_PIECES];
}

sub vacant {
	my ($self) = @_;

	return ~($self->[CP_POS_WHITE_PIECES] | $self->[CP_POS_BLACK_PIECES]);
}

sub halfMoves {
	shift->[CP_POS_HALF_MOVES];
}

sub halfMoveClock {
	shift->[CP_POS_HALF_MOVE_CLOCK];
}

sub reversibleClock {
	shift->[CP_POS_REVERSIBLE_CLOCK];
}

sub info {
	shift->[CP_POS_INFO];
}

sub evasionSquares {
	shift->[CP_POS_EVASION_SQUARES];
}

sub signature {
	shift->[CP_POS_SIGNATURE];
}

sub inCheck {
	shift->[CP_POS_IN_CHECK];
}

sub toFEN {
	my ($self) = @_;

	my $w_pieces = $self->[CP_POS_WHITE_PIECES];
	my $b_pieces = $self->[CP_POS_BLACK_PIECES];
	my $pieces = $w_pieces | $b_pieces;
	my $pawns = $self->[CP_POS_PAWNS];
	my $bishops = $self->[CP_POS_BISHOPS];
	my $knights = $self->[CP_POS_KNIGHTS];
	my $rooks = $self->[CP_POS_ROOKS];
	my $queens = $self->[CP_POS_QUEENS];

	my $fen = '';

	for (my $rank = CP_RANK_8; $rank >= CP_RANK_1; --$rank) {
		my $empty = 0;
		for (my $file = CP_FILE_A; $file <= CP_FILE_H; ++$file) {
			my $shift = $self->coordinatesToShift($file, $rank);
			my $mask = 1 << $shift;

			if ($mask & $pieces) {
				if ($empty) {
					$fen .= $empty;
					$empty = 0;
				}

				if ($mask & $w_pieces) {
					if ($mask & $pawns) {
						$fen .= 'P';
					} elsif ($mask & $knights) {
						$fen .= 'N';
					} elsif ($mask & $bishops) {
						$fen .= 'B';
					} elsif ($mask & $rooks) {
						$fen .= 'R';
					} elsif ($mask & $queens) {
						$fen .= 'Q';
					} else {
						$fen .= 'K';
					}
				} elsif ($mask & $b_pieces) {
					if ($mask & $pawns) {
						$fen .= 'p';
					} elsif ($mask & $knights) {
						$fen .= 'n';
					} elsif ($mask & $bishops) {
						$fen .= 'b';
					} elsif ($mask & $rooks) {
						$fen .= 'r';
					} elsif ($mask & $queens) {
						$fen .= 'q';
					} else {
						$fen .= 'k';
					}
				}
			} else {
				++$empty;
			}

			if ($file == CP_FILE_H) {
				if ($empty) {
					$fen .= $empty;
					$empty = 0;
				}
				if ($rank != CP_RANK_1) {
					$fen .= '/';
				}
			}
		}
	}

	$fen .= ($self->toMove == CP_WHITE) ? ' w ' : ' b ';

	my $castling = $self->castlingRights;

	if ($castling) {
		my $castle = '';
		$castle .= 'K' if $castling & 0x1;
		$castle .= 'Q' if $castling & 0x2;
		$castle .= 'k' if $castling & 0x4;
		$castle .= 'q' if $castling & 0x8;
		$fen .= "$castle ";
	} else {
		$fen .= '- ';
	}

	if ($self->enPassantShift) {
		$fen .= $self->shiftToSquare($self->enPassantShift);
	} else {
		$fen .= '-';
	}

	$fen .= sprintf ' %u %u', $self->[CP_POS_HALF_MOVE_CLOCK],
			1 + ($self->[CP_POS_HALF_MOVES] >> 1);

	return $fen;
}

sub board {
	my ($self) = @_;

	my $w_pieces = $self->[CP_POS_WHITE_PIECES];
	my $b_pieces = $self->[CP_POS_BLACK_PIECES];
	my $pieces = $w_pieces | $b_pieces;
	my $pawns = $self->[CP_POS_PAWNS];
	my $bishops = $self->[CP_POS_BISHOPS];
	my $knights = $self->[CP_POS_KNIGHTS];
	my $rooks = $self->[CP_POS_ROOKS];
	my $queens = $self->[CP_POS_QUEENS];

	my $ep_shift = $self->enPassantShift;
	my $board = "  a b c d e f g h\n";
	if ($self->blackQueenSideCastlingRight) {
		$board .= " +-+-<-<-<-";
	} else {
		$board .= " +-+-+-+-+-";
	}
	if ($self->blackKingSideCastlingRight) {
		$board .= ">->-+-+\n";
	} else {
		$board .= "+-+-+-+\n";
	}

	for (my $rank = CP_RANK_8; $rank >= CP_RANK_1; --$rank) {
		$board .= ($rank + 1) . '|';
		for (my $file = CP_FILE_A; $file <= CP_FILE_H; ++$file) {
			my $shift = $self->coordinatesToShift($file, $rank);
			my $mask = 1 << $shift;

			$board .= ' ' if $file != CP_FILE_A;
			if ($mask & $pieces) {
				if ($mask & $w_pieces) {
					if ($mask & $pawns) {
						$board .= 'P';
					} elsif ($mask & $knights) {
						$board .= 'N';
					} elsif ($mask & $bishops) {
						$board .= 'B';
					} elsif ($mask & $rooks) {
						$board .= 'R';
					} elsif ($mask & $queens) {
						$board .= 'Q';
					} else {
						$board .= 'K';
					}
				} elsif ($mask & $b_pieces) {
					if ($mask & $pawns) {
						$board .= 'p';
					} elsif ($mask & $knights) {
						$board .= 'n';
					} elsif ($mask & $bishops) {
						$board .= 'b';
					} elsif ($mask & $rooks) {
						$board .= 'r';
					} elsif ($mask & $queens) {
						$board .= 'q';
					} else {
						$board .= 'k';
					}
				}
			} elsif ($ep_shift && $shift == $ep_shift) {
				if ($self->toMove == CP_WHITE) {
					$board .= 'v';
				} else {
					$board .= '^';
				}
			} else {
				$board .= '.';
			}

			if ($file == CP_FILE_H) {
			}
		}
		$board .= '|' . ($rank + 1) . "\n";
	}

	if ($self->whiteQueenSideCastlingRight) {
		$board .= " +-+-<-<-<-";
	} else {
		$board .= " +-+-+-+-+-";
	}
	if ($self->whiteKingSideCastlingRight) {
		$board .= ">->-+-+\n";
	} else {
		$board .= "+-+-+-+\n";
	}

	return $board;
}

sub legalMoves {
	my ($self) = @_;

	my @legal;

	foreach my $move ($self->pseudoLegalMoves) {
		# Sets also captured piece and color.
		my $undo_info = $self->doMove($move) or next;
		push @legal, $undo_info->[0];
		$self->undoMove($undo_info);
	}

	return @legal;
}

sub dumpBitboard {
	my (undef, $bitboard) = @_;

	my $output = "  a b c d e f g h\n";
	foreach my $rank (reverse(0 .. 7)) {
		$output .= $rank + 1;
		foreach my $file (0 .. 7) {
			my $shift = ($rank << 3) + $file;
			if ($bitboard & 1 << $shift) {
				$output .= ' x';
			} else {
				$output .= ' .';
			}
		}
		$output .= ' ' . ($rank + 1) . "\n";
	}
	$output .= "  a b c d e f g h\n";

	return $output;
}

sub SAN {
	my ($self, $move, $use_pseudo_legal_moves) = @_;

	my ($from, $to, $promote, $piece) = (
		$self->moveFrom($move),
		$self->moveTo($move),
		$self->movePromote($move),
		$self->movePiece($move),
	);

	if ($piece == CP_KING && ((($from - $to) & 0x3) == 0x2)) {
		my $to_mask = 1 << $to;
		if ($to_mask & CP_G_MASK) {
			return 'O-O';
		} else {
			return 'O-O-O';
		}
	}

	# Avoid extra hassle for queen moves.
	my @pieces = ('', '', 'N', 'B', 'R', 'Q', 'K');

	my $san = $pieces[$piece];

	my $from_board = $self->[CP_POS_WHITE_PIECES + $self->toMove]
		& $self->[CP_POS_BLACK_PIECES + $piece];

	# Or use legalMoves?
	my @legal_moves = $self->legalMoves or return;
	my @cmoves = $use_pseudo_legal_moves
		? $self->pseudoLegalMoves : @legal_moves;
	return if !@cmoves;

	my (%files, %ranks);
	my $candidates = 0;
	# When we iterate over the moves make sure that we do not count moves that
	# just differ in the promotion piece, four times.  We do that by just
	# stripping off the promotion piece and making the array unique.
	my %cmoves = map { $_ => 1 }
			map { $self->moveSetPromote($_, CP_NO_PIECE) }
			@cmoves;
	foreach my $cmove (keys %cmoves) {
		my ($cfrom, $cto, $cpiece) = ($self->moveFrom($cmove), $self->moveTo($cmove), $self->movePiece($cmove));
		next if $cto != $to;
		next if $cpiece != $piece;

		++$candidates;
		my ($ffile, $frank) = $self->shiftToCoordinates($cfrom);
		++$files{$ffile};
		++$ranks{$frank};
	}

	my $to_mask = 1 << $to;
	my $to_move = $self->toMove;
	my $her_pieces = $self->[CP_POS_WHITE_PIECES + !$to_move];
	my $ep_shift = $self->enPassantShift;
	my @files = ('a' .. 'h');
	my @ranks = ('1' .. '8');
	my ($from_file, $from_rank) = $self->shiftToCoordinates($from);

	if ($candidates > 1) {
		my $numfiles = keys %files;
		my $numranks = keys %ranks;

		if ($numfiles == $candidates) {
			$san .= $files[$from_file];
		} elsif ($numranks == $candidates) {
			$san .= $ranks[$from_rank];
		} else {
			$san .= "$files[$from_file]$ranks[$from_rank]";
		}
	}

	if (($to_mask & $her_pieces)
	    || ($ep_shift && $piece == CP_PAWN && $to == $ep_shift)) {
		# Capture.  For pawn captures we always add the file unless it was
		# already added.
		if ($piece == CP_PAWN && !length $san) {
			$san .= $files[$from_file];
		}
		$san .= 'x';
	}

	$san .= $self->shiftToSquare($to);

	my $promote = $self->movePromote($move);
	if ($promote) {
		$san .= "=$pieces[$promote]";
	}

	my $copy = $self->copy;
	if ($copy->doMove($move) && $copy->inCheck) {
		my @moves = $copy->legalMoves;
		if (!@moves) {
			$san .= '#';
		} else {
			$san .= '+';
		}
	}

	return $san;
}

sub equals {
	my ($self, $other) = @_;

	return if @$self != @$other;

	for (my $i = 0; $i < @$self; ++$i) {
		next if $i == CP_POS_EVASION_SQUARES && !$self->[CP_POS_IN_CHECK];
		return if $self->[$i] != $other->[$i];
	}

	return $self;
}

sub RNG {
	$cp_random ^= ($cp_random << 21);
	$cp_random ^= (($cp_random >> 35) & 0x1fff_ffff);
	$cp_random ^= ($cp_random << 4);

	return $cp_random;
}

sub __parseSAN {
	my ($self, $move) = @_;

	# First clean-up but in multiple steps.
	my $san = $move;

	# First delete whitespace and dots.
	$san =~ s/[ \011-\015\.]//g;

	# So that we can strip-off s possible en-passant notation.
	$san =~ s/ep//gi;

	# And now other noise.
	$san =~ s/[^a-h0-8pnbrqko]//gi;

	my $pattern;

	my $to_move = $self->toMove;
	if ($san =~ /^[0oO][0oO]([0oO])?$/) {
		my $queen_side = $1;

		if ($to_move == CP_WHITE) {
			if ($queen_side) {
				$pattern = 'Ke1c1';
			} else {
				$pattern = 'Ke1g1';
			}
		} else {
			if ($queen_side) {
				$pattern = 'Ke8c8';
			} else {
				$pattern = 'Ke8g8';
			}
		}
	} else {
		my $piece = '.',
		my $from_file = '.';
		my $to_file = '.';
		my $from_rank = '.';
		my $to_rank = '.',
		my $promote = '';

		# Before we convert to lowercase, we try to extract the moving piece
		# which must always be uppercase.
		if ($san =~ s/^([PNBRQK])//) {
			$piece = $1;
		}

		my @san = split //, lc $san;

		my %pieces = map { $_ => 1 } qw(p n b r q k);

		# Promotion?
		if (exists $pieces{$san[-1]}) {
			$promote = $san[-1];
			pop @san;
		}

		# Target rank?
		if (@san && $san[-1] >= '1' && $san[-1] <= '8') {
			$to_rank = $san[-1];
			pop @san;
		}

		# Target file?
		if (@san && $san[-1] >= 'a' && $san[-1] <= 'h') {
			$to_file = $san[-1];
			pop @san;
		}

		# From rank?
		if (@san && $san[-1] >= '1' && $san[-1] <= '8') {
			$from_rank = $san[-1];
			pop @san;
		}

		# From file?
		if (@san && $san[-1] >= 'a' && $san[-1] <= 'h') {
			$from_file = $san[-1];
			pop @san;
		}

		# Leading garbage?
		return if @san;

		$pattern = join '', $piece, 
				$from_file, $from_rank, $to_file, $to_rank, $promote;
	}

	# Get the legal moves.
	my @legal = $self->movesCoordinateNotation($self->legalMoves);

	# Prefix every move with the piece that moves.
	my @pieces = qw(X P N B R Q K);
	foreach my $move (@legal) {
		my $from_square = substr $move, 0, 2;
		my $mover = $self->pieceAtSquare($from_square);
		$move = $pieces[$mover] . $move;
	}

	my @candidates;
	@candidates = grep { /^$pattern$/ } @legal;

	# We must find exactly one candidate.  If we have 0 matches, the move
	# could not be parsed.  If we have more than 1 match, the move was
	# ambiguous.
	if (@candidates != 1 && $move !~ /^[PNBRQK]/) {
		# If no piece was explicitely specified, try again with a pawn.
		$pattern =~ s/^./P/;
		@candidates = grep { /^$pattern$/ } @legal;
	}

	return if @candidates != 1;

	$move = $candidates[0];
	return if $move !~ /^[PNBRQK]([a-h][1-8])([a-h][1-8])([qrbn])?$/;

	return $self->__parseUCIMove($1, $2, $3);
}

sub perftByUndo {
	my ($self, $depth) = @_;

	my $nodes = 0;
	my @moves = $self->pseudoLegalMoves;
	foreach my $move (@moves) {
		my $undo_info = $self->doMove($move) or next;

		if ($depth > 1) {
			$nodes += $self->perftByUndo($depth - 1);
		} else {
			++$nodes;
		}

		$self->undoMove($undo_info);
	}

	return $nodes;
}

sub perftByCopy {
	my ($class, $pos, $depth) = @_;

	my $nodes = 0;
	my @moves = $pos->pseudoLegalMoves;
	foreach my $move (@moves) {
		my $copy = bless [@$pos], 'Chess::Plisco';
		$copy->doMove($move) or next;

		if ($depth > 1) {
			$nodes += $class->perftByCopy($copy, $depth - 1);
		} else {
			++$nodes;
		}
	}

	return $nodes;
}

sub perftByUndoWithOutput {
	my ($self, $depth, $fh) = @_;

	return if $depth <= 0;

	require Time::HiRes;
	my $started = [Time::HiRes::gettimeofday()];

	my $nodes = 0;

	my @moves = $self->pseudoLegalMoves;
	foreach my $move (@moves) {
		my $undo_info = $self->doMove($move) or next;

		my $movestr = $self->moveCoordinateNotation($move);

		$fh->print("$movestr: ");

		my $subnodes;

		if ($depth > 1) {
			$subnodes = $self->perft($depth - 1);
		} else {
			$subnodes = 1;
		}

		$nodes += $subnodes;

		$fh->print("$subnodes\n");

		$self->undoMove($undo_info);
	}

	no integer;

	my $elapsed = Time::HiRes::tv_interval($started, [Time::HiRes::gettimeofday()]);

	my $nps = '+INF';
	if ($elapsed) {
		$nps = int (0.5 + $nodes / $elapsed);
	}
	$fh->print("info nodes: $nodes ($elapsed s, nps: $nps)\n");

	return $nodes;
}

sub perftByCopyWithOutput {
	my ($self, $depth, $fh) = @_;

	return if $depth <= 0;

	require Time::HiRes;
	my $started = [Time::HiRes::gettimeofday()];

	my $nodes = 0;

	my @moves = $self->pseudoLegalMoves;
	foreach my $move (@moves) {
		my $copy = bless [@$self], 'Chess::Plisco';
		$copy->doMove($move) or next;

		my $movestr = $copy->moveCoordinateNotation($move);

		$fh->print("$movestr: ");

		my $subnodes;

		if ($depth > 1) {
			$subnodes = $self->perftByCopy($copy, $depth - 1);
		} else {
			$subnodes = 1;
		}

		$nodes += $subnodes;

		$fh->print("$subnodes\n");
	}

	no integer;

	my $elapsed = Time::HiRes::tv_interval($started, [Time::HiRes::gettimeofday()]);

	my $nps = '+INF';
	if ($elapsed) {
		$nps = int (0.5 + $nodes / $elapsed);
	}
	$fh->print("info nodes: $nodes ($elapsed s, nps: $nps)\n");

	return $nodes;
}

sub coordinatesToShift {
	my (undef, $file, $rank) = @_;

	return ($rank << 3) + $file;
}

sub coordinatesToSquare {
	my (undef, $file, $rank) = @_;

	return chr(97 + $file) . (1 + $rank);
}

sub shiftToCoordinates {
	my (undef, $shift) = @_;

	my $file = $shift & 0x7;
	my $rank = $shift >> 3;

	return $file, $rank;
}

sub squareToCoordinates {
	my (undef, $square) = @_;

	return ord($square) - 97, -1 + substr $square, 1;
}

sub shiftToSquare {
	my (undef, $shift) = @_;

	my $rank = 1 + ($shift >> 3);
	my $file = $shift & 0x7;

	return sprintf '%c%u', $file + ord 'a', $rank;
}

sub squareToShift {
	my ($whatever, $square) = @_;

	if ($square !~ /^([a-h])([1-8])$/) {
		die __x("Illegal square '{square}'.\n", square => $square);
	}

	my $file = ord($1) - ord('a');
	my $rank = $2 - 1;

	return $whatever->coordinatesToShift($file, $rank);
}

sub consistent {
	my ($self) = @_;

	my $consistent = 1;

	my $w_pieces = $self->[CP_POS_WHITE_PIECES];
	my $b_pieces = $self->[CP_POS_BLACK_PIECES];

	if ($w_pieces & $b_pieces) {
		warn "White and black pieces overlap.\n";
		undef $consistent;
	}

	my $occupied = $w_pieces | $b_pieces;
	my $empty = ~$occupied;	

	my $pawns = $self->[CP_POS_PAWNS];
	my $knights = $self->[CP_POS_KNIGHTS];
	my $bishops = $self->[CP_POS_BISHOPS];
	my $rooks = $self->[CP_POS_ROOKS];
	my $queens = $self->[CP_POS_QUEENS];
	my $kings = $self->[CP_POS_KINGS];

	my $occupied_by_pieces = $pawns | $knights | $bishops | $rooks | $queens
		| $kings;
	if ($occupied_by_pieces & $empty) {
		if ($pawns & $empty) {
			warn "Orphaned pawn(s) (neither black nor white).\n";
			undef $consistent;
		}
		if ($knights & $empty) {
			warn "Orphaned knight(s) (neither black nor white).\n";
			undef $consistent;
		}
		if ($bishops & $empty) {
			warn "Orphaned bishop(s) (neither black nor white).\n";
			undef $consistent;
		}
		if ($rooks & $empty) {
			warn "Orphaned rooks(s) (neither black nor white).\n";
			undef $consistent;
		}
		if ($queens & $empty) {
			warn "Orphaned queens(s) (neither black nor white).\n";
			undef $consistent;
		}
		if ($kings & $empty) {
			warn "Orphaned king(s) (neither black nor white).\n";
			undef $consistent;
		}
	}

	my $not_occupied_by_pieces = ~$occupied_by_pieces;
	if ($not_occupied_by_pieces & $b_pieces) {
		warn "Square occupied by black without a piece.\n";
		undef $consistent;
	} elsif ($not_occupied_by_pieces & $w_pieces) {
		warn "Square occupied by white without a piece.\n";
		undef $consistent;
	}

	if ($pawns & $knights) {
		warn "Pawns and knights overlap.\n";
		undef $consistent;
	}
	if ($pawns & $bishops) {
		warn "Pawns and bishops overlap.\n";
		undef $consistent;
	}
	if ($pawns & $rooks) {
		warn "Pawns and rooks overlap.\n";
		undef $consistent;
	}
	if ($pawns & $queens) {
		warn "Pawns and queens overlap.\n";
		undef $consistent;
	}
	if ($pawns & $kings) {
		warn "Pawns and kings overlap.\n";
		undef $consistent;
	}
	if ($knights & $bishops) {
		warn "Knights and bishops overlap.\n";
		undef $consistent;
	}
	if ($knights & $rooks) {
		warn "Knights and rooks overlap.\n";
		undef $consistent;
	}
	if ($knights & $queens) {
		warn "Knights and queens overlap.\n";
		undef $consistent;
	}
	if ($knights & $kings) {
		warn "Knights and kings overlap.\n";
		undef $consistent;
	}
	if ($bishops & $rooks) {
		warn "Bishops and rooks overlap.\n";
		undef $consistent;
	}
	if ($bishops & $queens) {
		warn "Bishops and queens overlap.\n";
		undef $consistent;
	}
	if ($bishops & $kings) {
		warn "Bishops and kings overlap.\n";
		undef $consistent;
	}
	if ($queens & $kings) {
		warn "Queens and kings overlap.\n";
		undef $consistent;
	}

	return $self if $consistent;

	warn $self->dumpAll;

	return;
}


sub pieceAtSquare {
	my ($self, $square) = @_;

	return $self->pieceAtShift($self->squareToShift($square));
}

sub pieceAtCoordinates {
	my ($self, $file, $rank) = @_;

	return $self->pieceAtShift($self->coordinatesToShift($file, $rank));
}

sub pieceAtShift {
	my ($self, $shift) = @_;

	return if $shift < 0;
	return if $shift > 63;

	my $mask = 1 << $shift;
	my ($piece, $color) = (CP_NO_PIECE);
	if ($mask & $self->[CP_POS_WHITE_PIECES]) {
		$color = CP_WHITE;
	} elsif ($mask & $self->[CP_POS_BLACK_PIECES]) {
		$color = CP_BLACK;
	}

	if (defined $color) {
		if ($mask & $self->[CP_POS_PAWNS]) {
			$piece = CP_PAWN;
		} elsif ($mask & $self->[CP_POS_KNIGHTS]) {
			$piece = CP_KNIGHT;
		} elsif ($mask & $self->[CP_POS_BISHOPS]) {
			$piece = CP_BISHOP;
		} elsif ($mask & $self->[CP_POS_ROOKS]) {
			$piece = CP_ROOK;
		} elsif ($mask & $self->[CP_POS_QUEENS]) {
			$piece = CP_QUEEN;
		} else {
			$piece = CP_KING;
		}
	}

	if (wantarray) {
		return $piece, $color;
	} else {
		return $piece;
	}
}

sub moveLegal {
	my ($self, $move) = @_;

	if ($move =~ /[a-z]/i) {
		$move = $self->parseMove($move) or return;
	}

	my @legal_moves = $self->legalMoves;
	foreach my $legal_move (@legal_moves) {
		return $self if $self->moveEquivalent($legal_move, $move);
	}

	return;
}

sub applyMove {
	my ($self, $move) = @_;

	if ($move =~ /[a-z]/i) {
		$move = $self->parseMove($move) or return;
	}

	return $self->doMove($move);
}

sub unapplyMove {
	my ($self, $state) = @_;

	return if !ref $state;
	return if 'ARRAY' ne reftype $state;

	return $self->undoMove($state);
}

sub dumpAll {
	my ($self) = @_;

	my $pad19 = sub {
		my $str = $_;
		while (19 > length $str) {
			$str .= ' ';
		}

		return $str;
	};

	my $output = '';

	my $w_pieces = $self->dumpBitboard($self->[CP_POS_WHITE_PIECES]);
	my $b_pieces = $self->dumpBitboard($self->[CP_POS_BLACK_PIECES]);
	my @w_pieces = map { $pad19->() } split /\n/, $w_pieces;
	my @b_pieces = map { $pad19->() } split /\n/, $b_pieces;
	$output .= "  White               Black\n";
	for (my $i = 0; $i < @w_pieces; ++$i) {
		$output .= "$w_pieces[$i]   $b_pieces[$i]\n";
	}

	my $pawns = $self->dumpBitboard($self->[CP_POS_PAWNS]);
	my @pawns = map { $pad19->() } split /\n/, $pawns;
	my $knights = $self->dumpBitboard($self->[CP_POS_KNIGHTS]);
	my @knights = map { $pad19->() } split /\n/, $knights;
	$output .= "\n  Pawns               Knights\n";
	for (my $i = 0; $i < @pawns; ++$i) {
		$output .= "$pawns[$i]   $knights[$i]\n";
	}

	my $bishops = $self->dumpBitboard($self->[CP_POS_BISHOPS]);
	my @bishops = split /\n/, $bishops;
	my $rooks = $self->dumpBitboard($self->[CP_POS_ROOKS]);
	my @rooks = map { $pad19->() } split /\n/, $rooks;
	$output .= "\n  Bishops             Rooks\n";
	for (my $i = 0; $i < @bishops; ++$i) {
		$output .= "$bishops[$i]   $rooks[$i]\n";
	}

	my $queens = $self->dumpBitboard($self->[CP_POS_QUEENS]);
	my @queens = split /\n/, $queens;
	my $kings = $self->dumpBitboard($self->[CP_POS_KINGS]);
	my @kings = map { $pad19->() } split /\n/, $kings;
	$output .= "\n  Queens              Kings\n";
	for (my $i = 0; $i < @queens; ++$i) {
		$output .= "$queens[$i]   $kings[$i]\n";
	}

	return $output;
}

sub dumpInfo {
	my ($self) = @_;

	my $output = 'Castling: ';

	my $castling = $self->castlingRights;
	if ($castling) {
		$output .= 'K' if $castling & 0x1;
		$output .= 'Q' if $castling & 0x2;
		$output .= 'k' if $castling & 0x4;
		$output .= 'q' if $castling & 0x8;
	} else {
		$output .= '- ';
	}

	$output .= "\nTo move: ";
	if (CP_WHITE == $self->toMove) {
		$output .= "white\n";
	} else {
		$output .= "black\n";
	}

	$output .= 'En passant square: ';
	if ($self->enPassantShift) {
		$output .= $self->shiftToSquare($self->enPassantShift);
	} else {
		$output .= '-';
	}

	$output .= "\nKing to move: ";
	$output .= $self->shiftToSquare($self->kingShift);
	$output .= "\n";

	my $checkers = $self->[CP_POS_IN_CHECK];
	if ($checkers) {
		$output .= "In check: yes\n";

		my $evasion_strategy = $self->evasion;
		$output .= 'Check evasion strategies: ';
		if ($evasion_strategy == CP_EVASION_ALL) {
			$output .= "king move, capture, block\n";
		} elsif ($evasion_strategy == CP_EVASION_CAPTURE) {
			$output .= "king move, capture\n";
		} elsif ($evasion_strategy == CP_EVASION_KING_MOVE) {
			$output .= "king move\n";
		} else {
			$output .= "$evasion_strategy (?)\n";
		}

		$output .= "Check evasion squares:\n";
		$output .= $self->dumpBitboard($self->[CP_POS_EVASION_SQUARES]);

		$output .= "Checkers:\n";
		$output .= $self->dumpBitboard($self->[CP_POS_IN_CHECK]);
	} else {
		$output .= "In check: no\n";
	}

	my $signature = $self->signature;
	$output .= "Signature: $signature\n";

	return $output;
}

sub movesCoordinateNotation {
	my ($class, @moves) = @_;

	foreach my $move (@moves) {
		$move = moveCoordinateNotation(undef, $move);
	}

	return @moves;
}

sub moveNumbers {
	my ($class);

	return @move_numbers;
}

sub kingAttackMask {
	return [@king_attack_masks];
}

sub knightAttackMask {
	return [@knight_attack_masks];
}

###########################################################################
# Generate lookup tables.
###########################################################################

# This would be slightly more efficient in one giant loop but with separate
# loops for each variable, it is easier to understand and maintain.

# King attack masks.
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;

	my $mask = 0;

	# East.
	$mask |= (1 << ($shift + 1)) if $file < 7;

	# South-east.
	$mask |= (1 << ($shift - 7)) if $file < 7 && $rank > 0;

	# South.
	$mask |= (1 << ($shift - 8)) if              $rank > 0;

	# South-west.
	$mask |= (1 << ($shift - 9)) if $file > 0 && $rank > 0;

	# West.
	$mask |= (1 << ($shift - 1)) if $file > 0;

	# North-west.
	$mask |= (1 << ($shift + 7)) if $file > 0 && $rank < 7;

	# North.
	$mask |= (1 << ($shift + 8)) if              $rank < 7;

	# North-east.
	$mask |= (1 << ($shift + 9)) if $file < 7 && $rank < 7;

	$king_attack_masks[$shift] = $mask;
}

# Knight attack masks.
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;

	my $mask = 0;

	# North-north-east.
	$mask |= (1 << ($shift + 17)) if $file < 7 && $rank < 6;

	# North-east-east.
	$mask |= (1 << ($shift + 10)) if $file < 6 && $rank < 7;

	# South-east-east.
	$mask |= (1 << ($shift -  6)) if $file < 6 && $rank > 0;

	# South-south-east.
	$mask |= (1 << ($shift - 15)) if $file < 7&&  $rank > 1;

	# South-south-west.
	$mask |= (1 << ($shift - 17)) if $file > 0 && $rank > 1;

	# South-west-west.
	$mask |= (1 << ($shift - 10)) if $file > 1 && $rank > 0;

	# North-west-west.
	$mask |= (1 << ($shift +  6)) if $file > 1 && $rank < 7;

	# North-north-west.
	$mask |= (1 << ($shift + 15)) if $file > 0 && $rank < 6;

	$knight_attack_masks[$shift] = $mask;
}

# Pawn masks.
my @white_pawn_single_masks;
for my $shift (0 .. 63) {
	push @white_pawn_single_masks, 1 << ($shift + 8);
}
my @white_pawn_double_masks;
for my $shift (0 .. 63) {
	if ($shift >= 8 && $shift <= 15) {
		push @white_pawn_double_masks, 1 << ($shift + 16);
	} else {
		push @white_pawn_double_masks, 0;
	}
}
my @white_pawn_capture_masks;
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;
	my $mask = 0;
	if ($file > 0) {
		$mask |= 1 << ($shift + 7);
	}
	if ($file < 7) {
		$mask |= 1 << ($shift + 9);
	}
	push @white_pawn_capture_masks, $mask;
}
$pawn_masks[CP_WHITE] = [\@white_pawn_single_masks, \@white_pawn_double_masks,
		\@white_pawn_capture_masks];

my @black_pawn_single_masks;
for my $shift (0 .. 63) {
	push @black_pawn_single_masks, 1 << ($shift - 8);
}
my @black_pawn_double_masks;
for my $shift (0 .. 63) {
	if ($shift >= 48 && $shift <= 55) {
		push @black_pawn_double_masks, 1 << ($shift - 16);
	} else {
		push @black_pawn_double_masks, 0;
	}
}
my @black_pawn_capture_masks;
for my $shift (0 .. 63) {
	my ($file, $rank) = shiftToCoordinates undef, $shift;
	my $mask = 0;
	if ($file > 0) {
		$mask |= 1 << ($shift - 9);
	}
	if ($file < 7) {
		$mask |= 1 << ($shift - 7);
	}
	push @black_pawn_capture_masks, $mask;
}
$pawn_masks[CP_BLACK] = [\@black_pawn_single_masks, \@black_pawn_double_masks,
		\@black_pawn_capture_masks];

# Map en passant squares to masks.
foreach my $shift (16 .. 23) {
	$ep_pawn_masks[$shift] = 1 << ($shift + 8);
}
foreach my $shift (40 .. 47) {
	$ep_pawn_masks[$shift] = 1 << ($shift - 8);
}

# Common lines.
for (my $i = 0; $i < 63; ++$i) {
	$common_lines[$i] = [];
	for (my $j = 0; $j < 63; ++$j) {
		$common_lines[$i]->[$j] = [];
	}
}

# Mask lookup for files and ranks for rooks.
foreach my $m1 (
	CP_1_MASK, CP_2_MASK, CP_3_MASK, CP_4_MASK,
	CP_5_MASK, CP_6_MASK, CP_7_MASK, CP_8_MASK,
	CP_A_MASK, CP_B_MASK, CP_C_MASK, CP_D_MASK,
	CP_E_MASK, CP_F_MASK, CP_G_MASK, CP_H_MASK,
) {
	my $m2 = $m1;
	my @shifts;
	while ($m2) {
		push @shifts, bitboardCountTrailingZbits(undef, $m2);
		$m2 = bitboardClearLeastSet(undef, $m2);
	}

	foreach my $i (@shifts) {
		foreach my $j (@shifts) {
			my $mask = $m1;
			# Clear all bits that are not between i and j.
			for my $k (0 .. 63) {
				my $d1 = $i - $k;
				my $d2 = $j - $k;
				if ($d1 * $d2 > 0) {
					$mask &= ~(1 << $k);
				}

			}
			$common_lines[$i]->[$j] = [1, $m1, $mask];
		}
	}
}

# Mask lookup for diagonals for bishops.  The short diagonals with 1 or 2
# squares only are omitted because they cannot be used for pins.
foreach my $m1 (
	CP_F1H3_MASK, CP_E1H4_MASK, CP_D1H5_MASK, CP_C1H6_MASK, CP_B1H7_MASK,
	CP_A1H8_MASK,
	CP_A2G8_MASK, CP_A3F8_MASK, CP_A4E8_MASK, CP_A5D8_MASK, CP_A6C8_MASK,
	CP_C1A3_MASK, CP_D1A4_MASK, CP_E1A5_MASK, CP_F1A6_MASK, CP_G1A7_MASK,
	CP_H1A8_MASK,
	CP_H2B8_MASK, CP_H3C8_MASK, CP_H4D8_MASK, CP_H5E8_MASK, CP_H6F8_MASK,
) {
	my $m2 = $m1;
	my @shifts;
	while ($m2) {
		push @shifts, bitboardCountTrailingZbits(undef, $m2);
		$m2 = bitboardClearLeastSet(undef, $m2);
	}

	foreach my $i (@shifts) {
		foreach my $j (@shifts) {
			my $mask = $m1;
			# Clear all bits that are not between i and j.
			for my $k (0 .. 63) {
				my $d1 = $i - $k;
				my $d2 = $j - $k;
				if ($d1 * $d2 > 0) {
					$mask &= ~(1 << $k);
				}

			}
			$common_lines[$i]->[$j] = [0, $m1, $mask];
		}
	}
}

# The indices are the target squares of the king.
$castling_rook_move_masks[CP_C1] = CP_1_MASK & (CP_A_MASK | CP_D_MASK);
$castling_rook_move_masks[CP_G1] = CP_1_MASK & (CP_H_MASK | CP_F_MASK);
$castling_rook_move_masks[CP_C8] = CP_8_MASK & (CP_A_MASK | CP_D_MASK);
$castling_rook_move_masks[CP_G8] = CP_8_MASK & (CP_H_MASK | CP_F_MASK);

$castling_rook_to_mask[CP_C1] = 1 << CP_D1;
$castling_rook_to_mask[CP_G1] = 1 << CP_F1;
$castling_rook_to_mask[CP_C8] = 1 << CP_D8;
$castling_rook_to_mask[CP_G8] = 1 << CP_F8;

# The indices are the original squares of the rooks.
@castling_rights_rook_masks = (-1) x 64;
$castling_rights_rook_masks[CP_H1] = ~0x1;
$castling_rights_rook_masks[CP_A1] = ~0x2;
$castling_rights_rook_masks[CP_H8] = ~0x4;
$castling_rights_rook_masks[CP_A8] = ~0x8;

my @piece_values = (0, CP_PAWN_VALUE, CP_KNIGHT_VALUE, CP_BISHOP_VALUE,
	CP_ROOK_VALUE, CP_QUEEN_VALUE);
@material_deltas = (0) x (1 + (1 | (CP_QUEEN << 1) | (CP_QUEEN << 4)));
foreach my $captured (CP_NO_PIECE, CP_PAWN, CP_KNIGHT, CP_BISHOP, CP_ROOK, CP_QUEEN) {
	$material_deltas[CP_WHITE | ($captured << 4)] = ($piece_values[$captured] << 19);
	$material_deltas[CP_BLACK | ($captured << 4)] = (-$piece_values[$captured] << 19);
	foreach my $promote (CP_KNIGHT, CP_BISHOP, CP_ROOK, CP_QUEEN) {
		$material_deltas[CP_WHITE | ($promote << 1) | ($captured << 4)] =
			($piece_values[$captured] + $piece_values[$promote] - CP_PAWN_VALUE) << 19;
		$material_deltas[CP_BLACK | ($promote << 1) | ($captured << 4)] =
			-($piece_values[$captured] + $piece_values[$promote] - CP_PAWN_VALUE) << 19;
	}
}

# Obscured masks.
#
# If a sliding pieces moves from FROM to TO, sliding pieces of the same type
# may now also attack TO.  The obscured_masks give the answer to the question
# which squares had been previously obscured.
foreach my $from (0 .. 63) {
	$obscured_masks[$from] = [(0) x 64];
	my $from_mask = 1 << $from;
	foreach my $to (0 .. 63) {
		my $common = $common_lines[$from]->[$to] or next;

		my ($type, $diagonal, $common) = @$common;

		# If $from is less than $to, all bits of the diagonal that are less
		# than from constitute the obscure squares, otherwise all bits that are
		# greater than from.
		if ($from < $to) {
			$obscured_masks[$from]->[$to] = $diagonal & ($from_mask - 1);
		} else {
			$obscured_masks[$from]->[$to] = $diagonal & ~($from_mask - 1) & ~$from_mask;
		}
	}
}

# Zobrist keys.
my %zk_seen;
for (my $i = 0; $i < 768; ++$i) {
	push @zk_pieces, RNG();
}
for (my $i = 0; $i < 16; ++$i) {
	push @zk_castling, RNG();
}
for (my $i = 0; $i < 8; ++$i) {
	push @zk_ep_files, RNG();
}
$zk_color = RNG();

@zk_move_masks = (0) x 0x40_0000;
# Moves:
# 0-5: to
# 6-11: from
# 12-14: promote
# 15-17: piece
# 18-20: captured
# 21: color
my $gen_moves = sub {
	my ($moves, $piece, $from, $to, $color) = @_;
	my $move = $to | ($from << 6) | ($piece << 15) | ($color << 21);
	push @$moves, $move if $piece != CP_PAWN;
	push @$moves, $move | (CP_PAWN << 18);
	push @$moves, $move | (CP_KNIGHT << 18);
	push @$moves, $move | (CP_BISHOP << 18);
	push @$moves, $move | (CP_ROOK << 18);
	push @$moves, $move | (CP_QUEEN << 18);

	# En passant.
	if ($color == CP_WHITE && $piece == CP_PAWN && $to >= CP_A6 && $to <= CP_H6) {
		push @$moves, $move | (CP_KING << 18);
	} elsif ($color == CP_BLACK && $piece == CP_PAWN && $to >= CP_A3 && $to <= CP_H3) {
		push @$moves, $move | (CP_KING << 18);
	}
};
my $gen_promotions = sub {
	my ($moves, $from, $color) = @_;
	my $move = ($from << 6) | (CP_PAWN << 15) | ($color << 21);
	my $to = $color ? $from - 8 : $from + 8;
	# Normal promotions.
	push @$moves, $move | (CP_QUEEN << 12) | $to;
	push @$moves, $move | (CP_ROOK << 12) | $to;
	push @$moves, $move | (CP_BISHOP << 12) | $to;
	push @$moves, $move | (CP_KNIGHT << 12) | $to;
	# Promotions with captures to the left-side.
	if (($from & 0x7) != CP_FILE_A) {
		$to = $color ? $from - 9 : $from + 7;
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_QUEEN << 18);
	}
	# Promotions with captures to the right-side.
	if (($from & 0x7) != CP_FILE_H) {
		$to = $color ? $from - 7 : $from + 9;
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_QUEEN << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_ROOK << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_BISHOP << 12) | $to | (CP_QUEEN << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_KNIGHT << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_BISHOP << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_ROOK << 18);
		push @$moves, $move | (CP_KNIGHT << 12) | $to | (CP_QUEEN << 18);
	}
};

foreach my $file (CP_FILE_A .. CP_FILE_H) {
	my $mb = 1 << 21;
	foreach my $rank (CP_RANK_1 .. CP_RANK_8) {
		my @moves;
		my $from = coordinatesToShift(undef, $file, $rank);
		my $move_from = $from << 6;

		# Pawn moves.
		if ($rank == CP_RANK_2) {
			# White single step.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from + 8);
			# White double step.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from + 16);
			# White captures.
			$gen_moves->(\@moves, CP_PAWN, $from, $from + 7, CP_WHITE)
				if $file != CP_FILE_A;
			$gen_moves->(\@moves, CP_PAWN, $from, $from + 9, CP_WHITE)
				if $file != CP_FILE_H;
			# Black promotions.
			$gen_promotions->(\@moves, $from, CP_BLACK);
		} elsif ($rank > CP_RANK_2 && $rank < CP_RANK_7) {
			# White single steps.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from + 8);
			# White captures.
			$gen_moves->(\@moves, CP_PAWN, $from, $from + 7, CP_WHITE)
				if $file != CP_FILE_A;
			$gen_moves->(\@moves, CP_PAWN, $from, $from + 9, CP_WHITE)
				if $file != CP_FILE_H;
			# Black single steps.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from - 8) | $mb;
			# Black captures.
			$gen_moves->(\@moves, CP_PAWN, $from, $from - 9, CP_BLACK)
				if $file != CP_FILE_A;
			$gen_moves->(\@moves, CP_PAWN, $from, $from - 7, CP_BLACK)
				if $file != CP_FILE_H;
		} elsif ($rank == CP_RANK_7) {
			# Black single step.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from - 8) | $mb;
			# Black double step.
			push @moves, ((CP_PAWN << 15) | ($move_from) | $from - 16) | $mb;
			# Black captures.
			$gen_moves->(\@moves, CP_PAWN, $from, $from - 9, CP_BLACK)
				if $file != CP_FILE_A;
			$gen_moves->(\@moves, CP_PAWN, $from, $from - 7, CP_BLACK)
				if $file != CP_FILE_H;
			# White promotions.
			$gen_promotions->(\@moves, $from, CP_WHITE);
		}

		# Knight moves.
		my $attack_mask = $knight_attack_masks[$from];
		while ($attack_mask) {
			my $to = bitboardCountTrailingZbits(undef, $attack_mask);
			$gen_moves->(\@moves, CP_KNIGHT, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_KNIGHT, $from, $to, CP_BLACK);
			$attack_mask = bitboardClearLeastSet(undef, $attack_mask);
		}

		# Bishop and bishop-style queen moves.
		my ($to, $to_file, $to_rank);
		# North-east.
		$to = $from;
		for (my ($to_file, $to_rank) = ($file + 1, $rank + 1);
				$to_file <= CP_FILE_H && $to_rank <= CP_RANK_8;
				++$to_file, ++$to_rank) {
			$to += 9;
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_BLACK);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
		}
		# South-east.
		$to = $from;
		for (my ($to_file, $to_rank) = ($file + 1, $rank - 1);
				$to_file <= CP_FILE_H && $to_rank >= CP_RANK_1;
				++$to_file, --$to_rank) {
			$to -= 7;
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_BLACK);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
		}
		# South-west.
		$to = $from;
		for (my ($to_file, $to_rank) = ($file - 1, $rank - 1);
				$to_file >= CP_FILE_A && $to_rank >= CP_RANK_1;
				--$to_file, --$to_rank) {
			$to -= 9;
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_BLACK);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
		}
		# North-west.
		$to = $from;
		for (my ($to_file, $to_rank) = ($file - 1, $rank + 1);
				$to_file >= CP_FILE_A && $to_rank <= CP_RANK_8;
				--$to_file, ++$to_rank) {
			$to += 7;
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_BISHOP, $from, $to, CP_BLACK);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
		}

		# Rook and rook-style queen moves.
		foreach my $dist_to (-7 .. -1, +1 .. +7) {
			my $to = $from + $dist_to;
			next if $to < 0 || $to > 63;
			if (($from & 0x38) == ($to & 0x38)) {
				$gen_moves->(\@moves, CP_ROOK, $from, $to, CP_WHITE);
				$gen_moves->(\@moves, CP_ROOK, $from, $to, CP_BLACK);
				$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
				$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
			}
		}
		foreach my $dist_to (-7 .. -1, +1 .. +7) {
			my $to = $from + 8 * $dist_to;
			next if $to < 0 || $to > 63;
			if (($from & 0x7) == ($to & 0x7)) {
				$gen_moves->(\@moves, CP_ROOK, $from, $to, CP_WHITE);
				$gen_moves->(\@moves, CP_ROOK, $from, $to, CP_BLACK);
				$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_WHITE);
				$gen_moves->(\@moves, CP_QUEEN, $from, $to, CP_BLACK);
			}
		}

		# King moves.
		$attack_mask = $king_attack_masks[$from];
		while ($attack_mask) {
			my $to = bitboardCountTrailingZbits(undef, $attack_mask);
			$gen_moves->(\@moves, CP_KING, $from, $to, CP_WHITE);
			$gen_moves->(\@moves, CP_KING, $from, $to, CP_BLACK);
			$attack_mask = bitboardClearLeastSet(undef, $attack_mask);
		}

		# Castlings.
		if ($from == CP_E1) {
			push @moves, ((CP_KING << 15) | (CP_E1 << 6) | CP_G1);
			push @moves, ((CP_KING << 15) | (CP_E1 << 6) | CP_C1);
		} elsif ($from == CP_E8) {
			push @moves, ((CP_KING << 15) | (CP_E8 << 6) | CP_G8) | $mb;
			push @moves, ((CP_KING << 15) | (CP_E8 << 6) | CP_C8) | $mb;
		}

		push @move_numbers, @moves;

		foreach my $move (@moves) {
			my $is_ep;
			my $color = 1 & ($move >> 21);
			my $captured = 0x7 & ($move >> 18);
			if ($captured == CP_KING) {
				$captured = CP_PAWN;
				$is_ep = 1;
			}
			my ($to, $from, $promote, $piece) = (
				moveTo(undef, $move),
				moveFrom(undef, $move),
				movePromote(undef, $move),
				movePiece(undef, $move),
			);

			my $zk_update = __zobristKeyLookup(undef, $piece, $color, $from)
				^ __zobristKeyLookup(undef, $piece, $color, $to);

			$zk_update ^= $zk_color;

			# Castling?
			if ($piece == CP_KING && (($from - $to) & 0x3) == 0x2) {
				my ($rook_from, $rook_to);
				if ($color) {
					if ($to > $from) {
						($rook_from, $rook_to) = (CP_H8, CP_F8);
					} else {
						($rook_from, $rook_to) = (CP_A8, CP_D8);
					}
				} else {
					if ($to > $from) {
						($rook_from, $rook_to) = (CP_H1, CP_F1);
					} else {
						($rook_from, $rook_to) = (CP_A1, CP_D1);
					}
				}
				$zk_update ^= __zobristKeyLookup(undef, CP_ROOK, $color, $rook_from)
					^ __zobristKeyLookup(undef, CP_ROOK, $color, $rook_to);
			} elsif ($is_ep) {
				my $ep_file = $to & 0x7;
				my $ep_shift = $color ? $to + 8 : $to - 8;
				$zk_update ^= __zobristKeyLookup(undef, CP_PAWN, !$color, $ep_shift);
			} elsif (CP_PAWN == $piece
					&& (($to - $from == 16) || ($to - $from == -16))) {
				# Pawn double step?
				$zk_update ^= $zk_ep_files[$from & 0x7];
			} elsif ($captured) {
				$zk_update ^= __zobristKeyLookup(undef, $captured, !$color, $to);
			}

			if ($promote) {
				$zk_update ^= __zobristKeyLookup(undef, CP_PAWN, $color, $to);
				$zk_update ^= __zobristKeyLookup(undef, $promote, $color, $to);
			}

			$zk_move_masks[$move] = $zk_update;
		}
	}
}

# Magic moves.
sub __initmagicmoves_occ {
	my ($squares, $linocc) = @_;

	my $ret = 0;
	for (my $i = 0; $i < @$squares; ++$i) {
		if ($linocc & (1 << $i)) {
			$ret |= (1 << $squares->[$i]);
		}
	}

	return $ret;
}

sub __initmagicmoves_Rmoves {
	my ($square, $occ) = @_;

	my $ret = 0;
	my $bit;
	my $bit_8_mask = (1 << (64 - 8)) - 1;
	my $bit_1_mask = (1 << (64 - 1)) - 1;
	my $rowbits = (0xFF) << (8 * ($square / 8));

	$bit = 1 << $square;
	do {
		$bit <<= 8;
		$ret |= $bit;
	} while ($bit && !($bit & $occ));

	$bit = 1 << $square;
	do {
		$bit >>= 8;
		$bit &= $bit_8_mask;
		$ret |= $bit;
	} while ($bit && !($bit & $occ));

	$bit = 1 << $square;
	{
		do {
			$bit <<= 1;
			if ($bit & $rowbits) {
				$ret |= $bit;
			} else {
				last;
			}
		} while (!($bit & $occ));
	}

	$bit = (1 << $square);
	{
		do {
			$bit >>= 1;
			$bit &= $bit_1_mask;
			if ($bit & $rowbits) {
				$ret |= $bit; }
			else { 
				last;
			}
		} while (!($bit & $occ));
	}
	
	return $ret;
}

sub __initmagicmoves_Bmoves {
	my ($square, $occ) = @_;
	my $ret = 0;
	my $bit;
	my $bit2;
	my $rowbits = ((0xFF) << (8 * ($square / 8)));
	my $bit_7_mask = (1 << (64 - 7)) - 1;
	my $bit_9_mask = (1 << (64 - 9)) - 1;
	my $bit2_sign_mask = (1 << 63) - 1;

	$bit = (1 << $square);
	$bit2 = $bit;
	{
		do {
			$bit <<= 8 - 1;
			$bit2 >>= 1;
			$bit2 &= $bit2_sign_mask;
			if ($bit2 & $rowbits) {
				$ret |= $bit;
			} else {
				last;
			}
		} while ($bit && !($bit & $occ));
	}

	$bit = (1 << $square);
	$bit2 = $bit;
	{
		do {
			$bit <<= 8 + 1;
			$bit2 <<= 1;
			if ($bit2 & $rowbits) {
				$ret |= $bit;
			} else {
				last;
			}
		} while ($bit && !($bit & $occ));
	}

	$bit = (1 << $square);
	$bit2 = $bit;
	{
		do {
			$bit >>= 8 - 1;
			$bit &= $bit_7_mask;
			$bit2 <<= 1;
			if ($bit2 & $rowbits)
				{
					$ret |= $bit;
				} else {
					last;
				} 
		} while ($bit && !($bit & $occ));
	}

	$bit = (1 << $square);
	$bit2 = $bit;
	{
		do {
			$bit >>= 8 + 1;
			$bit &= $bit_9_mask;
			$bit2 >>= 1;
			$bit2 &= $bit2_sign_mask;
			if ($bit2 & $rowbits) {
				$ret |= $bit;
			} else {
				last;
			}
		} while ($bit && !($bit & $occ));
	}

	return $ret;
}

# Init magicmoves.
my @__initmagicmoves_bitpos64_database = (
	63,  0, 58,  1, 59, 47, 53,  2,
	60, 39, 48, 27, 54, 33, 42,  3,
	61, 51, 37, 40, 49, 18, 28, 20,
	55, 30, 34, 11, 43, 14, 22,  4,
	62, 57, 46, 52, 38, 26, 32, 41,
	50, 36, 17, 19, 29, 10, 13, 21,
	56, 45, 25, 31, 35, 16,  9, 12,
	44, 24, 15,  8, 23,  7,  6,  5
);

use constant MINIMAL_B_BITS_SHIFT => 55;
use constant MINIMAL_R_BITS_SHIFT => 52;

my $b_bits_shift_mask = (1 << (64 - MINIMAL_B_BITS_SHIFT)) - 1;
my $r_bits_shift_mask = (1 << (64 - MINIMAL_R_BITS_SHIFT)) - 1;
my $mask58 = (1 << (64 - 58)) - 1;
for (my $i = 0; $i < 64; ++$i) {
	my @squares;
	my $numsquares = 0;
	my $temp = $magicmoves_b_mask[$i];

	while ($temp) {
		my $bit = $temp & -$temp;
		$squares[$numsquares++] = $__initmagicmoves_bitpos64_database[$mask58 & (($bit * 0x07EDD5E59A4E28C2) >> 58)];
		$temp ^= $bit;
	}
	for ($temp = 0; $temp < (1 << $numsquares); ++$temp) {
		my $tempocc = __initmagicmoves_occ(\@squares, $temp);
		my $j = (($tempocc) * $magicmoves_b_magics[$i]);
		my $k = ($j >> MINIMAL_B_BITS_SHIFT) & $b_bits_shift_mask;
		$magicmovesbdb[$i]->[$k]
				= __initmagicmoves_Bmoves($i, $tempocc);
	}
}

for (my $i = 0; $i < 64; ++$i) {
	my @squares;
	my $numsquares = 0;
	my $temp = $magicmoves_r_mask[$i];
	while ($temp) {
			my $bit = $temp & -$temp;
			$squares[$numsquares++] = $__initmagicmoves_bitpos64_database[$mask58 & (($bit * 0x07EDD5E59A4E28C2) >> 58)];
			$temp ^= $bit;
	}
	for ($temp = 0; $temp < 1 << $numsquares; ++$temp) {
		my $tempocc = __initmagicmoves_occ(\@squares, $temp);

		my $j = (($tempocc) * $magicmoves_r_magics[$i]);
		my $k = ($j >> MINIMAL_R_BITS_SHIFT) & $r_bits_shift_mask;
		$magicmovesrdb[$i][$k] = __initmagicmoves_Rmoves($i, $tempocc);
	}
}

1;
