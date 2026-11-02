#!/usr/bin/perl

# End-to-end tests for Database::Join when the component databases are backed
# by remote files via File::Slurp::Remote.  Section 2 specifically tests that
# the user@host form ("njh@myhost") is passed through unmodified to
# read_remote_file, matching the behaviour verified in Database::Abstraction
# t/remote.t Section 6.
#
# No real SSH connection is made.  File::Slurp::Remote::read_remote_file is
# replaced with a stub that returns in-memory fixture data.
#
#   djremote_a (primary):   entry | name  | tier
#       one     Alice   gold
#       two     Bob     silver
#       three   Carol   bronze   <- primary-only key
#
#   djremote_b (secondary): entry | score
#       one     95
#       two     72
#       four    88               <- secondary-only key

use strict;
use warnings;

use Test::Most;
use Test::Needs 'File::Slurp::Remote';

BEGIN {
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
}

BEGIN {
	package Database::djremote_a;
	use base 'Database::Abstraction';
}

BEGIN {
	package Database::djremote_b;
	use base 'Database::Abstraction';
}

use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Fixture data keyed by "$host:$path"
# ---------------------------------------------------------------------------

my %FIXTURE = (
	'myhost:/data/djremote_a.csv' =>
		"entry!name!tier\none!Alice!gold\ntwo!Bob!silver\nthree!Carol!bronze\n",
	'myhost:/data/djremote_b.csv' =>
		"entry!score\none!95\ntwo!72\nfour!88\n",
	'njh@myhost:/data/djremote_a.csv' =>
		"entry!name!tier\none!Alice!gold\ntwo!Bob!silver\nthree!Carol!bronze\n",
	'njh@myhost:/data/djremote_b.csv' =>
		"entry!score\none!95\ntwo!72\nfour!88\n",
);

{
	no warnings 'redefine';
	*File::Slurp::Remote::read_remote_file = sub {
		my ($host, $file) = @_;
		my $key = "$host:$file";
		die "remote: no fixture for $key\n" unless exists $FIXTURE{$key};
		return $FIXTURE{$key};
	};
}

# ===========================================================================
# S1: Plain host -- two remote-backed DAs joined
# ===========================================================================

subtest 'plain host: left join of two remote-backed DAs' => sub {
	my $da_a = Database::djremote_a->new(
		host	  => 'myhost',
		directory => '/data',
	);
	my $da_b = Database::djremote_b->new(
		host	  => 'myhost',
		directory => '/data',
	);

	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	my $rows = $join->selectall_arrayref();
	is(scalar @{$rows}, 3, 'left join: 3 rows (primary defines key set)');

	my %by_key = map { $_->{entry} => $_ } @{$rows};
	ok( exists $by_key{one},   'key "one" present (in both)');
	ok( exists $by_key{two},   'key "two" present (in both)');
	ok( exists $by_key{three}, 'key "three" present (primary-only)');
	ok(!exists $by_key{four},  'key "four" absent (secondary-only)');

	is($by_key{one}{name},  'Alice', 'row one name from primary');
	is($by_key{one}{score}, 95,	  'row one score from secondary');
	ok(!defined $by_key{three}{score}, 'row three score undef (no secondary row)');

	is($join->count(), 3, 'count() returns 3');
};

# ===========================================================================
# S2: user@host -- username is passed through to File::Slurp::Remote
# ===========================================================================

subtest 'user@host: left join with user@host form on both DAs' => sub {
	my $da_a = Database::djremote_a->new(
		host	  => 'njh@myhost',
		directory => '/data',
	);
	my $da_b = Database::djremote_b->new(
		host	  => 'njh@myhost',
		directory => '/data',
	);

	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	my $rows = $join->selectall_arrayref();
	is(scalar @{$rows}, 3, 'user@host: left join returns 3 rows');

	my %by_key = map { $_->{entry} => $_ } @{$rows};
	is($by_key{one}{name},   'Alice', 'user@host: row one name correct');
	is($by_key{one}{score},  95,	  'user@host: row one score correct');
	is($by_key{two}{name},   'Bob',   'user@host: row two name correct');
	is($by_key{two}{score},  72,	  'user@host: row two score correct');
	ok(!defined $by_key{three}{score}, 'user@host: row three score undef (primary-only)');
};

# ===========================================================================
# S3: user@host -- inner join
# ===========================================================================

subtest 'user@host: inner join returns only keys present in both' => sub {
	my $da_a = Database::djremote_a->new(
		host	  => 'njh@myhost',
		directory => '/data',
	);
	my $da_b = Database::djremote_b->new(
		host	  => 'njh@myhost',
		directory => '/data',
	);

	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
		join_type   => 'inner',
	);

	my $rows = $join->selectall_arrayref();
	is(scalar @{$rows}, 2, 'user@host inner join: 2 rows (one and two)');

	my %by_key = map { $_->{entry} => $_ } @{$rows};
	ok( exists $by_key{one},   'key "one" present');
	ok( exists $by_key{two},   'key "two" present');
	ok(!exists $by_key{three}, 'key "three" absent (not in secondary)');
	ok(!exists $by_key{four},  'key "four" absent (not in primary)');

	is($join->count(), 2, 'count() agrees with inner join row count');
};

# ===========================================================================
# S4: user@host -- fetchrow_hashref, count, and criteria routing
# ===========================================================================

subtest 'user@host: fetchrow_hashref, count, and criteria routing' => sub {
	my $da_a = Database::djremote_a->new(
		host	  => 'njh@myhost',
		directory => '/data',
	);
	my $da_b = Database::djremote_b->new(
		host	  => 'njh@myhost',
		directory => '/data',
	);

	my $join = Database::Join->new(
		databases   => [$da_a, $da_b],
		join_column => 'entry',
	);

	my $row = $join->fetchrow_hashref(entry => 'two');
	ok(defined $row,  'fetchrow_hashref returns a row for entry "two"');
	is($row->{name},  'Bob',  'fetchrow_hashref: name correct');
	is($row->{score}, 72,	 'fetchrow_hashref: score correct');
	is($row->{tier},  'silver', 'fetchrow_hashref: tier correct');

	is($join->count(),  3, 'count() returns 3');
	is($join->count(tier => 'gold'), 1, 'count(tier=>gold) returns 1 (criteria routed to primary)');

	my $gold_rows = $join->selectall_arrayref(tier => 'gold');
	is(scalar @{$gold_rows}, 1,   'selectall_arrayref(tier=>gold): 1 row');
	is($gold_rows->[0]{name}, 'Alice', 'gold row name is Alice');
	is($gold_rows->[0]{score}, 95,	 'gold row score from secondary');
};

done_testing();
