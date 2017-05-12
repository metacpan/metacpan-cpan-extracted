use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::Most;
use Catalyst::Test 'MyApp';

{
  ok my ($res, $ctx)
  = ctx_request '/public/example.txt';
  is $res->code, 200;
  is $res->content, "example\n";
  is $res->content_length, 8;
  is $res->content_type, 'text/plain';
  is $ctx->uri_for( $ctx->controller('Public')->uri_args('example.txt')),
    'http://localhost/public/example.txt';
}

done_testing;
