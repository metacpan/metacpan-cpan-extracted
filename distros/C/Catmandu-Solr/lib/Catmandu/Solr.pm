package Catmandu::Solr;

# ABSTRACT: Catmandu modules for working with solr endpoints
our $VERSION = "0.0303";

=head1 NAME

Catmandu::Solr - Catmandu modules for working with solr endpoints

=head1 SYNOPSIS

    # From the command line

    # Import data into Solr
    $ catmandu import JSON to Solr  < data.json

    # Export data from ElasticSearch
    $ catmandu export Solr to JSON > data.json

    # Export only one record
    $ catmandu export Solr --id 1234

    # Export using an Solr query
    $ catmandu export Solr --query "name:Recruitment OR name:college"

    # Export using a CQL query (needs a CQL mapping)
    $ catmandu export Solr --q "name any college"

=head1 AUTHOR

Nicolas Steenlant, C<< nicolas.steenlant at ugent.be >>

Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be >>

Nicolas Franck, C<< nicolas.franck at ugent.be >>

=head1 SYNOPSIS

For documentation on these fixes see:

L<Catmandu::Store::Solr>

L<Catmandu::Importer::Solr>

=head1 SEE ALSO

L<Catmandu::Store>

L<Catmandu>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
