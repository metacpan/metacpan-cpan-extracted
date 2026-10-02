#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Clone qw(clone);

# GH #108: Memory leak via double refcount increment on HEf_SVKEY magic
#
# When cloning an SV whose magic chain contains an entry with mg_len ==
# HEf_SVKEY, Clone.xs was calling SvREFCNT_inc(mg->mg_ptr) manually and
# then passing mg_ptr to sv_magic(), which internally calls SvREFCNT_inc
# again for HEf_SVKEY.  The result: two increments for one ownership.
#
# Direct pure-Perl reproduction of the exact code path is not possible on
# modern Perl (5.10+): the only common source of HEf_SVKEY magic on SVs
# reachable through Clone's magic loop is PERL_MAGIC_tiedelem on PVLV
# proxy scalars (e.g. \$tied_hash{key}), but Clone returns those via the
# early-exit path (SvREFCNT_inc only, no magic loop) due to the GH #42
# fix.  Hash::Util::FieldHash on modern Perl also uses mg_len=0, not
# HEf_SVKEY.
#
# These tests verify the related invariants:
#   - PVLV tied-element proxies (which bear HEf_SVKEY magic) clone without
#     leaking: Clone correctly uses the SvREFCNT_inc early-exit path.
#   - Refcounts on tied objects remain stable across clone/destroy cycles.

BEGIN {
    eval { require B; require Scalar::Util; 1 }
        or plan skip_all => 'B or Scalar::Util not available';
    plan tests => 4;
}

package TiedHash;
sub TIEHASH  { bless {}, shift }
sub FETCH    { return $_[0]->{$_[1]} }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FIRSTKEY { my $k = keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub DELETE   { delete $_[0]->{$_[1]} }

package main;

# Test 1: tied-element PVLV has HEf_SVKEY magic (verifies test setup is valid).
{
    tie my %h, 'TiedHash';
    $h{key} = 'val';

    my $lv = \$h{key};   # ref to PVLV with PERL_MAGIC_tiedelem, MG_LEN=HEf_SVKEY (-2)
    my $pvlv = B::svref_2object($lv);
    my $mg   = $pvlv->MAGIC;

    is($mg->LENGTH, -2,
       'PVLV tied-element proxy has HEf_SVKEY magic (mg_len == -2)');
}

# Test 2: cloning the PVLV proxy returns the same SV (Clone early-exit path).
{
    tie my %h, 'TiedHash';
    $h{key} = 'hello';

    my $lv = \$h{key};
    my $cloned = clone($lv);

    is($cloned, $lv,
       'PVLV clone is the same SV (SvREFCNT_inc early-exit, not a deep copy)');
}

# Test 3: tied-object refcount is stable across many clone/destroy cycles.
# With the HEf_SVKEY double-increment bug, each cycle would strand one extra
# refcount on mg_ptr; the tied object would accumulate refcounts and never
# reach zero.  (This specific check applies to non-PVLV SVs; for PVLVs Clone
# uses the early-exit path, so refcount growth on mg_ptr cannot occur here.)
{
    tie my %h, 'TiedHash';
    $h{key} = 'value';

    my $lv = \$h{key};
    my $tie_rc_before = B::svref_2object(tied(%h))->REFCNT;

    for (1..100) {
        my $c = clone($lv);
    }

    my $tie_rc_after = B::svref_2object(tied(%h))->REFCNT;

    is($tie_rc_after, $tie_rc_before,
       'tied-object refcount unchanged after 100 clone/destroy cycles');
}

# Test 4: cloned value matches original (basic correctness).
{
    tie my %h, 'TiedHash';
    $h{key} = 'expected';

    my $lv     = \$h{key};
    my $cloned = clone($lv);

    is($$cloned, 'expected',
       'cloned tied-element value matches original');
}
