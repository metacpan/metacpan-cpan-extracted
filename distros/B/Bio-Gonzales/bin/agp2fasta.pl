#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use 5.010;

use Bio::Gonzales::Assembly::IO qw/agpslurp agp2fasta/;
use Bio::Gonzales::Util::File qw/expand_path/;
use Getopt::Long::Descriptive;

my ( $opt, $usage ) = describe_options(
    '%c %o --seq <seqfile1> --seq <seqfile2 .. --agp <agpfile1> --agp <agpfile2> .. <output_file>',
    [],
    [ 'seq|s=s@', 'use this sequence files for extraction' ],
    [ 'agp|a=s@', 'use this agp files for extraction' ],
    [],
    [ 'verbose|v', "print extra stuff" ],
    [ 'help',      "print usage message and exit" ],
);

print( $usage->text ), exit if $opt->help;

my $out = shift @ARGV;
$usage->die( { pre_text => 'no output file suppplied' } ) unless ($out);

agp2fasta( $opt->agp, $opt->seq, $out );
