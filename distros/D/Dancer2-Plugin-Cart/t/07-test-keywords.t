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

subtest 'getting quantity' => sub {

  my $req = POST $site . '/cart/add_product', [ 'ec_sku' => "SU01", 'ec_quantity' => '1' ];
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );

  $req = POST $site . '/cart/add_product', [ 'ec_sku' => "SU01", 'ec_quantity' => '7' ];
  $jar->add_cookie_header($req);
  $res = $test->request( $req );

  $req = GET $site . '/cart/quantity';
  $jar->add_cookie_header( $req );
  $res = $test->request( $req );
  like(
    $res->content,qr/8/, 'The cart has 8 items' 
  );
};

done_testing;
