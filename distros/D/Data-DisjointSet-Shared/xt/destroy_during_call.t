#!/usr/bin/perl
# Regression: argument magic that runs arbitrary Perl must not leave the running
# method dereferencing a freed -- or replaced -- handle.
#
# EXTRACT pins the referent with sv_2mortal(SvREFCNT_inc(SvRV(sv))), but that
# only blocks REFCOUNT-driven destruction. The magic can still:
#
#   1. call $obj->DESTROY explicitly, freeing the handle and zeroing the IV;
#   2. REPLACE the invocant ($obj = 42), which mutates ST(0) itself because Perl
#      passes aliases -- so SvRV would then run on a non-reference.
#
# union_many has THREE windows where Perl can run after the handle is captured:
#   * SvGETMAGIC(pairs)                 -- tied/overloaded scalar argument
#   * av_len(av)                        -- AvFILL -> mg_size -> tied FETCHSIZE
#   * SvUV(*el) in the resolve loop     -- tied/overloaded elements
# The first two precede the read of h->n; the third precedes the write lock.
# Both REEXTRACT sites must turn each into a clean croak.
#
# The hostile calls run in a child so a regression is reported, not fatal here.
use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::DisjointSet::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

our $victim;

{   package Evil::Destroy;
    use overload '0+' => sub { $_[0][0]->DESTROY; 1 },
                 '""' => sub { $_[0][0]->DESTROY; '1' },
                 fallback => 1;
}
{   package Evil::Replace;
    use overload '0+' => sub { $main::victim = 42; 1 },
                 '""' => sub { $main::victim = 42; '1' },
                 fallback => 1;
}
# A tied array whose FETCHSIZE (reached via av_len) destroys the set and then
# reports EMPTY, so the element loop is skipped entirely.
{   package Tied::Empty;
    sub TIEARRAY  { bless { obj => $_[1] }, $_[0] }
    sub FETCHSIZE { $_[0]{obj}->DESTROY; 0 }
    sub FETCH     { 0 }
}

my $destroyed = qr/destroyed during the call/;
my $replaced  = qr/replaced during the call/;

my @cases = (
    [ 'element-magic destroys', $destroyed,
      sub { my $e = bless [$victim], 'Evil::Destroy'; $victim->union_many([$e, 1, 2, 3]) } ],
    [ 'element-magic replaces', $replaced,
      sub { my $e = bless [$victim], 'Evil::Replace'; $victim->union_many([$e, 1, 2, 3]) } ],
    [ 'tied FETCHSIZE destroys (empty array skips the element loop)', $destroyed,
      sub { tie my @a, 'Tied::Empty', $victim; $victim->union_many(\@a) } ],
);

for my $case (@cases) {
    my ($name, $want, $call) = @$case;
    my $pid = fork();
    unless (defined $pid) { plan skip_all => "fork failed: $!" }
    unless ($pid) {
        $victim = Data::DisjointSet::Shared->new(undef, 64);
        my $ok  = eval { $call->(); 1 };
        my $err = $@ // '';
        # exit 0 ONLY for the specific guard. Any OTHER death does not prove the
        # guard fired: free() does not unmap, so a stale read can trip an
        # unrelated check and croak, which would pass even with the fix removed.
        POSIX::_exit($ok ? 7 : ($err =~ $want ? 0 : 8));
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "union_many: no crash when $name"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "union_many: croaks instead of using the bad handle when $name";
}

done_testing;
