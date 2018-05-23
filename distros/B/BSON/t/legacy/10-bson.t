#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use Test::Deep;
use Tie::IxHash;
use Math::BigInt;
require re;

use BSON qw/encode decode/;

my $a;
tie( my %h, 'Tie::IxHash' );
tie( my %h1, 'Tie::IxHash' );
tie( my %h2, 'Tie::IxHash' );

sub _dump_bson {
    my $bson = unpack("H*",shift);
    $bson =~ s/(..)/$1 /g;
    return $bson;
}

sub _delta_ok {
    my ($lhs, $rhs, $label) = @_;;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( abs($lhs - $rhs) < 1e-6, $label );
}

# Int32
subtest int32 => sub {
    plan tests => 2;
    %h = ( a => 1, b => 2147483647, c => -2147483648 );
    my $bson = encode( \%h );
    is_deeply(
        [ unpack "C*", $bson ],
        [
            26,  0,   0,   0,   16, 97, 0, 1, 0, 0, 0,   16, 98, 0,
            255, 255, 255, 127, 16, 99, 0, 0, 0, 0, 128, 0
        ],
        'Int32 encode'
    );
    is_deeply( decode($bson), \%h, 'Int32 decode' );
};

# Int64
subtest int64 => sub {
    %h = (
        a => Math::BigInt->new('2147483648'),
        b => Math::BigInt->new('9223372036854775807'),
        c => Math::BigInt->new('-9223372036854775808')
    );
    my $bson = encode( \%h );

    cmp_deeply(
        [ unpack "C*", $bson ],
        [
            38,  0,   0,   0,
            18,  97,  0,   0,   0,   0,   128, 0,   0,   0,   0,
            18,  98,  0,   255, 255, 255, 255, 255, 255, 255, 127,
            18,  99,  0,   0,   0,   0,   0,   0,   0,   0,   128,
            0
        ],
        'Int64 encode'
    );

    # is_deeply fails to compare int64 properly
    my $decoded = decode($bson);
    for my $k ( qw/a b c/ ) {
        is( $decoded->{$k}, $h{$k}, "key $k" );
    }
};

# Mixed ints
subtest mix_ints => sub {
    %h = ( a => Math::BigInt->new('2147483648'), b => 1, c => -20 );
    my $bson = encode( \%h );

    # is_deeply fails to compare int64 properly
    cmp_deeply(
        [ unpack "C*", $bson ],
        [
            30,  0, 0,  0,  18, 97,  0,   0,   0,   0,
            128, 0, 0,  0,  0,  16,  98,  0,   1,   0,
            0,   0, 16, 99, 0,  236, 255, 255, 255, 0
        ],
        'Mixints encode'
    );

    # is_deeply fails to compare int64 properly
    my $decoded = decode($bson);
    for my $k ( qw/a b c/ ) {
        is( $decoded->{$k}, $h{$k}, "key $k" );
    }
};

subtest boolean => sub {
    plan tests => 6;

    # Boolean true
    %h = ( a => BSON::Bool->true );
    my $bson = encode( \%h );
    is_deeply(
        [ unpack "C*", $bson ],
        [ 9, 0, 0, 0, 8, 97, 0, 1, 0 ],
        'True encode'
    );
    is_deeply( decode($bson), \%h, 'True decode' );

    # Boolean false
    %h = ( a => BSON::Bool->false );
    $bson = encode( \%h );
    is_deeply(
        [ unpack "C*", $bson ],
        [ 9, 0, 0, 0, 8, 97, 0, 0, 0 ],
        'False encode'
    );
    is_deeply( decode($bson), \%h, 'False decode' );

    # Boolean mixed
    %h = ( a => BSON::Bool->true, b => BSON::Bool->false );
    $bson = encode( \%h );
    is_deeply(
        [ unpack "C*", $bson ],
        [ 13, 0, 0, 0, 8, 97, 0, 1, 8, 98, 0, 0, 0 ],
        'mixed encode'
    );
    is_deeply( decode($bson), \%h, 'Mixed decode' );
};

# Double
subtest double => sub {
    plan tests => 4;
    %h = ( a => 0.12345, b => -0.1234, c => 123456.789 );
    my $bson = encode( \%h );
    is_deeply(
        [ unpack "C*", $bson ],
        [
            38,  0,   0,   0,   1,   97,  0,  124, 242, 176,
            80,  107, 154, 191, 63,  1,   98, 0,   243, 142,
            83,  116, 36,  151, 191, 191, 1,  99,  0,   201,
            118, 190, 159, 12,  36,  254, 64, 0
        ],
        'Double encode'
    );

    my $hash = decode( $bson );
    for my $k ( sort keys %$hash ) {
        _delta_ok( $hash->{$k}, $h{$k}, "Double decode $h{$k}" );
    }
};

# String
subtest string => sub {
    plan tests => 5;
    %h = ( a => 'bar', b => 'foo' );
    my $bson = encode( \%h );
    is_deeply(
        [ unpack "C*", $bson ],
        [
            27, 0, 0,  0, 2, 97, 0, 4, 0,   0,   0,   98, 97, 114,
            0,  2, 98, 0, 4, 0,  0, 0, 102, 111, 111, 0,  0
        ],
        'String encode'
    );

    my $hash = decode( $bson );
    is_deeply( $hash, \%h, 'String decode' );

    # String object
    %h = (
        a => BSON::String->new(123456),
        b => BSON::String->new(-11.99)
    );
    $bson = encode( \%h );
    is_deeply(
        [ unpack "C*", $bson ],
        [
            33, 0,  0,  0,  2,  97, 0,  7,  0, 0, 0, 49,
            50, 51, 52, 53, 54, 0,  2,  98, 0, 7, 0, 0,
            0,  45, 49, 49, 46, 57, 57, 0,  0
        ],
        'String object encode'
    );

    $hash = decode( $bson );
    is( $hash->{a}, 123456, 'String object decode' );
    is( $hash->{b}, -11.99, 'String object decode 2' );
};

# Array
subtest array => sub {
    plan tests => 2;
    %h = ( a => [ 1, 2, 3, 'a', 'b', 'c' ] );
    my $bson = encode(\%h);
    is_deeply(
        [ unpack "C*", $bson ],
        [
            61, 0,  0,  0,  4, 97, 0, 53, 0, 0,  0,  16, 48, 0, 1, 0,
            0,  0,  16, 49, 0, 2,  0, 0,  0, 16, 50, 0,  3,  0, 0, 0,
            2,  51, 0,  2,  0, 0,  0, 97, 0, 2,  52, 0,  2,  0, 0, 0,
            98, 0,  2,  53, 0, 2,  0, 0,  0, 99, 0,  0,  0
        ],
        'Array encode'
    );
    is_deeply( decode($bson), \%h, 'Array decode' );
};

# Null
subtest null => sub {
    plan tests => 2;
    my $h = { a => undef };
    my $bson = encode( $h );
    is_deeply(
        [ unpack "C*", $bson ],
        [ 8, 0, 0, 0, 10, 97, 0, 0 ],
        'Null encode'
    );

    is_deeply( decode($bson), $h, 'Null decode' );
};

# Hash
subtest hash => sub {
    plan tests => 4;
    tie( %h2, 'Tie::IxHash', b => 1, c => 'bar' );
    %h = ( a => \%h2 );
    my $bson = encode( \%h );
    is_deeply(
        [ unpack "C*", $bson ],
        [
            31, 0,  0,  0,   3, 97, 0, 23, 0, 0, 0, 16,
            98, 0,  1,  0,   0, 0,  2, 99, 0, 4, 0, 0,
            0,  98, 97, 114, 0, 0,  0
        ],
        'Hash 1 encode'
    );
    is_deeply( decode($bson), \%h, 'Hash 1 decode' );

    # Hash 2
    tie( %h1, 'Tie::IxHash', a => [ 1, 2, 3 ], b => 'foo' );
    tie( %h2, 'Tie::IxHash', a => \%h1, b => [ 1, 2, 3 ] );
    %h = ( a => \%h2, b => \%h1 );
    $bson = encode( \%h );
    is_deeply(
        [ unpack "C*", $bson ],
        [
            138, 0,  0, 0,  3,  97, 0,   82,  0,   0, 0,  3,  97,  0,
            45,  0,  0, 0,  4,  97, 0,   26,  0,   0, 0,  16, 48,  0,
            1,   0,  0, 0,  16, 49, 0,   2,   0,   0, 0,  16, 50,  0,
            3,   0,  0, 0,  0,  2,  98,  0,   4,   0, 0,  0,  102, 111,
            111, 0,  0, 4,  98, 0,  26,  0,   0,   0, 16, 48, 0,   1,
            0,   0,  0, 16, 49, 0,  2,   0,   0,   0, 16, 50, 0,   3,
            0,   0,  0, 0,  0,  3,  98,  0,   45,  0, 0,  0,  4,   97,
            0,   26, 0, 0,  0,  16, 48,  0,   1,   0, 0,  0,  16,  49,
            0,   2,  0, 0,  0,  16, 50,  0,   3,   0, 0,  0,  0,   2,
            98,  0,  4, 0,  0,  0,  102, 111, 111, 0, 0,  0
        ],
        'Hash 2 encode'
    );
    is_deeply( decode($bson), \%h, 'Hash 2 decode' );
};

# Regex
subtest regex => sub {
    plan tests => 9;

    my @sp = BSON::PP::_split_re(qr/\w/i);
    is_deeply(\@sp, ['\w', 'i']);

    my $re1_str = q!"(?:[^"\\\]++|\\\.)*+"!;
    my @re1_bytes = (
        34,  40, 63, 58, 91, 94, 34, 92, 92, 93, 43, 43,
        124, 92, 92, 46, 41, 42, 43, 34, 0,  0
    );
    my $re2_str = q!"(?>(?:(?>[^"\\\]+)|\\\.)*)"!;
    my @re2_bytes = (
        34, 40, 63, 62, 40, 63, 58,  40, 63, 62, 91, 94,
        34, 92, 92, 93, 43, 41, 124, 92, 92, 46, 41, 42,
        41, 34, 0,  0
    );

    my @expected_bytes;
    if ($] >= 5.01) {
        # first regex works only on perl >= 5.10
        %h = eval { ( a => qr/$re1_str/, b => qr/$re2_str/ ) };
        die "Can't eval regexes: $@" if $@;
        @expected_bytes = (
            61, 0,  0, 0,
            11, 97, 0, @re1_bytes,
            11, 98, 0, @re2_bytes,
            0
        );
    } else {
        %h = (a => qr/$re2_str/, b => qr/$re2_str/);
        @expected_bytes = (
            67, 0,  0, 0,
            11, 97, 0, @re2_bytes,
            11, 98, 0, @re2_bytes,
            0
        );
    }

    my $bson = encode( \%h );
    is_deeply(
        [ unpack "C*", $bson ],
        \@expected_bytes,
        'Regex encode'
    );
    my $hash = decode( $bson );
    is(ref $hash->{a}, 'BSON::Regex');
    is(ref $hash->{b}, 'BSON::Regex');

    SKIP: {
        skip "Comparing regexes is fragile before 5.10", 1 if $] lt 5.010;
        $hash->{$_} = $hash->{$_}->try_compile for qw/a b/;
        for (qw/a b/) {
            is_deeply(
                [ re::regexp_pattern( $hash->{$_} ) ],
                [ re::regexp_pattern( $h{$_} ) ],
                "Regex decode of key $_",
            );
        }
    }

    #<<<
    %h = ( a => qr/(?:(?:[+-]?)(?:(?=[0123456789]|[.])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))/i );
    #>>>
    $bson = encode(\%h);
    is_deeply(
        [ unpack "C*", $bson ],
        [
            139, 0,  0,  0,  11,  97,  0,  40,  63,  58, 40, 63,
            58,  91,  43, 45,  93,  63, 41, 40,
            63,  58, 40, 63, 61,  91,  48, 49,  50,  51, 52, 53,
            54,  55, 56, 57, 93,  124, 91, 46,  93,  41, 40, 63,
            58,  91, 48, 49, 50,  51,  52, 53,  54,  55, 56, 57,
            93,  42, 41, 40, 63,  58,  40, 63,  58,  91, 46, 93,
            41,  40, 63, 58, 91,  48,  49, 50,  51,  52, 53, 54,
            55,  56, 57, 93, 123, 48,  44, 125, 41,  41, 63, 41,
            40,  63, 58, 40, 63,  58,  91, 69,  93,  41, 40, 63,
            58,  40, 63, 58, 91,  43,  45, 93,  63,  41, 40, 63,
            58,  91, 48, 49, 50,  51,  52, 53,  54,  55, 56, 57,
            93,  43, 41, 41, 124, 41,  41, 0,   105, 0,  0
        ],
        'real num regex'
    );
    $hash = decode( $bson );
    is(ref $hash->{a}, 'BSON::Regex');
    SKIP: {
        skip "Comparing regexes is fragile before 5.10", 2 if $] lt 5.010;
        $hash->{a} = $hash->{a}->try_compile;
        # after try_compile, "i" flags are put into the regex, so we must
        # do the same with the original
        my ($p,$f) = re::regexp_pattern($h{a});
        $h{a} = qr{(?$f:$p)};
        is_deeply(
            [ re::regexp_pattern( $hash->{a} ) ],
            [ re::regexp_pattern( $h{a} ) ],
            "Regex decode of key a",
        );
    }
};

# Datetime
subtest datetime => sub {
    eval { require DateTime };
    plan skip_all => "Needs DateTime" unless $INC{"DateTime.pm"};
    plan tests => 6;

    my $dt = DateTime->new(
        year      => 1974,
        month     => 10,
        day       => 15,
        hour      => 22,
        minute    => 50,
        second    => 8,
        time_zone => 'UTC'
    );
    my $h = { a => BSON::Time->new( $dt->epoch ) };
    my $bson = encode( $h );
    #<<<
    is_deeply(
        [ unpack "C*", $bson ],
        [ 16, 0, 0, 0, 9, 97, 0, 0, 149, 210, 46, 35, 0, 0, 0, 0 ],
        'encode 1974'
    );
    #>>>
    is_deeply( decode($bson), $h, 'decode 1974' );

    $dt = DateTime->new(
        year      => 1964,
        month     => 10,
        day       => 15,
        hour      => 22,
        minute    => 50,
        second    => 8,
        time_zone => 'UTC'
    );
    $h = { a => BSON::Time->new( $dt->epoch ) };
    $bson = encode( $h );
    #<<<
    is_deeply(
        [ unpack "C*", $bson ],
        [16, 0, 0, 0, 9, 97, 0, 0, 37, 154, 183, 217, 255, 255, 255, 0],
        'encode 1964'
    );
    #>>>
    is_deeply( decode($bson), $h, 'decode 1964' );

    $dt = DateTime->new(
        year      => 2028,
        month     => 10,
        day       => 15,
        hour      => 22,
        minute    => 50,
        second    => 8,
        time_zone => 'UTC'
    );
    $h = { a => BSON::Time->new( $dt->epoch ) };
    $bson = encode( $h );
    #<<<
    is_deeply(
        [ unpack "C*", $bson ],
        [16, 0, 0, 0, 9, 97, 0, 0, 229, 74, 246, 175, 1, 0, 0, 0],
        'encode 2028'
    );
    #>>>
    is_deeply( decode($bson), $h, 'decode 2028' );
};

subtest min_max_key => sub {
    plan tests => 4;
    my $bson = encode( { a => BSON::MinKey->new } );
    #<<<
    is_deeply(
        [ unpack "C*", $bson ],
        [8, 0, 0, 0, 255, 97, 0, 0],
        'MinKey encode'
    );
    #>>>
    isa_ok( decode($bson)->{a}, 'BSON::MinKey', 'MinKey decode' );

    $bson = encode( { a => BSON::MaxKey->new } );
    #<<<
    is_deeply(
        [ unpack "C*", $bson ],
        [8, 0, 0, 0, 127, 97, 0, 0],
        'MaxKey'
    );
    #>>>
    isa_ok( decode($bson)->{a}, 'BSON::MaxKey', 'MaxKey decode' );
};


subtest binary => sub {
    plan tests => 8;
    my $bin = BSON::Binary->new( [ 1, 2, 3, 4, 5 ] );
    my $bson = encode( { a => $bin } );
    #<<<
    is_deeply(
        [ unpack "C*", $bson ],
        [18, 0, 0, 0, 5, 97, 0, 5, 0, 0, 0, 0, 1, 2, 3, 4, 5, 0],
        'Binary 1 encode'
    ) or diag _dump_bson($bson);
    #>>>
    my $hash = decode($bson);
    isa_ok( $hash->{a}, 'BSON::Bytes' );
    is( $hash->{a}->type, $bin->type, 'compare type' );
    is_deeply( $hash->{a}->data, pack("C*",@{$bin->data}), 'compare data' );

    $bin = BSON::Binary->new( "5366a937375901366effb80511b39919", 5 );
    $bson = encode( { a => $bin } );
    $a = [ unpack "C*", encode( { a => $bin } ) ];
    is_deeply(
        [ unpack "C*", $bson ],
        [
            45, 0,  0,  0,  5,  97,  0,   32,  0,  0,  0,  5,
            53, 51, 54, 54, 97, 57,  51,  55,  51, 55, 53, 57,
            48, 49, 51, 54, 54, 101, 102, 102, 98, 56, 48, 53,
            49, 49, 98, 51, 57, 57,  49,  57,  0
        ],
        'Binary 2 encode'
    );
    $hash = decode($bson);
    isa_ok( $hash->{a}, 'BSON::Bytes' );
    is( $hash->{a}->type, $bin->type, 'compare type' );
    is_deeply( $hash->{a}->data, pack("C*",@{$bin->data}), 'compare data' );
};

# ObjectId
subtest objectid => sub {
    plan tests => 4;
    my $oid = BSON::ObjectId->new('4e2766e6e1b8325d02000028');
    my $h = { _id => $oid };
    my $bson = encode( $h );
    is_deeply(
        [ unpack "C*", $bson ],
        [
            22,  0,   0,   0,  7,  95, 105, 100, 0,  78, 39, 102,
            230, 225, 184, 50, 93, 2,  0,   0,   40, 0
        ],
        'ObjectId encode'
    );

    my $hash = decode($bson);
    isa_ok( $hash->{_id}, 'BSON::OID', 'OID created' );
    is_deeply( $hash, $h, 'OID decode' );
    is("$h->{_id}", "$hash->{_id}", 'Match');
};


subtest code => sub {
    plan tests => 8;
    my $code = BSON::Code->new("function a(b,c){return b>c?c:b}", {});
    my $bson = encode( { a => $code } );
    is_deeply(
        [ unpack "C*", $bson ],
        [
            53,  0,  0,  0,   15,  97,  0,   45,  0,   0,   0,   32,
            0,   0,  0,  102, 117, 110, 99,  116, 105, 111, 110, 32,
            97,  40, 98, 44,  99,  41,  123, 114, 101, 116, 117, 114,
            110, 32, 98, 62,  99,  63,  99,  58,  98,  125, 0,   5,
            0,   0,  0,  0,   0
        ],
        'Code with empty scope encode'
    );

    my $hash = decode( $bson );
    isa_ok( $hash->{a}, 'BSON::Code' );
    is( $hash->{a}->code, $code->code );
    is_deeply( $hash->{a}->scope, $code->scope );

    %h = ( a => 'foo', b => 'bar', c => 45 );
    $code = BSON::Code->new("function a(b,c){alert('OMG!')}", \%h);
    $bson = encode( { a => $code } );
    is_deeply(
        [ unpack "C*", $bson ],
        [
            81, 0,  0,  0,   15,  97,  0,   73,  0,   0,   0,   31,
            0,  0,  0,  102, 117, 110, 99,  116, 105, 111, 110, 32,
            97, 40, 98, 44,  99,  41,  123, 97,  108, 101, 114, 116,
            40, 39, 79, 77,  71,  33,  39,  41,  125, 0,   34,  0,
            0,  0,  2,  97,  0,   4,   0,   0,   0,   102, 111, 111,
            0,  2,  98, 0,   4,   0,   0,   0,   98,  97,  114, 0,
            16, 99, 0,  45,  0,   0,   0,   0,   0
        ],
        'Code'
    );

    $hash = decode( $bson );
    isa_ok( $hash->{a}, 'BSON::Code' );
    is( $hash->{a}->code, $code->code );
    is_deeply( $hash->{a}->scope, $code->scope );
};

subtest timestamp => sub {
    plan tests => 4;
    my $ts = BSON::Timestamp->new( 0x1234, 0x5678 );
    my $bson = encode( { a => $ts } );
    is_deeply(
        [ unpack "C*", $bson ],
        [ 16, 0, 0, 0, 17, 97, 0, 120, 86, 0, 0, 52, 18, 0, 0, 0 ],
        'timestamp encode'
    );

    my $hash = decode( $bson );
    isa_ok( $hash->{a}, 'BSON::Timestamp' );
    is( $hash->{a}->increment, $ts->increment, 'timestamp increment' );
    is( $hash->{a}->seconds, $ts->seconds, 'timestamp seconds' );
};

subtest options => sub {
    plan tests => 2;

    # ixhash
    my $hash = { a => 1, b => 2 };
    my $bson = encode($hash);
    my $h1   = decode($bson);
    my $h2   = decode( $bson, ixhash => 1 );
    is( ref tied %$h1, '',            'regular hash' );
    is( ref tied %$h2, 'Tie::IxHash', 'Tie::IxHash' );
};
