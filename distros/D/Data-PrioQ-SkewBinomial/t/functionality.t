#!perl
use warnings;
use strict;

use Test::More tests => do {
	# hax
	my $self = __FILE__;
	open my $fh, '<', $self or die "Can't open $self: $!";
	my $tests = 0;
	my @scale = 1;
	while (my $line = <$fh>) {
		if ($line =~ /\Q((\E\s*(\d+)\s*\Q))\E/) {
			push @scale, $scale[-1] * $1;
		} elsif ($line =~ /#\s*\Q))((\E/) {
			pop @scale;
		} else {
			$tests += $scale[-1] * $line =~ /^\s*(?:ok|is_deeply|is)\b/;
		}
	}
	$tests
};

use Data::PrioQ::SkewBinomial;

sub queue2list {
	my ($pq) = @_;
	my @r;
	until ($pq->is_empty) {
		($pq, my ($k, $v)) = $pq->shift_min;
		push @r, [$k, $v];
	}
	\@r
}

sub list2queue {
	my $q = Data::PrioQ::SkewBinomial->empty;
	for my $pair (@_) {
		$q = $q->insert(@$pair);
	}
	$q
}

sub regroup {
	my (@data) = @_;
	my @r;
	while (@data) {
		my $x = shift @data;
		my ($k, @v) = @$x;
		while (@data && $data[0][0] == $k) {
			push @v, shift(@data)->[1];
		}
		push @r, sort @v;
	}
	@r
}

sub group_sort {
	regroup sort {$a->[0] <=> $b->[0]} @_
}

my $e = Data::PrioQ::SkewBinomial->empty;
ok $e->is_empty, "empty queue is empty";

{
	my ($k, $v) = (0, "xxx");
	my $pq0 = $e->insert($k, $v);
	my ($e2, $k2, $v2) = $pq0->shift_min;
	ok $e2->is_empty;
	is $k, $k2;
	is $v, $v2;
	is_deeply [$pq0->peek_min], [$k, $v];
}

for my $j (1 .. ((3))) {
	my @data = map [int rand(200) - 50, $_], 1 .. 2 + int rand 1000;
	my $pq1 = list2queue @data;

	ok $e->is_empty, "empty queue is still empty";
	ok !$pq1->is_empty, "new queue is nonempty";

	{
		my ($pq2, @val) = $pq1->shift_min;
		ok $e->is_empty;
		ok !$pq1->is_empty;
		ok !$pq2->is_empty;
	}

	is_deeply [regroup @{queue2list $pq1}], [group_sort @data];

	my @data2 = map [int rand(200) - 50, $_], 1 .. int rand 1000;
	my $pq2 = list2queue @data2;
	is_deeply [regroup @{queue2list $pq2}], [group_sort @data2];
	
	my $pq3 = $pq1->merge($pq2);
	my $pq4 = $pq2->merge($pq1);
	is_deeply [regroup @{queue2list $pq1}], [group_sort @data];
	is_deeply [regroup @{queue2list $pq2}], [group_sort @data2];
	is_deeply [regroup @{queue2list $pq3}], [group_sort @data, @data2];
	is_deeply [regroup @{queue2list $pq4}], [group_sort @data, @data2];
} # ))((
