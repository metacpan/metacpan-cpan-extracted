#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 84;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::Msgpack';
    use_ok 'DR::Tnt::Dumper';
}


is msgpack(undef), pack('C', 0xC0), 'undef';
for (0, 0x01, 0x7E, 0x7F) {
    is msgpack($_), pack('C', 0x00 | $_), "pack $_";
}

for (0x7F+1, 0xFE, 0xFF) {
    is msgpack($_), pack('CC', 0xCC, $_), "pack $_";
}
for (0xFF+1, 0xFFFE, 0xFFFF) {
    is msgpack($_), pack('Cs>', 0xCD, $_), "pack $_";
}
for (0xFFFF+1, 0xFFFF_FFFE, 0xFFFF_FFFF) {
    is msgpack($_), pack('CL>', 0xCE, $_), "pack $_";
}
for (0xFFFF_FFFF + 1, 0xFFFF_FFFF + 2, 0xFFFF_FFFF * 25) {
    is msgpack($_), pack('CQ>', 0xCF, $_), "pack $_";
}
for (-1, -0x1F, -0x20) {
    is msgpack($_), pack('c', $_), "pack negative $_";
}
for (-0x21, -0x7F, -0x7F-1) {
    is msgpack($_), pack('Cc', 0xD0,  $_), "pack negative $_";
}
for (-0x7F-2, -0x7FFF, -0x7FFF-1) {
    is msgpack($_), pack('Cs>', 0xD1,  $_), "pack negative $_";
}
for (-0x7FFF-2, -0x7FFF_FFFF, -0x7FFF_FFFF-1) {
    is msgpack($_), pack('Cl>', 0xD2,  $_), "pack negative $_";
}
for (-0x7FFF_FFFF-2, -0x7FFF_FFFF - 3, -0x7FFF_FFFF*25) {
    is msgpack($_), pack('Cq>', 0xD3,  $_), "pack negative $_";
}

for (1.1, 2.3, -7.4) {
    is msgpack($_), pack('Cd>', 0xCB, $_), "pack double $_";
}

for ('', 'hello', 'x' x 0x1E, 'x'x 0x1F) {
    is msgpack($_), pack('Ca*', (0xA0|length $_), $_), "pack string len " . length $_;
    is length(msgpack $_), 1 + length $_, "msgpack's length";
}

for ('x' x 0x20, 'x' x 0x21, 'x' x 0xFE, 'x' x 0xFF) {
    is msgpack($_), pack('CCa*', 0xD9, length $_, $_), "pack string len " . length $_;
    is length(msgpack $_), 2 + length $_, "msgpack's length";
}
for ('x' x 0x100, 'x' x 0x101, 'x' x 0xFFFE, 'x' x 0xFFFF) {
    is msgpack($_), pack('CS>a*', 0xDA, length $_, $_), "pack string len " . length $_;
    is length(msgpack $_), 3 + length $_, "msgpack's length";
}
for ('x' x 0x1_0000, 'x' x 0x1_0001, 'x' x 0x1_0002) {
    is msgpack($_), pack('CL>a*', 0xDB, length $_, $_), "pack string len " . length $_;
    is length(msgpack $_), 5 + length $_, "msgpack's length";
}

for my $s ('привет', 'медвед') {
    my $u = $s;
    utf8::encode $u;
    is msgpack($s), pack('Ca*', (0xA0 | length $u), $u), "pack utf8 string '$s'";
    is length(msgpack $s), 1 + length $u, "msgpack's length";
}


for ([], [0], [0,0], [(0) x 0xF]) {
    my $len = @$_;
    is msgpack($_), pack("CC$len", 0x90|$len, (0)x$len), "fixarray $len";
}
for ([(0) x 0x10], [(0) x 0xFFFF]) {
    my $len = @$_;
    is msgpack($_), pack("CS>C$len", 0xDC, $len, (0)x$len), "array16 $len";
}
for ([(1) x 0x1000F]) {
    my $len = @$_;
    is msgpack($_), pack("CL>C$len", 0xDD, $len, (1)x$len), "array32 $len";
}

for my $h ({}, { map { ($_ => $_) } 1 .. 0xF }) {
    my $len = keys %$h;

    is  msgpack($h),
        pack("CC@{[ 2 * $len ]}",
            0x80|$len,
            map { ($_, $_) } keys %$h
        ),
        "Fix hash $len";
}

for my $h ({ map { ($_ => $_) } 1 .. 0x1F }) {
    my $len = keys %$h;

    is  msgpack($h),
        pack("CS>C@{[ 2 * $len ]}",
            0xDE,
            $len,
            map { ($_, $_) } keys %$h
        ),
        "hash16 $len";
}


subtest 'JSON::PP::Boolean' => sub {
    return plan skip_all => 'JSON::PP::Boolean is not installed'
        unless eval "require JSON::PP; 1" ;
    plan tests => 2;
    is msgpack(JSON::PP::true()), pack('C', 0xC3), 'true';
    is msgpack(JSON::PP::false()), pack('C', 0xC2), 'false';
};

subtest 'JSON::XS' => sub {
    return plan skip_all => 'JSON::XS is not installed'
        unless eval "require JSON::XS; 1" ;
    plan tests => 2;
    is msgpack(JSON::XS::true()), pack('C', 0xC3), 'true';
    is msgpack(JSON::XS::false()), pack('C', 0xC2), 'false';
};
subtest 'Types::Serialiser' => sub {
    return plan skip_all => 'Types::Serialiser is not installed'
        unless eval "require Types::Serialiser; 1" ;
    plan tests => 2;
    is msgpack(Types::Serialiser::true()), pack('C', 0xC3), 'true';
    is msgpack(Types::Serialiser::false()), pack('C', 0xC2), 'false';
};

