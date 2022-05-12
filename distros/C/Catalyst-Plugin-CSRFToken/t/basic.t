
use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test 'MyApp';
use Test::Most;
use HTTP::Request::Common;

{
  ok my $res = request '/get';
  ok my $token = $res->content;
  {
    ok my $res = request POST '/test', [csrf_token => $token];
    is $res->content, 'ok';
  }
}

{
  ok my $res = request POST '/test', [csrf_token => 'badddd'];
  is $res->content, 'Bad Request';
}

{
  ok my $res = request '/in_session';
  ok my $token = $res->content;
  {
    ok my $res = request POST '/test', [csrf_token => $token];
    is $res->content, 'ok';
  }
  {
    ok my $res = request POST '/test', [csrf_token => $token]; # SHouldn't work the second time
    is $res->content, 'Bad Request';
  }
}

done_testing;

