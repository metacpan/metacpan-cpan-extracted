#!/usr/bin/env perl
use strict;
use Crypt::Pwsafe;

my $file = shift;
die "File not found.\n" unless $file && -f $file;
my $comb = Crypt::Pwsafe::enter_combination();
my $pwsafe = new Crypt::Pwsafe $file, $comb;
foreach my $group (keys %$pwsafe) {
	print "$group\n";
	my $gh = $pwsafe->{$group};
	foreach my $entry (keys %$gh) {
		print "    $entry\n";
		my $eh = $gh->{$entry};
		foreach my $field (keys %$eh) {
			print "        $field=$eh->{$field}\n";
		}
	}
}
