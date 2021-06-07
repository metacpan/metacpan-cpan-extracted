package Bin::TSV::Util ;
our $VERSION = '0.100' ; 
our $DATE = '2021-05-28T22:40+0900' ; 

=encoding utf8

=head1 NAME

Bin::TSV::Util

=head1 SYNOPSIS

This module "Bin::TSV::Util" provides scripts for specific functions that deals especially TSV formatted data.

=head1 DESCRIPTION

The included commands are as follows. Only one of many major functions are explained for each command. 
Note that all of the command here is designed based on Unix philosophy such as
 "Write programs that do one thing and do it well", "Write programs to work together", and 
 "Write programs to handle text streams because that is a universal interface". 

colsummary : Print the table about 8 statistics of each column of the input TSV file.

colorplus : By "colorplus -t 5" you can easily recognize to see how each column of a TSV file. 

colchop : You can make it easy to see a TSV file in a "square" format even if the lengths of cell of the table differs.

collen : You can take the lenghts (byte size) of each cell of the input cell of the input TSV file.

keyvalues : "How many different values each key has?" for the input TSV files whose 1st column is regarded to be key.

kvcmp : For multiple TSV files, whether key-value relationship is the same or not will be checked.

colpairs : For a TSV with N columns, N x N matrix will be output to show every "two columns" pair statistics. 

colhashS : For each column, the total of SHA1 value is output. Useful for a kind of rigorous check of data processing.

colsplit : Some kind of "column splitting" is performed. Try using it for understanding how it works. 

crosstable : 2-way contingency table for 2 column TSV file. Also a crosstable each of whose cell shows the sum of the 3rd column.
 
colgrep : "grep" on a specifed column. 

inarow : clealy show the rows grouping by the specific columns. 

join2 : The alternative Unix command "join" or "SQL join", for 2 TSV files. 

joinn : for N TSV files, each of whose 1st column is regarded to be key column, the values (all of not the key) of N files are alligned. 

=over 4

=item *

1. B<something>   ;;

=back

=head1 SEE ALSO

=cut

1 ;
