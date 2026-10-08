use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SI;

# pop/shift/drain during each() must not move each()'s shard cursor: a key
# each() never yields must be a key that is no longer there.

my $dir = tempdir(CLEANUP => 1);
my @keys = map { "sharded-iter-key-longer-than-inline-$_" } 1 .. 40;

for my $case (
    [ 'pop',   sub { $_[0]->pop } ],
    [ 'shift', sub { $_[0]->shift } ],
    [ 'drain', sub { $_[0]->drain(2) } ],
) {
    my ($name, $act) = @$case;
    my $m = Data::HashMap::Shared::SI->new_sharded("$dir/$name", 4, 1000);
    $m->put($_, 1) for @keys;
    is($m->size, scalar @keys, "$name: seeded all keys");

    my (%seen, $step);
    while (my ($k, $v) = $m->each) {
        $seen{$k} = 1;
        $act->($m) if ++$step == 5;
    }

    my @skipped_but_live = grep { !$seen{$_} && $m->exists($_) } @keys;
    is(scalar @skipped_but_live, 0,
       "$name during each(): no live key is skipped by the iteration")
        or diag "skipped while still live: @skipped_but_live";
}

# clear() must also reset the dispatcher's shard cursor of an abandoned each()
{
    my $m = Data::HashMap::Shared::SI->new_sharded("$dir/cleared", 4, 1000);
    $m->put($_, 1) for @keys;

    my $n = 0;
    while (my ($k, $v) = $m->each) { last if ++$n >= 15 }
    $m->clear;

    my @after = map { "post-clear-$_" } @keys;
    $m->put($_, 1) for @after;

    my %seen;
    while (my ($k, $v) = $m->each) { $seen{$k} = 1 }
    is scalar(keys %seen), scalar @after,
        'each() after clear() visits every shard, not just the ones above the old cursor';
}

done_testing;
