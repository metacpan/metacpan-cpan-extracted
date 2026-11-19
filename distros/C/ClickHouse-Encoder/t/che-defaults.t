use strict;
use warnings;
use Test::More;
use Tie::Hash;
use ClickHouse::Encoder;

sub matches {
    my ($columns, $rows, $expected, $label, @opts) = @_;
    my $enc = ClickHouse::Encoder->new(columns => $columns, @opts);
    my $plain = ClickHouse::Encoder->new(columns => $columns, empty_as_null => 1);
    my $want = $plain->encode($expected);
    my $got = eval { $enc->encode($rows) };
    is($@, '', "$label: rows accepted");
    is($got, $want, "$label: row bytes");
    my %cols = map { my $c = $_; $columns->[$c][0] => [map { $_->[$c] } @$rows] } 0 .. $#$columns;
    $got = eval { $enc->encode_columns(\%cols) };
    is($@, '', "$label: columns accepted");
    is($got, $want, "$label: column bytes");
}

matches([[n => 'UInt32'], [s => 'String'], [f => 'FixedString(3)'],
         [e => q{Enum8('seven' = 7, 'first' = -4)}], [d => 'Decimal64(3)'],
         [t => 'DateTime'], [a => 'Array(UInt8)'], [m => 'Map(String, UInt8)']],
        [[undef, undef, undef, '', '', '', undef, ''],
         ['', '', '', undef, undef, undef, '', undef]],
        [[12, 'fallback', 'abc', 'seven', '1.234', 1700000000, [9], [['x', 2]]],
         [12, '', '', 'seven', '1.234', 1700000000, [9], [['x', 2]]]],
        'explicit defaults use normal encoders', defaults => {
            n => 12, s => 'fallback', f => 'abc', e => 'seven', d => '1.234',
            t => '2023-11-14T22:13:20Z', a => [9], m => [['x', 2]],
        });

my @types = ('UInt8', 'Int64', 'Float64', 'BFloat16', 'String', 'FixedString(2)',
             q{Enum16('later' = 7, 'first' = -5)}, 'Decimal256(4)', 'Date', 'Date32',
             'DateTime', 'DateTime64(3)', 'Bool', 'UUID', 'IPv4', 'IPv6',
             'Array(UInt8)', 'Map(String, UInt8)', 'Tuple(UInt8, String, Nullable(UInt8), Array(UInt8))',
             'LowCardinality(String)', 'LowCardinality(UInt32)', 'Variant(String, UInt64)', 'Dynamic', 'JSON');
my @values = (0, 0, 0, 0, '', '', -5, '0', 0, 0, 0, 0, 0,
              '00000000-0000-0000-0000-000000000000', '0.0.0.0', '::', [], [], [0, '', undef, []], '', 0, undef, undef, {});
my @columns = map { ["c$_", $types[$_]] } 0 .. $#types;
matches(\@columns, [[(undef) x @types], [('') x @types]], [\@values, \@values],
        'recursive type defaults', empty_as_default => 1);

matches([[n => 'UInt8'], [s => 'String']], [[undef, undef]], [[9, '']],
        'explicit overrides type default', empty_as_default => 1, defaults => {n => 9});
matches([[n => 'Nullable(UInt8)'], [s => 'Nullable(String)'],
         [lc => 'LowCardinality(Nullable(UInt8))']], [[undef, undef, undef], ['', '', '']],
        [[undef, undef, undef], [undef, '', undef]], 'Nullable keeps NULL rules',
        empty_as_default => 1, empty_as_null => 1, defaults => {n => 8, s => 'x', lc => 8});
matches([[a => 'Array(UInt8)'], [m => 'Map(String, UInt8)'],
         [t => 'Tuple(Array(UInt8), Map(String, UInt8))']],
        [[undef, '', [undef, '']], ['', undef, ['', undef]]],
        [[[], [], [[], []]], [[], [], [[], []]]], 'empty containers including Tuple elements');
matches([[a => 'Array(LowCardinality(String))'], [m => 'Map(String, Array(UInt8))']],
        [[undef, ''], [['x'], {key => undef}], ['', [['key', [1]]]]],
        [[[], []], [['x'], {key => []}], [[], [['key', [1]]]]],
        'empty and populated containers share offsets and prefixes');
matches([[j => 'JSON(x Date32, y Tuple(Nullable(UInt8), Date32))']],
        [[undef], ['']], [[{x => 0, y => [undef, 0]}], [{x => 0, y => [undef, 0]}]],
        'typed JSON recursive defaults', empty_as_default => 1);

{
    my $name = "caf\x{e9}";
    utf8::upgrade($name);
    matches([[$name => 'UInt8']], [[undef]], [[9]], 'Unicode default name', defaults => {$name => 9});
}

for my $opts ({defaults => []}, {defaults => undef}, {defaults => {missing => 1}}) {
    eval { ClickHouse::Encoder->new(columns => [[n => 'UInt8']], %$opts) };
    like($@, qr/defaults.*(?:hashref|missing)/, 'invalid defaults rejected at construction');
}

subtest 'tied defaults are copied at construction' => sub {
    tie my %defaults, 'Tie::StdHash';
    %defaults = (n => 7, s => 'fallback', a => [4]);
    my @columns = ([n => 'UInt8'], [s => 'String'], [a => 'Array(UInt8)']);
    my $enc = ClickHouse::Encoder->new(columns => \@columns, defaults => \%defaults, empty_as_default => 1);
    my $want = ClickHouse::Encoder->new(columns => \@columns)->encode([[7, 'fallback', [4]]]);
    $defaults{n} = 99;
    my $got = eval { $enc->encode([[(undef) x 3]]) };
    is($@, '', 'tied values accepted');
    is($got, $want, 'tied values override type defaults and scalar values are captured at new');
    is($enc->encode_columns({n => [undef], s => [undef], a => [undef]}), $want, 'column path uses tied defaults');
    my $named_only = ClickHouse::Encoder->new(columns => [[n => 'UInt8']], defaults => do {
        tie my %one, 'Tie::StdHash'; $one{n} = 8; \%one;
    });
    is($named_only->encode([[undef]]), ClickHouse::Encoder->new(columns => [[n => 'UInt8']])->encode([[8]]),
       'tied defaults work without empty_as_default');
    $defaults{missing} = 1;
    eval { ClickHouse::Encoder->new(columns => \@columns, defaults => \%defaults) };
    like($@, qr/defaults key.*missing.*matches no column/, 'unknown tied key rejected at construction');
    tie my %partial, 'Tie::StdHash';
    $partial{n} = 7;
    my @partial_columns = ([n => 'UInt8'], [t => 'Tuple(UInt8, String)']);
    my $partial = ClickHouse::Encoder->new(columns => \@partial_columns,
        defaults => \%partial, empty_as_default => 1);
    $got = eval { $partial->encode([[undef, undef]]) };
    is($@, '', 'absent tied key retains type-default fallback');
    is($got, ClickHouse::Encoder->new(columns => \@partial_columns)->encode([[7, [0, '']]]),
       'absent tied key is not an explicit undef override');
    my $override = ClickHouse::Encoder->from_columns([[n => 'UInt8', 'DEFAULT', 'n + 100']],
        empty_as_default => 1, defaults => do {
            tie my %one, 'Tie::StdHash'; $one{n} = 0; \%one;
        });
    is($override->encode([[undef]]), ClickHouse::Encoder->new(columns => [[n => 'UInt8']])->encode([[0]]),
       'tied caller override resolves a non-literal expression');
};

my $nested = ClickHouse::Encoder->new(columns => [[a => q{Array(Enum8('x' = 1))}]],
                                    empty_as_default => 1, defaults => {a => [1]});
eval { $nested->encode([[['']]]) };
like($@, qr/[Ee]num/, 'column defaults do not replace empty array elements');
my $many = ClickHouse::Encoder->new(columns => [map { ["a$_", 'Array(UInt8)'] } 1 .. 35],
                                  defaults => {map { ("a$_", [$_]) } 1 .. 35});
my $bytes = eval { $many->encode([[(undef) x 35]]) };
is($@, '', 'defaults survive more than two gather groups');
is_deeply($bytes && ClickHouse::Encoder->decode_block($bytes)->{columns}[34]{values}, [[35]], 'last gather group default');

{
    package CHE::StringObject;
    use overload '""' => sub { 'okay' }, fallback => 1;
    package CHE::PlainObject;
}
for my $type ('String', 'FixedString(4)', 'Nullable(String)', 'LowCardinality(String)',
              'LowCardinality(Nullable(FixedString(4)))') {
    my $enc = ClickHouse::Encoder->new(columns => [[v => $type]]);
    for my $value ([], {}, \1, bless({}, 'CHE::PlainObject')) {
        eval { $enc->encode([[$value]]) };
        like($@, qr/(?:String|FixedString).*reference/, "$type rejects references without string overload");
        eval { $enc->encode_columns({v => [$value]}) };
        like($@, qr/(?:String|FixedString).*reference/, "$type column path rejects reference");
    }
    my $got = eval { $enc->encode([[bless({}, 'CHE::StringObject')]]) };
    is($@, '', "$type permits string overload");
    is($got, $enc->encode([['okay']]), "$type overload value");
}

done_testing;
