package CLI::Table::Util;

use 5.006;
use strict;
use warnings;

=head1 NAME

CLI::Table::Util - If you are given table text file, what would you do? This provides CLI commands "colsummary", "colsplit", "colchop" and so on.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

This module provides the following programs : 
  1. colsummary -- gives sevelral useful information about each columns of a table by this one-shot command.
  2. colsplit -- divides a TSV file into files each contains each original column. 
  3. colchop -- limits the column string lenghs by folding or omitting for the sake of viewing.
  4. csv2tsv -- transforms from CSV (RFC4180) into TSV format.
  5. colgrep -- performs "grep" on only spcified column.

 To know the detail of the commands, please read the documents invoked by "--help" such as 
 "colsummary --help" etc. 

=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cli-table-util at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CLI-Table-Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CLI::Table::Util




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

1; # End of CLI::Table::Util
