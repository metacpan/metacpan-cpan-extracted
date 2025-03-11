
use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test 'MyApp';
use Test::Most;
use HTTP::Request::Common;

{
  ok my $res = request '/get';
  ok my $token = $res->content;
  {
    ok my $res = request POST '/test', [csrf_token2 => $token];
    is $res->content, 'ok';
  }
  {
    ok my $res = request POST '/test', [csrf_token2 => $token]; # Shouldn't work the second time
    is $res->content, 'Forbidden: Invalid CSRF token.';
  }
}

  {
    ok my $res = request POST '/skip';
    is $res->content, 'ok';
  }

{
  ok my $res = request '/config_test';
  my $VAR1; ok eval $res->content;

  is_deeply $VAR1, {
    'token_session_key' => '_csrf_token2',
    'max_age' => 8888,
    'default_secret' => 'begin',
    'token_param_key' => 'csrf_token2',
  };
}

done_testing;