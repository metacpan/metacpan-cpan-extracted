#!/usr/bin/env perl
#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

=pod

=head1 Description

This script calculates an annotated jalview track. the exon-boundaries are marked by e\d\d within the track.
Input are exon/intron boundaries from the gene. introns are split out and only exons are considered and converted to fit the protein data (div by 3).

=cut
use warnings;
use strict;
use Carp;

use feature ':5.10';

use Bio::SeqIO;
use Bio::Perl;
use Perl6::Slurp;
use Bio::Gonzales::Util::Tools::Jalview;
use List::Util qw/sum/;

my ( $fastafile, $trackfile) = @ARGV;
#die "$fastafile is no file" unless(-f $fastafile);
#die "$trackfile is no file" unless(-f $trackfile);


# mit 2 starten, da 2/3 > 0.5, und somit die annotation bei 1 und nicht bei 0 anfängt (jalview startet bei 1)
my @t = qw/
exon  	  	2-216  	  	 	  	 	 
intron 	  	217-485 	  		  		 
exon 	  	486-639 	  		  		 
intron 	  	640-775 	  		  		 
exon 	  	776-879 	  		  		 
intron 	  	880-979 	  		  		 
exon 	  	980-1168 	  		  		 
intron 	  	1169-1432 	  		  		 
exon 	  	1433-1633 	  		  		 
intron 	  	1634-1748 	  		  		 
exon 	  	1749-2144 	  		  		 
intron 	  	2145-2248 	  		  		 
exon 	  	2249-2508 	  		  		 
intron 	  	2509-2599 	  		  		 
exon 	  	2600-2818 	  		  		 
intron 	  	2819-2900 	  		  		 
exon 	  	2901-3108 	  		  		 
intron 	  	3109-3192 	  		  		 
exon 	  	3193-3346 	  		  		 
intron 	  	3347-3461 	  		  		 
exon 	  	3462-4067 	  		  		 
intron 	  	4068-4158 	  		  		 
exon 	  	4159-4847 	  		  
/;

my $difference = 0;
my @z;
for(my $i = 0; $i < @t; $i+=2) {
    my ($s, $e) = split /-/,$t[$i+1];
    if ($t[$i] =~ /^e/ ) {
        push @z, [sprintf("%.0f", ($s - $difference)/3), sprintf("%.0f", ($e - $difference)/3), "e$i"];
        say STDERR join " - ", ($z[-1]->[0], $z[-1]->[1]);
    } elsif ($t[$i] =~ /^i/) {
        $difference += $e - $s + 1;
    }
}


    my $sio = Bio::SeqIO->new(
        -format => 'fasta',
        -file => $fastafile,
    );
    say STDERR join "-", map { ($_->[1] - $_->[0] + 1) } @z;
    say STDERR "sum: ", sum (map { ($_->[1] - $_->[0] + 1) } @z);

    my $jannot = Bio::Gonzales::Util::Tools::Jalview->new(sequence => $sio->next_seq());
    print $jannot->annotation_track({name => 'Exons1', description => 'keine', track=>\@z});
    
