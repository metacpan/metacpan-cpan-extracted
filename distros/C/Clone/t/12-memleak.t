#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Clone qw(clone);

# GH #42: Memory leak when cloning non-existent hash values
# When $hash{nonexistent_key} is passed directly to clone(), Perl creates
# a temporary SVt_PVLV (defelem) SV. The clone code treats PVLV types by
# just incrementing the refcount (clone == ref), but then the magic-cloning
# loop adds duplicate magic entries to the original SV, leaking the cloned
# mg_obj on every call.

# Helper: measure RSS in KB (portable across Linux and macOS)
sub get_rss_kb {
    if ($^O eq 'linux') {
        # /proc/self/status is available on Linux
        open my $fh, '<', '/proc/self/status' or return undef;
        while (<$fh>) {
            return $1 if /^VmRSS:\s+(\d+)\s+kB/;
        }
        return undef;
    }
    elsif ($^O eq 'darwin') {
        my $rss = `ps -o rss= -p $$`;
        chomp $rss;
        return $rss =~ /^\s*(\d+)/ ? $1 : undef;
    }
    return undef;
}

# Test 1: clone of non-existent hash key should return undef
{
    my $data = {};
    my $result = clone($data->{no_such_key});
    ok(!defined $result, "clone of non-existent hash key returns undef");
}

# Test 2: clone of non-existent hash key with populated hash
{
    my %hash = (a => 1, b => 2);
    my $result = clone($hash{no_such_key});
    ok(!defined $result, "clone of non-existent key in populated hash returns undef");
}

# Test 3: clone of non-existent hashref key
{
    my $data = { foo => 'bar' };
    my $result = clone($data->{nonexistent});
    ok(!defined $result, "clone of non-existent hashref key returns undef");
}

# Test 4: intermediate variable should not leak (baseline)
{
    my $data = {};
    my $before = get_rss_kb();
    SKIP: {
        skip "Cannot measure RSS on this platform", 1 unless defined $before;
        for (1..100_000) {
            my $tmp = $data->{no_such_key};
            clone($tmp);
        }
        my $after = get_rss_kb();
        my $delta = $after - $before;
        ok($delta < 2000, "clone via intermediate variable does not leak (delta: ${delta} KB)")
            or diag("Memory grew by $delta KB over 100K iterations");
    }
}

# Test 5: direct hash miss should not leak (the actual bug from GH #42)
{
    my $data = {};
    my $before = get_rss_kb();
    SKIP: {
        skip "Cannot measure RSS on this platform", 1 unless defined $before;
        for (1..100_000) {
            Clone::clone($data->{no_such_key});
        }
        my $after = get_rss_kb();
        my $delta = $after - $before;
        ok($delta < 2000, "clone of hash miss does not leak (delta: ${delta} KB)")
            or diag("Memory grew by $delta KB over 100K iterations — GH #42 regression");
    }
}

# Test 6: populated hash, direct miss should not leak
{
    my %hash = (a => 1, b => 2, c => 3);
    my $before = get_rss_kb();
    SKIP: {
        skip "Cannot measure RSS on this platform", 1 unless defined $before;
        for (1..100_000) {
            Clone::clone($hash{nonexistent});
        }
        my $after = get_rss_kb();
        my $delta = $after - $before;
        ok($delta < 2000, "clone of hash miss on populated hash does not leak (delta: ${delta} KB)")
            or diag("Memory grew by $delta KB over 100K iterations");
    }
}

# Test 7: clone of existing hash key should work fine and not leak
{
    my %hash = (key => "value");
    my $result = clone($hash{key});
    is($result, "value", "clone of existing hash key returns correct value");
}

# Test 8: clone of nested hash with non-existent key
{
    my $data = { inner => { a => 1 } };
    my $result = clone($data->{inner}{no_such_key});
    ok(!defined $result, "clone of non-existent key in nested hash returns undef");
}

done_testing;
