use strict;
use warnings;
use Test::More;
use IPC::Open3;
use Symbol qw(gensym);
use JSON::PP qw(decode_json);
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
my ($reachable, $version) = eval { query('select version()') };
plan skip_all => 'ClickHouse not reachable on the configured native port' unless $reachable;
my ($major, $minor) = $version =~ /^(\d+)\.(\d+)/;
my $version_num = $major * 100 + $minor;
my $tag = "che_defaults_$$";
my @tables;
END { eval { query("drop table if exists $_") for @tables } }

for my $type ('UInt8', 'Int64', 'Float64', 'BFloat16', 'String', 'FixedString(2)',
              q{Enum8('a'=7,'b'=-5)}, 'Decimal64(3)', 'Date', 'Date32', 'DateTime',
              'DateTime64(3)', 'Bool', 'UUID', 'IPv4', 'IPv6', 'Array(UInt8)',
              'Map(String, UInt8)', 'Tuple(UInt8, String, Nullable(UInt8), Array(UInt8))',
              'LowCardinality(String)', 'LowCardinality(UInt32)', 'Variant(String, UInt64)',
              'Dynamic', 'JSON', 'JSON(x Date32, y Tuple(Nullable(UInt8), Date32))') {
    subtest "$type matches server defaults and empty CSV" => sub {
        plan skip_all => 'requires ClickHouse 24.11+' if $type eq 'BFloat16' && $version_num < 2411;
        plan skip_all => 'requires ClickHouse 24.1+' if $type =~ /^Variant/ && $version_num < 2401;
        plan skip_all => 'requires ClickHouse 24.8+' if $type =~ /^(?:Dynamic|JSON)/ && $version_num < 2408;
        my @flags = $type =~ /^Variant/ ? ('--allow_experimental_variant_type=1')
                  : $type =~ /^Dynamic/ ? ('--allow_experimental_dynamic_type=1')
                  : $type =~ /^JSON/ ? ('--allow_experimental_json_type=1') : ();
        my $table = "${tag}_type";
        my $lit = $type;
        $lit =~ s/([\\'])/\\$1/g;
        push @tables, $table unless @tables;
        query("drop table if exists $table");
        # An empty CSV cell stores day 0 for Date32, not defaultValueOfTypeName's 1900-01-01.
        my $csv_default = $type eq 'Date32';
        my $dflt = $csv_default ? '' : " default defaultValueOfTypeName('$lit')";
        my ($ok, undef, $error) = query("create table $table (v $type$dflt, k UInt8) engine = Memory", undef, @flags);
        ok($ok, 'table created') or diag $error;
        return unless $ok;
        my $enc = ClickHouse::Encoder->new(columns => [[v => $type], [k => 'UInt8']], empty_as_default => 1);
        my $bytes = eval { $enc->encode([[undef, 1], ['', 2]]) };
        is($@, '', 'empty values encode');
        return unless defined $bytes;
        ($ok, undef, $error) = query("insert into $table format Native", $bytes, @flags);
        ok($ok, 'Native insert') or diag $error;
        ($ok, undef, $error) = query("insert into $table format CSV", ",3\n", @flags,
                                    '--input_format_csv_empty_as_default=1', '--input_format_defaults_for_omitted_fields=1');
        ok($ok, 'empty CSV insert') or diag $error;
        my (undef, $want, $err) = query("select toString(defaultValueOfTypeName('$lit'))", undef, @flags);
        is($err, '', 'server type default available');
        $want = "1970-01-01\n" if $csv_default;
        my (undef, $values) = query("select toString(v) from $table order by k", undef, @flags);
        is($values, $want x 3, 'Native undef/empty and CSV agree on the type default');
    };
}

subtest 'table defaults insert with async_insert' => sub {
    my $table = "${tag}_async";
    push @tables, $table;
    my ($ok, undef, $error) = query("create table $table (k UInt8, n Int32 default cast(-12, 'Int32'), "
        . "s String default 'fallback', a Array(UInt8) default [1], "
        . "t Tuple(UInt8, String) default (7, 'x'), lc LowCardinality(String) default 'category', "
        . "d Decimal64(3) default cast('1.234', 'Decimal64(3)')) engine = MergeTree order by k");
    ok($ok, 'table created') or diag $error;
    return unless $ok;
    my (undef, $schema) = query("select name, type, default_kind, default_expression from system.columns "
        . "where database = currentDatabase() and table = '$table' order by position format JSONEachRow");
    my @rows = map { decode_json($_) } split /\n/, $schema;
    my $enc = eval { ClickHouse::Encoder->from_columns(\@rows, empty_as_default => 1) };
    is($@, '', 'table schema and literal defaults accepted');
    return unless $enc;
    my $bytes = eval { $enc->encode([[1, (undef) x 6]]) };
    is($@, '', 'own table types encode client defaults');
    return unless defined $bytes;
    my %http = (host => $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1',
                port => $ENV{TEST_CLICKHOUSE_PORT} || 18151,
                settings => {async_insert => 1, wait_for_async_insert => 1});
    my ($url, $headers) = ClickHouse::Encoder::_http_url_headers("insert into $table format Native", %http);
    my $response = ClickHouse::Encoder::_http_tiny(%http)->post($url, {headers => $headers, content => $bytes});
    ok($response->{success}, 'raw async Native insert waits successfully') or diag $response->{content};
    ($ok, undef, $error) = query("insert into $table format CSV", "2,,,,,,\n",
                                '--input_format_csv_empty_as_default=1', '--input_format_defaults_for_omitted_fields=1');
    ok($ok, 'CSV fills declared defaults') or diag $error;
    my (undef, $values) = query("select n, s, a, t, lc, d from $table order by k format TSV");
    my @values = split /\n/, $values;
    is(scalar @values, 2, 'both inserts stored');
    is($values[0], $values[1], 'client defaults match CSV defaults');
};

done_testing;
