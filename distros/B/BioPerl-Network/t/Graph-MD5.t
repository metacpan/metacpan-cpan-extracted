# This is -*-Perl-*- code#
# Bioperl Test Harness Script for Modules#

use strict;

BEGIN {
	use Bio::Root::Test;
	test_begin(-tests => 23,
			   -requires_module => 'Digest::MD5');

 	use_ok('Graph::Undirected');
}

#
# The purpose of these tests is to check to see if bugs have been 
# fixed in Perl's Graph, particularly refvertexed bugs
#
my $g = Graph::Undirected->new(refvertexed => 1);

ok 1;

my $seq1 = Digest::MD5->new;
my $seq2 = Digest::MD5->new;
my $seq3 = Digest::MD5->new;
my $seq4 = Digest::MD5->new;

my $str = "ljfgouyouiyougs";

$g->add_vertices($seq1,$seq2,$seq3,$seq4);
$g->add_edges([$seq1,$seq2],[$seq3,$seq4],[$seq3,$seq2]);

my @vs = $g->vertices; # OK
ok $vs[0]->add($str);

my $c = $g->complete; # OK
@vs = $c->vertices;
ok $vs[0]->add($str);

my $comp = $g->complement; # OK
@vs = $comp->vertices;
ok $vs[0]->add($str);

@vs = $g->interior_vertices; # OK
ok $vs[0]->add($str);

my $apsp = $g->APSP_Floyd_Warshall;
@vs = $apsp->path_vertices($seq1,$seq4); # OK
ok $vs[0]->add($str);

my $seq = $g->random_vertex; # OK
ok $seq->add($str);

my $t = Graph::Traversal::DFS->new($g);
$t->dfs;
@vs = $t->seen;
ok scalar @vs == 4;
for my $seq (@vs) {
	ok $seq->add($str); # NOT OK in version .73
}

@vs = $g->articulation_points; 
ok scalar @vs == 2;
ok $vs[0]->add($str); # OK in version .70
ok $vs[1]->add($str);

my @cc = $g->connected_components;
for my $ref (@cc) {
	for my $seq (@$ref) {
		ok $seq->add($str); # OK in version .70
	}
}

my @bs = $g->bridges;
ok $bs[0][0]->add($str); # NOT OK in version .73

my $cg = $g->connected_graph;
@vs = $cg->vertices;
# ok $vs[0]->add($str); # is my usage correct?

my @spd = $g->SP_Dijkstra($seq1,$seq4); # OK in version .70
ok scalar @spd == 4;

my @spbf = $g->SP_Bellman_Ford($seq1,$seq4); # OK in version .70
ok scalar @spbf == 4;

__END__
