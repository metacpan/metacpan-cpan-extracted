use strict;
use warnings;
use Test::More;
use ClickHouse::Encoder;

my @rows = (
    [n => 'Int64', 'DEFAULT', '-12'],
    {name => 's', type => 'String', default_kind => 'DEFAULT', default_expression => q{'a\n\x42\0\t\'z'}},
    [a => 'Array(Int32)', 'DEFAULT', '[1]'],
    [t => 'Tuple(Int32, String)', 'DEFAULT', q{(-2, 'it''s')}],
    [c => 'UInt16', 'DEFAULT', q{cast(42, 'UInt16')}],
    [p => 'UInt32', 'DEFAULT', q{0xFF::UInt32}],
    [d => 'Decimal128(6)', 'DEFAULT', q{cast('12345678901234567890.123456', 'Decimal128(6)')}],
    [b => 'Array(Tuple(UInt8, String))', 'DEFAULT', q{[(true, 'yes'), (false, 'no')]::Array(Tuple(UInt8, String))}],
    [x => 'UInt8', 'DEFAULT', 'n + 1'],
    [m => 'UInt8', 'MATERIALIZED', '1'], [alias => 'UInt8', 'ALIAS', '1'],
    [e => 'UInt8', 'EPHEMERAL', '1'],
);
my $enc = eval { ClickHouse::Encoder->from_columns(\@rows, empty_as_default => 1, defaults => {x => 7, c => 99}) };
is($@, '', 'from_columns accepts mixed system.columns row shapes');
SKIP: {
    skip 'from_columns unavailable', 4 unless $enc;
    is_deeply($enc->columns, [map { [ref($_) eq 'HASH' ? @$_{qw(name type)} : @$_[0, 1]] } @rows[0 .. 8]], 'computed columns omitted');
    my $expected = ClickHouse::Encoder->new(columns => $enc->columns)->encode([
        [-12, "a\nB\0\t'z", [1], [-2, "it's"], 99, 255, '12345678901234567890.123456', [[1, 'yes'], [0, 'no']], 7],
    ]);
    my $got = eval { $enc->encode([[(undef) x 9]]) };
    is($@, '', 'literal defaults encode');
    is($got, $expected, 'literals, casts and caller overrides retain values');
    is_deeply($rows[2], [a => 'Array(Int32)', 'DEFAULT', '[1]'], 'schema input unmodified');
}

for my $expr (q{now()}, q{1 + 2}, q{'x' garbage}, q{[1,]}, q{cast(n, 'UInt8')},
              q{cast(1, 'UInt8') + 1}, q{[1, n]}, q{'unterminated}, q{1::UInt8 garbage}) {
    my $e = eval { ClickHouse::Encoder->from_columns([[n => 'UInt8', 'DEFAULT', $expr]]) };
    is($@, '', "$expr: construction accepts unresolved expression");
    next unless $e;
    is($e->encode([[undef]]), ClickHouse::Encoder->new(columns => [[n => 'UInt8']])->encode([[undef]]),
       "$expr: unresolved default left to caller");
    is($e->encode([[3]]), ClickHouse::Encoder->new(columns => [[n => 'UInt8']])->encode([[3]]), 'nonempty needs no default');
}
for my $case (
    ['Array(Int32)', '[]', []], ['Array(Int32)', '[1, -2, +3]', [1, -2, 3]],
    ['Int64', '(-0x2A)', -42], ['Float64', '1.25e+2', 125],
    ['Nullable(UInt8)', 'null', undef], ['UInt8', 'true', 1],
    ['UInt8', q{cast((7) as UInt8)}, 7], ['UInt8', q{cast(cast(7, 'UInt16'), 'UInt8')}, 7],
    ['UInt64', '18446744073709551615', '18446744073709551615'],
) {
    my ($type, $expr, $expected) = @$case;
    my $e = eval { ClickHouse::Encoder->from_columns([[v => $type, 'DEFAULT', $expr]]) };
    my $got = $e && eval { $e->encode([[undef]]) };
    is($@, '', "$expr: accepted");
    is($got, ClickHouse::Encoder->new(columns => [[v => $type]])->encode([[$expected]]), "$expr: literal value");
}
for my $bad (undef, {}, [undef], [[]], [{name => 'x'}]) {
    eval { ClickHouse::Encoder->from_columns($bad) };
    like($@, qr/from_columns/, 'malformed schema rejected');
}

subtest 'non-literal defaults fail only when needed' => sub {
    my @schema = (
        [n => 'UInt32', 'DEFAULT', 'n + 100'],
        [t => 'DateTime', 'DEFAULT', 'now()'],
        [d => 'Date32', 'DEFAULT', q{toDate('2026-11-18')}],
        [s => 'String', 'DEFAULT', "concat('a', 'b')"],
        [a => 'Array(UInt8)', 'DEFAULT', 'range(3)'],
        [m => 'Map(String, UInt8)', 'DEFAULT', "map('x', 1)"],
        [tuple => 'Tuple(UInt8, String)', 'DEFAULT', "tuple(n, 'x')"],
        [lc => 'LowCardinality(String)', 'DEFAULT', "concat('c', 'd')"],
    );
    my @values = (7, 1700000000, 1, '', [], [], [1, 'x'], '');
    my @columns = map { [@$_[0, 1]] } @schema;
    my $plain = ClickHouse::Encoder->new(columns => \@columns);
    my $enc = ClickHouse::Encoder->from_columns(\@schema, empty_as_default => 1);
    my $expected = $plain->encode([\@values]);
    my $got = eval { $enc->encode([\@values]) };
    is($@, '', 'nonempty rows do not evaluate expressions');
    is($got, $expected, 'nonempty row bytes unchanged');
    $got = eval { $enc->encode_columns({map { $schema[$_][0] => [$values[$_]] } 0 .. $#schema}) };
    is($@, '', 'nonempty columns do not evaluate expressions');
    is($got, $expected, 'nonempty column bytes unchanged');
    is($enc->encode([]), $plain->encode([]), 'empty block does not need defaults');

    for my $c (0 .. $#schema) {
        my ($name, $type, undef, $expr) = @{$schema[$c]};
        for my $empty (undef, '') {
            next if defined $empty && $type =~ /\A(?:String|LowCardinality\(String\))\z/;
            my @row = @values;
            $row[$c] = $empty;
            my $error = qr/\Q$name\E.*\Q$expr\E.*defaults\s*=>/s;
            eval { $enc->encode([\@row]) };
            like($@, $error, "$name: row error identifies expression and override");
            eval { $enc->encode_columns({map { $schema[$_][0] => [$row[$_]] } 0 .. $#schema}) };
            like($@, $error, "$name: column error identifies expression and override");
        }
    }

    my $override = ClickHouse::Encoder->from_columns(\@schema, empty_as_default => 1,
        defaults => {map { $schema[$_][0] => $values[$_] } 0 .. $#schema});
    is($override->encode([[(undef) x @schema]]), $expected, 'caller defaults override unresolved expressions');
    my $undef_override = ClickHouse::Encoder->from_columns([$schema[0]], empty_as_default => 1, defaults => {n => undef});
    is($undef_override->encode([[undef]]), ClickHouse::Encoder->new(columns => [$columns[0]])->encode([[undef]]),
       'explicit undef override counts as an entry');
    my $nullable = ClickHouse::Encoder->from_columns(
        [[v => 'Nullable(UInt8)', 'DEFAULT', 'n + 100'],
         [lc => 'LowCardinality(Nullable(UInt8))', 'DEFAULT', 'n + 100']],
        empty_as_default => 1, empty_as_null => 1);
    is($nullable->encode([[undef, '']]), $nullable->encode([[undef, undef]]), 'Nullable retains NULL rules');
    eval { $enc->encode([[]], positions => [0 .. $#schema]) };
    like($@, qr/n.*n \+ 100.*defaults\s*=>/s, 'missing projected position needs an override');
    is($enc->encode([\@values]), $expected, 'encoder is reusable after default errors');
};

subtest 'unresolved defaults across gather groups' => sub {
    my @schema = map { ["a$_", 'Array(UInt8)', 'DEFAULT', 'range(3)'] } 1 .. 35;
    my $enc = ClickHouse::Encoder->from_columns(\@schema, empty_as_default => 1);
    my @row = map { [] } @schema;
    $row[-1] = undef;
    eval { $enc->encode([\@row]) };
    like($@, qr/a35.*range\(3\).*defaults\s*=>/s, 'later gather group checks its own unresolved expression');
};

done_testing;
