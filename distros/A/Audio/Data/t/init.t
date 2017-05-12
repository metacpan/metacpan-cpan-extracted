#!/usr/local/bin/perl -w
use strict;
use Audio::Data;

print "1..6\n";

my $au = new Audio::Data;
print "not " unless defined $au;
print "ok 1\n";
$au->data(1,2,3,4);
my @data = $au->data;
print "not " unless (@data == 4);
print "ok 2\n";
print "not " unless ("@data" eq "1 2 3 4");
print "ok 3\n";
$au->data(19,23);
@data = $au->data;
print "not " unless ("@data" eq "19 23");
print "ok 4\n";
my $c = ~$au;
@data = $c->data;
print "#@data\nnot " unless (@data == 4);
print "ok 5\n";
print "not " unless ($data[0] == 19 && $data[1] == 0 &&
                     $data[2] == 23 && $data[3] == 0);
print "ok 6\n";

# $au->complex_debug(\*STDERR);

