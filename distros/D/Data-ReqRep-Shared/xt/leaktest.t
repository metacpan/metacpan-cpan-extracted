use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

sub rss_kb {
    open my $fh, '<', '/proc/self/status' or return 0;
    while (<$fh>) { return $1 if /^VmRSS:\s+(\d+)/ }
    return 0;
}

plan skip_all => '/proc/self/status not available' unless rss_kb() > 0;

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 64, 16, 256);
my $cli = Data::ReqRep::Shared::Client->new($path);

for (1..500) {
    my $id = $cli->send("warmup");
    my ($r, $ri) = $srv->recv;
    $srv->reply($ri, "ok");
    $cli->get($id);
}

my $before = rss_kb();
for (1..10_000) {
    my $id = $cli->send("leak_test");
    my ($r, $ri) = $srv->recv;
    $srv->reply($ri, "ok");
    $cli->get($id);
}
my $after = rss_kb();
my $growth = $after - $before;
ok $growth < 1024, "RSS growth after 10K round-trips: ${growth}KB (should be < 1MB)"
    or diag "before=${before}KB after=${after}KB";

$before = rss_kb();
for (1..10_000) {
    my $id = $cli->send("cancel_leak");
    $cli->cancel($id) if defined $id;
}
while (my ($r, $ri) = $srv->recv) { $srv->reply($ri, "ok") }
$after = rss_kb();
$growth = $after - $before;
ok $growth < 1024, "RSS growth after 10K cancel cycles: ${growth}KB (should be < 1MB)"
    or diag "before=${before}KB after=${after}KB";

$before = rss_kb();
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    while (my ($r, $ri) = $srv->recv_wait(5.0)) {
        $srv->reply($ri, "ok");
    }
    exit 0;
}
for (1..5_000) {
    $cli->req("req_leak");
}
$after = rss_kb();
$growth = $after - $before;
ok $growth < 1024, "RSS growth after 5K req() cycles: ${growth}KB (should be < 1MB)"
    or diag "before=${before}KB after=${after}KB";
waitpid $pid, 0;

$before = rss_kb();
for (1..2_000) {
    my $c = Data::ReqRep::Shared::Client->new($path);
}
$after = rss_kb();
$growth = $after - $before;
ok $growth < 1024, "RSS growth after 2K client create/destroy: ${growth}KB (should be < 1MB)"
    or diag "before=${before}KB after=${after}KB";

$srv->unlink;
done_testing;
