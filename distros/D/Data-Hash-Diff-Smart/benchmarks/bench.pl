#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark qw(cmpthese);
use Data::Compare;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Hash::Diff::Smart qw(diff);

my @cases = qw(
	small
	medium
	large
	cycles
	unordered
	lcs
);

for my $case (@cases) {
	my $file = "$Bin/$case.pl";
	my ($old, $new, %opts) = do $file or die "Failed to load $file: $@ $!";

	print "\n=== Benchmark: $case ===\n";

	cmpthese(-1, {
		smart => sub { diff($old, $new) },
		# hashdiff => sub { Hash::Diff::diff($old, $new) },
		datacmp => sub { Data::Compare::Compare($old, $new) },
	});
}
