# -*- perl -*-

# t/002_parse.t - check parsing

use Test::NoWarnings;
use Test::More tests => 1 + 115;

use MIME::Base64 ();

use Crypt::RSA::Parse ();

#NB: These are all the same key.

my $modulus_bits = 1555;
my $modulus_hex =
  '75ef1cf209a32ce22d3423f9d6cab8d70ddf9ef7831fc5b9923dcb3c0a4681fbe121776f58c692cf69fc076d651a70b8e4054cd7c599664396132862ef2c0a41640ad590ad862d85a88ff2b2aaf837240b28d1758d1bea8133df15824c3c1ee9d3f32d972765a3cd9117e0940057ded947f832b3c963bf14549180c01de1e77d13a59d730adc14c4991e0fed20a0e0a22eaf4c0e9da035934ca428841f6d29de189eb5b79ea45ed7c5e0681618a09051ee7f007c999ced902c2e68429312c0efdceff';
my $exponent = 65537;

my $rsa_key = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIDiAIBAAKBwwde8c8gmjLOItNCP51sq41w3fnveDH8W5kj3LPApGgfvhIXdvWM
aSz2n8B21lGnC45AVM18WZZkOWEyhi7ywKQWQK1ZCthi2FqI/ysqr4NyQLKNF1jR
vqgTPfFYJMPB7p0/Mtlydlo82RF+CUAFfe2Uf4MrPJY78UVJGAwB3h530TpZ1zCt
wUxJkeD+0goOCiLq9MDp2gNZNMpCiEH20p3hietbeepF7XxeBoFhigkFHufwB8mZ
ztkCwuaEKTEsDv3O/wIDAQABAoHDBQTYYHJRrQCB5Bn7GSWS1tegvnwZ+udcM7Wg
pWEqUaAzmzwRC3gVccFo2/PPUYAONUmGtPjUQ7xw+cceaT9wfwqL9b1ozhjYOyWH
oowJQNb+SNYbrKX9TZL0na6oMgeOg85J/pIPYwe9vaBxvLeGRtIj9QTp5xhWnloE
HZpaMxFM8kuLn3Ox9NX7iv730ricrqW7tafXxMJtVmGCv8snoCjf+0g5t/jNIYj5
iq8eb43vYfG4TaMvo4+KOYiPeqQHl3mBAmIDyn5+nMRBwe5IKyLCjjinrWEV+/C9
1049bNXQh3wwHDGccDr+ozzGY6mrf0H9GQV35aWoQDHvgDNwQrEr4xR2xzpw2PwZ
U1lgvpnRkkFrReiT9PlbnKyx2G90qjsiTu0nQQJiAfG+gzdG7DXxBN5R5OaGqu+o
s3ccT0NRIBDYXFSQ+DmlWUqmLWiN5GRzcW+yPE2fnNfR2KmtMLdvhqB/BtdyVGdf
m/GyN5B36jBPvKlrFsJAj/XhmXE4iMISlWPsQoTtpj8CYgFdHxQ9IPzm3ulnWyHS
N99aJ8rYz0n74lGGjYRuuOY1vkMgvJhN8NcNk0P2i66ZCbaQDn/wWAZogBiqZUH8
dqgkE4n1BPu3WDfNWVhi3NXSWFChl/K08gsoaS/27T7yVa4BAmIAgxJyJ1pL1aCU
cZ8LMhGAbf/00obn8Igqc4UmOza5xyRdsSS1jHThEfq8gndjHeXMPaEK9xOeYo/B
2f3ZZV68D0TEIg+WRjrttq8otUx3/8tUnaE88O28Ra7zHA8ZLTwPrQJiAO8zHT/Y
hukWHLnf9gm00hph93EA92/AHccrIwDe/wO41hUvgK96fr7zi3JHWxqVdKtEXMba
z1i/3ACvVgBJArs9o/5WxBWiF7PVwe9S3vz0NxhzHUSnKdWt1qfGzk/WLbk=
-----END RSA PRIVATE KEY-----
END

my $rsa_public_key = <<END;
-----BEGIN RSA PUBLIC KEY-----
MIHLAoHDB17xzyCaMs4i00I/nWyrjXDd+e94MfxbmSPcs8CkaB++Ehd29YxpLPaf
wHbWUacLjkBUzXxZlmQ5YTKGLvLApBZArVkK2GLYWoj/Kyqvg3JAso0XWNG+qBM9
8Vgkw8HunT8y2XJ2WjzZEX4JQAV97ZR/gys8ljvxRUkYDAHeHnfROlnXMK3BTEmR
4P7SCg4KIur0wOnaA1k0ykKIQfbSneGJ61t56kXtfF4GgWGKCQUe5/AHyZnO2QLC
5oQpMSwO/c7/AgMBAAE=
-----END RSA PUBLIC KEY-----
END

my $pkcs8_key = <<END;
-----BEGIN PRIVATE KEY-----
MIIDogIBADANBgkqhkiG9w0BAQEFAASCA4wwggOIAgEAAoHDB17xzyCaMs4i00I/
nWyrjXDd+e94MfxbmSPcs8CkaB++Ehd29YxpLPafwHbWUacLjkBUzXxZlmQ5YTKG
LvLApBZArVkK2GLYWoj/Kyqvg3JAso0XWNG+qBM98Vgkw8HunT8y2XJ2WjzZEX4J
QAV97ZR/gys8ljvxRUkYDAHeHnfROlnXMK3BTEmR4P7SCg4KIur0wOnaA1k0ykKI
QfbSneGJ61t56kXtfF4GgWGKCQUe5/AHyZnO2QLC5oQpMSwO/c7/AgMBAAECgcMF
BNhgclGtAIHkGfsZJZLW16C+fBn651wztaClYSpRoDObPBELeBVxwWjb889RgA41
SYa0+NRDvHD5xx5pP3B/Cov1vWjOGNg7JYeijAlA1v5I1huspf1NkvSdrqgyB46D
zkn+kg9jB729oHG8t4ZG0iP1BOnnGFaeWgQdmlozEUzyS4ufc7H01fuK/vfSuJyu
pbu1p9fEwm1WYYK/yyegKN/7SDm3+M0hiPmKrx5vje9h8bhNoy+jj4o5iI96pAeX
eYECYgPKfn6cxEHB7kgrIsKOOKetYRX78L3XTj1s1dCHfDAcMZxwOv6jPMZjqat/
Qf0ZBXflpahAMe+AM3BCsSvjFHbHOnDY/BlTWWC+mdGSQWtF6JP0+VucrLHYb3Sq
OyJO7SdBAmIB8b6DN0bsNfEE3lHk5oaq76izdxxPQ1EgENhcVJD4OaVZSqYtaI3k
ZHNxb7I8TZ+c19HYqa0wt2+GoH8G13JUZ1+b8bI3kHfqME+8qWsWwkCP9eGZcTiI
whKVY+xChO2mPwJiAV0fFD0g/Obe6WdbIdI331onytjPSfviUYaNhG645jW+QyC8
mE3w1w2TQ/aLrpkJtpAOf/BYBmiAGKplQfx2qCQTifUE+7dYN81ZWGLc1dJYUKGX
8rTyCyhpL/btPvJVrgECYgCDEnInWkvVoJRxnwsyEYBt//TShufwiCpzhSY7NrnH
JF2xJLWMdOER+ryCd2Md5cw9oQr3E55ij8HZ/dllXrwPRMQiD5ZGOu22ryi1THf/
y1SdoTzw7bxFrvMcDxktPA+tAmIA7zMdP9iG6RYcud/2CbTSGmH3cQD3b8Adxysj
AN7/A7jWFS+Ar3p+vvOLckdbGpV0q0RcxtrPWL/cAK9WAEkCuz2j/lbEFaIXs9XB
71Le/PQ3GHMdRKcp1a3Wp8bOT9YtuQ==
-----END PRIVATE KEY-----
END

my $pkcs8_public_key = <<END;
-----BEGIN PUBLIC KEY-----
MIHhMA0GCSqGSIb3DQEBAQUAA4HPADCBywKBwwde8c8gmjLOItNCP51sq41w3fnv
eDH8W5kj3LPApGgfvhIXdvWMaSz2n8B21lGnC45AVM18WZZkOWEyhi7ywKQWQK1Z
Cthi2FqI/ysqr4NyQLKNF1jRvqgTPfFYJMPB7p0/Mtlydlo82RF+CUAFfe2Uf4Mr
PJY78UVJGAwB3h530TpZ1zCtwUxJkeD+0goOCiLq9MDp2gNZNMpCiEH20p3hietb
eepF7XxeBoFhigkFHufwB8mZztkCwuaEKTEsDv3O/wIDAQAB
-----END PUBLIC KEY-----
END

sub _pem_to_der {
    my ($pem) = @_;

    $pem =~ s<^-.+?$><>mgs;
    return MIME::Base64::decode($pem);
}

my $pub_der = _pem_to_der($pkcs8_public_key);
my $prv_der = _pem_to_der($pkcs8_key);

#----------------------------------------------------------------------

sub verify_public {
    my ($rsa_pub) = @_;

    is( $rsa_pub->modulus()->as_hex(), "0x$modulus_hex", 'modulus' );
    is( $rsa_pub->N()->as_hex(), "0x$modulus_hex", 'modulus, called N()' );

    is( $rsa_pub->size(),              $modulus_bits,    'size (i.e., modulus length)' );

    is( $rsa_pub->exponent(),          $exponent,        'exponent' );
    is( $rsa_pub->E(),          $exponent,        'exponent, called E()' );
}

for my $pub_pem ( $rsa_public_key, $pkcs8_public_key ) {
    note( "public(): " . ( $pub_pem =~ m<\A(.+?)$>ms && $1 ) );

    verify_public( Crypt::RSA::Parse::public($pub_pem) );
}

{
    note 'public_pkcs8()';

    verify_public( Crypt::RSA::Parse::public_pkcs8($pkcs8_public_key) );
}

{
    note 'public(), DER';
    verify_public( Crypt::RSA::Parse::public($pub_der) );

    note 'public_pkcs8(), DER';

    verify_public( Crypt::RSA::Parse::public_pkcs8($pub_der) );
}

#----------------------------------------------------------------------

sub verify_private {
    my ($rsa) = @_;

    is( $rsa->modulus()->as_hex(), "0x$modulus_hex", 'modulus' );
    is( $rsa->N()->as_hex(), "0x$modulus_hex", 'modulus, called N()' );

    is( $rsa->size(),    $modulus_bits, 'size (i.e., modulus length)' );
    is( $rsa->version(), 0,             'version' );

    is( $rsa->publicExponent(), $exponent, 'publicExponent' );
    is( $rsa->E(), $exponent, 'public exponent, called E()' );

    my @to_check = qw(
        privateExponent     D
        prime1              P
        prime2              Q
        exponent1           DP
        exponent2           DQ
        coefficient         QINV
    );

    for my $m (@to_check) {
        isa_ok( $rsa->$m(), 'Math::BigInt', $m );
    }

    return;
}

for my $pem ( $rsa_key, $pkcs8_key ) {
    note( "private(): " . ( $pem =~ m<\A(.+?)$>ms && $1 ) );

    verify_private( Crypt::RSA::Parse::private($pem) );
}

{
    note 'private_pkcs8()';

    verify_private( Crypt::RSA::Parse::private_pkcs8($pkcs8_key) );
}

{
    note 'private(), DER';
    verify_private( Crypt::RSA::Parse::private($prv_der) );

    note 'private_pkcs8(), DER';

    verify_private( Crypt::RSA::Parse::private_pkcs8($prv_der) );
}
