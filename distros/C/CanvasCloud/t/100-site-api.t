use Test::More;

require_ok( 'CanvasCloud::API' );

ok my $api = CanvasCloud::API->new( domain => 'localhost', token => '!wow!'  ), 'new object';

is $api->uri, 'https://localhost/api/v1', 'uri is correct';

isa_ok $api->request( 'GET', $api->uri ), 'HTTP::Request';

done_testing();
