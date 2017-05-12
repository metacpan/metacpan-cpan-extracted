#perl

use strict;
use warnings;
use Test::More;
use Plack::Test;
use Dancer2;
use HTTP::Request::Common;
use HTTP::Cookies;

use lib File::Spec->catdir( 't', 'lib' );

use t::lib::TestApp;

t::lib::TestApp::set plugins => {
};

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $jar = HTTP::Cookies->new;
my $site = "http://localhost";

my $req = POST $site . '/cart/add_product', [ 'ec_sku' => "SU01", 'ec_quantity' => '7' ];
my $res = $test->request( $req );
$jar->extract_cookies( $res );
$req = POST $site . '/cart/add_product', [ 'ec_sku' => "SU02", 'ec_quantity' => '1' ];
$jar->add_cookie_header( $req );
$test->request( $req );

subtest 'Get subtotal' => sub {
  my $req =  GET $site . '/cart_';
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );
  like(
      $res->content, qr/SU01/,'Get content for /cart and check SU01'
  );

  like(
      $res->content, qr/SU02/,'Get content for /cart and check SU02'
  );
};

subtest 'Clearing cart' => sub {
  my $req = GET $site . '/cart/clear_cart/';
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );
  like(
      $res->content, qr/\[\]/,'Get content for /cart/clear_cart'
  );
};

done_testing();
