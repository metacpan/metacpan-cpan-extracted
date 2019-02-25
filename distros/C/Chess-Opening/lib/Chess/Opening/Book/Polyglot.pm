#! /bin/false

# Copyright (C) 2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Make Dist::Zilla happy.
# ABSTRACT: Read chess opening books in polyglot format

package Chess::Opening::Book::Polyglot;
$Chess::Opening::Book::Polyglot::VERSION = '0.6';
use common::sense;

use 5.12.0;

use base 'Chess::Opening::Book';

use Fcntl qw(:seek);
use IO::Seekable 1.20;

use Chess::Opening::Book::Polyglot::Random64;

sub new {
	my ($class, $filename) = @_;

	open my $fh, '<', $filename
		or die __x("error opening '{filename}': {error}!\n",
		           filename => $filename, error => $!);

	$fh->sysseek(0, SEEK_END)
		or die __x("error seeking '{filename}': {error}!\n",
		           filename => $filename, error => $!);
	
	my $size = $fh->sysseek(0, SEEK_CUR);
	die __x("error getting position in '{filename}': {error}!\n",
		    filename => $filename, error => $!)
		if $size < 0;
	
	die __x("error: {filename}: file size {size} is not a multiple of 16!\n",
		    filename => $filename, size => $size, error => $!)
		if $size & 0xf;
	my $num_entries = $size >> 4;
	bless {
		__fh => $fh,
		__filename => $filename,
		__num_entries => $num_entries,
	}, $class;
}

# Do a binary search in the file for the requested position.
# Using variations of the binary search like interpolation search or the
# newer adaptive search or hybrid search 
# (https://arxiv.org/ftp/arxiv/papers/1708/1708.00964.pdf) is less performant
# because it involves significantly more disk access.
# This method returns a range of matching records.
sub _findKey {
	my ($self, $key) = @_;

	return if !$self->{__num_entries};

	my $left = 0;
	my $right = $self->{__num_entries};

	my $found = '';
	my $mid;
	while ($left < $right) {
		$mid = $left + (($right - $left) >> 1);
		$found = $self->__getEntryKey($mid);
		if ($found gt $key) {
			$right = $right == $mid ? $mid - 1 : $mid;
		} elsif ($found lt $key) {
			$left = $left == $mid ? $mid + 1 : $mid;
		} else {
			last;
		}
	}

	# Found?
	return if $key ne $found;

	my $first = $mid;
	my $last = $mid;
	while ($first - 1 >= 0) {
		$found = $self->__getEntryKey($first - 1);
		last if $found ne $key;
		--$first;
	}
	while ($last + 1 < $self->{__num_entries}) {
		$found = $self->__getEntryKey($last + 1);
		last if $found ne $key;
		++$last;
	}

	return ($first, $last);
}

sub _getKey {
	my ($whatever, $fen) = @_;

	use integer;

	my $key = "\x00" x 8;

	# 32-bit safe xor routine.
	my $xor = sub {
		my ($left, $right) = @_;

		my @llongs = unpack 'NN', $left;
		my @rlongs = unpack 'NN', $right;
		$llongs[0] ^= $rlongs[0];
		$llongs[1] ^= $rlongs[1];

		return pack 'NN', @llongs;
	};

	my $random64 = Chess::Opening::Book::Polyglot::Random64::DATA();

	my %pos = $whatever->_parseFEN($fen) or return;
	my %pieces = $whatever->_pieces;
	foreach my $spec (@{$pos{pieces}}) {
		my ($file, $rank) = split //, $spec->{field};
		$file = (ord $file) - (ord 'a');
		$rank = (ord $rank) - (ord '1');
		my $piece = $pieces{$spec->{piece}};
		my $offset = ($piece << 6) | ($rank << 3) | $file;
		$key = $xor->($key, $random64->[$offset]);
	}

	my %castling_offsets = (
		K => 768 + 0,
		Q => 768 + 1,
		k => 768 + 2,
		q => 768 + 3,
	);

	foreach my $char (keys %{$pos{castling}}) {
		my $offset = $castling_offsets{$char};
		$key = $xor->($key, $random64->[$offset]);
	}

	if ($pos{ep}) {
		my ($ep_file, $ep_rank) = split //, $pos{ep};
		my $ep_char = ord $ep_file;
		# This may produce invalid coordinates for the a and h rank but this
		# is harmless.
		my @pawns;
		my $pawn;
		
		if ('w' eq $pos{on_move}) {
			@pawns = (
				chr($ep_char - 1) . '5',
				chr($ep_char + 1) . '5',
			);
			$pawn = 'P';
		} else {
			@pawns = (
				chr($ep_char - 1) . '4',
				chr($ep_char + 1) . '4',
			);
			$pawn = 'p';
		}

		SPEC: foreach my $spec(@{$pos{pieces}}) {
			foreach my $field (@pawns) {
				if ($spec->{field} eq $field && $spec->{piece} eq $pawn) {
					my $offset = 772 + $ep_char - ord 'a';
					$key = $xor->($key, $random64->[$offset]);
					last SPEC;
				}
			}
		}
	}

	if ('w' eq $pos{on_move}) {
		$key = $xor->($key, $random64->[780]);
	}

	return $key;
}

sub __getEntryKey {
	my ($self, $number) = @_;

	my $offset = $number << 4;

	$self->{__fh}->sysseek($offset, SEEK_SET)
		or die __x("error seeking '{filename}': {error}!\n",
		           filename => $self->{__filename}, error => $!);
	
	my $key;
	my $bytes_read = $self->{__fh}->sysread($key, 8);
	die __x("error reading from '{filename}': {error}!\n",
	        filename => $self->{__filename}, error => $!)
		if $bytes_read <= 0;
	die __x("unexpected end-of-file reading from '{filename}'\n",
	        filename => $self->{__filename}, error => $!)
	    if 8 != $bytes_read;

	return $key;
}

sub _getEntry {
	my ($self, $number) = @_;

	my $offset = $number << 4;

	$self->{__fh}->sysseek($offset, SEEK_SET)
		or die __x("error seeking '{filename}': {error}!\n",
		           filename => $self->{__filename}, error => $!);
	
	my $buf;
	my $bytes_read = $self->{__fh}->sysread($buf, 16);
	die __x("error reading from '{filename}': {error}!\n",
	        filename => $self->{__filename}, error => $!)
		if $bytes_read <= 0;
	die __x("unexpected end-of-file reading from '{filename}'\n",
	        filename => $self->{__filename}, error => $!)
	    if 16 != $bytes_read;

	my $key = substr $buf, 0, 8;
	
	my ($move, $count, $learn) = unpack 'n2N', substr $buf, 8;

	my $to_file = $move & 0x7;
	my $to_rank = ($move >> 3) & 0x7;
	my $from_file = ($move >> 6) & 0x7;
	my $from_rank = ($move >> 9) & 0x7;
	my $promote = ($move >> 12) & 0x7;
	my @promotion_pieces = (
		'', 'k', 'b', 'r', 'q'
	);

	my $move = chr($from_file + ord 'a')
	         . chr($from_rank + ord '1')
	         . chr($to_file + ord 'a')
	         . chr($to_rank + ord '1')
	         . $promotion_pieces[$promote];
	die __x("error: '{filename}' is corrupted\n",
	        filename => $self->{__filename})
		if $move !~ /^[a-h][1-8][a-h][1-8][kbrq]?$/;
	
	return (
		move => $move,
		count => $count,
		learn => $learn,
	);
}

1;
