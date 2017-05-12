use strict;
use warnings FATAL =>'all';

use FindBin;
use Test::More;
use HTTP::Request::Common 'GET';

use lib "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp';

is request(GET '/')->content, 'test';
is request(GET '/foo')->content, 'foo';
is request(GET '/root')->content, 'root_0';
is request(GET '/root/100')->content, 'root_1';
is request(GET '/root/foo/100')->content, 'root_foo_1';

is request(GET '/syntax')->content, 'syntax_root_0';
is request(GET '/syntax/100')->content, 'syntax_root_1';
is request(GET '/syntax/foo/100')->content, 'syntax_root_foo_1';

done_testing;
