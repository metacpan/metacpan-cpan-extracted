#!/Users/metaperl/install/bin/perl

use strict;

my $file = shift or die 'must supply file';
my $a = 'annotateh';
my $bitmaps = '/Users/metaperl/wares/bitmaps';
my $icc_handle = '(princepawn|metaperl)';

my $C='((w)hite|(b)lack)';
open F, $file;

my ($c) = grep /$C\s+"$icc_handle"/i, <F>;

my @match = $c =~ /$C/i;

my $color = lc (defined $match[1] ? $match[1] : $match[2]) ;

#annotateh <gamefile> bw 1-99 -1 1 -5

my @cmd = ('annotate', "../$file", $color, qw(1-999 0.75 30));
#my @cmd = ('annotateh', "../$file", 'bw', qw(1-99 -1 -5));

my $cmd = "mkdir $a; cd $a; echo '@cmd' | crafty";

system $cmd;

#symlink $bitmaps, 'bitmaps';

rename $file, "$file.pgn";
