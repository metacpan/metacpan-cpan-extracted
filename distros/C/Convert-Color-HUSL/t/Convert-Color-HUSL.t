#!/usr/bin/perl
use 5.008009;
use strict;
use warnings;

use Convert::Color::RGB8;
use Test::More tests => 7 * ($ENV{RELEASE_TESTING} ? 4096 : 512);

use constant EPSILON => $ENV{RELEASE_TESTING} ? 1e-11 : 2e-4;
my @spaces = qw/XYZ LUV LCh HUSL HUSLp/;

sub isf {
	my ($xx, $yy, $name) = @_;
	for (0 .. 2) {
		my ($x, $y) = ($xx->[$_], $yy->[$_]);
		do { diag "$x != $y"; return fail $name } if abs ($x - $y) > EPSILON;
	}
	pass $name;
}

my @tests;

if ($ENV{RELEASE_TESTING}) {
	require JSON::MaybeXS;
	open my $fh, '<', 't/snapshot-rev4.json';
	my $snapshot = join '', <$fh>;

	my %tests = %{JSON::MaybeXS::decode_json $snapshot};
	@tests = map { [$_, $tests{$_}] } sort keys %tests;
} else {
	open my $fh, '<', 't/snapshot-rev4.csv';
	<$fh>;

	while (<$fh>) {
		my ($color, @good) = split ',';
		my %test;
		$test{rgb} = [Convert::Color::RGB8->new($color)->rgb];
		$test{lc $spaces[$_]} = [@good[$_ * 3 .. $_ * 3 + 2]] for 0 .. $#spaces;
		push @tests, ["#$color", \%test]
	}
}

for my $test (@tests) {
	my ($color, $data) = @$test;
	my $col = Convert::Color::RGB8->new(substr $color, 1);
	isf $col->convert_to(lc), $data->{lc()}, "convert $color to $_" for @spaces;
	isf [$col->convert_to(lc)->rgb], $data->{rgb}, "convert $color to $_ and back" for qw/HUSL HUSLp/;
}
