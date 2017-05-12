use strict;
use warnings;

plan tests => 46;

can_ok('main', qw( 
    remember remember_these 
    recall recall_each recall_and_update 
    forget forget_when 
));

remember foo => 1;
remember bar => 2;
remember baz => 3;

remember_these qux => 4;
remember_these qux => 5;
remember_these qux => 6;

is(recall 'foo', 1, 'recalled foo is 1');
is(recall 'bar', 2, 'recalled bar is 2');
is(recall 'baz', 3, 'recalled baz is 3');
is_deeply([@{recall('qux')}], [ 4, 5, 6 ], 'recalled qux is [ 4, 5, 6 ]');

is_deeply(recall [], {
    foo => 1,
    bar => 2,
    baz => 3,
    qux => [ 4, 5, 6 ],
}, 'recalled all the top level keys');

{
    my $iter = recall_each [];
    my %got;
    while (my ($k, $v) = $iter->()) {
        $got{$k} = $v;
    }
    is_deeply(\%got, {
        foo => 1,
        bar => 2,
        baz => 3,
        qux => [ 4, 5, 6 ],
    }, 'recalled each got all top level keys by iterator');
}

my $bar = recall_and_update { $_++ } 'bar';
is($bar, 2, 'recall_and_update returned 2');
is(recall 'bar', 3, 'recall_and_update changed bar to 3');

forget 'bar';
forget 'bar'; # forgetting something twice is redundant, but ok

is(recall 'foo', 1, 'recalled foo is 1');
is(recall 'bar', undef, 'recalled bar is forgotten');
is(recall 'baz', 3, 'recalled baz is 3');

forget 'foo';

remember [ foo => 1, bar => 2, baz => 3 ], 'fantastic';
remember [ foo => 3, bar => 2, baz => 4 ], 'supreme';
remember [ foo => 1, bar => 3, baz => 2 ], 'excellent';

is(recall [ foo => 1, bar => 2, baz => 3 ], 'fantastic', 'long key 1 => fantastic');
is(recall [ foo => 3, bar => 2, baz => 4 ], 'supreme', 'long key 2 => supreme');
is(recall [ foo => 1, bar => 3, baz => 2 ], 'excellent', 'long key 3 => excellent');

remember [ foo => 1, bar => 2, baz => 3 ], {
    fantastic => 10,
    supreme   => 9,
    excellent => 8,
};

is(recall [ foo => 1, bar => 2, baz => 3, 'fantastic' ], 10, 'fantastic => 10');
is(recall [ foo => 1, bar => 2, baz => 3, 'supreme' ], 9, 'supreme => 9');
is(recall [ foo => 1, bar => 2, baz => 3, 'excellent' ], 8, 'excellent => 8');

{
    my $iter = recall_each [ foo => 1, 'bar' ];
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
    remember flarg => { dood => 20, daad => 21, diid => 22 };

    is(recall [ flarg => 'dood' ], 20, 'flarg dood is 20');
    is(recall [ flarg => 'daad' ], 21, 'flarg daad is 21');
    is(recall [ flarg => 'diid' ], 22, 'flarg diid is 22');

    forget_when { $_[0] eq 'daad' or $_[1] eq 22 } 'flarg';

    is(recall [ flarg => 'dood' ], 20, 'flarg dood is 20');
    is(recall [ flarg => 'daad' ], undef, 'flarg daad is undef');
    is(recall [ flarg => 'diid' ], undef, 'flarg diid is undef');
}

# Forget when hash using $_
{
    remember flarg => { dood => 23, daad => 24, diid => 25 };

    is(recall [ flarg => 'dood' ], 23, 'flarg dood is 23');
    is(recall [ flarg => 'daad' ], 24, 'flarg daad is 24');
    is(recall [ flarg => 'diid' ], 25, 'flarg diid is 25');

    forget_when { $_ eq 23 } 'flarg';

    is(recall [ flarg => 'dood' ], undef, 'flarg dood is undef');
    is(recall [ flarg => 'daad' ], 24, 'flarg daad is 24');
    is(recall [ flarg => 'diid' ], 25, 'flarg diid is 24');
}

# Forget when array using $_[0] and $_[1]
{
    remember splack => [ 11, 12, 13 ];

    is_deeply([@{recall('splack')}], [ 11, 12, 13 ], 'splack is [ 11,12,13 ]');

    forget_when { $_[0] == 2 or $_[1] == 11 } 'splack';

    is_deeply([@{recall('splack')}], [ 12 ], 'splack is [ 12 ]');
}

# Forget when array using $_
{
    remember splack => [ 14, 15, 16 ];

    is_deeply([@{recall('splack')}], [ 14, 15, 16 ], 'splack is [ 14,15,16 ]');

    forget_when { $_ == 15 } 'splack';

    is_deeply([@{recall('splack')}], [ 14, 16 ], 'splack is [ 14,16 ]');
}

# Forget when scalar using $_[1]
{
    remember blah => 7;
    remember bloo => 8;

    is(recall 'blah', 7, 'recalled blah is 7');
    is(recall 'bloo', 8, 'recalled bloo is 8');

    forget_when { $_ == 8 } 'blah';
    forget_when { $_ == 8 } 'bloo';

    is(recall 'blah', 7, 'recalled blah is 7');
    is(recall 'bloo', undef, 'recalled bloo is undef');
}

# Forget when scalar using $_
{
    remember blah => 9;
    remember bloo => 10;

    is(recall 'blah', 9, 'recalled blah is 9');
    is(recall 'bloo', 10, 'recalled bloo is 10');

    forget_when { is($_[0], undef); $_[1] == 9 } 'blah';
    forget_when { is($_[0], undef); $_[1] == 9 } 'bloo';

    is(recall 'blah', undef, 'recalled blah is undef');
    is(recall 'bloo', 10, 'recalled bloo is 10');
}
