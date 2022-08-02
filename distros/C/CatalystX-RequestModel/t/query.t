BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90090; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
}

use Test::Lib;
use HTTP::Request::Common;
use Catalyst::Test 'Example';

{
  ok my $res = request GET '/info?page=10;offset=100;search=nope';
  ok my $data = eval $res->content;  
  is_deeply $data, +{
    page=>10,
    offset=>100,
    search=>'nope'
  };
}

{
  ok my $body_parameters = [
    username => 'jjn',
    password => 'abc123',
  ];

  ok my $res = request POST '/postinfo?page=10;offset=100;search=nope',$body_parameters;
  ok my $data = eval $res->content;
  
  is_deeply $data, +{
    get => {
      offset => 100,
      page => 10,
      search => "nope",
    },
    post => {
      password => "abc123",
      username => "jjn",
    },
  };
}

done_testing;
