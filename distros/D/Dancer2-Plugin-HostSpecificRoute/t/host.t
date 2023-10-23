use Test2::V0;
use Test2::Plugin::NoWarnings;
use Test2::Plugin::Times;
use Test::WWW::Mechanize::PSGI;

plan(9);

{
    package MyApp;

    use lib 't/lib';

    use Dancer2;
    use Dancer2::Plugin::HostSpecificRoute;

    set show_errors => 1;
    set traces      => 1;

    get '/string' => sub {
      send_as html => 'Boo!';
    };

    get '/file' => host 'howdy.test' => sub {
      send_as html => 'Howdy!';
    };

    get '/helper' => host qr/.*\.match.test$/ => sub {
      send_as html => 'Bizz!';
    };

    get '/helper' => sub {
      send_as html => 'Buzz!';
    };
}

my $mech = Test::WWW::Mechanize::PSGI->new( app => MyApp->to_app );

my $res;
$mech->get_ok('/string', 'Able to do a get from the app.');
$mech->content_contains('Boo!', 'GET content correct.');

$mech->get_ok('http://howdy.test/file', 'GET with specific host.');
$mech->content_contains('Howdy!', 'Specific host content correct.');

$res = $mech->get( 'http://wronghost.test/file');
ok( $res->code == 404, 'GET with wrong host and no fallback fails.');

$mech->get_ok('http://foo.match.test/helper', 'GET on regex success.');
$mech->content_contains('Bizz!', 'regex-success content correct.');

$mech->get_ok( 'http://wronghost.test/helper', 'Regex fail falls through to default.');
$mech->content_contains('Buzz!', 'Default route content correct.');

exit;