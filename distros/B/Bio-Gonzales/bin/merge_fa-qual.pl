#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use 5.010;

use Bio::SeqIO;
use Bio::Seq::Quality;

use Getopt::Long::Descriptive;

my ( $opt, $usage ) = describe_options(
    '%c %o <seq_file> <qual_file>',
    [],
    [ 'variant|v=s', "can be solexa, illumina, sanger", { default => 'sanger' } ],
    [ 'help',      "print usage message and exit" ],
);

print( $usage->text ), exit if $opt->help;

die "pass a fasta and a fasta-quality file\n"
    unless @ARGV;

my ( $seq_infile, $qual_infile ) = ( scalar @ARGV == 1 ) ? ( $ARGV[0], "$ARGV[0].qual" ) : @ARGV;

## Create input objects for both a seq (fasta) and qual file

my $in_seq_obj = Bio::SeqIO->new(
    -file   => $seq_infile,
    -format => 'fasta',
);

my $in_qual_obj = Bio::SeqIO->new(
    -file   => $qual_infile,
    -format => 'qual',
);

my $out_fastq_obj = Bio::SeqIO->new( -format => 'fastq', -variant => $opt->variant );

while (1) {
    ## create objects for both a seq and its associated qual
    my $seq_obj = $in_seq_obj->next_seq || last;
    my $qual_obj = $in_qual_obj->next_seq;

    die "foo!\n"
        unless $seq_obj->id eq $qual_obj->id;

    ## Here we use seq and qual object methods feed info for new BSQ
    ## object.
    my $bsq_obj = Bio::Seq::Quality->new(
        -id   => $seq_obj->id,
        -seq  => $seq_obj->seq,
        -qual => $qual_obj->qual,
    );

    ## and print it out.
    $out_fastq_obj->write_fastq($bsq_obj);
}

