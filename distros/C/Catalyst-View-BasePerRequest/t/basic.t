BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90090; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
}

use Test::Lib;
use Catalyst::Test 'Example';

my $expected = q[
    <html>
      <head>
        <title>Hello</title>
        <style>...</style>
      </head>
      <body><div>Hello John!</div>: one</body>
    </html>];

{
  ok my $res = request '/test1';
  is $res->content, $expected;
}

{
  ok my $res = request '/test2';
  is $res->content, $expected;
}

{
  ok my $res = request '/test3';
  is $res->content, $expected;
}

done_testing
