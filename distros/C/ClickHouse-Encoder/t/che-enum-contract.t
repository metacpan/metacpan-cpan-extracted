use strict;
use warnings;
use Test::More;
use ClickHouse::Encoder;

sub encoded_value {
    my ($type, $value) = @_;
    my $enc = ClickHouse::Encoder->new(columns => [[v => $type]]);
    return ClickHouse::Encoder->decode_block($enc->encode([[$value]]))->{columns}[0]{values}[0];
}

for my $width (8, 16) {
    my $type = "Enum$width('a' = 1, '1' = 2, '-5' = 3, 'zero' = 0)";
    for my $case ([1, 2], ['1', 2], [1.0, 2], [-5, 3], ['-5', 3],
                  ['a', 1], ['+1', 1], [2, 2], [0, 0], [undef, 0]) {
        my $got = eval { encoded_value($type, $case->[0]) };
        is($@, '', "Enum$width accepts declared value");
        is($got, $case->[1], 'labels precede numeric codes');
    }
    for my $bad (5, '5', -1, '-1', '999999999999999999999',
                  unpack('Q', pack('Q', -1))) {
        eval { encoded_value($type, $bad) };
        like($@, qr/enum.*(?:undeclared|unknown|range)/i, "Enum$width rejects undeclared or overflowing code");
    }
    $type = "Enum$width('one' = 1, 'negative' = -5)";
    is(encoded_value($type, -5), -5, 'numeric code without integer labels');
    is(encoded_value($type, undef), -5, 'undef is the type default, the smallest declared code');
    is(encoded_value("Nullable($type)", undef), undef, 'Nullable enum NULL bypasses code validation');
    eval { encoded_value($type, 0) };
    like($@, qr/enum.*(?:undeclared|unknown)/i, 'explicit undeclared zero is rejected');
    my $nullable = ClickHouse::Encoder->new(empty_as_null => 1, columns => [[v => "Nullable($type)"]]);
    my $block = ClickHouse::Encoder->decode_block($nullable->encode([[''], ['one'], [undef]]));
    is_deeply($block->{columns}[0]{values}, [undef, 1, undef], 'empty_as_null bypasses enum validation');
    my $lc = ClickHouse::Encoder->new(columns => [[v => "LowCardinality(Nullable($type))"]]);
    $block = ClickHouse::Encoder->decode_block($lc->encode([[undef], ['one'], [-5]]));
    is_deeply($block->{columns}[0]{values}, [undef, 1, -5], 'LowCardinality NULL sentinel is not an input code');
    for my $wrapped ('Array', 'Tuple', 'LowCardinality') {
        my $nested = ClickHouse::Encoder->new(columns => [[v => "$wrapped($type)"]]);
        my $input = $wrapped eq 'LowCardinality' ? 5 : [5];
        eval { $nested->encode([[$input]]) };
        like($@, qr/enum.*undeclared/i, 'nested enum codes validated');
    }
    my $tuple = ClickHouse::Encoder->new(columns => [[v => "Nullable(Tuple($type, UInt8))"]]);
    $block = ClickHouse::Encoder->decode_block($tuple->encode([[undef], [['one', 7]]]));
    is_deeply($block->{columns}[0]{values}, [undef, [1, 7]], 'recursive NULL placeholder bypasses input validation');
}

done_testing;
