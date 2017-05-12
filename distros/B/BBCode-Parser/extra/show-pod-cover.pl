#!/usr/bin/perl
use warnings;
use strict;
use aliased 'Pod::Coverage::CountParents' => 'PC';
use Test::Pod::Coverage ();
use lib 'lib';

@ARGV = sort(Test::Pod::Coverage::all_modules()) if @ARGV == 0;

foreach my $mod (@ARGV) {
	print "$mod\n";
	my $pc = PC->new(package => $mod);
	if(defined(my $cover = $pc->coverage)) {
		printf "\tCoverage: %.1f%%\n", $cover * 100;
		if($cover < 1) {
			print "\tNaked:\n";
			foreach my $func (sort $pc->naked) {
				print "\t\t$func\n";
			}
		}
	} else {
		print "\tNo coverage available: ", $pc->why_unrated, "\n";
	}
}
