use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use Catalyst::Test 'TestApp2' ;

{
  is( request( 'http://localhost/test/scalar' )->content, 's3', 'test3' );
  is( request( 'http://localhost/test/array' )->content, '["bug3", "sweet3", "foobar3"]', 'test3' );
  is( request( 'http://localhost/test/hash' )->content, '{ foo => "bar3" }', 'test3' );
}

done_testing();
