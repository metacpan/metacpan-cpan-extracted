#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 108;
use Encode qw(decode encode);

use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Msgpuck';
    use_ok 'DR::Msgpuck::Str';
    use_ok 'DR::Msgpuck::Num';
}

for (+note 'null') {
    for (my $o = DR::Msgpuck::msgpack(undef)) {
        ok defined($o) => 'msgpack undef';
        is length($o), 1, 'length';
        is $o => pack('C', 0xC0), 'body';
    }
}
for (+note 'bool') {
    for (my $o = DR::Msgpuck::msgpack(DR::Msgpuck::True->new)) {
        ok defined($o) => 'msgpack true';
        is length($o), 1, 'length';
        is $o => pack('C', 0xC3), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(DR::Msgpuck::False->new)) {
        ok defined($o) => 'msgpack false';
        is length($o), 1, 'length';
        is $o => pack('C', 0xC2), 'body';
    }
}

for (+note 'str') {
    for (my $o = DR::Msgpuck::msgpack("abc")) {
        ok defined($o) => 'msgpack str';
        is length($o) => 4, 'length';
        is $o => pack('C a3', (0xA0 | 3), 'abc'), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack("")) {
        ok defined($o) => 'msgpack str';
        is length($o) => 1, 'length';
        is $o => pack('C', (0xA0 | 0)), 'body';
    }
}

for (+note 'numbers') {
    for (my $o = DR::Msgpuck::msgpack(3.2)) {
        ok defined($o) => 'msgpack double';
        is length($o) => 9, 'length';
        is $o => pack('Cd>', 0xcb, 3.2), 'body';
    }
}

for (+note 'integers') {
    for (my $o = DR::Msgpuck::msgpack(0)) {
        ok defined($o) => 'msgpack unsigned char';
        is length($o) => 1, 'length';
        is $o => pack('C', 0), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(1)) {
        ok defined($o) => 'msgpack unsigned char';
        is length($o) => 1, 'length';
        is $o => pack('C', 1), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(0x7F)) {
        ok defined($o) => 'msgpack unsigned char';
        is length($o) => 1, 'length';
        is $o => pack('C', 0x7F), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(0x7F + 1)) {
        ok defined($o) => 'msgpack unsigned char';
        is length($o) => 2, 'length';
        is $o => pack('CC', 0xCC, 0x7F + 1), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(0xFF)) {
        ok defined($o) => 'msgpack unsigned char';
        is length($o) => 2, 'length';
        is $o => pack('CC', 0xCC, 0xFF), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(0xFF + 1)) {
        ok defined($o) => 'msgpack unsigned short';
        is length($o) => 3, 'length';
        is $o => pack('Cs>', 0xCD, 0xFF + 1), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(0xFFFF)) {
        ok defined($o) => 'msgpack unsigned short';
        is length($o) => 3, 'length';
        is $o => pack('Cs>', 0xCD, 0xFFFF), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(0xFFFF + 1)) {
        ok defined($o) => 'msgpack unsigned int';
        is length($o) => 5, 'length';
        is $o => pack('CI>', 0xCE, 0xFFFF + 1), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(0xFFFF_FFFF)) {
        ok defined($o) => 'msgpack unsigned int';
        is length($o) => 5, 'length';
        is $o => pack('CI>', 0xCE, 0xFFFF_FFFF), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(0xFFFF_FFFF + 1)) {
        ok defined($o) => 'msgpack unsigned long long';
        is length($o) => 9, 'length';
        is $o => pack('CQ>', 0xCF, 0xFFFF_FFFF + 1), 'body';
    }
    
    for (my $o = DR::Msgpuck::msgpack(-1)) {
        ok defined($o) => 'msgpack unsigned char';
        is length($o) => 1, 'length';
        is $o => pack('C', 0xE0 | ((-1) &0x7F) ), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(-32)) {
        ok defined($o) => 'msgpack unsigned char';
        is length($o) => 1, 'length';
        is $o => pack('C', 0xE0 | ((-32) &0x7F) ), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(-33)) {
        ok defined($o) => 'msgpack signed char';
        is length($o) => 2, 'length';
        is $o => pack('Cc', 0xD0, -33), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(-128)) {
        ok defined($o) => 'msgpack signed char';
        is length($o) => 2, 'length';
        is $o => pack('Cc', 0xD0, -128), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(-129)) {
        ok defined($o) => 'msgpack signed char';
        is length($o) => 3, 'length';
        is $o => pack('Cs>', 0xD1, -129), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(-32768)) {
        ok defined($o) => 'msgpack signed short';
        is length($o) => 3, 'length';
        is $o => pack('Cs>', 0xD1, -32768), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(-32769)) {
        ok defined($o) => 'msgpack signed int';
        is length($o) => 5, 'length';
        is $o => pack('Cl>', 0xD2, -32769), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack(-3123456789)) {
        ok defined($o) => 'msgpack signed long long';
        is length($o) => 9, 'length';
        is $o => pack('Cq>', 0xD3, -3123456789), 'body';
    }
}

for (+note 'arrays') {
    for (my $o = DR::Msgpuck::msgpack([])) {
        ok defined($o) => 'msgpack empty array';
        is length($o) => 1, 'length';
        is $o => pack('C', 0x90), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack([70])) {
        ok defined($o) => 'msgpack one item array';
        is length($o) => 2, 'length';
        is $o => pack('CC', 0x91, 70), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack([(1)x15])) {
        ok defined($o) => 'msgpack array_len=15';
        is length($o) => 15 + 1, 'length';
        is $o => pack('CC*', 0x90 | 15, (1)x15), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack([(3)x16])) {
        ok defined($o) => 'msgpack array_len=16';
        is length($o) => 16 + 1 + 2, 'length';
        is $o => pack('Cs>C*', 0xDC,  16, (3)x16), 'body';
    }
}

for (+note 'hashes') {
    for (my $o = DR::Msgpuck::msgpack({})) {
        ok defined($o) => 'msgpack empty hash';
        is length($o) => 1, 'length';
        is $o => pack('C', 0x80), 'body';
    }
    for (my $o = DR::Msgpuck::msgpack({5 => 5})) {
        ok defined($o) => 'msgpack hash_len=1';
        is length($o) => 3, 'length';
        is $o => pack('CC*', 0x81, 5, 5), 'body';
    }
}


for (+note 'forced to str') {
    
    for my $s ('', 'hello', 'hello' x 10, 'hello' x 1000, 'hello' x 65000) {
        is DR::Msgpuck::msgpack($s), DR::Msgpuck::Str->new($s)->TO_MSGPACK,
            'msgpack strlen=' . length $s;
    }

    for my $s ('', 'привет', 'привет' x 10, 'привет' x 1000, 'привет' x 65000) {
        is DR::Msgpuck::msgpack($s), DR::Msgpuck::Str->new($s)->TO_MSGPACK,
            'msgpack utf8 strlen=' . length $s;
    }
}

for (+note 'forced to num') {
    for my $s ('0', '1', '2', '2.56', '-1.28') {
        is DR::Msgpuck::msgpack($s), DR::Msgpuck::Num->new($s)->TO_MSGPACK,
            'msgpack ' . $s;
    }
}

