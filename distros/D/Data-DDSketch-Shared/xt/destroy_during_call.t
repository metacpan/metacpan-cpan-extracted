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
# Covered here:
#   * add_many, element get-magic          (SvNV(*el) in the resolve loop)
#   * add_many, tied FETCHSIZE             (av_len -> AvFILL -> mg_size), with an
#     EMPTY result so the element loop is skipped entirely -- a guard placed
#     inside that loop would never fire
#   * merge, sv_isobject(other)            (sv_isobject begins with SvGETMAGIC)
#
# The hostile calls run in a child so a regression is reported, not fatal here.
use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::DDSketch::Shared;

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
{   package Tied::Empty;
    sub TIEARRAY  { bless { obj => $_[1] }, $_[0] }
    sub FETCHSIZE { $_[0]{obj}->DESTROY; 0 }   # frees handle, reports EMPTY
    sub FETCH     { 0 }
}
{   package Tied::Other;
    sub TIESCALAR { bless { obj => $_[1], peer => $_[2] }, $_[0] }
    sub FETCH     { $_[0]{obj}->DESTROY; $_[0]{peer} }
}

my $destroyed = qr/destroyed during the call/;
my $replaced  = qr/replaced during the call/;

my @cases = (
    [ 'add_many: element magic destroys', $destroyed,
      sub { my $e = bless [$victim], 'Evil::Destroy'; $victim->add_many([$e, 2, 3]) } ],
    [ 'add_many: element magic replaces', $replaced,
      sub { my $e = bless [$victim], 'Evil::Replace'; $victim->add_many([$e, 2, 3]) } ],
    [ 'add_many: tied FETCHSIZE destroys (empty array skips the element loop)', $destroyed,
      sub { tie my @a, 'Tied::Empty', $victim; $victim->add_many(\@a) } ],
    [ 'merge: sv_isobject get-magic on other destroys self', $destroyed,
      sub {
          my $peer = Data::DDSketch::Shared->new(undef, 0.01, 1024);
          tie my $other, 'Tied::Other', $victim, $peer;
          $victim->merge($other);
      } ],
);

for my $case (@cases) {
    my ($name, $want, $call) = @$case;
    my $pid = fork();
    unless (defined $pid) { plan skip_all => "fork failed: $!" }
    unless ($pid) {
        $victim = Data::DDSketch::Shared->new(undef, 0.01, 1024);
        my $ok  = eval { $call->(); 1 };
        my $err = $@ // '';
        # exit 0 ONLY for the specific guard. Any OTHER death does not prove the
        # guard fired: free() does not unmap, so a stale read can trip an
        # unrelated check and croak, which would pass even with the fix removed.
        POSIX::_exit($ok ? 7 : ($err =~ $want ? 0 : 8));
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "no crash -- $name"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "croaks instead of using the bad handle -- $name";
}

done_testing;
