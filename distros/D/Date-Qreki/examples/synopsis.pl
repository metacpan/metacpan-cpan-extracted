#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Date::Qreki ':all';
my @qreki = calc_kyureki (2017, 1, 31);
print "Old calendar $qreki[0] $qreki[2] $qreki[3]\n";

