package Catmandu::RIS;

our $VERSION = '0.13';

1;

__END__

=encoding utf-8

=head1 NAME

Catmandu::RIS -  Catmandu modules for working with RIS data

=begin markdown

# STATUS

![Test status](https://github.com/LibreCat/Catmandu-RIS/actions/workflows/linux.yml/badge.svg)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-RIS/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-RIS)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-RIS.png)](http://cpants.cpanauthors.org/dist/Catmandu-RIS)

=end markdown

=head1 SYNOPSIS

  catmandu convert RIS < input.txt

  # Use the --human option to translate RIS tags into human readable strings
  catmandu convert RIS --human 1 < input.txt

  # Provide a comma separated mapping file to translate RIS tags
  catmandu convert RIS --human mappings/my_tags.txt < input.txt

=head1 MODULES

=over

=item * L<Catmandu::Exporter::RIS>

=item * L<Catmandu::Importer::RIS>

=back

=head1 MAPPING

See the examples in the package L<https://github.com/LibreCat/Catmandu-RIS/tree/master/examples>
for some hints how to create a mapping.

=head1 Author

Nicolas Steenlant

=head1 CONTRIBUTORS

Vitali Peil

Patrick Hochstenbach

Nicolas Franck

Mohammad S Anwar

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catmandu>, L<Catmandu::Exporter>, L<Catmandu::Importer>

=head2 for other bibliographic formats

L<Catmandu::BibTeX>

=cut
