#!/usr/bin/env perl
use warnings;
use strict;
use Array::Circular;
use Test::More;
use Test::Exception;

my $a = new_ok('Array::Circular', [(qw/one two three four five/)]);

# github issue #2
subtest 'forward/back many' => sub { 
    is $a->current, 'one', "first element";
    is $a->next(2), 'three', "second element";
    is $a->current, 'three', "second element";
    is $a->previous(2), 'one', "first element";
};

# github issue #5
subtest 'negative offsets' => sub {
    is $a->index, 0, 'index';
    is $a->current, 'one', 'current';
    lives_ok { $a->next(-1) } 'expecting to live';
    is $a->index, 4, 'index';
    is $a->current, 'five', 'current';
    lives_ok { $a->next(-2) } 'expecting to live';
    is $a->index, 2, 'index';
    is $a->current, 'three', 'current';

    lives_ok { $a->prev(-1) } 'expecting to live';
    is $a->index, 3, 'index';
    is $a->current, 'four', 'current';
    lives_ok { $a->prev(-2) } 'expecting to live';
    is $a->index, 0, 'index';
    is $a->current, 'one', 'current';
};

done_testing;
