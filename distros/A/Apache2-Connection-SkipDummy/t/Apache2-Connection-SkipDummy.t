use strict;
use warnings FATAL => 'all';

use Apache::Test qw( -withtestmore );
use Apache::TestRequest qw(GET GET_OK);

plan tests => 1, need_lwp;

ok GET_OK '/';

