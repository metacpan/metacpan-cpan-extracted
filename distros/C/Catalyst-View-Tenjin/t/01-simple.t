#!perl

use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;

ok(($response = request("/"))->is_success, 'default request okay');
is($response->content, "Amy, do you like magic?\n", 'default response okay');

ok(($response = request("/encoding"))->is_success, 'encoding request okay');
is($response->content, qq~<h1>העמוד בכתובת <a href="encoding" title="&lt;&quot;&gt;">encoding</a> אומר: מי שלא שותה לא משתין</h1>\n~, 'encoding response okay');

done_testing();
