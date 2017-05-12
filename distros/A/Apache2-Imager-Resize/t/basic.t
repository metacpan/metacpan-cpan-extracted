#file:t/basic.t
#-----------
use strict;
use warnings FATAL => 'all';

use Apache2::Imager::Resize;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

plan tests => 1;

ok 1; # simple load test
