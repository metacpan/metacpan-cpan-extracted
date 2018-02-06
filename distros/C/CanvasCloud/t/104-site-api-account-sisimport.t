use Test::More;
use FindBin;

require_ok( 'CanvasCloud::API::Account::SISImport' );

ok my $api = CanvasCloud::API::Account::SISImport->new( domain => 'localhost', token => '!wow!', account_id => 1  ), 'new object';

is $api->uri, 'https://localhost/api/v1/accounts/1/sis_imports', 'uri is correct';

isa_ok $api->request( 'GET', $api->uri ), 'HTTP::Request';

TODO: {
    local $TODO = 'Implement local test server';

    ok $api->sendzip( $FindBin::Bin .'/104-site-api-account-sisimport.t'),   'call sendzip on sisimport object';
    ok $api->status(1), 'call zipstatus on sisimport object';
}

done_testing();
