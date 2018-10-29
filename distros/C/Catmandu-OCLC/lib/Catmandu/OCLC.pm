package Catmandu::OCLC;

=head1 NAME

Catmandu::OCLC - Catmandu modules for working with OCLC web services

=begin markdown

# STATUS
[![Build Status](https://travis-ci.org/LibreCat/Catmandu-OCLC.svg)](https://travis-ci.org/LibreCat/Catmandu-OCLC)
[![Coverage Status](https://coveralls.io/repos/LibreCat/Catmandu-OCLC/badge.svg)](https://coveralls.io/r/LibreCat/Catmandu-OCLC)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-OCLC.png)](http://cpants.cpanauthors.org/dist/Catmandu-OCLC)

=end markdown

=cut

our $VERSION = '0.007';

=head1 SYNOPSIS

  add_field('number','102333412');
  do
     maybe();
     viaf_read('number');
     marc_map('700','author.$append')
     remove_field(record)
  end

=head1 MODULES

=over

=item * L<Catmandu::Fix::xID>

=item * L<Catmandu::Fix::viaf_read>

=back

=head1 DESCRIPTION

With Catmandu, LibreCat tools abstract digital library and research services as data
warehouse processes. As stores we reuse MongoDB or ElasticSearch providing us with
developer friendly APIs. Catmandu works with international library standards such as
MARC, MODS and Dublin Core, protocols such as OAI-PMH, SRU and open repositories such
as DSpace and Fedora. And, of course, we speak the evolving Semantic Web.

Follow us on L<http://librecat.org> and read an introduction into Catmandu data
processing at L<https://github.com/LibreCat/Catmandu/wiki>.

=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Importer>,
L<Catmandu::Fix>,
L<Catmandu::Store>

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 COPYRIGHT

This software is copyright (c) 2015 by Patrick Hochstenbach.
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
