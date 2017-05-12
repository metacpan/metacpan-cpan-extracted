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
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use File::Temp;

use lib "$FindBin::Bin/lib";

use parent qw(
    TestClass
);

use Crypt::Perl::PK ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test__parse_key : Tests(4) {
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
