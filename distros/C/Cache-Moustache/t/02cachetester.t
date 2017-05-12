# Cache::Moustache passes the test suite from Cache::Cache, except
# for namespace stuff, and class-wide methods.

use lib "lib";
use lib "t/lib";

use Cache::CacheTester;
use Cache::Moustache;

print "1..24\n";
Cache::CacheTester
	-> new( 1 )
	-> test( Cache::Moustache->new(clone_references => 1) );
