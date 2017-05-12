#!/usr/bin/perl
# Detect problems relating to conflicts consiting of a single element, and
# various nearby cases.

use strict;
use Algorithm::Diff qw{diff};
use Algorithm::Diff::Apply qw{apply_diffs};
use vars qw{@TESTCASES};

BEGIN
{
	@TESTCASES = (
		{
			base => [qw{foo}],
			rev1 => [qw{bar}],
			rev2 => [qw{baz}],
			expc => [qw{rev1>> bar rev2>> baz <<done}],
		},
		{
			base => [qw{foo x}],
			rev1 => [qw{bar x}],
			rev2 => [qw{baz x}],
			expc => [qw{rev1>> bar rev2>> baz <<done x}],
		},
		{
			base => [qw{a foo x}],
			rev1 => [qw{a bar x}],
			rev2 => [qw{a baz x}],
			expc => [qw{a rev1>> bar rev2>> baz <<done x}],
		},
		{
			base => [qw{a b foo x}],
			rev1 => [qw{a c bar x}],
			rev2 => [qw{a d baz x}],
			expc => [qw{a rev1>> c bar rev2>> d baz <<done x}],
		},
		{
			base => [qw{a b foo x}],
			rev1 => [qw{a bar x}],
			rev2 => [qw{a d baz x}],
			expc => [qw{a rev1>> bar rev2>> d baz <<done x}],
		},
		{
			base => [qw{a b foo x}],
			rev1 => [qw{a c bar x}],
			rev2 => [qw{a baz x}],
			expc => [qw{a rev1>> c bar rev2>> baz <<done x}],
		},
		{
			base => [qw{c d e f g h i}],
			rev1 => [qw{c d e f g bye}],
			rev2 => [qw{c d e f g rehi}],
			expc => [qw{c d e f g rev1>> bye rev2>> rehi <<done}],
		},
	);
}
use Test::Simple tests => scalar @TESTCASES;


sub resolver
{
	my %opt = @_;
	my %alt = %{$opt{alt_txts}};
	my @ret;
	foreach my $id (sort keys %alt)
	{
		push @ret, "${id}>>";
		push @ret, @{$alt{$id}};
	}
	push @ret, "<<done";
	return @ret;
}



foreach my $t (@TESTCASES)
{
	my $d1 = diff($t->{base}, $t->{rev1});
	my $d2 = diff($t->{base}, $t->{rev2});
	my @base = @{$t->{base}};
	my $expc = join(':', @{$t->{expc}});
	my $gen = join(':', apply_diffs(
		\@base, { resolver => \&resolver },
		rev1 => $d1,
		rev2 => $d2,
	));
	ok($gen eq $expc)
	 or warn "\nEXP: '$expc'\nGOT: '$gen'\n\n";
}
