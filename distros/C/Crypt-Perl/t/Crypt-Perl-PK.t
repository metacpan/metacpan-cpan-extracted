package t::Crypt::Perl::PK;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::FailWarnings;
use Test::Deep;
use Test::Exception;

use File::Temp;

use lib "$FindBin::Bin/lib";

use parent qw(
    TestClass
);

use Crypt::Perl::PK ();

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

sub test__parse_key__generic_private : Tests(1) {
    my $ecc = <<END;
-----BEGIN PRIVATE KEY-----
MIG2AgEAMBAGByqGSM49AgEGBSuBBAAiBIGeMIGbAgEBBDCjQEAvrGxBbZnLFgK9
d5KiCiu2Fj4hSLXTKDHL32/TjRVmd3oy9mEqhsIvjNoYNdWhZANiAASoAjX340vY
1Sb+SZ1OrYG6WvMXN3htrB1N6sT1g4qYVTYTFOMgyRZQkkYmEqqVGc3Y0co3tfWf
w16OQ3fGdNzSlv3AjLRRAsH7PvRShUzkQYe/6CT7hF16g0y8hChh3+M=
-----END PRIVATE KEY-----
END

    my $parsed = Crypt::Perl::PK::parse_key($ecc);

    isa_ok(
        $parsed,
        'Crypt::Perl::ECDSA::PrivateKey',
        'parse_key($ecc)',
    );

    return;
}

sub test__parse_key : Tests(8) {
    throws_ok(
        sub { Crypt::Perl::PK::parse_key([]) },
        'Crypt::Perl::X::Generic',
        'fail on arrayref',
    );

    my $err = $@;
    like($err, qr<ARRAY>, '… and value is given');

    my $dsa_priv = <<END;
-----BEGIN DSA PRIVATE KEY-----
MIIBWAIBAAJhAOEnQNSaTbnSurfFZeR9i/E9SzorfARYn3ORM2tW+cz44FX/BDQR
dCqvi9t2Vi8IRA15dzA96OGojmnIv+6Mq8EFGE7dZvMXhVP+z1jBQX4mF2PFU694
hqm+xDHRgAq4xQIVAN4yNCwCl5V8+9+zZTEDmEfTUaJNAmBoi6Wh7A7J0Kr9S7Vz
kXpG0Ryj+CJh8oAt4Vqu3rIDdah0gw7QYc5mlyqSCwgEbmhG5DKdvW50/oFrOQ4E
zxpC3fALBuK/5BYd8zgObG+o6OAY7pJFD3W5d+P+CxSrfwkCYCF7+jOGXMREtJQu
AnGULUho2RD1u0g3hvJE7LJumUe7pAYXGhecG/ABIz1OxUWNJ+cSrZX3rEqU5u7T
/IvHIYdvE2XoaXeFx8NdPuvuyBiZ/PeHwXeHIvzBQonOPnOrnwIVAIBoSa04LKAE
EvF3uh/r74EWHYD8
-----END DSA PRIVATE KEY-----
END

    throws_ok(
        sub { Crypt::Perl::PK::parse_key($dsa_priv) },
        'Crypt::Perl::X::Generic',
        'fail on arrayref',
    );

    $err = $@;
    like($err, qr<DSA PRIVATE>, '… and value is given');

    my $rsa_priv = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIBPAIBAAJBAMUG9V5cTXHM0gAaPp4cmxiUL9oVD/JBWtVXapjVWLpCiQSR+IqK
RmrKHqmJ7+L9t18I8ZytRFoa+7atY1T9bFECAwEAAQJASEprUPnw+GY8TwlSHFVG
mtgUTqIXvb05BLoURItTCNOnNJfcMJ9grCSsGqmtsL68JRYEzAKeQVrHYpa/H7xk
IQIhAPe8JzMutX8oNX8SYxBBS4HrKSTG8hrWzMUKysCOi/ilAiEAy5m4zLiFqbCb
IuMgOf4Z5NdO/a3789WyUrhs2UHx6T0CIQCNn9jhH8DOktQScxaDAnECMsfwqHNb
+JRTyRmj/1nxqQIhAJ+4343S8CDYCExNK9ny6rNo6XH/jJmUOonEXrftkO7tAiEA
9vs9RwGKBwiy+jki+b2ozBW+bCUCLR3uBtpTop0I/HE=
-----END RSA PRIVATE KEY-----
END

    isa_ok(
        Crypt::Perl::PK::parse_key($rsa_priv),
        'Crypt::Perl::RSA::PrivateKey',
        'parse_key($rsa_priv)',
    );

    my $rsa_pub = <<END;
-----BEGIN PUBLIC KEY-----
MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAMUG9V5cTXHM0gAaPp4cmxiUL9oVD/JB
WtVXapjVWLpCiQSR+IqKRmrKHqmJ7+L9t18I8ZytRFoa+7atY1T9bFECAwEAAQ==
-----END PUBLIC KEY-----
END
    isa_ok(
        Crypt::Perl::PK::parse_key($rsa_pub),
        'Crypt::Perl::RSA::PublicKey',
        'parse_key($rsa_pub)',
    );

    my $ecc_priv = <<END;
-----BEGIN EC PRIVATE KEY-----
MIHcAgEBBEIBxEqlPSymlwNlkRjPY4Gyr5H+/XpVKNkM26n9YxKMpFeFNTQvf2+9
Ruj5J6JLN0vsh2OBjgY/ZqHSnU6NRVv8IGKgBwYFK4EEACOhgYkDgYYABABlYnQ5
Kt8a+fCMUtsb30PvndLCxiYl+I2NlaxJyPoVJUgBibU/UlcFAzOczE0pLPmWUw0j
5eAC/nn1FK+9ihVCDAE9mMjzp3rVAmk+JVUw/7D3EziM9pGJ/uHsLMSrlqt2AajS
Ip4aHXvm6x7K4KA3yHp0STHw8ZB/cO7rJpDkwoNQng==
-----END EC PRIVATE KEY-----
END

    isa_ok(
        Crypt::Perl::PK::parse_key($ecc_priv),
        'Crypt::Perl::ECDSA::PrivateKey',
        'parse_key($ecc_priv)',
    );

    my $ecdsa_pub = <<END;
-----BEGIN PUBLIC KEY-----
MIGbMBAGByqGSM49AgEGBSuBBAAjA4GGAAQAZWJ0OSrfGvnwjFLbG99D753SwsYm
JfiNjZWsScj6FSVIAYm1P1JXBQMznMxNKSz5llMNI+XgAv559RSvvYoVQgwBPZjI
86d61QJpPiVVMP+w9xM4jPaRif7h7CzEq5ardgGo0iKeGh175useyuCgN8h6dEkx
8PGQf3Du6yaQ5MKDUJ4=
-----END PUBLIC KEY-----
END
    isa_ok(
        Crypt::Perl::PK::parse_key($ecdsa_pub),
        'Crypt::Perl::ECDSA::PublicKey',
        'parse_key($ecdsa_pub)',
    );

    return;
}

sub test__parse_jwk__junk : Tests(6) {
    dies_ok(
        sub { Crypt::Perl::PK::parse_jwk([]) },
        'fail on arrayref',
    );

    my $err = $@;
    cmp_deeply(
        $err,
        all( re(qr<HASH>), re(qr<ARRAY>) ),
        '… error contents',
    );

    #----------------------------------------------------------------------

    my $pr_jwk = {
        kty => "whatwhat",
        crv => "Ed25519",
        x => "oF0a6lgwrJplzfs4RmDUl-NpfEa0Gc8s7IXei9JFRZ0",
    };

    throws_ok(
        sub { Crypt::Perl::PK::parse_jwk($pr_jwk) },
        'Crypt::Perl::X::UnknownJWKkty',
        'fail on unknown kty',
    );

    $err = $@;
    cmp_deeply(
        $err,
        all( re(qr<whatwhat>) ),
        '… error contents',
    );

    #----------------------------------------------------------------------

    $pr_jwk = {
        foo => 'bar',
        baz => 'qux',
    };

    throws_ok(
        sub { Crypt::Perl::PK::parse_jwk($pr_jwk) },
        'Crypt::Perl::X::InvalidJWK',
        'fail on bad JWK',
    );

    $err = $@;
    cmp_deeply(
        $err,
        all(
            map { re(qr<$_>) } sort %$pr_jwk
        ),
        '… error contents',
    );
}

sub test__parse_jwk__ed25519 : Tests(3) {
    my $pr_jwk = {
        kty => "OKP",
        crv => "Ed25519",
        x => "oF0a6lgwrJplzfs4RmDUl-NpfEa0Gc8s7IXei9JFRZ0",
    };

    my $got = Crypt::Perl::PK::parse_jwk($pr_jwk);

    cmp_deeply(
        $got,
        all(
            Isa('Crypt::Perl::Ed25519::PublicKey'),
        ),
        'expected parse',
    );

    #----------------------------------------------------------------------

    $pr_jwk = {
        kty => "OKP",
        crv => "whatwhat",
        x => "oF0a6lgwrJplzfs4RmDUl-NpfEa0Gc8s7IXei9JFRZ0",
    };

    throws_ok(
        sub { Crypt::Perl::PK::parse_jwk($pr_jwk) },
        'Crypt::Perl::X::Generic',
        'fail on unknown crv',
    );

    my $err = $@;
    cmp_deeply(
        $err,
        all( re(qr<crv>), re(qr<whatwhat>) ),
        '… error contents',
    );
}

sub test__parse_jwk__rsa : Tests(2) {

    my ($pr_jwk) = {
        kty => 'RSA',
        n => "0ZnvJBJiEp9hO1BOwKyA6dvVoS8ij0IlMOAp2oj2ZkiEdyaGO4aL5Lq2LIQKvFpLzRmQlmApFlnOlLbhxZCuF53iGC0IU0Z02jBfEdWiewL4L2dSCvw14-Z-oVWBJfwN",
        e => "AQAB",
        d => "NILvUcc1QNsjPfvxrv3I0k4cKGSpsOBudt9CPRjhOmDipwNEz_b2Z1iLuX1fPy8TqHpTv4ECDOIs2ArAvZabrrPmjjPo8rzbzlyTLoAaqBNVGpzQuFnOKONkil9gY7A1",
        p => "63Omrbj0-jqnCFYA4He0Tn6OzZyFPL-tmcWcCD9U4fSAZXsEFZhcJWPrtJPXFpdn",
        q => "4-S-pP0u32ty6kshqFDSKYxCrzuY6_7Pbw-6pd-w1hElmxY9sZ7PdVxeGpTveSxr",
        dp => "exO_Yzw1wr_6JF9gofWw6P87Arv44eKIisNDZwRECMFYhLOjVO6J7Hmo8oH9gy-t",
        dq => "3pOiv3GoPf2rlrkaflGxcXLUDmGe0Z9k6YvrN-ZpyCmnGPl39-qrpGw6XKvp1-dR",
        qi => "w0uFy3hHFZL94Xk0JK6VApoNY6czBmIBhCbHSIKKfpKoDVQzfqMYN8Q6jBTPH-ln",
    };

    isa_ok(
        Crypt::Perl::PK::parse_jwk($pr_jwk),
        'Crypt::Perl::RSA::PrivateKey',
        'parse_jwk($rsa_private_jwk)',
    );

    my ($pub_jwk) = {
        kty => 'RSA',
        n => "0ZnvJBJiEp9hO1BOwKyA6dvVoS8ij0IlMOAp2oj2ZkiEdyaGO4aL5Lq2LIQKvFpLzRmQlmApFlnOlLbhxZCuF53iGC0IU0Z02jBfEdWiewL4L2dSCvw14-Z-oVWBJfwN",
        e => "AQAB",
    };

    isa_ok(
        Crypt::Perl::PK::parse_jwk($pub_jwk),
        'Crypt::Perl::RSA::PublicKey',
        'parse_jwk($rsa_public_jwk)',
    );

    return;
}

sub test__parse_jwk__ecdsa : Tests(2) {
    my ($pr_jwk) = {
        kty => 'EC',
        crv => 'P-384',
        x => '7r2u_ZkCnSjowORDMgnqWvI1A9HQ6CH06LIAaftFO2iYYazSICi-HoH_M2tBn4fR',
        y => 'ouVhCnZ-g4E8aVqgJcqmIdiGZIN8qlqWG9K8wvFKWvUbSI561j_WXuKH3cBp0ewq',
        d => '5ITbOa5Bw3lhq5doenNkZ-JcJVT0e4sWQpdtfo-5et9-Bqx8qQv8T9T1wS-jCZB2',
    };

    isa_ok(
        Crypt::Perl::PK::parse_jwk($pr_jwk),
        'Crypt::Perl::ECDSA::PrivateKey',
        'parse_jwk($ecc_private_jwk)',
    );

    my ($pub_jwk) = {
        kty => 'EC',
        crv => 'P-384',
        x => '7r2u_ZkCnSjowORDMgnqWvI1A9HQ6CH06LIAaftFO2iYYazSICi-HoH_M2tBn4fR',
        y => 'ouVhCnZ-g4E8aVqgJcqmIdiGZIN8qlqWG9K8wvFKWvUbSI561j_WXuKH3cBp0ewq',
    };

    isa_ok(
        Crypt::Perl::PK::parse_jwk($pub_jwk),
        'Crypt::Perl::ECDSA::PublicKey',
        'parse_jwk($ecc_public_jwk)',
    );

    return;
}
