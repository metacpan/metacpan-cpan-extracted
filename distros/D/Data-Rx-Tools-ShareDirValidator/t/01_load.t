use strict;
use warnings;

use Test::More 0.96;
use FindBin;

use lib "$FindBin::Bin/01_files/lib/";

use Test::File::ShareDir
  -root  => "$FindBin::Bin/01_files/",
  -share => { -module => { "Example" => 'share' } };

use Example;

ok( Example->check( {} ), 'Basic {} spec test' );
ok( !Example->check( [] ), 'Basic [] expected not ok spec test' );

# For coverage purposes.

my $obj = bless {}, 'Example';

ok( $obj->check( {} ), 'Basic {} spec test' );
ok( !$obj->check( [] ), 'Basic [] expected not ok spec test' );

done_testing;

