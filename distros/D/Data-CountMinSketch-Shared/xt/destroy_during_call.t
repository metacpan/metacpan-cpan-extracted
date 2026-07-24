#!/usr/bin/perl
# Regression: argument magic that explicitly calls $obj->DESTROY must not leave
# the running method dereferencing a freed handle.
#
# EXTRACT pins the referent with sv_2mortal(SvREFCNT_inc(SvRV(sv))), but that
# only blocks REFCOUNT-driven destruction. An explicit ->DESTROY runs the
# destructor regardless, freeing the handle and zeroing the IV -- so a method
# that captured `h` before running argument magic held a dangling pointer and
# segfaulted on the next lock. Methods where magic can intervene now re-read the
# handle (REEXTRACT) and croak instead.
#
# The hostile call runs in a child so a regression is reported, not fatal here.
use strict;
use warnings;
use Test::More;
use Config;
use Data::CountMinSketch::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

{ package Evil;
  use overload '""' => sub { $_[0][0]->DESTROY; 'k' }, fallback => 1; }

for my $method (qw(estimate add add_many)) {
    my $pid = fork();
    unless ($pid) {
        my $cms  = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);
        my $evil = bless [$cms], 'Evil';
        my $ok = eval {
            if    ($method eq 'estimate') { $cms->estimate($evil) }
            elsif ($method eq 'add')      { $cms->add($evil, 1) }
            else                          { $cms->add_many([$evil]) }
            1;
        };
        exit($ok ? 7 : 0);        # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
