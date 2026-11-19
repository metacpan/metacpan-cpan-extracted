use strict;
use warnings;
use Test::More;
use ClickHouse::Encoder;

my $tzdata = eval { ClickHouse::Encoder->new(timezone => 'Europe/Moscow', columns => []) } ? 1 : 0;

sub values_for {
    my ($type, $values, @opts) = @_;
    my $enc = ClickHouse::Encoder->new(columns => [[v => $type]], @opts);
    return ClickHouse::Encoder->decode_block($enc->encode([map { [$_] } @$values]))
        ->{columns}[0]{values};
}

subtest 'empty_as_null' => sub {
    for my $type ('Nullable(UInt8)', 'Nullable(IPv4)', 'Nullable(DateTime)',
                  'Nullable(Decimal64(2))', 'LowCardinality(Nullable(UInt8))') {
        my $got = eval { values_for($type, ['', undef], empty_as_null => 1) };
        is($@, '', "$type accepts empty strings");
        is_deeply($got, [undef, undef], "$type stores NULL");
    }
    is_deeply(values_for('Nullable(String)', ['', undef], empty_as_null => 1),
              ['', undef], 'String preserves empty');
    is_deeply(values_for('Nullable(FixedString(2))', ['', undef], empty_as_null => 1),
              ["\0\0", undef], 'FixedString preserves empty');
    for my $case (
        ['Array(Nullable(UInt8))', [['', 3]], [[undef, 3]]],
        ['Tuple(Nullable(UInt8), Nullable(String))', [['', '']], [[undef, '']]],
        ['Map(String, Nullable(UInt8))', [[['k', '']]], [[['k', undef]]]],
    ) {
        my $got = eval { values_for($case->[0], $case->[1], empty_as_null => 1) };
        is($@, '', "$case->[0] accepts nested empty");
        is_deeply($got, $case->[2], 'nested NULL');
    }
    eval { values_for('Nullable(UInt8)', ['']) };
    like($@, qr/out of range/, 'option defaults off');
    eval { values_for('UInt8', [''], empty_as_null => 1) };
    like($@, qr/out of range/, 'non-Nullable unchanged');
};

subtest 'enum text codes' => sub {
    for my $width (8, 16) {
        my $type = "Enum$width('a' = -5, 'b' = 1, '51' = 7)";
        my $got = eval { values_for($type, ['-5', '+1', '51']) };
        is($@, '', "Enum$width accepts codes");
        is_deeply($got, [-5, 1, 7], 'labels precede integer strings');
        for my $bad ('999999999999999999999999', '-999999999999999999999') {
            eval { values_for($type, [$bad]) };
            like($@, qr/out of range/, 'huge code rejected');
        }
        eval { values_for($type, ['1.0']) };
        like($@, qr/Unknown enum/, 'fraction is not an integer code');
    }
};

subtest 'decimal exponents' => sub {
    for my $width (32, 64, 128, 256) {
        my $type = "Decimal$width(6)";
        my $precision = $width == 32 ? 9 : $width == 64 ? 18 : $width == 128 ? 38 : 76;
        my $enc = ClickHouse::Encoder->new(columns => [[v => $type]]);
        for my $pair (['2.9e-05', '0.000029'], ['1.e2', '100'],
                      ['.5e1', '5'], ['1E+2', '100'], ['-123e-8', '-0.000001'],
                      ['0e2', '0'], ['1e-999', '0']) {
            my $got = eval { $enc->encode([[$pair->[0]]]) };
            is($@, '', "$type accepts $pair->[0]");
            is($got, $enc->encode([[$pair->[1]]]), 'exact shifted digits');
        }
        if ($width > 32) {
            my $got = eval { $enc->encode([['9007199254740993e-6']]) };
            is($@, '', 'exponent mantissa above 2^53 accepted');
            is($got, $enc->encode([['9007199254.740993']]), 'no floating-point rounding');
        }
        for my $bad ('1e999999999', '0e999', '0e999999999', '1e', '1e+', '1e2x',
                     '0e' . ($precision - 5)) {
            eval { $enc->encode([[$bad]]) };
            like($@, qr/decimal|Decimal/, "$type rejects $bad");
        }
    }
    my $enc = ClickHouse::Encoder->new(columns => [[v => 'Decimal(7, 6)']]);
    is(eval { $enc->encode([['.5e1']]) }, $enc->encode([['5']]), 'declared precision exponent limit');
    eval { $enc->encode([['0e2']]) };
    like($@, qr/decimal/, 'zero exponent respects declared precision');
};

subtest 'IPv4 in IPv6' => sub {
    my $got = eval { values_for('IPv6', ['1.2.3.4']) };
    is($@, '', 'dotted IPv4 accepted');
    is_deeply($got, [("\0" x 10) . "\xff\xff\x01\x02\x03\x04"], 'mapped address');
};

subtest 'declared decimal precision' => sub {
    for my $case (
        ['Decimal(9, 2)', ['9999999.99', '-9999999.99', '9999999.999', 9999999.99, '99999.99e2'],
                          ['1e7', '10000000', '-10000000', '10000000.001', 1e7, -1e7, '100000.001e2']],
        ['Decimal(18, 4)', ['9' x 14, '-' . '9' x 14 . '.9999'], ['1' . '0' x 14, 1e14]],
        ['Decimal(38, 0)', ['9' x 38, '-' . '9' x 38], ['1' . '0' x 38, '-1' . '0' x 38, 2e38]],
        ['Decimal(76, 2)', ['9' x 74 . '.99'], ['1' . '0' x 74, '-1' . '0' x 74, 2e74]],
        ['Decimal32(2)', ['9999999.99'], ['10000000']],
    ) {
        my ($type, $good, $bad) = @$case;
        my $enc = ClickHouse::Encoder->new(columns => [[v => $type]]);
        for my $value (@$good) {
            ok(defined eval { $enc->encode([[$value]]) }, "$type accepts $value") or diag $@;
        }
        for my $value (@$bad) {
            eval { $enc->encode([[$value]]) };
            like($@, qr/Decimal\d+ overflow/, "$type rejects $value");
        }
    }
};

subtest 'encode_row_binary uses encoder options' => sub {
    my $enc = ClickHouse::Encoder->new(empty_as_null => 1,
        columns => [[n => 'Nullable(UInt8)'], [s => 'Nullable(String)'], [a => 'Array(Nullable(Int32))']]);
    my $rb = eval { $enc->encode_row_binary([['', '', ['', 5]], [7, 'x', []]]) };
    is($@, '', 'empty strings accepted');
    is($rb, "\x01" . "\x00\x00" . "\x02\x01\x00\x05\x00\x00\x00"
          . "\x00\x07" . "\x00\x01x" . "\x00", 'empty_as_null applies to RowBinary');
    is_deeply($enc->decode_row_binary($rb // ''), [[undef, '', [undef, 5]], [7, 'x', []]], 'round trip');
    SKIP: {
        skip 'system timezone database not found', 2 unless $tzdata;
        my $tz = ClickHouse::Encoder->new(timezone => 'Europe/Moscow',
            columns => [[v => 'DateTime'], [w => 'Nullable(DateTime64(3))']]);
        my $row = ['2026-11-17 22:00:00', '2026-11-17 22:00:00.5'];
        is(unpack('V', $tz->encode_row_binary([$row])), 1794942000, 'RowBinary uses the timezone option');
        my $native = ClickHouse::Encoder->decode_block($tz->encode([$row]));
        is_deeply($tz->decode_row_binary($tz->encode_row_binary([$row])),
                  [[map { $_->{values}[0] } @{$native->{columns}}]], 'RowBinary matches Native');
    }
};

subtest 'helper encoder options' => sub {
    plan skip_all => 'system timezone database not found' unless $tzdata;
    my @schema = ([v => 'Nullable(UInt8)'], [ts => 'DateTime']);
    my $bulk = ClickHouse::Encoder->bulk_inserter(table => 'che_options', columns => \@schema,
        empty_as_null => 1, timezone => 'Europe/Moscow');
    my $bytes = eval { $bulk->{enc}->encode([['', '2026-11-17 22:00:00']]) };
    is($@, '', 'bulk_inserter passes encoder options');
    my $block = $bytes ? ClickHouse::Encoder->decode_block($bytes) : undef;
    is_deeply($block && [map { $_->{values}[0] } @{$block->{columns}}],
              [undef, 1794942000], 'bulk options take effect');
    {
        package CHE::HTTP;
        sub post { return { success => 1, content => $_[2]{content} } }
    }
    no warnings 'redefine';
    local *ClickHouse::Encoder::_http_tiny = sub { bless {}, 'CHE::HTTP' };
    my $response = eval { ClickHouse::Encoder->insert_http(table => 'che_options', columns => \@schema,
        rows => [['', '2026-11-17 22:00:00']], empty_as_null => 1, timezone => 'Europe/Moscow') };
    is($@, '', 'insert_http passes encoder options');
    is($response && $response->{content}, $bytes, 'HTTP helper encodes using both options');
    my $enc = ClickHouse::Encoder->new(columns => \@schema, empty_as_null => 1, timezone => 'Europe/Moscow');
    my $streamed;
    my $st = $enc->streamer(sub { $streamed = $_[0] });
    eval { $st->push_row(['', '2026-11-17 22:00:00']); $st->finish };
    is($@, '', 'streamer uses configured encoder');
    is($streamed, $bytes, 'streamed values use both options');
};

done_testing;
