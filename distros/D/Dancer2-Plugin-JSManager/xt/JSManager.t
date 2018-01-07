use strict;
use warnings;

BEGIN { $ENV{'DANCER_ENVIRONMENT'} = 'testing' }

use Test::More tests => 4;
use Plack::Test;
use HTTP::Request::Common;

{ package TestApp;
  use Dancer2;
  use Dancer2::Plugin::JSManager;

  get '/' => sub { return template 'index' };
}

my $test = Plack::Test->create( TestApp->to_app );
my $res = $test->request( GET '/' );

ok( $res->is_success, 'Successful request' );
like( $res->content, qr/function load_js.*<\/head>/s, 'Added fallback function to head' );
like( $res->content, qr/jquery-1.11.*<\/head>/s, 'Added jquery library to head' );
like( $res->content, qr/<body>.*jquery.growl/s, 'Added growler library to body' );
