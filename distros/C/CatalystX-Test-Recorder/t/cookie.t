use Test::More;

use lib qw(t/lib);


use HTTP::Request::Common qw(GET HEAD PUT DELETE POST);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

my $response = $mech->request(GET '/cookie');
is($response->code, 200, 'setting cookie');


$response = $mech->request(GET '/cookie');
is($response->code, 404, 'cookie is set');
done_testing;