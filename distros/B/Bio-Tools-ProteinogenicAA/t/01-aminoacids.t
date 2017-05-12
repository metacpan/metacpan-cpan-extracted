#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
use Bio::Tools::ProteinogenicAA;

plan tests => 3;

my $p = Bio::Tools::ProteinogenicAA->new();

cmp_ok ($p->aminoacids->[0]->amino_acid, 'eq', "Alanine");

cmp_ok ($p->aminoacids->[10]->avg_mass, '==', '113.1594');

cmp_ok ($p->aminoacids->[21]->side_chain, 'eq', "-CH(CH3)2");
