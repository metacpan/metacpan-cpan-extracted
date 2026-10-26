use v5.40;
use blib;
$|++;
use Acme::Parataxis qw[:all];
use IO::Socket::INET;
use Time::HiRes qw[time];

# A miniature HTTP/1.1 server: one parataxis fiber per connection, every
# socket operation a park (await_read/await_write) rather than a block, so
# many connections make progress on a single OS thread. A convoy of two
# self-test client fibers pushes REQUESTS_TARGET requests through it, then
# the demo winds down and exits 0.
#
#   GET  /         index page
#   GET  /hello    fixed text reply
#   GET  /slow     parks the handler (await_sleep 0.3s) before replying
#   POST /echo     echoes the request body
#   anything else  404
my $REQUESTS_TARGET = 12;
my $requests        = 0;
my $shutdown        = 0;

sub index_html {
    return join '', "<h1>parataxis mini HTTP server</h1>\n", "<p>one fiber per connection. Try <a href=\"/hello\">/hello</a>, ",
        "park on <a href=\"/slow\">/slow</a>, or POST to <code>/echo</code>.</p>\n";
}

# Serve one request on an accepted connection: read the header block and the
# Content-Length body with parked reads, then reply with parked writes. Each
# read/write suspends this fiber and lets a sibling advance.
sub serve_connection ($conn) {
    my $buf = '';
    while ( index( $buf, "\r\n\r\n" ) < 0 ) {
        my $r = await_read( $conn, 3000 );
        return if !defined $r || $r <= 0;
        my $n = sysread( $conn, my $chunk, 65536 );
        return if !defined $n || $n == 0;
        $buf .= $chunk;
    }
    my ( $head, $rest ) = split /\r\n\r\n/, $buf, 2;
    $buf = $rest // '';    # pipelined bytes, if any
    my @lines = split /\r\n/, $head;
    my ( $method, $path ) = split ' ', shift @lines;
    return if !$method || !$path;
    my %headers;
    for my $line (@lines) {
        my ( $k, $v ) = split /:\s*/, $line, 2;
        $headers{ lc $k } = $v if defined $v;
    }
    my $cl = $headers{'content-length'} // 0;
    while ( length $buf < $cl ) {
        my $r = await_read( $conn, 3000 );
        return if !defined $r || $r <= 0;
        my $n = sysread( $conn, my $chunk, 65536 );
        return if !defined $n || $n == 0;
        $buf .= $chunk;
    }
    my $body = $cl ? substr( $buf, 0, $cl ) : '';
    my ( $status, $ctype, $content ) = ( '200 OK', 'text/plain', '' );
    if ( $method eq 'GET' && $path eq '/' ) {
        $ctype   = 'text/html';
        $content = index_html();
    }
    elsif ( $method eq 'GET' && $path eq '/hello' ) {
        $content = "hello from parataxis\n";
    }
    elsif ( $method eq 'GET' && $path eq '/slow' ) {
        await_sleep(300);    # the handler parks 300ms; sibling fibers keep running
        $content = "slow reply, after a 300ms park\n";
    }
    elsif ( $method eq 'POST' && $path eq '/echo' ) {
        $content = "echoed $cl bytes: $body";
    }
    else {
        $status  = '404 Not Found';
        $content = "no route: $method $path\n";
    }
    $requests++;
    say sprintf '  [fiber %-2d] %-4s %-8s -> %4d bytes  (%s)', current_fid(), $method, $path, length $content, $status;
    $shutdown = 1 if $requests >= $REQUESTS_TARGET;
    my $resp
        = "HTTP/1.1 $status\r\n" .
        "Content-Type: $ctype\r\n" .
        'Content-Length: ' .
        length($content) . "\r\n" .
        "Connection: close\r\n\r\n" .
        $content;
    while ( length $resp ) {
        my $r = await_write( $conn, 3000 );
        return if !defined $r || $r <= 0;
        my $w = syswrite( $conn, $resp );
        return if !defined $w || $w == 0;
        substr( $resp, 0, $w ) = '';
    }
    $conn->close();
}

# Listen for connections, and hand each one to a fresh handler fiber.
sub accept_loop ($listener) {
    while ( !$shutdown ) {
        my $r = await_read( $listener, 100 );
        next if !defined $r || $r <= 0;
        while ( my $conn = $listener->accept ) {
            $conn->blocking(0);
            $conn->autoflush(1);
            my $fd = fileno($conn);
            spawn( sub { say "  accepted fd=$fd"; serve_connection($conn) } );
        }
    }
    $listener->close();
}

# One raw HTTP request over a non-blocking socket; retire when the peer
# closes (Connection: close), and return (status_code, full_response).
sub http_request ( $port, $method, $path, $body = '' ) {
    my $sock = IO::Socket::INET->new( PeerHost => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Blocking => 0 ) or return 0;
    $sock->autoflush(1);
    my $req = "$method $path HTTP/1.1\r\nHost: 127.0.0.1:$port\r\n";
    $req .= 'Content-Length: ' . length($body) . "\r\n" if length $body;
    $req .= "Connection: close\r\n\r\n" . $body;
    my $sent = 0;
    while ( $sent < length $req ) {
        my $r = await_write( $sock, 3000 );
        return 0 if !defined $r || $r <= 0;
        my $w = syswrite( $sock, $req, length($req) - $sent, $sent );
        return 0 if !defined $w;
        $sent += $w;
    }
    my $resp = '';
    while (1) {
        my $r = await_read( $sock, 3000 );
        last if !defined $r || $r <= 0;
        my $n = sysread( $sock, my $chunk, 65536 );
        last if !defined $n;
        last if $n == 0;       # EOF
        $resp .= $chunk;
    }
    $sock->close();
    ( my $sline ) = split /\r\n/, $resp;
    my ($code) = $sline =~ m{\AHTTP/1\.[01]\s+(\d{3})};
    return $code // 0;
}

sub client_worker ( $port, $n ) {
    my $fid = current_fid();
    my $ok  = 0;
    for my $i ( 1 .. $n ) {
        my ( $method, $path, $code );
        if ( $i % 3 == 0 ) {
            ( $method, $path ) = ( 'POST', '/echo' );
            $code = http_request( $port, 'POST', '/echo', "payload from fiber $fid (#$i)" );
        }
        elsif ( $i % 3 == 1 ) {
            ( $method, $path ) = ( 'GET', '/hello' );
            $code = http_request( $port, 'GET', '/hello' );
        }
        else {
            ( $method, $path ) = ( 'GET', '/slow' );
            my $t = time;
            $code = http_request( $port, 'GET', '/slow' );
            say sprintf '  [fiber %-2d] client: %-4s %-8s -> HTTP %s (%.1fms of handler park)', $fid, $method, $path, $code ? 200 : 'ERR',
                ( time() - $t ) * 1000;
        }
        $ok++ if $code == 200;
    }
    return $ok;
}
Acme::Parataxis::run(
    sub {
        my $listener = IO::Socket::INET->new( LocalHost => '127.0.0.1', LocalPort => 0, Proto => 'tcp', Listen => 64, Reuse => 1 ) or
            die "cannot listen: $!";
        $listener->blocking(0);
        my $port = $listener->sockport;
        say "parataxis HTTP/1.1 server on  http://127.0.0.1:$port";
        say "driving $REQUESTS_TARGET requests from two concurrent client fibers...";
        my $t0 = time;
        spawn( sub { accept_loop($listener) } );
        my @clients;
        push @clients, spawn( sub { client_worker( $port, $REQUESTS_TARGET / 2 ) } ) for 1 .. 2;
        my $ok = 0;

        for my $c (@clients) {
            $ok += $c->await;
        }
        $shutdown = 1;
        my $dt = time() - $t0;
        say '';
        say sprintf '%d/%d requests returned HTTP 200 in %.3fs (%.1f req/s)', $ok, $REQUESTS_TARGET, $dt, $REQUESTS_TARGET / $dt;
        say 'each client waits behind two 300ms handler parks; the wall time shows the parks overlap.';
        die "self-test failed: got $ok/$REQUESTS_TARGET HTTP 200\n" if $ok != $REQUESTS_TARGET;
        stop();
    }
);
say 'exit 0';
