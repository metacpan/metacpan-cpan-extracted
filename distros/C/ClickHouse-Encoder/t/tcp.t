#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use ClickHouse::Encoder::TCP;

# Round-trip a Hello: pack, then unpack, verify fields.
{
    my $bytes = ClickHouse::Encoder::TCP->pack_hello(
        client_name => 'test-client',
        database    => 'default',
        user        => 'admin',
        password    => 's3cret',
    );
    # Replace the leading CLIENT_HELLO (=0) with SERVER_HELLO (=0).
    # They're the same value, just the per-direction packet types
    # collide on 0; unpack_packet treats it as a server hello.
    my ($pkt) = ClickHouse::Encoder::TCP->unpack_packet($bytes, 0);
    is($pkt->{type}, 0, 'hello packet type');
    is($pkt->{name}, 'test-client', 'client name preserved');
    is($pkt->{major},    1, 'major default');
    is($pkt->{revision}, 54429, 'revision default');
    # Hello pack continues with database/user/password as varint+
    # bytes, but server hello layout differs after the revision
    # field. Don't compare past that.
}

# SERVER_HELLO optional trailing fields are gated on the reported
# revision (matching CH's DBMS_MIN_REVISION_WITH_* thresholds), not
# on whether bytes happen to remain. Build server-hello payloads by
# hand: type(0) + name + major + minor + revision + [optionals].
{
    my $lstr = \&ClickHouse::Encoder::TCP::pack_string;
    my $lv   = \&ClickHouse::Encoder::TCP::pack_varint;

    # Old revision (< 54058): no optional fields, even if bytes follow.
    my $old = "\x00" . $lstr->('srv') . $lv->(1) . $lv->(0)
            . $lv->(54000);
    my ($p) = ClickHouse::Encoder::TCP->unpack_packet($old, 0);
    is($p->{revision}, 54000, 'old-revision hello: revision parsed');
    ok(!exists $p->{timezone},
       'old-revision hello: timezone absent (gated by revision)');

    # Modern revision: all three optional fields present.
    my $new = "\x00" . $lstr->('srv') . $lv->(1) . $lv->(0)
            . $lv->(54429)
            . $lstr->('UTC') . $lstr->('srv-display') . $lv->(7);
    ($p) = ClickHouse::Encoder::TCP->unpack_packet($new, 0);
    is($p->{timezone},      'UTC',         'modern hello: timezone');
    is($p->{display_name},  'srv-display', 'modern hello: display_name');
    is($p->{version_patch}, 7,             'modern hello: version_patch');

    # A modern-revision hello truncated before its timezone field must
    # croak /truncated/ so a sliding-buffer reader fetches more, rather
    # than silently returning a hello with timezone missing.
    my $cut = "\x00" . $lstr->('srv') . $lv->(1) . $lv->(0) . $lv->(54429);
    my $err = eval { ClickHouse::Encoder::TCP->unpack_packet($cut, 0); 1 }
              ? '' : $@;
    like($err, qr/truncated/,
         'truncated modern hello croaks instead of dropping a field');
}

# Pack a Query packet, verify framing
{
    my $bytes = ClickHouse::Encoder::TCP->pack_query(
        query => 'insert into events format native',
    );
    is(ord(substr($bytes, 0, 1)),
       ClickHouse::Encoder::TCP::CLIENT_QUERY,
       'query packet leads with CLIENT_QUERY type byte');
    like($bytes, qr/insert into events format native/,
         'query string is on the wire');
}

# Settings hashref: each entry is `name + flags_varint(0) + value`
# terminated by an empty key. Verify the wire layout pin.
{
    my $bytes = ClickHouse::Encoder::TCP->pack_query(
        query    => 'select 1',
        settings => { max_memory_usage => '100000', readonly => '1' },
    );
    like($bytes, qr/max_memory_usage/, 'setting key appears');
    like($bytes, qr/100000/,            'setting value appears');
    # Verify the flags byte separates name from value: the byte after
    # the 16-char name "max_memory_usage" should be \x00 (flags=0),
    # then \x06 (varint len of "100000"), then "100000". Reach into
    # the buffer to confirm.
    my $idx = index($bytes, 'max_memory_usage');
    cmp_ok($idx, '>', 0, 'name found in bytes');
    is(ord(substr($bytes, $idx + 16, 1)), 0,
       'flags byte (=0) between name and value');
    is(ord(substr($bytes, $idx + 17, 1)), 6,
       'value length varint (6 = "100000") follows flags');
}

# Settings as a raw byte string: a non-ref settings value is passed
# through verbatim (the caller pre-encoded the settings block), so a
# query packed with the raw bytes must equal one packed with the
# equivalent hashref.
{
    my $raw = ClickHouse::Encoder::TCP::_pack_settings(
        { max_memory_usage => '100000' });
    my $from_hash = ClickHouse::Encoder::TCP->pack_query(
        query => 'select 1', settings => { max_memory_usage => '100000' });
    my $from_raw = ClickHouse::Encoder::TCP->pack_query(
        query => 'select 1', settings => $raw);
    is($from_raw, $from_hash,
       'pack_query: raw settings byte string passes through unchanged');
}

# Query-processing stage: pack_query encodes the stage constant as a
# varint, defaulting to STAGE_COMPLETE.
{
    my %base = (query => 'select 1', query_id => 'q');
    my $default  = ClickHouse::Encoder::TCP->pack_query(%base);
    my $complete = ClickHouse::Encoder::TCP->pack_query(%base,
        stage => ClickHouse::Encoder::TCP::STAGE_COMPLETE);
    is($default, $complete, 'pack_query stage defaults to STAGE_COMPLETE');

    my $fetch = ClickHouse::Encoder::TCP->pack_query(%base,
        stage => ClickHouse::Encoder::TCP::STAGE_FETCH_COLUMNS);
    my $merge = ClickHouse::Encoder::TCP->pack_query(%base,
        stage => ClickHouse::Encoder::TCP::STAGE_WITH_MERGEABLE);
    isnt($fetch, $complete, 'STAGE_FETCH_COLUMNS yields a distinct packet');
    isnt($merge, $complete, 'STAGE_WITH_MERGEABLE yields a distinct packet');
    is(length($fetch), length($complete),
       'stage 0/1/2 each encode as a single-byte varint');
}

# Data packet wraps a real Native block, byte-perfectly
{
    my $enc = ClickHouse::Encoder->new(columns => [['x','Int32']]);
    my $block = $enc->encode([[1],[2],[3]]);
    my $pkt = ClickHouse::Encoder::TCP->pack_data($block);
    # Type byte
    is(ord(substr($pkt, 0, 1)),
       ClickHouse::Encoder::TCP::CLIENT_DATA, 'data type');
    # Empty table name (1 varint byte == 0)
    is(ord(substr($pkt, 1, 1)), 0, 'empty table name varint');
    # The remaining bytes ARE the Native block
    is(substr($pkt, 2), $block, 'wrapped block bytes intact');
}

# pack_data_end: empty block signal
{
    my $end = ClickHouse::Encoder::TCP->pack_data_end();
    # \x02 (CLIENT_DATA) + \x00 (empty table) + \x00 (ncols=0) + \x00 (nrows=0)
    is($end, "\x02\x00\x00\x00", 'end-of-insert canonical bytes');
}

# Ping / Cancel
{
    is(ClickHouse::Encoder::TCP->pack_ping,   "\x04", 'ping packet');
    is(ClickHouse::Encoder::TCP->pack_cancel, "\x03", 'cancel packet');
}

# unpack a synthetic Exception
{
    # type=2 (SERVER_EXCEPTION), code=Int32 LE (=42), name, message,
    # stack_trace, has_nested(byte)
    my $bytes = "\x02"                       # type
              . pack('l<', 42)                # code
              . "\x09ErrorName\x00"           # name (len=9 + "ErrorName") + msg(empty)
              . "\x00"                        # stack_trace (empty)
              . "\x00";                       # has_nested
    # Re-pack the name+message correctly:
    $bytes = "\x02"
           . pack('l<', 42)
           . _len_str('Bad')
           . _len_str('something failed')
           . _len_str('')
           . "\x00";
    my ($pkt) = ClickHouse::Encoder::TCP->unpack_packet($bytes, 0);
    is($pkt->{type},        2,                  'exception type');
    is($pkt->{code},        42,                 'exception code');
    is($pkt->{name},        'Bad',              'exception name');
    is($pkt->{message},     'something failed', 'exception message');
    is($pkt->{stack_trace}, '',                 'empty stack trace');
    is($pkt->{has_nested},  0,                  'no nested');
}

# unpack EndOfStream (no payload)
{
    my ($pkt) = ClickHouse::Encoder::TCP->unpack_packet("\x05", 0);
    is($pkt->{type}, 5, 'EOS type');
}

# unpack Pong (no payload) - the companion of EndOfStream in the
# same payload-less branch of unpack_packet.
{
    my ($pkt, $off) = ClickHouse::Encoder::TCP->unpack_packet("\x04", 0);
    is($pkt->{type}, 4, 'Pong type');
    is($off,         1, 'Pong consumes only the 1-byte type');
}

# unpack a Progress packet (the fixed 5-varint revision-54429 layout)
{
    # type=3, then 5 varints
    my $bytes = "\x03"
              . _varint(100)   # rows
              . _varint(1024)  # bytes
              . _varint(500)   # total_rows
              . _varint(50)    # written_rows
              . _varint(512);  # written_bytes
    my ($pkt, $end) = ClickHouse::Encoder::TCP->unpack_packet($bytes, 0);
    is($pkt->{type},          3,    'progress type');
    is($pkt->{rows},          100,  'progress rows');
    is($pkt->{bytes},         1024, 'progress bytes');
    is($pkt->{written_rows},  50,   'written rows');
    is($pkt->{written_bytes}, 512,  'written bytes');
    is($end, length($bytes),
       'progress consumes exactly its five varints');
}

# A Progress packet must stop at written_bytes even when the buffer
# already holds the next packet: unpack_packet must not consume the
# following packet's bytes as a trailing Progress field.
{
    my $progress = "\x03" . _varint(1) . _varint(2) . _varint(3)
                          . _varint(4) . _varint(5);
    my $buf = $progress . "\x05";   # Progress then EndOfStream
    my ($pkt, $end) = ClickHouse::Encoder::TCP->unpack_packet($buf, 0);
    is($pkt->{type}, 3,                 'progress type from multi-packet buffer');
    is($end, length($progress),
       'progress end offset stops before the next packet');
    my ($next) = ClickHouse::Encoder::TCP->unpack_packet($buf, $end);
    is($next->{type}, 5, 'following EndOfStream still parses intact');
}

# Unknown type -> croak
{
    my $bytes = "\x63";  # 99 unknown
    my $err = eval { ClickHouse::Encoder::TCP->unpack_packet($bytes, 0); 1 }
              ? '' : $@;
    like($err, qr/unknown server packet type 99/,
         'unknown packet rejected');
}

# Client revision gates the ClientInfo trailing fields: at rev >= 54058
# quota_key is emitted, at rev >= 54401 version_patch is too. A query
# packed at an older revision must omit those bytes.
{
    my %base = (query => 'select 1', query_id => 'q');
    my $modern = ClickHouse::Encoder::TCP->pack_query(%base,
        revision => 54429);
    my $pre_quota = ClickHouse::Encoder::TCP->pack_query(%base,
        revision => 54050);   # < 54058 -> no quota_key, no version_patch
    my $pre_patch = ClickHouse::Encoder::TCP->pack_query(%base,
        revision => 54200);   # >= 54058, < 54401 -> quota_key but no patch

    # Modern hello bytes - pre-quota hello bytes = lenstr("") + varint(0)
    # = 2 bytes (one empty-string length prefix + one zero varint).
    cmp_ok(length($modern), '>', length($pre_quota),
           'rev<54058: ClientInfo omits quota_key + version_patch');
    cmp_ok(length($pre_quota), '<', length($pre_patch),
           'rev>=54058: ClientInfo includes quota_key');
    cmp_ok(length($pre_patch), '<', length($modern),
           'rev<54401: ClientInfo still omits version_patch');
    is(length($modern) - length($pre_patch), 1,
       'version_patch encodes as exactly one varint byte for value 0');
    is(length($pre_patch) - length($pre_quota), 1,
       'quota_key encodes as exactly one lenstr byte for empty value');
}

# Encoder-side argument croaks.
{
    my $err = eval { ClickHouse::Encoder::TCP->pack_data(undef); 1 }
              ? '' : $@;
    like($err, qr/block bytes required/,
         'pack_data croaks on undef block');
    $err = eval { ClickHouse::Encoder::TCP->pack_query(); 1 } ? '' : $@;
    like($err, qr/'query' is required/,
         'pack_query croaks when query is missing');
}

# Totals (type 7) and Extremes (type 8) share the Data-shape layout:
# table_name string, then a Native block. Verify unpack_packet sets
# block_offset past the table_name so the caller can decode_block
# from there.
{
    for my $type (7, 8) {
        my $bytes = chr($type) . _len_str('');  # empty table name
        my ($pkt, $off) = ClickHouse::Encoder::TCP->unpack_packet($bytes, 0);
        is($pkt->{type},         $type, "type $type unpacks");
        is($pkt->{table_name},   '',    "type $type table_name empty");
        is($pkt->{block_offset}, 2,     "type $type block_offset past 1-byte type+empty name");
    }
}

# ProfileEvents (type 14) shares the same Data-shape layout: a
# table_name string followed by a block; block_offset points past
# the name so the caller can decode_block from there.
{
    my $bytes = "\x0e" . _len_str('');  # type 14, empty table name
    my ($pkt) = ClickHouse::Encoder::TCP->unpack_packet($bytes, 0);
    is($pkt->{type},         14, 'ProfileEvents type');
    is($pkt->{table_name},   '', 'ProfileEvents table_name empty');
    is($pkt->{block_offset}, 2,  'ProfileEvents block_offset past type+name');
}

# ProfileInfo: rows + blocks + rows_bytes (varints), applied_limit
# (byte), rows_before_limit (varint), calculated_rows_before_limit (byte).
{
    my $bytes = "\x06"
              . _varint(1234)   # rows
              . _varint(5)      # blocks
              . _varint(98765)  # rows_bytes
              . "\x01"          # applied_limit
              . _varint(1000)   # rows_before_limit
              . "\x00";         # calculated_rows_before_limit
    my ($pkt) = ClickHouse::Encoder::TCP->unpack_packet($bytes, 0);
    is($pkt->{type},                          6,      'profile-info type');
    is($pkt->{rows},                          1234,   'profile-info rows');
    is($pkt->{blocks},                        5,      'profile-info blocks');
    is($pkt->{rows_bytes},                    98765,  'profile-info rows_bytes');
    is($pkt->{applied_limit},                 1,      'profile-info applied_limit');
    is($pkt->{rows_before_limit},             1000,   'profile-info rows_before_limit');
    is($pkt->{calculated_rows_before_limit},  0,      'profile-info calc-rows-before-limit');
}

# TableColumns (type 11): two strings (table_name, column_descriptor).
{
    my $bytes = "\x0b"
              . _len_str('mytab')
              . _len_str('id Int32, name String');
    my ($pkt) = ClickHouse::Encoder::TCP->unpack_packet($bytes, 0);
    is($pkt->{type},              11,                       'table-columns type');
    is($pkt->{table_name},        'mytab',                  'table-columns table_name');
    is($pkt->{column_descriptor}, 'id Int32, name String',  'table-columns descriptor');
}

# pack_data with compress => 'lz4' wraps the Native block in
# CH's compressed-block framing (16 byte CityHash128 + 9-byte header
# + LZ4 payload). The unit-level check: extract the inner bytes and
# verify decompress_native_block gives back the original block.
SKIP: {
    eval { require Compress::LZ4; 1 }
        or skip 'Compress::LZ4 not installed', 5;

    my $enc = ClickHouse::Encoder->new(columns => [['x','Int32']]);
    my $block = $enc->encode([[1],[2],[3]]);

    my $pkt = ClickHouse::Encoder::TCP->pack_data($block,
                                                   compress => 'lz4');
    is(ord(substr($pkt, 0, 1)),
       ClickHouse::Encoder::TCP::CLIENT_DATA,
       'compressed pack_data: leads with CLIENT_DATA type byte');
    is(ord(substr($pkt, 1, 1)), 0,
       'compressed pack_data: empty table_name varint follows');

    # Everything past byte 2 is the compressed-block framing.
    my $framed = substr($pkt, 2);
    cmp_ok(length($framed), '>=', 25,
       'framed payload has at least the 25-byte prefix');
    # Method tag at offset 16 inside the framed block:
    is(ord(substr($framed, 16, 1)), 0x82,
       'framed payload uses LZ4 method tag 0x82');

    my $plain = ClickHouse::Encoder->decompress_native_block($framed);
    is($plain, $block, 'compressed Data packet round-trips through decompress');
}

# pack_data_end with compression: the empty Native block must also
# go through the same framing so the server's CompressedReadBuffer
# can parse it.
SKIP: {
    eval { require Compress::LZ4; 1 }
        or skip 'Compress::LZ4 not installed', 2;

    my $end = ClickHouse::Encoder::TCP->pack_data_end(compress => 'lz4');
    is(ord(substr($end, 0, 1)),
       ClickHouse::Encoder::TCP::CLIENT_DATA,
       'compressed pack_data_end: leads with CLIENT_DATA type byte');
    # Verify the framed empty block decompresses to the canonical
    # empty-Native-block bytes (ncols=0, nrows=0).
    my $framed = substr($end, 2);
    my $plain  = ClickHouse::Encoder->decompress_native_block($framed);
    is($plain, "\x00\x00",
       'compressed pack_data_end framing wraps the 2-byte empty block');
}

# pack_data / pack_data_end also accept compress => 'zstd'; the only
# wire difference from lz4 is the method tag (0x90 vs 0x82). Same
# round-trip check.
SKIP: {
    eval { require Compress::Zstd; 1 }
        or skip 'Compress::Zstd not installed', 3;

    my $enc   = ClickHouse::Encoder->new(columns => [['x','Int32']]);
    my $block = $enc->encode([[1],[2],[3]]);

    my $pkt    = ClickHouse::Encoder::TCP->pack_data($block,
                                                     compress => 'zstd');
    my $framed = substr($pkt, 2);
    is(ord(substr($framed, 16, 1)), 0x90,
       'zstd pack_data uses ZSTD method tag 0x90');
    is(ClickHouse::Encoder->decompress_native_block($framed), $block,
       'zstd-compressed Data packet round-trips through decompress');

    my $end = ClickHouse::Encoder::TCP->pack_data_end(compress => 'zstd');
    is(ClickHouse::Encoder->decompress_native_block(substr($end, 2)),
       "\x00\x00",
       'zstd pack_data_end framing wraps the empty block');
}

# read_packet(compressed => 1) decompresses inner Data blocks.
# read_packet is for SERVER-side packets; CLIENT_DATA collides with
# SERVER_EXCEPTION (both =2), so build a SERVER_DATA (=1) packet by
# hand: type varint + empty table_name varint + compressed-framed
# Native block bytes.
SKIP: {
    eval { require Compress::LZ4; 1 }
        or skip 'Compress::LZ4 not installed', 4;

    my $enc = ClickHouse::Encoder->new(columns => [['x','Int32']]);
    my $block = $enc->encode([[42], [43], [44]]);
    my $framed = ClickHouse::Encoder->compress_native_block(
        $block, mode => 'lz4');
    my $server_pkt =
        "\x01"          # SERVER_DATA type
      . "\x00"          # empty table_name varint
      . $framed;        # compressed-framed Native block

    pipe(my $r, my $w) or die "pipe: $!";
    binmode $r; binmode $w;
    print $w $server_pkt;
    close $w;

    my $got = ClickHouse::Encoder::TCP->read_packet($r, compressed => 1);
    is($got->{type},
       ClickHouse::Encoder::TCP::SERVER_DATA,
       'compressed read_packet: SERVER_DATA type');
    is($got->{block}{nrows}, 3,
       'compressed read_packet: nrows decoded');
    is_deeply($got->{block}{columns}[0]{values}, [42, 43, 44],
              'compressed read_packet: values round-trip');
    is($got->{compressed_consumed}, length($framed),
       'compressed read_packet: compressed_consumed matches framed size');
    close $r;
}

# read_packet(buffer => \$buf): a single sysread can pull in several
# packets; the caller-owned buffer must carry the over-read bytes
# forward so a looping reader does not lose them. Write Pong (\x04)
# and EndOfStream (\x05) back-to-back, then read both.
{
    pipe(my $r, my $w) or die "pipe: $!";
    binmode $r; binmode $w;
    print $w "\x04\x05";   # Pong + EndOfStream in one segment
    close $w;

    my $buf = '';
    my $p1 = ClickHouse::Encoder::TCP->read_packet($r, buffer => \$buf);
    is($p1->{type}, 4, 'buffered read_packet: first call returns Pong');
    is($buf, "\x05", 'buffered read_packet: over-read byte kept in buffer');

    # Second call is satisfied entirely from the buffer - the pipe is
    # already at EOF, so without the carry-forward this would die.
    my $p2 = ClickHouse::Encoder::TCP->read_packet($r, buffer => \$buf);
    is($p2->{type}, 5, 'buffered read_packet: second call returns EndOfStream');
    is($buf, '', 'buffered read_packet: buffer drained');
    close $r;
}

# Without a buffer, read_packet is one-shot: the over-read EndOfStream
# byte is dropped, so a second call hits EOF and croaks.
{
    pipe(my $r, my $w) or die "pipe: $!";
    binmode $r; binmode $w;
    print $w "\x04\x05";
    close $w;

    my $p1 = ClickHouse::Encoder::TCP->read_packet($r);
    is($p1->{type}, 4, 'one-shot read_packet: first call returns Pong');
    my $err = eval {
        ClickHouse::Encoder::TCP->read_packet($r); 1
    } ? '' : $@;
    like($err, qr/connection closed/,
         'one-shot read_packet: over-read byte was dropped, 2nd call hits EOF');
    close $r;
}

# Live INSERT end-to-end. Opt-in: this requires a ClickHouse server
# at protocol revision <= 54474 (older than the chunking-negotiation
# extension introduced around CH 24.10). Modern servers (rev >=
# 54475) advertise a chunking offer right after Hello that this
# subset does not respond to, so the connection ends with a fast
# protocol-mismatch error rather than a real handshake. The unit
# tests above fully cover the wire-format encoding correctness.
SKIP: {
    skip "set TEST_CLICKHOUSE_TCP=1 (default port 9000) to enable "
       . "live TCP tests; requires a server at protocol revision "
       . "<= 54474 - newer servers add chunking negotiation past "
       . "this subset's scope", 4
        unless $ENV{TEST_CLICKHOUSE_TCP};
    my $tcp_port = $ENV{TEST_CLICKHOUSE_TCP_PORT} // 9000;
    require IO::Socket::INET;
    my $sock = IO::Socket::INET->new(
        PeerAddr => "127.0.0.1:$tcp_port",
        Timeout  => 2,
    );
    skip "ClickHouse TCP not reachable on :$tcp_port", 4 unless $sock;
    binmode $sock;

    print $sock ClickHouse::Encoder::TCP->pack_hello(
        user => 'default', password => '', database => 'default');
    my $hello = ClickHouse::Encoder::TCP->read_packet($sock);
    is($hello->{type}, 0, 'server hello received');
    cmp_ok($hello->{revision}, '>', 54000, 'server revision sane');

    # Create + INSERT
    print $sock ClickHouse::Encoder::TCP->pack_query(
        query => 'drop table if exists ch_tcp_t');
    # Consume to EndOfStream
    while (1) {
        my $p = ClickHouse::Encoder::TCP->read_packet($sock);
        last if $p->{type} == 5;  # EOS
        next if $p->{type} == 3;  # progress
        die "drop: unexpected $p->{type}" if $p->{type} == 2;
    }
    print $sock ClickHouse::Encoder::TCP->pack_query(
        query => 'create table ch_tcp_t (x Int32, s String) engine=Memory');
    while (1) {
        my $p = ClickHouse::Encoder::TCP->read_packet($sock);
        last if $p->{type} == 5;
        next if $p->{type} == 3;
        die "create: unexpected $p->{type}" if $p->{type} == 2;
    }

    # INSERT
    print $sock ClickHouse::Encoder::TCP->pack_query(
        query => 'insert into ch_tcp_t format native');
    # Server replies with TableColumns + empty Data sample block.
    # Drain until first non-progress non-table-columns packet.
    while (1) {
        my $p = ClickHouse::Encoder::TCP->read_packet($sock);
        last if $p->{type} == 1;       # SERVER_DATA (sample)
        next if $p->{type} == 11;      # TableColumns
        next if $p->{type} == 3;       # Progress
        die "insert: unexpected $p->{type}" if $p->{type} == 2;
    }

    my $enc = ClickHouse::Encoder->new(columns =>
        [['x','Int32'],['s','String']]);
    my $block = $enc->encode([[1,'a'],[2,'b'],[3,'c']]);
    print $sock ClickHouse::Encoder::TCP->pack_data($block);
    print $sock ClickHouse::Encoder::TCP->pack_data_end();

    # Read until EOS
    while (1) {
        my $p = ClickHouse::Encoder::TCP->read_packet($sock);
        last if $p->{type} == 5;
        next if $p->{type} == 3;
        next if $p->{type} == 6;       # ProfileInfo
        next if $p->{type} == 14;      # ProfileEvents
        die "insert flush: type $p->{type} $p->{message}\n"
            if $p->{type} == 2;
    }
    ok(1, 'INSERT via TCP completed without exception');

    # SELECT count() via the same connection
    print $sock ClickHouse::Encoder::TCP->pack_query(
        query => 'select count() from ch_tcp_t');
    my $got_count;
    while (1) {
        my $p = ClickHouse::Encoder::TCP->read_packet($sock);
        last if $p->{type} == 5;
        next if $p->{type} == 3 || $p->{type} == 6 || $p->{type} == 14
             || $p->{type} == 11;
        if ($p->{type} == 1) {
            # Data: decoded inline by read_packet.
            $got_count = $p->{block}{columns}[0]{values}[0]
                if $p->{block}{nrows};
        }
    }
    is($got_count, 3, 'SELECT count via TCP returned 3');

    close $sock;
}

done_testing();

# helpers ----------------------------------------------------------
sub _varint {
    my $v = shift;
    my $s = '';
    while ($v >= 0x80) { $s .= chr(($v & 0x7f) | 0x80); $v >>= 7 }
    return $s . chr($v);
}
sub _len_str {
    my $s = shift;
    return _varint(length $s) . $s;
}
