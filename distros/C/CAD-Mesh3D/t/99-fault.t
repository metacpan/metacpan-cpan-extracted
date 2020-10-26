use strict;
use warnings;
use Test::More tests => 45;
use Test::Exception;

use CAD::Mesh3D qw(+STL :all);

################################################################
# error handling
################################################################

# createVertex(): wrong number of coordinates
throws_ok { createVertex(); } qr/createVertex.*requires 3 coordinates; you supplied 0/, 'Error Handling: createVertex(no args)';
throws_ok { createVertex(1,2); } qr/createVertex.*requires 3 coordinates; you supplied 2/, 'Error Handling: createVertex(two args)';
throws_ok { createVertex(1..4); } qr/createVertex.*requires 3 coordinates; you supplied 4/, 'Error Handling: createVertex(four args)';

# createFacet(): wrong number of Vertexs
throws_ok { createFacet(); } qr/createFacet.*requires 3 Vertexes; you supplied 0/, 'Error Handling: createFacet(no args)';
throws_ok { createFacet(1..2); } qr/createFacet.*requires 3 Vertexes; you supplied 2/, 'Error Handling: createFacet(two args)';
throws_ok { createFacet(1..4); } qr/createFacet.*requires 3 Vertexes; you supplied 4/, 'Error Handling: createFacet(four args)';

# createFacet(): invalid Vertex
throws_ok { createFacet( undef, [0,0,0], [1,1,1]); } qr/createFacet.*each Vertex must be an array ref or equivalent object; you supplied a scalar"<undef>"/, 'Error Handling: createFacet(undef first  Vertex)';
throws_ok { createFacet( 1, [0,0,0], [1,1,1]); } qr/createFacet.*each Vertex must be an array ref or equivalent object; you supplied a scalar"1"/, 'Error Handling: createFacet(scalar first  Vertex)';
throws_ok { createFacet( {}, [0,0,0], [1,1,1]); } qr/createFacet.*each Vertex must be an array ref or equivalent object; you supplied "HASH"/, 'Error Handling: createFacet(wrong ref first  Vertex)';
throws_ok { createFacet( [1,2], [0,0,0], [1,1,1]); } qr/createFacet.*each Vertex requires 3 coordinates; you supplied 2/, 'Error Handling: createFacet(short first  Vertex)';
throws_ok { createFacet( [1..4], [0,0,0], [1,1,1]); } qr/createFacet.*each Vertex requires 3 coordinates; you supplied 4/, 'Error Handling: createFacet(long  first  Vertex)';
throws_ok { createFacet( [0,0,0], undef, [1,1,1]); } qr/createFacet.*each Vertex must be an array ref or equivalent object; you supplied a scalar"<undef>"/, 'Error Handling: createFacet(undef second Vertex)';
throws_ok { createFacet( [0,0,0], 'txt', [1,1,1]); } qr/createFacet.*each Vertex must be an array ref or equivalent object; you supplied a scalar"txt"/, 'Error Handling: createFacet(scalar second Vertex)';
throws_ok { createFacet( [0,0,0], \'sref', [1,1,1]); } qr/createFacet.*each Vertex must be an array ref or equivalent object; you supplied "SCALAR"/, 'Error Handling: createFacet(wrong ref second Vertex)';
throws_ok { createFacet( [0,0,0], [1,2], [1,1,1]); } qr/createFacet.*each Vertex requires 3 coordinates; you supplied 2/, 'Error Handling: createFacet(short second Vertex)';
throws_ok { createFacet( [0,0,0], [1..4], [1,1,1]); } qr/createFacet.*each Vertex requires 3 coordinates; you supplied 4/, 'Error Handling: createFacet(long  second Vertex)';
throws_ok { createFacet( [0,0,0], [1,1,1], undef); } qr/createFacet.*each Vertex must be an array ref or equivalent object; you supplied a scalar"<undef>"/, 'Error Handling: createFacet(undef third  Vertex)';
throws_ok { createFacet( [0,0,0], [1,1,1], 3); } qr/createFacet.*each Vertex must be an array ref or equivalent object; you supplied a scalar"3"/, 'Error Handling: createFacet(scalar third  Vertex)';
throws_ok { createFacet( [0,0,0], [1,1,1], \*STDIN); } qr/createFacet.*each Vertex must be an array ref or equivalent object; you supplied "GLOB"/, 'Error Handling: createFacet(wrong ref third  Vertex)';
throws_ok { createFacet( [0,0,0], [1,1,1], [1,2]); } qr/createFacet.*each Vertex requires 3 coordinates; you supplied 2/, 'Error Handling: createFacet(short third  Vertex)';
throws_ok { createFacet( [0,0,0], [1,1,1], [1..4]); } qr/createFacet.*each Vertex requires 3 coordinates; you supplied 4/, 'Error Handling: createFacet(long  third  Vertex)';

# createQuadrangleFacets(): wrong number of Vertexes
throws_ok { createQuadrangleFacets(); } qr/createQuadrangleFacets.*requires 4 Vertexes; you supplied 0/, 'Error Handling: createQuadrangleFacets(no args)';
throws_ok { createQuadrangleFacets(1..3); } qr/createQuadrangleFacets.*requires 4 Vertexes; you supplied 3/, 'Error Handling: createQuadrangleFacets(three args)';
throws_ok { createQuadrangleFacets(1..5); } qr/createQuadrangleFacets.*requires 4 Vertexes; you supplied 5/, 'Error Handling: createQuadrangleFacets(five args)';

# createMesh(): invalid triangle
throws_ok { createMesh( undef ); } qr/createMesh.*each triangle must be defined; this one was undef/, 'Error Handling: createMesh(undef triangle)';
throws_ok { createMesh( [] ); } qr/createMesh.*each triangle requires 3 Vertexes; you supplied 0/, 'Error Handling: createMesh(no Vertexs)';
throws_ok { createMesh( [1..2] ); } qr/createMesh.*each triangle requires 3 Vertexes; you supplied 2/, 'Error Handling: createMesh(two Vertexs)';
throws_ok { createMesh( [1..4] ); } qr/createMesh.*each triangle requires 3 Vertexes; you supplied 4/, 'Error Handling: createMesh(four Vertexs)';
throws_ok { createMesh( [undef, [0,0,0], [1,1,1]] ); } qr/createMesh.*each Vertex must be an array ref or equivalent object; you supplied a scalar"<undef>"/, 'Error Handling: createMesh(first  Vertex undef)';
throws_ok { createMesh( [1, [0,0,0], [1,1,1]] ); } qr/createMesh.*each Vertex must be an array ref or equivalent object; you supplied a scalar"1"/, 'Error Handling: createMesh(first  Vertex scalar)';
throws_ok { createMesh( [{}, [0,0,0], [1,1,1]] ); } qr/createMesh.*each Vertex must be an array ref or equivalent object; you supplied "HASH"/, 'Error Handling: createMesh(first  Vertex wrong ref)';
throws_ok { createMesh( [[], [0,0,0], [1,1,1]] ); } qr/createMesh.*each Vertex in each triangle requires 3 coordinates; you supplied 0/, 'Error Handling: createMesh(first  Vertex empty)';
throws_ok { createMesh( [[1..2], [0,0,0], [1,1,1]] ); } qr/createMesh.*each Vertex in each triangle requires 3 coordinates; you supplied 2/, 'Error Handling: createMesh(first  Vertex short)';
throws_ok { createMesh( [[1..4], [0,0,0], [1,1,1]] ); } qr/createMesh.*each Vertex in each triangle requires 3 coordinates; you supplied 4/, 'Error Handling: createMesh(first  Vertex long)';
throws_ok { createMesh( [[1,2,3], 2, [1,1,1]] ); } qr/createMesh.*each Vertex must be an array ref or equivalent object; you supplied a scalar"2"/, 'Error Handling: createMesh(second Vertex invalid)';
throws_ok { createMesh( [[1,2,3], [0,0,0], 3] ); } qr/createMesh.*each Vertex must be an array ref or equivalent object; you supplied a scalar"3"/, 'Error Handling: createMesh(third  Vertex invalid)';

# will need a valid mesh for the remaining output tests
my $lft = [sqrt( 0/12),sqrt(0/12),sqrt(0/12)];
my $rgt = [sqrt(12/12),sqrt(0/12),sqrt(0/12)];
my $mid = [sqrt( 3/12),sqrt(9/12),sqrt(0/12)];
my $top = [sqrt( 3/12),sqrt(1/12),sqrt(8/12)];
my $mesh = [[$lft, $mid, $rgt], [$lft, $rgt, $top], [$rgt, $mid, $top], [$mid, $lft, $top]];

# addToMesh():
throws_ok { addToMesh( undef ); } qr/addToMesh.*: mesh must have already been created/, 'Error Handling: addToMesh(undef): no mesh';
throws_ok { addToMesh( $mesh, undef ); } qr/addToMesh.*: each triangle must be an array ref or equivalent object; you supplied a scalar "<undef>"/, 'Error Handling: addToMesh(mesh, undef): no triangle(s)';
throws_ok { addToMesh( $mesh, 5 ); } qr/addToMesh.*: each triangle must be an array ref or equivalent object; you supplied a scalar "5"/, 'Error Handling: addToMesh(mesh, 5): scalar instead of triangle';
throws_ok { addToMesh( $mesh, {} ); } qr/addToMesh.*: each triangle must be an array ref or equivalent object; you supplied "HASH"/, 'Error Handling: addToMesh(mesh, {}): triangle is wrong kind of reference';
throws_ok { addToMesh( $mesh, [] ); } qr/addToMesh.*: each triangle requires 3 Vertexes; you supplied 0/, 'Error Handling: addToMesh(mesh, []): empty triangle';
throws_ok { addToMesh( $mesh, [$lft, $top, undef] ); } qr/addToMesh.*: each Vertex must be an array ref or equivalent object; you supplied a scalar "<undef>"/, 'Error Handling: addToMesh(mesh, [left, top, undef]): one vertex undef';
throws_ok { addToMesh( $mesh, [$lft, 7, $mid] ); } qr/addToMesh.*: each Vertex must be an array ref or equivalent object; you supplied a scalar "7"/, 'Error Handling: addToMesh(mesh, [left, scalar, middle]): one vertex scalar';
throws_ok { addToMesh( $mesh, [$lft, $top, {}] ); } qr/addToMesh.*: each Vertex must be an array ref or equivalent object; you supplied "HASH"/, 'Error Handling: addToMesh(mesh, [left, top, {}]): one vertex wrong reference type';
throws_ok { addToMesh( $mesh, [[], $top, $mid] ); } qr/addToMesh.*: each Vertex in each triangle requires 3 coordinates; you supplied 0/, 'Error Handling: addToMesh(mesh, [[], top, mid]): one vertex empty';

done_testing();