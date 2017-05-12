use Test::More;
use Test::Exception;

use aliased 'Business::Giropay::Response::Transaction';

my $response;

throws_ok { $response = Transaction->new }
qr/Missing required arguments: hash, json, network, secret/,
  "Response class with no parameters method dies";

lives_ok {
    $response = Transaction->new(
        json => '{"reference":"4004f19c-7f68-472f-9369-7c7f0ecce077","redirect":"https:\/\/ftg-customer-integration.giropay.de\/ftg\/b\/go\/07i2i1k00pp0ykup3k5u2iwt;jsessionid=5A3634335A55E0AAE3D42CF1088DF019.sf-testapp02tom23","rc":"0","msg":""}',
        hash    => '4dc3fe43c4601cf280b3a51a4a1426a8',
        network => 'giropay',
        secret  => 'mysecret',
    );
}
"good response with good bic lives";

ok $response->success, "success is OK";
ok !$response->msg, "msg is empty";
like $response->reference, qr/\w+/, "reference looks OK";
like $response->redirect, qr/^https*:\/\//, "redirect looks OK";

lives_ok {
    $response = Transaction->new(
        json => '{"reference":null,"redirect":null,"rc":5202,"msg":"Bank des Absenders ung\u00fcltig"}',
        hash    => 'f5e01706ca2fe087f76b73be7f0e5ca7',
        network => 'giropay',
        secret  => 'mysecret',
    );
}
"good response with bad bic lives";

ok !$response->success, "success is not OK";
ok $response->msg, "msg is not empty";
ok !defined $response->reference, "reference is undef";
ok !defined $response->redirect, "reference is undef";

throws_ok {
    $response = Transaction->new(
        json => '{"reference":"4004f19c-7f68-472f-9369-7c7f0ecce077","redirect":"https:\/\/ftg-customer-integration.giropay.de\/ftg\/b\/go\/07i2i1k00pp0ykup3k5u2iwt;jsessionid=5A3634335A55E0AAE3D42CF1088DF019.sf-testapp02tom23","rc":"0","msg":""}',
        hash    => 'Xdc3fe43c4601cf280b3a51a4a1426a8',
        network => 'giropay',
        secret  => 'mysecret',
    );
}
qr/hash.+does not match/,
"response with bad hash dies";

done_testing;
