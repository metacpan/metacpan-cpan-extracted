use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes ();

# pop/shift return an EMPTY LIST on an empty map, which is what makes
# `while (my ($k, $v) = $map->shift)` terminate.  Every existing caller binds
# the result with `my ($k) = ...`, which cannot tell () from (undef).  Check
# the list shape directly, on every variant.

my @variants = qw(II IS SI SS I16 I16S I32 I32S SI16 SI32);
my $dir = tempdir(CLEANUP => 1);
for my $v (@variants) {
    my $cls = "Data::HashMap::Shared::$v";
    eval "require $cls; 1" or die $@;
    my $m = $cls->new("$dir/pop-$v.shm", 16);

    is_deeply [$m->pop],   [], "$v: pop on an empty map returns an empty list";
    is_deeply [$m->shift], [], "$v: shift on an empty map returns an empty list";

    $m->put(1, 1);
    is scalar(my @kv = $m->pop), 2, "$v: pop on a one-entry map returns (key, value)";
    is_deeply [$m->pop],   [], "$v: pop after the last entry returns an empty list";
    is_deeply [$m->shift], [], "$v: shift after the last entry returns an empty list";

    $m->put($_, $_) for 1 .. 3;
    my $drained = 0;
    while (my ($k, $val) = $m->shift) { last if ++$drained > 10 }
    is $drained, 3, "$v: while (my (\$k, \$v) = shift) drains 3 entries and stops";

    $m->put($_, $_) for 1 .. 3;
    $drained = 0;
    while (my ($k, $val) = $m->pop) { last if ++$drained > 10 }
    is $drained, 3, "$v: while (my (\$k, \$v) = pop) drains 3 entries and stops";
}

# Finding only expired entries, pop, shift and drain sweep them away, and the
# table shrinks as after any other removal.
{
    require Data::HashMap::Shared::II;
    my %m;
    for my $op (qw(pop shift drain)) {
        $m{$op} = Data::HashMap::Shared::II->new("$dir/sweep-$op.shm", 10000, 0, 60);
        $m{$op}->put_ttl($_, $_, 1) for 1 .. 5000;
    }
    my $cap = $m{pop}->capacity;
    Time::HiRes::sleep(1.2);
    for my $op (qw(pop shift drain)) {
        my @r = $op eq 'drain' ? $m{$op}->drain(10) : $m{$op}->$op;
        is_deeply \@r, [], "$op: an all-expired map returns an empty list";
        is $m{$op}->size, 0, "$op: ...having swept the expired entries";
        cmp_ok $m{$op}->capacity, '<', $cap / 4, "$op: ...and shrunk the table from $cap slots";
    }
}
done_testing;
