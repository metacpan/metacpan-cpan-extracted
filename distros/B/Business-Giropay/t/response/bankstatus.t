use Test::More;
use Test::Exception;

use aliased 'Business::Giropay::Response::Bankstatus';

my $response;

throws_ok { $response = Bankstatus->new }
qr/Missing required arguments: hash, json, network, secret/,
  "Response class with no parameters method dies";

lives_ok {
    $response = Bankstatus->new(
        json => '{"bankcode":"12345679","bic":"TESTDETT421","bankname":"Testbank","giropay":1,"giropayid":1,"rc":0,"msg":""}',
        hash    => 'b4067dcea42fb418d32a3934e9b7cb22',
        network => 'giropay',
        secret  => 'mysecret',
    );
}
"good response with good bic lives";

ok $response->success, "success is OK";
ok $response->supported, "supported is OK";
ok !$response->msg, "msg is empty";
cmp_ok $response->bankcode, 'eq', '12345679', "bankcode is good";
cmp_ok $response->bankname, 'eq', 'Testbank', "bankname is good";

lives_ok {
    $response = Bankstatus->new(
        json => '{"bankcode":null,"bic":null,"bankname":null,"giropay":null,"giropayid":null,"rc":5026,"msg":"bic ung\u00fcltig"}',
        hash    => '321dcbb974f31e735b1e0dd239a4bc51',
        network => 'giropay',
        secret  => 'mysecret',
    );
}
"good response with bad bic lives";

ok !$response->success, "success is not OK";
ok !$response->supported, "supported is not OK";
ok $response->msg, "msg is not empty";

throws_ok {
    $response = Bankstatus->new(
        json => '{"bankcode":null,"bic":null,"bankname":null,"giropay":null,"giropayid":null,"rc":5026,"msg":"bic ung\u00fcltig"}',
        hash    => 'X21dcbb974f31e735b1e0dd239a4bc51',
        network => 'giropay',
        secret  => 'mysecret',
    );
}
qr/hash.+does not match/,
"response with bad hash dies";

done_testing;
