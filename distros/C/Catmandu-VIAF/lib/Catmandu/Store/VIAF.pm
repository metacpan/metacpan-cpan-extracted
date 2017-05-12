package Catmandu::Store::VIAF;

use Catmandu::Sane;
use Moo;

use Catmandu::Store::VIAF::Bag;

with 'Catmandu::Store';

has lang          => (is => 'ro', default => 'nl-NL');
has fallback_lang => (is => 'ro', default => 'en-US');

1;
__END__

=encoding utf-8

=head1 NAME

=for html <a href="https://travis-ci.org/thedatahub/Catmandu-VIAF"><img src="https://travis-ci.org/thedatahub/Catmandu-VIAF.svg?branch=master"></a>

Catmandu::Store::VIAF - Retrieve items from VIAF

=head1 SYNOPSIS

This module contains a L<store|Catmandu::Store::VIAF> to lookup a I<viaf_id> in L<VIAF|https://www.viaf.org>.

  lookup_in_store(authortName, VIAF, lang:'nl-NL', fallback_lang:'en-US')

=head1 DESCRIPTION

  lookup_in_store(
    authorName,
    AAT,
    lang: 'nl-NL',
    fallback_lang: 'en-US'
  )

The C<lang> parameter is optional and defaults to I<nl-NL>. It sets
the language of the returned I<prefLabel>. If no I<prefLabel> for the
I<viaf_id> in provided I<lang> exists, the I<prefLabel> for the
I<fallback_lang> is used.

The store takes the C<dc:identifier> of a I<Person> from VIAF and returns the following data:

  {
    'dcterms:identifier' => 'The identifier',
    'guid'               => 'The VIAF URL',
    'schema:birthDate'   => 'Birth date, if provided',
    'schema:deathDate'   => 'Death date, if provided',
    'schema:description' => 'Description, if provided',
    'skos:prefLabel'     => 'prefLabel, in lang or fallback_lang'
  }

=head2 PARAMETERS

=head3 Optional parameters

=over

=item C<lang>

Language of the returned C<skos:prefLabel>. Falls back to
C<fallback_lang> if none was found. Use L<IETF language tags|https://en.wikipedia.org/wiki/IETF_language_tag>.

=item C<fallback_lang>

Fallback language.

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter at packed.be E<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catmandu>
L<Catmandu::VIAF>
L<Catmandu::Fix::viaf_search>
L<Catmandu::Fix::viaf_match>

=cut
