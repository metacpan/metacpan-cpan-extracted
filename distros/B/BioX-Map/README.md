# NAME

BioX::Map - map read to genome with bwa and soap

# VERSION

version 0.0.12

# SYNOPSIS

    use BioX::Map;
    my $bm = BioX::Map->new(
      infile      => "in.fastq",
      out_prefix  => 'out',
      genome      => 'ref.fa',
    );

# DESCRIPTION

This module aim to wrap bwa and soap, and statistic result

# Attributes

## infile

the fastq file

## indir

The dir that include fastq file. The priority is higher than infile

## outfile

path of outfile which could include path

## outdir

outdir of mapping result

## force\_index

index genome before mapping

## mismatch

set mismatch allowed in mapping

## genome

path of genome file

## tool

mapping software. Enum\['bwa', 'soap'\]

## bwa

path of bwa

## soap

path of soap

## soap\_index

path of 2bwt-builder

## process\_tool

process of mapping software

## process\_sample

how many samples are processed parallel

# METHODS

## exist\_index

check whether genome index exists

## create\_index

create genome index before mapping

## \_map\_one

wrap mapping software

## map

process one or more samples

## statis\_result

statis mapping result

# AUTHOR

Yan Xueqing <yanxueqing621@163.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
