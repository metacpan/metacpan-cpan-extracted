Bio-InterProScanWrapper
=======================
This is a wrapper around InterProScan. It takes in a FASTA file of proteins, splits them up into smaller chunks,
processes them with individual instances of iprscan and then sticks it all back together again.
It can run in parallelised mode on a single host or over LSF.

Features
========
Annotates using InterProScan 5.
Intermediate files cleaned up as soon as they are finished with,
It creates a GFF3 file with the input sequences at the end.

Dependancies
============
A working version of IPRscan 5.

Usage
=====


    # Run InterProScan using LSF
    $script_name -a proteins.faa
  
    # Provide an output file name 
    $script_name -a proteins.faa -o output.gff
  
    # Create 200 jobs at a time, writing out intermediate results to a file
    $script_name -a proteins.faa -p 200
  
    # Run on a single host (no LSF). '-p x' needs x*2 CPUs and x*2GB of RAM to be available
    $script_name -a proteins.faa --no_lsf -p 10 

    # This help message
    annotate_eukaryotes -h


Install
==========
cpanm Bio::InterProScanWrapper


Building from source
=============
dzil authordeps | cpanm
dzil listdeps | cpanm
dzil build
