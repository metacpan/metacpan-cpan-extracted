use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Data::HashMap::Shared::II;

# take/pop/shift/drain are the removal primitives eg/work_queue.pl is built on,
# and their whole promise is that a key is claimed by exactly one caller.
# t/16-fork-multiproc.t races cas/add/incr/cas_take and stops there, so nothing
# exercised these across processes -- the same kind of gap that let a sharded
# first-open race ship.
#
# Workers are released through a pipe barrier: a bare fork loop lets the first
# child finish before the last one exists, so the claims barely overlap.

my $dir   = tempdir(CLEANUP => 1);
my $NKEYS = 400;
my $PROCS = 4;

sub claim_race {
    my ($map, $label) = @_;

    pipe(my $result_r, my $result_w) or die "pipe: $!";
    pipe(my $barrier_r, my $barrier_w) or die "pipe: $!";

    my @pids;
    for my $w (1 .. $PROCS) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            close $barrier_w;
            close $result_r;
            <$barrier_r>;
            my @claimed;
            my $idle = 0;
            my $rounds = 0;
            # bounded so a primitive that returns without removing fails
            # the test instead of hanging the suite
            while ($idle < 3 && ++$rounds <= 4 * $NKEYS) {
                my $got = 0;
                # each worker leans on a different primitive, all removing
                if    ($w == 1) { my ($k) = $map->pop;      $got = defined $k ? push @claimed, $k : 0 }
                elsif ($w == 2) { my ($k) = $map->shift;    $got = defined $k ? push @claimed, $k : 0 }
                elsif ($w == 3) { my @kv  = $map->drain(7);
                                  while (@kv) { my $k = shift @kv; shift @kv; push @claimed, $k; $got = 1 } }
                else            { for my $k (1 .. $NKEYS) {
                                      next unless defined $map->take($k);
                                      push @claimed, $k; $got = 1;
                                  } }
                $idle = $got ? 0 : $idle + 1;
            }
            print {$result_w} join(',', @claimed), "\n";
            close $result_w;
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    close $barrier_r;
    close $result_w;
    close $barrier_w;                 # release every worker at once

    my @lines = <$result_r>;
    waitpid $_, 0 for @pids;

    my %count;
    for my $line (@lines) {
        chomp $line;
        $count{$_}++ for grep { length } split /,/, $line;
    }
    my @dupes  = grep { $count{$_} > 1 } keys %count;
    my @missed = grep { !$count{$_} } 1 .. $NKEYS;

    is scalar(@dupes), 0, "$label: no key claimed twice"
        or diag "claimed more than once: @{[ (sort { $a <=> $b } @dupes)[0 .. ($#dupes > 4 ? 4 : $#dupes)] ]}";
    is scalar(@missed), 0, "$label: no key left unclaimed"
        or diag "never claimed: @{[ (sort { $a <=> $b } @missed)[0 .. ($#missed > 4 ? 4 : $#missed)] ]}";
    is $map->size, 0, "$label: map is empty afterwards";
}

{
    my $path = "$dir/plain.shm";
    my $map = Data::HashMap::Shared::II->new($path, 40_000);
    $map->put($_, $_ * 3) for 1 .. $NKEYS;
    is $map->size, $NKEYS, 'plain: populated';
    claim_race($map, 'plain');
}

{
    my $prefix = "$dir/sharded";
    my $map = Data::HashMap::Shared::II->new_sharded($prefix, 8, 40_000);
    $map->put($_, $_ * 3) for 1 .. $NKEYS;
    is $map->size, $NKEYS, 'sharded: populated';
    claim_race($map, 'sharded');
}

done_testing;
