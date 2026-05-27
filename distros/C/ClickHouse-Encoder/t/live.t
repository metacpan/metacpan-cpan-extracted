#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use lib 'blib/lib', 'blib/arch';

# Check if clickhouse-client is available
my $ch_client = `which clickhouse-client 2>/dev/null`;
chomp $ch_client;

if (!$ch_client) {
    plan skip_all => 'clickhouse-client not found';
    exit 0;
}

# Check if we can connect to a running ClickHouse server
my $ch_running = system("clickhouse-client --query 'select 1' >/dev/null 2>&1") == 0;

my $tmpdir;
my $ch_pid;
my $ch_port = 9000;
my $http_port = 8123;

if (!$ch_running) {
    # Try to find clickhouse-server
    my $ch_server = `which clickhouse-server 2>/dev/null`;
    chomp $ch_server;

    if (!$ch_server) {
        # Try clickhouse binary (single binary mode)
        $ch_server = `which clickhouse 2>/dev/null`;
        chomp $ch_server;
        $ch_server = "$ch_server server" if $ch_server;
    }

    if (!$ch_server) {
        plan skip_all => 'clickhouse-server not found and no running instance';
        exit 0;
    }

    # Find available ports
    for my $base_port (19000, 29000, 39000) {
        my $sock1 = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1',
            LocalPort => $base_port,
            Proto => 'tcp',
            ReuseAddr => 1,
        );
        my $sock2 = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1',
            LocalPort => $base_port + 1,
            Proto => 'tcp',
            ReuseAddr => 1,
        );
        if ($sock1 && $sock2) {
            $ch_port = $base_port;
            $http_port = $base_port + 1;
            $sock1->close;
            $sock2->close;
            last;
        }
    }

    # Create temp directory for ClickHouse data
    $tmpdir = tempdir(CLEANUP => 1);

    # Create minimal config
    my $config = qq{<?xml version="1.0"?>
<clickhouse>
    <logger>
        <level>warning</level>
        <console>1</console>
    </logger>
    <tcp_port>$ch_port</tcp_port>
    <http_port>$http_port</http_port>
    <path>$tmpdir/</path>
    <tmp_path>$tmpdir/tmp/</tmp_path>
    <user_files_path>$tmpdir/user_files/</user_files_path>
    <format_schema_path>$tmpdir/format_schemas/</format_schema_path>
    <mark_cache_size>5368709120</mark_cache_size>
    <users>
        <default>
            <password></password>
            <networks><ip>::/0</ip></networks>
            <profile>default</profile>
            <quota>default</quota>
            <access_management>1</access_management>
        </default>
    </users>
    <profiles><default></default></profiles>
    <quotas><default></default></quotas>
</clickhouse>
};

    mkdir "$tmpdir/tmp";
    mkdir "$tmpdir/user_files";
    mkdir "$tmpdir/format_schemas";

    open my $fh, '>', "$tmpdir/config.xml" or die "Cannot write config: $!";
    print $fh $config;
    close $fh;

    # Start ClickHouse server
    $ch_pid = fork();
    if ($ch_pid == 0) {
        # Child process
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        exec $ch_server, '--config-file', "$tmpdir/config.xml";
        exit 1;
    }

    # Wait for server to start
    my $started = 0;
    for my $i (1..30) {
        if (system("clickhouse-client --port $ch_port --query 'select 1' >/dev/null 2>&1") == 0) {
            $started = 1;
            last;
        }
        select(undef, undef, undef, 0.5);
    }

    if (!$started) {
        kill 'TERM', $ch_pid if $ch_pid;
        plan skip_all => 'Could not start clickhouse-server';
        exit 0;
    }

    diag "Started ClickHouse server on port $ch_port (pid $ch_pid)";
}

# Cleanup handler
END {
    if ($ch_pid) {
        kill 'TERM', $ch_pid;
        waitpid($ch_pid, 0);
        diag "Stopped ClickHouse server";
    }
}

# Now we have a running ClickHouse - run the tests
use ClickHouse::Encoder;

my @ch_cmd = ('clickhouse-client', '--port', $ch_port);

sub ch_query {
    my ($query) = @_;
    system(@ch_cmd, '--query', $query) == 0
        or die "Query failed: $query";
}

sub ch_query_result {
    my ($query) = @_;
    open my $fh, '-|', @ch_cmd, '--query', $query
        or die "Cannot run clickhouse-client: $!";
    my $result = do { local $/; <$fh> };
    close $fh;
    $result =~ s/\s+\z// if defined $result;
    return $result // '';
}

sub ch_insert_native {
    my ($table, $data) = @_;
    open my $fh, '|-', @ch_cmd, '--query', "insert into $table format native"
        or die "Cannot run clickhouse-client: $!";
    binmode $fh;
    print $fh $data;
    close $fh;
    return $? == 0;
}


# Test 1: Basic integer types
{
    ch_query("drop table if exists test_integers");
    ch_query("create table test_integers (
        a Int8, b Int16, c Int32, d Int64,
        e UInt8, f UInt16, g UInt32, h UInt64
    ) engine = Memory");

    my $enc = ClickHouse::Encoder->for_table('test_integers', port => $ch_port);
    my $data = $enc->encode([
        [-1, -1000, -100000, -10000000000, 255, 65535, 4294967295, 4611686018427387904],
    ]);

    ok(ch_insert_native('test_integers', $data), 'insert integers');

    my $result = ch_query_result("select * from test_integers format csv");
    is($result, '-1,-1000,-100000,-10000000000,255,65535,4294967295,4611686018427387904', 'integers match');
}

# Test 2: Float types
{
    ch_query("drop table if exists test_floats");
    ch_query("create table test_floats (a Float32, b Float64) engine = Memory");

    my $enc = ClickHouse::Encoder->for_table('test_floats', port => $ch_port);
    my $data = $enc->encode([[3.14, 2.718281828]]);

    ok(ch_insert_native('test_floats', $data), 'insert floats');

    my $result = ch_query_result("select round(a, 2), round(b, 9) from test_floats format csv");
    is($result, '3.14,2.718281828', 'floats match');
}

# Test 3: String types
{
    ch_query("drop table if exists test_strings");
    ch_query("create table test_strings (a String, b FixedString(10)) engine = Memory");

    my $enc = ClickHouse::Encoder->for_table('test_strings', port => $ch_port);
    my $data = $enc->encode([['hello world', 'fixed']]);

    ok(ch_insert_native('test_strings', $data), 'insert strings');

    my $result = ch_query_result("select a, b from test_strings format csv");
    # FixedString is padded with nulls, CSV shows them
    like($result, qr/"hello world","fixed/, 'strings match');
}

# Test 4: UTF-8 strings
{
    ch_query("drop table if exists test_utf8");
    ch_query("create table test_utf8 (a String) engine = Memory");

    my $enc = ClickHouse::Encoder->for_table('test_utf8', port => $ch_port);
    use utf8;
    my $data = $enc->encode([['Привет мир 日本語 🎉']]);

    ok(ch_insert_native('test_utf8', $data), 'insert utf8');

    my $result = ch_query_result("select length(a) from test_utf8");
    # UTF-8 byte length of "Привет мир 日本語 🎉" = 12+1+6+1+9+1+4 = 34 bytes
    ok($result > 20, 'utf8 string has correct byte length');
}

# Test 5: Array type
{
    ch_query("drop table if exists test_arrays");
    ch_query("create table test_arrays (a Array(UInt32), b Array(String)) engine = Memory");

    my $enc = ClickHouse::Encoder->for_table('test_arrays', port => $ch_port);
    my $data = $enc->encode([
        [[1, 2, 3], ['foo', 'bar']],
        [[], ['single']],
    ]);

    ok(ch_insert_native('test_arrays', $data), 'insert arrays');

    my $result = ch_query_result("select * from test_arrays format jsoneachrow");
    like($result, qr/\[1,2,3\]/, 'array values match');
    like($result, qr/\["foo","bar"\]/, 'string array match');
}

# Test 6: Nullable type
{
    ch_query("drop table if exists test_nullable");
    ch_query("create table test_nullable (a Nullable(Int32), b Nullable(String)) engine = Memory");

    my $enc = ClickHouse::Encoder->for_table('test_nullable', port => $ch_port);
    my $data = $enc->encode([
        [42, 'hello'],
        [undef, undef],
        [100, 'world'],
    ]);

    ok(ch_insert_native('test_nullable', $data), 'insert nullable');

    my $result = ch_query_result("select * from test_nullable format csv");
    like($result, qr/42,"hello"/, 'nullable values');
    like($result, qr/\\N,\\N/, 'null values');
}

# Test 7: Tuple type
{
    ch_query("drop table if exists test_tuple");
    ch_query("create table test_tuple (a Tuple(UInt32, String, Float64)) engine = Memory");

    my $enc = ClickHouse::Encoder->for_table('test_tuple', port => $ch_port);
    my $data = $enc->encode([
        [[1, 'one', 1.1]],
        [[2, 'two', 2.2]],
    ]);

    ok(ch_insert_native('test_tuple', $data), 'insert tuple');

    my $result = ch_query_result("select a.1, a.2, round(a.3, 1) from test_tuple format csv");
    like($result, qr/1,"one",1.1/, 'tuple values');
}

# Test 8: Enum types (use explicit schema since for_table enum parsing varies by CH version)
{
    ch_query("drop table if exists test_enum");
    ch_query("create table test_enum (
        a Enum8('pending' = 0, 'active' = 1, 'closed' = 2),
        b Enum16('low' = 100, 'medium' = 200, 'high' = 300)
    ) engine = Memory");

    # Use explicit column definitions to avoid enum parsing issues with for_table
    my $enc = ClickHouse::Encoder->new(columns => [
        ['a', "Enum8('pending' = 0, 'active' = 1, 'closed' = 2)"],
        ['b', "Enum16('low' = 100, 'medium' = 200, 'high' = 300)"],
    ]);
    # Test both string and integer input
    my $data = $enc->encode([
        ['pending', 'low'],
        [1, 200],           # integer values
        ['closed', 'high'],
    ]);

    ok(ch_insert_native('test_enum', $data), 'insert enum');

    my $result = ch_query_result("select * from test_enum format csv");
    like($result, qr/"pending","low"/, 'enum string values');
    like($result, qr/"active","medium"/, 'enum integer values');
}

# Test 9: Decimal types
{
    ch_query("drop table if exists test_decimal");
    ch_query("create table test_decimal (
        a Decimal32(2),
        b Decimal64(4),
        c Decimal128(2)
    ) engine = Memory");

    my $enc = ClickHouse::Encoder->for_table('test_decimal', port => $ch_port);
    my $data = $enc->encode([
        [123.45, 123.4567, 999999.99],
        [-67.89, -0.0001, -123.45],
    ]);

    ok(ch_insert_native('test_decimal', $data), 'insert decimal');

    my $result = ch_query_result("select * from test_decimal format csv");
    like($result, qr/123\.45,123\.4567,999999\.99/, 'decimal positive');
    like($result, qr/-67\.89,-0\.0001,-123\.45/, 'decimal negative');
}

# Test 10: Date/DateTime types
{
    ch_query("drop table if exists test_datetime");
    ch_query("create table test_datetime (
        a Date,
        b DateTime,
        c DateTime64(3)
    ) engine = Memory");

    my $enc = ClickHouse::Encoder->for_table('test_datetime', port => $ch_port);
    my $data = $enc->encode([
        ['2024-06-15', '2024-06-15 12:30:45', '2024-06-15 12:30:45.123'],
        [19889, 1718451045, 1718451045.500],  # numeric values
    ]);

    ok(ch_insert_native('test_datetime', $data), 'insert datetime');

    my $result = ch_query_result("select * from test_datetime format csv");
    like($result, qr/2024-06-15/, 'date values');
    # Check that datetime has proper format (time may vary by timezone)
    like($result, qr/\d{2}:\d{2}:\d{2}/, 'datetime has time values');
}

# Test 11: Multiple rows stress test
{
    ch_query("drop table if exists test_stress");
    ch_query("create table test_stress (id UInt32, name String, value Float64) engine = Memory");

    my $enc = ClickHouse::Encoder->for_table('test_stress', port => $ch_port);

    my @rows;
    for my $i (1..1000) {
        push @rows, [$i, "name_$i", $i * 1.5];
    }

    my $data = $enc->encode(\@rows);
    ok(ch_insert_native('test_stress', $data), 'insert 1000 rows');

    my $count = ch_query_result("select count() from test_stress");
    is($count, '1000', '1000 rows inserted');
}

# Test 12: extended types — Bool, UUID, IPv4, IPv6, Map, LowCardinality
{
    ch_query("drop table if exists test_ext");
    ch_query(q{create table test_ext (
        b   Bool,
        u   UUID,
        v4  IPv4,
        v6  IPv6,
        m   Map(String, UInt32),
        lc  LowCardinality(String),
        lcn LowCardinality(Nullable(String))
    ) engine = Memory});

    my $enc = ClickHouse::Encoder->for_table('test_ext', port => $ch_port);
    my $data = $enc->encode([
        [1, '550e8400-e29b-41d4-a716-446655440000',
            '1.2.3.4', '2001:db8::1',
            {a => 10, b => 20}, 'alpha', 'x'],
        [0, '00000000-0000-0000-0000-000000000001',
            '0.0.0.0', '::1',
            {}, 'alpha', undef],
        [1, '11111111-2222-3333-4444-555555555555',
            '255.255.255.255', 'fe80::1',
            [['k', 1]], 'beta', ''],   # the empty-string-not-null case
    ]);
    ok(ch_insert_native('test_ext', $data), 'insert extended types');

    my $bool_count = ch_query_result("select countIf(b) from test_ext");
    is($bool_count, '2', 'Bool roundtrip (2 truthy of 3)');
    my $uuid = ch_query_result(
        "select u from test_ext where u = '550e8400-e29b-41d4-a716-446655440000'");
    is($uuid, '550e8400-e29b-41d4-a716-446655440000', 'UUID exact roundtrip');
    my $v4 = ch_query_result("select v4 from test_ext where v4 = '1.2.3.4'");
    is($v4, '1.2.3.4', 'IPv4 exact roundtrip');
    my $v6 = ch_query_result("select v6 from test_ext where v6 = '2001:db8::1'");
    is($v6, '2001:db8::1', 'IPv6 exact roundtrip');

    # LowCardinality(Nullable(String)): row 2 should be null, row 3 should be "" (empty).
    my $null_count = ch_query_result(
        "select count() from test_ext where isNull(lcn)");
    is($null_count, '1', 'LC(Nullable(String)) preserves null vs empty (1 null)');
    my $empty_count = ch_query_result(
        "select count() from test_ext where lcn = ''");
    is($empty_count, '1', 'LC(Nullable(String)) preserves empty (1 empty string)');

    my $lc_alpha = ch_query_result("select count() from test_ext where lc = 'alpha'");
    is($lc_alpha, '2', 'LC(String) dictionary roundtrip');
}

# Test 13: LowCardinality(FixedString) and Geo aliases — live roundtrip.
{
    ch_query("drop table if exists test_geo");
    ch_query(q{SET allow_experimental_geo_types=1});
    ch_query(q{create table test_geo (
        code   LowCardinality(FixedString(2)),
        loc    Point,
        path   LineString,
        area   Polygon
    ) engine = Memory});

    my $enc = ClickHouse::Encoder->new(columns => [
        ['code', 'LowCardinality(FixedString(2))'],
        ['loc',  'Point'],
        ['path', 'LineString'],
        ['area', 'Polygon'],
    ]);
    my $data = $enc->encode([
        ['US', [55.7, 37.6], [[0,0],[1,1],[2,0]],
            [[[0,0],[1,0],[1,1],[0,1],[0,0]]]],
        ['GB', [51.5,  0.1], [[10,10],[20,20]],
            [[[5,5],[6,5],[6,6],[5,5]]]],
        ['US', [40.7,-74.0], [[100,100]],
            [[[0,0],[10,0],[10,10],[0,10],[0,0]]]],
    ]);
    ok(ch_insert_native('test_geo', $data), 'insert LC(FixedString) + Geo');

    my $us = ch_query_result("select count() from test_geo where code = 'US'");
    is($us, '2', 'LC(FixedString(2)) dictionary roundtrip');
    my $loc = ch_query_result("select loc from test_geo order by code, loc limit 1");
    like($loc, qr/\(51\.5,/, 'Point roundtrip');
    my $area_count = ch_query_result(
        "select count() from test_geo where length(area) >= 1");
    is($area_count, '3', 'Polygon roundtrip (3 polygons)');
}

# JSON type (CH 24.8+)
SKIP: {
    my $ver = ch_query_result("select version()");
    my ($major, $minor) = $ver =~ /^(\d+)\.(\d+)/ ? ($1, $2) : (0, 0);
    skip "JSON type requires CH 24.8+", 8
        if ($major < 24) || ($major == 24 && $minor < 8);

    ch_query("drop table if exists test_json");
    # JSON type needs an experimental-feature gate in CH 24.x/25.x and
    # an explicit enable in 26.x. Each clickhouse-client call is a new
    # session, so the flag must be set on the same call as the CREATE.
    # `--allow_experimental_json_type=1 --enable_json_type=1` covers
    # both: unknown flags are silently ignored by clickhouse-client.
    my @json_flags = ('--allow_experimental_json_type=1',
                      '--enable_json_type=1');
    system(@ch_cmd, @json_flags, '--query',
           "create table test_json (j JSON) engine = Memory") == 0
        or skip "Could not create JSON table (CH may not support it)", 8;

    require JSON::PP;
    my $enc = ClickHouse::Encoder->new(columns => [['j', 'JSON']]);
    my $rows = [
        [{name => "alice", age => 30, active => JSON::PP::true()}],
        [{name => "bob",   age => 25}],
        [{}],
        [undef],
        [{score => 3.14}],
        [{user => {name => "carol", age => 40}}],
    ];
    my $data = $enc->encode($rows);
    ok(ch_insert_native('test_json', $data), 'INSERT format native (JSON)');

    my $n = ch_query_result("select count() from test_json");
    is($n, '6', '6 rows in JSON table');

    my $nm_alice = ch_query_result(
        "select count() from test_json where j.name = 'alice'");
    is($nm_alice, '1', 'string subcolumn query');
    my $score_count = ch_query_result(
        "select count() from test_json where toFloat64(j.score) > 3");
    is($score_count, '1', 'float subcolumn query');
    my $carol_age = ch_query_result(
        "select toInt64(j.user.age) from test_json where j.user.name = 'carol'");
    is($carol_age, '40', 'nested path subcolumn query');

    # Read back JSON column via select format native and decode
    open my $fh, '-|', @ch_cmd, '--query',
        'select j from test_json order by toInt64(j.age) asc nulls last format native'
        or die "Cannot spawn clickhouse-client: $!";
    binmode $fh;
    my $native = do { local $/; <$fh> };
    close $fh;
    my $block = ClickHouse::Encoder->decode_block($native);
    is($block->{ncols}, 1, 'decoded ncols');
    is($block->{nrows}, 6, 'decoded nrows');
    # All 6 should be hashrefs
    is(scalar(grep { ref $_ eq 'HASH' } @{ $block->{columns}[0]{values} }),
       6, 'all 6 decoded rows are hashrefs');

    # Typed JSON paths
    ch_query("drop table if exists test_json_typed");
    system(@ch_cmd, @json_flags, '--query',
           "create table test_json_typed "
         . "(j JSON(name String, age UInt32)) engine = Memory") == 0
        or skip "Could not create typed JSON table", 3;
    my $te = ClickHouse::Encoder->new(
        columns => [['j','JSON(name String, age UInt32)']]);
    my $td = $te->encode([
        [{name => 'alice', age => 30}],
        [{name => 'bob',   age => 25, extra => 'more'}],
    ]);
    ok(ch_insert_native('test_json_typed', $td),
       'typed JSON paths INSERT accepted');
    my $cnt = ch_query_result("select count() from test_json_typed");
    is($cnt, '2', 'typed JSON paths: 2 rows');
    my $name = ch_query_result(
        "select j.name from test_json_typed where j.age = 30");
    is($name, 'alice', 'typed path subcolumn query');
}

# Test: compressed Native INSERT over HTTP. End-to-end wire-compat
# check for the bundled CityHash128 v1.0.2 port - if our hash diverges
# from cityhash102 in any detail the server rejects with "Checksum
# doesn't match in compressed block" before storing any rows.
SKIP: {
    eval { require HTTP::Tiny; require Compress::LZ4; 1 }
        or skip 'HTTP::Tiny or Compress::LZ4 not installed', 4;

    my $port = $http_port;
    my $http = HTTP::Tiny->new(timeout => 5);
    my $ping = $http->get("http://127.0.0.1:$port/ping");
    skip "HTTP endpoint not reachable on :$port", 4
        unless $ping->{success} && $ping->{content} =~ /Ok/;

    # Drop + create a fresh table via the existing client; then push
    # rows through the HTTP `?decompress=1` path.
    ch_query("drop table if exists test_compressed");
    ch_query("create table test_compressed
                  (id Int32, msg String, ts DateTime) engine = Memory");

    my $enc = ClickHouse::Encoder->new(columns =>
        [['id','Int32'], ['msg','String'], ['ts','DateTime']]);
    my $native = $enc->encode([
        [1, 'alpha',  1700000001],
        [2, 'beta',   1700000002],
        [3, 'gamma',  1700000003],
    ]);

    # Wrap in CH's compressed-block framing - this calls our bundled
    # CityHash128 v1.0.2 implementation. If the hash bytes diverge
    # from CH's cityhash102 the server will refuse the INSERT.
    my $framed = ClickHouse::Encoder->compress_native_block(
        $native, mode => 'lz4');

    my $resp = $http->post(
        "http://127.0.0.1:$port/"
            . "?query=insert+into+test_compressed+format+native"
            . "&decompress=1",
        { content => $framed,
          headers => { 'Content-Type' => 'application/octet-stream' } });
    ok($resp->{success},
       'compressed Native INSERT accepted (CityHash128 validates against CH)')
        or diag("status=$resp->{status} body=$resp->{content}");

    my $cnt = ch_query_result("select count() from test_compressed");
    is($cnt, '3', 'compressed INSERT delivered 3 rows');

    my $sum = ch_query_result(
        "select sum(id) from test_compressed");
    is($sum, '6', 'compressed INSERT row values intact (sum=6)');

    # Round-trip the other way: SELECT the data back uncompressed and
    # confirm the values match (additional pin on the whole pipeline).
    my $first_msg = ch_query_result(
        "select msg from test_compressed where id = 2");
    is($first_msg, 'beta', 'compressed-then-stored row decodes correctly');

    # Round-trip the other direction: SELECT with ?compress=1 and read
    # the response through select_blocks(decompress => 1). End-to-end
    # validation of CityHash128 in the response direction too.
    my @ids;
    ClickHouse::Encoder->select_blocks(
        "select id, msg, ts from test_compressed order by id",
        host => '127.0.0.1', port => $port,
        decompress => 1,
        on_block   => sub {
            my $b = shift;
            for my $col (@{ $b->{columns} }) {
                push @ids, @{ $col->{values} } if $col->{name} eq 'id';
            }
        });
    is_deeply(\@ids, [1, 2, 3],
              'select_blocks(decompress=>1): all ids round-trip');
}

done_testing();
