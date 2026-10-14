#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use List::Util qw(shuffle);
use FindBin ();
use lib "$FindBin::Bin/lib";
use Deferred;
use Context::Vars qw($id $part);

# A thousand tasks, five callbacks each, run in a shuffled order. Every
# callback reads its own task's id; afterwards nothing is held.

my $holders = Context::Vars::_live_holders();
my $q = Deferred->new(wired => 1);
my (%bad, $runs);

sub task {
    my ($n) = @_;
    $id = "task$n";
    for my $k (1 .. 5) {
        $part = $k;
        $q->later(sub {
            $runs++;
            $bad{$n}++ unless $id eq "task$n" && $part == $k;
        });
    }
}
task($_) for 1 .. 1000;
is($q->pending, 5000, 'five thousand callbacks are queued');

srand(20261014);
$q->run_all(shuffle 0 .. 4999);
is($runs, 5000, 'all of them ran');
is(scalar keys %bad, 0, 'every one read its own task\'s id and its own part')
    or diag 'wrong in tasks: ' . join(',', (sort { $a <=> $b } keys %bad)[0 .. 9]);
is(Context::Vars::_live_holders(), $holders, 'once the queue is empty, nothing holds a context');
is(Context::Vars::_depth(), 0, 'and nothing is entered');

done_testing;
