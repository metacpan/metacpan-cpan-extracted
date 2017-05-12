use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use HTTP::Tiny;
use Plack::Test;
use HTTP::Request::Common;

HTTP::Tiny->new->get("http://google.com/")->{success}
  or plan skip_all => "google.com not available";

{
  package Test::Adapter::HttpTiny;
  use Dancer2;
  use Dancer2::Plugin::Adapter;

  set show_errors => 1;

  set plugins => {
    Adapter => {
      http => {
        class   => 'HTTP::Tiny',
        options => { max_redirect => 10 },
      },
    },
  };

  get '/' => sub {
    ::diag "in /";
    return "Hello World";
  };

  get '/proxy' => sub {
    my $response = service("http")->get("http://google.com/");
    return $response->{content};
  };
}

my $test = Plack::Test->create( Test::Adapter::HttpTiny->to_app );

my $res = $test->request( GET '/proxy');
ok $res->is_success, "Request success";
like $res->content, qr/google/i, "HTTP::Tiny got proxy response";

done_testing;
# COPYRIGHT
