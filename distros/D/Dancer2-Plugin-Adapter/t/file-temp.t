use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use File::Temp 0.19; # newdir
use Plack::Test;
use HTTP::Request::Common;


{ # Test app
  package Test::Adapter::FileTemp;
  use Dancer2;
  use Dancer2::Plugin::Adapter;

  set show_errors => 0;

  set plugins => {
    Adapter => {
      tempdir => {
        class      => 'File::Temp',
        constructor => 'newdir',
      },
    },
  };

  get '/' => sub {
    if ( -d service("tempdir") ) {
      return 'Hello World';
    }
    else {
      return "Goodbye World";
    }
  };
}

my $test = Plack::Test->create( Test::Adapter::FileTemp->to_app );

my $res = $test->request( GET '/' );
ok( $res->is_success, "Request success" );
like $res->content, qr/Hello World/i, "Request content correct";

done_testing;
# COPYRIGHT
