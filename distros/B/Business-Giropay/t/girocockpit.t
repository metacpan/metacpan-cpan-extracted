#
# to run this test you must first set the following ENV variables:
#
# merchantId
# eps_projectId
# eps_secret
# giropay_projectId
# giropay_secret
# ideal_projectId
# ideal_secret=
#
use Test::More;
use Test::Exception;

use Business::Giropay;

my ( $giropay, $response );

plan skip_all => '$ENV{merchantId} not set' unless $ENV{merchantId};

subtest 'EPS' => sub {
    plan skip_all => '$ENV{eps_projectId} not set' unless $ENV{eps_projectId};
    plan skip_all => '$ENV{eps_secret} not set'    unless $ENV{eps_secret};

    lives_ok {
        $giropay = Business::Giropay->new(
            network    => 'eps',
            merchantId => $ENV{merchantId},
            projectId  => $ENV{eps_projectId},
            secret     => $ENV{eps_secret}
          )
    }
    "new EPS giropay object";

    lives_ok {
        $response = $giropay->bankstatus( bic => 'HYPTAT22XXX' );
    }
    "bankstatus request lives";

    ok $response->success,      "response success";
    ok $response->supported,    "supported OK";
    cmp_ok $response->bankcode, 'eq', '57000', 'bankcode is good';
    cmp_ok $response->bankname, 'eq', 'HYPO TIROL BANK AG', 'bankname is good';

    lives_ok {
        $response = $giropay->issuer;
    }
    "issuer request lives";

    ok $response->success, "response success";
    my %issuers = %{ $response->issuers };
    ok %issuers, "response has issuers";
    ok $issuers{HYPTAT22XXX}, "HYPTAT22XXX found in issuers";
    ok $response->has_bic('HYPTAT22XXX'), "has_bic('HYPTAT22XXX') is true";

    lives_ok {
        $response = $giropay->transaction(
            merchantTxId => '123456789',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Test Transaction',
            bic          => 'HYPTAT22XXX',
            urlRedirect  => 'http://www.example.com/redirect',
            urlNotify    => 'http://www.example.com/notify',
        );
    }
    "transaction request lives";

    ok $response->success, "response success" or diag explain $response;
    like $response->reference, qr{\w+}, "reference looks good";
    like $response->redirect, qr{^https*://.+},
      "redirect looks good: " . $response->redirect;

    lives_ok {
        $giropay = Business::Giropay->new(
            network     => 'eps',
            merchantId  => $ENV{merchantId},
            projectId   => $ENV{eps_projectId},
            secret      => $ENV{eps_secret},
            urlRedirect => 'http://www.example.com/redirect',
            urlNotify   => 'http://www.example.com/notify',
          )
    }
    "new EPS giropay object with urlRedirect and urlNotify lives";

    lives_ok {
        $response = $giropay->transaction(
            merchantTxId => '123456789',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Test Transaction',
            bic          => 'HYPTAT22XXX',
        );
    }
    "transaction request lives";

    ok $response->success, "response success" or diag explain $response;
    like $response->reference, qr{\w+}, "reference looks good";
    like $response->redirect, qr{^https*://.+},
      "redirect looks good: " . $response->redirect;
};

subtest 'Giropay' => sub {
    plan skip_all => '$ENV{giropay_projectId} not set'
      unless $ENV{giropay_projectId};
    plan skip_all => '$ENV{giropay_secret} not set' unless $ENV{giropay_secret};

    lives_ok {
        $giropay = Business::Giropay->new(
            network    => 'giropay',
            merchantId => $ENV{merchantId},
            projectId  => $ENV{giropay_projectId},
            secret     => $ENV{giropay_secret}
          )
    }
    "new Giropay giropay object";

    lives_ok {
        $response = $giropay->bankstatus( bic => 'TESTDETT421' );
    }
    "bankstatus request lives";

    ok $response->success,      "response success";
    ok $response->supported,    "supported OK";
    ok $response->giropayid,    "giropayid OK";
    cmp_ok $response->bankcode, 'eq', '12345679', 'bankcode is good';
    cmp_ok $response->bankname, 'eq', 'Testbank', 'bankname is good';

    lives_ok {
        $response = $giropay->issuer;
    }
    "issuer request lives";

    my %issuers = %{ $response->issuers };
    ok %issuers, "response has issuers";
    ok $issuers{TESTDETT421}, "TESTDETT421 found in issuers";
    ok $response->has_bic('TESTDETT421'), "has_bic('TESTDETT421') is true";

    lives_ok {
        $response = $giropay->transaction(
            merchantTxId => '123456789',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Test Transaction',
            bic          => 'TESTDETT421',
            urlRedirect  => 'http://www.example.com/redirect',
            urlNotify    => 'http://www.example.com/notify',
        );
    }
    "transaction request lives";

    ok $response->success, "response success" or diag explain $response;
    like $response->reference, qr{\w+}, "reference looks good";
    like $response->redirect, qr{^https*://.+},
      "redirect looks good: " . $response->redirect;

    lives_ok {
        $giropay = Business::Giropay->new(
            network     => 'giropay',
            merchantId  => $ENV{merchantId},
            projectId   => $ENV{giropay_projectId},
            secret      => $ENV{giropay_secret},
            urlRedirect => 'http://www.example.com/redirect',
            urlNotify   => 'http://www.example.com/notify',
          )
    }
    "new Giropay giropay object with urlRedirect and urlNotify lives";

    lives_ok {
        $response = $giropay->transaction(
            merchantTxId => '123456789',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Test Transaction',
            bic          => 'TESTDETT421',
        );
    }
    "transaction request lives";

    ok $response->success, "response success" or diag explain $response;
    like $response->reference, qr{\w+}, "reference looks good";
    like $response->redirect, qr{^https*://.+},
      "redirect looks good: " . $response->redirect;
};

subtest 'iDeal' => sub {
    plan skip_all => '$ENV{ideal_projectId} not set'
      unless $ENV{ideal_projectId};
    plan skip_all => '$ENV{ideal_secret} not set' unless $ENV{ideal_secret};

    lives_ok {
        $giropay = Business::Giropay->new(
            network    => 'ideal',
            merchantId => $ENV{merchantId},
            projectId  => $ENV{ideal_projectId},
            secret     => $ENV{ideal_secret}
          )
    }
    "new iDEAL giropay object";

    throws_ok {
        $response = $giropay->bankstatus( bic => 'RABOBANK', );
    }
    qr/bankstatus request not supported by ideal/, "bankstatus request dies";

    lives_ok {
        $response = $giropay->issuer;
    }
    "issuer request lives";

    my %issuers = %{ $response->issuers };
    ok %issuers, "response has issuers";
    ok $issuers{RABOBANK}, "RABOBANK found in issuers";
    ok $response->has_bic('RABOBANK'), "has_bic('RABOBANK') is true";

    lives_ok {
        $response = $giropay->transaction(
            merchantTxId => '123456789',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Test Transaction',
            issuer       => 'RABOBANK',
            urlRedirect  => 'http://www.example.com/redirect',
            urlNotify    => 'http://www.example.com/notify',
        );
    }
    "transaction request lives";

    ok $response->success, "response success" or diag explain $response;
    like $response->reference, qr{\w+}, "reference looks good";
    like $response->redirect, qr{^https*://.+},
      "redirect looks good: " . $response->redirect;

    lives_ok {
        $giropay = Business::Giropay->new(
            network     => 'ideal',
            merchantId  => $ENV{merchantId},
            projectId   => $ENV{ideal_projectId},
            secret      => $ENV{ideal_secret},
            urlRedirect => 'http://www.example.com/redirect',
            urlNotify   => 'http://www.example.com/notify',
          )
    }
    "new iDEAL giropay object with urlRedirect and urlNotify lives";

    lives_ok {
        $response = $giropay->transaction(
            merchantTxId => '123456789',
            amount       => 100,
            currency     => 'EUR',
            purpose      => 'Test Transaction',
            issuer       => 'RABOBANK',
        );
    }
    "transaction request lives";

    ok $response->success, "response success" or diag explain $response;
    like $response->reference, qr{\w+}, "reference looks good";
    like $response->redirect, qr{^https*://.+},
      "redirect looks good: " . $response->redirect;
};

done_testing;
