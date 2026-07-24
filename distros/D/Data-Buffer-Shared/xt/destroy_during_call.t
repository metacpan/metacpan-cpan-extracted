#!/usr/bin/perl
# Regression: argument magic that explicitly calls $obj->DESTROY must not leave
# the running method dereferencing a freed handle.
#
# EXTRACT_BUF pins the referent with sv_2mortal(SvREFCNT_inc(SvRV(sv))), which
# only blocks REFCOUNT-driven destruction. An explicit ->DESTROY runs the
# destructor regardless, freeing the handle and zeroing the IV -- so a method
# that captured `h` before running argument magic held a dangling pointer and
# segfaulted. Methods where magic can intervene now re-read the handle
# (REEXTRACT_BUF) and croak instead.
use strict;
use warnings;
use Test::More;
use Config;
use Data::Buffer::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

{ package Evil;
  use overload '""' => sub { $_[0][0]->DESTROY; 'k' }, fallback => 1; }

for my $case (['set', sub { $_[0]->set(0, $_[1]) }],
              ['fill', sub { $_[0]->fill($_[1]) }]) {
    my ($name, $call) = @$case;
    my $pid = fork();
    unless ($pid) {
        my $b    = Data::Buffer::Shared::Str->new_anon(8, 16);
        my $evil = bless [$b], 'Evil';
        my $ok = eval { $call->($b, $evil); 1 };
        exit($ok ? 7 : 0);      # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$name: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$name: croaks instead of using the freed handle";
}

done_testing;
