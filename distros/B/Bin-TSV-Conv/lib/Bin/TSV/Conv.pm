package Bin::TSV::Conv ; 

our $VERSION = "0.310" ; 
our $DATE = "2021-05-28T23:45+0900" ; 

=encoding utf8

=head1 NAME

Bin::TSV::Conv

=head1 SYNOPSIS

This module "Bin::TSV::Conv" provides scripts for specific functionalities that deals about the conversions regarding TSV files.  

=head1 DESCRIPTION

The included commands are as follows.

B<csv2tsv> : functions converting CSV into TSV. Also with many related functionalities.

B<xlsx2tsv> : The conversion from XLSX into TSV. Note: I<Not so mature in the function designs about this command.>

B<mtranspose> : I<Transpose> the table data in the TSV format as if it is the mathematical matrix. Just exchaning rows and columns. 

B<csel> : A simeple utility more than AWK. Very easy manipulations of columns of a TSV file with `-p' or `-d' options. 

B<join2> : A one-step advanced version of "Unix join" or "SQL join". May need to be refined another step! 

For each command, with "--help" option will give you the detailed explanation how to use them, but it is written in mainly Japanese.


=cut

1 ; 


