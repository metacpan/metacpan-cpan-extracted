use v5.10; use strict; use warnings;
use Test::More;
use Socket;
use POSIX qw(WNOHANG _exit);
use Curl::Impersonate;
local $ENV{no_proxy} = '*'; local $ENV{NO_PROXY} = '*';

socket(my $server, PF_INET, SOCK_STREAM, 0) or die $!;
bind($server, sockaddr_in(0, inet_aton('127.0.0.1'))) or die $!;
listen($server, 8) or die $!;
my $port = (sockaddr_in(getsockname($server)))[0];
my $pid = fork // die $!;
if (!$pid) {
    while (accept(my $s, $server)) {
        my $req = '';
        while (index($req, "\r\n\r\n") < 0) { sysread($s, my $b, 4096) or last; $req .= $b }
        my ($head, $body) = split /\r\n\r\n/, $req, 2;
        my ($method) = $head =~ /^(\S+)/;
        my ($length) = $head =~ /\r\ncontent-length:\s*(\d+)/i;
        $length //= 0; $body //= '';
        while (length($body) < $length) { sysread($s, my $b, 4096) or last; $body .= $b }
        my $response = "$method:$body";
        syswrite($s, "HTTP/1.1 200 OK\r\nContent-Length: " . length($response)
            . "\r\nX-Method: $method\r\nConnection: close\r\n\r\n"
            . ($method eq 'HEAD' ? '' : $response));
        close $s;
    }
    _exit(0);
}
close $server;
END {
    local $?;
    if ($pid && waitpid($pid, WNOHANG) == 0) { kill 'TERM', $pid; waitpid($pid, 0) }
}

for my $mode (qw(sync buffered streaming)) {
    my $h = Curl::Impersonate->new(impersonate => 'chrome131', timeout => 3);
    my $m = Curl::Impersonate->multi;
    for my $case (['POST', 'one'], ['HEAD'], ['GET'], ['HEAD'], ['POST', 'two'],
                  ['HEAD'], ['POST', ''], ['HEAD'], ['PUT', 'three'], ['GET']) {
        my ($method, $body) = @$case;
        my $req = { method => $method, url => "http://127.0.0.1:$port/", body => $body };
        my ($res, $headers, $bodies) = ({}, 0, 0);
        if ($mode eq 'sync') { $res = $h->request(%$req) }
        elsif ($mode eq 'buffered') {
            $m->add($h, $req, sub { $res = $_[0] // { error => $_[1] } });
            $m->perform_blocking;
        }
        else {
            $res->{body} = '';
            $m->add_streaming($h, $req, {
                on_headers => sub { $headers++; @{$res}{qw(status headers)} = @_ },
                on_body => sub { $bodies++; $res->{body} .= $_[0]; return 0 },
                on_done => sub { $res->{error} = $_[0] if $_[0] },
            });
            $m->perform_blocking;
            is($headers, 1, "$mode $method emits one response head");
            is($bodies, 0, 'streaming HEAD emits no body chunks') if $method eq 'HEAD';
        }
        is($res->{status}, 200, "$mode $method succeeds on a reused handle") or diag($res->{error} // '');
        is(($res->{headers} // {})->{'x-method'}, $method, 'origin receives the intended method');
        is($res->{body} // '', $method eq 'HEAD' ? '' : "$method:" . ($body // ''),
           'response body and request upload remain correct across HEAD transitions');
        is(($res->{headers} // {})->{'content-length'}, 5, 'HEAD sends no stale upload')
            if $method eq 'HEAD';
    }
}

done_testing;
