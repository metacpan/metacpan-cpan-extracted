package CLI::Table::Key::Finder;

use 5.006;
use strict;
use warnings;

=head1 NAME

CLI::Table::Key::Finder - These CLIs help you to find key column(s) of a table, as fast as possible, hopefully.

=head1 VERSION

Version 0.31

=cut

our $VERSION = '0.31';


=head1 SYNOPSIS

  Followings are CLI (command line interfaces) commands. 

   alluniq -- To check evely lines has different values ; if not it ouputs how the multiple-ness occurs.
   colpairs -- (Not matured) Shows N x N matrics to see how many different values appear on every pair of N columns.
   colsummary -- Quickly (but not so computationally fast) shows the summary of every column of a table. Useful.
   csel -- the columns selector like AWK/cut in a simpler way.
   freq -- 1-way contingency table of values separated by line ends. A frequency table is ouput with many options.
   keyvalues -- How many different values each key column value has?
   piececount -- How many lines that have the specified pattern? 
   wisejoin -- a wiser command than Unix-join. It is like SQL-join. You can combiner another table to refer to.

  If you are given a table, you may want to check : 
    - whether the table has lines which shares completely same value,
    - whether it has a meaningful a key column to be refered to,
    - whether it has a meaningful key columns if not it does not have a key columns,
    - the minimum number of combination of column(s) to distinguish all the records of the table, 
    - whether the column which seems to have all number values really has only numbers..

   The above commands would greatly help you on such questions. 

  One scenario : 

    1. Use `colsummary' to see all the statistics of each column by one-shot command. 
    2. If you cannot find any key column, use `colpairs' to try to find the key-pairs which distinguished all the recoods.
    3. In case you cannot find such key-pairs, `csel -d X table | alluniq` changing X from 1 to N give you hints to 
       identify the neccessary columns to dinstinguish all the records. 
    4. You would use `piececount` to check the format of key column values. 
    5. `freq' and `keyvalues' is helpful to check the "disinguishability"-ness of columns. 
    6. Sometimes (actually potentially everytime), you like to "join" tables. `wisejoin' is helpful.

  Note: 
    Some of 8 commands has long history to be used by the authors hands but the others are not. So it is 
    vulnerable to change the function of such commands easily. 

=cut


=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CLI::Table::Key::Finder


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 "Toshiyuki Shimono".

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of CLI::Table::Key::Finder
