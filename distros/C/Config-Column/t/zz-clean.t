use utf8;
use strict;
use warnings;
use Test::More tests => 1;
use FindBin '$Bin';

opendir my $dh,"$Bin";
my @files = readdir $dh;
closedir $dh;
for(@files){
	unlink $Bin.'/'.$_ if /html$|dat$/;
}

pass();
