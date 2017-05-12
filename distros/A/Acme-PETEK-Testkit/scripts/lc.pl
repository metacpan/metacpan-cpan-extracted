#!/usr/bin/perl -w

use strict;
use Acme::PETEK::Testkit;

my $c = Acme::PETEK::Testkit->new;

my $pattern = shift @ARGV;
if ($pattern eq '-v') {
	print "lc.pl version 0.01";
	exit;
}

while(!$pattern) {
	print 'Pattern> ';
	chomp($pattern = <STDIN>);
}

print '> ';
while(defined(my $line = <>)) {
	$c->incr if $line =~ qr/\Q$pattern\E/;
	last if $line eq ".\n";
	print 'Matches: ', $c->value, "\n" if $line eq "?\n";
	print '> ';
}

print 'Matches: ', $c->value, "\n";

exit(0);
