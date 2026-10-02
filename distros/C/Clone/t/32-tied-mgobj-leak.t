#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Clone qw(clone);

# Refcount leak in magic mg_obj cloning.
#
# When cloning an SV with magic that has a non-NULL mg_obj (e.g. tied
# hashes/arrays), sv_clone() returns a cloned mg_obj with one caller
# reference.  sv_magic() then takes its own SvREFCNT_inc.  If the
# caller's reference is never released, the cloned mg_obj leaks one
# refcount per clone — DESTROY never fires on the cloned tie object.
#
# This affects any magic type where mg_obj is recursively cloned:
# tied ('P'/'p'/'q') and all other non-skipped magic types.

BEGIN {
    eval { require B; require Scalar::Util; 1 }
        or plan skip_all => 'B or Scalar::Util not available';
    plan tests => 7;
}

package TiedHash;
our $destroy_count = 0;
sub TIEHASH  { bless {}, shift }
sub DESTROY  { $destroy_count++ }
sub FETCH    { return $_[0]->{$_[1]} }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FIRSTKEY { my $k = keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub DELETE   { delete $_[0]->{$_[1]} }

package TiedArray;
our $destroy_count = 0;
sub TIEARRAY  { bless [], shift }
sub DESTROY   { $destroy_count++ }
sub FETCH     { return $_[0]->[$_[1]] }
sub STORE     { $_[0]->[$_[1]] = $_[2] }
sub FETCHSIZE { scalar @{$_[0]} }
sub STORESIZE { $#{$_[0]} = $_[1] - 1 }
sub PUSH      { my $self = shift; push @$self, @_ }

package TiedScalar;
our $destroy_count = 0;
sub TIESCALAR { bless \(my $x = $_[1]), shift }
sub DESTROY   { $destroy_count++ }
sub FETCH     { ${$_[0]} }
sub STORE     { ${$_[0]} = $_[1] }

package main;

# Test 1: cloned tied hash's tie object is freed (DESTROY fires)
{
    $TiedHash::destroy_count = 0;
    tie my %h, 'TiedHash';
    $h{key} = 'value';

    for (1..10) {
        my $c = clone(\%h);
    }

    is($TiedHash::destroy_count, 10,
       'tied hash: DESTROY fires for each cloned tie object');
}

# Test 2: weakref confirms cloned tie object does not survive
{
    tie my %h, 'TiedHash';
    $h{key} = 'value';

    my $c = clone(\%h);
    my $ct = tied(%$c);
    Scalar::Util::weaken($ct);
    undef $c;

    ok(!defined $ct,
       'tied hash: cloned tie object freed when clone destroyed');
}

# Test 3: refcount of cloned tie object is correct
{
    tie my %h, 'TiedHash';
    $h{key} = 'value';

    my $c = clone(\%h);
    my $ct = tied(%$c);
    my $rc = B::svref_2object($ct)->REFCNT;

    # Expected: 1 from magic (MGf_REFCOUNTED) + 1 from $ct = 2
    is($rc, 2,
       'tied hash: cloned tie object refcount is 2 (magic + lexical)');
}

# Test 4: tied array clone does not leak
{
    $TiedArray::destroy_count = 0;
    tie my @a, 'TiedArray';
    push @a, 1, 2, 3;

    for (1..10) {
        my $c = clone(\@a);
    }

    is($TiedArray::destroy_count, 10,
       'tied array: DESTROY fires for each cloned tie object');
}

# Test 5: tied scalar clone does not leak
{
    $TiedScalar::destroy_count = 0;
    tie my $s, 'TiedScalar', 'hello';

    for (1..10) {
        my $c = clone(\$s);
    }

    is($TiedScalar::destroy_count, 10,
       'tied scalar: DESTROY fires for each cloned tie object');
}

# Tests 6-7: arylen magic ('#') -- sv_magic() stores mg_obj *without*
# taking a reference for this type, so the cloned mg_obj must NOT be
# decremented or the clone is left pointing at freed memory.
{
    my @a = (1, 2, 3);
    my $c = clone(\$#a);

    is($$c, 2, 'arylen: cloned $#a reads the cloned array last index');

    @a = ();    # source array gone; clone must own its own AV
    is($$c, 2, 'arylen: cloned mg_obj survives the source array');
}
