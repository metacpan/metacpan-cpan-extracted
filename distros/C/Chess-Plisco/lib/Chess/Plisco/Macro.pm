#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Macro;
$Chess::Plisco::Macro::VERSION = '0.3';
use strict;

use Filter::Util::Call;
use PPI::Document;

sub _define;
sub _define_from_file;
sub preprocess;
sub _extract_arguments;
sub _split_arguments;
sub _expand;
sub _expand_placeholders;
sub _expand_placeholder;

my %defines;

# The no-op empty subroutines only exist so that Pod::Coverage works
# correctly.
_define cp_pos_white_pieces => '$p', '$p->[CP_POS_WHITE_PIECES]';
sub cp_pos_white_pieces {}
_define cp_pos_black_pieces => '$p', '$p->[CP_POS_BLACK_PIECES]';
sub cp_pos_black_pieces {}
_define cp_pos_pawns => '$p', '$p->[CP_POS_PAWNS]';
sub cp_pos_pawns {}
_define cp_pos_knights => '$p', '$p->[CP_POS_KNIGHTS]';
sub cp_pos_knights {}
_define cp_pos_bishops => '$p', '$p->[CP_POS_BISHOPS]';
sub cp_pos_bishops {}
_define cp_pos_queens => '$p', '$p->[CP_POS_QUEENS]';
sub cp_pos_queens {}
_define cp_pos_rooks => '$p', '$p->[CP_POS_ROOKS]';
sub cp_pos_rooks {}
_define cp_pos_kings => '$p', '$p->[CP_POS_KINGS]';
sub cp_pos_kings {}
_define cp_pos_half_move_clock => '$p', '$p->[CP_POS_HALF_MOVE_CLOCK]';
sub cp_pos_half_move_clock {}
_define cp_pos_in_check => '$p', '$p->[CP_POS_IN_CHECK]';
sub cp_pos_in_check {}
_define cp_pos_half_moves => '$p', '$p->[CP_POS_HALF_MOVES]';
sub cp_pos_half_moves {}
_define cp_pos_signature => '$p', '$p->[CP_POS_SIGNATURE]';
sub cp_pos_signature {}
_define cp_pos_info => '$p', '$p->[CP_POS_INFO]';
sub cp_pos_info {}
_define cp_pos_reversible_clock => '$p', '$p->[CP_POS_REVERSIBLE_CLOCK]';
sub cp_pos_reversible_clock {}

_define cp_pos_info_castling_rights => '$i', '$i & 0xf';
sub cp_pos_info_castling_rights {}
_define cp_pos_info_white_king_side_castling_right => '$i', '$i & (1 << 0)';
sub cp_pos_info_white_king_side_castling_right {}
_define cp_pos_info_white_queen_side_castling_right => '$i', '$i & (1 << 1)';
sub cp_pos_info_white_queen_side_castling_right {}
_define cp_pos_info_black_king_side_castling_right => '$i', '$i & (1 << 2)';
sub cp_pos_info_black_king_side_castling_right {}
_define cp_pos_info_black_queen_side_castling_right => '$i', '$i & (1 << 3)';
sub cp_pos_info_black_queen_side_castling_right {}
_define cp_pos_info_to_move => '$i', '(($i & (1 << 4)) >> 4)';
sub cp_pos_info_to_move {}
_define cp_pos_info_en_passant_shift => '$i', '(($i & (0x3f << 5)) >> 5)';
sub cp_pos_info_en_passant_shift {}
_define cp_pos_info_king_shift => '$i', '(($i & (0x3f << 11)) >> 11)';
sub cp_pos_info_king_shift {}
_define cp_pos_info_evasion => '$i', '(($i & (0x3 << 17)) >> 17)';
sub cp_pos_info_evasion {}
_define cp_pos_info_material => '$i', '($i >> 19)';
sub cp_pos_info_material {}

_define _cp_pos_info_set_castling => '$i', '$c',
	'($i = ($i & ~0xf) | $c)';
_define _cp_pos_info_set_white_king_side_castling_right => '$i', '$c',
	'($i = ($i & ~(1 << 0)) | ($c << 0))';
_define _cp_pos_info_set_white_queen_side_castling_right => '$i', '$c',
	'($i = ($i & ~(1 << 1)) | ($c << 1))';
_define _cp_pos_info_set_black_king_side_castling_right => '$i', '$c',
	'($i = ($i & ~(1 << 2)) | ($c << 2))';
_define _cp_pos_info_set_black_queen_side_castling_right => '$i', '$c',
	'($i = ($i & ~(1 << 3)) | ($c << 3))';
_define _cp_pos_info_set_to_move => '$i', '$c',
	'($i = ($i & ~(1 << 4)) | ($c << 4))';
_define _cp_pos_info_set_en_passant_shift => '$i', '$s',
	'($i = ($i & ~(0x3f << 5)) | ($s << 5))';
_define _cp_pos_info_set_king_shift => '$i', '$s',
	'($i = ($i & ~(0x3f << 11)) | ($s << 11))';
_define _cp_pos_info_set_evasion => '$i', '$e',
	'($i = ($i & ~(0x3 << 17)) | ($e << 17))';
_define _cp_pos_info_set_material => '$i', '$m',
	'($i = (($i & 0x7fffffff) | ($m << 19)))';

_define_from_file _cp_pos_info_update => '$p', '$i' => 'infoUpdate.pm';

_define cp_pos_castling_rights => '$p',
		'(cp_pos_info_castling_rights(cp_pos_info($p)))';
sub cp_pos_castling_rights {}
_define cp_pos_white_king_side_castling_right => '$p',
		'(cp_pos_info_white_king_side_castling_right(cp_pos_info($p)))';
sub cp_pos_white_king_side_castling_right {}
_define cp_pos_white_queen_side_castling_right => '$p',
		'(cp_pos_info_white_queen_side_castling_right(cp_pos_info($p)))';
sub cp_pos_white_queen_side_castling_right {}
_define cp_pos_black_king_side_castling_right => '$p',
		'(cp_pos_info_black_king_side_castling_right(cp_pos_info($p)))';
sub cp_pos_black_king_side_castling_right {}
_define cp_pos_black_queen_side_castling_right => '$p',
		'(cp_pos_info_black_queen_side_castling_right(cp_pos_info($p)))';
sub cp_pos_black_queen_side_castling_right {}
_define cp_pos_to_move => '$p', '(cp_pos_info_to_move(cp_pos_info($p)))';
sub cp_pos_to_move {}
_define cp_pos_en_passant_shift => '$p', '(cp_pos_info_en_passant_shift(cp_pos_info($p)))';
sub cp_pos_en_passant_shift {}
_define cp_pos_king_shift => '$p', '(cp_pos_info_king_shift(cp_pos_info($p)))';
sub cp_pos_king_shift {}
_define cp_pos_evasion => '$p', '(cp_pos_info_evasion(cp_pos_info($p)))';
sub cp_pos_evasion {}
_define cp_pos_material => '$p', '(cp_pos_info_material(cp_pos_info($p)))';
sub cp_pos_material {}

_define _cp_pos_set_castling => '$p', '$c',
	'(_cp_pos_info_set_castling(cp_pos_info($p), $c))';
_define _cp_pos_set_white_king_side_castling_right => '$p', '$c',
	'(_cp_pos_info_set_white_king_side_castling_right(cp_pos_info($p), $c))';
_define _cp_pos_set_white_queen_side_castling_right => '$p', '$c',
	'(_cp_pos_info_set_white_queen_side_castling_right(cp_pos_info($p), $c))';
_define _cp_pos_set_black_king_side_castling_right => '$p', '$c',
	'(_cp_pos_info_set_black_king_side_castling_right(cp_pos_info($p), $c))';
_define _cp_pos_set_black_queen_side_castling_right => '$p', '$c',
	'(_cp_pos_info_set_black_queen_side_castling_right(cp_pos_info($p), $c))';
_define _cp_pos_set_to_move => '$p', '$c',
	'(_cp_pos_info_set_to_move(cp_pos_info($p), $c))';
_define _cp_pos_set_en_passant_shift => '$p', '$s',
	'(_cp_pos_info_set_en_passant_shift(cp_pos_info($p), $s))';
_define _cp_pos_set_king_shift => '$p', '$s',
	'(_cp_pos_info_set_king_shift(cp_pos_info($p), $s))';
_define _cp_pos_set_evasion => '$p', '$e',
	'(_cp_pos_info_set_evasion(cp_pos_info($p), $e))';
_define _cp_pos_set_material => '$p', '$m',
	'(_cp_pos_info_set_material(cp_pos_info($p), $m))';

_define cp_pos_evasion_squares => '$p', '$p->[CP_POS_EVASION_SQUARES]';
sub cp_pos_evasion_squares {}

_define cp_move_to => '$m', '(($m) & 0x3f)';
sub cp_move_to {}
_define cp_move_set_to => '$m', '$v', '(($m) = (($m) & ~0x3f) | (($v) & 0x3f))';
sub cp_move_set_to {}
_define cp_move_from => '$m', '(($m >> 6) & 0x3f)';
sub cp_move_from {}
_define cp_move_set_from => '$m', '$v',
		'(($m) = (($m) & ~0xfc0) | (($v) & 0x3f) << 6)';
sub cp_move_set_from {}
_define cp_move_promote => '$m', '(($m >> 12) & 0x7)';
sub cp_move_promote {}
_define cp_move_set_promote => '$m', '$p',
		'(($m) = (($m) & ~0x7000) | (($p) & 0x7) << 12)';
sub cp_move_set_promote {}
_define cp_move_piece => '$m', '(($m >> 15) & 0x7)';
sub cp_move_piece {}
_define cp_move_set_piece => '$m', '$a',
		'(($m) = (($m) & ~0x38000) | (($a) & 0x7) << 15)';
sub cp_move_set_piece {}
_define cp_move_captured => '$m', '(($m >> 18) & 0x7)';
sub cp_move_captured {}
_define cp_move_set_captured => '$m', '$a',
		'(($m) = (($m) & ~0x1c0000) | (($a) & 0x7) << 18)';
sub cp_move_set_captured {}
_define cp_move_color => '$m', '(($m >> 21) & 0x1)';
sub cp_move_color {}
_define cp_move_set_color => '$m', '$c',
		'(($m) = (($m) & ~0x20_0000) | (($c) & 0x1) << 21)';
sub cp_move_set_captured {}
_define cp_move_coordinate_notation => '$m', 'cp_shift_to_square(cp_move_from $m) . cp_shift_to_square(cp_move_to $m) . CP_PIECE_CHARS->[CP_BLACK]->[cp_move_promote $m]';
sub cp_move_coordinate_notation {}
_define cp_move_significant => '$m', '($m & 0x7fff)';
sub cp_move_significant {}
_define cp_move_equivalent => '$m1', '$m2',
		'(cp_move_significant($m1) == cp_move_significant($m2))';
sub cp_move_equivalent {}

# Bitboard macros.
_define cp_bitboard_popcount => '$b', '$c',
		'{ my $_b = $b; for ($c = 0; $_b; ++$c) { $_b &= $_b - 1; } }';
sub cp_bitboard_popcount {}
_define cp_bitboard_clear_but_least_set => '$b', '(($b) & -($b))';
sub cp_bitboard_clear_but_least_set {}
_define_from_file cp_bitboard_clear_but_most_set => '$bb', 'clearButMostSet.pm';
sub cp_bitboard_clear_but_most_set {}
_define_from_file cp_bitboard_count_isolated_trailing_zbits => '$bb',
		'countIsolatedTrailingZbits.pm';
sub cp_bitboard_count_isolated_trailing_zbits {}
_define_from_file cp_bitboard_count_trailing_zbits => '$bb', 'countTrailingZbits.pm';
sub cp_bitboard_count_trailing_zbits {}
_define cp_bitboard_clear_least_set => '$bb', '(($bb) & (($bb) - 1))';
sub cp_bitboard_clear_least_set {}
_define cp_bitboard_more_than_one_set => '$bb', '($bb && ($bb & ($bb - 1)))';
sub cp_bitboard_more_than_one_set {}

# Magic moves.
_define cp_mm_bmagic => '$s', '$o',
	'CP_MAGICMOVESBDB->[$s][(((($o) & CP_MAGICMOVES_B_MASK->[$s]) * CP_MAGICMOVES_B_MAGICS->[$s]) >> 55) & ((1 << (64 - 55)) - 1)]';
sub cp_mm_bmagic {}
_define cp_mm_rmagic => '$s', '$o',
	'CP_MAGICMOVESRDB->[$s][(((($o) & CP_MAGICMOVES_R_MASK->[$s]) * CP_MAGICMOVES_R_MAGICS->[$s]) >> 52) & ((1 << (64 - 52)) - 1)]';
sub cp_mm_rmagic {}

# Conversion between different notions of a square.
_define cp_coordinates_to_shift => '$f', '$r', '(($r << 3) + $f)';
sub cp_coordinates_to_shift {}
_define cp_shift_to_coordinates => '$s', '($s & 0x7, $s >> 3)';
sub cp_shift_to_coordinates {}
_define cp_coordinates_to_square => '$f', '$r', 'chr(97 + $f) . (1 + $r)';
sub cp_coordinates_to_square {}
_define cp_square_to_coordinates => '$s', '(ord($s) - 97, -1 + substr $s, 1)';
sub cp_square_to_coordinates {}
_define cp_square_to_shift => '$s',
		'(((substr $s, 1) - 1) << 3) + ord($s) - 97';
sub cp_square_to_shift {}
_define cp_shift_to_square => '$s', 'chr(97 + ($s & 0x7)) . (1 + ($s >> 3))';
sub cp_shift_to_square {}

_define_from_file _cp_moves_from_mask => '$t', '@m', '$b',
	'movesFromMask.pm';
_define_from_file _cp_promotion_moves_from_mask => '$t', '@m', '$b',
	'promotionMovesFromMask.pm';
_define_from_file _cp_pos_move_pinned =>
	'$p', '$from', '$to', '$ks', '$mp', '$hp', 'movePinned.pm';
_define_from_file _cp_pos_color_attacked => '$p', '$c', '$shift', 'attacked.pm';
_define_from_file _cp_pos_move_attacked => '$p', '$from', '$to', 'moveAttacked.pm';
_define _cp_pawn_double_step => '$f', '$t', '(!(($t - $f) & 0x9))';

# Bit twiddling.
_define_from_file cp_abs => '$v', 'abs.pm';
sub cp_abs {}

# At least as fast as the versions w/o branching for example
# a - ((a -b) & ((a - b) >> 63)), and there are no overflow issues.
_define cp_max => '$A', '$B', '((($A) > ($B)) ? ($A) : ($B))';
sub cp_max {}
_define cp_min => '$A', '$B', '((($A) < ($B)) ? ($A) : ($B))';
sub cp_min {}

# Zobrist keys.
_define _cp_zk_lookup => '$p', '$c', '$s', '$zk_pieces[((($p) << 7) | (($c) << 6) | ($s)) - 128]';

sub import {
	my ($type) = @_;

	my $self = {
		__source => '',
		__eof => 0,
	};

	filter_add(bless $self); ## no critic
}

sub filter {
	my ($self) = @_;

	return 0 if $self->{__eof};

	my $status = filter_read();

	if ($status > 0) {
		$self->{__source} .= $_;
		$_ = '';
	} elsif ($status == 0) {
		$_ = preprocess $self->{__source};
		$self->{__eof} = 1;
		return 1;
	}

	return $status;
}

sub _expand {
	my ($parent, $invocation) = @_;

	# First find the invocation.
	my @siblings = $parent->children;
	my $count = -1;
	my $idx;
	foreach my $sibling (@siblings) {
		++$count;
		if ($sibling == $invocation) {
			$idx = $count;
			last;
		}
	}

	return if !defined $idx;

	# First remove all elements following the invocation, and later re-add
	# them.
	my $name = $invocation->content;

	my $definition = $defines{$name};
	my $code = $definition->{code}->content;
	$code =~ s/\n//g;
	my $cdoc = PPI::Document->new(\$code);
	my $cut = 0;
	if (@{$definition->{args}} == 0) {
		# Just a constant, no arguments.
		# Check whether there is a list following, and discard it.
		my $to;
		foreach ($to = $idx + 1; $to < @siblings; ++$to) {
			last if $siblings[$to]->significant;
		}
		if ($to < @siblings && $siblings[$to]->isa('PPI::Structure::List')) {
			$cut = $to - $idx;
		}
	} else {
		my @arguments = _extract_arguments $invocation;
		my @placeholders = @{$definition->{args}};
		my %placeholders;
		for (my $i = 0; $i < @placeholders; ++$i) {
			my $placeholder = $placeholders[$i];
			if ($i > $#arguments) {
				$placeholders{$placeholder} = [];
			} else {
				$placeholders{$placeholder} = $arguments[$i];
			}
		}
		_expand_placeholders $cdoc, %placeholders;

		my ($to, $first_significant);
		foreach ($to = $idx + 1; $to < @siblings; ++$to) {
			if (!defined $first_significant && $siblings[$to]->significant) {
				$first_significant = $siblings[$to];
				if ($first_significant->isa('PPI::Structure::List')) {
					--$to;
					last;
				}
			}
		}
		$to = $idx if $to >= @siblings;
		$cut = $to - $idx + 1;
	}

	$parent->remove_child($invocation);

	my @tail;
	for (my $i = $idx + 1; $i < @siblings; ++$i) {
		push @tail, $parent->remove_child($siblings[$i]);
	}

	splice @tail, 0, $cut;

	my @children = $cdoc->children;
	foreach my $child (@children) {
		$cdoc->remove_child($child);
	}


	foreach my $sibling (@children, @tail) {
		$parent->add_element($sibling);
	}

	return $invocation;
}

sub _expand_placeholders {
	my ($doc, %placeholders) = @_;

	my $words = $doc->find(sub { 
		($_[1]->isa('PPI::Token::Symbol') || $_[1]->isa('PPI::Token::Word'))
		&& exists $placeholders{$_[1]->content} 
	});

	foreach my $word (@$words) {
		_expand_placeholder $word, @{$placeholders{$word->content}};
	}
}

sub _expand_placeholder {
	my ($word, @arglist) = @_;

	# Find the word in the parent.
	my $parent = $word->parent;
	my $idx;

	my @siblings = $parent->children;
	my $word_idx;
	my @tail;
	for (my $i = 0; $i < @siblings; ++$i) {
		if (defined $word_idx) {
			my $sibling = $siblings[$i];
			$parent->remove_child($sibling);
			push @tail, $sibling;
		} elsif ($siblings[$i] == $word) {
			$word_idx = $i;
			$parent->remove_child($word);
		}
	}

	foreach my $token (@arglist) {
		# We have to clone the token, in case it had been used before.
		$token = $token->clone;
	}

	foreach my $token (@arglist, @tail) {
		$parent->add_element($token);
	}
}

sub preprocess {
	my ($content) = @_;

	my ($head, $code, $tail);

	if ($content =~ /(.*\n)# *__BEGIN_MACROS__.*?\n(.*\n)# *__END_MACROS__.*?\n(.*)/s) {
		($head, $code, $tail) = ($1, $2, $3);
		$head .= "\n";
		$tail = "\n$tail";
	} else {
		$head = '';
		$code = $content;
		$tail = '';
	}

	my $source = PPI::Document->new(\$code);

	# We always replace the last macro invocation only, and then re-scan the
	# document. This should ensure that nested macro invocations will work.
	while (1) {
		my $invocations = $source->find(sub {
			$_[1]->isa('PPI::Token::Word') && exists $defines{$_[1]->content}
		});

		last if !$invocations;

		my $invocation = $invocations->[-1];
		my $parent = $invocation->parent;

		_expand $parent, $invocation;
	}

	return $head . $source->content . $tail;
}

sub _define {
	my ($name, @args) = @_;

	my $code = pop @args;
	$code = '' if !defined $code;

	if (exists $defines{$name}) {
		require Carp;
		Carp::croak("duplicate macro definition '$name'");
	}

	my $code_doc = PPI::Document->new(\$code);
	if (!$code_doc) {
		require Carp;
		my $msg = $@->message;
		Carp::croak("cannot parse code for '$name': $msg\n");
	}

	$code_doc->prune('PPI::Token::Comment');

	$defines{$name} = {
		args => [@args],
		code => $code_doc,
	};

	return;
}

sub _define_from_file {
	my ($name, @args) = @_;

	my $relname = pop @args;
	my $filename = __FILE__;
	$filename =~ s{\.pm$}{/$relname};

	open my $fh, '<', $filename
		or die "cannot open '$filename' for reading: $!";
	
	my $code = join '', <$fh>;

	return _define $name, @args, $code;
}

sub _extract_arguments {
	my ($word) = @_;

	my $parent = $word->parent;
	my @siblings = $parent->children;
	my $pos;
	for (my $i = 0; $i < @siblings; ++$i) {
		if ($siblings[$i] == $word) {
			$pos = $i;
			last;
		}
	}

	return if !defined $pos;

	# No arguments?
	return if $pos == $#siblings;

	# Skip insignicant tokens.
	my $argidx;
	for (my $i = $pos + 1; $i < @siblings; ++$i) {
		if ($siblings[$i]->significant) {
			$argidx = $i;
			last;
		}
	}

	return if !defined $argidx;

	my @argnodes;
	my $argnodes_parent = $parent;

	if ($siblings[$argidx]->isa('PPI::Token::Structure')) {
		# No arguments.
		return;
	} elsif ($siblings[$argidx]->isa('PPI::Structure::List')) {
		# Call with parentheses.  The only child should be an expression.
		my @expression = $siblings[$argidx]->children;
		return if @expression != 1;
		$argnodes_parent = $expression[0];
		return if !$argnodes_parent->isa('PPI::Statement::Expression');
		@argnodes = $argnodes_parent->children;
	} else {
		for (my $i = $argidx; $i < @siblings; ++$i) {
			# Call without parentheses.
			if ($siblings[$i]->isa('PPI::Token::Structure')
			    && ';' eq $siblings[$i]->content) {
					last;
			}

			push @argnodes, $siblings[$i];
		}
	}

	return _split_arguments $argnodes_parent, @argnodes;
}

sub _split_arguments {
	my ($parent, @argnodes) = @_;

	my @arguments;
	my @argument;

	for (my $i = 0; $i < @argnodes; ++$i) {
		my $argnode = $argnodes[$i];

		$parent->remove_child($argnode);

		if ($argnode->isa('PPI::Token::Operator')
		    && ',' eq $argnode->content) {
			push @arguments, [@argument];
			undef @argument;
		} else {
			push @argument, $argnode;
		}
	}
	push @arguments, [@argument] if @argument;

	foreach my $argument (@arguments) {
		while (!$argument->[0]->significant) {
			shift @$argument;
		}
		while (!$argument->[-1]->significant) {
			pop @$argument;
		}
	}

	return @arguments;
}

1;
