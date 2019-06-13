#!/usr/bin/env perl
use warnings;
use strict;
use Array::Circular;
use Test::More;

my $a = new_ok('Array::Circular', [(qw/one two three four five/)], "made a new one");
is_deeply ($a->me, {current => 0, count => 0 }, "internal store initialised"  );
is $a->current, 'one', "first element";
is $a->next, 'two', "second element";
is $a->current, 'two', "second element";
is $a->previous, 'one', "first element";
is $a->current, 'one', "first element";
is $a->previous, 'five', "went back to last element";
is $a->loops, -1, "gone back once";
is $a->next, 'one', "first element";
is $a->current, 'one', "first element";
is $a->loops, 0, "back to zero loops";


subtest 'first loop' => sub {
    $a->next for 1 .. 4;
    $a->next;
    is ($a->current, "one", "Wrapped around 1");
    is ($a->loops, 1, "Been around 1 time");
};

subtest 'second loop' => sub {
    $a->next for 1 .. 4;
    $a->next;
    is ($a->current, "one", "Wrapped around 2");
    is ($a->loops, 2, "Been around 2 time");
};

subtest 'first backwards' => sub {
    $a->previous;
    is ($a->current, 'five', 'end of list');
    is ($a->loops, 1, 'went down one count');
    $a->previous for 1 .. 5;
    is $a->loops, 0, 'went down one count';
    $a->previous for 1 .. 5;
    is $a->loops, -1, 'went down one count';

};

subtest 'test reset' => sub {
    is $a->current, 'five', "last element";
    is $a->reset, 'one', 'back to beginning';
    is $a->loops, 0, "Reset loop counter too";
};

for ( 1 .. $a->size * 2) {
    subtest "test peek and size for starting index $_" => sub {
        for (0 .. $a->size *2 ) {
            my $expected = $a->peek($_);
            my $idx = ($_ + $a->index) % $a->size;
            # diag "Peek index is $idx";
            my $got = $a->[$idx];
            is $got, $expected, "peeking $_: $expected and $got are the same";
        }
    };
    $a->next;
}
$a->reset;



    


done_testing;
exit;

