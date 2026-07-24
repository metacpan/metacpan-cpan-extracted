#!/usr/bin/perl
# Regression: argument magic that runs arbitrary Perl must not leave the running
# method dereferencing a freed -- or replaced -- handle.
#
# EXTRACT_HEAP pins the referent with sv_2mortal(SvREFCNT_inc(SvRV(sv))), but
# that only blocks REFCOUNT-driven destruction. Two things the magic can still do:
#
#   1. call $obj->DESTROY explicitly, which frees the handle and zeroes the IV;
#   2. REPLACE the invocant ($obj = 42), which mutates ST(0) itself because Perl
#      passes aliases -- so SvRV would then run on a non-reference.
#
# pop_wait resolves its optional timeout with SvGETMAGIC(ST(1)) after the handle
# has been captured, so both are reachable there. REEXTRACT_HEAP must turn each
# into a clean croak.
#
# The hostile calls run in a child so a regression is reported, not fatal here.
use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::Heap::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

our $victim;

{   package Evil::Destroy;
    use overload '0+' => sub { $_[0][0]->DESTROY; 0 },
                 '""' => sub { $_[0][0]->DESTROY; '0' },
                 fallback => 1;
}
{   package Evil::Replace;
    # does not destroy anything -- just makes the invocant stop being a reference
    use overload '0+' => sub { $main::victim = 42; 0 },
                 '""' => sub { $main::victim = 42; '0' },
                 fallback => 1;
}

my @cases = (
    [ 'destroyed', 'Evil::Destroy', qr/destroyed during the call/ ],
    [ 'replaced',  'Evil::Replace', qr/replaced during the call/  ],
);

for my $case (@cases) {
    my ($name, $class, $want) = @$case;
    my $pid = fork();
    unless (defined $pid) { plan skip_all => "fork failed: $!" }
    unless ($pid) {
        $victim = Data::Heap::Shared->new(undef, 16);
        $victim->push(1, 100);
        my $evil = bless [$victim], $class;
        my $ok  = eval { $victim->pop_wait($evil); 1 };
        my $err = $@ // '';
        # exit 0 ONLY for the specific guard. Any OTHER death does not prove the
        # guard fired: free() does not unmap, so a stale read can trip an
        # unrelated check and croak, which would pass even with the fix removed.
        POSIX::_exit($ok ? 7 : ($err =~ $want ? 0 : 8));
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "pop_wait/$name: no crash when argument magic attacks the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "pop_wait/$name: croaks instead of using the bad handle";
}

done_testing;
