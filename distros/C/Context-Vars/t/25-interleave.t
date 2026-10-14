#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Deferred;
use Context::Vars qw($id);

# Two tasks, each assigning its id in a sub and queueing three callbacks that
# read it, run alternately. Wired, each callback reads its own task's id.
# Unwired, each reads nothing, and never the other task's.

my @read;
sub task {
    my ($q, $name) = @_;
    $id = $name;
    for my $n (1 .. 3) {
        $q->later(sub { push @read, "$name$n reads " . ($id // 'nothing') });
    }
}

for my $mode (qw(wired unwired)) {
    my $want = sub { my ($task, $n) = @_; $mode eq 'wired' ? "$task$n reads $task" : "$task$n reads nothing" };
    for my $order ([A1 => 0], [B1 => 3]) {
        @read = ();
        my $q = Deferred->new(wired => $mode eq 'wired');
        task($q, 'A');
        task($q, 'B');
        # Queue positions: A's three at 0 1 2, B's at 3 4 5.
        my @alternate = $order->[1] == 0 ? (0, 3, 1, 4, 2, 5) : (3, 0, 4, 1, 5, 2);
        $q->run_all(@alternate);
        my @expect = map { my ($t, $n) = /^(.)(.)$/; $want->($t, $n) }
                     $order->[1] == 0 ? qw(A1 B1 A2 B2 A3 B3) : qw(B1 A1 B2 A2 B3 A3);
        is_deeply(\@read, \@expect, "$mode, starting with $order->[0]: every callback read "
                  . ($mode eq 'wired' ? 'its own task\'s id' : 'nothing, not the other task\'s id'));
        is_deeply([$q->errors], [], "$mode, starting with $order->[0]: no callback died");
    }
}

ok(!defined $id, 'the top level reads nothing');
is(Context::Vars::_depth(), 0, 'no context is left entered');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');

done_testing;
