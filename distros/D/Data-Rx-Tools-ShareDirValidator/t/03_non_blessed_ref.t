use strict;
use warnings;

use Test::More 0.96;
use FindBin;
use Test::Fatal;

use lib "$FindBin::Bin/03_files/lib/";

use Test::File::ShareDir
  -root  => "$FindBin::Bin/03_files/",
  -share => { -module => { "Example" => 'share' } };

use Example;

# For coverage purposes.

isnt( exception { Example->can('check')->( {}, {} ) }, undef, 'Basic {} spec test with invalid self' );
isnt( exception { Example->can('check')->( {}, [] ) }, undef, 'Basic [] expected not ok spec test with invalid self' );

done_testing;

