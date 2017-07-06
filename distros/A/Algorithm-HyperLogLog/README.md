[![Build Status](https://travis-ci.org/hideo55/p5-Algorithm-HyperLogLog.svg?branch=master)](https://travis-ci.org/hideo55/p5-Algorithm-HyperLogLog)
# NAME

Algorithm::HyperLogLog - Implementation of the HyperLogLog cardinality estimation algorithm

# SYNOPSIS

    use Algorithm::HyperLogLog;
    
    my $hll = Algorithm::HyperLogLog->new(14);
    
    while(<>){
        $hll->add($_);
    }
    
    my $cardinality = $hll->estimate(); # Estimate cardinality
    $hll->dump_to_file('hll_register.dump');# Dumps internal data

Construct object from dumped file.

    use Algorithm::HyperLogLog;
    
    # Restore internal state 
    my $hll = Algorithm::HyperLogLog->new_from_file('hll_register.dump');

# DESCRIPTION

This module is implementation of the HyperLogLog algorithm.

HyperLogLog is an algorithm for estimating the cardinality of a set.

# METHODS

## new($b)

Constructor.

\`$b\` is the parameter for determining register size. (The register size is 2^$b.)

\`$b\` must be a integer between 4 and 16.

## new\_from\_file($filename)

This method constructs object and restore the internal data of object from dumped file(dumped by dump\_to\_file() method).

## dump\_to\_file($filename)

This method dumps the internal data of an object to a file.

## add($data)

Adds element to the cardinality estimator.

## estimate()

Returns estimated cardinality value in floating point number.

## merge($other)

Merges the estimate from 'other' into this object, returning the estimate of their union.

## register\_size()

Return number of register.(In the XS implementation, this equals size in bytes)

## XS()

If using XS backend, this method return true value.

# SEE ALSO

Philippe Flajolet, Éric Fusy, Olivier Gandouet and Frédéric Meunier. HyperLogLog: the analysis of a near-optimal cardinality estimation algorithm. 2007 Conference on Analysis of Algorithms, DMTCS proc. AH, pp. 127–146, 2007. [http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf](http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf)

# AUTHOR

Hideaki Ohno <hide.o.j55 {at} gmail.com>

# THANKS TO

MurmurHash3([https://github.com/PeterScott/murmur3](https://github.com/PeterScott/murmur3))

- Austin Appleby
- Peter Scott

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
