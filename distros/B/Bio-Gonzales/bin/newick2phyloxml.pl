#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

use 5.010;

use Bio::TreeIO;

my $ti = Bio::TreeIO->new(-format => 'newick', -file => 'test.newick');

my $tree = $ti->next_tree;

my $to = Bio::TreeIO->new(-format => 'phyloxml', -file => '>test.phyloxml');

$to->write_tree($tree);
