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
  ok my $res = request GET '/info2?page=10;offset=100;search=nope';
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

  ok my $res = request POST '/postinfo2?page=10;offset=100;search=nope',$body_parameters;
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

{
  ok my $res = request GET '/info3?user.page=10;user.offset=100;user.search=nope';
  ok my $data = eval $res->content;  
  is_deeply $data, +{
    page=>10,
    offset=>100,
    search=>'nope'
  };
}

{
  ok my $res = request GET '/info2';
  ok my $data = eval $res->content;  
  is_deeply $data, +{ };
}

{
  ok my $res = request GET '/info3';
  ok my $data = eval $res->content;  
  is_deeply $data, +{};
}

done_testing;

