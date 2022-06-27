package Catmandu::Identifier;

use strict;
our $VERSION = '0.15';

1;
__END__

=encoding utf-8

=head1 NAME

Catmandu::Identifier - Namespace fixing around identifiers (for normalization, validation, etc.), e.g. ISBN, ISSN

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-Identifier.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-Identifier)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-Identifier/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-Identifier)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-Identifier.png)](http://cpants.cpanauthors.org/dist/Catmandu-Identifier)

=end markdown

=head1 MODULES

=over

=item * L<Catmandu::Fix::isbn10>

=item * L<Catmandu::Fix::isbn13>

=item * L<Catmandu::Fix::isbn_versions>

=item * L<Catmandu::Fix::issn>

=item * L<Catmandu::Fix::uuid>

=item * L<Catmandu::Fix::memento_find>

=item * L<Catmandu::Fix::orcid_bio>

=item * L<Catmandu::Fix::orcid_find>

=item * L<Catmandu::Fix::orcid_profile>

=item * L<Catmandu::Fix::orcid_works>

=item * L<Catmandu::Fix::uri_status_code>

=item * L<Catmandu::Fix::Condition::is_valid_isbn>

=item * L<Catmandu::Fix::Condition::is_valid_issn>

=item * L<Catmandu::Fix::Condition::is_uri>

=item * L<Catmandu::Fix::Condition::is_http_uri>

=item * L<Catmandu::Fix::Condition::is_https_uri>

=item * L<Catmandu::Fix::Condition::is_web_uri>

=item * L<Catmandu::Fix::Condition::is_live_web_uri>

=item * L<Catmandu::Fix::Condition::is_archived_web_uri>

=item * L<Catmandu::Fix::Condition::is_valid_orcid>

=item * L<Catmandu::Fix::Condition::is_live_orcid>

=back

=head1 AUTHOR

Vitali Peil

=head2 CONTRIBUTOR

Patrick Hochstenbach

brian d foy

Ere Maijala

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
