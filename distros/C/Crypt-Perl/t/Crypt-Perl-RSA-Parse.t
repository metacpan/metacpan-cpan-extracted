package t::Crypt::Perl::RSA::Parse;

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

use parent qw( TestClass );

use Crypt::Format ();

use Crypt::Perl::RSA::Parse ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_jwk_private : Tests(1) {

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

    my $pr_pem = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIBywIBAAJhANGZ7yQSYhKfYTtQTsCsgOnb1aEvIo9CJTDgKdqI9mZIhHcmhjuG
i+S6tiyECrxaS80ZkJZgKRZZzpS24cWQrhed4hgtCFNGdNowXxHVonsC+C9nUgr8
NePmfqFVgSX8DQIDAQABAmA0gu9RxzVA2yM9+/Gu/cjSThwoZKmw4G5230I9GOE6
YOKnA0TP9vZnWIu5fV8/LxOoelO/gQIM4izYCsC9lpuus+aOM+jyvNvOXJMugBqo
E1UanNC4Wc4o42SKX2BjsDUCMQDrc6atuPT6OqcIVgDgd7ROfo7NnIU8v62ZxZwI
P1Th9IBlewQVmFwlY+u0k9cWl2cCMQDj5L6k/S7fa3LqSyGoUNIpjEKvO5jr/s9v
D7ql37DWESWbFj2xns91XF4alO95LGsCMHsTv2M8NcK/+iRfYKH1sOj/OwK7+OHi
iIrDQ2cERAjBWISzo1Tuiex5qPKB/YMvrQIxAN6Tor9xqD39q5a5Gn5RsXFy1A5h
ntGfZOmL6zfmacgppxj5d/fqq6RsOlyr6dfnUQIxAMNLhct4RxWS/eF5NCSulQKa
DWOnMwZiAYQmx0iCin6SqA1UM36jGDfEOowUzx/pZw==
-----END RSA PRIVATE KEY-----
END

    my $from_jwk = Crypt::Perl::RSA::Parse::jwk($pr_jwk);
    my $from_pem = Crypt::Perl::RSA::Parse::private($pr_pem);

    is_deeply( $from_jwk, $from_pem, 'from JWK is identical to from PEM' );
    return;
}

sub test_jwk_public : Tests(1) {

    my ($jwk) = {
        kty => 'RSA',
        n => "0ZnvJBJiEp9hO1BOwKyA6dvVoS8ij0IlMOAp2oj2ZkiEdyaGO4aL5Lq2LIQKvFpLzRmQlmApFlnOlLbhxZCuF53iGC0IU0Z02jBfEdWiewL4L2dSCvw14-Z-oVWBJfwN",
        e => "AQAB",
    };

    my $pb_pem = <<END;
-----BEGIN RSA PUBLIC KEY-----
MGgCYQDRme8kEmISn2E7UE7ArIDp29WhLyKPQiUw4CnaiPZmSIR3JoY7hovkurYs
hAq8WkvNGZCWYCkWWc6UtuHFkK4XneIYLQhTRnTaMF8R1aJ7AvgvZ1IK/DXj5n6h
VYEl/A0CAwEAAQ==
-----END RSA PUBLIC KEY-----
END

    my $from_jwk = Crypt::Perl::RSA::Parse::jwk($jwk);
    my $from_pem = Crypt::Perl::RSA::Parse::public($pb_pem);

    is_deeply( $from_jwk, $from_pem, 'from JWK is identical to from PEM' );
    return;
}

sub test_pkcs8_private : Tests(4) {
    my $pkey_pem = <<END;
-----BEGIN PRIVATE KEY-----
MIIB4wIBADANBgkqhkiG9w0BAQEFAASCAc0wggHJAgEAAmEAnzBnEKWqUIMXqVpj
9IncS0srB2bBeYgSIpeT1/ZNGBE28TAgQN2PZr9sCvPmjLIXjkv+jwkiTaMxXA93
nOmD5J6pLlDLDYM3KpmbuYdsIijO9VuHLS4i+8WPwDgp3G9pAgEDAmBqIES1w8bg
V2UbkZf4W+gyMhyvmdZRBWFsZQ06pDNlYM9LdWrV6QpEf51copmzIWP8GClTJ+Dx
/nqPV389MDg6oBU6404O0UkVKsRG+B2QKY1fjlh/EUowfwvNyz/hjYsCMQDTL7tI
IJ9yxwrZwtPRVBMCufGqffzhclsRJnHQ9VJZIH8wTSIyflpF2bg5v5kSUJUCMQDA
+AVKLLFv3m6rSWTvzRyJ9JerfdkV1u55swN+He1wyfu1uOA8FdltLUXRx7D3yoUC
MQCMynzawGpMhLHmgeKLjWIB0UvG/qiWTDy2GaE1+OGQwFTK3hbMVDwukSV71RC2
4GMCMQCApVjcHcuf6Z8c25if3hMGow/HqTtj5J77zKz+vp5LMVJ5JerSuTueHi6L
2nX6hwMCMFjmoIj6oHSFlze46vw+Hip1oO5IVsmMqjIVYU3vpIgXylj2ppaQi7sU
GLzyXiw4aw==
-----END PRIVATE KEY-----
END

    my $rsa_pem = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIByQIBAAJhAJ8wZxClqlCDF6laY/SJ3EtLKwdmwXmIEiKXk9f2TRgRNvEwIEDd
j2a/bArz5oyyF45L/o8JIk2jMVwPd5zpg+SeqS5Qyw2DNyqZm7mHbCIozvVbhy0u
IvvFj8A4KdxvaQIBAwJgaiBEtcPG4FdlG5GX+FvoMjIcr5nWUQVhbGUNOqQzZWDP
S3Vq1ekKRH+dXKKZsyFj/BgpUyfg8f56j1d/PTA4OqAVOuNODtFJFSrERvgdkCmN
X45YfxFKMH8Lzcs/4Y2LAjEA0y+7SCCfcscK2cLT0VQTArnxqn384XJbESZx0PVS
WSB/ME0iMn5aRdm4Ob+ZElCVAjEAwPgFSiyxb95uq0lk780cifSXq33ZFdbuebMD
fh3tcMn7tbjgPBXZbS1F0cew98qFAjEAjMp82sBqTISx5oHii41iAdFLxv6olkw8
thmhNfjhkMBUyt4WzFQ8LpEle9UQtuBjAjEAgKVY3B3Ln+mfHNuYn94TBqMPx6k7
Y+Se+8ys/r6eSzFSeSXq0rk7nh4ui9p1+ocDAjBY5qCI+qB0hZc3uOr8Ph4qdaDu
SFbJjKoyFWFN76SIF8pY9qaWkIu7FBi88l4sOGs=
-----END RSA PRIVATE KEY-----
END

    my $pkey_der = Crypt::Format::pem2der($pkey_pem);
    my $rsa_der = Crypt::Format::pem2der($rsa_pem);

    my $key = Crypt::Perl::RSA::Parse::private($pkey_pem);

    is(
        sprintf("%v.02x", $key->to_der()),
        sprintf("%v.02x", $rsa_der),
        'private() with PKCS8 (pem)',
    );

    $key = Crypt::Perl::RSA::Parse::private_pkcs8($pkey_pem);

    is(
        sprintf("%v.02x", $key->to_der()),
        sprintf("%v.02x", $rsa_der),
        'private_pkcs8(), pem',
    );

    #----------------------------------------------------------------------

    is(
        sprintf("%v.02x", Crypt::Perl::RSA::Parse::private($pkey_der)->to_der()),
        sprintf("%v.02x", $rsa_der),
        'private() with PKCS8 (der)',
    );

    is(
        sprintf("%v.02x", Crypt::Perl::RSA::Parse::private_pkcs8($pkey_der)->to_der()),
        sprintf("%v.02x", $rsa_der),
        'private_pkcs8(), der',
    );

    return;
}
