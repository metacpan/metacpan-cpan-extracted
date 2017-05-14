
use strict;
use warnings;

use Test::More;
BEGIN {
  use_ok('Algorithm::MCL');
  use_ok('PDL');
};



my $matrix1 = zeros(4, 4);
$matrix1->set(1, 2, 0.5);
$matrix1->set(2, 1, 0.5);
$matrix1->set(1, 1, 0.5);
$matrix1->set(2, 2, 0.5);
$matrix1->set(2, 3, 0.5);
$matrix1->set(3, 2, 0.5);
$matrix1->inplace->makeStochastic;
ok(1/2 == $matrix1->at(1, 1), "stochastic 1");
ok(1/3 == $matrix1->at(3, 2), "stochastic 2");


my $val1 = \"aaa";
my $val2 = \"bbb";
my $val3 = \"ccc";
my $val4 = \"ddd";
my $val5 = \"eee";

my $mcl1 = Algorithm::MCL->new();
$mcl1->addEdge($val1, $val2);
$mcl1->addEdge($val1, $val3);
$mcl1->addEdge($val2, $val3);
$mcl1->addEdge($val3, $val4);
$mcl1->addEdge($val4, $val5);

my $clusters1 = $mcl1->run();
ok(2 == scalar @$clusters1, "numbers of clusters");
my $sortedClusters1 = sortBySize( $clusters1 );
my $cluster1 = $sortedClusters1->[0];
my $cluster2 = $sortedClusters1->[1];
ok(includeVertex($cluster1, $val4) > 0, "vertex is not in cluster - 1");
ok(includeVertex($cluster1, $val5) > 0, "vertex is not in cluster - 2");
ok(includeVertex($cluster2, $val1) > 0, "vertex is not in cluster - 3");
ok(includeVertex($cluster2, $val2) > 0, "vertex is not in cluster - 4");
ok(includeVertex($cluster2, $val3) > 0, "vertex is not in cluster - 5");




my $t2vl1 = \"a1";
my $t2vl2 = \"a2";
my $t2vl3 = \"a3";
my $t2vl4 = \"a4";
my $t2vl5 = \"a5";
my $t2vl6 = \"a6";
my $t2vl7 = \"a7";
my $t2vl8 = \"a8";
my $t2vl9 = \"a9";
my $t2vl10 = \"a10";
my $t2vl11 = \"a11";
my $t2vl12 = \"a12";
my $t2vl13 = \"a13";
my $t2vl14 = \"a14";
my $t2vl15 = \"a15";
my $t2vl16 = \"a16";


my $mcl2 = Algorithm::MCL->new();
$mcl2->addEdge($t2vl1, $t2vl2);
$mcl2->addEdge($t2vl2, $t2vl5);
$mcl2->addEdge($t2vl2, $t2vl4);
$mcl2->addEdge($t2vl2, $t2vl3);
$mcl2->addEdge($t2vl3, $t2vl4);
$mcl2->addEdge($t2vl3, $t2vl6);
$mcl2->addEdge($t2vl6, $t2vl7);
$mcl2->addEdge($t2vl7, $t2vl12);
$mcl2->addEdge($t2vl8, $t2vl9);
$mcl2->addEdge($t2vl8, $t2vl11);
$mcl2->addEdge($t2vl12, $t2vl13);
$mcl2->addEdge($t2vl1, $t2vl3);
$mcl2->addEdge($t2vl1, $t2vl5);
$mcl2->addEdge($t2vl14, $t2vl15);
$mcl2->addEdge($t2vl9, $t2vl10);
$mcl2->addEdge($t2vl9, $t2vl13);
$mcl2->addEdge($t2vl10, $t2vl11);
$mcl2->addEdge($t2vl10, $t2vl13);
$mcl2->addEdge($t2vl4, $t2vl8);
$mcl2->addEdge($t2vl5, $t2vl6);
$mcl2->addEdge($t2vl11, $t2vl12);
$mcl2->addEdge($t2vl14, $t2vl16);
$mcl2->addEdge($t2vl15, $t2vl16);
$mcl2->addEdge($t2vl3, $t2vl7);
$mcl2->addEdge($t2vl4, $t2vl7);

my $t2clusters = $mcl2->run();
ok(3 == scalar @$t2clusters, "numbers of clusters 3");
my $t2sortedClusters = sortBySize( $t2clusters );
my $t2cluster1 = $t2sortedClusters->[0];
my $t2cluster2 = $t2sortedClusters->[1];
my $t2cluster3 = $t2sortedClusters->[2];

ok(includeVertex($t2cluster1, $t2vl14) > 0, "t2 vertex is not in cluster - 1");
ok(includeVertex($t2cluster1, $t2vl15) > 0, "t2 vertex is not in cluster - 2");
ok(includeVertex($t2cluster1, $t2vl16) > 0, "t2 vertex is not in cluster - 3");

ok(includeVertex($t2cluster2, $t2vl8) > 0, "t2 vertex is not in cluster - 4");
ok(includeVertex($t2cluster2, $t2vl9) > 0, "t2 vertex is not in cluster - 5");
ok(includeVertex($t2cluster2, $t2vl10) > 0, "t2 vertex is not in cluster - 6");
ok(includeVertex($t2cluster2, $t2vl11) > 0, "t2 vertex is not in cluster - 7");
ok(includeVertex($t2cluster2, $t2vl12) > 0, "t2 vertex is not in cluster - 8");
ok(includeVertex($t2cluster2, $t2vl13) > 0, "t2 vertex is not in cluster - 9");

ok(includeVertex($t2cluster3, $t2vl1) > 0, "t2 vertex is not in cluster - 10");
ok(includeVertex($t2cluster3, $t2vl2) > 0, "t2 vertex is not in cluster - 11");
ok(includeVertex($t2cluster3, $t2vl3) > 0, "t2 vertex is not in cluster - 12");
ok(includeVertex($t2cluster3, $t2vl4) > 0, "t2 vertex is not in cluster - 13");
ok(includeVertex($t2cluster3, $t2vl5) > 0, "t2 vertex is not in cluster - 14");
ok(includeVertex($t2cluster3, $t2vl6) > 0, "t2 vertex is not in cluster - 15");
ok(includeVertex($t2cluster3, $t2vl7) > 0, "t2 vertex is not in cluster - 16");



done_testing;


sub sortBySize {
  my ( $clrs ) = @_;
  my @sClrs = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, scalar @$_] } @$clrs;
  return \@sClrs;
}


sub includeVertex {
  my ( $clr, $vl) = @_;
  foreach my $vrtx ( @$clr )
    {
      if ( $$vrtx eq $$vl)
	{
	  return 1;
	}
    }
  return 0;
}

