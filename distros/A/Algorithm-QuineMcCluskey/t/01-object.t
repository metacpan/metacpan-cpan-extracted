#!/usr/bin/perl -w
use strict;
use Algorithm::QuineMcCluskey;

#
# Test object creation.
#

use Test::More tests => 6;

my $q = Algorithm::QuineMcCluskey->new(
	title => "Null Test",
	width => 1,
	minterms => [ 1 ]
);

isa_ok($q, "Algorithm::QuineMcCluskey");

$q = Algorithm::QuineMcCluskey->new(
	title => "Columnstring from minterms",
	width => 3,
	minterms => [ 0, 1, 3, 4, 7 ]
);

my $columnstring = $q->columnstring;
ok($columnstring eq "11011001", $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title => "Columnstring from maxterms",
	width => 3,
	maxterms => [ 0, 1, 3, 4, 7 ]
);

$columnstring = $q->columnstring;
ok($columnstring eq "00100110", $q->title);

$q = Algorithm::QuineMcCluskey->new(
	title => "Minterms from columnstring",
	width => 3,
	columnstring => "11011001"
);

my @terms_ref = @{$q->minterms};
is_deeply(\@terms_ref, [0, 1, 3, 4, 7], $q->title);

my $q_comp = $q->complement();
@terms_ref = @{$q_comp->minterms};
is_deeply(\@terms_ref, [2, 5, 6], $q_comp->title);

my $q_dual = $q->dual();
@terms_ref = @{$q_dual->minterms};
is_deeply(\@terms_ref, [1, 2, 5], $q_dual->title);
