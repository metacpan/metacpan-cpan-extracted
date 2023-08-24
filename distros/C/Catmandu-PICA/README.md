# NAME

Catmandu::PICA - Catmandu modules for working with PICA+ data

[![Linux build status](https://github.com/gbv/Catmandu-PICA/actions/workflows/linux.yml/badge.svg)](https://github.com/gbv/Catmandu-PICA/actions/workflows/linux.yml)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/myyyxpobr8kn6aby?svg=true)](https://ci.appveyor.com/project/nichtich/catmandu-pica)
[![Coverage Status](https://coveralls.io/repos/gbv/Catmandu-PICA/badge.svg?branch=main)](https://coveralls.io/r/gbv/Catmandu-PICA?branch=main)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-PICA.png)](http://cpants.cpanauthors.org/dist/Catmandu-PICA)

# DESCRIPTION

Catmandu::PICA provides methods to work with PICA data within the [Catmandu](https://metacpan.org/pod/Catmandu)
framework.  

See [PICA::Data](https://metacpan.org/pod/PICA%3A%3AData) for more information about PICA data format and record
structure.

See [Catmandu::Introduction](https://metacpan.org/pod/Catmandu%3A%3AIntroduction) and [http://librecat.org/Catmandu](http://librecat.org/Catmandu) for an
introduction into Catmandu.

# MODULES

## Read/write PICA

- [Catmandu::Exporter::PICA](https://metacpan.org/pod/Catmandu%3A%3AExporter%3A%3APICA)
- [Catmandu::Importer::PICA](https://metacpan.org/pod/Catmandu%3A%3AImporter%3A%3APICA)
- [Catmandu::Importer::SRU::Parser::picaxml](https://metacpan.org/pod/Catmandu%3A%3AImporter%3A%3ASRU%3A%3AParser%3A%3Apicaxml)
- [Catmandu::Importer::SRU::Parser::ppxml](https://metacpan.org/pod/Catmandu%3A%3AImporter%3A%3ASRU%3A%3AParser%3A%3Appxml)

## Fix functions

- [Catmandu::Fix::pica\_map](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Apica_map) copy from PICA values
- [Catmandu::Fix::pica\_keep](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Apica_keep) reduce record to selected fields
- [Catmandu::Fix::pica\_remove](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Apica_remove) delete (sub)fields
- [Catmandu::Fix::pica\_update](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Apica_update) change/add PICA values to fixed strings
- [Catmandu::Fix::pica\_append](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Apica_append) parse and append full PICA fields
- [Catmandu::Fix::pica\_set](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Apica_set) set PICA values from other fields
- [Catmandu::Fix::pica\_add](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Apica_add) add PICA values from other fields
- [Catmandu::Fix::pica\_tag](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Apica_tag) set field tag
- [Catmandu::Fix::pica\_occurrence](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Apica_occurrence) set field occurrence
- [Catmandu::Fix::Bind::pica\_each](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3ABind%3A%3Apica_each) process selected fields
- [Catmandu::Fix::Bind::pica\_diff](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3ABind%3A%3Apica_diff) track changes
- [Catmandu::Fix::Condition::pica\_match](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3ACondition%3A%3Apica_match) check whether PICA values match a regular expression

## Validation

- [Catmandu::Validator::PICA](https://metacpan.org/pod/Catmandu%3A%3AValidator%3A%3APICA)

# CONTRIBUTORS

Johann Rolschewski <jorol@cpan.org>

Jakob Voß <voss@gbv.de>

Carsten Klee <klee@cpan.org>

# COPYRIGHT

Copyright 2014- Johann Rolschewski and Jakob Voss

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

[PICA::Data](https://metacpan.org/pod/PICA%3A%3AData), [Catmandu](https://metacpan.org/pod/Catmandu)
