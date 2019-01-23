
use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test 'MyApp';
use Test::Most;

{
  ok my $res = request '/test';
  is $res->code, 200;
  is $res->content, 'test';
}

done_testing;
