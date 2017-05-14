use strictures 1;
use Test::More;
use lib 't/lib';
use AuthServer;
use ClientApp;
use Plack::Builder;

use Test::WWW::Mechanize::PSGI;

my $auth_app = AuthServer->psgi_app;
my $main_app = ClientApp->psgi_app;
my $app      = builder {
  mount 'http://authserver/' => $auth_app;
  mount 'http://resourceserver/' => $auth_app;
  mount 'http://localhost/' => $main_app;
};

my $mech = $CatalystX::OAuth2::Client::UA =
  Test::WWW::Mechanize::PSGI->new( app => $app );

my $res = $mech->get('http://localhost/gold');

is( $res->content, '' );

$res = $mech->get('http://localhost/auth');
is( $res->content, '' ); # in a real app we display a form

my $uri = $res->request->uri;
$uri->query_form($uri->query_form, approved => 1); # simulate form submission
$res = $mech->get($uri);

is($res->content, 'auth ok');

$res = $mech->get('http://localhost/lead');
is( $res->content, 'ok', 'fetch non-protected resource' );

$res = $mech->get('http://localhost/gold');
ok( $res->is_success );
is( $res->content, 'gold' );

done_testing();
