use strict;
use warnings;
use Test::More 0.89;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestAppGlobals';

is(get('/'), "tiger\n", 'Basic rendering with a scalar str globals arg' );

done_testing;

