package Catmandu::SRU;

our $VERSION = '0.427';

=head1 NAME

Catmandu::SRU - Catmandu module for working with SRU data

=begin markdown

# STATUS
[![Build Status](https://travis-ci.org/LibreCat/Catmandu-SRU.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-SRU)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-SRU/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-SRU)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-SRU.png)](http://cpants.cpanauthors.org/dist/Catmandu-SRU)

=end markdown

=head1 SYNOPSIS

 # On the command line
 $ catmandu convert SRU --base http://www.unicat.be/sru --query data

 $ catmandu convert SRU --base http://www.unicat.be/sru --query data --recordSchema marcxml

 $ catmandu convert SRU --base http://www.unicat.be/sru --query data --recordSchema marcxml --parser marcxml

 # create a config file: catmandu.yml
 $ cat catmandu.yml
 ---
 importer:
   unicat:
     package: SRU
     options:
     	base: http://www.unicat.be/sru
     	recordSchema: marcxml
     	parser: marcxml

  $ catmandu convert unicat --query data

  # If you have Catmandu::MARC installed
  $ catmandu convert unicat --query data --fix 'marc_map("245a","title"); retain_field("title")' to CSV

  # The example above in perl
  use Catmandu -load;

  my $importer = Catmandu->importer('unicat', query => 'data');
  my $fixer    = Catmandu->fixer(['marc_map("245a","title")','retain_field("title")']);
  my $export   = Catmandu->exporter('CSV');

  $exporter->add_many($fixer->fix($importer));

  $exporter->commit;

=head1 MODULES

=over 2

=item L<Catmandu::Importer::SRU>

=item L<Catmandu::Importer::SRU::Parser>

=item L<Catmandu::Importer::SRU::Parser::raw>

=item L<Catmandu::Importer::SRU::Parser::simple>

=item L<Catmandu::Importer::SRU::Parser::struct>

=item L<Catmandu::Importer::SRU::Parser::marcxml>

=item L<Catmandu::Importer::SRU::Parser::meta>

=item L<Catmandu::Importer::SRU::Parser::mods>

=item L<Catmandu::Importer::SRU::Parser::picaxml>

=item L<Catmandu::Fix::sru_search>

=back

=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Importer>,
L<Catmandu::Fix>,
L<Catmandu::Exporter>,
L<Catmandu::MARC>

=head1 AUTHOR

Wouter Willaert, C<< <wouterw@inuits.eu> >>

=head1 CONTRIBUTORS

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

Jakob Voss C<< <jakob.voss at gbv.de> >>

Johann Rolschewski C<< <jorol at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
