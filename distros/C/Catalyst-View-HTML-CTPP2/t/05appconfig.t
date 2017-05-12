use strict;
use warnings;

use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $view = 'Appconfig';

my $response;

my $cmp_message = TestApp->config->{default_message};
ok(($response = request("/test?view=$view"))->is_success, 'request ok');
like($response->content, qr/$cmp_message/, 'message ok');

my $message = scalar localtime;
ok(($response = request("/test?view=$view&message=$message"))->is_success,
    'request with message ok');
like($response->content, qr/$message/, 'message ok')
