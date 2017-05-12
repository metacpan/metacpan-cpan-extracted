use Test::More;
use Test::Exception;

use aliased 'Business::Giropay::Response::Issuer';

my $response;

throws_ok { $response = Issuer->new }
qr/Missing required arguments: hash, json, network, secret/,
  "Response class with no parameters method dies";

lives_ok {
    $response = Issuer->new(
        json => '{"issuer":{"PBNKDEFF100":"Postbank","BELADEBEXXX":"Landesbank Berlin - Berliner Sparkasse"},"rc":0,"msg":""}',
        hash    => 'ba2baefaf83ba65b18075f8aa8ec5d25',
        network => 'giropay',
        secret  => 'mysecret',
    );
}
"good response lives";

ok $response->success, "success is OK";
ok !$response->msg, "msg is empty";
cmp_ok keys %{$response->issuers}, 'eq', 2, "two issuers";

throws_ok {
    $response = Issuer->new(
        json => '{"issuer":{"PBNKDEFF100":"Postbank","BELADEBEXXX":"Landesbank Berlin - Berliner Sparkasse"},"rc":0,"msg":""}',
        hash    => 'Xa2baefaf83ba65b18075f8aa8ec5d25',
        network => 'giropay',
        secret  => 'mysecret',
    );
}
qr/hash.+does not match/,
"response with bad hash dies";

done_testing;
