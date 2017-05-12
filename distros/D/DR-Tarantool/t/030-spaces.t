#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 149;
use Encode qw(decode encode);

my $LE = $] > 5.01 ? '<' : '';


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tarantool::Spaces';
}

use constant MODEL => 'DR::Tarantool::Spaces';


ok !eval { MODEL->new('abc') }, 'wrong arguments';
like $@, qr{HASHREF}, 'error message';
ok !eval { MODEL->new({a => 1}) }, 'wrong arguments';
like $@, qr{space number}, 'error message';
ok MODEL->new(), 'empty spaces';

my $s = MODEL->new({
    0 => {
        name    => 'test',
        default_type    => 'NUM',
        fields  => [
            qw(a b c),
            {
                type    => 'UTF8STR',
                name    => 'd'
            },
            {
                type    => 'NUM',
                name    => 'a123',
            },
            {
                type    => 'STR',
                name    => 'abcd',
            },
            {
                type    => 'INT',
                name    => 'int',
            },
            {
                type    => 'MONEY',
                name    => 'money',
            }
        ],
        indexes => {
            0   => [ qw(a b) ],
            1   => 'd',
            2   => 'c',
            3   => {
                name    => 'abc',
                fields  => [ qw(a b c) ]
            }
        }
    },
    1   => {
        name    => 'json',
        fields  => [
            {
                name => 'f',
                type => 'JSON',
            }
        ],
        indexes => {}
    }
});

is $s->family, 1, 'default family';
is $s->family(2), 2, 'change family';
is $s->space('test')->family, 2, 'space changed family';
is $s->family(1), 1, 'change again';
is $s->space('test')->family, 1, 'space changed family again';

is eval { $s->space('test')->index_number}, undef, 'index_number: undefined';
like $@, qr{name is undefined}, 'error string';
is eval { $s->space('test')->index_number('aaaaa') }, undef,
    'index_number: not found';
like $@, qr{index.*is undefined}, 'error string';

is $s->space_number('test'), 0, 'space_number(test)';
is $s->space_number('json'), 1, 'space_number(json)';
is eval { $s->space_number; 1}, undef, 'space_number()';
like $@, qr{space name or number is not defined}, 'error string';

is $s->space('test')->index_number('i0'), 0, 'index_number: i0';
is $s->space('test')->index_number('abc'), 3, 'index_number: i3';

is $s->space('test')->index_name(0), 'i0', 'index_name: i0';
is $s->space('test')->index_name(3), 'abc', 'index_name: i3';

is $s->space('test')->field_number('a'), 0, 'field_number(a)';
is $s->space('test')->field_number('b'), 1, 'field_number(b)';
is $s->space('test')->field_number('c'), 2, 'field_number(c)';
is eval { $s->space('test')->field_number('unknown'); 1 },
    undef, 'field_number(unknown)';
like $@, qr{Can't find field 'unknown' in this space}, 'error message';


is $s->space('test')->tail_index, 8, 'space0->tail_index';
is $s->space('json')->tail_index, 1, 'space1->tail_index';


my $class = $s->space('test')->tuple_class;
can_ok $class, qw(a b c d a123 abcd int money);
$class = $s->space('test')->tuple_class;
can_ok $class, qw(a b c d a123 abcd int money);
$class = $s->space('json')->tuple_class;
can_ok $class, qw(f);
$class = $s->space('json')->tuple_class;
can_ok $class, qw(f);

my $v = unpack "L$LE", $s->pack_field( test => a => '10' );
is $v, 10, 'pack_field NUM';
$v = unpack "L$LE", $s->pack_field( test => 0 => 11 );
is $v, 11, 'pack_field NUM';
$v = unpack "L$LE", $s->pack_field( 0 => 0 => 13 );
is $v, 13, 'pack_field NUM';
$v = unpack "L$LE", $s->pack_field( test => a123 => 13 );
is $v, 13, 'pack_field NUM64';
$v = $s->pack_field( test => d => 'test' );
is $v, 'test', 'pack_field STR';
$v = decode utf8 => $s->pack_field( test => d => 'привет' );
is $v, 'привет', 'pack_field STR';
$v = unpack "l$LE" => $s->pack_field( test => int => -10 );
is $v, -10, 'pack_field INT';
$v = decode utf8 => $s->pack_field( test => d => encode utf8 => 'привет' );
is $v, 'привет', 'pack_field STR';

# money
$v = unpack "l$LE" => $s->pack_field( test => money => '123');
is $v, 12300, 'pack_field MONEY(123)';
$v = unpack "l$LE" => $s->pack_field( test => money => '-123');
is $v, -12300, 'pack_field MONEY(-123)';
$v = unpack "l$LE" => $s->pack_field( test => money => '.123');
is $v, 12, 'pack_field MONEY(.12)';
$v = unpack "l$LE" => $s->pack_field( test => money => '0');
is $v, 0, 'pack_field MONEY(0)';
$v = unpack "l$LE" => $s->pack_field( test => money => '12345.21');
is $v, 1234521, 'pack_field MONEY(12345.21)';
$v = unpack "l$LE" => $s->pack_field( test => money => '12345.2');
is $v, 1234520, 'pack_field MONEY(12345.20)';
$v = unpack "l$LE" => $s->pack_field( test => money => '-12345.21');
is $v, -1234521, 'pack_field MONEY(-12345.21)';



$v = $s->unpack_field( test => a => pack "L$LE" => 14);
is $v, 14, 'unpack_field NUM';
$v = $s->unpack_field( test => int => pack "l$LE" => -14);
is $v, -14, 'unpack_field INT';
$v = $s->unpack_field( test => 0 => pack "L$LE" => 14);
is $v, 14, 'unpack_field NUM';
$v = $s->unpack_field( 0 => 0 => pack "L$LE" => 14);
is $v, 14, 'unpack_field NUM';
$v = $s->unpack_field( 0 => 'abcd' => 'test');
is $v, 'test', 'unpack_field STR';
$v = $s->unpack_field( 0 => 'abcd' => 'привет');
is $v, encode(utf8 => 'привет'), 'unpack_field STR';
$v = $s->unpack_field( 0 => 'd' => 'привет');
is $v, 'привет', 'unpack_field STR';

$v = $s->unpack_field( test => money => pack "l$LE" => 12345);
is $v, 123.45, 'unpack_field MONEY(123.45)';
$v = $s->unpack_field( test => money => pack "l$LE" => 0);
is $v, '0.00', 'unpack_field MONEY(0)';
$v = $s->unpack_field( test => money => pack "l$LE" => -1234);
is $v, '-12.34', 'unpack_field MONEY(-12.34)';
$v = $s->unpack_field( test => money => pack "l$LE" => 4);
is $v, '0.04', 'unpack_field MONEY(0.04)';


my $tt = [0, 1, 2, 'медвед', 10, 'test'];
my $t = $s->pack_tuple(test => $tt);
isa_ok $t => 'ARRAY';
my $ut = $s->unpack_tuple(0 => $t);
isa_ok $ut => 'ARRAY';
cmp_ok join(':', @$tt), 'eq', join(':', @$ut), 'unpacked packed tuple';

is unpack("L$LE", $t->[0]), 0, 'tuple[0]';
is unpack("L$LE", $t->[1]), 1, 'tuple[1]';
is unpack("L$LE", $t->[2]), 2, 'tuple[2]';
is $t->[3], encode(utf8 => 'медвед'), 'tuple[3]';
is unpack("L$LE", $t->[4]),  10, 'tuple[4]';
is $t->[5], 'test', 'tuple[5]';

# indexes
{
    my $w;
    local $SIG{__WARN__} = sub { $w = $_[0] };
    $t = $s->space('test')->pack_keys([1, 2], 'i0');
    like $w => qr{Ambiguous keys list}, 'ambiguous keys warning';
    cmp_ok join(':', @{ $t->[0] }), 'eq',
        join(':', pack("L$LE", 1), pack "L$LE", 2), 'pack_keys';
    undef $w;
    $t = $s->space('test')->pack_keys([[2, 3]], 'i0');
    cmp_ok join(':', @{ $t->[0] }), 'eq',
        join(':', pack("L$LE", 2), pack "L$LE", 3), 'pack_keys';
    is $w, undef, 'there was no ambiguous warning';
}
$t = eval { $s->space('test')->pack_keys([[1, 2, 3]], 'i0'); };
like $@, qr{must have 2}, 'error message';
is $t, undef, 'wrong elements count';

{
    my $w;
    local $SIG{__WARN__} = sub { $w = $_[0] };
    $t = $s->space('test')->pack_keys([2, 3], 0);
    like $w => qr{Ambiguous keys list}, 'ambiguous keys warning';
    cmp_ok join(':', @{ $t->[0] }), 'eq',
        join(':', pack("L$LE", 2), pack "L$LE", 3), 'pack_keys';
    undef $w;
    $t = $s->space('test')->pack_keys([[2, 3]], 0);
    cmp_ok join(':', @{ $t->[0] }), 'eq',
        join(':', pack("L$LE", 2), pack "L$LE", 3), 'pack_keys';
    is $w, undef, 'there was no ambiguous warning';
}
$t = eval { $s->space('test')->pack_keys([[1,2,3]], 0); };
like $@, qr{must have 2}, 'error message';
is $t, undef, 'wrong elements count';

$t = $s->space('test')->pack_keys(4, 'i2');
is unpack("L$LE", $t->[0][0]), 4, 'pack_keys';
$t = $s->space('test')->pack_keys([5], 'i2');
is unpack("L$LE", $t->[0][0]), 5, 'pack_keys';
$t = $s->space('test')->pack_keys([[6]], 'i2');
is unpack("L$LE", $t->[0][0]), 6, 'pack_keys';
$t = $s->space('test')->pack_keys([7,8,9], 'i2');
is unpack("L$LE", $t->[0][0]), 7, 'pack_keys';
is unpack("L$LE", $t->[1][0]), 8, 'pack_keys';
is unpack("L$LE", $t->[2][0]), 9, 'pack_keys';
$t = eval { $s->space('test')->pack_keys([[7,8,9]], 'i2') };
like $@, qr{must have 1}, 'error message';




# pack_operation
my $op = $s->space('test')->pack_operation([d => 'delete']);
is $op->[0], 3, '* operation field';
is $op->[1], 'delete', 'operation name';

for (qw(insert add and or xor set)) {
    my $n = int rand 100000;
    $op = $s->space('test')->pack_operation([a123 => $_ => $n]);
    is $op->[0], 4, "operation field: $_";
    is $op->[1], $_, 'operation name';
    is unpack("L$LE", $op->[2]), $n, 'operation argument';
}

$op = $s->space('test')->pack_operation([d => 'substr', 1, 2]);
is $op->[0], 3, 'operation field: substr';
is $op->[1], 'substr', 'operation name';
is $op->[2], 1, 'operation argument 1';
is $op->[3], 2, 'operation argument 2';
is $op->[4], undef, 'operation argument 3';

$op = $s->space('test')->pack_operation([d => 'substr', 231, 232, 'привет']);
is $op->[0], 3, 'operation field: substr';
is $op->[1], 'substr', 'operation name';
is $op->[2], 231, 'operation argument 1';
is $op->[3], 232, 'operation argument 2';
is $op->[4], 'привет', 'operation argument 3';

$op = $s->space('test')->pack_operations([ d => set => 'тест']);
is $op->[0][0], 3, "operation field: set";
is $op->[0][1], 'set', 'operation name';
is decode(utf8 => $op->[0][2]), 'тест', 'operation argument';
$op = $s->space('test')->pack_operations([
    [ d => set => 'тест'], [1 => insert => 500]
]);
is $op->[0][0], 3, "operation field: set";
is $op->[0][1], 'set', 'operation name';
is decode(utf8 => $op->[0][2]), 'тест', 'operation argument';

is $op->[1][0], 1, "operation field: set";
is $op->[1][1], 'insert', 'operation name';
is unpack("L$LE", $op->[1][2]), 500, 'operation argument';


$op = $s->pack_field(json => f => undef);
is $op, 'null', 'pack json: undef';
is $s->unpack_field(json => f => $op), undef, 'unpack json: undef';

$op = $s->pack_field(json => f => 123);
is $op, '123', 'pack json: scalar';
is $s->unpack_field(json => f => $op), 123, 'unpack json: scalar';

$op = $s->pack_field(json => f => []);
is $op, '[]', 'pack json: empty array';
isa_ok $s->unpack_field(json => f => $op) => 'ARRAY',
    'unpack json: empty array';

$op = $s->pack_field(json => f => {});
is $op, '{}', 'pack json: empty hash';
isa_ok $s->unpack_field(json => f => $op) => 'HASH',
    'unpack json: empty hash';

$op = $s->pack_field(json => f => [qw(hello world)]);
is decode(utf8 => $op), '["hello","world"]', 'pack json: array';
$op = $s->unpack_field(json => f => $op);
isa_ok $op => 'ARRAY', 'unpack json: array';
is $op->[0], 'hello', 'first element';
is $op->[1], 'world', 'second element';

$op = $s->pack_field(json => f => [qw(привет медвед)]);
is decode(utf8 => $op), '["привет","медвед"]', 'pack json: array';
$op = $s->unpack_field(json => f => $op);
isa_ok $op => 'ARRAY', 'unpack json: array';
is $op->[0], 'привет', 'first utf8 element';
is $op->[1], 'медвед', 'second utf8 element';

$op = $s->pack_field(json => f => {qw(hello world)});
is decode(utf8 => $op), '{"hello":"world"}', 'pack json: hash';
$op = $s->unpack_field(json => f => $op);
isa_ok $op => 'HASH', 'unpack json: hash';
is $op->{hello}, 'world', 'key element';

$op = $s->pack_field(json => f => {qw(привет медвед)});
is decode(utf8 => $op), '{"привет":"медвед"}', 'pack json: hash';
$op = $s->unpack_field(json => f => $op);
isa_ok $op => 'HASH', 'unpack json: hash';
is $op->{привет}, 'медвед', 'key utf8 element';
