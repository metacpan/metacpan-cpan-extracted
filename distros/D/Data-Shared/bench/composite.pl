#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(countit);
use File::Temp qw(tempdir);
use Data::Shared qw(shared_compile sharedc_get);

my $secs = $ENV{DS_BENCH_TIME} || 2;
my $children = $ENV{DS_BENCH_CHILDREN} || 64;
die "DS_BENCH_CHILDREN must be an integer >= 2\n" unless $children =~ /^\d+$/ && $children >= 2;

print "Composite reads: $children children, file cache_size=1, at least ${secs}s CPU per case\n";
for my $storage ('anonymous', 'file') {
    my $root = Data::Shared->new($storage eq 'file' ? tempdir(CLEANUP => 1) : undef);
    $root->mount('users', {
        spec => 'hashmap:ss', args => [$children + 1],
        child => { spec => 'hashmap:ss', args => [16] },
        max_children => $children, cache_size => 1,
    });
    $root->set("/users/$_/name", "name$_") for 0 .. $children - 1;
    my @paths = map { shared_compile("/users/$_/name") } 0 .. $children - 1;
    my $native = $root->handle('/users/0');
    die "missing child value\n" unless $root->get('/users/0/name') eq 'name0';
    my $i = 0;
    for my $case (
        ['native', sub { $native->get('name') }],
        ['string warm', sub { $root->get('/users/0/name') }],
        ['compiled warm', sub { sharedc_get($root, $paths[0]) }],
        ['compiled cycling', sub { $i = ($i + 1) % $children; sharedc_get($root, $paths[$i]) }],
    ) {
        my ($name, $code) = @$case;
        my $result = countit($secs, $code);
        my $rate = $result->iters / $result->cpu_p;
        printf "%-10s %-18s %10.0f/s %8.2f us/op\n", $storage, $name, $rate, 1e6 / $rate;
    }
    for my $id (0 .. $children - 1) {
        die "child $id lost data\n" unless $root->get("/users/$id/name") eq "name$id";
    }
}
