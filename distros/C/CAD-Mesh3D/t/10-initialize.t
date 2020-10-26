use strict;
use warnings;
use Test::More;
#use Data::Dumper;

use CAD::Mesh3D ':all';

################################################################
# valid initialization
################################################################
my $v123 = createVertex(1,2,3);
isa_ok( $v123, 'CAD::Mesh3D::Vertex', 'createVertex(1,2,3)' );
isa_ok( $v123, 'Math::Vector::Real', 'createVertex(1,2,3)' );
is_deeply( [@$v123], [1,2,3], 'createVertex(1,2,3)') or diag "\texplain: ", explain $v123;
is( getx($v123), 1, '[1,2,3]->getx()');
is( gety($v123), 2, '[1,2,3]->gety()');
is( getz($v123), 3, '[1,2,3]->getz()');

my $v000 = createVertex(0,0,0);
my $v111 = createVertex(1,1,1);
my $t = createFacet($v123, $v000, $v111);
isa_ok( $t, 'CAD::Mesh3D::Facet', 'createFacet([1,2,3], [0,0,0], [1,1,1])' );
isa_ok( $t, 'ARRAY', 'createFacet([1,2,3], [0,0,0], [1,1,1])' );
is_deeply( $t->[0], $v123, 'createFacet([1,2,3], [0,0,0], [1,1,1]) vertex-0' ) or diag "\texplain: ", explain $t;
is_deeply( $t->[1], $v000, 'createFacet([1,2,3], [0,0,0], [1,1,1]) vertex-1' ) or diag "\texplain: ", explain $t;
is_deeply( $t->[2], $v111, 'createFacet([1,2,3], [0,0,0], [1,1,1]) vertex-2' ) or diag "\texplain: ", explain $t;

my $vN1N = createVertex(-1,1,-1);
my ($q1, $q2) = createQuadrangleFacets( $v000, $v111, $v123, $vN1N );
is_deeply( $q1->[0], $v000, 'createQuadrangleFacet([0,0,0], [1,1,1], [1,2,3], [-1,1,-1]): facet-1 vertex-0') or diag "\texplain first:  ", explain $q1;
is_deeply( $q1->[1], $v111, 'createQuadrangleFacet([0,0,0], [1,1,1], [1,2,3], [-1,1,-1]): facet-1 vertex-1') or diag "\texplain first:  ", explain $q1;
is_deeply( $q1->[2], $v123, 'createQuadrangleFacet([0,0,0], [1,1,1], [1,2,3], [-1,1,-1]): facet-1 vertex-2') or diag "\texplain first:  ", explain $q1;

is_deeply( $q2->[0], $v000, 'createQuadrangleFacet([0,0,0], [1,1,1], [1,2,3], [-1,1,-1]): facet-2 vertex-0') or diag "\texplain second: ", explain $q2;
is_deeply( $q2->[1], $v123, 'createQuadrangleFacet([0,0,0], [1,1,1], [1,2,3], [-1,1,-1]): facet-2 vertex-1') or diag "\texplain second: ", explain $q2;
is_deeply( $q2->[2], $vN1N, 'createQuadrangleFacet([0,0,0], [1,1,1], [1,2,3], [-1,1,-1]): facet-2 vertex-2') or diag "\texplain second: ", explain $q2;

my $m = createMesh();
isa_ok( $m, 'CAD::Mesh3D', 'createMesh()' );
isa_ok( $m, 'ARRAY', 'createMesh()' );
is_deeply( $m, [], 'empty mesh initialization');

$m = createMesh($t, $q1, $q2);
isa_ok( $m, 'ARRAY', 'createMesh()' );
is( scalar @$m, 3 , 'createMesh(t,q1,q2) should have 3 elements');
is_deeply( $m->[0],  $t, 'createMesh(): mesh.facet-0 == t');
is_deeply( $m->[1], $q1, 'createMesh(): mesh.facet-1 == q1');
is_deeply( $m->[2], $q2, 'createMesh(): mesh.facet-2 == q2');

my $v456 = createVertex(4,5,6);
my $q3 = createFacet($v111, $v123, $v456);
my $q4 = createFacet($v123, $v111, $v456);
addToMesh($m, $q3);     # functional
$m->addToMesh($q4);     # object-oriented
is( scalar @$m, 5, 'addToMesh(): mesh should have 5 elements now');
is_deeply( $m->[0],  $t, 'addToMesh(): mesh.facet-0 == t');
is_deeply( $m->[1], $q1, 'addToMesh(): mesh.facet-1 == q1');
is_deeply( $m->[2], $q2, 'addToMesh(): mesh.facet-2 == q2');
is_deeply( $m->[3], $q3, 'addToMesh(): mesh.facet-3 == q3');
is_deeply( $m->[4], $q4, 'addToMesh(): mesh.facet-4 == q4');

done_testing();