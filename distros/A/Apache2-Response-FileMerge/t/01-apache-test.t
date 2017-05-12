
use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 2, \&need_lwp;
my $r = GET('/verify.js');

ok( $r->code() == 200 );
ok( $r->content() == 1 );
