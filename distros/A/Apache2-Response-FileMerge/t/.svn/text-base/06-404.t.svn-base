
use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 1, \&need_lwp;
my $r = GET('/css/thatonejustainthere.css');

ok( $r->code() == 404 );
