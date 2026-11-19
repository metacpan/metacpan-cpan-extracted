use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);
use ClickHouse::Encoder;

my @client = ('clickhouse-client', '--host', $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1',
              '--port', $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 19031,
              '--allow_suspicious_low_cardinality_types=1');
sub query {
    my ($sql, $input, @flags) = @_;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, @client, @flags, '--query', $sql);
    binmode $in;
    print $in $input if defined $input;
    close $in;
    local $/;
    my $text = <$out> // '';
    my $error = <$err> // '';
    waitpid $pid, 0;
    return ($? == 0, $text, $error);
}
my ($reachable) = eval { query('select 1') };
plan skip_all => 'ClickHouse not reachable on the configured native port' unless $reachable;
my $tzdata = eval { ClickHouse::Encoder->new(timezone => 'Europe/Moscow', columns => []) } ? 1 : 0;
my $tag = "che_release_$$";
my @tables;
END { eval { query("drop table if exists $_") for @tables } }
sub create_pair {
    my ($schema) = @_;
    for my $suffix (qw(native tsv)) {
        my $table = "${tag}_$suffix";
        query("drop table if exists $table");
        my ($ok, undef, $error) = query("create table $table ($schema) engine = Memory");
        die $error unless $ok;
        push @tables, $table;
    }
}
sub selected {
    my ($suffix, $expr) = @_;
    my ($ok, $text, $error) = query("select $expr from ${tag}_$suffix format TSV");
    die $error unless $ok;
    return $text;
}

subtest 'timezones match text input' => sub {
    plan skip_all => 'system timezone database not found' unless $tzdata;
    for my $case (
        ['Europe/Berlin', '2026-03-29 02:30:00', 1774744200],
        ['Europe/Berlin', '2026-10-25 02:30:00', 1792888200],
        ['Europe/Berlin', '2050-07-10 12:30:00'],
        ['Europe/Berlin', '2050-01-10 12:30:00'],
        ['America/New_York', '2090-07-10 12:30:00'],
        ['Australia/Lord_Howe', '2026-10-04 02:15:00'],
        ['Australia/Lord_Howe', '2026-04-05 01:45:00'],
        ['Pacific/Chatham', '2090-01-10 12:30:00'],
        ['Europe/Dublin', '2050-07-10 12:30:00'],
        ['Europe/Moscow', '2026-11-17 22:00:00'],
    ) {
        my ($zone, $wall, $expected) = @$case;
        my $type = "DateTime('$zone')";
        create_pair("v $type, w DateTime64(3, '$zone')");
        my $enc = ClickHouse::Encoder->new(columns => [[v => $type], [w => "DateTime64(3, '$zone')"]]);
        my ($ok, undef, $error) = query("insert into ${tag}_native format Native",
                                      $enc->encode([[$wall, "$wall.123"]]));
        ok($ok, "$zone $wall Native insert") or diag $error;
        ($ok, undef, $error) = query("insert into ${tag}_tsv format TSV", "$wall\t$wall.123\n");
        ok($ok, 'TSV oracle insert') or diag $error;
        my $expr = 'toUnixTimestamp(v), toUnixTimestamp64Milli(w)';
        is(selected('native', $expr), selected('tsv', $expr), 'same stored instants');
        if (defined $expected) {
            my ($yes, $text) = query("select toUnixTimestamp(toDateTime('$wall', '$zone'))");
            is($text, "$expected\n", 'toDateTime agrees with TSV for gap/fold');
        }
    }
    create_pair('v DateTime, w DateTime64(3)');
    my $enc = ClickHouse::Encoder->new(timezone => 'Europe/Moscow',
        columns => [[v => 'DateTime'], [w => 'DateTime64(3)']]);
    my $wall = '2026-11-17 22:00:00';
    my ($ok) = query("insert into ${tag}_native format Native", $enc->encode([[$wall, "$wall.123"]]));
    ok($ok, 'timezone option Native insert');
    query("insert into ${tag}_tsv format TSV", "$wall\t$wall.123\n");
    is(selected('native', 'toUnixTimestamp(v), toUnixTimestamp64Milli(w)'),
       selected('tsv', 'toUnixTimestamp(v), toUnixTimestamp64Milli(w)'), 'option matches server timezone');
};

subtest 'decimal TSV grammar and exact values' => sub {
    for my $width (32, 64, 128, 256) {
        my $type = "Decimal$width(6)";
        my $precision = $width == 32 ? 9 : $width == 64 ? 18 : $width == 128 ? 38 : 76;
        create_pair("v $type");
        my $enc = ClickHouse::Encoder->new(columns => [[v => $type]]);
        for my $value ('2.9e-05', '1.e2', '.5e1', '1E+2', '-123e-8', '0e2',
                       '1e-999999999', '0e999', '1e999999999', '1e+', '1e2x',
                       '0e' . ($precision - 6), '0e' . ($precision - 5),
                       '9' x ($precision - 6) . '.999999', '-' . '9' x ($precision - 6),
                       '1' . '0' x ($precision - 6), '-1' . '0' x ($precision - 6) . '.5',
                       '1e' . ($precision - 6)) {
            query("truncate table ${tag}_native");
            query("truncate table ${tag}_tsv");
            my $bytes = eval { $enc->encode([[$value]]) };
            my $encoded = !$@;
            my ($tsv_ok) = query("insert into ${tag}_tsv format TSV", "$value\n");
            is($encoded, $tsv_ok, "$type $value acceptance matches TSV");
            if ($encoded && $tsv_ok) {
                my ($ok, undef, $error) = query("insert into ${tag}_native format Native", $bytes);
                ok($ok, 'Native insert accepted') or diag $error;
                is(selected('native', 'v'), selected('tsv', 'v'), 'exact decimal matches TSV');
            }
        }
    }
};

subtest 'declared precision and time shapes match TSV' => sub {
    my @cases = (
        ['Decimal(9, 2)', '1e7', '9999999.99', '9999999.999', '-9999999.99', '10000000',
                          '-10000000', '10000000.001', 9999999.99, 1e7],
        ['Decimal(38, 0)', '9' x 38, '1' . '0' x 38],
        ['Decimal(76, 0)', '9' x 76, '1' . '0' x 76],
        [q{DateTime('UTC')}, '2024-03-31 02:30', '2024-03-31T02:30', '2024-03-31 02:30Z',
                     '2024-03-31 02:30:00', '2024-03-31 02:30:00x'],
    );
    for my $case (@cases) {
        my ($type, @values) = @$case;
        create_pair("v $type");
        my $enc = ClickHouse::Encoder->new(columns => [[v => $type]]);
        for my $value (@values) {
            query("truncate table ${tag}_native");
            query("truncate table ${tag}_tsv");
            my $bytes = eval { $enc->encode([[$value]]) };
            my ($tsv_ok) = query("insert into ${tag}_tsv format TSV", "$value\n");
            is(defined $bytes ? 1 : 0, $tsv_ok ? 1 : 0, "$type $value acceptance matches TSV");
            next unless defined $bytes && $tsv_ok;
            query("insert into ${tag}_native format Native", $bytes);
            is(selected('native', 'toString(v)'), selected('tsv', 'toString(v)'), 'same stored value');
        }
    }
};

subtest 'enum and IPv6 text coercion' => sub {
    my $type = q{Enum8('a' = -5, 'b' = 1, '51' = 7)};
    create_pair("v $type, ip IPv6");
    my $enc = ClickHouse::Encoder->new(columns => [[v => $type], [ip => 'IPv6']]);
    my $bytes = eval { $enc->encode([['-5', '1.2.3.4'], ['1', '127.0.0.1'], ['51', '::1']]) };
    is($@, '', 'string codes and dotted IPv4 accepted');
    my ($ok, undef, $error) = query("insert into ${tag}_native format Native", $bytes // '');
    ok($ok, 'Native enum/IP insert') or diag $error;
    ($ok, undef, $error) = query("insert into ${tag}_tsv format TSV", "-5\t1.2.3.4\n1\t127.0.0.1\n51\t::1\n");
    ok($ok, 'TSV enum/IP insert') or diag $error;
    is(selected('native', 'v, ip'), selected('tsv', 'v, ip'), 'label precedence and mapped IP match TSV');
};

subtest 'enum labels and declared codes' => sub {
    for my $width (8, 16) {
        my $type = "Enum$width('a' = 1, '1' = 2, 'minus' = -5, 'zero' = 0)";
        create_pair("v $type");
        my $enc = ClickHouse::Encoder->new(columns => [[v => $type]]);
        my @values = (1, '1', 'a', 2, '2', -5, '-5', 0, 'zero');
        my ($ok, undef, $error) = query("insert into ${tag}_native format Native",
                                      $enc->encode([map { [$_] } @values]));
        ok($ok, "Enum$width Native insert") or diag $error;
        ($ok, undef, $error) = query("insert into ${tag}_tsv format TSV", join('', map { "$_\n" } @values));
        ok($ok, 'TSV enum oracle') or diag $error;
        is(selected('native', 'toInt16(v), v'), selected('tsv', 'toInt16(v), v'),
           'numeric input gives the same label precedence as TSV');
        for my $value (5, -6) {
            eval { $enc->encode([[$value]]) };
            like($@, qr/Enum.*undeclared/, 'undeclared code rejected before Native insert');
            ($ok) = query("insert into ${tag}_tsv format TSV", "$value\n");
            ok(!$ok, 'server rejects undeclared TSV code');
        }
        {
            my $wrapped = "Nullable(Enum$width('a' = 1, '1' = 2))";
            create_pair("v $wrapped");
            $enc = ClickHouse::Encoder->new(columns => [[v => $wrapped]]);
            ($ok, undef, $error) = query("insert into ${tag}_native format Native",
                                       $enc->encode([[undef], ['a'], ['1']]));
            ok($ok, "$wrapped accepts NULL sentinel") or diag $error;
            ($ok, undef, $error) = query("insert into ${tag}_tsv format TSV", "\\N\na\n1\n");
            ok($ok, 'TSV nullable enum oracle') or diag $error;
            is(selected('native', 'v'), selected('tsv', 'v'), 'nullable enum reads remain valid');
        }
    }
};

subtest 'NULL applies real server defaults' => sub {
    my $table = "${tag}_defaults";
    push @tables, $table;
    my ($ok, undef, $error) = query("create table $table (n UInt8, d Int32 default -3, "
        . "e UInt32 default n + 100, ts DateTime default now(), s String default 'dflt') engine = Memory");
    die $error unless $ok;
    my $enc = ClickHouse::Encoder->new(empty_as_null => 1, columns => [
        [n => 'UInt8'], [d => 'Nullable(Int32)'], [e => 'Nullable(UInt32)'],
        [ts => 'Nullable(DateTime)'], [s => 'Nullable(String)']]);
    my $bytes = eval { $enc->encode([[1, '', '', '', undef]]) };
    is($@, '', 'empty strings encode as NULL for server defaults');
    return unless defined $bytes;
    ($ok, undef, $error) = query("insert into $table format Native",
        $bytes, '--input_format_null_as_default=1');
    ok($ok, 'Nullable Native insert with empty_as_null') or diag $error;
    my (undef, $text) = query("select n, d, e, abs(dateDiff('second', ts, now())) < 10, s from $table format TSV");
    is($text, "1\t-3\t101\t1\tdflt\n", 'constant, dependent expression, now(), and String defaults evaluated');
    my $lc = "${tag}_lc";
    push @tables, $lc;
    ($ok, undef, $error) = query("create table $lc (v LowCardinality(Nullable(UInt8))) engine = Memory");
    die $error unless $ok;
    $enc = ClickHouse::Encoder->new(empty_as_null => 1,
        columns => [[v => 'LowCardinality(Nullable(UInt8))']]);
    ($ok, undef, $error) = query("insert into $lc format Native", $enc->encode([[''], [0], [7], [undef], [7]]));
    ok($ok, 'numeric LowCardinality nullable Native insert') or diag $error;
    (undef, $text) = query("select v from $lc format TSV");
    is($text, "\\N\n0\n7\n\\N\n7\n", 'NULL and numeric dictionary entries are distinct');
    my ($discovered, $block);
    if ($tzdata) {
        $discovered = ClickHouse::Encoder->for_table($table, port => $client[4], empty_as_null => 1,
                                                     timezone => 'Europe/Moscow');
        $block = ClickHouse::Encoder->decode_block(
            $discovered->encode([[1, -3, 101, '2026-11-17 22:00:00', 'dflt']]));
        is($block->{columns}[3]{values}[0], 1794942000, 'for_table forwards timezone');
    }
    $discovered = ClickHouse::Encoder->for_table($lc, port => $client[4], empty_as_null => 1,
                                                 timezone => undef);
    $block = ClickHouse::Encoder->decode_block($discovered->encode([['']]));
    is_deeply($block->{columns}[0]{values}, [undef], 'for_table forwards empty_as_null');
};

done_testing;
