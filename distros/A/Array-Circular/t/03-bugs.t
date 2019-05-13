#!/usr/bin/env perl
use warnings;
use strict;
use Array::Circular;
use Test::More;
use Test::Exception;

my $a = new_ok('Array::Circular', [(qw/one two three four five/)], "made a new one");

# github issue #2
subtest 'forward/back many' => sub { 
    is $a->current, 'one', "first element";
    is $a->next(2), 'three', "second element";
    is $a->current, 'three', "second element";
    is $a->previous(2), 'one', "first element";
};

subtest 'dies ok' => sub {
    dies_ok { $a->next(-2) } 'expecting to die';
};

done_testing;
