use v5.36;
use HTTP::Tiny;
use JSON::PP;

my $base = shift // 'http://127.0.0.1:5000';
my $http = HTTP::Tiny->new;
my $json = JSON::PP->new->canonical;

sub mcp ($payload) {
    say '--> ' . $json->encode($payload);
    my $res = $http->post( "$base/mcp", {
        headers => { 'Content-Type' => 'application/json' },
        content => $json->encode($payload),
    } );
    say "<-- HTTP $res->{status} "
        . ( length $res->{content} ? $res->{content} : '(empty body)' );
    say '';
    return $res->{success};
}

my $ok = 1;
$ok &&= mcp( { jsonrpc => '2.0', method => 'initialize',
    params => { protocolVersion => '2025-06-18' }, id => 1 } );
$ok &&= mcp( { jsonrpc => '2.0', method => 'tools/list', id => 2 } );
$ok &&= mcp( { jsonrpc => '2.0', method => 'tools/call',
    params => { name => 'echo', arguments => { msg => 'hi' } }, id => 3 } );
$ok &&= mcp( { jsonrpc => '2.0', method => 'resources/read',
    params => { uri => 'mem://greeting' }, id => 4 } );

exit( $ok ? 0 : 1 );
