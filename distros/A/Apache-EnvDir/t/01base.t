use strict;
use warnings FATAL => 'all';

use Apache::Test qw(plan ok have_lwp have_module);
use Apache::TestRequest qw(GET);
use Apache::TestUtil qw(t_cmp);

# test CleanLevel

plan tests => 1;

my $response = GET '/index.html';
ok ($response->code == 200);
