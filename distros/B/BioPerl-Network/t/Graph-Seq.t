# This is -*-Perl-*- code#
# Bioperl Test Harness Script for Modules#

use strict;

BEGIN {
	use Bio::Root::Test;
	test_begin(-tests => 21,
			   -requires_module => 'Graph');

	use_ok('Graph::Undirected');
	use_ok('Graph::Traversal::DFS');
	use_ok('Bio::Seq');

}

#
# The purpose of these tests is to check to see if bugs have been
# fixed in Perl's Graph, particularly if refvertexed == 1
#
my $g = Graph::Undirected->new(refvertexed => 1);

ok 1;

my $seq1 = Bio::Seq->new(-seq => "aaaaaaa");
my $seq2 = Bio::Seq->new(-seq => "ttttttt");
my $seq3 = Bio::Seq->new(-seq => "ccccccc");
my $seq4 = Bio::Seq->new(-seq => "ggggggg");

$g->add_vertices($seq1,$seq2,$seq3,$seq4);
$g->add_edges([$seq1,$seq2],[$seq3,$seq4],[$seq3,$seq2]);

my @vs = $g->vertices;
ok $vs[0]->seq;

my $c = $g->complete;
@vs = $c->vertices;
ok $vs[0]->seq;

my $comp = $g->complement;
@vs = $comp->vertices;
ok $vs[0]->seq;

@vs = $g->interior_vertices;
ok $vs[0]->seq;

my $apsp = $g->APSP_Floyd_Warshall;
@vs = $apsp->path_vertices($seq1,$seq4);
ok $vs[0]->seq;

my $seq = $g->random_vertex;
ok $seq->seq;

my $t = Graph::Traversal::DFS->new($g);
$t->dfs;
@vs = $t->seen;
for my $seq (@vs) {
	ok $seq->seq;
}

# Fixed in Graph .86
@vs = $g->articulation_points; 
ok $vs[0]->seq; # not OK in Graph v. .80
ok scalar @vs == 2;

my @cc = $g->connected_components;
for my $ref (@cc) {
	for my $seq (@$ref) {
		ok $seq->seq;
	}
}

my @bs = $g->bridges;
ok $bs[0][0]->seq;

my $cg = $g->connected_graph;
@vs = $cg->vertices;
# ok $vs[0]->seq; incorrect usage

my @spd = $g->SP_Dijkstra($seq1,$seq4);

my @spbf = $g->SP_Bellman_Ford($seq1,$seq4);

__END__
