#!/usr/bin/env perl

use Modern::Perl '2011';
use autodie;

use Template;
use Path::Class qw(file);

my $gcprt = file('test/taxdump', 'gc.prt')->slurp;

# compute template and output paths for TT
my $template = file('codegen/templates', 'Factory.tt')->stringify;
my $outfile  = file('lib/Bio/MUST/Core/GeneticCode', 'Factory.pm')->stringify;

my $vars = {
    gcprt => $gcprt,
};

my $tt = Template->new( { RELATIVE => 1 } );

$tt->process($template, $vars, $outfile)
    or die 'Cannot build: ' . $outfile . ": $!";
