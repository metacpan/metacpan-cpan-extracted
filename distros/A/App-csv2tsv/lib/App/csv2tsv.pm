package App::csv2tsv;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::csv2tsv - A command transforming from CSV to TSV handling tab/line-ends with escaping, durable for reverse operation.

=head1 VERSION

Version 0.56

=cut

our $VERSION = '0.56';

=head1 SYNOPSIS

csv2tsv [B<-t> str] [B<-n> str] [-v] [-Q] [-2] [B<-~>] file

=head1 DESCRIPTION 

Transforms CSV formatted data (cf. RFC4180) into TSV formated data.
Input is assumed to be UTF-8.
(The input line ends can be both CRLF or LF. The output line ends are LF.)
Warnings/errors would be properly printed on STDERR (as far as the author of
this program experienced).

=head1 EXAMPLE 

csv2tsv file.csv > file.tsv     

csv2tsv B<-n> '[\n]' file.csv > file.tsv       
  # "\n" in the CSV cell will be transfomed to [\n].

csv2tsv B<-t> TAB file.csv > file.tsv       
  # "\t" in the CSV cell will be transfomed to "TAB". UTF-8 characters can be specified.

B<for> i B<in> *.csv ; B<do> csv2tsv -n'"\n"' -t'"\t"' $i > ${i/csv/tsv} ; B<done>
  # BASH or ZSH is required to use this "for" statement. Useful for multiple CSV files.

For the safety, when '-t' or '-n' is set with string character specification,
a B<warning> is displayed every time a values in the input cells matches the specified string charatcter
unless B<-Q> is set.

csv2tsv < file.csv > file.tsv     
  # file name information cannot be passed to "csv2tsv". So the warning messages may lack a few information.

=head1 OPTION

=over 4

=item B<-t> str 

What the input TAB character will be replaced with is specified. 

=item B<-n> str 

What "\n" character in the input CSV cell will be replaced with is specified. 

=item -v 

Always tell the existence of "\t" or "\n" even if "-t str" or "-n str" is specified. 

=item -Q 

No warning even if "\t" or "\n" is included in the cell of input. 

=item -2 

Double space output, to find "\n" anormality by human eyes. 
(For a kind expediency when this program author was firstly making this program)

=item B<-~>

The opposite conversion of csv2tsv, i.e. B<TSV to CSV> conversion.
(Every cell will be encloded by double quotes.)

=item --help 

Shows this help.

=item --help ja 

Shows Japanese help.

=item --version

Shows the version information of this program. 

=back 


=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-csv2tsv at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-csv2tsv>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::csv2tsv


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-csv2tsv>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-csv2tsv>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-csv2tsv>

=item * Search CPAN

L<http://search.cpan.org/dist/App-csv2tsv/>

=back


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

1; # End of App::csv2tsv
