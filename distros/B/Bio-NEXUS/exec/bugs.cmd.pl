#!/usr/bin/perl -w
# Write BUGS scripts for reconstruction
# Tree has to be bifurcating
# Author:  
# $Date: 2006/08/24 06:41:57 $
# $Revision: 1.3 $

use Data::Dumper;
use Bio::NEXUS;

die "bugs-m.pl <model name> <update1> <update2>\n" unless @ARGV >= 1;
my $model = shift;
my $update1 = shift || 100;
my $update2 = shift || 200;

###############################
#  ".cmd" file
###############################
open (OUT, ">$model.cmd");
print OUT "compile(\"$model\.bug\")\n";
print OUT "update($update1)\n";
print OUT "monitor(alpha)\n";
print OUT "monitor(beta)\n";
print OUT "monitor(r)\n";
print OUT "monitor(k)\n";
print OUT "monitor(llike)\n";
print OUT "monitor(root)\n";
print OUT "monitor(node)\n";
#print OUT "monitor(node[,14])\n";
#print OUT "monitor(node[,28])\n";
#print OUT "monitor(node[,31])\n";
#print OUT "monitor(node[,39])\n";
print OUT "update($update2)\n";
print OUT "stats(alpha)\n";
print OUT "stats(beta)\n";
print OUT "stats(r)\n";
print OUT "stats(k)\n";
print OUT "stats(llike)\n";
print OUT "stats(root)\n";
print OUT "stats(node)\n";
#print OUT "stats(node[,14])\n";
#print OUT "stats(node[,28])\n";
#print OUT "stats(node[,31])\n";
#print OUT "stats(node[,39])\n";
print OUT "q()\n";
close (OUT);

