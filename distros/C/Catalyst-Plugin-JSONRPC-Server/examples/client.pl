use v5.36;
use HTTP::Tiny;
use JSON::PP;

my $base = shift // 'http://127.0.0.1:5000';
my $http = HTTP::Tiny->new;
my $json = JSON::PP->new->canonical;

sub rpc ($payload) {
    say '--> ' . $json->encode($payload);
    my $res = $http->post( "$base/rpc", {
        headers => { 'Content-Type' => 'application/json' },
        content => $json->encode($payload),
    } );
    say "<-- HTTP $res->{status} "
        . ( length $res->{content} ? $res->{content} : '(empty body)' );
    say '';
    return $res->{success};
}

my $ok = 1;
# single call
$ok &&= rpc( { jsonrpc => '2.0', method => 'sum', params => [ 1, 2, 3, 4 ], id => 1 } );
# batch: a call plus a call to an unregistered method (-32601)
$ok &&= rpc( [
    { jsonrpc => '2.0', method => 'echo', params => ['hello'], id => 2 },
    { jsonrpc => '2.0', method => 'nope', id => 3 },
] );

exit( $ok ? 0 : 1 );
