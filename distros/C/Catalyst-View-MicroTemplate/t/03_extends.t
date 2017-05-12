use strict;
use warnings;
use Test::More tests => 6;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $view = 'AppConfig';

my $prefix = "Hello, your message was decorated as Hiiiii Deee Hoo, ";

my $response;
ok(($response = request("/test_extends?view=$view"))->is_success, 'request ok');
is($response->content, $prefix . TestApp->config->{default_message} . "\n", 'message ok');

my $message = scalar localtime;
ok(($response = request("/test_extends?view=$view&message=$message"))->is_success, 'request with message ok');
is($response->content_type, 'text/html', 'content_type ok' );
is($response->content, "$prefix$message\n", 'message ok')