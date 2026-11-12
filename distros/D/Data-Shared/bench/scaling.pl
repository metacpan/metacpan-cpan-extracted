#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp qw(tempdir);
use Time::HiRes qw(time);
use POSIX qw(_exit);
use JSON::PP qw(encode_json decode_json);
use Data::Shared qw(shared_compile sharedc_get);

my @sizes = split /,/, $ENV{DS_BENCH_SIZES} || '100,1000,3000';
my $working = $ENV{DS_BENCH_WORKING_SET} || 128;
my $iterations = $ENV{DS_BENCH_ITERATIONS} || 2000;
my $workers = $ENV{DS_BENCH_WORKERS} || 4;
for my $value (@sizes, $working, $iterations, $workers) {
    die "benchmark sizes must be positive integers\n" unless $value =~ /\A[1-9]\d*\z/;
}

sub cpu { my @t = times; return $t[0] + $t[1] }
sub rss {
    open my $fh, '<', "/proc/$$/status" or die $!;
    while (<$fh>) { return $1 if /^VmRSS:\s+(\d+)/ }
    return 0;
}
sub percentiles {
    my @values = sort { $a <=> $b } @_;
    return map { $values[int(($#values) * $_)] } (0.50, 0.95, 0.99);
}
sub mount_maps {
    my ($root, $children, $cache, $leaf) = @_;
    $root->mount('users', { spec => 'hashmap:ss', args => [$children + 1],
        child => { spec => $leaf || 'hashmap:ss', args => [16] },
        max_children => $children, cache_size => $cache });
}

print "Perl $^V; wall time and process CPU time; RSS includes the Perl interpreter and allocator history\n";
print "Creation scaling (anonymous children; cache_size=child_count)\n";
for my $n (@sizes) {
    my $root = Data::Shared->new;
    mount_maps($root, $n, $n);
    my ($wall, $cpu) = (time, cpu());
    $root->set("/users/$_/name", "name$_") for 1 .. $n;
    ($wall, $cpu) = (time - $wall, cpu() - $cpu);
    die "child budget mismatch\n" unless $root->call('/users', 'child_count') == $n;
    printf "%6d children  wall=%7.3f s CPU=%7.3f s %8.1f wall us/child RSS=%d KiB\n",
        $n, $wall, $cpu, 1e6 * $wall / $n, rss();
}

print "\nWorking set: $working file-backed children, $iterations cycling compiled reads\n";
my %seen;
for my $cache (grep { !$seen{$_}++ } (1, 32, $working)) {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    mount_maps($root, $working, $cache);
    $root->set("/users/$_/name", "name$_") for 0 .. $working - 1;
    my @paths = map { shared_compile("/users/$_/name") } 0 .. $working - 1;
    my @latency;
    my ($wall, $cpu) = (time, cpu());
    for my $i (0 .. $iterations - 1) {
        my $id = $i % $working;
        my $start = time;
        my $value = sharedc_get($root, $paths[$id]);
        push @latency, 1e6 * (time - $start);
        die "lost child data\n" unless defined $value && $value eq "name$id";
    }
    ($wall, $cpu) = (time - $wall, cpu() - $cpu);
    printf "cache=%4d wall=%6.3f s CPU=%6.3f s p50=%7.2f p95=%7.2f p99=%7.2f wall us RSS=%d KiB\n",
        $cache, $wall, $cpu, percentiles(@latency), rss();
}

print "\nContention: $workers processes, $iterations increments each, one shared child counter\n";
my $root = Data::Shared->new(tempdir(CLEANUP => 1));
mount_maps($root, 1, 1, 'hashmap:ii');
$root->set('/users/shared/0', 0);
pipe my $ready_r, my $ready_w or die $!;
pipe my $go_r, my $go_w or die $!;
my @pids;
for my $worker (1 .. $workers) {
    my $pid = fork(); die $! unless defined $pid;
    if (!$pid) {
        close $ready_r; close $go_w;
        my $ok = eval {
            my $child = Data::Shared->open($root->dir);
            syswrite($ready_w, 'r') == 1 or die $!;
            sysread($go_r, my $go, 1) == 1 or die 'missing start signal';
            my @latency;
            my $cpu = cpu();
            for (1 .. $iterations) {
                my $start = time;
                $child->incr('/users/shared/0');
                push @latency, 1e6 * (time - $start);
            }
            $cpu = cpu() - $cpu;
            open my $fh, '>', $root->dir . "/worker-$worker.json" or die $!;
            print {$fh} encode_json({ latency => \@latency, cpu => $cpu, rss => rss() });
            close $fh or die $!;
            1;
        };
        warn $@ unless $ok;
        _exit($ok ? 0 : 1);
    }
    push @pids, $pid;
}
close $ready_w; close $go_r;
my $ready = '';
while (length $ready < $workers) {
    sysread($ready_r, my $next, $workers - length $ready) > 0 or die 'worker exited before barrier';
    $ready .= $next;
}
my $wall = time;
syswrite($go_w, 'g' x $workers) == $workers or die $!;
close $go_w;
for my $pid (@pids) {
    waitpid $pid, 0;
    die "worker $pid failed: $?\n" if $?;
}
$wall = time - $wall;
my (@latency, @rss);
my $cpu = 0;
for my $worker (1 .. $workers) {
    open my $fh, '<', $root->dir . "/worker-$worker.json" or die $!;
    my $data = decode_json(do { local $/; <$fh> });
    push @latency, @{ $data->{latency} };
    push @rss, $data->{rss};
    $cpu += $data->{cpu};
}
my $total = $workers * $iterations;
die "lost increments\n" unless $root->get('/users/shared/0') == $total;
printf "%d operations wall=%.3f s worker CPU=%.3f s %.0f op/s p50=%.2f p95=%.2f p99=%.2f wall us\n",
    $total, $wall, $cpu, $total / $wall, percentiles(@latency);
print 'worker RSS KiB: ', join(', ', @rss), "\n";
