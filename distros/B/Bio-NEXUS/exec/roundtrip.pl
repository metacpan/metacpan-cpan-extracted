#! /usr/bin/perl -w

# two kinds of behavior depending on how its called: 
#
#   1.  If passed a file name, it does the read/write/re-read/compare test. 
#   2.  If not, it does a read test on all *.nex files in the working directory. 
#

use strict;
use Bio::NEXUS;

my $file = shift @ARGV;
if ($file) {
    print "read $file, write, read again, compare object with original\n";
    my $nexus = new Bio::NEXUS($file, 0);
    $nexus->write("temp.nex");
    my $newnexus = new Bio::NEXUS("temp.nex");
    if ($nexus->equals($newnexus)) {print "===> content of re-written file is same\n";}
    else {print "==> ERROR, content of re-written file is not the same\n";}
    exit;
}
else { 
    print "read (only) all *.nex files in this directory\n"; 
    opendir(DIR, '.');
    my @files = readdir DIR;
    closedir DIR;
    
    foreach my $file (@files) {
	if ($file =~ /.+\.nex$/) {
	    print "read $file ...\n";
	    my $nexus = new Bio::NEXUS($file);
	    print " file is read without error\n"
	    }
    }
}
