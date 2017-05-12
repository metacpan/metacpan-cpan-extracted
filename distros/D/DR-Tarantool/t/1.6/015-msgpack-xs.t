#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);
use lib qw(blib/lib blib/arch ../blib/lib
    ../blib/arch ../../blib/lib ../../blib/arch);

use Test::More tests    => 73;
use Encode qw(decode encode);


BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tarantool::MsgPack', 'msgpack', 'msgunpack', 'msgcheck';
}
note '===================== pack ===============================';
note 'string';
{
    my $res = DR::Tarantool::_msgpack('test');
    like $res, qr{test$}, 'text';
    my $type = unpack 'C', $res;
    is $type, 0xA4, 'type';

    $res = DR::Tarantool::_msgpack('test' x 20);
    like $res, qr{test$}, 'text';
    $type = unpack 'C', $res;
    is $type, 0xD9, 'str 8';


    $res = DR::Tarantool::_msgpack('test' x 200);
    like $res, qr{test$}, 'text';
    $type = unpack 'C', $res;
    is $type, 0xDA, 'str 16';

    $res = DR::Tarantool::_msgpack('test' x 20000);
    like $res, qr{test$}, 'text';
    $type = unpack 'C', $res;
    is $type, 0xDb, 'str 32';
}

note 'numbers';
{
    my $res = DR::Tarantool::_msgpack(10);
    my $type = unpack 'C', $res;
    is $type, 10, 'fixint';


    $res = DR::Tarantool::_msgpack(-10);
    $type = unpack 'c', $res;
    is $type, -10, 'negative fixint';


    $res = DR::Tarantool::_msgpack(140);
    $type = unpack 'C', $res;
    is $type, 0xCC, 'positive uint8';

    $res = DR::Tarantool::_msgpack(-105);
    $type = unpack 'C', $res;
    is $type, 0xD0, 'negative int8';

    $res = DR::Tarantool::_msgpack(1400);
    $type = unpack 'C', $res;
    is $type, 0xCD, 'positive uint16';

    $res = DR::Tarantool::_msgpack(-1400);
    $type = unpack 'C', $res;
    is $type, 0xD1, 'negative int16';

    $res = DR::Tarantool::_msgpack(67000);
    $type = unpack 'C', $res;
    is $type, 0xCE, 'positive uint32';

    $res = DR::Tarantool::_msgpack(-68123);
    $type = unpack 'C', $res;
    is $type, 0xD2, 'negative int32';

    $res = DR::Tarantool::_msgpack(67000000000);
    $type = unpack 'C', $res;
    is $type, 0xCF, 'positive uint64';

    $res = DR::Tarantool::_msgpack(-68123456789);
    $type = unpack 'C', $res;
    is $type, 0xD3, 'negative int64';
}

note 'float';
{
    my $res = DR::Tarantool::_msgpack(10.0);
    my $type = unpack 'C', $res;
    is $type, 10, 'double as fixint';

    $res = DR::Tarantool::_msgpack(-10.0);
    $type = unpack 'c', $res;
    is $type, -10, 'double as fixint';

    $res = DR::Tarantool::_msgpack(10.1);
    $type = unpack 'C', $res;
    is $type, 0xCB, 'double';
}


note 'nil';
{
    my $res = DR::Tarantool::_msgpack(undef);
    my $type = unpack 'C', $res;
    is $type, 0xC0, 'nil';
}


note 'array';
{
    my $res = DR::Tarantool::_msgpack([]);
    my $type = unpack 'C', $res;
    is $type, 0x90, 'fixed empty array';
    is length($res), 1, 'array_len';
}
{
    my $res = DR::Tarantool::_msgpack([1, 2, 3]);
    my ($type, $v1, $v2, $v3) = unpack 'C*', $res;
    is $type, 0x93, 'fixed array';
    is length($res), 1 + 3, 'array_len';
    is_deeply [$v1, $v2, $v3], [1,2,3], 'values';
}


note 'hash';
{
    my $res = DR::Tarantool::_msgpack({});
    my $type = unpack 'C', $res;
    is $type, 0x80, 'fixed empty hash';
    is length($res), 1, 'pack_len';
}
{
    my $res = DR::Tarantool::_msgpack({ 1 => 2 });
    my ($type, $v1, $v2, $v3) = unpack 'C*', $res;
    is $type, 0x81, 'fixed hash';
    is length($res), 3, 'hash len';
    diag explain [ $v1, $v2, $v3 ] unless
    is_deeply [ $v1, $v2 ], [ 1,2 ], 'values';
}
{
    my $res = DR::Tarantool::_msgpack({ 'a' => 2 });
    my ($type, $v1, $v2, $v3) = unpack 'C*', $res;
    is $type, 0x81, 'fixed hash';
    is length($res), 4, 'hash len';
    diag explain [ $v1, $v2, $v3 ] unless
    is_deeply [ $v1, chr($v2), $v3 ], [ 0xA1, 'a',2 ], 'values';
}

note 'bless';
{
    my $res = DR::Tarantool::_msgpack(DR::Tarantool::MsgPack::Bool->new(0));
    is length $res, 1, 'package length';
    is $res, pack('C', 0xC2), 'false';
    
    $res = DR::Tarantool::_msgpack(DR::Tarantool::MsgPack::FALSE);
    is length $res, 1, 'package length';
    is $res, pack('C', 0xC2), 'false';
    
    $res = DR::Tarantool::_msgpack(DR::Tarantool::MsgPack::Bool->new(1));
    is length $res, 1, 'package length';
    is $res, pack('C', 0xC3), 'true';
    
    $res = DR::Tarantool::_msgpack(DR::Tarantool::MsgPack::TRUE);
    is length $res, 1, 'package length';
    is $res, pack('C', 0xC3), 'false';

    {
        package BTest;
    }
    my $tp = bless {} => 'BTest';
    $res = eval { DR::Tarantool::_msgpack($tp) };
    like $@, qr{msgpack}, 'error message for broken package';
}

note '==================== unpack ==============================';
note 'string';
{
    my $p = DR::Tarantool::_msgpack('test');
    is DR::Tarantool::_msgunpack($p, 1), 'test', 'fixed string';

    $p = DR::Tarantool::_msgpack('test' x 20);
    is DR::Tarantool::_msgunpack($p, 1), 'test' x 20, 'string 8';

    $p = DR::Tarantool::_msgpack('test' x 200);
    is DR::Tarantool::_msgunpack($p, 1), 'test' x 200, 'string 16';

    $p = DR::Tarantool::_msgpack('test' x 20000);
    is DR::Tarantool::_msgunpack($p, 1), 'test' x 20000, 'string 32';
}
note 'numbers';
{
    my $p = DR::Tarantool::_msgpack(10);
    is DR::Tarantool::_msgunpack($p, 1), 10, 'fixed int';

    $p = DR::Tarantool::_msgpack(-10);
    is DR::Tarantool::_msgunpack($p, 1), -10, 'fixed negative';

    $p = DR::Tarantool::_msgpack(-100);
    is DR::Tarantool::_msgunpack($p, 1), -100, 'negative int8';

    $p = DR::Tarantool::_msgpack(10000);
    is DR::Tarantool::_msgunpack($p, 1), 10000, 'uint16';

    $p = DR::Tarantool::_msgpack(123333939393939);
    is DR::Tarantool::_msgunpack($p, 1), 123333939393939, 'uint64';
}

note 'nil';
{
    my $p = DR::Tarantool::_msgpack(undef);
    is DR::Tarantool::_msgunpack($p, 1), undef, 'undef';
}


note 'bool';
{
    my $p = DR::Tarantool::_msgpack(DR::Tarantool::MsgPack::TRUE);
    ok DR::Tarantool::_msgunpack($p, 1), 'true';
    $p = DR::Tarantool::_msgpack(DR::Tarantool::MsgPack::FALSE);
    ok !DR::Tarantool::_msgunpack($p, 1), 'false';
}

note 'hash';
{
    my $p = DR::Tarantool::_msgpack({});
    is_deeply DR::Tarantool::_msgunpack($p, 1), {}, 'empty hash';
}
{
    my $p = DR::Tarantool::_msgpack({ a => 'b' });
    is_deeply DR::Tarantool::_msgunpack($p, 1), {a => 'b'}, 'non-empty hash';
}
{
    my $p = DR::Tarantool::_msgpack({ a => 'b', c => 'd' });
    is_deeply DR::Tarantool::_msgunpack($p, 1), {a => 'b', c => 'd'},
        'non-empty hash';
}
{
    my $p = DR::Tarantool::_msgpack({ a => 'b', c => undef });
    is_deeply DR::Tarantool::_msgunpack($p, 1), {a => 'b', c => undef},
        'non-empty hash';
}

note 'arrays';
{
    my $p = DR::Tarantool::_msgpack([]);
    diag explain DR::Tarantool::_msgunpack($p, 1) unless
    is_deeply DR::Tarantool::_msgunpack($p, 1), [], 'empty array';
}
{
    my $p = DR::Tarantool::_msgpack([ a => 'b' ]);
    diag explain DR::Tarantool::_msgunpack($p, 1) unless
    is_deeply DR::Tarantool::_msgunpack($p, 1), [a => 'b'], 'non-empty array';
}
{
    my $p = DR::Tarantool::_msgpack([ a => 'b', c => 'd', undef ]);
    ok DR::Tarantool::_msgcheck($p), 'non broken msgpack';
    is DR::Tarantool::_msgcheck($p), DR::Tarantool::_msgcheck($p . 'aaa'),
        'msgcheck return length';
    is DR::Tarantool::_msgcheck($p), length($p), 'length is valid';
    diag explain DR::Tarantool::_msgunpack($p, 1) unless
    is_deeply DR::Tarantool::_msgunpack($p, 1), [ a => 'b', c => 'd', undef ],
        'non-empty array';
}


note 'unpack errors';
{
    my $p = substr DR::Tarantool::_msgpack([1,2,3,4,5, 6, 7, 5000]), 0, 8;
    is DR::Tarantool::_msgcheck($p), 0, 'broken msgpack';
    ok !eval { DR::Tarantool::_msgunpack($p, 1); 1 }, '_msgpack(broken)';
    like $@ => qr{Unexpected EOF}, 'message error';
}

note 'utf8';
{
    my $p = DR::Tarantool::_msgpack(['привет']);
    ok $p => 'encode msgpack';

    is_deeply DR::Tarantool::_msgunpack($p, 1), ['привет'], 'decode msgpack';
    is_deeply DR::Tarantool::_msgunpack($p, 0),
        [encode utf8 => 'привет'], 'decode msgpack';
}
