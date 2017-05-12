use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 4, have_lwp;

my $url = '/multi/';

my $response = GET $url;

ok $response->code == 401;
my @Authenticate = $response->header('WWW-Authenticate');
ok(@Authenticate == 2);
ok($Authenticate[0] eq qq!Basic realm="cookbook"!);
ok($Authenticate[1] =~ m/Digest realm="cookbook", nonce="[0-9]+"/);
