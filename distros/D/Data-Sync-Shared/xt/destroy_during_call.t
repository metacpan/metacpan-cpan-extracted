#!/usr/bin/perl
# Regression: argument magic that explicitly calls $obj->DESTROY must not
# leave the running method dereferencing a freed handle.
#
# EXTRACT_HANDLE pins the referent with sv_2mortal(SvREFCNT_inc(SvRV(sv))),
# but that only blocks REFCOUNT-driven destruction. An explicit ->DESTROY
# runs the destructor regardless, freeing the handle and zeroing the IV --
# so a method that captured `h` before running argument magic held a
# dangling pointer and segfaulted on the next lock. Methods where magic can
# intervene now re-read the handle (REEXTRACT) and croak instead.
#
# The hostile call runs in a child so a regression is reported, not fatal here.
use strict;
use warnings;
use Test::More;
use Config;
use Data::Sync::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Every REEXTRACT'd method here reads its trigger argument numerically
# (SvNV timeout / SvUV count), so '0+' is the overload that fires; define
# string magic too, with fallback, to be safe.
{ package Evil;
  use overload
      '0+' => sub { $_[0][0]->DESTROY; 0 },
      '""' => sub { $_[0][0]->DESTROY; 'k' },
      fallback => 1; }

my @cases = (
    [ 'Semaphore::acquire',
      sub { Data::Sync::Shared::Semaphore->new(undef, 1) },
      sub { my ($obj, $evil) = @_; $obj->acquire($evil) } ],
    [ 'Semaphore::release',
      sub { Data::Sync::Shared::Semaphore->new(undef, 1) },
      sub { my ($obj, $evil) = @_; $obj->release($evil) } ],
    [ 'Barrier::wait',
      sub { Data::Sync::Shared::Barrier->new(undef, 2) },   # count must be >= 2
      sub { my ($obj, $evil) = @_; $obj->wait($evil) } ],
    [ 'Once::enter',
      sub { Data::Sync::Shared::Once->new(undef) },
      sub { my ($obj, $evil) = @_; $obj->enter($evil) } ],
);

for my $case (@cases) {
    my ($name, $make, $call) = @$case;
    my $pid = fork();
    unless ($pid) {
        my $obj  = $make->();
        my $evil = bless [$obj], 'Evil';
        my $ok = eval { $call->($obj, $evil); 1 };
        exit($ok ? 7 : 0);  # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$name: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$name: croaks instead of using the freed handle";
}

done_testing;
