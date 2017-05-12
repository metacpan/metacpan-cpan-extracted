use Test::More;

require_ok( 'CanvasCloud::API::Account' );

ok my $api = CanvasCloud::API::Account->new( domain => 'localhost', token => '!wow!', account_id => 1  ), 'new object';

is $api->uri, 'https://localhost/api/v1/accounts/1', 'uri is correct';

isa_ok $api->request( 'GET', $api->uri ), 'HTTP::Request';

done_testing();
