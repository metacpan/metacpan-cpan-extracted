package Catmandu::RIS;

our $VERSION = '0.10';

1;
__END__

=encoding utf-8

=head1 NAME

Catmandu::RIS -  Catmandu modules for working with RIS data

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-RIS.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-RIS)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-RIS/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-RIS)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-RIS.png)](http://cpants.cpanauthors.org/dist/Catmandu-RIS)

=end markdown

=head1 SYNOPSIS

  catmandu convert RIS < input.txt
  
  # Use the --human option to translate RIS tags into human readable strings
  catmandu convert RIS --human 1 < input.txt

  # Provide a comma separated mapping file to translate RIS tags
  catmandu convert RIS --human mappings/my_tags.txt < input.txt

=head1 Author

Nicolas Steenlant

=head1 CONTRIBUTOR

Vitali Peil

Patrick Hochstenbach

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catmandu>, L<Catmandu::Exporter>, L<Catmandu::Importer>

=head2 for other bibliographic formats

L<Catmandu::BibTeX>

=cut
