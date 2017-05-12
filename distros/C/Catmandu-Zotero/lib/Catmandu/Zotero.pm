package Catmandu::Zotero;

our $VERSION = '0.07';

1;
__END__

=head1 NAME

Catmandu::Zotero - Catmandu modules for working with Zotero web

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-Zotero.png)](https://travis-ci.org/LibreCat/Catmandu-Zotero)
[![Coverage Status](https://coveralls.io/repos/LibreCat/Catmandu-Zotero/badge.png)](https://coveralls.io/r/LibreCat/Catmandu-Zotero)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-Zotero.png)](http://cpants.cpanauthors.org/dist/Catmandu-Zotero)

=end markdown

=head1 SYNOPSIS

  # From the command line
  $ catmandu convert Zotero --userID <userID> to JSON
  $ catmandu convert Zotero --groupID <groupID> to JSON
  
  # From Perl
  use Catmandu;

  my $importer = Catmandu->importer('Zotero', userID => '...');

  $importer->each(sub {
	   my $item = shift;
	   print "%s %s\n", $item->{_id} , $item->{title}->[0];
  });

=head1 MODULES

=over

=item * L<Catmandu::Importer::Zotero>

=back

=head1 EXAMPLES

See L<https://github.com/LibreCat/Catmandu-Zotero/tree/master/example/zotero_marc.fix> for an
use case how to transform a Zotero library into a MARCXML dump:

    $ catmandu convert Zotero --groupID <key> to MARC --type XML --fix zotero.fix 

=head1 AUTHOR

Patrick Hochstenbach, C<patrick.hochstenbach at ugent.be>

=head2 CONTRIBUTORS

Jakob Voss, C<voss at gbv.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Patrick Hochstenbach

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
