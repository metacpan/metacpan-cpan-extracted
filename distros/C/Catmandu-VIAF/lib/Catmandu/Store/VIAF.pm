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

    # From the command line
    $ catmandu export VIAF --id 102333412 to YAML
    ---
    dcterms:identifier: '102333412'
    guid: http://viaf.org/viaf/102333412
    schema:birthDate: 1775-12-16
    schema:deathDate: 1817-07-18
    schema:description: English novelist
    skos:prefLabel: Jane Austen
    ...

    # From a Catmandu Fix
    lookup_in_store(
        objectName,    # objectName is a field containing the VIAF identifier
        VIAF
    )

    # From Perl code
    use Catmandu;

    my $store = Catmandu->store('VIAF')->bag;

    my $item = $store->get('102333412');

    print $item->{'skos:prefLabel'} , "\n";  # Jane Austen

=head1 DESCRIPTION

A Catmandu::Store::VIAF is a Perl package that can query the <VIAF|http://viaf.org/>
authority file.

This store supports only one method C<get> to retrieve an AAT record by its identifier

=head1 CONFIGURATION

=head2 lang

The C<lang> parameter is optional and defaults to I<nl-NL>. It sets
the language of the returned I<prefLabel>. If no I<prefLabel> for the
I<viaf_id> in provided I<lang> exists, the I<prefLabel> for the
I<fallback_lang> is used.

=head2 fallback_lang

Optional. Default I<en-US>.

=head1 METHODS

=head2 new(%configuration)

Create a new Catmandu::Store::VIAF

=head2 get($id)

Retrieve a VIAF record given an identifier. Returns a record like:

  {
    'dcterms:identifier' => 'The identifier',
    'guid'               => 'The VIAF URL',
    'schema:birthDate'   => 'Birth date, if provided',
    'schema:deathDate'   => 'Death date, if provided',
    'schema:description' => 'Description, if provided',
    'skos:prefLabel'     => 'prefLabel, in lang or fallback_lang'
  }

=head2 add()

Not supported

=head2 delete()

Not supported

=head2 each()

Not supported

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
