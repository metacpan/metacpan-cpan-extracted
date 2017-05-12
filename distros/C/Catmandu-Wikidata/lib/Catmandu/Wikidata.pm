use strict;
use warnings;
package Catmandu::Wikidata;
#ABSTRACT: Import from Wikidata for processing with Catmandu
our $VERSION = '0.06'; #VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Wikidata - Import from Wikidata for processing with Catmandu

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    catmandu convert Wikidata --items Q42,P19 to JSON --pretty 1

    echo Q42 | catmandu convert Wikidata to JSON --pretty 1

    catmandu convert Wikidata --site enwiki --title "Emma Goldman" to JSON --pretty 1
    catmandu convert Wkidata --title dewiki:Metadaten to JSON --pretty 1

    catmandu convert Wikidata --title "Emma Goldman" \
        --fix "wd_language('en')" to JSON --pretty 1

=head1 DESCRIPTION

B<Catmandu::Wikidata> provides modules to process data from
L<http://www.wikidata.org/> within the L<Catmandu> framework. In particular it
facilitates access to Wikidata entity record via
L<Catmandu::Importer::Wikidata>, the simplification of these records via fixes
(C<wd_language($language)>, C<wd_simple()>, C<wd_simple_strings()>, and
C<wd_simple_claims()>). Other Catmandu modules can be used to further process
the records, for instance to load them into a database.

=head1 MODULES

=over

=item L<Catmandu::Importer::Wikidata>

Imports entities from L<http://www.wikidata.org/>.

=item L<Catmandu::Fix::wd_language>

Limit string values in a Wikidata entity record to a selected language.

=item L<Catmandu::Fix::wd_simple_strings>

Simplifies labels, descriptions, and aliases of Wikidata entity record.

=item L<Catmandu::Fix::wd_simple_claims>

Simplifies claims of a Wikidata entity record.

=item L<Catmandu::Fix::wd_simple>

Applies L<Catmandu::Fix::wd_simple_strings> and
L<Catmandu::Fix::wd_simple_claims>. Further simplifies sitelinks and optionally
applies L<Catmandu::Fix::wd_language>.

=back

=head1 SEE ALSO

Background information on Catmandu can be found at L<http://librecat.org/>.

Background information on Wikidata can be found at
L<http://www.wikidata.org/wiki/Wikidata:Introduction>.

=head1 AUTHOR

Jakob Voß

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
