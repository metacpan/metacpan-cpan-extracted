package Catmandu::VIAF;

use strict;

our $VERSION = '0.05';

1;
__END__

=encoding utf-8

=head1 NAME

=for html <a href="https://travis-ci.org/thedatahub/Catmandu-VIAF"><img src="https://travis-ci.org/thedatahub/Catmandu-VIAF.svg?branch=master"></a>

Catmandu::VIAF - Retrieve items from the VIAF authority file

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
    lookup_in_store(authortName, VIAF, lang:'nl-NL', fallback_lang:'en-US')

    # Perform a direct match between a name and a mainHeadingEl from VIAF
    viaf_match(authorName, -lang:'nl-NL', -fallback_lang:'en-US')

    # Perform a search for a name in VIAF
    viaf_search(authorName, -lang:'nl-NL', -fallback_lang:'en-US')

=head1 MODULES

=over

=item * L<Catmandu::Store::VIAF>

=item * L<Catmandu::Fix::viaf_match>

=item * L<Catmandu::Fix::viaf_search>

=item * L<Catmandu::VIAF::API>

=back

=head1 AUTHORS

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>
Pieter De Praetere <pieter@packed.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by PACKED, vzw, Vlaamse Kunstcollectie, vzw.

This is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License, Version 3, June 2007.

=head1 SEE ALSO

L<Catmandu>
L<Catmandu::Store::VIAF>
L<Catmandu::Fix::viaf_search>
L<Catmandu::Fix::viaf_match>

=cut
