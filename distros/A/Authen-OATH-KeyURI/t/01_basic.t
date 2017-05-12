use Authen::OATH::KeyURI;

use Test::More;

subtest 'constructor' => sub {
    my $keyURI = Authen::OATH::KeyURI->new(
        accountname => q{alice@google.com},
        secret      => q{test_secret},
    );
    ok($keyURI, q{constructor});
    is($keyURI->as_string, q{otpauth://totp/alice@google.com?secret=orsxg5c7onswg4tfoq}, q{as_string});
    isa_ok($keyURI->as_uri, q{URI});
    is($keyURI->as_uri->as_string, $keyURI->as_string, q{as_uri});
};

subtest 'space encoding' => sub {
    my $keyURI = Authen::OATH::KeyURI->new(
        accountname => q{Alice Smith},
        secret      => q{test_secret},
    );
    ok($keyURI, q{constructor});
    is($keyURI->as_string, q{otpauth://totp/Alice%20Smith?secret=orsxg5c7onswg4tfoq}, q{space});
};

subtest 'issuer' => sub {
    my $keyURI = Authen::OATH::KeyURI->new(
        accountname => q{alice@google.com},
        secret      => q{test_secret},
        issuer => q{Example},
    );
    ok($keyURI, q{constructor});
    like($keyURI->as_string, qr/\Aotpauth\:\/\/totp\/Example\:alice\@google\.com\?/, q{label});
    like($keyURI->as_string, qr/issuer=Example/, q{param});
    like($keyURI->as_string, qr/secret=orsxg5c7onswg4tfoq/, q{secret});
};

subtest 'other params(TOTP)' => sub {
    my $keyURI = Authen::OATH::KeyURI->new(
        accountname => q{alice@google.com},
        secret      => q{test_secret},
        algorithm   => q{SHA256},
        digits      => 8,
        period      => 60,
        counter     => 10, # invalid
    );
    ok($keyURI, q{constructor});
    like($keyURI->as_string, qr/\Aotpauth\:\/\/totp\/alice\@google\.com\?/, q{label});
    like($keyURI->as_string, qr/secret=orsxg5c7onswg4tfoq/, q{secret});
    like($keyURI->as_string, qr/algorithm=SHA256/, q{algorithm});
    like($keyURI->as_string, qr/digits=8/, q{digits});
    like($keyURI->as_string, qr/period=60/, q{period});
    like($keyURI->as_string, qr/(?!.*counter)/, q{counter});
};

subtest 'other params(HOTP)' => sub {
    my $keyURI = Authen::OATH::KeyURI->new(
        type        => q{hotp},
        accountname => q{alice@google.com},
        secret      => q{test_secret},
        algorithm   => q{SHA256},
        digits      => 8,
        period      => 60, # invalid
        counter     => 10,
    );
    ok($keyURI, q{constructor});
    like($keyURI->as_string, qr/\Aotpauth\:\/\/hotp\/alice\@google\.com\?/, q{label});
    like($keyURI->as_string, qr/secret=orsxg5c7onswg4tfoq/, q{secret});
    like($keyURI->as_string, qr/algorithm=SHA256/, q{algorithm});
    like($keyURI->as_string, qr/digits=8/, q{digits});
    like($keyURI->as_string, qr/counter=10/, q{counter});
    like($keyURI->as_string, qr/(?!.*period)/, q{period});
};

subtest 'different scheme' => sub {
    my $keyURI = Authen::OATH::KeyURI->new(
        scheme      => q{yjotp},
        accountname => q{alice@google.com},
        secret      => q{test_secret},
    );
    ok($keyURI, q{constructor});
    is($keyURI->as_string, q{yjotp://totp/alice@google.com?secret=orsxg5c7onswg4tfoq}, q{as_string});
    isa_ok($keyURI->as_uri, q{URI});
    is($keyURI->as_uri->as_string, $keyURI->as_string, q{as_uri});
};

subtest 'secret encoding' => sub {
    my $keyURI = Authen::OATH::KeyURI->new(
        accountname => q{alice@google.com},
        secret      => q{example secret},
    );
    ok($keyURI, q{constructor});
    is($keyURI->as_string, q{otpauth://totp/alice@google.com?secret=mv4gc3lqnrssa43fmnzgk5a}, q{as_string});
    isa_ok($keyURI->as_uri, q{URI});
    is($keyURI->as_uri->as_string, $keyURI->as_string, q{as_uri});

    my $keyURI_w_encoded_secret = Authen::OATH::KeyURI->new(
        accountname => q{alice@google.com},
        secret      => q{mv4gc3lqnrssa43fmnzgk5a},
        is_encoded  => 1,
    );
    ok($keyURI_w_encoded_secret, q{constructor});
    is_deeply($keyURI_w_encoded_secret->as_uri, $keyURI->as_uri, q{secret encoding});
};

done_testing;
