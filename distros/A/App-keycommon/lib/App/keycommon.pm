package App::keycommon;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::keycommon - You can combine multiple TSV (also machine-readable CSV) files which share a common key column.

=head1 VERSION

Version 0.0012

=cut

our $VERSION = '0.0012';


=head1 SYNOPSIS

See the help manual that can be invoked by 'keycommon --help' (only Japanese manual is available, sorry!).
You can use the command as follows :

  keycommon file1.tsv file2.tsv .. fileN.tsv
  
  keycommon -f 2 file1.tsv file2.tsv .. fileN.tsv  # If the "key column" is the combination of 1st and 2nd columns.
  keycommon -0 "nodata"   file1.tsv file2.tsv   # you can specify what to be filled to the empty cell.
  keycommon -/ ","  file1 file2 file3    # You can specify the column separator.  Partially CSV can be handled (not fully).

  keycommon -n file1 file2 file3  #  The output is sorted according to the key regarded as "number".
  keycommon -r file1 file2 file3  #  The output is sorted according to the key order, but in the reverse manner.

=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-keycommon at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-keycommon>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::keycommon

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-keycommon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-keycommon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-keycommon>

=item * Search CPAN

L<http://search.cpan.org/dist/App-keycommon/>

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

1; # End of App::keycommon
