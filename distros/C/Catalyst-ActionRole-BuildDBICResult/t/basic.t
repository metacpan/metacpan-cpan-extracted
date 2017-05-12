use strict;
use warnings;
use Test::More;

use_ok 'Catalyst::ActionRole::BuildDBICResult';

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok 'TestApp';

done_testing;
