use AnyEvent::HTTP;
use Test::More;
use Net::SSLeay;

if ( Net::SSLeay::OPENSSL_VERSION_NUMBER() < 0x01000000 ) {
    done_testing();
    exit;
}

use_ok AnyEvent::TLS::SNI;

# my $cv = AnyEvent->condvar;

# my $body_sni;
# $cv->begin;
# AnyEvent::HTTP::http_get(
#     'https://sni.velox.ch/',
#     tls_ctx => {
#         verify => 1,
#         verify_peername => 'https',
#         host_name => 'sni.velox.ch'
#     },
#     sub {
#         $body_sni = shift;
#         $cv->end;
#     }
# );

# $cv->recv;

# ok length( $body_sni ), 'SNI on';

done_testing();