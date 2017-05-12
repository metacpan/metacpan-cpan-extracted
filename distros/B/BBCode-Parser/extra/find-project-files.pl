#!/usr/bin/perl
use warnings;
use strict;

use Fcntl qw(:flock);

open(MF, '<', 'MANIFEST') or die qq(Failed to open "MANIFEST" for reading: $!);
flock(MF, LOCK_SH);
while(<MF>) {
	chomp;
	s/\t.*$//;
	while(1) {
		if(-f $_) {
			print "$_\n";
			last;
		}
		s/\s+\S*$// or last;
	}
}
close(MF);

