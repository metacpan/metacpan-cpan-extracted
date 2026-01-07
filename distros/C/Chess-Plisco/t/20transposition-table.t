#! /usr/bin/env perl

# Copyright (C) 2018 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use integer;

use Test::More;

use Chess::Plisco::Engine::TranspositionTable;
use Chess::Plisco::Engine::Constants;

# Create the default transposition table of 16 MB.
my $tt = Chess::Plisco::Engine::TranspositionTable->new(16);
ok $tt, "create transposition table";

# The entries are organised into clusters. Each cluster has 40 bytes.
my $num_clusters = int(16 * 1024 * 1024 / 40);

is scalar @$tt, $num_clusters, "$num_clusters clusters";

# Retrieve an entry.
my $signature = 0xbea7ab1e_ba5eba11;
my ($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);

ok !$tt_hit, 'hit in empty table';
ok !$tt_depth, 'depth in empty table';
ok !$tt_move, 'move in empty table';
ok !defined $tt_value, 'value in empty table';
ok !defined $tt_eval, 'eval in empty table';
ok !$tt_bound, 'bound in empty table';
ok !$tt_pv, 'PV flag in empty table';

# Store an entry and get the values.
# @write_info, $signature, $value, $pv, $bound, $depth, $move, $eval) = @_;
$tt->store(@write_info, $signature, 314, 1, BOUND_EXACT, 7, 1234 << 6, 278);
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);
ok $tt_hit, 'hit on first entry';
is $tt_depth, 7, 'depth in first entry';
is $tt_bound, BOUND_EXACT, 'bound in first entry';
is $tt_move, 1234 << 6, 'move in first entry';
is $tt_value, 314, 'value in first entry';
is $tt_eval, 278, 'eval in first entry';

# Test that exact entries overwrite lower bound entries.
$tt->clear;
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);
$tt->store(@write_info, $signature, 314, 1, BOUND_LOWER, 7, 1233 << 6, 278);
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);
ok $tt_hit, 'hit on lower bound';
is $tt_move, 1233 << 6, 'lower bound move';
$tt->store(@write_info, $signature, 314, 1, BOUND_EXACT, 7, 1234 << 6, 278);
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);
ok $tt_hit, 'hit on exact bound';
is $tt_move, 1234 << 6, 'exact bound move';

# Test that exact entries overwrite upper bound entries.
$tt->clear;
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);
$tt->store(@write_info, $signature, 314, 1, BOUND_UPPER, 7, 1235 << 6, 278);
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);
ok $tt_hit, 'hit on upper bound';
is $tt_move, 1235 << 6, 'upper bound move';
$tt->store(@write_info, $signature, 314, 1, BOUND_EXACT, 7, 1234 << 6, 278);
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);
ok $tt_hit, 'hit on exact bound';
is $tt_move, 1234 << 6, 'exact bound move';

# Test that entries with another key do not overwrite old ones.
$tt->clear;

# Store first entry with original signature
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
 $tt_pv, @write_info) = $tt->probe($signature);
$tt->store(@write_info, $signature, 314, 1, BOUND_EXACT, 7, 1234 << 6, 278);

# Probe it back to make sure it's there
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
 $tt_pv, @write_info) = $tt->probe($signature);
ok $tt_hit, 'hit on original key';
is $tt_move, 1234 << 6, 'original move stored correctly';

# Now use a new signature with a different key
my $signature2 = $signature + $num_clusters;  # simple way to get different key
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
 $tt_pv, @write_info) = $tt->probe($signature2);
$tt->store(@write_info, $signature2, 555, 0, BOUND_UPPER, 5, 4321 << 6, 999);

# Probe both signatures
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
 $tt_pv, @write_info) = $tt->probe($signature);
ok $tt_hit, 'original key should not be overwritten';

($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
 $tt_pv, @write_info) = $tt->probe($signature2);
ok $tt_hit, 'new key stored';
is $tt_move, 4321 << 6, 'new move stored correctly';

# Fill the cluster with 4 distinct keys
my @signatures = (
	$signature,
	$signature + 1 * $num_clusters,
	$signature + 2 * $num_clusters,
	$signature + 3 * $num_clusters,
);
my @moves = (1001 << 6, 1002 << 6, 1003 << 6, 1004 << 6);

$tt->clear;
for my $i (0 .. 3) {
	my $sig = $signatures[$i];
	my ($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
		$tt_pv, @write_info) = $tt->probe($sig);
	$tt->store(@write_info, $sig, 314, 1, BOUND_EXACT, 7, $moves[$i], 278);
}

# All 4 should be present
for my $i (0..3) {
	my ($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
		$tt_pv, @write_info) = $tt->probe($signatures[$i]);
	ok $tt_hit, "cluster contains signature $i";
	is $tt_move, $moves[$i], "correct move for signature $i";
}

# Now store a 5th distinct entry, forcing a replacement
my $sig5 = $signature + 4 * $num_clusters;
my $move5 = 9999 << 6;
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
    $tt_pv, @write_info) = $tt->probe($sig5);
$tt->store(@write_info, $sig5, 314, 1, BOUND_EXACT, 7, $move5, 278);

# Probe all 5 signatures: one of the old ones must have been replaced
my $found_count = 0;
for my $i (0 .. 4) {
	my ($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
		$tt_pv, @write_info) = $tt->probe($i < 4 ? $signatures[$i] : $sig5);
	$found_count++ if $tt_hit;
}
is $found_count, 4, 'cluster still contains 4 entries after replacement';

# Ensure the new move is stored
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
 $tt_pv, @write_info) = $tt->probe($sig5);
ok $tt_hit, 'new signature stored';
is $tt_move, $move5, 'new move stored correctly';

# Check that a new generation overwrites older ones.
$tt->clear;
for my $i (0 .. 3) {
	my $sig = $signatures[$i];
	my ($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
		$tt_pv, @write_info) = $tt->probe($sig);
	$tt->store(@write_info, $sig, 314, 1, BOUND_EXACT, 100, $moves[$i], 278);
}

# Force next generation.
$tt->newSearch;

my @new_moves = (10000 << 6, 10001 << 6, 10002 << 6, 10003 << 6);
for my $i (0 .. 3) {
	my $sig = $signatures[$i];
	my ($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
		$tt_pv, @write_info) = $tt->probe($sig);
	# Store them with with a non-exact bound type at a much lower depth.
	$tt->store(@write_info, $sig, 314, 1, BOUND_UPPER, 3, $new_moves[$i], 278);
}

# Now check that we have new moves only.
for my $i (0 .. 3) {
	my ($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
		$tt_pv, @write_info) = $tt->probe($signatures[$i]);
	ok $tt_hit, "next generation tt hit $i";
	is $tt_move, $new_moves[$i], "overwritten move $i";
}

# In this position, the from field of the move was discarded.
$signature = 0x25B6869AFC33400E;
my $move = 870400;
($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);

ok !$tt_hit, 'no initial hit for bug position';

$tt->store(@write_info, $signature, 14996, 0, 2, 3, $move);

($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
	$tt_pv, @write_info) = $tt->probe($signature);
ok $tt_hit, 'hit for bug position';
is $tt_depth, 3, 'depth for bug position';
is $tt_bound, 2, 'bound for bug position';
is $tt_move, $move, 'move for bug position';
is $tt_value, 14996, 'value for bug position';
is $tt_eval, 0, 'evaluation for bug position';
is $tt_pv, 0, 'pv flag for bug position';

$tt->clear;

foreach my $signature (1 .. 42 * 4) {
	($tt_hit, $tt_depth, $tt_bound, $tt_move, $tt_value, $tt_eval,
		$tt_pv, @write_info) = $tt->probe($signature);
	$tt->store(@write_info, $signature, 14996, 0, 2, 3, 64);
}
is $tt->hashfull, 42, 'hashfull';

done_testing;
