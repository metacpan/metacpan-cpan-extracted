use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;
use TestCH qw(read_varint);

# Test basic types
{
    my $enc = ClickHouse::Encoder->new(
        columns => [
            ['a', 'UInt32'],
            ['b', 'String'],
        ],
    );

    my $bin = $enc->encode([[1, 'hello'], [2, 'world']]);
    ok(defined $bin, 'encode returns data');
    ok(length($bin) > 0, 'encoded data not empty');

    # Check structure: 2 columns, 2 rows
    my ($ncols, $off) = read_varint($bin, 0);
    is($ncols, 2, 'num columns');
    my ($nrows, $off2) = read_varint($bin, $off);
    is($nrows, 2, 'num rows');
}

# Test Array
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['tags', 'Array(String)']],
    );

    my $bin = $enc->encode([[['a', 'b']], [['c']]]);
    ok(defined $bin, 'array encode works');
}

# Test Tuple
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['point', 'Tuple(Float64, Float64)']],
    );

    my $bin = $enc->encode([[[1.5, 2.5]], [[3.0, 4.0]]]);
    ok(defined $bin, 'tuple encode works');
}

# Test Nullable
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['val', 'Nullable(Int32)']],
    );

    my $bin = $enc->encode([[42], [undef], [100]]);
    ok(defined $bin, 'nullable encode works');
}

# Test nested Array(Tuple(...))
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['data', 'Array(Tuple(String, UInt32))']],
    );

    my $bin = $enc->encode([[[['foo', 1], ['bar', 2]]]]);
    ok(defined $bin, 'nested array of tuples works');
}

# Test columns() accessor
{
    my $enc = ClickHouse::Encoder->new(
        columns => [
            ['id',   'UInt32'],
            ['name', 'String'],
        ],
    );

    my $cols = $enc->columns;
    is(ref($cols), 'ARRAY', 'columns returns arrayref');
    is(scalar @$cols, 2, 'columns count');
    is($cols->[0][0], 'id', 'first column name');
    is($cols->[0][1], 'UInt32', 'first column type');
    is($cols->[1][0], 'name', 'second column name');
    is($cols->[1][1], 'String', 'second column type');
}

done_testing();
