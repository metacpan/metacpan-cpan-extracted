use Test::More tests => 2;
BEGIN { use_ok('Catalyst::Controller::SOAP') };
use Catalyst::Action::SOAP::DocumentLiteral;
use lib qw(t/lib);
use Catalyst::Test 'TestApp';
use Encode;

my $response_content = get('/ws/foo?who=World');
ok($response_content =~ /Hello World/, 'Hello World!');

