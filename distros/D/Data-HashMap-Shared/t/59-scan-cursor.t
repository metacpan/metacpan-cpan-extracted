use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::II;

# On a map without $max_size, pop and drain sweep forward from where the last
# one stopped and shift sweeps backward likewise, so successive partial drains
# thin the whole table instead of always taking the lowest slots and leaving
# a hash-biased survivor set behind.  The large table stays above the shrink
# threshold, and the wrap is shown on a 16-slot table, which never shrinks, so
# no rehash reorders the slots mid-test.

my $dir = tempdir(CLEANUP => 1);

sub keys_of { my @kv = @_; @kv[grep { $_ % 2 == 0 } 0 .. $#kv] }

{
    my $m = Data::HashMap::Shared::II->new("$dir/q.shm", 4096);
    $m->put($_, $_) for 1 .. 1000;
    my @order = $m->keys;                    # slot order
    my $low = $order[0];

    my @drained;
    push @drained, keys_of($m->drain(100)) for 1 .. 3;
    is_deeply \@drained, [ @order[0 .. 299] ], 'three drains take the first three hundred in slot order';
    ok $m->put($low, $low), 'the lowest-slot key is put back';
    my @popped;
    push @popped, ($m->pop)[0] for 1 .. 100;
    is_deeply \@popped, [ @order[300 .. 399] ], 'pop continues past where the drain stopped, not from the bottom';
}

# clear resets both cursors.  Only a 16-slot table shows it: clear shrinks the
# table to its minimum, and above that a stale cursor lands past the regrown
# table_cap, where the clamp starts the sweep at 0 whether it was reset or not.
{
    my $c = Data::HashMap::Shared::II->new("$dir/c.shm", 8);
    $c->put($_, $_) for 1 .. 12;
    $c->drain(4);
    $c->shift for 1 .. 4;
    $c->clear;
    $c->put($_, $_) for 1 .. 12;
    my @n = $c->keys;
    is +($c->pop)[0],   $n[0],  'clear resets the forward sweep to the bottom';
    is +($c->shift)[0], $n[-1], 'clear resets the backward sweep to the top';
}

# Each primitive advances the cursor itself, not only through the other one: a
# key put straight back into the slot just vacated is not taken again.
{
    my $w = Data::HashMap::Shared::II->new("$dir/again.shm", 8);
    $w->put($_, $_) for 1 .. 12;
    my @o = $w->keys;
    my ($p) = $w->pop;
    is $p, $o[0], 'the first pop takes the lowest slot';
    ok $w->put($p, $p), '  ... and the key goes straight back into it';
    is +($w->pop)[0], $o[1], '  ... which the next pop passes over';

    my $d = Data::HashMap::Shared::II->new("$dir/again2.shm", 8);
    $d->put($_, $_) for 1 .. 12;
    my @q = $d->keys;
    is_deeply [ keys_of($d->drain(4)) ], [ @q[0 .. 3] ], 'a drain takes the four lowest slots';
    ok $d->put($q[0], $q[0]), '  ... and one drained key goes straight back into its slot';
    is_deeply [ keys_of($d->drain(4)) ], [ @q[4 .. 7] ], '  ... which the next drain passes over';
}

{
    my $w = Data::HashMap::Shared::II->new("$dir/w.shm", 8);
    $w->put($_, $_) for 1 .. 12;
    my @o = $w->keys;
    my $low = $o[0];
    is_deeply [ keys_of($w->drain(4)) ], [ @o[0 .. 3] ], 'a drain takes the four lowest slots';
    ok $w->put($low, $low), 'the lowest-slot key is put back';
    my @rest;
    while (my ($k) = $w->pop) { push @rest, $k }
    is_deeply \@rest, [ @o[4 .. 11], $low ], 'pop sweeps to the top, then wraps to the key put back at the bottom';
}

{
    my $s = Data::HashMap::Shared::II->new("$dir/s.shm", 4096);
    $s->put($_, $_) for 1 .. 1000;
    my @order = $s->keys;
    my $high = $order[-1];
    my @shifted;
    push @shifted, ($s->shift)[0] for 1 .. 300;
    is_deeply \@shifted, [ reverse @order[700 .. 999] ], 'shift takes from the top of the table downward';
    ok $s->put($high, $high), 'the highest-slot key is put back';
    my @more;
    push @more, ($s->shift)[0] for 1 .. 100;
    is_deeply \@more, [ reverse @order[600 .. 699] ], 'shift continues below where it stopped, not from the top again';
}

{
    my $w = Data::HashMap::Shared::II->new("$dir/ws.shm", 8);
    $w->put($_, $_) for 1 .. 12;
    my @o = $w->keys;
    my $high = $o[-1];
    is_deeply [ map { ($w->shift)[0] } 1 .. 4 ], [ reverse @o[8 .. 11] ], 'four shifts take the four highest slots';
    ok $w->put($high, $high), 'the highest-slot key is put back';
    my @rest;
    while (my ($k) = $w->shift) { push @rest, $k }
    is_deeply \@rest, [ reverse(@o[0 .. 7]), $high ], 'shift sweeps to the bottom, then wraps to the key put back at the top';
}

done_testing;
