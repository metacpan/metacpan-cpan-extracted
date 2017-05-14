package Bio::Gonzales;

use warnings;
use strict;

=head1 NAME

Bio::Gonzales - Speedy functions to manipulate biological data

=cut

our $VERSION = '0.0546'; # VERSION


=head1 SYNOPSIS

Biological data analysis is often cumbersome: most tasks are very similar, but
still there is a small difference between them. Bio::Gonzales gives you the
modules and functions that make data crunching easy and speedy, while keeping the
flexibility.

It should not be complete, the focus relies on a few standard formats. If one
is burning in format hell, L<Bio::Perl> might be a much better complement.

To outline the simple usage, here an example to read a fasta sequence file
into a array of L<Bio::Gonzales::Seq> objects.


  use Bio::Gonzales::Seq::IO qw/faslurp/;

  my @seqs = faslurp('sequences.fa');

  # Oh, f**k, somebody sent me gzipped fasta files!
  # Calm down! Gonzales has a speedy answer for that:

  my @seqs = faslurp('sequences.fa.gz');

=head1 DESCRIPTION

THIS IS THE ALPHA STAGE, SO BEWARE. MY TIMELINE IS TO GET THE DOCUMENTATION DONE TILL MARCH 2013.

Motivation for this package is the lack of speed or ease of use or both in other modules.

=head2 Stable modules 

=head3 L<Bio::Gonzales::Seq::IO>

=head3 L<Bio::Gonzales::Range::Overlap>

=head3 L<Bio::Gonzales::Matrix::IO>

=head3 L<Bio::Gonzales::Seq>

=head3 L<Bio::Gonzales::Feat::IO::GFF3>

=head3 L<Bio::Gonzales::Feat>

=head2 Stable, but undocumented

=head3 L<Bio::Gonzales::Project>

=head3 L<Bio::Gonzales::Project::Functions>

=head3 L<Bio::Gonzales::MiniFeat>

=head1 AUTHOR

Joachim Bargsten, C<< <jwb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bargsten-bio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Gonzales>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::Gonzales


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-Gonzales>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-Gonzales>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-Gonzales>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-Gonzales/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Joachim Bargsten.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Bio::Gonzales
