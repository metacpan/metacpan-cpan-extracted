use Test::More;
use FindBin;

require_ok( 'CanvasCloud::API::Account::OutcomeImport' );

ok my $api = CanvasCloud::API::Account::OutcomeImport->new( domain => 'localhost', token => '!wow!', account_id => 1  ), 'new object';

is $api->uri, 'https://localhost/api/v1/accounts/1/outcome_imports', 'uri is correct';

isa_ok $api->request( 'GET', $api->uri ), 'HTTP::Request';

TODO: {
    local $TODO = 'Implement local test server';

    ok $api->sendcsv( $FindBin::Bin .'/104-site-api-account-outcomeimport.t'),   'call sendcsv on OutcomeImport object';
    ok $api->status(1), 'call status on OutcomeImport object';
}

done_testing();
