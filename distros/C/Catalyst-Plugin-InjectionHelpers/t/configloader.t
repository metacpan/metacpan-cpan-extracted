BEGIN {
  use Test::Most;
  eval "use Catalyst::Plugin::ConfigLoader; 1" || do {
    plan skip_all => "Need a Catalyst::Plugin::ConfigLoader.pm => $@";
  };
}

use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test 'MyApp';

{
  ok my $res = request '/test';
  is $res->code, 200;
  is $res->content, 'test';
}

done_testing;
