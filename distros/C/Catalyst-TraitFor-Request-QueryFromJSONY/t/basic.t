BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90093; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
}

{
  package MyApp::Controller::Root;
  use base 'Catalyst::Controller';
  use Data::Dumper;

  sub echo :Local {
    my ($self, $c) = @_;
    my $data;
    if(my $param = $c->req->query_parameters->{jsony}) {
      $data = Dumper $c->req->query_data($param);
    } else {
      $data = Dumper $c->req->query_data({
          parse_error=>sub { return +{err=>"can't parse $_[1]"} }});
    }

    $c->res->body($data);
  }

  sub many :Local {
    my ($self, $c) = @_;
    my $data = Dumper [$c->req->query_data(qw/a b c/)];
    $c->res->body($data);
  }

  sub many2 :Local {
    my ($self, $c) = @_;
    my $data = Dumper [
      $c->req->query_data(qw/a b c/, +{ 
        param_missing => sub {
          my ($req, $key) = @_;
          return '[]';
        },
      })
    ];
    $c->res->body($data);
  }


  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  package MyApp;
  use Catalyst;
  
  MyApp->request_class_traits(['QueryFromJSONY']);
  MyApp->setup;
}

use HTTP::Request::Common;
use Catalyst::Test 'MyApp';
use utf8;

{
  ok my $res = request GET "/root/echo?q=foo bar baz ♥";
  is_deeply eval $res->content, [qw/foo bar baz ♥/];
}

{
  ok my $res = request GET "/root/echo?q=['foo','bar','baz']";
  is_deeply eval $res->content, [qw/foo bar baz/];
}

{
  ok my $res = request GET "/root/echo?q={'id':100,'age':['>',10]}";
  is_deeply eval $res->content, {
    'id' => 100,
    'age' => [ '>', 10 ]
  };
}

{
  ok my $res = request GET "/root/echo?jsony=z&z={'id':100,'age':['>',10]}";
  is_deeply eval $res->content, {
    'id' => 100,
    'age' => [ '>', 10 ]
  };
}

{
  ok my $res = request GET "/root/many?a={'id':100,'age':['>',10]}&b=['foo','bar','baz']";
  is_deeply eval $res->content, [
    {
      'id' => 100,
      'age' => [ '>', 10 ]
    },
    [qw/foo bar baz/],
    {},
  ];
}

{
  ok my $res = request GET "/root/many2?a={'id':100,'age':['>',10]}&b=['foo','bar','baz']";
  is_deeply eval $res->content, [
    {
      'id' => 100,
      'age' => [ '>', 10 ]
    },
    [qw/foo bar baz/],
    [],
  ];
}

{
  ok my $res = request GET "/root/echo?q={f : }d}";
  is_deeply eval $res->content, {'err' => 'can\'t parse {f : }d}'};
}


done_testing;
