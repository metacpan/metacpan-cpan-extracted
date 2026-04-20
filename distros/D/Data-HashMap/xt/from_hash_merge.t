use strict;
use warnings;
use Test::More;

use Data::HashMap::II;
use Data::HashMap::SS;
use Data::HashMap::IA;

# ---- from_hash basic ----

{
    my $m = Data::HashMap::II->new();
    $m->from_hash({ 1 => 10, 2 => 20, 3 => 30 });
    is $m->size, 3, 'from_hash: 3 entries';
    is $m->get(2), 20, 'from_hash: value correct';
}

# ---- merge basic ----

{
    my $a = Data::HashMap::II->new();
    my $b = Data::HashMap::II->new();
    $a->put($_, $_) for 1..5;
    $b->put($_, $_ * 100) for 3..7;
    $a->merge($b);
    is $a->size, 7, 'merge: union size';
    is $a->get(2), 2,   'merge: left-only untouched';
    is $a->get(4), 400, 'merge: overlapping key replaced by right';
    is $a->get(6), 600, 'merge: right-only added';
}

# ---- self-merge (no-op) ----

{
    my $m = Data::HashMap::II->new();
    $m->put($_, $_) for 1..10;
    $m->merge($m);
    is $m->size, 10, 'self-merge: size unchanged';
    is $m->get(5), 5, 'self-merge: values unchanged';
}

# ---- merge into max_size map triggers LRU eviction ----

{
    my $a = Data::HashMap::II->new(5);   # max_size=5
    my $b = Data::HashMap::II->new();
    $a->put($_, $_) for 1..5;
    $b->put($_, -$_) for 100..104;
    $a->merge($b);
    cmp_ok $a->size, '<=', 5, 'merge+max_size: size stays at max';
    ok $a->exists(104), 'newest merged key kept';
}

# ---- merge with TTL-enabled maps ----

{
    my $a = Data::HashMap::II->new(0, 60);
    my $b = Data::HashMap::II->new(0, 60);
    $a->put($_, $_) for 1..5;
    $b->put($_, $_ * 10) for 6..10;
    $a->merge($b);
    is $a->size, 10, 'merge with TTL: count correct';
    is $a->get(8), 80, 'merge with TTL: value correct';
}

# ---- from_hash into IA (SV* values) ----

{
    my $m = Data::HashMap::IA->new();
    $m->from_hash({ 1 => [1, 2], 2 => [3, 4] });
    is_deeply $m->get(1), [1, 2], 'IA from_hash: arrayref value';
    is_deeply $m->get(2), [3, 4], 'IA from_hash: second arrayref';
}

done_testing;
