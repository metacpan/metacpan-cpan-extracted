#!/usr/bin/env perl

# Hold each module to the mutation score it has reached.  The scheduled
# mutation workflow commits its results to mutation.json; the next CI run
# reads them here, and fails when a module has slipped below its floor, or
# when mutants were dropped because they would not compile (App::Test::
# Generator 0.51 and later report those as compile_skipped: such a run
# reports a score for code it never tested).
#
# mutation.json is not in the distribution, so this skips outside a checkout.
# The workflow files are shared by every repo and overwritten from there, so
# the floors live here rather than in a workflow step.

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use JSON::MaybeXS ();
use Test::Most;

my $results_file = File::Spec->catfile($Bin, File::Spec->updir, 'mutation.json');
plan skip_all => 'no mutation.json (it is written by CI, and not shipped)' unless -f $results_file;

# The lowest score (percent of mutants killed) each module may report.  Raise
# a floor when its module's score rises, so the score cannot slip back.
#	Merge:    every mutant is killed.
#	Delta:    one survivor is equivalent ("return undef" for a bare return).
#	Platform: the two survivors are its return value, which nothing reads.
#	Server:   about 80 survivors negate a return value nothing reads (see the
#	          TODO in lib/App/FileSync.pm).  40 is an estimate: CI has not yet
#	          mutated Server (see below), so set it from the first real run.
# A module with no floor is reported but never fails.
#
# Up to App::Test::Generator 0.50 the compile check before each mutant runs
# without lib/, so in CI every module that loads another App::FileSync module
# is dropped whole, and only Platform.pm appears.  0.51 fixes that.
my %FLOOR = (
	'lib/App/FileSync/Merge.pm'    => 100,
	'lib/App/FileSync/Delta.pm'    => 95,
	'lib/App/FileSync/Platform.pm' => 80,
	'lib/App/FileSync/Server.pm'   => 40,
);

my $results = do {
	open my $fh, '<:raw', $results_file or die "$results_file: $!";
	local $/;
	JSON::MaybeXS->new->decode(<$fh>);
};

my (%killed, %survived);
$killed{ $_->{file} }++ for @{ $results->{killed} || [] };
$survived{ $_->{file} }++ for @{ $results->{survived} || [] };

my @files = sort { $a cmp $b } keys %{ { %killed, %survived } };
ok(scalar @files, 'mutation.json holds results for at least one module');

for my $file (@files) {
	my $killed = $killed{$file} || 0;
	my $total  = $killed + ($survived{$file} || 0);
	my $score  = 100 * $killed / $total;
	my $floor  = $FLOOR{$file};
	if (defined $floor) {
		cmp_ok($score, '>=', $floor, sprintf('%s: %d of %d killed (%.2f%%), floor %d%%', $file, $killed, $total, $score, $floor));
	} else {
		note(sprintf('%s: %d of %d killed (%.2f%%), no floor', $file, $killed, $total, $score));
	}
}

my $compile_skipped = $results->{compile_skipped} || {};
for my $file (sort { $a cmp $b } keys %{$compile_skipped}) {
	is($compile_skipped->{$file}, 0, "$file: no mutant was skipped for not compiling");
}

done_testing();
