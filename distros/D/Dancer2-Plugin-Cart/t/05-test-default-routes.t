#perl

use strict;
use warnings;
use Test::More;
use Plack::Test;
use Dancer2;
use HTTP::Request::Common;
use HTTP::Cookies;
use Data::Dumper;

use t::lib::TestApp1;

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $site = "http://localhost";

my $jar = HTTP::Cookies->new;


subtest 'list products' => sub {
  my $req = GET $site . '/products';
  my $res = $test->request( $req );
  like(
    $res->content, qr/SU01/,'Get content /products'
  );
  like(
    $res->content, qr/SU02/,'Get content /products'
  );
  like(
    $res->content, qr/SU03/,'Get content /products'
  );
  $jar->extract_cookies($res);
};

subtest 'Add product' => sub {
  my $req = POST $site . '/cart/add', [ 'ec_sku' => "SU03", 'ec_quantity' => '1' ];
  $jar->add_cookie_header($req);
  my $res = $test->request( $req );
  is(
    $res->{_rc}, '302','Get content /cart'
  );
  like(
    $res->headers->{location}, qr/cart/, 'Redirect to /cart'
  );

  $req = GET $site . '/cart';
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  like(
    $res->content, qr/SU03/, 'Cart has SU03'
  );  

  $req = POST $site . '/cart/add', [ 'ec_sku' => "SU03", 'ec_quantity' => '1' ];
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  $req = GET $site . '/cart';
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  like(
    $res->content, qr/>2</, 'Cart has SU03 with 2 items'
  );
};

subtest "hooks add product" => sub {
  my $req = POST $site . '/cart/add', [ 'ec_sku' => "SU01", 'ec_quantity' => '1' ];
  $jar->add_cookie_header($req);
  my $res = $test->request( $req );
  $req = GET $site . '/cart';
  $jar->add_cookie_header($req);
  $res = $test->request( $req );
  like(
    $res->content, qr/>SUNN</, 'Cart has SUNN'
  );
  like(
    $res->content, qr/<td>-1<\/td>/, 'Cart has SUNN with price -1'
  );
};


subtest 'Shipping info' => sub {
  my $req = GET $site.'/cart/shipping';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '200','Get content /cart/shipping'
  );

  $req = POST $site.'/cart/shipping'; 
  $jar->add_cookie_header( $req );
  $res = $test->request ( $req ); 
  is( $res->{_rc}, '302','Redirect to get /cart/shipping');
  like(
    $res->request->uri, qr/shipping/, 'Validates redirects location to shipping'
  );

  $req = POST $site.'/cart/shipping', [ 'ship_mode' => "2" ];
  $jar->add_cookie_header( $req );
  $res = $test->request ( $req );
  is(
    $res->{_rc}, '302','Validation redirects to Billing Info'
  );
  like(
    $res->headers->{location}, qr/billing/, 'Validates redirects location to billing info'
  );
};


subtest 'Billing info' => sub {
  my $req = GET $site.'/cart/billing';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '200','Get content /cart/billing'
  );

  $req = POST $site.'/cart/billing', [ 'billing_name' => "1" ];
  $jar->add_cookie_header( $req );
  $res = $test->request ( $req );
  is(
    $res->{_rc}, '302','Validation redirects to Billing Info'
  );
  like(
    $res->headers->{location}, qr/review/, 'Validates redirects location to review'
  );
};

subtest 'Review info' => sub {
  my $req = GET $site.'/cart/review';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '200','Get content /cart/review'
  );
  
  like(
    $res->content, qr/Discounts/, 'Discounts adjustments are on the review info'
  );
  like(
    $res->content, qr/Shipping/, 'Shipping adjustments are on the review info'
  );
  like(
    $res->content, qr/Taxes/, 'Taxes adjustments are on the review info'
  );
};

subtest 'Place Order' => sub {
  my $req = POST $site.'/cart/checkout';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '302','Checkout process'
  );

};

subtest 'Receipt' => sub {
  my $req = GET $site.'/cart/receipt';
  $jar->add_cookie_header( $req );
  my $res = $test->request ( $req );
  is(
    $res->{_rc}, '200','Get content /cart/receipt'
  );
  like(
    $res->content, qr/Receipt #: /, 'Receipt number is on the review info'
  );

};

done_testing();
