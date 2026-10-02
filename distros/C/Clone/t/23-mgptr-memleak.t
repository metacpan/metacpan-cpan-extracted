#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Clone qw(clone);

# Test for memory leak in magic mg_ptr cloning.
# When an SV has magic with mg_len >= 0 and non-null mg_ptr (e.g. vstring
# magic), sv_magic() makes its own copy via savepvn().  An intermediate
# Newxz buffer was being allocated but never freed — leaked on every clone.

# Helper: measure RSS in KB (portable across Linux and macOS)
sub get_rss_kb {
    if ($^O eq 'linux') {
        open my $fh, '<', '/proc/self/status' or return undef;
        while (<$fh>) {
            return $1 if /^VmRSS:\s+(\d+)\s+kB/;
        }
        return undef;
    }
    elsif ($^O eq 'darwin') {
        # Use list form of open to avoid invoking a shell. Also redirect
        # STDERR to /dev/null before the fork so that if the exec is blocked
        # by a sandbox (e.g. MacPorts build user with no valid shell), the
        # "Can't exec" message from the child is discarded instead of
        # polluting test output. STDERR is restored when the function returns
        # via Perl's 'local' mechanism.  (mirrors t/12-memleak.t, GH #122)
        open(local *STDERR, '>', '/dev/null') or return undef;
        open(my $ps, '-|', '/bin/ps', '-o', 'rss=', '-p', $$) or return undef;
        my $rss = <$ps>;
        close $ps;
        return defined($rss) && $rss =~ /^\s*(\d+)/ ? $1 : undef;
    }
    return undef;
}

# Test 1: vstring clone produces correct value
{
    my $v = v1.2.3;
    my $c = clone($v);
    ok($v eq $c, "vstring clone produces equal value");
}

# Test 2: vstring clone is independent
{
    my $v = v5.10.1;
    my $c = clone($v);
    ok(\$v != \$c, "vstring clone is a separate SV");
}

# Test 3: vstring magic is preserved on clone
SKIP: {
    eval { require B; 1 } or skip "B module not available", 2;
    my $v = v1.2.3;
    my $c = clone($v);

    my $orig_sv = B::svref_2object(\$v);
    my $clone_sv = B::svref_2object(\$c);

    my $orig_mg = $orig_sv->MAGIC;
    my $clone_mg = $clone_sv->MAGIC;

    ok($orig_mg && $orig_mg->TYPE eq 'V', "original has vstring magic");
    ok($clone_mg && $clone_mg->TYPE eq 'V', "clone has vstring magic");
}

# Test 4: repeated vstring cloning does not leak memory
# The old code allocated an intermediate buffer via Newxz for each
# mg_ptr copy, then sv_magic() made its own copy via savepvn(),
# leaking the Newxz buffer on every clone() call.
{
    my $v = v1.20.300.4000;
    my $before = get_rss_kb();
    SKIP: {
        skip "Cannot measure RSS on this platform", 1 unless defined $before;
        for (1..200_000) {
            clone($v);
        }
        my $after = get_rss_kb();
        my $delta = $after - $before;
        ok($delta < 2000,
            "repeated vstring clone does not leak (delta: ${delta} KB)")
            or diag("Memory grew by $delta KB over 200K iterations — mg_ptr leak");
    }
}

# Test 5: vstring in a data structure
{
    my $data = { version => v2.0.0, name => "test" };
    my $c = clone($data);
    ok($c->{version} eq v2.0.0, "vstring in hash clones correctly");
    ok($c->{name} eq "test", "non-magic value in same hash clones correctly");
    $c->{version} = v3.0.0;
    ok($data->{version} eq v2.0.0, "mutating cloned vstring does not affect original");
}

done_testing;
