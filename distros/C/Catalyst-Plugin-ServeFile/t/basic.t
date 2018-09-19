
use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test 'MyApp';
use Test::Most;

{
  ok my $res = request '/test';
  is $res->code, 200;
  is $res->content_type, 'text/plain';
  like $res->content,qr/package MyApp;/;
}

{
  ok my $res = request '/test_404';
  is $res->code, 404;
  is $res->content_type, 'text/plain';
  like $res->content,qr/package MyApp;/;
}

{
  ok my $res = request '/static/a/a.txt';
  is $res->code, 200;
  is $res->content_type, 'text/plain';
  like $res->content,qr/package MyApp;/;
}

{
  ok my $res = request '/static/a/b.txt';
  is $res->code, 200;
  is $res->content_type, 'text/plain';
  like $res->content,qr/package MyApp;/;
}

{
  ok my $res = request '/static/a/c.txt';
  is $res->code, 200;
  is $res->content_type, 'text/plain';
  like $res->content,qr/package MyApp;/;
}

{
  ok my $res = request '/static/a/d.txt';
  is $res->code, 404;
  like $res->content,qr/Not Found/;
}

{
  ok my $res = request '/absolute';
  is $res->code, 404;
  like $res->content,qr/Not Found/;
}

done_testing;

