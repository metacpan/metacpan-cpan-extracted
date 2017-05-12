#!/usr/bin/perl -w
use strict;
use Bio::NEXUS;
use Data::Dumper;
use Getopt::Std;

# nexdump is a simple tool for developers working on the NEXPL API.  I found 
# myself frequently wanting to verify the structure or content of NEXUS objects,
# and was annoyed that I always had to write the same few lines of code over 
# and over.  - TH 050913 (Happy Birthday to me)


my %flags;
getopts('d:b:h', \%flags) or die &usage;
die &usage if $flags{h};

$Data::Dumper::Maxdepth = $flags{d} if $flags{d};

my @blocktypes = split /[\s,]+/, $flags{b} if $flags{b};

my @nexusfiles = @ARGV;

die &usage unless @nexusfiles;

for my $file (@nexusfiles) {
    unless (-e $file) {warn "File: <$file> is not a valid filepath\n"; next};
    my $nexus = new Bio::NEXUS($file);
    if ($flags{b}) {
        for my $blocktype (@blocktypes) {
            my $blocks = $nexus->get_blocks($blocktype);
            if (@$blocks) {
                print Dumper $blocks;
            } else {warn "No <$blocktype> blocks found\n";}
        }
    } else {
        print Dumper $nexus;
    }
}


sub usage {

    print STDERR << "EOF";
    
    Usage: nexdump.pl [-h] [-d depth] [-b 'blocks'] file1.nex [file2.nex ...]
    
        -d depth    : sets \$Data::Dumper::Maxdepth
        -b 'blocks' : specifies which blocks are to be dumped
        -h          : displays this usage information

EOF
    exit;
}
