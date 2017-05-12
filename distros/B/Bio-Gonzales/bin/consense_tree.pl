#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use 5.010;

use Bio::Gonzales::Phylo::Util qw/consensus_tree/;


use Getopt::Long::Descriptive;

my ($opt, $usage) = describe_options(
    '%c %o <input_forest> <output_consensus_tree>',
    [ 'fraction|f=f',  "set bootstrap cutoff", {default => 0.5}            ],
    [ 'help',       "print usage message and exit" ],
 );

print($usage->text), exit if $opt->help;

my ($input, $output) = @ARGV;

die "couldn't open $input" unless($input && -f $input);

die "no output file" unless($output);

consensus_tree($input, $output, $opt->fraction);
