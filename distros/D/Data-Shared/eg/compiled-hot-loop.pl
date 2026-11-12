#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::Shared qw(shared_get shared_compile sharedc_get);

my $root = Data::Shared->new;
my $native = eval { $root->mount('cache', 'hashmap:ii', undef, 100_000) };
die "hashmap backend unavailable: $@" unless $native;
$native->put($_, $_ * 10) for 1 .. 1000;

my $cp = shared_compile('/cache/500');
for my $name (qw(string compiled)) {
    my $v = $name eq 'string' ? shared_get($root, '/cache/500') : sharedc_get($root, $cp);
    print "$name: /cache/500 = $v\n";
    die "mismatch" unless $v == 5000;
}

# Written out, not through a coderef: a closure call per iteration would land in both numbers.
my $n = 50_000;
my $start = time();
shared_get($root, '/cache/500') for 1 .. $n;
printf "string   %d gets in %.2fs\n", $n, time() - $start;
$start = time();
sharedc_get($root, $cp) for 1 .. $n;
printf "compiled %d gets in %.2fs\n", $n, time() - $start;
print "see bench/ for stable numbers; \$root->handle('/cache') gives the native handle\n";
