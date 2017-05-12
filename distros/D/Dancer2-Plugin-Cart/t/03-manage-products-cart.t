#perl

use strict;
use warnings;
use Test::More;
use Plack::Test;
use Dancer2;
use HTTP::Request::Common;
use File::Temp qw(tempfile);
use HTTP::Cookies;

use t::lib::TestApp;
t::lib::TestApp::set plugins => {
    'Cart' => {
			'product_list' => [
			{
							'ec_sku' => 'SU01',
							'ec_price' => 10,
			},
			{
							'ec_sku' => 'SU02',
							'ec_price' => 15,
			},
			{
							'ec_sku' => 'SU03',
							'ec_price' => 20,
			},
			]
    },
};

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $jar = HTTP::Cookies->new;
my $site = "http://localhost";

my $req = GET $site . '/cart/new/'; 
my $res = $test->request( $req );
$jar->extract_cookies($res);

subtest 'adding existing product' => sub {
  my $req = POST $site . '/cart/add_product', [ 'ec_sku' => "SU01", 'ec_quantity' => '1' ];
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );
  like(
      $res->content, qr/SU01/,'Get content for /cart/add_product/SU01'
  );
};

subtest 'adding existing product on cart' => sub {
  my $req = POST $site . '/cart/add_product', [ 'ec_sku' => "SU01", 'ec_quantity' => '7' ];
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  like(
      $res->content, qr/'ec_quantity'\s=>\s8/,'Get content for /cart/add_product/SU01'
  );
};

subtest 'getting products' => sub {

  my $req = POST $site . '/cart/add_product', [ 'ec_sku' => "SU02", 'ec_quantity' => '1' ];
  $jar->add_cookie_header( $req );
  $test->request( $req );

  $req = GET $site . '/cart/products';
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );
  like(
    $res->content,qr/SU01/, 'Get an array of products with their info - check Product 1' 
  );

  like(
    $res->content,qr/SU02/, 'Get an array of products with their info - check Product 2' 
  );
};

subtest 'removing porducts' => sub {
  
  my $req = POST $site . '/cart/add_product', [ 'ec_sku' => "SU01", 'ec_quantity' => '-8' ];
  $jar->add_cookie_header( $req );
  $test->request( $req );
  $req = GET $site . '/cart/products';
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );
  unlike(
    $res->content,qr/SU01/, 'Get an array of products with their info - product 1 disappear' 
  );
  like(
    $res->content,qr/SU02/, 'Get an array of products with their info - product 2' 
  );

};



done_testing;
