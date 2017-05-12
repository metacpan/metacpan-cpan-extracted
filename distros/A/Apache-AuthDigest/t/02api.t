use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 4, have_lwp;

# most of this is taken right from 
# perl-framework/t/http11/basicauth.t
#
# many kudos to LWP for supporting Digest authentication natively!

my $url = '/protected/index.html';

my $response = GET $url;

ok $response->code == 401;

ok $response->header('WWW-Authenticate') =~ m/Digest realm="cookbook"/;

$response = GET $url, username => 'geoff', password => 'geoff';

ok $response->code == 200;

$response = GET $url, username => 'geoff', password => 'badpass';

ok $response->code == 401;
