#!/usr/bin/perl
# Regression: argument magic that runs arbitrary Perl must not leave the running
# method dereferencing a freed -- or replaced -- handle, nor a freed arrayref.
#
# EXTRACT pins the referent with sv_2mortal(SvREFCNT_inc(SvRV(sv))), but that
# only blocks REFCOUNT-driven destruction. The magic can still:
#
#   1. call $obj->DESTROY explicitly, freeing the handle and zeroing the IV;
#   2. REPLACE the invocant with a non-ref ($obj = 42) -- SvROK catches it;
#   3. REPLACE the invocant with a DIFFERENT same-class object -- SvROK passes
#      and SvIV yields a real-but-WRONG handle; only the h != h0 identity check
#      (this is what REEXTRACT adds) rejects it;
#   4. drop the caller's last ref to the pairs arrayref mid-loop -- the AV would
#      be freed and the next av_fetch a use-after-free, unless union_many pins it.
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
our $arr;

{   package Evil::Destroy;
    use overload '0+' => sub { $_[0][0]->DESTROY; 1 },
                 '""' => sub { $_[0][0]->DESTROY; '1' },
                 fallback => 1;
}
{   package Evil::Replace;              # replace the invocant with a non-ref
    use overload '0+' => sub { $main::victim = 42; 1 },
                 '""' => sub { $main::victim = 42; '1' },
                 fallback => 1;
}
{   package Evil::ReplaceObj;           # replace with a DIFFERENT same-class object
    use overload '0+' => sub { $main::victim = Data::DisjointSet::Shared->new(undef, 64); 1 },
                 '""' => sub { $main::victim = Data::DisjointSet::Shared->new(undef, 64); '1' },
                 fallback => 1;
}
{   package Evil::FreeArr;              # drop the caller's last ref to the pairs arrayref
    use overload '0+' => sub { undef $main::arr; 1 },
                 '""' => sub { undef $main::arr; '1' },
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
my $repl_obj  = qr/replaced or destroyed during the call/;

# [ name, want-regex (undef = expect clean completion), call, expected-exit ]
#   exit 0 = croaked with want ; exit 7 = completed OK ; exit 8 = some OTHER death
my @cases = (
    [ 'element-magic destroys', $destroyed,
      sub { my $e = bless [$victim], 'Evil::Destroy'; $victim->union_many([$e, 1, 2, 3]) }, 0 ],
    [ 'element-magic replaces with a non-ref', $replaced,
      sub { my $e = bless [$victim], 'Evil::Replace'; $victim->union_many([$e, 1, 2, 3]) }, 0 ],
    [ 'element-magic replaces with a DIFFERENT object (identity check)', $repl_obj,
      sub { my $e = bless [$victim], 'Evil::ReplaceObj'; $victim->union_many([$e, 1, 2, 3]) }, 0 ],
    [ 'tied FETCHSIZE destroys (empty array skips the element loop)', $destroyed,
      sub { tie my @a, 'Tied::Empty', $victim; $victim->union_many(\@a) }, 0 ],
    [ 'element-magic frees the pairs arrayref (AV pin keeps it alive)', undef,
      sub { $main::arr = [ (bless [], 'Evil::FreeArr'), 1, 2, 3 ]; $victim->union_many($main::arr) }, 7 ],
);

for my $case (@cases) {
    my ($name, $want, $call, $exp) = @$case;
    $exp //= 0;
    my $pid = fork();
    unless (defined $pid) { plan skip_all => "fork failed: $!" }
    unless ($pid) {
        $victim = Data::DisjointSet::Shared->new(undef, 64);
        my $ok  = eval { $call->(); 1 };
        my $err = $@ // '';
        # exit 7 = completed OK; exit 0 = croaked with the wanted message; exit 8 =
        # any OTHER death (does not prove a guard fired: free() does not unmap, so a
        # stale read can trip an unrelated check and croak even with the fix removed).
        POSIX::_exit($ok ? 7 : (($want && $err =~ $want) ? 0 : 8));
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "union_many: no crash when $name"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, $exp, "union_many: expected outcome ($exp) when $name";
}

done_testing;
