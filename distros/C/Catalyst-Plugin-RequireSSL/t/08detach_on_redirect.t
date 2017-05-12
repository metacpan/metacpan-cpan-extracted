#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 4;
use Catalyst::Test 'TestApp';

{
  TestApp->config->{require_ssl}->{detach_on_redirect} = 0;

  # test an SSL redirect
  ok( my $res = request('http://localhost/ssl/test_detach'), 'request ok' );
  is( $res->header('location'), 'http://www.mydomain.com/redirect_from_the_action',
    'the action did the redirect after $c->require_ssl'
  );
}

{
  TestApp->config->{require_ssl}->{detach_on_redirect} = 1;

  # test an SSL redirect
  ok( my $res = request('http://localhost/ssl/test_detach'), 'request ok' );
  is( $res->header('location'), 'https://localhost/ssl/test_detach',
    'the action finished in $c->require_ssl'
  );
}
