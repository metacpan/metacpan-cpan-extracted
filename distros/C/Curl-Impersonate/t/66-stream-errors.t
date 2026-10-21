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
        syswrite($s, $req =~ m{^GET /empty }
            ? "HTTP/1.1 204 No Content\r\nConnection: close\r\n\r\n"
            : "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nhi");
        close $s;
    }
    _exit(0);
}
close $server;
END {
    local $?;
    if ($pid && waitpid($pid, WNOHANG) == 0) { kill 'TERM', $pid; waitpid($pid, 0) }
}

for my $case (['on_headers', '/body'], ['on_body', '/body'], ['on_headers', '/empty']) {
    my ($callback, $path) = @$case;
    my $h = Curl::Impersonate->new(impersonate => 'chrome131', timeout => 3);
    my $m = Curl::Impersonate->multi;
    my (@warnings, $error, $done, $body_calls);
    my $callbacks = {
        on_headers => sub {},
        on_body => sub { $body_calls++; return 0 },
        on_done => sub { $done++; $error = $_[0] },
    };
    $callbacks->{$callback} = sub { die "sink failed\n" };
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $m->add_streaming($h, { url => "http://127.0.0.1:$port$path" }, $callbacks);
        $m->perform_blocking;
    }
    ok($error, "$callback failure at $path reaches on_done as an error");
    is($done, 1, 'completion fires once');
    like(join('', @warnings), qr/\Q$callback\E died: sink failed/, 'original exception is reported');
    ok(!$body_calls, 'a failed response head prevents body delivery') if $callback eq 'on_headers';
    my $next = $h->get("http://127.0.0.1:$port/body");
    is($next->{status}, 200, 'handle remains reusable after callback failure');
    is($next->{body}, 'hi', 'subsequent transfer is complete');
}

done_testing;
