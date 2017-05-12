[![Build Status](https://travis-ci.org/bioperl/Bio-ASN1-EntrezGene.svg?branch=master)](https://travis-ci.org/bioperl/Bio-ASN1-EntrezGene)
[![Coverage Status](https://coveralls.io/repos/bioperl/Bio-ASN1-EntrezGene/badge.png?branch=master)](https://coveralls.io/r/bioperl/Bio-ASN1-EntrezGene?branch=master)

Bio-ASN1-Entrezgene
===================

This distribution includes:
1. XML parser-like parser for the ASN.1-formatted NCBI Entrez Gene files.
2. Indexer for Entrez Gene files.
3. XML parser-like parser for the ASN.1-formatted NCBI Sequence files.
4. Indexer for Sequence files.

These modules have quite high performance and error reporting capabilities.
Additionally, one could dump the data structure generated from extracted
NCBI object records into XML extremely easily using XML::Simple's XMLout().

Written by Dr. Mingyi Liu <mingyiliu@gmail.com>.
Copyright (c) 2005 Mingyi Liu, GPC Biotech, Altana Research Institute.

This program is free software - you can redistribute it and/or modify
it under the same terms as Perl itself.

INSTALLATION
------------

Bio::ASN1::EntrezGene package can be installed & tested as follows:

    perl Makefile.PL
    make
    make test
    make install

DOCUMENTATION
-------------

For documentation, among many other things, please refer to the POD (
plain old documentation) inside the module.

It is highly recommended that you check the example scripts out (under
the examples directory)!

- - -

This distribution is part of the [BioPerl](http://www.bioperl.org/) project.
