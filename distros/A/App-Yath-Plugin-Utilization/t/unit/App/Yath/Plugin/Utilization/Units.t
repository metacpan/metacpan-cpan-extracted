use Test2::V0;
use App::Yath::Plugin::Utilization::Units qw/parse_quantity parse_byte_size parse_duration parse_count_or_pct parse_size_or_pct/;

subtest parse_quantity => sub {
    is([parse_quantity('512mb', units => [qw/kb mb gb tb/])], [512, 'mb'], 'basic');
    is([parse_quantity('  1.5 GB ', units => [qw/kb mb gb tb/])], [1.5, 'gb'], 'whitespace + case');
    is([parse_quantity('42', units => [qw/s m/], default_unit => 's')], [42, 's'], 'default unit');

    like(dies { parse_quantity('5xy', units => [qw/kb mb/]) }, qr/invalid value '5xy'/, 'bad unit');
    like(dies { parse_quantity('42', units => [qw/kb mb/]) }, qr/unit required/, 'missing unit no default');
    like(dies { parse_quantity(undef, units => [qw/kb/]) }, qr/value is required/, 'undef');
};

subtest parse_byte_size => sub {
    is(parse_byte_size('1kb'), 1024, 'kb');
    is(parse_byte_size('2MB'), 2 * 1024**2, 'mb');
    is(parse_byte_size('1gb'), 1024**3, 'gb');
    is(parse_byte_size('1.5gb'), int(1.5 * 1024**3), 'fractional');
    like(dies { parse_byte_size('0kb') }, qr/must be > 0/, 'zero rejected');
    like(dies { parse_byte_size('5') }, qr/unit required/, 'bare rejected by default');
    is(parse_byte_size('5', default_unit => 'mb'), 5 * 1024**2, 'default unit honored');
};

subtest parse_duration => sub {
    is(parse_duration('500ms'), 0.5, 'ms');
    is(parse_duration('2s'), 2, 's');
    is(parse_duration('2'), 2, 'bare default s');
    is(parse_duration('3m'), 180, 'm');
    like(dies { parse_duration('0s') }, qr/must be > 0/, 'zero rejected');
};

subtest parse_count_or_pct => sub {
    is(parse_count_or_pct('5'), {kind => 'count', value => 5}, 'bare count');
    is(parse_count_or_pct('10%'), {kind => 'pct', value => 10}, 'pct');
    like(dies { parse_count_or_pct('0') }, qr/count must be > 0/, 'zero count');
    like(dies { parse_count_or_pct('0%') }, qr/pct must be > 0/, 'zero pct');
    like(dies { parse_count_or_pct('100%') }, qr/pct must be > 0 and < 100/, '100 pct');
    like(dies { parse_count_or_pct('1.5') }, qr/unit required/, 'fractional bare');
    like(dies { parse_count_or_pct('5mb') }, qr/invalid count '5mb'/, 'bad unit');
};

subtest parse_size_or_pct => sub {
    is(parse_size_or_pct('25%'), {kind => 'pct', value => 25}, 'pct');
    is(parse_size_or_pct('512mb'), {kind => 'bytes', value => 512 * 1024**2}, 'bytes');
    like(dies { parse_size_or_pct('25') }, qr/expected NUMBER\[kb\|mb\|gb\|tb\|%\]/, 'bare rejected by default');
    is(parse_size_or_pct('25', default_unit => '%'), {kind => 'pct', value => 25}, 'default unit pct');
    like(dies { parse_size_or_pct('0%') }, qr/pct must be > 0/, 'zero pct');
    like(dies { parse_size_or_pct('100%') }, qr/pct must be > 0 and < 100/, '100 pct');
    like(dies { parse_size_or_pct('0mb') }, qr/must be > 0/, 'zero size');
};

done_testing;
