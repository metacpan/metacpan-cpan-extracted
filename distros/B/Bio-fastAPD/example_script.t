#!/usr/bin/perl
# example_script.t - intended for demonstrating the use of the fastAPD perl module
# Author - Joseph D. Baugher, PhD
# Copyright (c) 2014,2015 Joseph D. Baugher (<joebaugher@hotmail.com>). All rights reserved.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself. See L<perlartistic>.
#  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
##################################################################

use warnings;
use strict;
use lib './lib';
use Bio::fastAPD;

my $file_name = "example_data.fasta";
if ($ARGV[0]) { $file_name = $ARGV[0] }

### Create an array of sequences from an MSA file
my $sequences_ref = create_seq_array($file_name);     

### Create and initialize a new fastAPD object    
my $fastAPD_obj = Bio::fastAPD->new();
$fastAPD_obj->initialize(seq_array_ref => $sequences_ref,
                         alphabet      => 'dna');

### Calculate APD
my $apd = $fastAPD_obj->apd('gap_base');

### Calculate standard error of the APD                                            
my $std_err = $fastAPD_obj->std_err('gap_base');

### Get number of reads and positions in the MSA input
my $num_reads     = $fastAPD_obj->n_reads;                                      
my $num_positions = $fastAPD_obj->width;        
   
### Print results   
print join("\t", qw(File APD StdErr Positions Reads)), "\n";      
print join("\t", $file_name, $apd, $std_err, $num_positions, $num_reads), "\n";  

######################

### Subroutines

sub create_seq_array {
    my $file = shift;
    my @sequences;
                                                                      
    # Read in aligned sequence file (fasta format for this test)
    open(my $input_fh, '<', $file);
    chomp(my @fasta_lines = <$input_fh>);
    close $input_fh;
    
    # Create an array of aligned sequences
    my $curr_seq;
    foreach my $line (@fasta_lines) {
        if (substr($line, 0, 1) eq ">") { 
            if ($curr_seq) { push(@sequences, $curr_seq) }
            $curr_seq = ();
        }
        else { $curr_seq .= $line }
    }
    if ($curr_seq) { push(@sequences, $curr_seq) }

    return(\@sequences);
}
   
