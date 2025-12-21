#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# This file is heavily inspired by python-chess.

use strict;
use integer;

use List::Util qw(reduce);
use Locale::TextDomain qw('Chess-Plisco');
use Scalar::Util qw(reftype);

use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!

my $TBPIECES = 7;

use constant INVTRIANGLE => [1, 2, 3, 10, 11, 19, 0, 9, 18, 27];

# FIXME! These are candidates for macros!
my $offdiag = sub {
	my ($shift) = @_;

	my ($file, $rank) = ($shift & 0x7, $shift >> 3);

	return $rank - $file;
};

my $flipdiag = sub {
	my ($shift) = @_;

	return (($shift >> 3) | ($shift << 3)) & 63;
};

my $read_byte = sub {
	my ($data, $offset) = @_;

	return ord substr $data, $offset, 1;
};

my $remove_ep = sub {
	my ($pos) = @_;

	my $pos2 = $pos->copy;

	$pos2->[CP_POS_EN_PASSANT_SHIFT] = 0;

	return $pos2;
};

my $is_checkmate = sub {
	my ($pos) = @_;

	my $game_over = $pos->gameOver or return;
	return 1 if ($game_over && CP_GAME_WHITE_WINS);
	return 1 if ($game_over && CP_GAME_BLACK_WINS);
};

my @PTWIST = (
	 0,  0,  0,  0,  0,  0,  0,  0,
	47, 35, 23, 11, 10, 22, 34, 46,
	45, 33, 21,  9,  8, 20, 32, 44,
	43, 31, 19,  7,  6, 18, 30, 42,
	41, 29, 17,  5,  4, 16, 28, 40,
	39, 27, 15,  3,  2, 14, 26, 38,
	37, 25, 13,  1,  0, 12, 24, 36,
	 0,  0,  0,  0,  0,  0,  0,  0,
);

use constant INVFLAP => [
	 8, 16, 24, 32, 40, 48,
	 9, 17, 25, 33, 41, 49,
	10, 18, 26, 34, 42, 50,
	11, 19, 27, 35, 43, 51,
];

use constant TEST45_MASK => (1 << (CP_A5)) | (1 << (CP_A6)) | (1 << (CP_A7)) | (1 << (CP_B5)) | (1 << (CP_B6)) | (1 << (CP_C5));

my $test45 = sub {
	my ($shift) = @_;

	return !!((1 << $shift) & TEST45_MASK);
};

use constant MTWIST => [
	15, 63, 55, 47, 40, 48, 56, 12,
	62, 11, 39, 31, 24, 32,  8, 57,
	54, 38,  7, 23, 16,  4, 33, 49,
	46, 30, 22,  3,  0, 17, 25, 41,
	45, 29, 21,  2,  1, 18, 26, 42,
	53, 37,  6, 20, 19,  5, 34, 50,
	61, 10, 36, 28, 27, 35,  9, 58,
	14, 60, 52, 44, 43, 51, 59, 13,
];

my @PAWNIDX = ([], [], [], [], []);
my @PFACTOR = ([], [], [], [], []);

my $binom = sub {
	my ($x, $y) = @_;

	my $numerator = reduce { $a * $b } $x - $y + 1 .. $x;
	my $denominator = reduce { $a * $b } 1 .. $y;

	return $numerator / $denominator;
};

for my $i (0 .. 4) {
	my $j = 0;

	my $s = 0;
	while ($j < 6) {
		$PAWNIDX[$i]->[$j] = $s;
		$s += $i == 0 ? 1 : $binom->($PTWIST[INVFLAP->[$j]], $i);
		++$j;
	}
	$PFACTOR[$i]->[0] = $s;

	$s = 0;
	while ($j < 12) {
		$PAWNIDX[$i]->[$j] = $s;
		$s += $i == 0 ? 1 : $binom->($PTWIST[INVFLAP->[$j]], $i);
		++$j;
	}
	$PFACTOR[$i]->[1] = $s;

	$s = 0;
	while ($j < 18) {
		$PAWNIDX[$i]->[$j] = $s;
		$s += $i == 0 ? 1 : $binom->($PTWIST[INVFLAP->[$j]], $i);
		++$j;
	}
	$PFACTOR[$i]->[2] = $s;

	$s = 0;
	while ($j < 24) {
		$PAWNIDX[$i]->[$j] = $s;
		$s += $i == 0 ? 1 : $binom->($PTWIST[INVFLAP->[$j]], $i);
		++$j;
	}
	$PFACTOR[$i][3] = $s;
}

my @MULTIDX = ([], [], [], [], []);
my @MFACTOR;

for my $i (0 .. 4) {
	my $s = 0;
	for my $j (0 .. 9) {
		$MULTIDX[$i]->[$j] = $s;
		$s += $i == 0 ? 1 : $binom->(MTWIST->[INVTRIANGLE->[$j]], $i);
		++$j;
	}
	$MFACTOR[$i] = $s;
}

my @PCHR = ('K', 'Q', 'R', 'B', 'N', 'P');
my %PCHR_IDX = map { $PCHR[$_] => $_ } 0 .. $#PCHR;

use constant TABLENAME_REGEX => qr/^[KQRBNP]+v[KQRBNP]+\Z/;

my $normalise_tablename = sub {
	my ($name, $mirror) = @_;

	my ($white, $black) = split /v/, $name, 2;

	# Sort pieces according to PCHR order.
	$white = join '', sort { $PCHR_IDX{$a} <=> $PCHR_IDX{$b} } split //, $white;
	$black = join '', sort { $PCHR_IDX{$a} <=> $PCHR_IDX{$b} } split //, $black;

	return $mirror ? $black . "v" . $white : $white . "v" . $black;
};

my $is_tablename = sub {
	my ($name, %__options) = @_;

	my %options = (
		normalised => 1,
		piece_count => $TBPIECES,
		%__options,
	);

	return if defined $options{piece_count} && length $name > $options{piece_count} + 1;
	return if $name !~ TABLENAME_REGEX;
	return if $name =~ /K.*K.*K/; # More than three kings.
	return if $options{normalised} && $normalise_tablename->($name) ne $name;

	return 1;
};

my $calc_key = sub {
	my ($pos, $mirror) = @_;

	$mirror //= 0;

	my ($wh, $bl) = ($pos->[CP_POS_WHITE_PIECES], $pos->[CP_POS_BLACK_PIECES]);

	my @pieces = qw(P N B R Q);

	my ($wkey, $bkey) = ('K', 'K');
	foreach my $i (reverse CP_POS_PAWNS .. CP_POS_QUEENS) {
		my $popcount;

		{ my $_b = $pos->[$i] & $wh; for ($popcount = 0; $_b; ++$popcount) { $_b &= $_b - 1; } };
		$wkey .= $pieces[$i - CP_POS_PAWNS] x $popcount;

		{ my $_b = $pos->[$i] & $bl; for ($popcount = 0; $_b; ++$popcount) { $_b &= $_b - 1; } };
		$bkey .= $pieces[$i - CP_POS_PAWNS] x $popcount;
	}

	return $mirror ? (join 'v', $bkey, $wkey) : (join 'v', $wkey, $bkey);
};

# Some endgames are stored with a different key than their filename
# indicates: http://talkchess.com/forum/viewtopic.php?p=695509#695509
my $recalc_key = sub {
	my ($pieces, $mirror) = @_;

	$mirror //= 0;

	my ($w, $b) = $mirror ? (8, 0) : (0, 8);
	my @l = qw(K Q R B N P);

	my $white = join '', map
		{
			my $c = (6 - $_) ^ $w;
			my $n = grep { $c == $_ } @$pieces;
			$l[$_] x $n;
		} 0 .. 5;
	my $black = join '', map
		{
			my $c = (6 - $_) ^ $b;
			my $n = grep { $c == $_ } @$pieces;
			$l[$_] x $n;
		} 0 .. 5;

	return join 'v', $white, $black;
};

my $subfactor = sub {
	my ($k, $n) = @_;

	my $f = $n;
	my $l = 1;

	for my $i (1 .. $k - 1) {
		$f *= $n - $i;
		$l *= $i + 1;
	}

	return int($f / $l);
};

my $dtz_before_zeroing = sub {
	my ($wdl) = @_;

	my $sign = ($wdl > 0 ? 1 : 0) - ($wdl < 0 ? 1 : 0);
	my $factor = (abs($wdl) == 2 ? 1 : 101);

	return $sign * $factor;
};

package Chess::Plisco::Tablebase::Syzygy::Testing;
$Chess::Plisco::Tablebase::Syzygy::Testing::VERSION = 'v1.0.1';
sub calc_key {
	my (undef, $pos, $mirror) = @_;

	return $calc_key->($pos, $mirror);
}

sub normalise_tablename {
	my (undef, $name, $mirror) = @_;

	return $normalise_tablename->($name, $mirror);
}

sub offdiag {
	my (undef, $shift) = @_;

	return $offdiag->($shift);
}

sub flipdiag {
	my (undef, $shift) = @_;

	return $flipdiag->($shift);
}

package Chess::Plisco::Tablebase::Syzygy::MissingTableException;
$Chess::Plisco::Tablebase::Syzygy::MissingTableException::VERSION = 'v1.0.1';
use overload '""' => sub { ${$_[0]} };

sub new {
	my ($class, $msg) = @_;

	bless \$msg, $class;
}

package Chess::Plisco::Tablebase::Syzygy::PairsData;
$Chess::Plisco::Tablebase::Syzygy::PairsData::VERSION = 'v1.0.1';
sub new {
	my ($class, %args) = @_;

	bless {
		indextable => $args{indextable} // 0,
		sizetable => $args{sizetable} // 0,
		data => $args{data} // 0,
		offset => $args{offset} // 0,
		symlen => $args{symlen} // [],
		sympat => $args{sympat} // 0,
		blocksize => $args{blocksize} // 0,
		idxbits => $args{idxbits} // 0,
		min_len => $args{min_len} // 0,
		base => $args{base} // [],
	}, $class;
}

package Chess::Plisco::Tablebase::Syzygy::PawnFileData;
$Chess::Plisco::Tablebase::Syzygy::PawnFileData::VERSION = 'v1.0.1';
sub new {
	my ($class) = @_;
	bless {
		precomp => [],
		factor => [],
		pieces => [],
		norm => [],
	}, $class;
}

package Chess::Plisco::Tablebase::Syzygy::PawnFileDataDtz;
$Chess::Plisco::Tablebase::Syzygy::PawnFileDataDtz::VERSION = 'v1.0.1';
sub new {
	my ($class, %args) = @_;

	bless {
		precomp => $args{precomp} // Chess::Plisco::Tablebase::Syzygy::PairsData->new(),
		factor => $args{factor} // [],
		pieces => $args{pieces} // [],
		norm => $args{norm} // [],
	}, $class;
}

package Chess::Plisco::Tablebase::Syzygy::Table;
$Chess::Plisco::Tablebase::Syzygy::Table::VERSION = 'v1.0.1';
use integer;

use Fcntl qw(O_RDONLY O_BINARY);
use Sys::Mmap qw(mmap PROT_READ MAP_SHARED);
use Math::Int64 qw(uint64);

use Locale::TextDomain qw(Chess-Plisco);

use constant FLAP => [
	0,  0,  0,  0,  0,  0,  0, 0,
	0,  6, 12, 18, 18, 12,  6, 0,
	1,  7, 13, 19, 19, 13,  7, 1,
	2,  8, 14, 20, 20, 14,  8, 2,
	3,  9, 15, 21, 21, 15,  9, 3,
	4, 10, 16, 22, 22, 16, 10, 4,
	5, 11, 17, 23, 23, 17, 11, 5,
	0,  0,  0,  0,  0,  0,  0, 0,
];

use constant FILE_TO_FILE => [0, 1, 2, 3, 3, 2, 1, 0];

use constant TRIANGLE => [
	6, 0, 1, 2, 2, 1, 0, 6,
	0, 7, 3, 4, 4, 3, 7, 0,
	1, 3, 8, 5, 5, 8, 3, 1,
	2, 4, 5, 9, 9, 5, 4, 2,
	2, 4, 5, 9, 9, 5, 4, 2,
	1, 3, 8, 5, 5, 8, 3, 1,
	0, 7, 3, 4, 4, 3, 7, 0,
	6, 0, 1, 2, 2, 1, 0, 6,
];

use constant LOWER => [
	28,  0,  1,  2,  3,  4,  5,  6,
	 0, 29,  7,  8,  9, 10, 11, 12,
	 1,  7, 30, 13, 14, 15, 16, 17,
	 2,  8, 13, 31, 18, 19, 20, 21,
	 3,  9, 14, 18, 32, 22, 23, 24,
	 4, 10, 15, 19, 22, 33, 25, 26,
	 5, 11, 16, 20, 23, 25, 34, 27,
	 6, 12, 17, 21, 24, 26, 27, 35,
];

use constant DIAG => [
	 0,  0,  0,  0,  0,  0,  0,  8,
	 0,  1,  0,  0,  0,  0,  9,  0,
	 0,  0,  2,  0,  0, 10,  0,  0,
	 0,  0,  0,  3, 11,  0,  0,  0,
	 0,  0,  0, 12,  4,  0,  0,  0,
	 0,  0, 13,  0,  0,  5,  0,  0,
	 0, 14,  0,  0,  0,  0,  6,  0,
	15,  0,  0,  0,  0,  0,  0,  7,
];

use constant KK_IDX => [[
	-1,  -1,  -1,   0,   1,   2,   3,   4,
	-1,  -1,  -1,   5,   6,   7,   8,   9,
	10,  11,  12,  13,  14,  15,  16,  17,
	18,  19,  20,  21,  22,  23,  24,  25,
	26,  27,  28,  29,  30,  31,  32,  33,
	34,  35,  36,  37,  38,  39,  40,  41,
	42,  43,  44,  45,  46,  47,  48,  49,
	50,  51,  52,  53,  54,  55,  56,  57,
], [
	 58,  -1,  -1,  -1,  59,  60,  61,  62,
	 63,  -1,  -1,  -1,  64,  65,  66,  67,
	 68,  69,  70,  71,  72,  73,  74,  75,
	 76,  77,  78,  79,  80,  81,  82,  83,
	 84,  85,  86,  87,  88,  89,  90,  91,
	 92,  93,  94,  95,  96,  97,  98,  99,
	100, 101, 102, 103, 104, 105, 106, 107,
	108, 109, 110, 111, 112, 113, 114, 115,
], [
	116, 117,  -1,  -1,  -1, 118, 119, 120,
	121, 122,  -1,  -1,  -1, 123, 124, 125,
	126, 127, 128, 129, 130, 131, 132, 133,
	134, 135, 136, 137, 138, 139, 140, 141,
	142, 143, 144, 145, 146, 147, 148, 149,
	150, 151, 152, 153, 154, 155, 156, 157,
	158, 159, 160, 161, 162, 163, 164, 165,
	166, 167, 168, 169, 170, 171, 172, 173,
], [
	174,  -1,  -1,  -1, 175, 176, 177, 178,
	179,  -1,  -1,  -1, 180, 181, 182, 183,
	184,  -1,  -1,  -1, 185, 186, 187, 188,
	189, 190, 191, 192, 193, 194, 195, 196,
	197, 198, 199, 200, 201, 202, 203, 204,
	205, 206, 207, 208, 209, 210, 211, 212,
	213, 214, 215, 216, 217, 218, 219, 220,
	221, 222, 223, 224, 225, 226, 227, 228,
], [
	229, 230,  -1,  -1,  -1, 231, 232, 233,
	234, 235,  -1,  -1,  -1, 236, 237, 238,
	239, 240,  -1,  -1,  -1, 241, 242, 243,
	244, 245, 246, 247, 248, 249, 250, 251,
	252, 253, 254, 255, 256, 257, 258, 259,
	260, 261, 262, 263, 264, 265, 266, 267,
	268, 269, 270, 271, 272, 273, 274, 275,
	276, 277, 278, 279, 280, 281, 282, 283,
], [
	284, 285, 286, 287, 288, 289, 290, 291,
	292, 293,  -1,  -1,  -1, 294, 295, 296,
	297, 298,  -1,  -1,  -1, 299, 300, 301,
	302, 303,  -1,  -1,  -1, 304, 305, 306,
	307, 308, 309, 310, 311, 312, 313, 314,
	315, 316, 317, 318, 319, 320, 321, 322,
	323, 324, 325, 326, 327, 328, 329, 330,
	331, 332, 333, 334, 335, 336, 337, 338,
], [
	-1,  -1, 339, 340, 341, 342, 343, 344,
	-1,  -1, 345, 346, 347, 348, 349, 350,
	-1,  -1, 441, 351, 352, 353, 354, 355,
	-1,  -1,  -1, 442, 356, 357, 358, 359,
	-1,  -1,  -1,  -1, 443, 360, 361, 362,
	-1,  -1,  -1,  -1,  -1, 444, 363, 364,
	-1,  -1,  -1,  -1,  -1,  -1, 445, 365,
	-1,  -1,  -1,  -1,  -1,  -1,  -1, 446,
], [
	-1,  -1,  -1, 366, 367, 368, 369, 370,
	-1,  -1,  -1, 371, 372, 373, 374, 375,
	-1,  -1,  -1, 376, 377, 378, 379, 380,
	-1,  -1,  -1, 447, 381, 382, 383, 384,
	-1,  -1,  -1,  -1, 448, 385, 386, 387,
	-1,  -1,  -1,  -1,  -1, 449, 388, 389,
	-1,  -1,  -1,  -1,  -1,  -1, 450, 390,
	-1,  -1,  -1,  -1,  -1,  -1,  -1, 451,
], [
	452, 391, 392, 393, 394, 395, 396, 397,
	 -1,  -1,  -1,  -1, 398, 399, 400, 401,
	 -1,  -1,  -1,  -1, 402, 403, 404, 405,
	 -1,  -1,  -1,  -1, 406, 407, 408, 409,
	 -1,  -1,  -1,  -1, 453, 410, 411, 412,
	 -1,  -1,  -1,  -1,  -1, 454, 413, 414,
	 -1,  -1,  -1,  -1,  -1,  -1, 455, 415,
	 -1,  -1,  -1,  -1,  -1,  -1,  -1, 456,
], [
	457, 416, 417, 418, 419, 420, 421, 422,
	 -1, 458, 423, 424, 425, 426, 427, 428,
	 -1,  -1,  -1,  -1,  -1, 429, 430, 431,
	 -1,  -1,  -1,  -1,  -1, 432, 433, 434,
	 -1,  -1,  -1,  -1,  -1, 435, 436, 437,
	 -1,  -1,  -1,  -1,  -1, 459, 438, 439,
	 -1,  -1,  -1,  -1,  -1,  -1, 460, 440,
	 -1,  -1,  -1,  -1,  -1,  -1,  -1, 461,
]];

use constant UINT64_BE => 'Q>'; # Unsigned 64-bit big-endian
use constant UINT32 => 'V'; # Unsigned 32-bit little-endian
use constant UINT32_BE => 'N'; # Unsigned 32-bit big-endian
use constant UINT16 => 'v'; # Unsigned 16-bit little-endian

sub new {
	my ($class, $path) = @_;

	my $self = {};

	$self->{path} = $path;

	# normalise tablename
	my ($basename) = $path =~ m{([^/]+)$};
	$basename =~ s/\.[^.]+$//;

	$self->{key} = $normalise_tablename->($basename);
	$self->{mirrored_key} = $normalise_tablename->($basename, 1);
	$self->{symmetric} = $self->{key} eq $self->{mirrored_key};

	$self->{num} = length($basename) - 1;

	$self->{has_pawns} = ($basename =~ /P/);

	# FIXME! That is taken from python-chess. But the variable names should
	# be swapped.
	my ($black_part, $white_part) = split /v/, $basename;

	if ($self->{has_pawns}) {
		$self->{pawns} = [
			$white_part =~ tr/P/P/, 
			$black_part =~ tr/P/P/, 
		];

		if ($self->{pawns}->[1] > 0
			&& ($self->{pawns}->[0] == 0 || $self->{pawns}->[1] < $self->{pawns}->[0]))
		{
			($self->{pawns}->[0], $self->{pawns}->[1]) =
				($self->{pawns}->[1], $self->{pawns}->[0]);
		}
	} else {
		my $j = 0;
		map { 
			++$j if 1 == (() = $white_part =~ /$_/g);
			++$j if 1 == (() = $black_part =~ /$_/g);
		} @PCHR;

		if ($j >= 3) {
			$self->{enc_type} = 0;
		} else {
			$self->{enc_type} = 2;
		}
	}

	bless $self, $class;
}

sub _initMmap {
	my ($self) = @_;

	return if defined $self->{data};

	# Open the file.
	sysopen(my $fh, $self->{path}, O_RDONLY | ($^O eq 'MSWin32' ? O_BINARY : 0))
		or die __x("Cannot open '{path}': {error}\n",
			path => $self->{path}, error => $@);

	# Get the file size.
	my $size = -s $fh;

	# Validate the file size.
	die __x("Invalid file size: Ensure '{path}' is a valid syzygy tablebase.\n",
			path => $self->{path})
		if $size % 64 != 16;

	# Make sure that the file is not closed.
	$self->{data_fh} = $fh;

	# Memory-map the file.
	my $data;
	mmap($data, $size, PROT_READ, MAP_SHARED, $fh)
		or die __x("Cannot mmap '{path}': {error}\n",
			path => $self->{path}, error => $@);

	$self->{data} = $data;
}

sub _checkMagic {
	my ($self, $magic) = @_;

	my @valid_magics = ($magic); # Use list so that we can theoretically expand.

	my $header = substr($self->{data}, 0, 4);

	my $ok = 0;
	for my $m (@valid_magics) {
		next unless defined $m;
		if ($header eq $m) {
			$ok = 1;
			last;
		}
	}

	if (!$ok) {
		die __x("Invalid magic header! Ensure that '{path}' is a valid syzygy tablebase file.\n",
			path => $self->{path});
	}
}

sub _setupPairs {
	my ($self, $data_ptr, $tb_size, $size_idx, $wdl) = @_;

	my $d = Chess::Plisco::Tablebase::Syzygy::PairsData->new;

	$self->{_flags} = $read_byte->($self->{data}, $data_ptr);

	if ($self->{_flags} & 0x80) {
		$d->{idxbits} = 0;

		if ($wdl) {
			$d->{min_len} = $read_byte->($self->{data}, $data_ptr + 1);
		} else {
			# http://www.talkchess.com/forum/viewtopic.php?p=698093#698093
			$d->{min_len} = 0;
		}

		$self->{_next} = $data_ptr + 2;
		$self->{size}->[$size_idx + 0] = 0;
		$self->{size}->[$size_idx + 1] = 0;
		$self->{size}->[$size_idx + 2] = 0;

		return $d;
	}

	$d->{blocksize} = $read_byte->($self->{data}, $data_ptr + 1);
	$d->{idxbits} = $read_byte->($self->{data}, $data_ptr + 2);

	my $real_num_blocks = $self->_readUint32($data_ptr + 4);
	my $num_blocks = $real_num_blocks + $read_byte->($self->{data}, $data_ptr + 3);
	my $max_len = $read_byte->($self->{data}, $data_ptr + 8);
	my $min_len = $read_byte->($self->{data}, $data_ptr + 9);
	my $h = $max_len - $min_len + 1;
	my $num_syms = $self->_readUint16($data_ptr + 10 + 2 * $h);

	${d}->{offset} = $data_ptr + 10;
	${d}->{symlen} = [(0) x ($h * 8 + $num_syms - 1)];
	${d}->{sympat} = $data_ptr + 12 + 2 * $h;
	${d}->{min_len} = $min_len;

	$self->{_next} = $data_ptr + 12 + 2 * $h + 3 * $num_syms + ($num_syms & 1);

	my $num_indices = ($tb_size + (1 << $d->{idxbits}) - 1) >> $d->{idxbits};
	$self->{size}->[$size_idx + 0] = 6 * $num_indices;
	$self->{size}->[$size_idx + 1] = 2 * $num_blocks;
	$self->{size}->[$size_idx + 2] = (1 << $d->{blocksize}) * $real_num_blocks;

	my @tmp = ((0) x ($num_syms - 1));
	for my $i (0 .. $num_syms - 1) {
		if (!$tmp[$i]) {
			$self->__calcSymlen($d, $i, \@tmp)
		}
	}

	$d->{base} = [(0) x $h];
	$d->{base}->[$h - 1] = 0;

	for my $i (reverse 0 .. $h - 2) {
		$d->{base}->[$i] = uint64(($d->{base}->[$i + 1]
			+ $self->_readUint16($d->{offset} + $i * 2)
			- $self->_readUint16($d->{offset} + $i * 2 + 2)) / 2);
	}

	for my $i (0 .. $h) {
		$d->{base}->[$i] <<= 64 - ($min_len + $i);
	}

	$d->{offset} -= 2 * $d->{min_len};

	return $d;
}

sub _setNormPiece {
	my ($self, $norm, $pieces) = @_;

	if ($self->{enc_type} == 0) {
		$norm->[0] = 3;
	} else {
		$norm->[0] = 2;
	}

	my $i = $norm->[0];
	while ($i < $self->{num}) {
		my $j = $i;
		while ($j < $self->{num} and $pieces->[$j] == $pieces->[$i]) {
			++$norm->[$i];
			++$j;
		}
		$i += $norm->[$i];
	}
}

sub _calcFactorsPiece {
	my ($self, $factor, $order, $norm) = @_;

	my @PIVFAC = (31332, 28056, 462);

	my $n = 64 - $norm->[0];

	my $f = 1;
	my $i = $norm->[0];
	my $k = 0;

	while ($i < $self->{num} || $k == $order) {
		if ($k == $order) {
			$factor->[0] = $f;
			if ($self->{enc_type} < 4) {
				$f *= $PIVFAC[$self->{enc_type}];
			} else {
				$f *= $MFACTOR[$self->{enc_type} - 2];
			}
		} else {
			$factor->[$i] = $f;
			$f *= $subfactor->($norm->[$i], $n);
			$n -= $norm->[$i];
			$i += $norm->[$i];
		}
		++$k;
	}

	return $f;
}

sub _calcFactorsPawn {
	my ($self, $factor, $order, $order2, $norm, $f) = @_;

	my $i = $norm->[0];
	if ($order2 < 0x0f) {
		$i += $norm->[$i];
	}
	my $n = 64 - $i;

	my $fac = 1;
	my $k = 0;

	while ($i < $self->{num} || $k == $order || $k == $order2) {
		if ($k == $order) {
			$factor->[0] = $fac;
			$fac *= $PFACTOR[$norm->[0] - 1]->[$f];
		} elsif ($k == $order2) {
			$factor->[$norm->[0]] = $fac;
			$fac *= $subfactor->($norm->[$norm->[0]], 48 - $norm->[0]);
		} else {
			$factor->[$i] = $fac;
			$fac *= $subfactor->($norm->[$i], $n);
			$n -= $norm->[$i];
			$i += $norm->[$i];
		}

		++$k;
	}

	return $fac;
}

sub _setNormPawn {
	my ($self, $norm, $pieces) = @_;

	$norm->[0] = $self->{pawns}->[0];

	if ($self->{pawns}->[1]) {
		$norm->[$self->{pawns}->[0]] = $self->{pawns}->[1];
	}

	my $i = $self->{pawns}->[0] + $self->{pawns}->[1];
	while ($i < $self->{num}) {
		my $j = $i;
		while ($j < $self->{num} && $pieces->[$j] == $pieces->[$i]) {
			++$norm->[$i];
			++$j;
		}
		$i += $norm->[$i];
	}
}

sub __calcSymlen {
	my ($self, $d, $s, $tmp) = @_;

	my $w = $d->{sympat} + 3 * $s;

	my $s2 = ($read_byte->($self->{data}, $w + 2) << 4) | ($read_byte->($self->{data}, $w + 1) >> 4);

	if ($s2 == 0x0fff) {
		$d->{symlen}->[$s] = 0;
	} else {
		my $s1 = (($read_byte->($self->{data}, $w + 1) & 0xf) << 8) | $read_byte->($self->{data}, $w);
		if (!$tmp->[$s1]) {
			$self->__calcSymlen($d, $s1, $tmp);
		}
		if (!$tmp->[$s2]) {
			$self->__calcSymlen($d, $s2, $tmp);
		}

		$d->{symlen}->[$s] = $d->{symlen}->[$s1] + $d->{symlen}->[$s2] + 1;
	}

	$tmp->[$s] = 1;
}

sub _pawnFile {
	my ($self, $shifts) = @_;

	foreach my $i (1 .. $self->{pawns}->[0] - 1) {
		if (FLAP->[$shifts->[0]] > FLAP->[$shifts->[$i]]) {
			($shifts->[0], $shifts->[$i]) = ($shifts->[$i], $shifts->[0]);
		}
	}

	return FILE_TO_FILE->[$shifts->[0] & 0x07];
}

sub _encodePiece {
	my ($self, $norm, $shifts, $factor) = @_;

	my $n = $self->{num};

	if ($shifts->[0] & 0x04) {
		foreach my $i (0 .. $n - 1) {
			$shifts->[$i] ^= 0x07;
		}
	}

	if ($shifts->[0] & 0x20) {
		foreach my $i (0 .. $n - 1) {
			$shifts->[$i] ^= 0x38;
		}
	}

	my $i;
	foreach (0 .. $n - 1) {
		$i = $_;
		if ($offdiag->($shifts->[$i])) {
			last;
		}
	}

	my $limit = $self->{enc_type} == 0 ? 3 : 2;
	if ($i < $limit && $offdiag->($shifts->[$i]) > 0) {
		foreach my $i (0 .. $n - 1) {
			$shifts->[$i] = $flipdiag->($shifts->[$i]);
		}
	}

	my $idx;
	if ($self->{enc_type} == 0) { # 111
		$i = $shifts->[1] > $shifts->[0];
		my $j = ($shifts->[2] > $shifts->[0]) + ($shifts->[2] > $shifts->[1]);

		if ($offdiag->($shifts->[0])) {
			$idx = TRIANGLE->[$shifts->[0]] * 63 * 62 + ($shifts->[1] - $i) * 62 + ($shifts->[2] - $j);
		} elsif ($offdiag->($shifts->[1])) {
			$idx = 6 * 63 * 62 + DIAG->[$shifts->[0]] * 28 * 62 + LOWER->[$shifts->[1]] * 62 + $shifts->[2] - $j;
		} elsif ($offdiag->($shifts->[2])) {
			$idx = 6 * 63 * 62 + 4 * 28 * 62 + (DIAG->[$shifts->[0]]) * 7 * 28 + (DIAG->[$shifts->[1]] - $i) * 28 + LOWER->[$shifts->[2]];
		} else {
			$idx = 6 * 63 * 62 + 4 * 28 * 62 + 4 * 7 * 28 + (DIAG->[$shifts->[0]] * 7 * 6) + (DIAG->[$shifts->[1]] - $i) * 6 + (DIAG->[$shifts->[2]] - $j);
		}
		$i = 3;
	} else { # K2
		$idx = KK_IDX->[TRIANGLE->[$shifts->[0]]]->[$shifts->[1]];
		$i = 2;
	}

	$idx *= $factor->[0];

	while ($i < $n) {
		my $t = $norm->[$i];

		foreach my $j ($i .. $i + $t - 1) {
			foreach my $k ($j + 1 .. $i + $t - 1) {
				# Swap.
				if ($shifts->[$j] > $shifts->[$k]) {
					($shifts->[$j], $shifts->[$k]) = ($shifts->[$k], $shifts->[$j]);
				}
			}
		}

		my $s = 0;

		foreach my $m ($i .. $i + $t - 1) {
			my $p = $shifts->[$m];
			my $j = 0;
			foreach my $l (0 .. $i - 1) {
				$j += $p > $shifts->[$l];
			}

			$s += $binom->($p - $j, $m - $i + 1);
		}

		$idx += $s * $factor->[$i];
		$i += $t;
	}

	return $idx;
}

sub _encodePawn {
	my ($self, $norm, $shifts, $factor) = @_;

	my $n = $self->{num};

	if ($shifts->[0] & 0x04) {
		foreach my $i (0 .. $n - 1) {
			$shifts->[$i] ^= 0x07;
		}
	}

	foreach my $i (1 .. $self->{pawns}->[0] - 1) {
		foreach my $j ($i + 1 .. $self->{pawns}->[0] - 1) {
			if ($PTWIST[$shifts->[$i]] < $PTWIST[$shifts->[$j]]) {
				($shifts->[$i], $shifts->[$j]) = ($shifts->[$j], $shifts->[$i]);
			}
		}
	}

	my $t = $self->{pawns}->[0] - 1;
	my $idx = $PAWNIDX[$t]->[FLAP->[$shifts->[0]]];
	foreach my $i (reverse 1 .. $t) {
		$idx += $binom->($PTWIST[$shifts->[$i]], $t - $i + 1);
	}
	$idx *= $factor->[0];

	# Remaining pawns.
	my $i = $self->{pawns}->[0];
	$t = $i + $self->{pawns}->[1];
	if ($t > $i) {
		foreach my $j ($i .. $t - 1){ 
			foreach my $k ($j + 1 .. $t - 1) {
				if ($shifts->[$j] > $shifts->[$k]) {
					($shifts->[$j], $shifts->[$k]) = ($shifts->[$k], $shifts->[$j]);
				}
			}
		}

		my $s = 0;
		foreach my $m ($i .. $t - 1) {
			my $p = $shifts->[$m];
			my $j = 0;

			foreach my $k (0 .. $i - 1) {
				$j += $p > $shifts->[$k];
			}

			$s += $binom->($p - $j - 8, $m - $i + 1);
		}

		$idx += $s * $factor->[$i];
		$i = $t;
	}

	while ($i < $n) {
		$t = $norm->[$i];
		foreach my $j ($i .. $i + $t - 1) {
			foreach my $k ($j + 1 .. $i + $t - 1){
				if ($shifts->[$j] > $shifts->[$k]) {
					($shifts->[$j], $shifts->[$k]) = ($shifts->[$k], $shifts->[$j]);
				}
			}
		}

		my $s = 0;
		foreach my $m ($i .. $i + $t - 1) {
			my $p = $shifts->[$m];
			my $j = 0;
			foreach my $k (0 .. $i - 1) {
				$j += $p > $shifts->[$k];
			}
			$s += $binom->($p - $j, $m - $i + 1);
		}

		$idx += $s * $factor->[$i];
		$i += $t;
	}

	return $idx;
}

sub _decompressPairs {
	my ($self, $d, $idx) = @_;

	if (!$d->{idxbits}) {
		return $d->{min_len};
	}

	my $mainidx = $idx >> $d->{idxbits};
	my $litidx = ($idx & (1 << $d->{idxbits}) - 1) - (1 << ($d->{idxbits} - 1));
	my $block = $self->_readUint32($d->{indextable} + 6 * $mainidx);

	my $idx_offset = $self->_readUint16($d->{indextable} + 6 * $mainidx + 4);
	$litidx += $idx_offset;

	if ($litidx < 0) {
		while ($litidx < 0) {
			--$block;
			$litidx += $self->_readUint16($d->{sizetable} + 2 * $block) + 1;
		}
	} else {
		while ($litidx > $self->_readUint16($d->{sizetable} + 2 * $block)) {
			$litidx -= $self->_readUint16($d->{sizetable} + 2 * $block) + 1;
			++$block;
		}
	}

	my $ptr = $d->{data} + ($block << $d->{blocksize});

	my $m = $d->{min_len};
	my $base_idx = -$m;
	my $symlen_idx = 0;

	my $code = $self->_readUint64BE($ptr);

	$ptr += 2 * 4;
	my $bitcnt = 0; # Number of empty bits in code
	my $sym;

	while (1) {
		my $l = $m;
		while ($code < $d->{base}->[$base_idx + $l]) {
			++$l;
		}
		$sym = $self->_readUint16($d->{offset} + $l * 2);
		$sym += ($code - $d->{base}->[$base_idx + $l]) >> (64 - $l);
		if ($litidx < $d->{symlen}->[$symlen_idx + $sym] + 1) {
			last;
		}
		$litidx -= $d->{symlen}->[$symlen_idx + $sym] + 1;
		$code <<= $l;
		$bitcnt += $l;
		if ($bitcnt >= 32) {
			$bitcnt -= 32;
			$code |= $self->_readUint32BE($ptr) << $bitcnt;
			$ptr += 4;
		}
	}

	my $sympat = $d->{sympat};
	while ($d->{symlen}->[$symlen_idx + $sym]) {
		my $w = $sympat + 3 * $sym;
		my $s1 = (($read_byte->($self->{data}, $w + 1) & 0xf) << 8) | $read_byte->($self->{data}, $w);
		if ($litidx < $d->{symlen}->[$symlen_idx + $s1] + 1) {
			$sym = $s1;
		} else {
			$litidx -= $d->{symlen}->[$symlen_idx + $s1] + 1;
			$sym = ($read_byte->($self->{data}, $w + 2) << 4) | ($read_byte->($self->{data}, $w + 1) >> 4);
		}
	}

	my $w = $sympat + 3 * $sym;
	if ($self->isa('DtzTable')) {
		return (($read_byte->($self->{data}, $w + 1) & 0x0f) << 8) | $read_byte->($self->{data}, $w);
	} else {
		return $read_byte->($self->{data}, $w);
	}
}

sub _readUint64BE {
	my ($self, $data_ptr) = @_;

	return uint64(unpack(UINT64_BE, substr($self->{data}, $data_ptr, 8)));
}

sub _readUint32 {
	my ($self, $data_ptr) = @_;

	return uint64(unpack(UINT32, substr($self->{data}, $data_ptr, 4)));
}

sub _readUint32BE {
	my ($self, $data_ptr) = @_;

	return unpack(UINT32_BE, substr($self->{data}, $data_ptr, 4));
}

sub _readUint16 {
	my ($self, $data_ptr) = @_;

	return unpack(UINT16, substr($self->{data}, $data_ptr, 2));
}

sub close {
	my ($self) = @_;

	if (defined $self->{data}) {
		delete $self->{data};
	}

	if (defined $self->{data_fh}) {
		close $self->{data_fh};
	}

	return;
}

sub DESTROY {
	my ($self) = @_;
	$self->close;
}

package Chess::Plisco::Tablebase::Syzygy::WdlTable;
$Chess::Plisco::Tablebase::Syzygy::WdlTable::VERSION = 'v1.0.1';
use Chess::Plisco qw(:all);

use base qw(Chess::Plisco::Tablebase::Syzygy::Table);

use constant TBW_MAGIC => "\x71\xe8\x23\x5d";

sub new {
	my ($class, @args) = @_;

	my $self = $class->SUPER::new(@args);

	$self->{_next} = 0;
	$self->{_flags} = 0;

	return $self;
}

sub __initTableWdl {
	my ($self) = @_;

	$self->_initMmap;

	if ($self->{initialized}) {
		return;
	}

	$self->_checkMagic(TBW_MAGIC);

	$self->{tb_size} = [(0) x 8];
	$self->{size} = [(0) x (8 * 3)];

	# Used if there are only pieces.
	$self->{precomp} = [];
	$self->{pieces} = [];
	$self->{factor} = [[(0) x $TBPIECES], [(0) x $TBPIECES]];
	$self->{norm} = [[(0) x $self->{num}], [(0) x $self->{num}]];

	# Used if there are pawns.
	$self->{files} = [
		Chess::Plisco::Tablebase::Syzygy::PawnFileData->new,
		Chess::Plisco::Tablebase::Syzygy::PawnFileData->new,
		Chess::Plisco::Tablebase::Syzygy::PawnFileData->new,
		Chess::Plisco::Tablebase::Syzygy::PawnFileData->new,
	];

	my $code = $read_byte->($self->{data}, 4);
	my $split = $code & 0x01;
	my $files = $code & 0x02 ? 4 : 1;

	my $data_ptr = 5;
	if (!$self->{has_pawns}) {
		$self->__setupPiecesPiece($data_ptr);

		$data_ptr += $self->{num} + 1;
		$data_ptr += $data_ptr & 0x01;

		$self->{precomp}->[0] = $self->_setupPairs($data_ptr, $self->{tb_size}->[0], 0, 1);
		$data_ptr = $self->{_next};
		if ($split) {
			$self->{precomp}->[1] = $self->_setupPairs($data_ptr, $self->{tb_size}->[1], 3, 1);
			$data_ptr = $self->{_next};
		}

		$self->{precomp}->[0]->{indextable} = $data_ptr;
		$data_ptr += $self->{size}->[0];
		if ($split) {
			$self->{precomp}->[1]->{indextable} = $data_ptr;
			$data_ptr += $self->{size}->[3];
		}

		$self->{precomp}->[0]->{sizetable} = $data_ptr;
		$data_ptr += $self->{size}->[1];
		if ($split) {
			$self->{precomp}->[1]->{sizetable} = $data_ptr;
			$data_ptr += $self->{size}->[4];
		}

		$data_ptr = ($data_ptr + 0x3f) & ~0x3f;
		$self->{precomp}->[0]->{data} = $data_ptr;
		$data_ptr += $self->{size}->[2];
		if ($split) {
			$data_ptr = ($data_ptr + 0x3f) & ~0x3f;
			$self->{precomp}->[1]->{data} = $data_ptr;
		}

		$self->{key} = $recalc_key->($self->{pieces}->[0]);
		$self->{mirrored_key} = $recalc_key->($self->{pieces}->[0], 1);
	} else {
		my $s = 1 + ($self->{pawns}->[1] > 0);
		foreach my $f (0 .. 3) {
			$self->__setupPiecesPawn($data_ptr, 2 * $f, $f);
			$data_ptr += $self->{num} + $s;
		}
		$data_ptr += $data_ptr & 0x01;

		foreach my $f (0 .. $files - 1) {
			$self->{files}->[$f]->{precomp}->[0] = $self->_setupPairs($data_ptr, $self->{tb_size}->[2 * $f], 6 * $f, 1);
			$data_ptr = $self->{_next};
			if ($split) {
				$self->{files}->[$f]->{precomp}->[1] = $self->_setupPairs($data_ptr, $self->{tb_size}->[2 * $f + 1], 6 * $f + 3, 1);
				$data_ptr = $self->{_next};
			}
		}

		foreach my $f (0 .. $files - 1) {
			$self->{files}->[$f]->{precomp}->[0]->{indextable} = $data_ptr;
			$data_ptr += $self->{size}->[6 * $f];
			if ($split) {
				$self->{files}->[$f]->{precomp}->[1]->{indextable} = $data_ptr;
				$data_ptr += $self->{size}->[6 * $f + 3];
			}
		}

		foreach my $f (0 .. $files - 1) {
			$self->{files}->[$f]->{precomp}->[0]->{sizetable} = $data_ptr;
			$data_ptr += $self->{size}[6 * $f + 1];
			if ($split) {
				$self->{files}->[$f]->{precomp}->[1]->{sizetable} = $data_ptr;
				$data_ptr += $self->{size}->[6 * $f + 4];
			}
		}

		foreach my $f (0 .. $files - 1) {
			$data_ptr = ($data_ptr + 0x3f) & ~0x3f;
			$self->{files}->[$f]->{precomp}->[0]->{data} = $data_ptr;
			$data_ptr += $self->{size}->[6 * $f + 2];
			if ($split) {
				$data_ptr = ($data_ptr + 0x3f) & ~0x3f;
				$self->{files}->[$f]->{precomp}->[1]->{data} = $data_ptr;
				$data_ptr += $self->{size}->[6 * $f + 5];
			}
		}
	}

	$self->{initialized} = 1;
}

sub __setupPiecesPawn {
	my ($self, $p_data, $p_tb_size, $f) = @_;

	my $j = 1 + ($self->{pawns}->[1] > 0);
	my $order = $read_byte->($self->{data}, $p_data) & 0x0f;
	my $order2 = $self->{pawns}->[1] ? $read_byte->($self->{data}, $p_data + 1) & 0x0f : 0x0f;
	foreach my $i (0 .. $self->{num} - 1) {
		$self->{files}->[$f]->{pieces}->[0]->[$i] = $read_byte->($self->{data}, $p_data + $i + $j) & 0x0f;
	}

	$self->{files}->[$f]->{norm}->[0] = [(0) x $self->{num}];	$self->_setNormPawn($self->{files}->[$f]->{norm}->[0], $self->{files}->[$f]->{pieces}->[0]);
	$self->{files}->[$f]->{factor}->[0] = [(0) x $TBPIECES];
	$self->{tb_size}->[$p_tb_size] = $self->_calcFactorsPawn($self->{files}->[$f]->{factor}->[0], $order, $order2, $self->{files}->[$f]->{norm}->[0], $f);

	$order = $read_byte->($self->{data}, $p_data) >> 4;
	$order2 = $self->{pawns}->[1] ? $read_byte->($self->{data}, $p_data + 1) >> 4 : 0x0f;
	foreach my $i (0 .. $self->{num} - 1) {
		$self->{files}->[$f]->{pieces}->[1]->[$i] = $read_byte->($self->{data}, $p_data + $i + $j) >> 4;
	}

	$self->{files}->[$f]->{norm}->[1] = [(0) x ($self->{num} - 1)];
	$self->_setNormPawn($self->{files}->[$f]->{norm}->[1], $self->{files}->[$f]->{pieces}->[1]);
	$self->{files}->[$f]->{factor}->[1] = [(0) x $TBPIECES];
	$self->{tb_size}->[$p_tb_size + 1] = $self->_calcFactorsPawn($self->{files}->[$f]->{factor}->[1], $order, $order2, $self->{files}->[$f]->{norm}->[1], $f);
}

sub __setupPiecesPiece {
	my ($self, $p_data) = @_;

	foreach my $i (0 .. $self->{num} - 1) {
		$self->{pieces}->[0]->[$i] = $read_byte->($self->{data}, $p_data + $i + 1) & 0x0f;
	}
	my $order = $read_byte->($self->{data}, $p_data) & 0x0f;
	$self->_setNormPiece($self->{norm}->[0], $self->{pieces}->[0]);
	$self->{tb_size}->[0] = $self->_calcFactorsPiece($self->{factor}->[0], $order, $self->{norm}->[0]);

	foreach my $i (0 .. $self->{num} - 1) {
		$self->{pieces}->[1]->[$i] = $read_byte->($self->{data}, $p_data + $i + 1) >> 4;
	}
	$order = $read_byte->($self->{data}, $p_data) >> 4;
	$self->_setNormPiece($self->{norm}->[1], $self->{pieces}->[1]);
	$self->{tb_size}->[1] = $self->_calcFactorsPiece($self->{factor}->[1], $order, $self->{norm}->[1]);
}

sub probeWdlTable {
	my ($self, $pos) = @_;

	$self->__initTableWdl;

	my $key = $calc_key->($pos);

	my ($cmirror, $mirror, $bside);
	my $to_move = $pos->[CP_POS_TURN];
	if (!$self->{symmetric}) {
		if ($key ne $self->{key}) {
			$cmirror = 8;
			$mirror = 0x38;
			$bside = $to_move == CP_WHITE;
		} else {
			$cmirror = $mirror = 0;
			$bside = $to_move != CP_WHITE;
		}
	} else {
		$cmirror = $to_move == CP_WHITE ? 0 : 8;
		$mirror = $to_move == CP_WHITE ? 0 : 0x38;
		$bside = 0
	}

	my $res;
	if (!$self->{has_pawns}) {
		my $p = [(0) x $TBPIECES];
		my $i = 0;
		while ($i < $self->{num}) {
			my $piece_type = $self->{pieces}->[$bside]->[$i] & 0x07;
			my $colour = ($self->{pieces}->[$bside]->[$i] ^ $cmirror) >> 3;
			my $bb = $colour ? ($pos->[$piece_type] & $pos->[CP_POS_BLACK_PIECES]) : ($pos->[$piece_type] & $pos->[CP_POS_WHITE_PIECES]); 

			while ($bb) {
				my $shift = (do {	my $B = $bb & -$bb;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
				$p->[$i++] = $shift;

				$bb = (($bb) & (($bb) - 1));
			}
		}

		# FIXME! idx is not always used by decompressPairs()!
		my $idx = $self->_encodePiece($self->{norm}->[$bside], $p, $self->{factor}->[$bside]);
		$res = $self->_decompressPairs($self->{precomp}->[$bside], $idx);
	} else {
		my $p = [(0) x $TBPIECES];
		my $i = 0;
		my $k = $self->{files}->[0]->{pieces}->[0]->[0] ^ $cmirror;
		my $colour = $k >> 3;
		my $piece_type = $k & 0x07;
		my $bb = $colour ? ($pos->[$piece_type] & $pos->[CP_POS_BLACK_PIECES]) : ($pos->[$piece_type] & $pos->[CP_POS_WHITE_PIECES]);

		while ($bb) {
			my $shift = (do {	my $B = $bb & -$bb;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
			$p->[$i++] = $shift ^ $mirror;

			$bb = (($bb) & (($bb) - 1));
		}

		my $f = $self->_pawnFile($p);
		my $pc = $self->{files}->[$f]->{pieces}->[$bside];

		while ($i < $self->{num}) {
			my $colour = ($pc->[$i] ^ $cmirror) >> 3;
			my $piece_type = $pc->[$i] & 0x07;
			my $bb = $colour ? ($pos->[$piece_type] & $pos->[CP_POS_BLACK_PIECES]) : ($pos->[$piece_type] & $pos->[CP_POS_WHITE_PIECES]); 

			while ($bb) {
				my $shift = (do {	my $B = $bb & -$bb;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
				$p->[$i++] = $shift ^ $mirror;

				$bb = (($bb) & (($bb) - 1));
			}
		}

		# FIXME! idx is not always used by decompressPairs()!
		my $idx = $self->_encodePawn($self->{files}->[$f]->{norm}->[$bside], $p, $self->{files}->[$f]->{factor}->[$bside]);
		$res = $self->_decompressPairs($self->{files}->[$f]->{precomp}->[$bside], $idx);
	}

	return $res - 2;
}

package Chess::Plisco::Tablebase::Syzygy::DtzTable;
$Chess::Plisco::Tablebase::Syzygy::DtzTable::VERSION = 'v1.0.1';
use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

use base qw(Chess::Plisco::Tablebase::Syzygy::Table);

use constant TBZ_MAGIC => "\xd7\x66\x0c\xa5";

use constant WDL_TO_MAP => [1, 3, 0, 2, 0];

use constant PA_FLAGS => [8, 0, 0, 0, 4];

sub __initTableDtz {
	my ($self) = @_;

	$self->_initMmap;

	if ($self->{initialized}) {
		return;
	}

	$self->_checkMagic(TBZ_MAGIC);

	$self->{factor} = [(0) x $TBPIECES];
	$self->{norm} = [(0) x $self->{num}];
	$self->{tb_size} = [0, 0, 0, 0];
	$self->{size} = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	$self->{files} = [
		Chess::Plisco::Tablebase::Syzygy::PawnFileDataDtz->new,
		Chess::Plisco::Tablebase::Syzygy::PawnFileDataDtz->new,
		Chess::Plisco::Tablebase::Syzygy::PawnFileDataDtz->new,
		Chess::Plisco::Tablebase::Syzygy::PawnFileDataDtz->new,
	];


	my $files = ($read_byte->($self->{data}, 4) & 0x2) ? 4 : 1;

	my $p_data = 5;

	if (!$self->{has_pawns}) {
		$self->{map_idx} = [[0, 0, 0, 0]];

		$self->__setupPiecesPieceDtz($p_data, 0);
		$p_data += $self->{num} + 1;
		$p_data += $p_data & 0x01;

		$self->{precomp} = $self->_setupPairs($p_data, $self->{tb_size}->[0], 0);
		$self->{flags} = $self->{_flags};

		$p_data = $self->{_next};
		$self->{p_map} = $p_data;
		if ($self->{flags} & 2) {
			if (!($self->{flags} & 16)) {
				foreach my $i (0 .. 3) {
					$self->{map_idx}->[0]->[$i] = $p_data + 1 - $self->{p_map};
					$p_data += 1 + $read_byte->($self->{data}, $p_data);
				}
			} else {
				foreach my $i (0 .. 3) {
					$self->{map_idx}->[0]->[$i] = (defined $self->{p_map}) ? ($p_data + 2 - $self->{p_map}) : 2;
					$p_data += 2 + 2 * $self->_readUint16($p_data);
				}
			}
		}
		$p_data += $p_data & 0x01;

		$self->{precomp}->{indextable} = $p_data;
		$p_data += $self->{size}->[0];

		$self->{precomp}->{sizetable} = $p_data;
		$p_data += $self->{size}->[1];

		$p_data = ($p_data + 0x3f) & ~0x3f;
		$self->{precomp}->{data} = $p_data;
		$p_data += $self->{size}->[2];

		$self->{key} = $recalc_key->($self->{pieces});
		$self->{mirrored_key} = $recalc_key->($self->{pieces}, 1);
	} else {
		my $s = 1 + ($self->{pawns}->[1] > 0);
		foreach my $f (0 .. 3) {
			$self->__setupPiecesPawnDtz($p_data, $f, $f);
			$p_data += $self->{num} + $s;
		}
		$p_data += $p_data & 0x01;

		$self->{flags} = [];
		foreach my $f (0 .. ($files - 1)) {
			$self->{files}->[$f]->{precomp} = $self->_setupPairs($p_data, $self->{tb_size}->[$f], 3 * $f);
			$p_data = $self->{_next};
			push @{$self->{flags}}, $self->{_flags};
		}

		$self->{map_idx} = [];
		$self->{p_map} = $p_data;
		foreach my $f (0 .. ($files - 1)) {
			push @{$self->{map_idx}}, [];
			if ($self->{flags}->[$f] & 2) {
				if (!($self->{flags}->[$f] & 16)) {
					foreach (0 .. 3) {
						push @{$self->{map_idx}->[-1]}, $p_data + 1 - $self->{p_map};
						$p_data += 1 + $read_byte->($self->{data}, $p_data);
					}
				} else {
					$p_data += $p_data & 0x01;
					foreach (0 .. 3) {
						if (defined $self->{p_map}) {
							push @{$self->{map_idx}->[-1]}, $p_data + 2 - $self->{p_map};
						} else {
							push @{$self->{map_idx}->[-1]}, 2;
						}
						$p_data += 2 + 2 * $self->_readUint16($p_data);
					}
				}
			}
		}
		$p_data += $p_data & 0x01;

		foreach my $f (0 .. ($files - 1)) {
			$self->{files}->[$f]->{precomp}->{indextable} = $p_data;
			$p_data += $self->{size}->[3 * $f];
		}

		foreach my $f (0 .. ($files - 1)) {
			$self->{files}->[$f]->{precomp}->{sizetable} = $p_data;
			$p_data += $self->{size}->[3 * $f + 1];
		}

		foreach my $f (0 .. ($files - 1)) {
			$p_data = ($p_data + 0x3f) & ~0x3f;
			$self->{files}->[$f]->{precomp}->{data} = $p_data;
			$p_data += $self->{size}->[3 * $f + 2];
		}
	}

	$self->{initialized} = 1;
}

sub __setupPiecesPieceDtz {
	my ($self, $p_data, $p_tb_size) = @_;

	foreach my $i (0 .. $self->{num} - 1) {
		$self->{pieces}->[$i] = $read_byte->($self->{data}, $p_data + $i + 1);
	}
	my $order = $read_byte->($self->{data}, $p_data) & 0x0f;
	$self->_setNormPiece($self->{norm}, $self->{pieces});
	$self->{tb_size}->[$p_tb_size] = $self->_calcFactorsPiece($self->{factor}, $order, $self->{norm});
}

sub __setupPiecesPawnDtz {
	my ($self, $p_data, $p_tb_size, $f) = @_;

	my $j = 1;
	++$j if $self->{pawns}->[1] > 0;
	my $order = $read_byte->($self->{data}, $p_data) & 0x0f;
	my $order2 = $self->{pawns}->[1] ? $read_byte->($self->{data}, $p_data + 1) & 0xf : 0xf;
	foreach my $i (0 .. $self->{num} - 1) {
		$self->{files}->[$f]->{pieces}->[$i] = $read_byte->($self->{data}, $p_data + $i + $j);
	}

	$self->{files}->[$f]->{norm} = [(0) x ($self->{num} - 1)];
	$self->_setNormPawn($self->{files}->[$f]->{norm}, $self->{files}->[$f]->{pieces});

	$self->{files}->[$f]->{factor} = [(0) x ($TBPIECES - 1)];
	$self->{tb_size}->[$p_tb_size] = $self->_calcFactorsPawn($self->{files}->[$f]->{factor}, $order, $order2, $self->{files}->[$f]->{norm}, $f);
}

sub probeDtzTable {
	my ($self, $pos, $wdl) = @_;

	$self->__initTableDtz;

	my $key = $calc_key->($pos);

	my ($cmirror, $mirror, $bside);
	my $to_move = $pos->[CP_POS_TURN];
	if (!$self->{symmetric}) {
		if ($key ne $self->{key}) {
			$cmirror = 8;
			$mirror = 0x38;
			$bside = $to_move == CP_WHITE;
		} else {
			$cmirror = $mirror = 0;
			$bside = $to_move != CP_WHITE;
		}
	} else {
		$cmirror = $to_move == CP_WHITE ? 0 : 8;
		$mirror = $to_move == CP_WHITE ? 0 : 0x38;
		$bside = 0
	}

	my $res;
	if (!$self->{has_pawns}) {
		if (($self->{flags} & 1) != $bside && !$self->{symmetric}) {
			return 0, -1;
		}

		my $pc = $self->{pieces};
		my $p = [(0) x ($TBPIECES - 1)];
		my $i = 0;
		while ($i < $self->{num}) {
			my $piece_type = $pc->[$i] & 0x07;
			my $colour = ($pc->[$i] ^ $cmirror) >> 3;
			my $bb = $colour ? ($pos->[$piece_type] & $pos->[CP_POS_BLACK_PIECES]) : ($pos->[$piece_type] & $pos->[CP_POS_WHITE_PIECES]); 

			while ($bb) {
				my $shift = (do {	my $B = $bb & -$bb;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
				$p->[$i++] = $shift;

				$bb = (($bb) & (($bb) - 1));
			}
		}

		# FIXME!
		my $idx = $self->_encodePiece($self->{norm}, $p, $self->{factor});
		$res = $self->_decompressPairs($self->{precomp}, $idx);

		if ($self->{flags} & 2) {
			if (!($self->{flags} & 16)) {
				$res = $read_byte->($self->{data}, $self->{p_map} + $self->{map_idx}->[0]->[WDL_TO_MAP->[$wdl + 2]] + $res);
			} else {
				$res = $self->_readUint16($self->{p_map} + 2 * ($self->{map_idx}->[0]->[WDL_TO_MAP->[$wdl + 2]] + $res));
			}
		}

		if (!($self->{flags} & PA_FLAGS->[$wdl + 2]) || ($wdl & 1)) {
			$res *= 2;
		}
	} else {
		my $k = $self->{files}->[0]->{pieces}->[0] ^ $cmirror;
		my $piece_type = $k & 0x07;
		my $colour = $k >> 3;
		my $bb = $colour ? ($pos->[$piece_type] & $pos->[CP_POS_BLACK_PIECES]) : ($pos->[$piece_type] & $pos->[CP_POS_WHITE_PIECES]); 

		my $i = 0;
		my $p = [(0) x ($TBPIECES - 1)];
		while ($bb) {
			my $shift = (do {	my $B = $bb & -$bb;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
			$p->[$i++] = $shift ^ $mirror;

			$bb = (($bb) & (($bb) - 1));
		}

		my $f = $self->_pawnFile($p);
		if (($self->{flags}->[$f] & 1) != $bside) {
			return 0, -1;
		}

		my $pc = $self->{files}->[$f]->{pieces};
		while ($i < $self->{num}) {
			$piece_type = $pc->[$i] & 0x07;
			$colour = ($pc->[$i] ^ $cmirror) >> 3;
			my $bb = $colour ? ($pos->[$piece_type] & $pos->[CP_POS_BLACK_PIECES]) : ($pos->[$piece_type] & $pos->[CP_POS_WHITE_PIECES]); 

			while ($bb) {
				my $shift = (do {	my $B = $bb & -$bb;	my $A = $B - 1 - ((($B - 1) >> 1) & 0x5555_5555_5555_5555);	my $C = ($A & 0x3333_3333_3333_3333) + (($A >> 2) & 0x3333_3333_3333_3333);	my $n = $C + ($C >> 32);	$n = ($n & 0x0f0f0f0f) + (($n >> 4) & 0x0f0f0f0f);	$n = ($n & 0xffff) + ($n >> 16);	$n = ($n & 0xff) + ($n >> 8);});
				$p->[$i++] = $shift ^ $mirror;

				$bb = (($bb) & (($bb) - 1));
			}
		}

		my $idx = $self->_encodePawn($self->{files}->[$f]->{norm}, $p, $self->{files}->[$f]->{factor});
		$res = $self->_decompressPairs($self->{files}->[$f]->{precomp}, $idx);

		if ($self->{flags}->[$f] & 2) {
			if (!($self->{flags}->[$f] & 16)) {
				$res = $read_byte->($self->{data}, $self->{p_map} + $self->{map_idx}->[$f]->[WDL_TO_MAP->[$wdl + 2]] + $res);
			} else {
				$res = $self->_readUint16($self->{p_map} + 2 * ($self->{map_idx}->[$f]->[WDL_TO_MAP->[$wdl + 2]] + $res));
			}
		}

		if (!($self->{flags}->[$f] & $->[$wdl + 2]) || ($wdl & 1)) {
			$res *= 2;
		}
	}

	return $res, 1;
}

package Chess::Plisco::Tablebase::Syzygy;
$Chess::Plisco::Tablebase::Syzygy::VERSION = 'v1.0.1';
use File::Basename qw(basename);
use File::Globstar qw(globstar);
use Locale::TextDomain qw('Chess-Plisco');
use Tie::Cache::LRU;

use Chess::Plisco qw(:all);
use Chess::Plisco::Macro;

use constant TBW_SUFFIX => 'rtbw';
use constant TBZ_SUFFIX => 'rtbz';
use constant WDL_TO_DTZ => [-1, -101, 0, 101, 1];

sub new {
	my ($class, $directory, %__options) = @_;

	my %options = (
		load_wdl => 1,
		load_dtz => 1,
		max_fds => 128,
		%__options
	);

	my %tables;
	if (0 + $options{max_fds} > 0) {
		tie %tables, 'Tie::Cache::LRU', $options{max_fds};
	}

	my $self = bless {
		tables => \%tables,
		wdl => {},
		dtz => {},
	}, $class;

	$self->addDirectory($directory, %options) if defined $directory;

	return $self;
}

sub addDirectory {
	my ($self, $directory, %__options) = @_;

	my %options = (
		load_wdl => 1,
		load_dtz => 1,
		%__options
	);

	my (@rtbw_files, @rtbz_files);
	$directory = File::Spec->rel2abs($directory);

	if ($options{recursive}) {
		@rtbw_files = globstar "$directory/**/*.rtbw" if $options{load_wdl};
		@rtbz_files = globstar "$directory/**/*.rtbz" if $options{load_dtz};
	} else {
		@rtbw_files = globstar "$directory/*.rtbw" if $options{load_wdl};
		@rtbz_files = globstar "$directory/*.rtbz" if $options{load_dtz};
	}

	my @files = (@rtbw_files, @rtbz_files);

	my $num_files = 0;
	foreach my $filename (@files) {
		++$num_files if $self->__addFile($filename, %options)
	}

	return $num_files;
}

sub __addFile {
	my ($self, $path, %options) = @_;

	my $basename = basename $path;
	my ($tablename, $ext) = split /\./, $basename, 2;

	if ($is_tablename->($tablename)) {
		my ($white_part, $black_part) = split 'v', $tablename;
		my $mirrored_tablename = join 'v', $black_part, $white_part;
		if ($ext eq TBW_SUFFIX) {
			if ($options{load_wdl}) {
				$self->{wdl}->{$tablename} = $path;
				$self->{wdl}->{$mirrored_tablename} = $path;

				return 1;
			}
		} elsif ($ext eq TBZ_SUFFIX) {
			if ($options{load_dtz}) {
				$self->{dtz}->{$tablename} = $path;
				$self->{dtz}->{$mirrored_tablename} = $path;

				return 1;
			}
		}
	}
}

sub largestWdl {
	my ($self) = @_;

	my $max = 0;
	foreach my $table (keys %{$self->{wdl}}) {
		my $num_pieces = (length $table) - 1;
		$max = $num_pieces if $num_pieces > $max;
	}

	return $max;
}

sub largestDtz {
	my ($self) = @_;

	my $max = 0;
	foreach my $table (keys %{$self->{dtz}}) {
		my $num_pieces = (length $table) - 1;
		$max = $num_pieces if $num_pieces > $max;
	}

	return $max;
}

sub largest {
	my ($self) = @_;

	my $largestWdl = $self->largestWdl;
	my $largestDtz = $self->largestDtz;

	return $largestWdl < $largestDtz ? $largestWdl : $largestDtz;
}

sub __checkPosition {
	my ($self, $pos) = @_;

	if ($pos->castlingRights) {
		die __x("Syzygy tables do not contain positions with castling rights: {fen}",
			fen => $pos->toFEN);
	}

	my $piece_count;
	{ my $_b = $pos->occupied; for ($piece_count = 0; $_b; ++$piece_count) { $_b &= $_b - 1; } };

	if ($piece_count > $TBPIECES + 1) {
		die __x("syzygy tables support up to {TBPIECES} pieces, not {piece_count}: {fen}",
			TBPIECES => $TBPIECES,
			piece_count => $piece_count,
			fen => $pos->toFEN);
	}

	return $self;
}

sub probeWdl {
	my ($self, $pos) = @_;

	$self->__checkPosition($pos);

	my ($value) = $self->__probeAb($pos, -2, 2);

	# Positions where en passant is possible need special care because the
	# Syzygy tablebases assume that en passant is not possible. Otherwise,
	# we can just return the result of the probe.
	my $ep_shift = $pos->[CP_POS_EN_PASSANT_SHIFT];
	return $value if !$ep_shift;

	# Positions resulting from en passant captures have not been considered,
	# when generating the table. We do that now, in the wrapper code, by
	# trying to play these en passant captures.  If any of them (maximum 2)
	# yields a better result than the probe, that move should be played.
	#
	# Test case: 8/8/8/pPk5/8/8/8/7K w - a6 0 1
	#
	# It is also possible that the only legal moves in a position are en
	# passant captures. Example: K7/3n1P2/1k6/pP6/8/8/8/8 w - a6 0 1. In this
	# case, the best of the captures have to be played.
	my $v1 = -3;
	my @legal_moves = $pos->legalMoves;
	my @ep_captures;
	foreach my $move (@legal_moves) {
		my $to = ((($move) >> 15) & 0x3f);
		next if $to != $ep_shift;

		my $piece = (($move) & 0x7);
		next if $piece != CP_PAWN;

		push @ep_captures, $move;
	}

	foreach my $move (@ep_captures) {
		my $undo = $pos->doMove($move);
		eval {
			my ($v0_plus) = $self->__probeAb($pos, -2, 2);
			my $v0 = -$v0_plus;

			if ($v0 > $v1) {
				$v1 = $v0;
			}
		};
		$pos->undoMove($undo);
		die $@ if $@;
	}

	if ($v1 > -3) {
		if ($v1 >= $value) {
			$value = $v1;
		} elsif ($value == 0) {
			if (@legal_moves == @ep_captures) {
				# All legal moves are en passant captures.
				$value = $v1;
			}
		}
	}
	
	return $value;
}

sub probeDtz {
	my ($self, $pos) = @_;

	my $value = $self->__probeDtzNoEP($pos);

	# Positions where en passant is possible need special care because the
	# Syzygy tablebases assume that en passant is not possible. Otherwise,
	# we can just return the result of the probe.
	my $ep_shift = $pos->[CP_POS_EN_PASSANT_SHIFT];

	return $value if !$ep_shift;

	# Positions resulting from en passant captures have not been considered,
	# when generating the table. We do that now, in the wrapper code, by
	# trying to play these en passant captures.  If any of them (maximum 2)
	# yields a better result than the probe, that move should be played.
	#
	# Test case: 8/8/8/pPk5/8/8/8/7K w - a6 0 1
	#
	# It is also possible that the only legal moves in a position are en
	# passant captures. Example: K7/3n1P2/1k6/pP6/8/8/8/8 w - a6 0 1. In this
	# case, the best of the captures have to be played.
	my $v1 = -3;
	my @legal_moves = $pos->legalMoves;
	my @ep_captures;
	foreach my $move (@legal_moves) {
		my $to = ((($move) >> 15) & 0x3f);
		next if $to != $ep_shift;

		my $piece = (($move) & 0x7);
		next if $piece != CP_PAWN;

		push @ep_captures, $move;
	}

	foreach my $move (@ep_captures) {
		my $undo = $pos->doMove($move);
		eval {
			my ($v0_plus) = $self->__probeAb($pos, -2, 2);
			my $v0 = -$v0_plus;

			if ($v0 > $v1) {
				$v1 = $v0;
			}
		};
		$pos->undoMove($undo);
		die $@ if $@;
	}

	if ($v1 > -3) {
		$v1 = WDL_TO_DTZ->[$v1 + 2];
		if ($value < -100) {
			if ($v1 >= 0) {
				$value = $v1;
			}
		} elsif ($value < 0) {
			if ($v1 >= 0 || $v1 < -100) {
				$value = $v1;
			}
		} elsif ($value > 100) {
			if ($v1 > 0) {
				$value = $v1;
			}
		} elsif ($value > 0) {
			if ($v1 == 1) {
				$value = $v1;
			}
		} elsif ($v1 >= 0) {
			$value = $v1;
		} else {
			if (@legal_moves == @ep_captures) {
				# All legal moves are en passant captures.
				$value = $v1;
			}
		}
	}

	return $value;
}

sub __probeDtzNoEP {
	my ($self, $pos) = @_;

	my ($wdl, $success) = $self->__probeAb($pos, -2, 2);
	return 0 if $wdl == 0;

	if ($success == 2
	    || !($pos->[CP_POS_WHITE_PIECES + $pos->[CP_POS_TURN]] & ~$pos->[CP_POS_PAWNS])) {
		return $dtz_before_zeroing->($wdl);
	}

	my $moves;
	if ($wdl > 0) {
		# Generate all legal non-capturing pawn moves.
		$moves //= [$pos->legalMoves];
		foreach my $move (@$moves) {
			next if (($move) & 0x7) != CP_PAWN;
			next if ((($move) >> 3) & 0x7);

			my $undo = $pos->doMove($move);

			my $v = eval { -$self->probeWdl($pos) };
			$pos->undoMove($undo);
			die $@ if $@;

			if ($v == $wdl) {
				return ($v == 2) ? 1 : 101;
			}
		}
	}

	my ($dtz, $success) = $self->__probeDtzTable($pos, $wdl);
	if ($success >= 0) {
		if ($wdl > 0) {
			return $dtz_before_zeroing->($wdl) + $dtz;
		} else {
			return $dtz_before_zeroing->($wdl) - $dtz;
		}
	}

	my $best;

	if ($wdl > 0) {
		$best = 0xffff;

		# Generate all quite non-pawn moves.
		$moves //= [$pos->legalMoves];
		foreach my $move (@$moves) {
			next if (($move) & 0x7) == CP_PAWN;
			next if ((($move) >> 3) & 0x7);

			my $undo = $pos->doMove($move);
			eval {
				my $v = -$self->probeDtz($pos);

				if ($v == 1 && $is_checkmate->($pos)) {
					$best = 1;
				} elsif (($v > 0) && (($v + 1) < $best)) {
					$best = $v + 1;
				}
			};
			$pos->undoMove($undo);
			die $@ if $@;
		}
	} else {
		$best = -1;

		$moves //= [$pos->legalMoves];
		foreach my $move (@$moves) {
			my $undo = $pos->doMove($move);

			my $v;
			eval {
				if (!$pos->[CP_POS_HALFMOVE_CLOCK]) {
					if ($wdl == -2) {
						$v = -1;
					} else {
						# FIXME! No need to store $success.
						($v, $success) = $self.__probeAb($pos, 1, 2);
						$v = ($v == 2) ? 0 : -101;
					}
				} else {
					$v = -$self->probeDtz($pos) - 1;
				}
			};
			$pos->undoMove($undo);
			die $@ if $@;

			if ($v < $best) {
				$best = $v;
			}
		}
	}

	return $best;
}

sub safeProbeWdl {
	my ($self, $pos, $default) = @_;

	my $result;
	eval {
		$result = $self->probeWdl($pos);
	};
	if ($@) {
		if (ref $@
		    && $@->isa('Chess::Plisco::Tablebase::Syzygy::MissingTableException')) {
			return $default;
		} else {
			# Re-throw.
			die $@;
		}
	}

	return $result;
}

sub safeProbeDtz {
	my ($self, $pos, $default) = @_;

	my $result;
	eval {
		$result = $self->probeDtz($pos);
	};
	if ($@) {
		if (ref $@ && $@->isa('Chess::Plisco::Tablebase::Syzygy::MissingTableException')) {
			return $default;
		} else {
			# Re-throw.
			die $@;
		}
	}

	return $result;
}

sub __probeAb {
	my ($self, $pos, $alpha, $beta) = @_;

	# Iterate over all non-ep captures.
	my $v;
	foreach my $move ($remove_ep->($pos)->legalMoves) {
		((($move) >> 3) & 0x7) or next;

		my $undo = $pos->doMove($move);
		eval {
			my ($v_plus) = $self->__probeAb($pos, -$beta, -$alpha);
			$v = -$v_plus;
		};
		$pos->undoMove($undo);
		die $@ if $@;

		if ($v > $alpha) {
			if ($v >= $beta) {
				return $v, 2;
			}

			$alpha = $v;
		}

	}

	$v = $self->__probeWdlTable($pos);

	if ($alpha >= $v) {
		return $alpha > 0 ? ($alpha, 2) : ($alpha, 1);
	}

	return $v, 1
}

sub __probeWdlTable {
	my ($self, $pos) = @_;

	# Test for KvK.
	if ($pos->[CP_POS_KINGS]
	    == ($pos->[CP_POS_WHITE_PIECES] | $pos->[CP_POS_BLACK_PIECES])) {
		return 0;
	}

	my $key = $calc_key->($pos);
	my $path = $self->{wdl}->{$key};
	if (!defined $path) {
		die Chess::Plisco::Tablebase::Syzygy::MissingTableException->new(__x(
			__"Missing WDL table '{key}'.\n",
			key => $key,
		));
	}

	my $full_key = join '', $key, '.', TBW_SUFFIX;
	my $table = $self->{tables}->{$full_key};
	if (!$table) {
		$table = Chess::Plisco::Tablebase::Syzygy::WdlTable->new($path);
		$self->{tables}->{$full_key} = $table if $table;
	}

	if (!$table) {
		die __x("Cannot initialize WDL table '{key}'.\n", key => $key);
	}

	return $table->probeWdlTable($pos);
}

sub __probeDtzTable {
	my ($self, $pos, $wdl) = @_;

	my $key = $calc_key->($pos);
	my $path = $self->{dtz}->{$key};
	if (!defined $path) {
		die Chess::Plisco::Tablebase::Syzygy::MissingTableException->new(__x(
			__"Missing DTZ table '{key}'.\n",
			key => $key,
		));
	}

	my $full_key = join '', $key, '.', TBZ_SUFFIX;
	my $table = $self->{tables}->{$full_key};
	if (!$table) {
		$table = Chess::Plisco::Tablebase::Syzygy::DtzTable->new($path);
		$self->{tables}->{$full_key} = $table if $table;
	}

	if (!$table) {
		die __x("Cannot initialize DTZ table '{key}'.\n", key => $key);
	}

	return $table->probeDtzTable($pos, $wdl);
}

1;
