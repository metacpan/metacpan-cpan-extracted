use strict;
use Test::More;
use Test::Requires qw( Plack::Test HTTP::Request Plack::Middleware::Lint );
use Test::Requires {
    'Plack' => 0.9981,
};
use CGI::Emulate::PSGI;

my $output = <<CGI;
Status: 302
Content-Type: text/html
X-Foo: bar
Location: http://localhost/
Multiline: Foo
  bar baz

This is the body!
CGI

my $app = CGI::Emulate::PSGI->handler(sub { print $output });
$app = Plack::Middleware::Lint->wrap($app);

Plack::Test::test_psgi($app, sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(GET => "/"));
    is $res->code, 302;
});

done_testing;
