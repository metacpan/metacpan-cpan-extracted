#!/usr/bin/perl

use strict;
use FindBin '$Bin';

use lib "$Bin/../lib","$Bin/../blib/arch";
use Bio::DB::BigWigSet;
use Carp 'croak';

my $dir = shift or die <<USAGE;
Usage: index_bigwigset.pl \$directory_path

Searches the indicated directory for all BigWig files with the
extension .bw and creates a skeleton metadata.index file that
you can use as a starting point for entering metadata about the
collection.
USAGE

my $count = Bio::DB::BigWigSet->index_dir($dir);
print STDERR "(Re)indexed $count BigWig files\n";

exit 0;

