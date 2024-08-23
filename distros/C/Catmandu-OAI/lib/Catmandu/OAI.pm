package Catmandu::OAI;

=head1 NAME

Catmandu::OAI - Catmandu modules for working with OAI repositories

=head1 SYNOPSIS

  # From the command line
  $ catmandu convert OAI --url http://biblio.ugent.be/oai --set allFtxt
  $ catmandu convert OAI --url http://biblio.ugent.be/oai --metadataPrefix mods --set books
  $ catmandu convert OAI --url http://biblio.ugent.be/oai --metadataPrefix mods --set books --handler raw
  $ catmandu import OAI --url http://biblio.ugent.be/oai --set allFtxt to MongoDB --database-name biblio

  # Harvest repository description
  $ catmandu convert OAI --url http://myrepo.org/oai --identify 1

  # Harvest identifiers
  $ catmandu convert OAI --url http://myrepo.org/oai --listIdentifiers 1

  # Harvest sets
  $ catmandu convert OAI --url http://myrepo.org/oai --listSets 1

  # Harvest metadataFormats
  $ catmandu convert OAI --url http://myrepo.org/oai --listMetadataFormats 1

  # Harvest one record
  $ catmandu convert OAI --url http://myrepo.org/oai --getRecord 1 --identifier oai:myrepo:1234

=cut

our $VERSION = '0.21';

=head1 MODULES

=over

=item * L<Catmandu::Importer::OAI>

=item * L<Catmandu::Store::OAI>

=back

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 CONTRIBUTOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

Jakob Voss, C<< <nichtich at cpan.org> >>

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ghent University Library

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
