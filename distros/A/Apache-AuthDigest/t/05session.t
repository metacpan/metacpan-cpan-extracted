use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 7, have_lwp;

my $url = '/session/index.html';

my $response = GET "$url?init";

ok $response->code == 401;

ok $response->header('WWW-Authenticate') =~ m/nonce="e37f0136aa3ffaf149b351f6a4c948e9"/;

$response = GET "$url?session1", username => 'geoff', password => 'geoff';

ok $response->code == 200;

ok $response->request->header('Authorization') =~ m/nonce="43fd828731048cda3a0a050b22bed4f3"/;

$response = GET "$url?expired", username => 'geoff', password => 'geoff';

ok $response->code == 401;

$response = GET "$url?session2", username => 'newuser', password => 'newpass';

ok $response->code == 401;

ok $response->request->header('Authorization') =~ m/nonce="98432f23b96c8138c2606ef8bebc0a82"/;
