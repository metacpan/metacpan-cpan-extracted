#!/usr/bin/perl

use strict;
use FindBin '$Bin';
use lib "$Bin/lib","$Bin/blib/lib","$Bin/blib/arch";

use Bio::DB::BigFile;
@ARGV == 3 or die <<USAGE;
Usage: $0 in.wig chrom.sizes out.bw
Where in.wig is in one of the ascii wiggle formats, but not including track lines
and chrom.sizes is two column: <chromosome name> <size in bases>
and out.bw is the output indexed big wig file.
USAGE

    Bio::DB::BigFile->createBigWig(@ARGV);

1;

