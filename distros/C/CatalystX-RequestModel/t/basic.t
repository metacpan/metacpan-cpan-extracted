BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90090; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
}

use Test::Lib;
use HTTP::Request::Common;
use Catalyst::Test 'Example';

ok my $body_parameters = [
  username => 'jjn',
  password => 'abc123',
];

{
  ok my $res = request POST '/root/test1', $body_parameters;
  ok my $data = eval $res->content;
  is $data->{username}, 'jjn';
  is $data->{password}, 'abc123';  
}

{
  ok my $res = request POST '/root/test2', $body_parameters;
  ok my $data = eval $res->content;
  is $data->{username}, 'jjn';
  is $data->{password}, 'abc123';  
}

{
  ok my $res = request POST '/root/test22', $body_parameters;
  ok my $data = eval $res->content;
  is $data->{username}, 'jjn';
  is $data->{password}, 'abc123';  
}

{
  ok my $res = request POST '/root/test222', $body_parameters;
  ok my $data = eval $res->content;
  is $data->{username}, 'jjn';
  is $data->{password}, 'abc123';  
}

{
  ok my $res = request GET '/root/test3?username=jjn;password=abc123';
  ok my $data = eval $res->content;
  is $data->{username}, 'jjn';
  is $data->{password}, 'abc123';  
}

{
  ok my $res = request GET '/root/test4?username=jjn;password=abc123';
  ok my $data = eval $res->content;
  is $data->{username}, 'jjn';
  is $data->{password}, 'abc123';  
}

{
  ok my $res = request GET '/root/test44?username=jjn;password=abc123';
  ok my $data = eval $res->content;
  is $data->{username}, 'jjn';
  is $data->{password}, 'abc123';  
}

{
  ok my $res = request GET '/root/test444?username=jjn;password=abc123';
  ok my $data = eval $res->content;
  is $data->{username}, 'jjn';
  is $data->{password}, 'abc123';  
}

{
  ok my $res = request POST '/root/omit', [aaa=>111];
  ok my $data = eval $res->content;

  is_deeply $data->{omit_array}, [];
  is_deeply $data->{omit_scalar}, undef;  
}

done_testing;