use warnings;
use strict;

use Test::More;
use Test::Exception;
use HTTP::Request::Common;
use CatalystX::Test::MockContext;
use FindBin;
use lib "t/lib";
use MyApp;

{
  my $myapp = mock_context('MyApp');
  my $c     = $myapp->( GET '/' );
  isa_ok($c, 'MyApp');
  lives_ok { $c->stash } 'has stash';
  is($c->req->path, '');
  $c->dispatch;
  is($c->stash->{count}, 1);
  is($c->res->body, 'root');
  $c = $myapp->( GET '/foo' );
  isa_ok($c, 'MyApp');
  is($c->req->path, 'foo');
  is($c->req->method, 'GET');
}

{
  my $otherapp = mock_context('OtherApp');
  my $c     = $otherapp->( GET '/foo' );
  isa_ok($c, 'OtherApp');
  is($c->req->path, 'foo');
  is($c->req->method, 'GET');
}

done_testing();
