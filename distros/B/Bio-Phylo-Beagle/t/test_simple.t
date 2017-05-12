#!/usr/bin/perl
use lib 'lib';
use Test::More 'no_plan';
use strict;
use warnings;
use Math::Round;
use Bio::Phylo::Beagle;
use Bio::Phylo::IO 'parse';
use Bio::Phylo::Models::Substitution::Dna::JC69;

# parse the FASTA matrix at the bottom of this file
my $matrix = parse(
    '-format' => 'fasta',
    '-type'   => 'dna',
    '-handle' => \*DATA,
)->[0];

# parse a NEWICK string
my $tree = parse(
    '-format' => 'newick',
    '-string' => '((homo:0.1,pan:0.1):0.2,gorilla:0.1);',
)->first;

# instantiate a JC69 model
my $model = Bio::Phylo::Models::Substitution::Dna::JC69->new;

# instantiate the beagle wrapper
my $beagle = Bio::Phylo::Beagle->new;

# create a beagle instance
my $instance = $beagle->create_instance(
    '-tip_count'             => $matrix->get_ntax, # tipCount
    '-partials_buffer_count' => 2, # partialsBufferCount
    '-compact_buffer_count'  => 3, # compactBufferCount
    '-state_count'           => 4, # stateCount
    '-pattern_count'         => $matrix->get_nchar, # patternCount
    '-eigen_buffer_count'    => 1, # eigenBufferCount
    '-matrix_buffer_count'   => 4, # matrixBufferCount
    '-category_count'        => 1, # categoryCount
);

# assign a character state matrix
$beagle->set_matrix($matrix);

# assign a substitution model
$beagle->set_model($model);

# set category weights
$beagle->set_category_weights( '-weights' => [1.0] );

# set category rates
$beagle->set_category_rates( 1.0 );

# set eigen decomposition
$beagle->set_eigen_decomposition(
    '-vectors' => [
        1.0,  2.0,  0.0,  0.5,
        1.0, -2.0,  0.5,  0.0,
        1.0,  2.0,  0.0, -0.5,
        1.0, -2.0, -0.5,  0.0        
    ],
    '-inverse_vectors' => [
        0.25,   0.25,  0.25,   0.25,
        0.125, -0.125, 0.125, -0.125,
        0.0,    1.0,   0.0,   -1.0,
        1.0,    0.0,  -1.0,    0.0        
    ],
    '-values' => [
        0.0, -1.3333333333333333, -1.3333333333333333, -1.3333333333333333
    ]
);

# assign a tree object
$beagle->set_tree($tree);

# update transition matrices
$beagle->update_transition_matrices;           

# create operation array
my $operations = Bio::Phylo::BeagleOperationArray->new(2);

# create operations
my $op0 = Bio::Phylo::BeagleOperation->new(
    '-destination_partials'     => 3,
    '-destination_scale_write'  => $Bio::Phylo::Beagle::BEAGLE_OP_NONE,
    '-destination_scale_read'   => $Bio::Phylo::Beagle::BEAGLE_OP_NONE,
    '-child1_partials'          => 0,
    '-child1_transition_matrix' => 0,
    '-child2_partials'          => 1,
    '-child2_transition_matrix' => 1
);
my $op1 = Bio::Phylo::BeagleOperation->new(
    '-destination_partials'     => 4,
    '-destination_scale_write'  => $Bio::Phylo::Beagle::BEAGLE_OP_NONE,
    '-destination_scale_read'   => $Bio::Phylo::Beagle::BEAGLE_OP_NONE,
    '-child1_partials'          => 2,
    '-child1_transition_matrix' => 2,
    '-child2_partials'          => 3,
    '-child2_transition_matrix' => 3
);

# insert operations in array
$operations->set_item( '-index' => 0, '-op' => $op0 );
$operations->set_item( '-index' => 1, '-op' => $op1 );

# update partials
$beagle->update_partials(
	'-operations' => $operations,
	'-count'      => 2,
	'-index'      => $Bio::Phylo::Beagle::BEAGLE_OP_NONE,
);

my $lnl = $beagle->calculate_root_log_likelihoods;
ok( round($lnl) == -85, "lnL = $lnl" );

__DATA__
>homo
CCGAG-AGCAGCAATGGAT-GAGGCATGGCG
>pan
GCGCGCAGCTGCTGTAGATGGAGGCATGACG
>gorilla
GCGCGCAGCAGCTGTGGATGGAAGGATGACG
