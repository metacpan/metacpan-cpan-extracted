[![Build Status](https://travis-ci.org/wang-q/AlignDB-DeltaG.svg?branch=master)](https://travis-ci.org/wang-q/AlignDB-DeltaG) [![Coverage Status](http://codecov.io/github/wang-q/AlignDB-DeltaG/coverage.svg?branch=master)](https://codecov.io/github/wang-q/AlignDB-DeltaG?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/AlignDB-DeltaG.svg)](https://metacpan.org/release/AlignDB-DeltaG)
# NAME

AlignDB::DeltaG - Calculate deltaG of polymer DNA sequences

# SYNOPSIS

- Normal use

        use AlignDB::DeltaG
        my $deltaG = AlignDB::DeltaG->new(
            temperature => 37,
            salt_conc   => 1,
        );
        my $seq = "TAACAAGCAATGAGATAGAGAAAGAAATATATCCA";
        print "$seq deltaG: ", $deltaG->polymer_deltaG($seq), "\n";

- Reset conditionss

        use AlignDB::DeltaG;
        # default value:
        #   temperature => 37,
        #   salt_conc   => 1,
        my $deltaG = AlignDB::DeltaG->new;
        $deltaG->temperature(30);
        $deltaG->salt_conc(0.1);
        $deltaG->BUILD;
        my $seq = "TAACAAGCAATGAGATAGAGAAAGAAATATATCCA";
        print "$seq deltaG: ", $deltaG->polymer_deltaG($seq), "\n";

# DESCRIPTION

`AlignDB::DeltaG` is a simple class to calculate deltaG of polymer DNA sequences using the NN model.

In the near future, it may be extanded to calculate oligonucleotide thermodynamics.

## Reference

    1. SantaLucia J, Jr. 2004. Annu Rev Biophys Biomol Struct;
    2. SantaLucia J, Jr. 1998. Proc Natl Acad Sci U S A;

# ATTRIBUTES

`temperature` - default: 37.0 degree centigrade

`salt_conc` - salt concentration, Default: 1 \[Na+\], in M. Should be above 0.05 M and below 1.1 M

`deltaH` - enthalpy, isa HashRef

`deltaS` - entropy (cal/K.mol), isa HashRef

`deltaG` - free energy, isa HashRef

# METHODS

## BUILD

rebuild the object by the new temperature and/or salt\_conc values

## polymer\_deltaG

    my $dG = $obj->polymer_deltaG($seq);

Calculate deltaG of a given sequence.

This method is the main calculating sub.

# AUTHOR

Qiang Wang &lt;wang-q@outlook.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
