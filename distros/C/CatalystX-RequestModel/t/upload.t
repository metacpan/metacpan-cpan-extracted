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
  ok my $body_parameters = [
    notes => 'This is the file you seek!',
    file =>[ undef, 'file.txt', Content => 'the file info' ]
  ];

  ok my $res = request POST '/upload',
    Content_Type => 'form-data',
    Content => $body_parameters;

  ok my $data = eval $res->content;  

  is $data->{notes}, 'This is the file you seek!';
  is $data->{file}, 'the file info';
}

done_testing;
