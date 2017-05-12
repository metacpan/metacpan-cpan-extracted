use Test::More;
use Test::Exception;

{

    package TestRequest;
    use Moo;
    with 'Business::Giropay::Role::Request';
    use namespace::clean;

    sub uri {
        return 'test/request';
    }

    sub parameters { return [] }
}

my $request;

throws_ok { $request = TestRequest->new }
qr/Missing required arguments: merchantId, network, projectId, secret/,
  "Request class with no parameters method dies";

lives_ok {
    $request = TestRequest->new(
        merchantId => 1234567,
        projectId  => 1234,
        secret     => 'secure',
        network    => 'eps',
    );
}
"good request lives";

cmp_ok $request->hash, 'eq', '02f123fdb8b2056596abc0e6ebb1a8c3', 'hash is good';

cmp_ok $request->url, 'eq',
  'https://payment.girosolution.de/girocheckout/api/v2/test/request',
  'url is good';

done_testing;
