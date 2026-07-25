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
# Every coordinate-taking method funnels through kd_read_point, which runs Perl
# three ways: SvGETMAGIC on the arrayref, av_len on a TIED array
# (AvFILL -> mg_size -> FETCHSIZE), and SvNV on each element. kd_read_point
# takes the handle BY VALUE, so re-reading inside it would not reach the
# caller's copy -- the guard has to sit at each call site.
#
# add() has a second window after that: the optional id's get-magic.
#
# The hostile calls run in a child so a regression is reported, not fatal here.
use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::KDTree::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

our $victim;
our $groom;   # keeps the realloc tree alive so its handle is not re-freed

# tied array whose FETCHSIZE (reached via av_len) destroys the tree
{   package Tied::Destroy;
    sub TIEARRAY  { bless { obj => $_[1] }, $_[0] }
    sub FETCHSIZE { $_[0]{obj}->DESTROY; 2 }
    sub FETCH     { 1.0 }
}
# tied array whose FETCHSIZE destroys the tree AND grooms the freed handle:
# a fresh dims=3 tree calloc's the same-sized KdHandle chunk (tcache LIFO), so a
# stale h->dims read sees 3 and kd_read_point(hi) dies with the WRONG message --
# only the intermediate REEXTRACT gives the specific "destroyed" croak.
{   package Tied::Destroy::Realloc;
    sub TIEARRAY  { bless { obj => $_[1] }, $_[0] }
    sub FETCHSIZE { $_[0]{obj}->DESTROY;
                    $main::groom = Data::KDTree::Shared->new(undef, 3, 16); 2 }
    sub FETCH     { 1.0 }
}
# tied array whose FETCHSIZE replaces the invocant instead
{   package Tied::Replace;
    sub TIEARRAY  { bless {}, $_[0] }
    sub FETCHSIZE { $main::victim = 42; 2 }
    sub FETCH     { 1.0 }
}
{   package Evil::Destroy;   # for add()'s optional id argument
    use overload '0+' => sub { $_[0][0]->DESTROY; 1 },
                 '""' => sub { $_[0][0]->DESTROY; '1' },
                 fallback => 1;
}

my $destroyed = qr/destroyed during the call/;
my $replaced  = qr/replaced during the call/;

my @cases = (
    [ 'add: tied FETCHSIZE destroys', $destroyed,
      sub { tie my @c, 'Tied::Destroy', $victim; $victim->add(\@c) } ],
    [ 'add: tied FETCHSIZE replaces the invocant', $replaced,
      sub { tie my @c, 'Tied::Replace'; $main::victim->add(\@c) } ],
    [ 'add: optional id magic destroys', $destroyed,
      sub { $victim->add([1.0, 2.0], bless([$victim], 'Evil::Destroy')) } ],
    [ 'nearest: tied FETCHSIZE destroys', $destroyed,
      sub { tie my @c, 'Tied::Destroy', $victim; $victim->nearest(\@c) } ],
    [ 'knn: tied FETCHSIZE destroys', $destroyed,
      sub { tie my @c, 'Tied::Destroy', $victim; $victim->knn(\@c, 1) } ],
    [ 'range: tied FETCHSIZE on lo destroys', $destroyed,
      sub { tie my @c, 'Tied::Destroy::Realloc', $victim; $victim->range(\@c, [0.0, 0.0]) } ],
    [ 'radius: tied FETCHSIZE destroys', $destroyed,
      sub { tie my @c, 'Tied::Destroy', $victim; $victim->radius(\@c, 1.0) } ],
);

for my $case (@cases) {
    my ($name, $want, $call) = @$case;
    my $pid = fork();
    unless (defined $pid) { plan skip_all => "fork failed: $!" }
    unless ($pid) {
        $victim = Data::KDTree::Shared->new(undef, 2, 16);
        $victim->add([0.5, 0.5]);
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
