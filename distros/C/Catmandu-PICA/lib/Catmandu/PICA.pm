package Catmandu::PICA;

our $VERSION = '1.18';

1;
__END__

=encoding utf-8

=head1 NAME

Catmandu::PICA - Catmandu modules for working with PICA+ data

=begin markdown

[![Linux build status](https://github.com/gbv/Catmandu-PICA/actions/workflows/linux.yml/badge.svg)](https://github.com/gbv/Catmandu-PICA/actions/workflows/linux.yml)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/myyyxpobr8kn6aby?svg=true)](https://ci.appveyor.com/project/nichtich/catmandu-pica)
[![Coverage Status](https://coveralls.io/repos/gbv/Catmandu-PICA/badge.svg?branch=main)](https://coveralls.io/r/gbv/Catmandu-PICA?branch=main)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-PICA.png)](http://cpants.cpanauthors.org/dist/Catmandu-PICA)

=end markdown

=head1 DESCRIPTION

Catmandu::PICA provides methods to work with PICA data within the L<Catmandu>
framework.  

See L<PICA::Data> for more information about PICA data format and record
structure.

See L<Catmandu::Introduction> and L<http://librecat.org/Catmandu> for an
introduction into Catmandu.

=head1 MODULES

=head2 Read/write PICA

=over

=item * L<Catmandu::Exporter::PICA>

=item * L<Catmandu::Importer::PICA>

=item * L<Catmandu::Importer::SRU::Parser::picaxml>

=item * L<Catmandu::Importer::SRU::Parser::ppxml>

=back

=head2 Fix functions

=over

=item * L<Catmandu::Fix::pica_map> copy from PICA values

=item * L<Catmandu::Fix::pica_keep> reduce record to selected fields

=item * L<Catmandu::Fix::pica_remove> delete (sub)fields

=item * L<Catmandu::Fix::pica_update> change/add PICA values to fixed strings

=item * L<Catmandu::Fix::pica_append> parse and append full PICA fields

=item * L<Catmandu::Fix::pica_set> set PICA values from other fields

=item * L<Catmandu::Fix::pica_add> add PICA values from other fields

=item * L<Catmandu::Fix::pica_tag> set field tag

=item * L<Catmandu::Fix::pica_occurrence> set field occurrence

=item * L<Catmandu::Fix::Bind::pica_each> process selected fields

=item * L<Catmandu::Fix::Bind::pica_diff> track changes

=item * L<Catmandu::Fix::Condition::pica_match> check whether PICA values match a regular expression

=back

=head2 Validation

=over

=item * L<Catmandu::Validator::PICA>

=back

=head1 CONTRIBUTORS

Johann Rolschewski <jorol@cpan.org>

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
