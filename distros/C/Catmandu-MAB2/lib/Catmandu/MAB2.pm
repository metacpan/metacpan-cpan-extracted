package Catmandu::MAB2;

our $VERSION = '0.20';

use strict;
use warnings;


1; # End of Catmandu::MAB2

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::MAB2 - Catmandu modules for working with MAB2 data.

=begin markdown

[![Build Status](https://travis-ci.org/jorol/Catmandu-MAB2.png)](https://travis-ci.org/jorol/Catmandu-MAB2)
[![Coverage Status](https://coveralls.io/repos/jorol/Catmandu-MAB2/badge.png?branch=devel)](https://coveralls.io/r/jorol/Catmandu-MAB2?branch=devel)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-MAB2.png)](http://cpants.cpanauthors.org/dist/Catmandu-MAB2)
[![CPAN version](https://badge.fury.io/pl/Catmandu-MAB2.png)](http://badge.fury.io/pl/Catmandu-MAB2)

=end markdown

=head1 DESCRIPTION

Catmandu::MAB2 provides methods to work with MAB2 data within the L<Catmandu>
framework. See L<Catmandu::Introduction> and L<http://librecat.org/> for an
introduction into Catmandu.

=head1 CATMANDU MODULES

=over

=item * L<Catmandu::Importer::MAB2>

=item * L<Catmandu::Exporter::MAB2>

=item * L<Catmandu::Importer::SRU::Parser::mabxml>

=item * L<Catmandu::Fix::mab_map>

=back

=head1 INTERNAL MODULES

Parser and writer for MAB2 data.

=over

=item * L<MAB2::Parser::Disk>

=item * L<MAB2::Parser::RAW>

=item * L<MAB2::Parser::XML>

=item * L<MAB2::Writer::Handle>

=item * L<MAB2::Writer::Disk>

=item * L<MAB2::Writer::RAW>

=item * L<MAB2::Writer::XML>

=back

=head1 AUTHOR

Johann Rolschewski <jorol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Johann Rolschewski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
