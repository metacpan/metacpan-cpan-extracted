package Catmandu::Z3950;

=head1 NAME

Catmandu::Z3950 - Catmandu module for working with Z3950 data

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

  $ catmandu convert Z3950 --host z3950.loc.gov --port 7090 --databaseName Voyager --query "(title = dinosaur)"

=cut

our $VERSION = '0.06';

=head1 MODULES

=over

=item * L<Catmandu::Importer::Z3950>

=back

=head1 AUTHOR

=over

=item * Wouter Willaert, C<< wouterw at inuits.eu> >>

=item * Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be> >>

=back

=head1 CONTRIBUTORS

=over

=item * Emmanuel Di Pretoro, C<< edipretoro at gmail.com >>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
