#!perl

use strict;
use warnings;
use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $request = request('/comp_path?view=Comppath');
ok($request->is_success, 'request ok');
is($request->content, "param: bar\n", 'used /foo component');
