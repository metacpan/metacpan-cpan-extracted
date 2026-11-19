use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::Local qw(timegm);
use ClickHouse::Encoder;

my $tzdata = eval { ClickHouse::Encoder->new(timezone => 'Europe/Moscow', columns => []) } ? 1 : 0;

sub epoch {
    my ($type, $value, @opts) = @_;
    my $enc = ClickHouse::Encoder->new(columns => [[v => $type]], @opts);
    return ClickHouse::Encoder->decode_block($enc->encode([[$value]]))->{columns}[0]{values}[0];
}

SKIP: {
    skip 'system timezone database not found', 7 unless $tzdata;
    is(epoch(q{DateTime('Europe/Moscow')}, '2026-11-17 22:00:00'), 1794942000, 'column wall time');
    is(epoch('DateTime', '2026-11-17 22:00:00', timezone => 'Europe/Moscow'), 1794942000, 'default timezone option');
    is(epoch(q{DateTime64(3, 'Europe/Moscow')}, '2026-11-17 22:00:00.123'), 1794942000123, 'fractional wall time');
    is(epoch(q{DateTime('Europe/Berlin')}, '2026-03-29 02:30:00'), 1774744200, 'DST gap moves backwards');
    is(epoch(q{DateTime('Europe/Berlin')}, '2026-10-25 02:30:00'), 1792888200, 'DST fold chooses first');
    is(epoch(q{DateTime('Europe/Moscow')}, '2026-11-17'), 1794862800, 'date-only wall time');
    "zone=Europe/Moscow" =~ /=(.+)/;
    is(epoch('DateTime', '2026-11-17 22:00:00', timezone => $1), 1794942000, 'timezone option reads get-magic');
}
is(epoch('DateTime', '2026-11-17 22:00:00'), 1794952800, 'default remains UTC');
for my $value ('2026-11-17T22:00:00Z', '2026-11-17 23:00:00+01:00',
               '2026-11-17T22:00:00.123Z', '2026-11-17T23:00:00.123+01:00',
               '1794952800', 1794952800) {
    is(epoch(q{DateTime('Europe/Moscow')}, $value), 1794952800, 'explicit instant unaffected');
}
for my $zone ('UTC', 'Etc/UTC', 'GMT') {
    local $ENV{TZDIR} = '/no/such/zoneinfo';
    is(epoch("DateTime('$zone')", '2026-11-17 22:00:00'), 1794952800, "$zone needs no database");
}
{
    eval { ClickHouse::Encoder->new(columns => [[v => 'UInt8']], timezone => 'Unknown/Nowhere') };
    like($@, qr/[Tt]imezone.*Unknown\/Nowhere/, 'unknown timezone option rejected at construction');
    eval { ClickHouse::Encoder->new(columns => [[v => 'UInt8']], timezone => undef) };
    like($@, qr/timezone must be a name/, 'undef timezone option rejected');
    my %opts = (timezone => undef, empty_as_null => undef);
    is_deeply([ClickHouse::Encoder::_encoder_options(%opts)], [], 'helpers do not forward undef options');
}
for my $zone ('Unknown/Nowhere', 'Europe/Moscow') {
    local $ENV{TZDIR} = tempdir(DIR => '.', CLEANUP => 1);
    my $enc = eval { ClickHouse::Encoder->new(columns => [[v => "DateTime('$zone')"], [w => "DateTime64(3, '$zone')"]]) };
    is($@, '', "column zone $zone is not loaded at construction");
    my $bytes = eval { $enc->encode([[1794952800, '2026-11-17T22:00:00.123Z']]) };
    is($@, '', 'epochs and explicit offsets need no timezone data');
    is_deeply($bytes && ClickHouse::Encoder->decode_block($bytes)->{columns}[1]{values},
              [1794952800123], 'instant kept');
    for (1, 2) {
        eval { $enc->encode([['2026-11-17 22:00:00', 0]]) };
        like($@, qr/[Tt]imezone.*\Q$zone\E/, "wall time croaks naming the zone (attempt $_)");
    }
}

sub tz_section {
    my ($version, $width, $offsets, $times, $indices) = @_;
    return pack('a4 a1 x15 N6', 'TZif', $version, 0, 0, 0, scalar(@$times), scalar(@$offsets), 4)
        . join('', map { pack($width == 8 ? 'q>' : 'l>', $_) } @$times)
        . pack('C*', @$indices)
        . join('', map { pack('l> C C', $_, 0, 0) } @$offsets) . "TST\0";
}
sub fixture {
    my ($name, $data) = @_;
    open my $fh, '>', "$ENV{TZDIR}/$name" or die $!;
    binmode $fh;
    print $fh $data;
    close $fh or die $!;
}
sub footer_zone {
    my ($name, $rule) = @_;
    fixture($name, tz_section('3', 4, [0], [], []) . tz_section('3', 8, [0], [], []) . "\n$rule\n");
}
subtest 'TZif versions and footer rules' => sub {
    local $ENV{TZDIR} = tempdir(DIR => '.', CLEANUP => 1);
    fixture('v1', tz_section("\0", 4, [19800], [], []));
    is(epoch(q{DateTime('v1')}, '2026-11-17 22:00:00'), 1794952800 - 19800, 'v1 fixed offset');
    for my $version (2, 3) {
        fixture("v$version", tz_section($version, 4, [1111], [], [])
            . tz_section($version, 8, [0, 10800], [2208988800], [1]) . "\n\n");
        is(epoch("DateTime('v$version')", '2050-07-10 12:30:00'),
           timegm(0, 30, 12, 10, 6, 2050) - 10800, "v$version reads the 64-bit section");
    }
    for my $rule ('M3.5.0/2,M10.5.0/3', 'J80/2,J300/3', '79/2,299/3') {
        footer_zone('footer', "STD-1DST-2,$rule");
        is(epoch(q{DateTime('footer')}, '2050-07-10 12:30:00'),
           timegm(0, 30, 12, 10, 6, 2050) - 7200, "$rule summer offset");
        is(epoch(q{DateTime('footer')}, '2050-01-10 12:30:00'),
           timegm(0, 30, 12, 10, 0, 2050) - 3600, "$rule winter offset");
    }
    footer_zone('allyear', 'EST5EDT,0/0,J365/25');
    for my $wall ([2050, 0, 1, 0, 30], [2050, 0, 10, 12, 30], [2050, 6, 10, 12, 30], [2050, 11, 31, 23, 30]) {
        my ($y, $m, $d, $h, $mi) = @$wall;
        my $text = sprintf '%04d-%02d-%02d %02d:%02d:00', $y, $m + 1, $d, $h, $mi;
        is(epoch(q{DateTime('allyear')}, $text), timegm(0, $mi, $h, $d, $m, $y) + 4 * 3600,
           "year-round DST footer at $text");
    }
    footer_zone('footer', 'STD-1DST-2,M3.5.0/2,M10.5.0/3');
    my $enc = ClickHouse::Encoder->new(columns => [[v => q{DateTime('footer')}]]);
    $enc->encode([['2050-01-10 12:30:00']]);
    unlink "$ENV{TZDIR}/footer" or die $!;
    my $bytes = $enc->encode([['2050-07-10 12:30:00']]);
    is(ClickHouse::Encoder->decode_block($bytes)->{columns}[0]{values}[0],
       timegm(0, 30, 12, 10, 6, 2050) - 7200, 'a loaded zone needs no file afterwards');
    for my $data ('bad', tz_section('3', 4, [0], [], [])
                          . tz_section('3', 8, [0], [], []) . "\nSTD-1DST,broken\n") {
        fixture('broken', $data);
        my $broken = ClickHouse::Encoder->new(columns => [[v => q{DateTime('broken')}]]);
        for (1, 2) {
            eval { $broken->encode([['2050-07-10 12:30:00']]) };
            like($@, qr/Invalid timezone.*broken/, 'malformed TZif or footer rejected on use');
        }
    }
};

subtest 'nested timezone and numeric instants' => sub {
    plan skip_all => 'system timezone database not found' unless $tzdata;
    my $enc = ClickHouse::Encoder->new(timezone => 'Europe/Moscow', columns => [
        [a => q{Array(Nullable(DateTime))}], [b => q{Tuple(DateTime('Europe/Berlin'), DateTime64(3))}]]);
    my $b = ClickHouse::Encoder->decode_block($enc->encode([
        [['2026-11-17 22:00:00', undef], ['2026-11-17 22:00:00', '2026-11-17 22:00:00.123']],
    ]));
    is_deeply($b->{columns}[0]{values}, [[1794942000, undef]], 'timezone option reaches nested Nullable');
    is_deeply($b->{columns}[1]{values}, [[1794949200, 1794942000123]], 'column zone overrides option in Tuple');
    is(epoch(q{DateTime64(3, 'Europe/Moscow')}, '1794952800123'), 1794952800123, 'string ticks unchanged');
    is(epoch(q{DateTime64(3, 'Europe/Moscow')}, '2026-11-17T22:00:00.123Z'), 1794952800123, 'explicit fractional UTC unchanged');
    is(epoch(q{SimpleAggregateFunction(max, DateTime('Europe/Moscow'))}, '2026-11-17 22:00:00'),
       1794942000, 'SimpleAggregateFunction retains the inner timezone');
    ClickHouse::Encoder->coerce_datetimes($b);
    my $roundtrip = { columns => [{ name => 'v', type => q{DateTime('Europe/Moscow')}, values => [1794942000] }] };
    ClickHouse::Encoder->coerce_datetimes($roundtrip);
    is(epoch(q{DateTime('Europe/Moscow')}, $roundtrip->{columns}[0]{values}[0]), 1794942000, 'UTC-rendered helper output roundtrips in column zone');
};

subtest 'time-of-day shapes' => sub {
    my $base = timegm(0, 0, 0, 31, 2, 2024);
    for my $case (['2024-03-31 02:30', 9000], ['2024-03-31T02:30', 9000], ['2024-03-31 02:30Z', 9000],
                  ['2024-03-31 02:30+01:00', 5400], ['2024-03-31 02:30:07', 9007],
                  ['2024-03-31 02:30:07 ', 9007], ['2024-03-31', 0]) {
        is(epoch(q{DateTime('UTC')}, $case->[0]), $base + $case->[1], "DateTime '$case->[0]'");
        is(epoch(q{DateTime64(1, 'UTC')}, $case->[0]), ($base + $case->[1]) * 10, "DateTime64 '$case->[0]'");
    }
    for my $bad ('2024-03-31 02:30:5', '2024-03-31T02', '2024-03-31 02:3', '2024-03-31 02:30:00x',
                 '2024-03-31 02:30.5', '2024-03-31 2:30:00') {
        for my $type (q{DateTime('UTC')}, q{DateTime64(3, 'UTC')}) {
            eval { epoch($type, $bad) };
            like($@, qr/Invalid datetime string/, "$type rejects '$bad'");
        }
    }
};

done_testing;
