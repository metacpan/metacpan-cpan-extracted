use Test::More;
use lib 't/lib';

BEGIN {   
    use_ok('Crypt::JWS::OpenSSL');
}

for my $tconf (
    [ 0.33, 1, 0, 0 ],
    [ 0.34, 1, 0, 0 ],
    [ 0.35, 1, 0, 0 ],
    [ 0.36, 0, 0, 1 ],
    [ 0.37, 0, 0, 1 ],
    [ 0.38, 1, 0, 1 ],
    [ 0.39, 1, 0, 1 ],
    [ 0.41, 1, 0, 1 ],
    ) {
    my ( $corver, $pkcs1, $pss_0, $pss_3 ) = @{ $tconf };
    $Crypt::OpenSSL::RSA::VERSION = $corver;
    my $h = Crypt::JWS::OpenSSL->new();
    $Crypt::JWS::OpenSSL::Local::HAS_OPENSSL3 = 0;
    is($h->can_use_pkcs1_padding, $pkcs1, qq($corver and not openssl 3 can_use_pkcs1_padding) );
    is($h->can_use_pkcs1_pss_padding, $pss_0, qq($corver and not openssl 3 can_use_pkcs1_pss_padding) );
    $Crypt::JWS::OpenSSL::Local::HAS_OPENSSL3 = 1;
    is($h->can_use_pkcs1_padding, $pkcs1, qq($corver and openssl 3 can_use_pkcs1_padding) );
    is($h->can_use_pkcs1_pss_padding, $pss_3, qq($corver and openssl 3 can_use_pkcs1_pss_padding) );   
}


 done_testing();
 
 1;
