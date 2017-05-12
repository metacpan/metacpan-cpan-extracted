
use strict;
use warnings;

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, have_lwp;

my $head = GET_HEAD "/test3.cs";
ok($head, qr!Content-Type: text/html; charset=utf-8!);
