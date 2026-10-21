use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use JSON::PP ();
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

my @cases = (
    ['LowCardinality(String)', [['x'], ['y'], ['x']], ['x','y','x']],
    ['Array(LowCardinality(String))', [[['x','y']], [[]], [['x']]], [['x','y'],[],['x']]],
    ['Array(Array(LowCardinality(String)))', [[[['x'],['y']]], [[[]]]], [[['x'],['y']],[[]]]],
    ['Tuple(String, LowCardinality(String))', [[['s1','a']], [['s2','b']]], [['s1','a'],['s2','b']]],
    ['Map(LowCardinality(String), LowCardinality(String))', [[[['k','v']]], [[]]], [{k=>'v'},{}]],
    ['Array(LowCardinality(Nullable(String)))', [[['x',undef]], [[]]], [['x',undef],[]]],
    ['Array(Variant(String, UInt8))', [[[[0,'x'],[1,5]]], [[]]], [['x',5],[]]],
    ['Tuple(String, Variant(String, UInt8))', [[['s',[0,'x']]], [['t',[1,5]]]], [['s','x'],['t',5]]],
    ['Array(JSON)', [[[ {a=>1}, {b=>'x'} ]], [[]]], [[{a=>1},{b=>'x'}],[]]],
    ['Tuple(UInt8, Dynamic)', [[[1,'x']], [[2,3]]], [[1,'x'],[2,3]]],
    ['Array(Dynamic)', [[[1,'x']], [[]]], [[1,'x'],[]]],
    ['Array(LowCardinality(String))', [[[]], [[]]], [[],[]]],
    ['Array(Variant(String, UInt8))', [[[]], [[]]], [[],[]]],
    ['Array(JSON)', [[[]], [[]]], [[],[]]],
    ['Variant(Decimal32(0), Decimal64(0))', [[[0,'7']], [[1,'9']]], [7,9]],
    ['JSON(`z` UInt8, a UInt8)', [[{a=>3,z=>7}]], [{a=>3,z=>7}]],

    ['Tuple()', [[[]], [[]]], [[],[]]],
);
for my $c (@cases) {
    my ($type, $rows) = @$c;
    my $e = ClickHouse::Encoder->new(columns => [['c',$type]]);
    my $b = $e->encode($rows);
    my $got = eval { $e->decode_rows($b) };
    ok($got, "$type decodes") or diag $@;
    is_deeply($got->{rows}, $rows, "$type values round-trip");
    is($got->{consumed}, length($b), "$type fully consumed");
    my $empty = $e->encode([]);
    my $zero = $e->decode_block($empty);
    is($zero->{consumed}, length($empty), "$type empty block fully consumed");
    is($zero->{nrows}, 0, "$type empty row count");
}
{
    my $golden = pack('H*', '010301631d4172726179284c6f7743617264696e616c69747928537472696e67292901000000000000000200000000000000020000000000000003000000000000000006000000000000030000000000000000017801790300000000000000010201');
    is_deeply(ClickHouse::Encoder->decode_rows($golden)->{rows}, [[['x','y']],[[]],[['x']]], 'ClickHouse nested LC fixture decodes');
}
SKIP: {
    my $local = `command -v clickhouse-local 2>/dev/null`; chomp $local;
    skip 'clickhouse-local unavailable', 2 * scalar @cases unless $local;
    my ($major, $minor) = `$local --version` =~ /(\d+)\.(\d+)/;
    skip 'ClickHouse 24.8+ required', 2 * scalar @cases
        unless defined $major && ($major > 24 || ($major == 24 && $minor >= 8));
    my $dir = tempdir('che-native-XXXXXX', TMPDIR => 1, CLEANUP => 1);
    for my $i (0 .. $#cases) {
        my ($type, $rows, $expected) = @{$cases[$i]};
        my $e = ClickHouse::Encoder->new(columns => [['c',$type]]);
        my $path = "$dir/input.native";
        open my $fh, '>:raw', $path or die $!;
        print $fh $e->encode([]), $e->encode($rows);
        close $fh;
        open my $pipe, '-|', $local, '--path', "$dir/state-$i", '--allow_experimental_json_type', 1, '--query',
            "select c from file('$path', 'Native') format JSONEachRow" or die $!;
        my @got;
        while (my $line = <$pipe>) { push @got, JSON::PP::decode_json($line)->{c} }
        close $pipe;
        is_deeply(\@got, $expected, "ClickHouse accepts $type") or diag "status=$?";
        open my $native, '-|', $local, '--path', "$dir/read-$i", '--allow_experimental_json_type', 1, '--query',
            "select c from file('$path', 'Native') format Native" or die $!;
        my $bytes = do { local $/; <$native> };
        close $native or die "ClickHouse Native output failed: $?";
        my $want = $type =~ /^Variant\(Decimal/ ? [[[1,7]], [[0,9]]] : $rows;
        is_deeply(ClickHouse::Encoder->decode_rows($bytes)->{rows}, $want,
            "module decodes ClickHouse $type");
    }
}
done_testing();
