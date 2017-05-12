#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib t/lib);

use Test::More tests    => 62;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::Proto';
    use_ok 'DR::Tnt::Msgpack';
    use_ok 'Data::Dumper';
}

local $Data::Dumper::Indent = 1;
local $Data::Dumper::Terse = 1;
local $Data::Dumper::Useqq = 1;
local $Data::Dumper::Deepcopy = 1;
local $Data::Dumper::Maxdepth = 0;


sub test_substrings($) {
    my ($pkt) = @_;

    my $pass = 1;

    do {
        substr $pkt, -1, 1, '';
        my ($o, $tail) = DR::Tnt::Proto::response $pkt;
        $pass = 0 if defined $o;
    } while length $pkt;;

    ok $pass, 'partial pkt parsing';
}

for my $sync (int rand 1_000_000) {

    my $ping = DR::Tnt::Proto::ping($sync, undef);
    ok $ping, 'PING body';

    my ($o, $tail) = DR::Tnt::Proto::response $ping;
    isa_ok $o => 'HASH';
    is $o->{CODE} => 'PING', 'request code';
    is $o->{SYNC}, $sync, 'request sync';
    is $tail, '', 'empty tail';
    test_substrings $ping;
}

for my $sync (int rand 1_000_000) {
    my $select = DR::Tnt::Proto::select $sync, undef, 123, 345, [ 'a', 'b' ], 10, 20, 'EQ';
    ok $select, 'SELECT body';

    my ($o, $tail) = DR::Tnt::Proto::response $select;
    isa_ok $o => 'HASH';
    is $tail, '', 'empty tail';

    is $o->{CODE}, 'SELECT', 'code';
    is $o->{SPACE_ID}, 123, 'space id';
    is $o->{INDEX_ID}, 345, 'index id';
    is_deeply $o->{KEY}, [ 'a', 'b' ], 'key';
    is $o->{LIMIT}, 10, 'limit';
    is $o->{OFFSET}, 20, 'offset';
    is $o->{ITERATOR}, 'EQ', 'iterator';
    is $o->{SYNC}, $sync, 'sync';

    test_substrings $select;
}

for my $m ('insert', 'replace') {
    for my $sync (int rand 1_000_000) {
        my $pkt;
        for my $mt ("DR::Tnt::Proto::$m") {
            no strict 'refs';
            $pkt = $mt->($sync, undef, 11, [ 'a', 'b', 'c' ]);
        }
        ok $pkt, uc ($m) . ' body';

        my ($o, $tail) = DR::Tnt::Proto::response $pkt;
        isa_ok $o => 'HASH';
        is $tail, '', 'empty tail';

        is $o->{CODE}, uc($m), 'code';
        is $o->{SPACE_ID}, 11, 'space id';
        is_deeply $o->{TUPLE}, [qw(a b c)], 'tuple';
        is $o->{SYNC}, $sync, 'sync';
        test_substrings $pkt;
    }
}

for my $sync (int rand 1_000_000) {
    my $del = DR::Tnt::Proto::del $sync, undef, 123, 'a';
    ok $del, 'DELETE body';
    
    my ($o, $tail) = DR::Tnt::Proto::response $del;
    isa_ok $o => 'HASH';
    is $tail, '', 'empty tail';

    is $o->{CODE}, 'DELETE', 'code';
    is $o->{SYNC}, $sync, 'sync';
    is_deeply $o->{KEY}, [ 'a' ], 'key';
    is $o->{SPACE_ID}, 123, 'space';
    
    test_substrings $del;
}

for my $sync (int rand 1_000_000) {
    my $up = DR::Tnt::Proto::update $sync, undef, 123, 'a', [ [ '=', 23, 22 ] ];
    ok $up => 'UPDATE body';
    
    my ($o, $tail) = DR::Tnt::Proto::response $up;
    isa_ok $o => 'HASH';
    is $tail, '', 'empty tail';

    is $o->{CODE}, 'UPDATE', 'code';
    is $o->{SYNC}, $sync, 'sync';
    is_deeply $o->{KEY}, [ 'a' ], 'key';
    is $o->{SPACE_ID}, 123, 'space';

    is_deeply $o->{TUPLE}, [[qw(= 23 22)]], 'tuple';

    test_substrings $up;
}

for my $sync (int rand 1_000_000) {
    my $up = DR::Tnt::Proto::eval_lua $sync, undef, 'return "Hello"', 1 .. 15;
    ok $up => 'EVAL body';
    
    my ($o, $tail) = DR::Tnt::Proto::response $up;
    isa_ok $o => 'HASH';
    is $tail, '', 'empty tail';

    is $o->{CODE}, 'EVAL', 'code';
    is $o->{SYNC}, $sync, 'sync';
    is_deeply $o->{TUPLE}, [ 1  .. 15 ], 'tuple';
    is $o->{EXPRESSION}, 'return "Hello"', 'EXPRESSION';

    test_substrings $up;
}
