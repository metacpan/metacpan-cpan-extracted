package CLI::Contingency::Table;

use 5.006;
use strict;
use warnings;

=head1 NAME

CLI::Contingency::Table - Command line programs for making a contingency tables in 1-way, 2-way. 
Also provides Venn diagram drawing functions for 4 sets and for arbitrarily number of sets.

You may know that to make a 1-way contingency table or frequency table in a unix-like environment
" sort | unic -c " is enough, but you may want to speedy response for large data or you may need 
other related functions. The created command "freq" works well for that. "crosstable" is for 
making 2-way contingency table. 

Provided commands (program files which work as command line interface): 
     freq -- to yiled 1-way contingency table 
     crosstable -- to yield 2-way contingency table
     venn4  -- to draw the Venn diagram for 4 sets using rectangles.
     venn  -- to perform similar things to draw the Venn diagram for any number of sets (but < 10 is practical)
     saikoro -- to generate random number from uniform distributions. Saikoro is a dice in Japanese.
     csel -- to select out columns from tabular files such as in CSV, TSV format. Easier than "cut" and "awk".

=head1 VERSION

Version 0.53

=cut

our $VERSION = '0.53';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use CLI::Contingency::Table;

    my $foo = CLI::Contingency::Table->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cli-contingency-table at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CLI-Contingency-Table>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CLI::Contingency::Table


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CLI-Contingency-Table>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CLI-Contingency-Table>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CLI-Contingency-Table>

=item * Search CPAN

L<http://search.cpan.org/dist/CLI-Contingency-Table/>

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

1; # End of CLI::Contingency::Table
