#perl

use strict;
use warnings;
use Test::More;
use Plack::Test;
use Dancer2;
use HTTP::Request::Common;
use HTTP::Cookies;
use Data::Dumper;

use t::lib::TestApp2;

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);

my $site = "http://localhost";

my $jar = HTTP::Cookies->new;


subtest 'list products' => sub {
  my $req = GET $site . '/products';
  my $res = $test->request( $req );
  like(
    $res->content, qr/SU10/,'Get content /products'
  );
  $jar->extract_cookies($res);
};

done_testing();
