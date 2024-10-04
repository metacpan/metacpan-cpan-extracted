BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90090; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
}

use Test::Most;
use Test::Lib;
use HTTP::Request::Common;
use Catalyst::Test 'Example';

{
  ok my $res = request GET '/hello';
  ok my $data = $res->content; 
  is $data, '<form accept-charset="UTF-8" enctype="application/x-www-form-urlencoded" method="post">
<input id="person_name" name="person.name" type="text" value=""/>
<input id="person_age" name="person.age" type="text" value=""/>
</form>';
}

done_testing;
