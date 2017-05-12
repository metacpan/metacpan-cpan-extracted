use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 4, have_lwp;

my $url = '/authz/index.html';

my $response = GET $url;

ok $response->code == 401;

ok $response->header('WWW-Authenticate') =~ m/Digest realm="flatfile"/;

$response = GET $url, username => 'geoff', password => 'geoff';

ok $response->code == 401;

$response = GET $url, username => 'test', password => 'test';

ok $response->code == 200;
