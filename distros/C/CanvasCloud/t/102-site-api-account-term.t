use Test::More;

require_ok( 'CanvasCloud::API::Account::Term' );

ok my $api = CanvasCloud::API::Account::Term->new( domain => 'localhost', token => '!wow!', account_id => 1  ), 'new object';

is $api->uri, 'https://localhost/api/v1/accounts/1/terms', 'uri is correct';

isa_ok $api->request( 'GET', $api->uri ), 'HTTP::Request';

TODO: {
    local $TODO = 'Implement local test server';
    ok $api->list, 'call list on reports object';
}

done_testing();
