package Catmandu::XML;

our $VERSION = '0.17';

__END__

=head1 NAME

Catmandu::XML - modules for handling XML data within the Catmandu framework

=begin markdown

# Status

[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-XML.png)](http://cpants.cpanauthors.org/dist/Catmandu-XML)

=end markdown

=head1 DESCRIPTION

L<Catmandu::XML> contains modules for handling XML data within the L<Catmandu>
framework. Parsing and serializing is based on L<XML::LibXML> with
L<XML::Struct>. XSLT transormation is based on L<XML::LibXSLT>.

=head1 MODULES

=over 4

=item L<Catmandu::Importer::XML>

Import serialized XML documents as data structures.

=item L<Catmandu::Exporter::XML>

Serialize data structures as XML documents.

=item L<Catmandu::XML::Transformer>

Utility module for XML/XSLT processing.

=item L<Catmandu::Fix::xml_read>

Fix function to parse XML to MicroXML as implemented by L<XML::Struct>.

=item L<Catmandu::Fix::xml_write>

Fix function to seralize XML.

=item L<Catmandu::Fix::xml_simple>

Fix function to parse XML or convert MicroXML to simple form as known from
L<XML::Simple>.

=item L<Catmandu::Fix::xml_transform>

Fix function to transform XML using XSLT stylesheets.

=back

=head1 SEE ALSO

This module requires the libraries C<libxml2> and C<libxslt>. For instance on
Ubuntu Linux call C<sudo apt-get install libxslt-dev libxml2-dev> before
installation of Catmandu::XML.

=encoding utf8

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2014-

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
