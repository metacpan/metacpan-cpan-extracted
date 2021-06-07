package Bin::Subtotal ; 

our $VERSION = "0.200" ; 
our $DATE = "2021-05-27T00:55+0900 ; 

=encoding utf8

=head1 NAME

Bin::Subtotal

=head1 SYNOPSIS

This module "Bin::Subtotal" provides scripts for specific functionalities that deals about "subtotals".  

=head1 DESCRIPTION

The included commands are as follows.

- freq : yield the frequency table from a file to be regarded as a collection of values whose elements are from each line. 

- crosstable : yield the contingency table from the 2-columned data of a file.

- summing : print out accumulative sum from the beggining line.  

- quantile : yield the quantile. Also yield the layered quantile table from 2-columned data. 

- digitdemog : print the character distribution table for each "digit" that are defined as "where is it from the left most of the input data".  

- hashtotal : print all the sum of SHA1 sum of each of line from the input files. Useful to compare multiple files if the stored order is not considered. 

=cut

1 ; 


