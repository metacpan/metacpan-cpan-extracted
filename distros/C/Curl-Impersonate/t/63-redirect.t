use v5.10; use strict; use warnings;
use Test::More;
use Socket;
use POSIX qw(WNOHANG _exit);
use Curl::Impersonate;
local $ENV{no_proxy} = '*'; local $ENV{NO_PROXY} = '*';

socket(my $srv, PF_INET, SOCK_STREAM, 0) or die "socket: $!";
setsockopt($srv, SOL_SOCKET, SO_REUSEADDR, 1);
bind($srv, sockaddr_in(0, inet_aton('127.0.0.1'))) or die "bind: $!";
listen($srv, 5) or die "listen: $!";
my $port = (sockaddr_in(getsockname($srv)))[0];
my $pid = fork // die "fork: $!";
if (!$pid) {
    while (accept(my $c, $srv)) {
        my $req = ''; while (index($req, "\r\n\r\n") < 0) { sysread($c, my $b, 4096) or last; $req .= $b }
        my ($head, $upload) = split /\r\n\r\n/, $req, 2;
        my ($method, $path) = $head =~ m{^(\S+)\s+(\S+)};
        my ($length) = $head =~ /\r\ncontent-length:\s*(\d+)/i;
        $length //= 0; $upload //= '';
        while (length($upload) < $length) { sysread($c, my $b, 4096) or last; $upload .= $b }
        if (($path // '') =~ m{/final}) {
            my $body = '{"ok":1}';
            syswrite($c, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
                       . "X-Method: $method\r\nX-Upload: $upload\r\n"
                       . "Content-Length: " . length($body) . "\r\nConnection: close\r\n\r\n"
                       . ($method eq 'HEAD' ? '' : $body));
        } else {
            my ($status) = $path =~ m{/start/(\d+)};
            $status //= 302;
            syswrite($c, "HTTP/1.1 $status Redirect\r\nLocation: /final\r\nContent-Type: text/html\r\n"
                       . "Set-Cookie: hop=1\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
        }
        close $c;
    }
    _exit(0);
}
close $srv;
END {
    local $?;
    if ($pid && waitpid($pid, WNOHANG) == 0) { kill 'TERM', $pid; waitpid($pid, 0) }
}

my $c = Curl::Impersonate->new(impersonate => 'chrome131', timeout => 3, follow_redirects => 1);
my $r = $c->get("http://127.0.0.1:$port/start");

is($r->{status}, 200, 'followed the 302 to the final 200');
# the result must carry ONLY the final response's headers, not the 302 hop merged in
is($r->{headers}{'content-type'}, 'application/json',
   'content-type is the final scalar (not an arrayref merged with the 302 text/html)');
ok(!ref $r->{headers}{'content-type'}, 'content-type is a scalar, not an arrayref');
ok(!exists $r->{headers}{location},     'the 302-only Location did not leak into the final headers');
ok(!exists $r->{headers}{'set-cookie'}, 'the 302-only Set-Cookie did not leak into the final headers');

my $m = Curl::Impersonate->multi;
for my $mode (qw(sync streaming)) {
    for my $case (['POST', 301, 'GET'], ['POST', 302, 'GET'], ['POST', 303, 'GET'],
                  ['POST', 307, 'POST'], ['POST', 308, 'POST'], ['PUT', 302, 'PUT'],
                  ['PUT', 303, 'GET'], ['PUT', 307, 'PUT'], ['PATCH', 302, 'PATCH'],
                  ['PATCH', 303, 'GET'], ['DELETE', 303, 'GET'], ['HEAD', 303, 'HEAD']) {
        my ($method, $status, $expected) = @$case;
        my $body = $method =~ /^(?:POST|PUT|PATCH)$/ ? 'x=1' : undef;
        my $req = { method => $method, url => "http://127.0.0.1:$port/start/$status", body => $body };
        my $res = {};
        if ($mode eq 'sync') { $res = $c->request(%$req) }
        else {
            $res->{body} = '';
            $m->add_streaming($c, $req, {
                on_headers => sub { @{$res}{qw(status headers)} = @_ },
                on_body => sub { $res->{body} .= $_[0]; return 0 },
                on_done => sub { $res->{error} = $_[0] if $_[0] },
            });
            $m->perform_blocking;
        }
        is($res->{status}, 200, "$mode $method follows $status") or diag($res->{error} // '');
        is(($res->{headers} // {})->{'x-method'}, $expected, 'redirect uses the intended method');
        is(($res->{headers} // {})->{'x-upload'}, $expected eq 'GET' ? '' : ($body // ''),
           'redirect preserves or drops the upload with its method');
        is($res->{body}, $expected eq 'HEAD' ? '' : '{"ok":1}', 'final response body is complete');
    }
}
done_testing;
