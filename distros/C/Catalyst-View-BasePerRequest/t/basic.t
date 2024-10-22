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
        wrapped <!-- 111 --><style>...</style><!-- 222 --> end wrap
      </head>
      <body><div>Hello prepared_joe!</div><div>Hello prepared_jon!</div><div>Hello prepared_John!</div>: one, nope</body>
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
  is $res->code, 400;
}

{
  ok my $res = request '/test4';
  is $res->content, $expected;
}

{
  ok my $res = request '/test5';
  is $res->content, $expected;
  is $res->code, 201;
  is $res->headers->header('location'), 'abc';
}

{
  ok my $res = request '/test6';
  is $res->content, $expected;
  is $res->code, 201;
  is $res->headers->header('location'), 'abc';
}

{
  ok my $factory = Example->view('Hello');
  is $factory->app, 'Example';
  is $factory->class, 'Example::View::Hello';
  is_deeply $factory->merged_args, +{
    catalyst_component_name => "Example::View::Hello",
    content_type => "text/html",
    from_config => "now",
    status_codes => {
      200 => 1,
      201 => 1,
      400 => 1,
    },
  };
}

done_testing
