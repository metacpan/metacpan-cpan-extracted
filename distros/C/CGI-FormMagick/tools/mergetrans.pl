#!/usr/bin/perl -w
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

open (A, $ARGV[0]) or die "Couldn't open $ARGV[0]: $!";
open (B, $ARGV[1]) or die "Couldn't open $ARGV[1]: $!";

while (my $a = <A> and my $b = <B>) {
	print "$a$b\n";
}
