#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moose;
    use Bread::Board::Declare;

    has foo => (
        reader    => 'get_foo',
        writer    => 'set_foo',
        accessor  => 'foo',
        predicate => 'has_foo',
        clearer   => 'clear_foo',
        value     => 'foo',
    );

    has bool => (
        traits  => ['Bool'],
        isa     => 'Bool',
        value   => 0,
        handles => {
            bool_unset  => 'unset',
            bool_set    => 'set',
            bool_not    => 'not',
            bool_toggle => 'toggle',
        },
    );

    has string => (
        traits  => ['String'],
        isa     => 'Str',
        value   => '',
        default => '', # XXX: ugh, needed because of the default_default stuff
        handles => {
            string_prepend => 'prepend',
            string_chop    => 'chop',
            string_substr  => 'substr',
            string_match   => 'match',
            string_length  => 'length',
            string_inc     => 'inc',
            string_append  => 'append',
            string_clear   => 'clear',
            string_chomp   => 'chomp',
            string_replace => 'replace',
        },
    );

    has hash => (
        traits  => ['Hash'],
        isa     => 'HashRef',
        block   => sub { {} },
        handles => {
            hash_delete   => 'delete',
            hash_exists   => 'exists',
            hash_values   => 'values',
            hash_get      => 'get',
            hash_set      => 'set',
            hash_is_empty => 'is_empty',
            hash_keys     => 'keys',
            hash_elements => 'elements',
            hash_kv       => 'kv',
            hash_defined  => 'defined',
            hash_accessor => 'accessor',
            hash_count    => 'count',
            hash_clear    => 'clear',
        },
    );

    has counter => (
        traits  => ['Counter'],
        isa     => 'Int',
        value   => 0,
        default => 0, # XXX: ugh, needed because of the default_default stuff
        handles => {
            counter_set   => 'set',
            counter_reset => 'reset',
            counter_inc   => 'inc',
            counter_dec   => 'dec',
        },
    );

    has code => (
        traits  => ['Code'],
        isa     => 'CodeRef',
        block   => sub { sub { } },
        handles => {
            code_execute        => 'execute',
            code_execute_method => 'execute_method',
        },
    );

    has array => (
        traits  => ['Array'],
        isa     => 'ArrayRef',
        block   => sub { [] },
        handles => {
            array_unshift       => 'unshift',
            array_shuffle       => 'shuffle',
            array_delete        => 'delete',
            array_get           => 'get',
            array_set           => 'set',
            array_uniq          => 'uniq',
            array_is_empty      => 'is_empty',
            array_shift         => 'shift',
            array_grep          => 'grep',
            array_sort_in_place => 'sort_in_place',
            array_sort          => 'sort',
            array_elements      => 'elements',
            array_pop           => 'pop',
            array_reduce        => 'reduce',
            array_insert        => 'insert',
            array_join          => 'join',
            array_first         => 'first',
            array_natatime      => 'natatime',
            array_accessor      => 'accessor',
            array_count         => 'count',
            array_map           => 'map',
            array_push          => 'push',
            array_clear         => 'clear',
            array_splice        => 'splice',
        },
    );

    has number => (
        traits  => ['Number'],
        isa     => 'Num',
        value   => 1,
        handles => {
            number_add => 'add',
            number_set => 'set',
            number_sub => 'sub',
            number_mul => 'mul',
            number_mod => 'mod',
            number_abs => 'abs',
            number_div => 'div',
        },
    );

    __PACKAGE__->meta->make_immutable;
}

pass("everything compiled successfully");

done_testing;
