#!/usr/local/bin/perl -w
use strict;
use Audio::Data;
use IO::File;

print "1..2\n";

my $fh = IO::File->new("<t/test.au") or die "Cannot open test.au:$!";
binmode($fh);
my $au = new Audio::Data;
$au->Load($fh);
$fh->close;

my $rate = $au->rate;
print "Rate is $rate\n";
print "not " unless($rate == 9600);
print "ok 1\n";

my $samp = $au->samples;
print "$samp samples\n";
print "not " unless($samp == 4992);
print "ok 2\n";

my $dur = $au->duration;
print "Duration $dur\n";

