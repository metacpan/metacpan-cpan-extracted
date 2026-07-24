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
use Data::CuckooFilter::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Items are read with SvPVbyte, so the magic runs on stringification; '0+' is
# defined too for safety (fallback lets Perl use it if ever numified).
{ package Evil;
  use overload
      '""' => sub { $_[0][0]->DESTROY; 'k' },
      '0+' => sub { $_[0][0]->DESTROY; 0 },
      fallback => 1; }

for my $method (qw(add contains count_of remove)) {
    my $pid = fork();
    unless ($pid) {
        my $cf   = Data::CuckooFilter::Shared->new(undef, 1000);   # anonymous mapping, nothing to clean up
        my $evil = bless [$cf], 'Evil';
        my $ok = eval {
            if    ($method eq 'add')      { $cf->add($evil) }
            elsif ($method eq 'contains') { $cf->contains($evil) }
            elsif ($method eq 'count_of') { $cf->count_of($evil) }
            else                          { $cf->remove($evil) }
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
