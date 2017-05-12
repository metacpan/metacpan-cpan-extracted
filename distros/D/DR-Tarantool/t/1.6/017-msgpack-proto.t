#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);
use lib qw(blib/lib blib/arch ../blib/lib
    ../blib/arch ../../blib/lib ../../blib/arch);

use Test::More tests    => 25;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tarantool::MsgPack::Proto',
        qw(call_lua response insert replace del update select auth);
}


note 'call';
{
    my ($p) = response call_lua(121, 'test');
    is_deeply $p => {
        CODE            => 'CALL',
        FUNCTION_NAME   => 'test',
        SYNC            => 121,
        TUPLE           => []
    }, 'Call request';
}

{
    my ($p) = response call_lua(121, 'test', 1, [2, 3], 4);
    is_deeply $p => {
        CODE            => 'CALL',
        FUNCTION_NAME   => 'test',
        SYNC            => 121,
        TUPLE           => [1, [2, 3], 4]
    }, 'Call request';
}

note 'insert';
{
    my ($p) = response insert(10, 20, [1,2,3]);
    is_deeply $p => {
        CODE            => 'INSERT',
        SYNC            => 10,
        TUPLE           => [1, 2, 3],
        SPACE_ID        => 20,
    }, 'Insert request with space number';
}
{
    my ($p) = response insert(17, 20, 'scalar');
    is_deeply $p => {
        CODE            => 'INSERT',
        SYNC            => 17,
        TUPLE           => ['scalar'],
        SPACE_ID        => 20,
    }, 'Insert request with space number';
}
{
    my ($p) = response insert(19, 'space_name', [1,2,3]);
    is_deeply $p => {
        CODE            => 'CALL',
        SYNC            => 19,
        TUPLE           => [1, 2, 3],
        FUNCTION_NAME   => 'box.space.space_name:insert',
    }, 'Insert request with space name';
}

note 'replace';
{
    my ($p) = response replace(10, 20, [1,2,3]);
    is_deeply $p => {
        CODE            => 'REPLACE',
        SYNC            => 10,
        TUPLE           => [1, 2, 3],
        SPACE_ID        => 20,
    }, 'Replace request with space number';
}
{
    my ($p) = response replace(17, 20, 'scalar');
    is_deeply $p => {
        CODE            => 'REPLACE',
        SYNC            => 17,
        TUPLE           => ['scalar'],
        SPACE_ID        => 20,
    }, 'Replace request with space number';
}
{
    my ($p) = response replace(19, 'space_name', [1,2,3]);
    is_deeply $p => {
        CODE            => 'CALL',
        SYNC            => 19,
        TUPLE           => [1, 2, 3],
        FUNCTION_NAME   => 'box.space.space_name:replace',
    }, 'Replace request with space name';
}

note 'del';
{
    my ($p) = response del(10, 27, [1,2,3]);
    is_deeply $p => {
        CODE            => 'DELETE',
        SYNC            => 10,
        KEY             => [1, 2, 3],
        SPACE_ID        => 27,
    }, 'Delete request with space number';
}
{
    my ($p) = response del(17, 20, 'scalar');
    is_deeply $p => {
        CODE            => 'DELETE',
        SYNC            => 17,
        KEY             => ['scalar'],
        SPACE_ID        => 20,
    }, 'Delete request with space number';
}
{
    my ($p) = response del(19, 'space_name', [1,2,3]);
    is_deeply $p => {
        CODE            => 'CALL',
        SYNC            => 19,
        TUPLE           => [1, 2, 3],
        FUNCTION_NAME   => 'box.space.space_name:delete',
    }, 'Delete request with space name';
}

note 'update';
{
    my ($p) = response update(10, 27, [1,2,3], [['+', 1, 2]]);
    is_deeply $p => {
        CODE            => 'UPDATE',
        SYNC            => 10,
        KEY             => [1, 2, 3],
        TUPLE           => [['+', 1, 2]],
        SPACE_ID        => 27,
    }, 'Update request with space number';
}
{
    my ($p) = response update(10, 27, 'test', [['+', 1, 2]]);
    is_deeply $p => {
        CODE            => 'UPDATE',
        SYNC            => 10,
        KEY             => ['test'],
        TUPLE           => [['+', 1, 2]],
        SPACE_ID        => 27,
    }, 'Update request with space number';
}
{
    my ($p) = response update(10, 'space_name', 'test', [['+', 1, 2]]);
    is_deeply $p => {
        CODE            => 'CALL',
        SYNC            => 10,
        TUPLE           => [['test'], [['+', 1, 2]]],
        FUNCTION_NAME   => 'box.space.space_name:update',
    }, 'Update request with space name';
}

note 'select';
{
    my ($p) = response select(10, 27, 30, [1,2,3]);
    is_deeply $p => {
        CODE            => 'SELECT',
        SYNC            => 10,
        OFFSET          => 0,
        LIMIT           => 0xFFFF_FFFF,
        KEY             => [1, 2, 3],
        SPACE_ID        => 27,
        INDEX_ID        => 30,
        ITERATOR        => 'EQ',
    }, 'Select request with space & index numbers';
}
{
    my ($p) = response select(10, 27, 30, [1,2,3], 300);
    is_deeply $p => {
        CODE            => 'SELECT',
        SYNC            => 10,
        OFFSET          => 0,
        LIMIT           => 300,
        KEY             => [1, 2, 3],
        SPACE_ID        => 27,
        INDEX_ID        => 30,
        ITERATOR        => 'EQ',
    }, 'Select request with space & index numbers';
}
{
    my ($p) = response select(10, 27, 30, [1,2,3], 300, 400, 'LE');
    is_deeply $p => {
        CODE            => 'SELECT',
        SYNC            => 10,
        OFFSET          => 400,
        LIMIT           => 300,
        KEY             => [1, 2, 3],
        SPACE_ID        => 27,
        INDEX_ID        => 30,
        ITERATOR        => 'LE',
    }, 'Select request with space & index numbers';
}
{
    my ($p) = response select('10', '27', '30', [1,2,3]);
    is_deeply $p => {
        CODE            => 'SELECT',
        SYNC            => 10,
        OFFSET          => 0,
        LIMIT           => 0xFFFF_FFFF,
        KEY             => [1, 2, 3],
        SPACE_ID        => 27,
        INDEX_ID        => 30,
        ITERATOR        => 'EQ',
    }, 'Select request with space & index numbers';
}
{
    my ($p) = response select('10', 'space_name', 'index_name', [1], 5, 1, 'GT');

    is_deeply $p => {
        CODE            => 'CALL',
        SYNC            => 10,
        FUNCTION_NAME   => 'box.space.space_name.index.index_name:select',
        TUPLE           => [
            [1],
            {
                limit       => 5,
                offset      => 1,
                iterator    => 6,
            }
        ]
    }, 'Select request with space & index numbers';
}

note 'auth';
{
    local $DR::Tarantool::MsgPack::Proto::DECODE_UTF8 = 0;
    my ($p) = response auth 19, 'user', 'password', '1234';
    isa_ok $p => 'HASH';
    my $tuple = delete $p->{TUPLE};
    is_deeply $p => {
        CODE        => 'AUTH',
        SYNC        => 19,
        USER_NAME   => 'user',
    }, 'Auth request';
    isa_ok $tuple => 'ARRAY';
    is $tuple->[0] => 'chap-sha1', 'chap-sha1';
    is length $tuple->[1] => 20, 'length of sha';
}
