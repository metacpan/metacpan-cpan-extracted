#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Cassandra::Client;
use Cassandra::Client::Protocol qw/:constants pack_int pack_long pack_metadata unpack_metadata/;

# Add some junk into our Perl magic variables
local $"= "junk join string ,";
local $/= "junk slurp";
local $\= "abcdef";

sub check_encdec {
    my ($rowspec, $row, $expected)= @_;
    eval {
        $expected= $row unless defined $expected;

        my $metadata= pack_metadata($rowspec);
        my ($rowmeta)= unpack_metadata($metadata);
        ok($rowmeta) or diag('No rowmeta');

        my $encoded= $rowmeta->encode($row);
        ok(length $encoded) or diag('Encoding failed');
        HACK: { # Turns the encoded parameter list into something our decoders understand
            substr($encoded, 0, 2, '');
            $encoded= pack_int(1).$encoded;
        }
        my $decoded= $rowmeta->decode($encoded, 0);
        is_deeply($decoded->[0], $expected);

        1;
    } or do {
        my $error= $@ || '??';
        ok(0) or diag($error);
    };
}

sub check_simple {
    my ($coltype, $row, $expected)= @_;
    my $meta= { columns => [] };
    my $i= ord('a');
    for my $field (@$row) {
        push @{$meta->{columns}}, [ 'schema', 'table', chr($i++), $coltype ];
    }
    check_encdec($meta, $row, $expected);
}

sub check_enc {
    my ($coltype, $col, $expected)= @_;
    my $meta= {
        columns => [
            [ 'schema', 'table', 'a', $coltype ]
        ]
    };
    eval {
        my $metadata= pack_metadata($meta);
        my ($rowmeta)= unpack_metadata($metadata);

        my $encoded= $rowmeta->encode([ $col ]);
        my $rowcount= unpack('n', substr($encoded, 0, 2, ''));
        ok($rowcount == 1);
        my $col_length= unpack('l>', substr($encoded, 0, 4, ''));
        ok($col_length >= 0);
        is(unpack('H*', $encoded), unpack('H*', $expected));
        1;
    } or do {
        my $error= $@ || "??";
        ok(0) or diag $error;
    };
}

# Custom
check_simple([TYPE_CUSTOM, 'java.lang.String'], [ 'abc', 'def', undef ]);
check_enc([TYPE_CUSTOM, 'java.lang.String'], 'abc', 'abc');

# ASCII
check_simple([TYPE_ASCII], [ 'test', 'abcdef', '', undef, 0 ]);
check_enc([TYPE_ASCII], 'test', 'test');

# Bigint
check_simple([TYPE_BIGINT], [0, 1, -2, 3, -4, 5, "1000000000000", undef]);
check_enc([TYPE_BIGINT], 0, "\0\0\0\0\0\0\0\0");
check_enc([TYPE_BIGINT], "1000000000000", "\0\0\0\xe8\xd4\xa5\x10\0");
check_enc([TYPE_BIGINT], -1, "\xff\xff\xff\xff\xff\xff\xff\xff");

# Blob
check_simple([TYPE_BLOB], [ 'test', undef, chr(rand()%256), '0', '' ]);
check_enc([TYPE_BLOB], "\0\1\2abc", "\0\1\2abc");

# Boolean
check_simple([TYPE_BOOLEAN], [ !0, !1, undef, 1, '' ]);
check_simple([TYPE_BOOLEAN], [ 2, 3, -1, 'a' ],
                             [ !0, !0, !0, !0 ]);
check_enc([TYPE_BOOLEAN], 1, "\1");
check_enc([TYPE_BOOLEAN], 0, "\0");

# Counter
check_simple([TYPE_COUNTER], [ undef, 0, 1, 2, 3, 4 ]);
check_enc([TYPE_COUNTER], 0, "\0\0\0\0\0\0\0\0");
check_enc([TYPE_COUNTER], "1000000000000", "\0\0\0\xe8\xd4\xa5\x10\0");
check_enc([TYPE_COUNTER], -1, "\xff\xff\xff\xff\xff\xff\xff\xff");

# Decimal
check_simple([TYPE_DECIMAL], [ undef, 0, 1, 100, '1e+100', 1E100 ]);
check_simple([TYPE_DECIMAL], [ "10000000000000001.123456789123456789E-1000" ], [ "10000000000000001123456789123456789e-1018" ]);
check_enc([TYPE_DECIMAL], 0, "\0\0\0\0\0");
check_enc([TYPE_DECIMAL], 1, "\0\0\0\0\1");
check_enc([TYPE_DECIMAL], 0.1, "\0\0\0\1\1");

# Double
check_simple([TYPE_DOUBLE], [ 0.5, 2, -3, undef, 0 ]);
check_enc([TYPE_DOUBLE], 0.1, "\x3f\xb9\x99\x99\x99\x99\x99\x9a");

# Float
check_simple([TYPE_FLOAT], [ 0.5, 2, -3, undef, 0 ]);
check_enc([TYPE_FLOAT], 0.1, "\x3d\xcc\xcc\xcd");

# Int
check_simple([TYPE_INT], [ 1, 2, -3, undef, 0 ]);
check_enc([TYPE_INT], 1, "\0\0\0\1");
check_enc([TYPE_INT], -1, "\xff\xff\xff\xff");

# Timestamp
check_simple([TYPE_TIMESTAMP], [ time()*1000, undef, 0 ]);
check_enc([TYPE_TIMESTAMP], 0, "\0\0\0\0\0\0\0\0");
check_enc([TYPE_TIMESTAMP], "1000000000000", "\0\0\0\xe8\xd4\xa5\x10\0");
check_enc([TYPE_TIMESTAMP], -1, "\xff\xff\xff\xff\xff\xff\xff\xff");

# Uuid
check_simple([TYPE_UUID], [ '00000000-0000-0000-0000-000000000000', 'ffffffff-ffff-ffff-ffff-ffffffffffff', undef ]);
check_enc([TYPE_UUID], '00000000-0000-0000-0000-000000000000', "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0");

# Varchar
check_simple([TYPE_VARCHAR], [ 'test', 'a', '', undef, '0' ]);
check_enc([TYPE_VARCHAR], 'test', 'test');

# Varint
check_simple([TYPE_VARINT], [ 1, 1000, 1000000, 1000000000, -1, -1000, -1000000, -1000000000, "100000000000", "1000000000000000000000000", "-1000000000000000000000000", "1000000000000000000000000000000000000000000000000000000000000000000"]);
check_enc([TYPE_VARINT], 0, "\0");
check_enc([TYPE_VARINT], 1, "\1");
check_enc([TYPE_VARINT], 127, "\x7f");
check_enc([TYPE_VARINT], 128, "\0\x80");
check_enc([TYPE_VARINT], 129, "\0\x81");
check_enc([TYPE_VARINT], -1, "\xff");
check_enc([TYPE_VARINT], -128, "\x80");
check_enc([TYPE_VARINT], -129, "\xff\x7f");
check_enc([TYPE_VARINT], "1000000000000000000000000000000000000000000000000000000000000000000", "\x09\x7e\xdd\x87\x1c\xfd\xa3\xa5\x69\x77\x58\xbf\x0e\x3c\xbb\x5a\xc5\x74\x1c\x64\0\0\0\0\0\0\0\0");

# Time
check_simple([TYPE_TIME], [
                            ( map "$_:00:00.12345", 0..23 ),
                            ( map "$_:59:59.999999999", 0..23 ),
                          ]);
check_enc([TYPE_TIME], '00:00:00.0', "\0\0\0\0\0\0\0\0");
check_enc([TYPE_TIME], '23:59:59.999999999', pack_long("86399999999999"));

# Date
check_simple([TYPE_DATE], [
                            "1970-01-01", 
                            "2016-01-01", 
                            ( map sprintf("0-02-%.2d", $_), 1..29 ),
                            ( map sprintf("10001-02-%.2d", $_), 1..28 ),
                            ( map sprintf("10001-03-%.2d", $_), 1..5 ),
                          ]);
check_enc([TYPE_DATE], "1970-01-01", "\x80\0\0\0");
check_enc([TYPE_DATE], "1970-03-01", "\x80\0\0\x3b");
check_enc([TYPE_DATE], "1970-02-29", "\x80\0\0\x3b");
check_enc([TYPE_DATE], "-5877641-06-23", "\0\0\0\0");
check_enc([TYPE_DATE], "5881580-07-11", "\377\377\377\377");

# Tinyint
check_simple([TYPE_TINYINT], [ (1..10), -50, -128, 127 ]);
check_enc([TYPE_TINYINT], 0, "\0");
check_enc([TYPE_TINYINT], 5, "\5");
check_enc([TYPE_TINYINT], -1, "\xff");
check_enc([TYPE_TINYINT], 127, "\x7f");
check_enc([TYPE_TINYINT], -128, "\x80");
{
    local $SIG{__WARN__}= sub{}; # Perl throws warnings when wrapping chars, but not all others...
    check_enc([TYPE_TINYINT], 128, "\x80"); # Wrap.
    check_enc([TYPE_TINYINT], -129, "\x7f"); # Wrap.
}

# Smallint
check_simple([TYPE_SMALLINT], [ (1..10), -50, -32768, 32767 ]);
check_enc([TYPE_SMALLINT], 123, "\0\x7b");
check_enc([TYPE_SMALLINT], -1, "\xff\xff");
check_enc([TYPE_SMALLINT], 1, "\0\1");
check_enc([TYPE_SMALLINT], 32767, "\x7f\xff");
check_enc([TYPE_SMALLINT], -32768, "\x80\0");
check_enc([TYPE_SMALLINT], 32768, "\x80\0"); # Wrap
check_enc([TYPE_SMALLINT], -32769, "\x7f\xff"); # Wrap.

# Timeuuid
check_simple([TYPE_TIMEUUID], [ '568ef050-5aca-11e5-9c6b-eb15c19b7bc8', undef ]);
check_enc([TYPE_TIMEUUID], '568ef050-5aca-11e5-9c6b-eb15c19b7bc8', "\x56\x8e\xf0\x50\x5a\xca\x11\xe5\x9c\x6b\xeb\x15\xc1\x9b\x7b\xc8");

# Inet
check_simple([TYPE_INET], [undef, qw/
                                     2001:1af8:4300:a031:1::
                                     1234::1234
                                     1::1
                                     127.0.0.1
                                     1.2.3.4
                                     255.255.255.255
                                     ::a:b:123
                                     123::123
                                     1::1
                                     1::
                                     ::1
                                    /]);
check_enc([TYPE_INET], "1.2.3.4", "\1\2\3\4");
check_enc([TYPE_INET], "255.255.255.255", "\xff\xff\xff\xff");
check_enc([TYPE_INET], "::1", "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\1");

# List
check_simple([TYPE_LIST, [ TYPE_INT ] ], [ [1, 2, 3], [4, 5, 6], undef, [4, undef, 6] ]);
check_enc([TYPE_LIST, [ TYPE_INT ] ], [ 1, 2, 3 ], "\0\0\0\3\0\0\0\4\0\0\0\1\0\0\0\4\0\0\0\2\0\0\0\4\0\0\0\3");

# Map
check_simple([TYPE_MAP, [ TYPE_INT ], [ TYPE_BOOLEAN ] ], [
                                                            { 1 => !1, 2 => !0 },
                                                          ]);
check_enc([TYPE_MAP, [ TYPE_INT ], [ TYPE_BOOLEAN ] ], { 2 => !0 }, "\0\0\0\1\0\0\0\4\0\0\0\2\0\0\0\1\1");
check_enc([TYPE_MAP, [ TYPE_INT ], [ TYPE_BOOLEAN ] ], { 1 => !1 }, "\0\0\0\1\0\0\0\4\0\0\0\1\0\0\0\1\0");

# Set
check_simple([TYPE_SET, [ TYPE_INT ]], [
                                        [ 1, 2, 3 ]
                                       ]);
check_enc([TYPE_SET, [ TYPE_INT ]], [ 1, 2, 3 ], "\0\0\0\3\0\0\0\4\0\0\0\1\0\0\0\4\0\0\0\2\0\0\0\4\0\0\0\3");

# UDT
check_simple([TYPE_UDT, 'keyspacename', 'udtname', [ ['my_int', [ TYPE_INT ] ] ] ], [
                                                                                      { my_int => 5 },
                                                                                    ]);
check_enc([TYPE_UDT, 'keyspacename', 'udtname', [ [ 'my_int', [ TYPE_INT ] ] ] ], { my_int => 5 }, "\0\0\0\4\0\0\0\5");

# Tuple
check_simple([TYPE_TUPLE, [[TYPE_INT], [TYPE_INT]]], [
                                                      [ 1, 2 ],
                                                      [ 1, 2 ]
                                                     ]);
check_enc([TYPE_TUPLE, [[TYPE_INT], [TYPE_INT]]], [ 1, 2 ], "\0\0\0\4\0\0\0\1\0\0\0\4\0\0\0\2" );

# list<frozen<map<int,bool>>>
check_simple([TYPE_LIST, [TYPE_MAP, [TYPE_INT], [TYPE_BOOLEAN]]], [
                                                                    [ { 1 => !1, 2 => !0 } ]
                                                                  ]);
check_enc([TYPE_LIST, [TYPE_MAP, [TYPE_INT], [TYPE_BOOLEAN]]],
    [ { 1 => !1 } ],
    pack("H*", '00000001000000110000000100000004000000010000000100')
);

# set<frozen<map<int,boolean>>>
check_simple([TYPE_SET, [TYPE_MAP, [TYPE_INT], [TYPE_BOOLEAN]]], [
                                                                    [ { 1 => !1, 2 => !0 } ],
                                                                 ]);
check_enc([TYPE_SET, [TYPE_MAP, [TYPE_INT], [TYPE_BOOLEAN]]],
    [ { 1 => !1 } ],
    pack('H*', '00000001000000110000000100000004000000010000000100')
);

# map<int,frozen<list<int>>>
check_simple([TYPE_MAP, [TYPE_INT], [TYPE_LIST, [TYPE_INT]]], [
                                                                { 1 => [2], 2 => [3] }
                                                              ]);
check_enc([TYPE_MAP, [TYPE_INT], [TYPE_LIST, [TYPE_INT]]],
    { 1 => [2] },
    pack('H*', '0000000100000004000000010000000c000000010000000400000002')
);


done_testing;
