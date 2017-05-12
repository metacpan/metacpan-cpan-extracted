use strict;
use warnings;
use Test::More tests => 7;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $view = 'Pkgconfig';

my $response;
ok(($response = request("/test?view=$view"))->is_success, 'request ok');
is($response->content, TestApp->config->{default_message}, 'default message ok');

my $message = scalar localtime;
ok(($response = request("/test?view=$view&message=$message"))->is_success, 'request with message ok');
is($response->content,  $message, 'message ok');

ok(($response = request("/test?view=$view&message=override"))->is_success, 'request with override message ok');
is($response->content,  'Shoved in by around_template', 'override message ok');
