use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, have_lwp;

my $body = GET_BODY "/test2.cs";
ok($body, qr/hello/);
