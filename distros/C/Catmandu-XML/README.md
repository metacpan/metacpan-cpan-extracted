# NAME

Catmandu::XML - modules for handling XML data within the Catmandu framework

# Status

[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-XML.png)](http://cpants.cpanauthors.org/dist/Catmandu-XML)

# DESCRIPTION

[Catmandu::XML](https://metacpan.org/pod/Catmandu%3A%3AXML) contains modules for handling XML data within the [Catmandu](https://metacpan.org/pod/Catmandu)
framework. Parsing and serializing is based on [XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML) with
[XML::Struct](https://metacpan.org/pod/XML%3A%3AStruct). XSLT transormation is based on [XML::LibXSLT](https://metacpan.org/pod/XML%3A%3ALibXSLT).

# MODULES

- [Catmandu::Importer::XML](https://metacpan.org/pod/Catmandu%3A%3AImporter%3A%3AXML)

    Import serialized XML documents as data structures.

- [Catmandu::Exporter::XML](https://metacpan.org/pod/Catmandu%3A%3AExporter%3A%3AXML)

    Serialize data structures as XML documents.

- [Catmandu::XML::Transformer](https://metacpan.org/pod/Catmandu%3A%3AXML%3A%3ATransformer)

    Utility module for XML/XSLT processing.

- [Catmandu::Fix::xml\_read](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Axml_read)

    Fix function to parse XML to MicroXML as implemented by [XML::Struct](https://metacpan.org/pod/XML%3A%3AStruct).

- [Catmandu::Fix::xml\_write](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Axml_write)

    Fix function to seralize XML.

- [Catmandu::Fix::xml\_simple](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Axml_simple)

    Fix function to parse XML or convert MicroXML to simple form as known from
    [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple).

- [Catmandu::Fix::xml\_transform](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Axml_transform)

    Fix function to transform XML using XSLT stylesheets.

# SEE ALSO

This module requires the libraries `libxml2` and `libxslt`. For instance on
Ubuntu Linux call `sudo apt-get install libxslt-dev libxml2-dev` before
installation of Catmandu::XML.

# COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2014-

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
