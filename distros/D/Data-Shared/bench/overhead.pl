#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(countit);
use Data::Shared qw(shared_get shareda_get shared_compile sharedc_get shared_call);

my $root = Data::Shared->new;
my $native = $root->mount('cache', 'hashmap:ii', undef, 100_000);
$native->put($_, $_ * 10) for 1 .. 1000;

my $cp = shared_compile('/cache/500');
my $arr = ['cache', '500'];
my $closure = do { my $h = $native; my $k = 500; sub { $h->get($k) } };

my $secs = $ENV{DS_BENCH_TIME} || 2;
for my $case (
    ['native',       sub { my $v = $native->get(500) }],
    ['perl closure', sub { my $v = $closure->() }],
    ['string',       sub { my $v = shared_get($root, '/cache/500') }],
    ['array',        sub { my $v = shareda_get($root, $arr) }],
    ['compiled',     sub { my $v = sharedc_get($root, $cp) }],
    ['call',         sub { my $v = shared_call($root, '/cache', 'get', 500) }],
) {
    my ($name, $code) = @$case;
    my $r = countit($secs, $code);
    my $cpu = $r->cpu_p;
    if ($cpu <= 0) {
        printf "%-14s no CPU time measured; raise DS_BENCH_TIME\n", $name;
        next;
    }
    my $rate = $r->iters / $cpu;
    printf "%-14s %10.0f/s  %6.2f us/op\n", $name, $rate, 1e6 / $rate;
}
print "sanity: ", shared_get($root, '/cache/500'), "\n";
