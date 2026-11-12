#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Data::Shared qw(shared_get shared_set shareda_get shared_compile sharedc_get sharedc_set shared_call shared_push shared_pop sharedc_push sharedc_pop);

my $secs = $ENV{DS_BENCH_TIME} || 2;

print "Data::Shared facade overhead (higher is better; native = leaf called directly)\n";
print "Each group runs for ${secs}s per case. Indicative only; see results.txt.\n\n";

{
    print "== HashMap::II get ==\n";
    my $root = Data::Shared->new;
    my $native = $root->mount('cache', 'hashmap:ii', undef, 100_000);
    $native->put($_, $_ * 10) for 1 .. 1000;
    my $cp = shared_compile('/cache/500');
    my $arr = ['cache', '500'];
    cmpthese(-$secs, {
        native   => sub { my $v = $native->get(500) },
        string   => sub { my $v = shared_get($root, '/cache/500') },
        array    => sub { my $v = shareda_get($root, $arr) },
        compiled => sub { my $v = sharedc_get($root, $cp) },
        call     => sub { my $v = shared_call($root, '/cache', 'get', 500) },
    });
    print "\n== HashMap::II set ==\n";
    cmpthese(-$secs, {
        native   => sub { $native->put(500, 5000) },
        string   => sub { shared_set($root, '/cache/500', 5000) },
        compiled => sub { sharedc_set($root, $cp, 5000) },
    });
}

{
    print "\n== Queue::Int push+pop (rate is per push+pop pair) ==\n";
    my $root = Data::Shared->new;
    my $native = $root->mount('jobs', 'queue:int', undef, 8192);
    my $cp = shared_compile('/jobs');
    cmpthese(-$secs, {
        native   => sub { $native->push(42); my $v = $native->pop },
        string   => sub { shared_push($root, '/jobs', 42); my $v = shared_pop($root, '/jobs') },
        compiled => sub { sharedc_push($root, $cp, 42); my $v = sharedc_pop($root, $cp) },
    });
}

{
    print "\n== HyperLogLog add / count via shared_call ==\n";
    my $root = Data::Shared->new;
    my $native = $root->mount('visitors', 'hyperloglog', undef, 14);
    cmpthese(-$secs, {
        'native add'  => sub { $native->add('alice') },
        'call add'    => sub { shared_call($root, '/visitors', 'add', 'alice') },
        'native count' => sub { my $v = $native->count },
        'call count'  => sub { my $v = shared_call($root, '/visitors', 'count') },
    });
}

{
    print "\n== NDArray get [0,1] ==\n";
    my $root = Data::Shared->new;
    my $native = $root->mount('lat', 'ndarray', undef, 'f64', 10, 10);
    $native->set(0, 1, 1.5);
    my $cp = shared_compile('/lat/0/1');
    cmpthese(-$secs, {
        native   => sub { my $v = $native->get(0, 1) },
        string   => sub { my $v = shared_get($root, '/lat/0/1') },
        compiled => sub { my $v = sharedc_get($root, $cp) },
    });
}
