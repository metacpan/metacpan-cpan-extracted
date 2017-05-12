use strict;
use warnings;

use Test::More;
use Data::Remember::Class;

can_ok('Data::Remember::Class', 'new');

my $store = Data::Remember::Class->new('Memory');

can_ok($store, qw( 
    remember remember_these
    recall recall_each recall_and_update
    forget forget_when
));

$store->remember(foo => 1);
$store->remember(bar => 2);
$store->remember(baz => 3);

$store->remember_these(qux => 4);
$store->remember_these(qux => 5);
$store->remember_these(qux => 6);

is($store->recall('foo'), 1, 'recalled foo is 1');
is($store->recall('bar'), 2, 'recalled bar is 2');
is($store->recall('baz'), 3, 'recalled baz is 3');
is_deeply([@{$store->recall('qux')}], [ 4, 5, 6 ], 'recalled qux is [ 4, 5, 6 ]');

is_deeply($store->recall([]), {
    foo => 1,
    bar => 2,
    baz => 3,
    qux => [ 4, 5, 6 ],
}, 'recalled all the top level keys');

{
    my $iter = $store->recall_each([]);
    my %got;
    while (my ($k, $v) = $iter->()) {
        $got{$k} = $v;
    }
    is_deeply(\%got, {
        foo => 1,
        bar => 2,
        baz => 3,
        qux => [ 4, 5, 6 ],
    }, 'recalled each got some top level keys by iterator');
}

my $bar = $store->recall_and_update(sub { $_++ }, 'bar');
is($bar, 2, 'recall_and_update returned 2');
is($store->recall('bar'), 3, 'recall_and_update change bar to 3');

$store->forget('bar');
$store->forget('bar'); # forgetting something twice is redundant, but ok

is($store->recall('foo'), 1, 'recalled foo is 1');
is($store->recall('bar'), undef, 'recalled bar is forgotten');
is($store->recall('baz'), 3, 'recalled baz is 3');

$store->forget('foo');

$store->remember([ foo => 1, bar => 2, baz => 3 ], 'fantastic');
$store->remember([ foo => 3, bar => 2, baz => 4 ], 'supreme');
$store->remember([ foo => 1, bar => 3, baz => 2 ], 'excellent');

is($store->recall([ foo => 1, bar => 2, baz => 3 ]), 'fantastic', 'long key 1 => fantastic');
is($store->recall([ foo => 3, bar => 2, baz => 4 ]), 'supreme', 'long key 2 => supreme');
is($store->recall([ foo => 1, bar => 3, baz => 2 ]), 'excellent', 'long key 3 => excellent');

$store->remember([ foo => 1, bar => 2, baz => 3 ], {
    fantastic => 10,
    supreme   => 9,
    excellent => 8,
});

is($store->recall([ foo => 1, bar => 2, baz => 3, 'fantastic' ]), 10, 'fantastic => 10');
is($store->recall([ foo => 1, bar => 2, baz => 3, 'supreme' ]), 9, 'supremem => 9');
is($store->recall([ foo => 1, bar => 2, baz => 3, 'excellent' ]), 8, 'excellent => 8');

{
    my $iter = $store->recall_each([ foo => 1, 'bar' ]);
    my %got;
    my $count = 0;
    while (my ($k, $v) = $iter->()) {
        $got{$k} = $v;
        $count++;
    }
    is($count, 2, 'iterated over complex keys twice');
    is_deeply(\%got, {
        2 => {
            baz => {
                3 => {
                    fantastic => 10,
                    supreme   => 9,
                    excellent => 8,
                },
            },
        },
        3 => {
            baz => {
                2 => 'excellent',
            },
        },
    }, 'recalled each got all top level keys by iterator');
}

# Forget when hash using $_[0] and $_[1]
{
    $store->remember(flarg => { dood => 20, daad => 21, diid => 22 });

    is($store->recall([ flarg => 'dood' ]), 20, 'flarg dood is 20');
    is($store->recall([ flarg => 'daad' ]), 21, 'flarg daad is 21');
    is($store->recall([ flarg => 'diid' ]), 22, 'flarg diid is 22');

    $store->forget_when(sub { $_[0] eq 'daad' or $_[1] eq 22 }, 'flarg');

    is($store->recall([ flarg => 'dood' ]), 20, 'flarg dood is 20');
    is($store->recall([ flarg => 'daad' ]), undef, 'flarg daad is undef');
    is($store->recall([ flarg => 'diid' ]), undef, 'flarg diid is undef');
}

# Foget when hash using $_
{
    $store->remember(flarg => { dood => 23, daad => 24, diid => 25 });

    is($store->recall([ flarg => 'dood' ]), 23, 'flarg dood is 23');
    is($store->recall([ flarg => 'daad' ]), 24, 'flarg daad is 24');
    is($store->recall([ flarg => 'diid' ]), 25, 'flarg diid is 25');

    $store->forget_when(sub { $_ eq 23 }, 'flarg');

    is($store->recall([ flarg => 'dood' ]), undef, 'flarg dood is undef');
    is($store->recall([ flarg => 'daad' ]), 24, 'flarg daad is 24');
    is($store->recall([ flarg => 'diid' ]), 25, 'flarg diid is 24');
}

# Forget when array using $_[0] and $_[1]
{
    $store->remember(splack => [ 11, 12, 13 ]);

    is_deeply([@{$store->recall('splack')}], [ 11, 12, 13 ], 'splack is [ 11, 12, 13 ]');
    
    $store->forget_when(sub { $_[0] == 2 or $_[1] == 11  }, 'splack');

    is_deeply([@{$store->recall('splack')}], [ 12 ], 'splack is [ 12 ]');
}

# Forget when array using $_
{
    $store->remember(splack => [ 14, 15, 16 ]);

    is_deeply([@{$store->recall('splack')}], [ 14, 15, 16 ], 'splack is [ 14,15,16 ]');

    $store->forget_when(sub { $_ == 15 }, 'splack');

    is_deeply([@{$store->recall('splack')}], [ 14, 16 ], 'splack is [ 14,16 ]');
}

# Forget when scalar using $_[1]
{
    $store->remember(blah => 7);
    $store->remember(bloo => 8);

    is($store->recall('blah'), 7, 'recalled blah is 7');
    is($store->recall('bloo'), 8, 'recalled bloo is 8');

    $store->forget_when(sub { $_ == 8 }, 'blah');
    $store->forget_when(sub { $_ == 8 }, 'bloo');

    is($store->recall('blah'), 7, 'recalled blah is 7');
    is($store->recall('bloo'), undef, 'recalled bloo is undef');
}

# Forget when scalar using $_
{
    $store->remember(blah => 9);
    $store->remember(bloo => 10);

    is($store->recall('blah'), 9, 'recalled blah is 9');
    is($store->recall('bloo'), 10, 'recalled bloo is 10');

    $store->forget_when(sub { is($_[0], undef); $_[1] == 9 }, 'blah');
    $store->forget_when(sub { is($_[0], undef); $_[1] == 9 }, 'bloo');

    is($store->recall('blah'), undef, 'recalled blah is undef');
    is($store->recall('bloo'), 10, 'recalled bloo is 10');
}

done_testing;
