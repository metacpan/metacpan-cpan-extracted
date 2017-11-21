package Catmandu::PICA;

our $VERSION = '0.24';

1;
__END__

=head1 NAME

Catmandu::PICA - Catmandu modules for working with PICA+ data

=begin markdown

[![Build Status](https://travis-ci.org/gbv/Catmandu-PICA.png)](https://travis-ci.org/gbv/Catmandu-PICA)
[![Coverage Status](https://coveralls.io/repos/gbv/Catmandu-PICA/badge.png?branch=master)](https://coveralls.io/r/gbv/Catmandu-PICA?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-PICA.png)](http://cpants.cpanauthors.org/dist/Catmandu-PICA)

=end markdown

=head1 DESCRIPTION

Catmandu::PICA provides methods to work with PICA data within the L<Catmandu>
framework.  

See L<PICA::Data> for more information about PICA data format and record
structure.

See L<Catmandu::Introduction> and L<http://librecat.org/> for an
introduction into Catmandu.

=head1 CATMANDU MODULES

=over

=item * L<Catmandu::Importer::PICA>

=item * L<Catmandu::Exporter::PICA>

=item * L<Catmandu::Importer::SRU::Parser::picaxml>

=item * L<Catmandu::Fix::pica_map>

=item * L<Catmandu::Fix::pica_add>

=item * L<Catmandu::Fix::pica_set>

=back

=head1 CONTRIBUTORS

=encoding utf8

Johann Rolschewski, <jorol@cpan.org>

Jakob Voß <voss@gbv.de>

Carsten Klee <klee@cpan.org>

=head1 COPYRIGHT

Copyright 2014- Johann Rolschewski and Jakob Voss

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<PICA::Data>, L<Catmandu>

=cut
