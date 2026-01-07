#! /bin/false

# Copyright (C) 2021-2026 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Rename that back to TranspositionTable, once done.
package Chess::Plisco::Engine::TranspositionTable;
$Chess::Plisco::Engine::TranspositionTable::VERSION = 'v1.0.2';
use strict;
use integer;

# Macros from Chess::Plisco::Macro are already expanded here!
use Chess::Plisco::Engine::Constants;

# The transposition table is organised into clusters, which in turn contain
# 4 buckets.
use constant CLUSTER_CAPACITY => 4;

# We store the keys separately from the actual entries, because that is easier
# to scan. The layout of a cluster is then like this:

# key0       16 bit
# key1       16 bit
# key2       16 bit
# key3       16 bit
# depth       8 bit start of bucket 0
# generation  5 bit
# pv node     1 bit
# bound type  2 bit
# move       16 bit
# value      16 bit
# evaluation 16 bit end of bucket 0
# bucket1    64 bit 
# bucket2    64 bit 
# bucket3    64 bit 

use constant KEY_BYTES => 2;
use constant BUCKET_BYTES => 8;

use constant TT_ENTRY_SIZE => 16;

use constant GENERATION_BITS => 3;
use constant GENERATION_DELTA => (1 << (GENERATION_BITS));
use constant GENERATION_CYCLE => 255 + GENERATION_DELTA;
use constant GENERATION_MASK => (0xFF << (GENERATION_BITS)) & 0xFF;

my $generation = 0;

# FIXME! Inline this!
my $relative_age = sub {
	return (GENERATION_CYCLE + $generation - $_[0]) & GENERATION_MASK;
};


sub new {
	my ($class, $size) = @_;

	# Reading array entries is almost 50 % faster than access strings with
	# substr.
	my $self = [];
	bless $self, $class;

	return $self->resize($size);
}

sub clear {
	my ($self) = @_;

	my $cluster_bytes = CLUSTER_CAPACITY * (KEY_BYTES + BUCKET_BYTES);

	$self->[$_] = "\0" x $cluster_bytes for 0 .. $#$self;

	return $self;
}

sub resize {
	my ($self, $size) = @_;

	my $cluster_bytes = CLUSTER_CAPACITY * (KEY_BYTES + BUCKET_BYTES);

	$#$self = 0;
	# Perl possibly rounds the size up. Therefore the int.
	$#$self = int($size * 1024 * 1024 / $cluster_bytes) - 1;

	$self->clear;

	$generation = 0;

	return $self;
}

sub newSearch {
	$generation += GENERATION_DELTA;
}

sub probe {
	my ($self, $signature) = @_;

	# Throw away the sign bit, because we cannot use negative indices.
	my $cluster_index = ($signature & 0x7fff_ffff_ffff_ffff) % scalar @$self;
	my $cluster = $self->[$cluster_index];
	
	# Use the lower 16 bits.
	my $key16 = $signature & 0xffff;

	my @keys = unpack 'S4', $cluster;
	for (my $i = 0; $i < @keys; ++$i) {
		if ($keys[$i] == $key16) {
			my $bucket = substr $cluster, 8 + $i * BUCKET_BYTES, BUCKET_BYTES;
			# The list now contains the depth, move, value, evaluation, and
			# encoded bitfield.
			my @bucket = (0, unpack 'CCSss', $bucket);
			my $occupied = $bucket[1] or next;
			$bucket[0] = $occupied && 1; # The occupied flag.
			$bucket[1] += DEPTH_ENTRY_OFFSET; # The actual depth.
			my $bitfield = $bucket[2];
			$bucket[2] &= 3; # Now contains the bound type.
			$bucket[3] = (($bucket[3]) << 6);
			push @bucket, $bitfield & 4, $cluster_index, $i, $bucket;

			return @bucket;
		}
	}

	# Nothing found. Find a bucket to replace.
	my ($depth, $generation) = unpack 'CC', substr $cluster, 8;
	my $bucket_index = 0;
	my $best = $depth - 8 * $relative_age->($generation);
	for (my $i = 1; $i < @keys; ++$i) {
		my $offset = 8 + $i * BUCKET_BYTES;
		my $repl_bucket = substr $cluster, $offset, BUCKET_BYTES;
		my ($repl_depth, $repl_generation) = unpack 'CC', $repl_bucket;
		if ($repl_depth - 8 * $relative_age->($repl_generation) < $best) {
			$depth = $repl_depth;
			$generation = $repl_generation;
			$bucket_index = $i;
		}
	}

	my $bucket = substr $cluster, 8 + $bucket_index * BUCKET_BYTES, BUCKET_BYTES;

	return 0, 0, 0, 0, undef, undef, 0, $cluster_index, $bucket_index, $bucket;
}

sub store {
	my ($self, $cluster_index, $bucket_index, $bucket, $signature, $value,
		$pv, $bound, $depth, $move, $eval) = @_;

	$pv = !!$pv;
	$generation &= GENERATION_MASK;

	my $k = $signature & 0xffff;

	# Unpacking just one value is almost two times faster than unpacking all
	# four keys and picking the right one.
	my $key = unpack 'S', substr $self->[$cluster_index], $bucket_index << 1, 2;

	# Preserve the old move.
	if (!$move && $key == $k) {
		$move = ((unpack 'S') << 6);
	}

	# Overwrite old entry?
	my $stored_depth;
	if ($bound == BOUND_EXACT || $key != $k
		|| ($stored_depth = unpack('C', substr $bucket, 0, 1) || 0) # Always false, forces stored_depth to be defined.
		|| $depth - DEPTH_ENTRY_OFFSET + ($pv << 1) > $stored_depth - 4
		|| $relative_age->($stored_depth) & GENERATION_MASK) {
		# Overwrite!
		substr($self->[$cluster_index], $bucket_index << 1, 2) = pack 'S', $k; # Key.
		substr($self->[$cluster_index], 8 + ($bucket_index << 3), BUCKET_BYTES) =
			pack('CCSss',
				$depth - DEPTH_ENTRY_OFFSET, # Depth.
				$generation | ($pv << 2) | $bound, # GenBound8.
				((($move) & 0x1fffc0) >> 6),
				$value,
				$eval,
			);
	}
}

sub hashfull {
	my ($self, $max_age) = @_;

	my $max_age_internal = $max_age << (GENERATION_BITS);
	my $cnt = 0;

	my $limit = @$self < 1000 ? @$self : 1000;

	for my $ci (0 .. $limit - 1) {
		my @c = unpack 'C40', $self->[$ci];

		for my $bi (0 .. CLUSTER_CAPACITY - 1) {
			my $k_lo = $c[$bi * 2];
			my $k_hi = $c[$bi * 2 + 1];
			next if ($k_lo | $k_hi) == 0;   # empty

			my $base = 8 + ($bi << 3);
			my $gen  = $c[$base + 1];

			my $age =
				(GENERATION_CYCLE + $generation - $gen)
				& GENERATION_MASK;

			$cnt++ if $age <= $max_age_internal;
		}
	}

	return int($cnt / CLUSTER_CAPACITY);
}

1;
