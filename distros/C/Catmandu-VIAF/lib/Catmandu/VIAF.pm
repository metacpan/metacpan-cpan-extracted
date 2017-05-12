package Catmandu::VIAF;

use strict;

our $VERSION = '0.04';

1;
__END__

=encoding utf-8

=head1 NAME

=for html <a href="https://travis-ci.org/thedatahub/Catmandu-VIAF"><img src="https://travis-ci.org/thedatahub/Catmandu-VIAF.svg?branch=master"></a>

Catmandu::VIAF - Retrieve items from VIAF

=head1 SYNOPSIS

This module contains a L<store|Catmandu::Store::VIAF> to lookup a I<viaf_id> in L<VIAF|https://www.viaf.org>, 
a L<fix|Catmandu::Fix::viaf_match> to match a name to a I<mainHeadingEl> and a
L<fix|Catmandu::Fix::viaf_search> to search for a name in VIAF.

  lookup_in_store(authortName, VIAF, lang:'nl-NL', fallback_lang:'en-US')

  viaf_match(authorName, -lang:'nl-NL', -fallback_lang:'en-US')

  viaf_search(authorName, -lang:'nl-NL', -fallback_lang:'en-US')

=head1 DESCRIPTION

=head2 L<Catmandu::Store::VIAF>

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

=head2 L<Catmandu::Fix::viaf_match>

  viaf_match(
    path,
    -lang: 'nl-NL',
    -fallback_lang: 'nl-NL'
  )

A fix that performs a match between a name and a I<mainHeadingEl> of VIAF I<Person>.

=head2 L<Catmandu::Fix::viaf_search>

  viaf_search(
    path,
    -lang: 'nl-NL',
    -fallback_lang: 'nl-NL'
  )

A fix that performs a search for a name in VIAF.

=head1 AUTHOR

Pieter De Praetere E<lt>pieter at packed.be E<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catmandu>
L<Catmandu::Store::VIAF>
L<Catmandu::Fix::viaf_search>
L<Catmandu::Fix::viaf_match>

=cut
