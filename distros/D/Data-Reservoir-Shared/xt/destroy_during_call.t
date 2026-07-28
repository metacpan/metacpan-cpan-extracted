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
# add_many has three windows after the handle is captured:
#   * SvGETMAGIC(items)              -- tied/overloaded scalar argument
#   * av_len(av)                     -- AvFILL -> mg_size -> tied FETCHSIZE
#   * SvPVbyte(*el) in the resolve loop
# The first two precede the read of h->mode; the third precedes the write lock.
# The empty-array case matters: a tied FETCHSIZE reporting 0 skips the element
# loop, so a guard placed only inside that loop would never fire.
#
# The hostile calls run in a child so a regression is reported, not fatal here.
use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::Reservoir::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

our $victim;

{   package Evil::Destroy;
    use overload '""' => sub { $_[0][0]->DESTROY; 'x' },
                 '0+' => sub { $_[0][0]->DESTROY; 1 },
                 fallback => 1;
}
{   package Evil::Replace;
    use overload '""' => sub { $main::victim = 42; 'x' },
                 '0+' => sub { $main::victim = 42; 1 },
                 fallback => 1;
}
{   package Tied::Empty;
    sub TIEARRAY  { bless { obj => $_[1] }, $_[0] }
    sub FETCHSIZE { $_[0]{obj}->DESTROY; 0 }   # frees handle, reports EMPTY
    sub FETCH     { 'x' }
}

my $destroyed = qr/destroyed during the call/;
my $replaced  = qr/replaced during the call/;

my @cases = (
    [ 'element magic destroys', $destroyed,
      sub { my $e = bless [$victim], 'Evil::Destroy'; $victim->add_many([$e, 'b', 'c']) } ],
    [ 'element magic replaces', $replaced,
      sub { my $e = bless [$victim], 'Evil::Replace'; $victim->add_many([$e, 'b', 'c']) } ],
    [ 'tied FETCHSIZE destroys (empty array skips the element loop)', $destroyed,
      sub { tie my @a, 'Tied::Empty', $victim; $victim->add_many(\@a) } ],
    [ 'item magic destroys', $destroyed,
      sub { my $e = bless [$victim], 'Evil::Destroy'; $victim->add($e) },
      'add' ],
);

for my $case (@cases) {
    my ($name, $want, $call, $method) = @$case;
    $method //= 'add_many';
    my $pid = fork();
    unless (defined $pid) { plan skip_all => "fork failed: $!" }
    unless ($pid) {
        $victim = Data::Reservoir::Shared->new(undef, 5, 64);
        my $ok  = eval { $call->(); 1 };
        my $err = $@ // '';
        # exit 0 ONLY for the specific guard. Any OTHER death does not prove the
        # guard fired: free() does not unmap, so a stale read can trip an
        # unrelated check and croak, which would pass even with the fix removed.
        POSIX::_exit($ok ? 7 : ($err =~ $want ? 0 : 8));
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when $name"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the bad handle when $name";
}

done_testing;
