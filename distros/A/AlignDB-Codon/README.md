[![Build Status](https://travis-ci.org/wang-q/AlignDB-Codon.svg?branch=master)](https://travis-ci.org/wang-q/AlignDB-Codon) [![Coverage Status](http://codecov.io/github/wang-q/AlignDB-Codon/coverage.svg?branch=master)](https://codecov.io/github/wang-q/AlignDB-Codon?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/AlignDB-Codon.svg)](https://metacpan.org/release/AlignDB-Codon)
# NAME

AlignDB::Codon - translate sequences and calculate Dn/Ds

# DESCRIPTION

AlignDB::Codon provides methods to translate sequences and calculate Dn/Ds with different codon
tables.

Some parts of this module are extracted from BioPerl to avoid the huge number of its dependencies.

# METHODS

## change\_codon\_table

    $obj->change_codon_table(2);

Change used codon table and recalc all attributes.

Codon table id should be in range of 1-6,9-16,21.

## comp\_codons

    my ($syn, $nsy) = $obj->comp_codons('TTT', 'GTA');

    my ($syn, $nsy) = $obj->comp_codons('TTT', 'GTA', 1);

Compares 2 codons to find the number of synonymous and non-synonymous mutations between them.

If the third parameter (in 0 .. 2) is given, this method will return syn&nsy at this position.

## is\_start\_codon

    my $bool = $obj->is_start_codon('ATG')

Returns true for codons that can be used as a translation start, false for others.

## is\_ter\_codon

    my $bool = $obj->is_ter_codon('GAA')

Returns true for codons that can be used as a translation terminator, false for others.

## convert\_123

    my $three_format = $obj->convert_123('ARN');

Convert aa code from one-letter to three-letter

## convert\_321

    my $one_format = $obj->convert_321('AlaArgAsn');

Convert aa code from three-letter to one-letter

# AUTHOR

Qiang Wang &lt;wang-q@outlook.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
