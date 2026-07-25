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
# Note: record()'s mandatory value argument is converted in the INPUT section
# before PREINIT/EXTRACT runs, so magic on it cannot dangle the handle; only the
# OPTIONAL count, read with SvUV(ST(2)) inside CODE, can.
#
# Vectors covered:
#   record       -- optional count get-magic
#   record_many  -- element get-magic
#   record_many  -- tied FETCHSIZE (av_len -> AvFILL -> mg_size) returning EMPTY,
#                   which skips the element loop entirely, so a guard placed only
#                   inside that loop never fires
#   merge        -- sv_isobject(other), which begins with SvGETMAGIC
#
# The hostile calls run in a child so a regression is reported, not fatal here.
use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::Histogram::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

our $victim;

{   package Evil::Destroy;
    use overload '0+' => sub { $_[0][0]->DESTROY; 1 },
                 '""' => sub { $_[0][0]->DESTROY; 'k' },
                 fallback => 1;
}
{   package Evil::Replace;
    use overload '0+' => sub { $main::victim = 42; 1 },
                 '""' => sub { $main::victim = 42; 'k' },
                 fallback => 1;
}
{   package Tied::Empty;
    sub TIEARRAY  { bless { obj => $_[1] }, $_[0] }
    sub FETCHSIZE { $_[0]{obj}->DESTROY; 0 }   # frees handle, reports EMPTY
    sub FETCH     { 1 }
}
{   package Tied::Other;
    sub TIESCALAR { bless { obj => $_[1], peer => $_[2] }, $_[0] }
    sub FETCH     { $_[0]{obj}->DESTROY; $_[0]{peer} }
}

my $destroyed = qr/destroyed during the call/;
my $replaced  = qr/replaced during the call/;

my @cases = (
    [ 'record: optional count magic destroys', $destroyed,
      sub { my $e = bless [$victim], 'Evil::Destroy'; $victim->record(1, $e) } ],
    [ 'record: optional count magic replaces', $replaced,
      sub { my $e = bless [$victim], 'Evil::Replace'; $victim->record(1, $e) } ],
    [ 'record_many: element magic destroys', $destroyed,
      sub { my $e = bless [$victim], 'Evil::Destroy'; $victim->record_many([1, $e]) } ],
    [ 'record_many: tied FETCHSIZE destroys (empty array skips the element loop)', $destroyed,
      sub { tie my @a, 'Tied::Empty', $victim; $victim->record_many(\@a) } ],
    [ 'merge: sv_isobject get-magic on other destroys self', $destroyed,
      sub {
          my $peer = Data::Histogram::Shared->new(undef, 1, 1000, 3);
          tie my $other, 'Tied::Other', $victim, $peer;
          $victim->merge($other);
      } ],
);

for my $case (@cases) {
    my ($name, $want, $call) = @$case;
    my $pid = fork();
    unless (defined $pid) { plan skip_all => "fork failed: $!" }
    unless ($pid) {
        $victim = Data::Histogram::Shared->new(undef, 1, 1000, 3);
        my $ok  = eval { $call->(); 1 };
        my $err = $@ // '';
        # exit 0 ONLY for the specific guard. Any OTHER death does not prove the
        # guard fired: free() does not unmap, so a stale read returns garbage
        # that can trip an unrelated check and croak -- which would make this
        # test pass even with the fix removed.
        POSIX::_exit($ok ? 7 : ($err =~ $want ? 0 : 8));
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "no crash -- $name"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "croaks instead of using the bad handle -- $name";
}

done_testing;
