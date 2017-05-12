#!/usr/bin/perl
#
# version 1.01 1-18-01 Michael Robinton, BizSystems michael@bizsystems.com
# Copyright, all rights reserved
#
# input:	ModuleSrc
#
use AutoSplit;

my($mod) = @ARGV;

my $pod;
($pod = $mod) =~ s/\.pm/\.PM/;
$pod =~ s/\.PM/\.pod/;

die "no source file" unless $mod && open(S,$mod);

system "./mod_parser.pl $mod $mod.nopod save > $pod";
