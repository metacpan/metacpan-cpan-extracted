#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use Test::More tests    => 335;
use Encode qw(decode encode);


BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::Tarantool', ':constant';
    use_ok 'File::Spec::Functions', 'catfile';
    use_ok 'File::Basename', 'dirname';
}

like TNT_INSERT,            qr{^\d+$}, 'TNT_INSERT';
like TNT_SELECT,            qr{^\d+$}, 'TNT_SELECT';
like TNT_UPDATE,            qr{^\d+$}, 'TNT_UPDATE';
like TNT_DELETE,            qr{^\d+$}, 'TNT_DELETE';
like TNT_CALL,              qr{^\d+$}, 'TNT_CALL';
like TNT_PING,              qr{^\d+$}, 'TNT_PING';

like TNT_FLAG_RETURN,       qr{^\d+$}, 'TNT_FLAG_RETURN';
like TNT_FLAG_ADD,          qr{^\d+$}, 'TNT_FLAG_ADD';
like TNT_FLAG_REPLACE,      qr{^\d+$}, 'TNT_FLAG_REPLACE';
# like TNT_FLAG_BOX_QUIET,    qr{^\d+$}, 'TNT_FLAG_BOX_QUIET';
# like TNT_FLAG_NOT_STORE,    qr{^\d+$}, 'TNT_FLAG_NOT_STORE';

my $LE = $] > 5.01 ? '<' : '';


# SELECT
my $sbody = DR::Tarantool::_pkt_select( 9, 8, 7, 6, 5, [ ['abc'], ['cde'] ] );
ok defined $sbody, '* select body';

my @a = unpack "( L$LE )*", $sbody;
is $a[0], TNT_SELECT, 'select type';
is $a[1], length($sbody) - 3 * 4, 'body length';
is $a[2], 9, 'request id';
is $a[3], 8, 'space no';
is $a[4], 7, 'index no';
is $a[5], 6, 'offset';
is $a[6], 5, 'limit';
is $a[7], 2, 'tuple count';
ok !eval { DR::Tarantool::_pkt_select( 1, 2, 3, 4, 5, [ 6 ] ) }, 'keys format';
like $@ => qr{ARRAYREF of ARRAYREF}, 'error string';

# PING
$sbody = DR::Tarantool::_pkt_ping( 11 );
ok defined $sbody, '* ping body';
@a = unpack "( L$LE )*", $sbody;
is $a[0], TNT_PING, 'ping type';
is $a[1], length($sbody) - 3 * 4, 'body length';
is $a[2], 11, 'request id';


# insert
$sbody = DR::Tarantool::_pkt_insert( 12, 13, 14, [ 'a', 'b', 'c', 'd' ]);
ok defined $sbody, '* insert body';
@a = unpack "( L$LE )*", $sbody;
is $a[0], TNT_INSERT, 'insert type';
is $a[1], length($sbody) - 3 * 4, 'body length';
is $a[2], 12, 'request id';
is $a[3], 13, 'space no';
is $a[4], 14, 'flags';
is $a[5], 4,  'tuple size';

# delete
$sbody = DR::Tarantool::_pkt_delete( 119, 120, 121, [ 122, 123 ] );
ok defined $sbody, '* delete body';
@a = unpack "( L$LE )*", $sbody;
is $a[0], TNT_DELETE, 'delete type';
is $a[1], length($sbody) - 3 * 4, 'body length';
is $a[2], 119, 'request id';

is $a[3], 120, 'space no';

if (TNT_DELETE == 20) {
    ok 1, '# skipped old delete code';
    is $a[4], 2,  'tuple size';
} else {
    is $a[4], 121, 'flags';  # libtarantool ignores flags
    is $a[5], 2,  'tuple size';
}

# call
$sbody = DR::Tarantool::_pkt_call_lua( 124, 125, 'tproc', [ 126, 127 ]);
ok defined $sbody, '* call body';
@a = unpack "L$LE L$LE L$LE L$LE w/Z* L$LE L$LE", $sbody;
is $a[0], TNT_CALL, 'call type';
is $a[1], length($sbody) - 3 * 4, 'body length';
is $a[2], 124, 'request id';
is $a[3], 125, 'flags';
is $a[4], 'tproc',  'proc name';
is $a[5], 2, 'tuple size';


eval {
    DR::Tarantool::_pkt_update( 15, 16, 17, [ 18 ], [[ 10, 'abc cde', 20 ]])
};

like $@, qr{unknown update operation: `abc cde'}, 'wrong update operation';

# update
my @ops = map { [ int rand 100, $_, int rand 100 ] }
    qw(add and or xor set delete insert);
push @ops => [ 10, 'substr', 1, 2 ];
$sbody = DR::Tarantool::_pkt_update( 15, 16, 17, [ 18 ], \@ops);
ok defined $sbody, '* update body';
@a = unpack "( L$LE )*", $sbody;
is $a[0], TNT_UPDATE, 'update type';
is $a[1], length($sbody) - 3 * 4, 'body length';
is $a[2], 15, 'request id';
is $a[3], 16, 'space no';
is $a[4], 17, 'flags';
is $a[5], 1,  'tuple size';




$sbody = DR::Tarantool::_pkt_call_lua( 124, 125, 'tproc', [  ]);

# parser
ok !eval { DR::Tarantool::_pkt_parse_response( undef ) }, '* parser: undef';
my $res = DR::Tarantool::_pkt_parse_response( '' );
isa_ok $res => 'HASH', 'empty input';
like $res->{errstr}, qr{too short}, 'error message';
is $res->{status}, 'buffer', 'status';

my $data;
for (TNT_INSERT, TNT_UPDATE, TNT_SELECT, TNT_DELETE, TNT_CALL, TNT_PING) {
    my $msg = "test message";
    $data = pack "L$LE L$LE L$LE L$LE Z*",
        $_, 5 + length $msg, $_ + 100, 0x0101, $msg;
    $res = DR::Tarantool::_pkt_parse_response( $data );
    isa_ok $res => 'HASH', 'well input ' . $_;
    is $res->{req_id}, $_ + 100, 'request id';
    is $res->{type}, $_, 'request type';

    unless($res->{type} == TNT_PING) {
        is $res->{status}, 'error', "status $_";
        is $res->{code}, 0x101, 'code';
        is $res->{errstr}, $msg, 'errstr';
    }
    
    $res = DR::Tarantool::_pkt_parse_response( $data . 'aaaa' );
    isa_ok $res => 'HASH', 'well input ' . $_;
    is $res->{req_id}, $_ + 100, 'request id';
    is $res->{type}, $_, 'request type';

    unless($res->{type} == TNT_PING) {
        is $res->{status}, 'error', "status $_";
        is $res->{code}, 0x101, 'code';
        is $res->{errstr}, $msg, 'errstr';
    }
}

my $cfg_dir = catfile dirname(__FILE__), 'test-data';
ok -d $cfg_dir, 'directory with test data';
my @bins = glob catfile $cfg_dir, '*.bin';

for my $bin (sort @bins) {
    my ($type, $err, $status) =
        $bin =~ /(?>0*)?(\d+?)-0*(\d+)-(\w+)\.bin$/;
    next unless defined $bin;
    next unless $type;
    ok -r $bin, "$bin is readable";

    ok open(my $fh, '<:raw', $bin), "open $bin";
    my $pkt;
    { local $/; $pkt = <$fh>; }
    ok $pkt, "response body was read ($type): " .
        join '', map { sprintf '.%02x', $_ } unpack 'C*', $pkt;

    my $res = DR::Tarantool::_pkt_parse_response( $pkt );
    SKIP: {
        skip 'legacy delete packet', 4 if $type == 20 and TNT_DELETE != 20;
        is $res->{status}, $status, 'status ' . $type;
        is $res->{type}, $type, 'status ' . $type;
        is $res->{code}, $err, 'error code ' . $type;
        ok ( !($res->{code} xor $res->{errstr}), 'errstr ' . $type );
    }
    
    $res = DR::Tarantool::_pkt_parse_response( $pkt . 'aaaaa');
    SKIP: {
        skip 'legacy delete packet', 4 if $type == 20 and TNT_DELETE != 20;
        is $res->{status}, $status, 'status(trash) ' . $type;
        is $res->{type}, $type, 'status(trash) ' . $type;
        is $res->{code}, $err, 'error code(trash) ' . $type;
        ok ( !($res->{code} xor $res->{errstr}), 'errstr(trash) ' . $type );
    }
}

SKIP: {
#     skip 'Devel tests $ENV{DEVEL_TEST}=0', 120 unless $ENV{DEVEL_TEST};

# Pack an integer into an <int32_varint>, per the Tarantool binary protocol.
sub pack_varint {
    my $num = shift;
    my $out = pack 'C', ($num & 0x7f);
    $num >>= 7;
    while ($num) {
        $out .= pack 'C', (($num & 0x7f) | 0x80);
        $num >>= 7;
    }
    return scalar reverse $out;
}

# Pack arbitrary data into a trivial <fq_tuple>, per the Tarantool binary
# protocol.
sub pack_fq_tuple {
    my $body = shift;
    my $len = length $body;
    # <fq_tuple> ::= <size><tuple>
    # <tuple> ::= <cardinality><field>+
    # <field> ::= <int32_varint><data>
    my $len_varint = pack_varint($len);
    return pack 'LLa*a*',
        4 * length($len_varint) + $len,
        1,
        $len_varint,
        $body
    ;
}

for (1 .. 30) {
    my $body = join '', map { chr int rand 256 } 1 .. (300 + int rand 300);
    my $pkt =
        pack 'LLLLLa*',
            TNT_SELECT,
            8 + length $body,
            int rand 500,
            0,
            1,
            pack_fq_tuple($body)
        ;
    $res = DR::Tarantool::_pkt_parse_response( $pkt );
    diag explain $res unless
    is $res->{status}, 'buffer', "Broken package $_";
    $pkt =
        pack 'LLLLLa*',
            TNT_SELECT,
            8 + 10 + length $body,
            int rand 500,
            0,
            1,
            pack_fq_tuple($body)
        ;
    $res = DR::Tarantool::_pkt_parse_response( $pkt );
    diag explain $res unless
    is $res->{status}, 'buffer', "Broken package $_, too long body";
    
    $pkt =
        pack 'LLLLLa*',
            TNT_SELECT,
            8 - 10 + length $body,
            int rand 500,
            0,
            1,
            pack_fq_tuple($body)
        ;
    $res = DR::Tarantool::_pkt_parse_response( $pkt );
    diag explain $res unless
    is $res->{status}, 'buffer', "Broken package $_, too short body";
    
    $pkt =
        pack 'LLLLa*',
            TNT_SELECT,
            5 + int rand 500,
            5 + int rand 500,
            0,
            ''
        ;

    my $pkth = join '', map { sprintf '.%02x', ord $_ } split //, $pkt;
    
    $res = DR::Tarantool::_pkt_parse_response( $pkt );
    diag explain [ $res, $pkth, TNT_SELECT ] unless
    is $res->{status}, 'buffer', "Broken package $_, zero length body";
}
}
