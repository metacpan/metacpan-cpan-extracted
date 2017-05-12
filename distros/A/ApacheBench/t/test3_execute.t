#!/usr/bin/perl

use strict;
use Test;
use HTTPD::Bench::ApacheBench;
use Net::HTTP;

BEGIN { plan tests => 25 }

my @urls = ( 'http://localhost/' );
my $n = 1;

my $b = HTTPD::Bench::ApacheBench->new;
ok(ref $b, "HTTPD::Bench::ApacheBench");

my $run0 = HTTPD::Bench::ApacheBench::Run->new({
    repeat => $n,
    urls   => [ @urls ],
    order  => "depth_first",
});
ok(ref $run0, "HTTPD::Bench::ApacheBench::Run");

$b->add_run($run0);
ok($b->run(0), $run0);
ok($b->run(0)->repeat, $n);

my $run0urls = $b->run(0)->urls;
ok(ref $run0urls, "ARRAY");
ok($#$run0urls, $#urls);
ok($b->run(0)->order, "depth_first");
ok($b->run(0)->cookies(['cookie=monster;']));
ok($b->run(0)->request_headers([map {"Accept-Encoding: text/html"} @urls]));

# we make three identical runs except the first will GET, the second will POST,
# and the third HEAD; the second run also uses the HTTP Keep-Alive feature
my $run1 = HTTPD::Bench::ApacheBench::Run->new({
    repeat => $n,
    urls   => [ @urls ],
    order  => "depth_first",
});
$run1->postdata([ map {"post"} @urls ]);
$run1->keepalive([map {1} @urls]);
$b->add_run($run1);
ok($b->run(1), $run1);

my $run2 = HTTPD::Bench::ApacheBench::Run->new({
    repeat => $n,
    urls   => [ @urls ],
    order  => "depth_first",
});
$run2->head_requests([ map {1} @urls ]);
$b->add_run($run2);
ok($b->run(2), $run2);

my $run1urls = $b->run(1)->urls;
ok(ref $run1urls, "ARRAY");
ok($#$run1urls, $#urls);
ok($b->run(1)->content_types([map {"text/plain"} @urls]));

my $run2urls = $b->run(2)->urls;
ok(ref $run2urls, "ARRAY");
ok($#$run2urls, $#urls);
ok($b->run(2)->content_types([map {"text/plain"} @urls]));


my ($host) = ( $urls[0] =~ m|http://([^/]+)| );
my $connected = Net::HTTP->new( Host => $host );

if (! defined $connected) {
    print STDERR "\n  Cannot connect to http server on: ".join(',', @urls)."\n  reason: $@\n ... skipping remaining tests\n";
    foreach (1..8) { skip(1, 1) }
    exit();
}

print STDERR "\n  Sending HTTP requests to: ".join(',', @urls)."\n";
my $rg = $b->execute;

ok(ref $rg, "HTTPD::Bench::ApacheBench::Regression");

if (! $run0->sent_requests(0) || ! $run1->sent_requests(0) || ! $run2->sent_requests(0)
      || $run0->failed_responses(0) || $run1->failed_responses(0) || $run2->failed_responses(0)) {
    print STDERR "\n  Cannot connect to http server on: ".join(',', @urls)." ... skipping remaining tests\n";
    foreach (1..7) { skip(1, 1) }

} else {
    print STDERR ("\n  ".$b->bytes_received . " bytes, " . $b->total_responses_received .
                    " responses received in " . $b->total_time . " ms");
    my $total_time = $b->total_time || 0.0001; # prevent division by zero for very fast responses, e.g. localhost
    print STDERR ("\n  ".$b->total_responses_received*1000 / $total_time) . " req/sec";
    print STDERR ("\n  ".$b->bytes_received*1000/1024 / $total_time) . " kb/sec\n";
    
    ok(defined $b->total_responses_received);
    ok(defined $b->total_time);
    ok(defined $b->bytes_received);
    ok(!defined $b->response_times);
    ok(ref $rg->run(0)->iteration(0)->response_times, "ARRAY");
    ok(ref $rg->run(1)->iteration(0)->response_times, "ARRAY");
    ok(ref $rg->run(2)->iteration(0)->response_times, "ARRAY");
}
