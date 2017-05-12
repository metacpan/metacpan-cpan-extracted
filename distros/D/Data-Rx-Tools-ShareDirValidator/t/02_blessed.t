use strict;
use warnings;

use Test::More 0.96;
use FindBin;

use lib "$FindBin::Bin/02_files/lib/";

use Test::File::ShareDir
  -root  => "$FindBin::Bin/02_files/",
  -share => { -module => { "Example" => 'share' } };

use Example;

# For coverage purposes.

my $obj = bless {}, 'Example';

ok( $obj->check( {} ), 'Basic {} spec test' );
ok( !$obj->check( [] ), 'Basic [] expected not ok spec test' );

done_testing;

