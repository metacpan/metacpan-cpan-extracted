use Test::More;
use Test::Exception;

use aliased 'Business::Giropay::Request::Transaction';

my $request;

subtest 'no args' => sub {

    throws_ok { $request = Transaction->new }
qr/Missing required arguments: amount, currency, merchantId, merchantTxId, network, projectId, purpose, secret, urlNotify, urlRedirect/,
      "Request class with no parameters method dies";
};

subtest eps => sub {
    throws_ok {
        $request = Transaction->new(
            merchantId   => 1234567,
            projectId    => 1234,
            merchantTxId => '1234567890',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Beispieltransaktion',
            info1Label   => 'Ihre Kundennummer',
            info1Text    => '0815',
            urlRedirect  => 'http://www.ihre-domein.de/girocheckout/redirect',
            urlNotify    => 'http: //www.ihre-domein.de/girocheckout/notify',
            secret       => 'secure',
            network      => 'eps',
        );
    }
    qr/Missing required argument: bic/, "Request with missing bic dies";

    lives_ok {
        $request = Transaction->new(
            merchantId   => 1234567,
            projectId    => 1234,
            merchantTxId => '1234567890',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Beispieltransaktion',
            bic          => 'TESTDETT421',
            info1Label   => 'Ihre Kundennummer',
            info1Text    => '0815',
            urlRedirect  => 'http://www.ihre-domein.de/girocheckout/redirect',
            urlNotify    => 'http: //www.ihre-domein.de/girocheckout/notify',
            secret       => 'secure',
            network      => 'giropay',
        );
    }
    "good request lives";

    cmp_ok $request->hash, 'eq', '983f8a2d2e483d08020c218adc7fb1c8',
      'hash is good';

    cmp_ok $request->url, 'eq',
      'https://payment.girosolution.de/girocheckout/api/v2/transaction/start',
      'url is good';
};

subtest giropay => sub {
    throws_ok {
        $request = Transaction->new(
            merchantId   => 1234567,
            projectId    => 1234,
            merchantTxId => '1234567890',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Beispieltransaktion',
            info1Label   => 'Ihre Kundennummer',
            info1Text    => '0815',
            urlRedirect  => 'http://www.ihre-domein.de/girocheckout/redirect',
            urlNotify    => 'http: //www.ihre-domein.de/girocheckout/notify',
            secret       => 'secure',
            network      => 'giropay',
        );
    }
    qr/Missing required argument: bic/, "Request with no missing bic dies";

    lives_ok {
        $request = Transaction->new(
            merchantId   => 1234567,
            projectId    => 1234,
            merchantTxId => '1234567890',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Beispieltransaktion',
            bic          => 'TESTDETT421',
            info1Label   => 'Ihre Kundennummer',
            info1Text    => '0815',
            urlRedirect  => 'http://www.ihre-domein.de/girocheckout/redirect',
            urlNotify    => 'http: //www.ihre-domein.de/girocheckout/notify',
            secret       => 'secure',
            network      => 'giropay',
        );
    }
    "good request lives";

    cmp_ok $request->hash, 'eq', '983f8a2d2e483d08020c218adc7fb1c8',
      'hash is good';

    cmp_ok $request->url, 'eq',
      'https://payment.girosolution.de/girocheckout/api/v2/transaction/start',
      'url is good';
};

subtest ideal => sub {
    throws_ok {
        $request = Transaction->new(
            merchantId   => 1234567,
            projectId    => 1234,
            merchantTxId => '1234567890',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Beispieltransaktion',
            info1Label   => 'Ihre Kundennummer',
            info1Text    => '0815',
            urlRedirect  => 'http://www.ihre-domein.de/girocheckout/redirect',
            urlNotify    => 'http: //www.ihre-domein.de/girocheckout/notify',
            secret       => 'secure',
            network      => 'ideal',
        );
    }
    qr/Missing required argument: issuer/, "Request with missing issuer dies";

    lives_ok {
        $request = Transaction->new(
            merchantId   => 1234567,
            projectId    => 1234,
            merchantTxId => '1234567890',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Beispieltransaktion',
            issuer       => 'INGBNL2A',
            info1Label   => 'Ihre Kundennummer',
            info1Text    => '0815',
            urlRedirect  => 'http://www.ihre-domein.de/girocheckout/redirect',
            urlNotify    => 'http: //www.ihre-domein.de/girocheckout/notify',
            secret       => 'secure',
            network      => 'ideal',
        );
    }
    "good request lives";

    cmp_ok $request->hash, 'eq', '3463d5bf019b0a391da7ca4651e39c83',
      'hash is good';

    cmp_ok $request->url, 'eq',
      'https://payment.girosolution.de/girocheckout/api/v2/transaction/start',
      'url is good';
};

done_testing;
