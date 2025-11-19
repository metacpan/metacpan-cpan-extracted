use strict;
use v5.10;
use List::Util qw(shuffle);

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

sub generate_board;
sub empty_pos;
sub print_positions;

my @files = @ARGV;

my @endgames;

foreach my $file (@files) {
	$file =~ s{.*/}{};
	$file =~ s{\..*}{};
	push @endgames, $file;
}

foreach my $i (1 .. 6000) {
	my $idx = int(rand(scalar @endgames));
	my $endgame = $endgames[$idx];
	my $pos;

	my %indexes = (
		K => CP_POS_KINGS,
		Q => CP_POS_QUEENS,
		R => CP_POS_ROOKS,
		B => CP_POS_BISHOPS,
		N => CP_POS_KNIGHTS,
		P => CP_POS_PAWNS,
	);
	while (!$pos) {
		my $new = empty_pos;
		my @board = generate_board $endgame;

		foreach my $shift (0 .. 63) {
			my $piece = $board[$shift] or next;
			my $index = $indexes{uc $piece};
			my $bb = 1 << $shift;
			$new->[$index] |= $bb;
			if ($piece ge 'a') {
				$new->[CP_POS_BLACK_PIECES] |= $bb;
			} else {
				$new->[CP_POS_WHITE_PIECES] |= $bb;
			}
		}

		eval {
			my $fen = $new->toFEN;
			$pos = Chess::Plisco->new($fen);
		};
		if ($pos) {
			my $legal = $pos->__legalityCheck;
			undef $pos if !$legal;
		}
	}

	print_positions $pos;
}

sub generate_board {
	my ($endgame) = @_;

	my ($white_part, $black_part) = split /v/, $endgame;
	$black_part = lc $black_part;

	my @board = ('') x 64;

	my @white_pieces = split //, $white_part;
	my @black_pieces = split //, $black_part;

	my @squares = shuffle(0 .. 63);

	foreach my $piece (@white_pieces, @black_pieces) {
		my $sq = shift @squares;
		$board[$sq] = $piece;
	}

	return @board;
}

sub empty_pos {
	my $pos = Chess::Plisco->new('7k/8/8/8/8/8/8/K7 w - - 0 1');

	$pos->[CP_POS_WHITE_PIECES] = $pos->[CP_POS_BLACK_PIECES] = $pos->[CP_POS_KINGS] = 0;

	return $pos;
}

sub print_positions {
	my ($pos) = @_;

	say $pos;

	my @groups = split / /, $pos->toFEN;
	my $occupancy = $pos->[CP_POS_WHITE_PIECES] | $pos->[CP_POS_BLACK_PIECES];
	my $pawns_bb = $pos->[CP_POS_PAWNS];
	my $black_pawns_bb = $pawns_bb & $pos->[CP_POS_BLACK_PIECES] & CP_5_MASK;
	while ($black_pawns_bb) {
		my $shift = $pos->bitboardCountTrailingZbits($black_pawns_bb);

		$black_pawns_bb = $pos->bitboardClearLeastSet($black_pawns_bb);
		my $ep_shift = $shift + 8;
		my $ep_mask = 1 << $ep_shift;
		next if $ep_mask & $occupancy;

		my $ep_square = $pos->shiftToSquare($ep_shift);
		$groups[3] = $ep_square;

		my $fen = join ' ', @groups;
		my $ep_pos = Chess::Plisco->new($fen);
		if ($ep_pos->__legalityCheck) {
			say $fen;
		}
	}

	my $black_fen = "$pos";
	$black_fen =~ s/w - -/b - -/;
	$pos = eval { Chess::Plisco->new($black_fen) };
	return if $@;
	return if !$pos->__legalityCheck;

	say $black_fen;

	@groups = split / /, $black_fen;

	my $white_pawns_bb = $pawns_bb & $pos->[CP_POS_WHITE_PIECES] & CP_4_MASK;
	while ($white_pawns_bb) {
		my $shift = $pos->bitboardCountTrailingZbits($white_pawns_bb);

		$white_pawns_bb = $pos->bitboardClearLeastSet($black_pawns_bb);
		my $ep_shift = $shift - 8;
		my $ep_mask = 1 << $ep_shift;
		next if $ep_mask & $occupancy;

		my $ep_square = $pos->shiftToSquare($ep_shift);
		$groups[3] = $ep_square;

		my $fen = join ' ', @groups;
		my $ep_pos = Chess::Plisco->new($fen);
		if ($ep_pos->__legalityCheck) {
			say $fen;
		}
	}
}