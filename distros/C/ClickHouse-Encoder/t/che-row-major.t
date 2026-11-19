use strict;
use warnings;
use utf8;
use Test::More;
use Digest::SHA qw(sha1_hex);
use ClickHouse::Encoder;

my @cases = (
    ['Int8', [-128, 127, undef]], ['UInt8', [0, 255, undef]],
    ['Int16', [-32768, 32767, 0]], ['UInt16', [65535, 1, 0]],
    ['Int32', [-2147483648, 2147483647, 0]], ['UInt32', [4294967295, 2, 0]],
    ['Int64', ['-9223372036854775808', '9223372036854775807', 0]],
    ['UInt64', ['18446744073709551615', 3, 0]],
    ['Float32', [1.25, -3.5, 0]], ['Float64', [-0.25, 2**100, 0]],
    ['BFloat16', [1.5, -2, 0]], ['Bool', [1, 0, undef]],
    ['String', ["a\0b", 'Привет', undef]], ['FixedString(5)', ['abc', 'longer than five', '']],
    [q{Enum8('zero' = 0, 'one' = 1, 'neg' = -5)}, [0, 'one', '-5']],
    [q{Enum16('zero' = 0, 'high' = 1000)}, ['high', 0, undef]],
    ['Decimal32(4)', ['-1.23456', '.5e1', '0']],
    ['Decimal64(6)', ['9007199254.740993', '2.9e-5', '0']],
    ['Decimal128(6)', ['12345678901234567890.123456', '-.000001', '0']],
    ['Decimal256(6)', ['1234567890123456789012345678901234567890.123456', '-1e-6', '0']],
    ['Date', ['2026-11-17', 0, undef]], ['Date32', ['1900-01-01', -1, 0]],
    [q{DateTime('Europe/Moscow')}, ['2026-11-17 22:00:00', '2026-11-17T22:00:00Z', 0]],
    [q{DateTime64(6, 'Europe/Berlin')}, ['2050-07-10 12:30:00.123456', -1, 0]],
    ['UUID', ['550e8400-e29b-41d4-a716-446655440000', "\0" x 16, undef]],
    ['IPv4', ['1.2.3.4', 0, undef]], ['IPv6', ['1.2.3.4', '2001:db8::1', undef]],
    ['Nullable(UInt32)', [undef, 9, 0]], ['Nullable(String)', [undef, '', 'x']],
    ['Nullable(FixedString(3))', ['', undef, 'xy']],
    ['Nullable(Decimal64(6))', [undef, '0.123456', '-2']],
    [q{Nullable(Enum8('one' = 1))}, [undef, 'one', 1]],
    ['Array(UInt32)', [[1, 2], [], [3]]],
    ['Array(LowCardinality(Nullable(String)))', [['x', undef, ''], [], ['y']]],
    ['Tuple(UInt32, String)', [[1, 'x'], [2, 'y'], [0, '']]],
    ['Map(String, Nullable(UInt8))', [[['x', 1]], [['y', undef]], []]],
    ['LowCardinality(String)', ['x', 'y', 'x']],
    ['LowCardinality(Nullable(UInt8))', [undef, 0, 7]],
    ['Variant(UInt32, String)', [[0, 42], [1, 'hi'], undef]],
    ['JSON', [{x => 1}, {x => 'text'}, {}]],
    ['Dynamic', [1, 'x', undef]],
    ['Nullable(Tuple(UInt32, String))', [undef, [1, 'x'], [0, '']]],
);
my $tzdata = eval { ClickHouse::Encoder->new(timezone => 'Europe/Moscow', columns => []) } ? 1 : 0;
@cases = grep { $_->[0] !~ /Europe/ } @cases unless $tzdata;
my @columns = map { ["c$_", $cases[$_][0]] } 0 .. $#cases;
my @rows = map { my $r = $_; [map { $cases[$_][1][$r] } 0 .. $#cases] } 0 .. 2;
my %columns = map { my $c = $_; ("c$c" => [map { $_->[$c] } @rows]) } 0 .. $#cases;
my $enc = ClickHouse::Encoder->new(columns => \@columns);
my $bytes = $enc->encode(\@rows);
is($bytes, $enc->encode_columns(\%columns), 'all types: row and column bytes match');
SKIP: {
    skip 'system timezone database not found', 1 unless $tzdata;
    is(sha1_hex($bytes), '77723eb4d605bc3458b2c54d3986dd005408a4a8', 'mixed bytes match pre-change output');
}

my $nullable = ClickHouse::Encoder->new(empty_as_null => 1, columns => [
    [n => 'Nullable(UInt32)'], [s => 'Nullable(String)'],
    [f => 'Nullable(FixedString(3))'], [d => 'Nullable(Decimal128(6))'],
    [a => 'Array(Nullable(UInt32))'], [t => 'Tuple(Nullable(UInt32), String)'],
]);
my $null_rows = [['', '', '', '', ['', 2], ['', 'x']],
                 [undef, undef, undef, undef, [undef], [undef, '']],
                 [7, 'x', 'ab', '1.234567', [], [3, 'y']]];
my %null_cols;
my @names = qw(n s f d a t);
for my $c (0 .. $#names) { $null_cols{$names[$c]} = [map { $_->[$c] } @$null_rows] }
my $null_bytes = $nullable->encode($null_rows);
is($null_bytes, $nullable->encode_columns(\%null_cols), 'empty_as_null bytes match column path');
is(sha1_hex($null_bytes), 'f0fc3774db4de2540e4dbb8e7f96a025e06fa8b4', 'nullable bytes match pre-change output');
my @wide = map { ['unused', reverse @$_] } @rows;
my @positions = reverse 1 .. scalar(@columns);
is($enc->encode(\@wide, positions => \@positions), $bytes, 'projection preserves every column body');
is($enc->encode([]), $enc->encode_columns({map { $_->[0] => [] } @columns}), 'empty block bytes match');

{
    package CHE::RowArray;
    sub TIEARRAY { bless { values => $_[1], fetches => [] }, $_[0] }
    sub FETCH { push @{$_[0]{fetches}}, $_[1]; $_[0]{values}[$_[1]] }
    sub FETCHSIZE { scalar @{$_[0]{values}} }
}
my (@tied, @objects);
for my $row (@rows) {
    tie my @r, 'CHE::RowArray', $row;
    push @objects, tied @r;
    push @tied, \@r;
}
tie my @outer, 'CHE::RowArray', \@tied;
is($enc->encode(\@outer), $bytes, 'tied outer and inner rows preserve bytes');
for my $object (@objects) {
    is_deeply([sort {$a <=> $b} @{$object->{fetches}}], [0 .. $#columns], 'each tied row position fetched once');
}

{
    package CHE::RowCell;
    sub TIESCALAR { bless { value => $_[1], tag => $_[2], log => $_[3] }, $_[0] }
    sub FETCH { push @{$_[0]{log}}, $_[0]{tag}; $_[0]{value} }
}
my (@magic, @log);
my $simple = ClickHouse::Encoder->new(columns => [map { ["n$_", 'UInt32'] } 0 .. 32]);
for my $r (0 .. 2) {
    my @row;
    for my $c (0 .. 32) { tie $row[$c], 'CHE::RowCell', 100 * $r + $c, "$r:$c", \@log }
    push @magic, \@row;
}
my $magic_bytes = $simple->encode(\@magic);
is($magic_bytes, $simple->encode([map { my $r = $_; [map { 100 * $r + $_ } 0 .. 32] } 0 .. 2]),
   'tied cells preserve encoded bytes');
my @expected = map { my $r = $_; map { ("$r:$_") x 2 } 0 .. 32 } 0 .. 2;
is_deeply(\@log, \@expected, 'scalar cells are consumed in row order with existing FETCH counts');

my @complex_columns = map { ["a$_", 'Array(UInt8)'] } 0 .. 39;
my $complex = ClickHouse::Encoder->new(columns => \@complex_columns);
my @complex_rows = map { my $r = $_; [map { [$r, $_] } 0 .. 39] } 0 .. 2;
my %complex_cols = map { my $c = $_; ("a$c" => [map { $_->[$c] } @complex_rows]) } 0 .. 39;
is($complex->encode(\@complex_rows), $complex->encode_columns(\%complex_cols), 'more than one group of complex columns');
my @complex_tied;
my @complex_positions = reverse 1 .. 40;
for my $row (@complex_rows) {
    my @wide = ('unused', reverse @$row);
    tie my @r, 'CHE::RowArray', \@wide;
    push @complex_tied, \@r;
}
is($complex->encode(\@complex_tied, positions => \@complex_positions), $complex->encode(\@complex_rows),
   'tied projection works across deferred complex groups');
for my $row (@complex_tied) {
    is_deeply([sort {$a <=> $b} @{(tied @$row)->{fetches}}], [1 .. 40],
              'each deferred tied row position fetched once');
}

{
    package CHE::Shrink;
    use overload '""' => sub { my $s = shift; if (my $row = delete $s->{row}) { @$row = (); my @x = map { [9] } 1 .. 50 } 'x' },
                 fallback => 1;
}
{
    my @shrinking = (['a', [1, 2]], ['b', [3]]);
    push @shrinking, [bless({ row => $shrinking[0] }, 'CHE::Shrink'), [4]];
    my $enc = ClickHouse::Encoder->new(columns => [[s => 'String'], [a => 'Array(UInt8)']]);
    my $got = eval { ClickHouse::Encoder->decode_block($enc->encode(\@shrinking)) };
    is($@, '', 'callback emptying an earlier row does not invalidate gathered cells');
    is_deeply($got && $got->{columns}[1]{values}, [[1, 2], [3], [4]], 'gathered cells keep their values');
}

done_testing;
