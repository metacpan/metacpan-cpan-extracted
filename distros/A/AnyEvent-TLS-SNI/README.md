= Adds Server Name Indication (SNI) support to AnyEvent::TLS client.

```
use AnyEvent::HTTP;
use AnyEvent::TLS::SNI;

my $cv = AnyEvent->condvar;
$cv->begin;
AnyEvent::HTTP::http_get(
    'https://sni.velox.ch/',
    tls_ctx => {
        verify => 1,
        verify_peername => 'https',
        host_name => 'sni.velox.ch'
    },
    sub {
        printf "Body length = %d\n", length( shift );
        $cv->end;
    }
);
$cv->recv;

```