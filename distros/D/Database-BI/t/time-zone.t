use strict;
use warnings;
use Test::Most;
use Test::Mojo;
use lib 'lib';
use Database::BI::Util qw(iso_datetime parse_zone zone_wall frame_epoch);
use Database::BI::Calc;
use Readonly;

# Windows has no POSIX::tzset and does not read Olson names from TZ, so a test
# that needs the server in another zone cannot run there.
Readonly my $CAN_SET_TZ => $^O ne 'MSWin32';

sub set_tz {
	my ($tz) = @_;
	return unless $CAN_SET_TZ;
	if (defined $tz) { $ENV{TZ} = $tz } else { delete $ENV{TZ} }
	POSIX::tzset();
	return;
}

# One formula over one row, as the pipeline runs it.
sub calc {
	my ($expr, $row) = @_;
	my $c = Database::BI::Calc->new(expr => $expr, columns => [ sort keys %{$row} ]);
	die $c->error if $c->has_error;
	return $c->evaluate($row);
}

Readonly my $STAMP => '2026-11-06T23:30:00Z';

subtest 'no zone: as written' => sub {
	local $Database::BI::Util::ZONE;
	is_deeply([iso_datetime($STAMP)], ['2026-11-06', '23', '30', '00'], 'Z ignored');
	is_deeply([iso_datetime('2026-11-06T23:30:00+01:00')], ['2026-11-06', '23', '30', '00'], 'offset ignored');
};

subtest 'parse_zone' => sub {
	is_deeply(parse_zone('UTC'), { kind => 'fixed', offset => 0 }, 'UTC');
	is_deeply(parse_zone('+05:30'), { kind => 'fixed', offset => 19_800 }, '+05:30');
	is_deeply(parse_zone('-0800'), { kind => 'fixed', offset => -28_800 }, '-0800');
	is_deeply(parse_zone('local'), { kind => 'local' }, 'local');
	is(parse_zone(undef), undef, 'undef');
	is(parse_zone(''), undef, 'empty');
	for my $bad ('Mars/Base', '+15:00', '+01:60', [], '+1') {
		throws_ok { parse_zone($bad) } qr/time_zone: .* is not UTC, local, or an offset/, 'refused: ' . (ref $bad || $bad);
	}
};

subtest 'moved to the zone' => sub {
	local $Database::BI::Util::ZONE = parse_zone('-05:00');
	is_deeply([iso_datetime($STAMP)], ['2026-11-06', '18', '30', '00'], 'Z to -05:00');
	is_deeply([iso_datetime('2026-11-06T02:10Z')], ['2026-11-05', '21', '10', undef], 'day goes back');
	is_deeply([iso_datetime('2026-11-06T23:30:00+01:00')], ['2026-11-06', '17', '30', '00'], 'offset to -05:00');
	is_deeply([iso_datetime('2026-11-06T23:30:00.9+0100')], ['2026-11-06', '17', '30', '00'], 'fraction, +0100');
	is_deeply([iso_datetime('2026-11-06T23:30:00+01')], ['2026-11-06', '17', '30', '00'], '+01');
	is_deeply([iso_datetime('2026-11-06 23:30')], ['2026-11-06', '23', '30', undef], 'no zone written: as is');
	is_deeply([iso_datetime('2026-11-06')], ['2026-11-06', undef, undef, undef], 'date only');
	is_deeply([iso_datetime('2026-02-31T10:00Z')], ['2026-02-31', '10', '00', undef], 'impossible date untouched');
	is_deeply([iso_datetime('2026-11-06T25:00Z')], ['2026-11-06', '25', '00', undef], 'impossible hour untouched');
	is_deeply([iso_datetime('2024-03-01T03:00Z')], ['2024-02-29', '22', '00', undef], 'leap day');
	local $Database::BI::Util::ZONE = parse_zone('+05:30');
	is_deeply([iso_datetime('2026-12-31T20:00Z')], ['2027-01-01', '01', '30', undef], 'year rolls');
};

subtest 'local zone' => sub {
	plan skip_all => 'no tzset on Windows' unless $CAN_SET_TZ;
	local $Database::BI::Util::ZONE = parse_zone('local');
	local $ENV{TZ} = $ENV{TZ};
	set_tz('Etc/GMT+3');
	is_deeply([iso_datetime('2026-11-06T02:00:00Z')], ['2026-11-05', '23', '00', '00'], 'server zone');
	set_tz(undef);
};

subtest 'formulas and buckets follow the zone' => sub {
	local $Database::BI::Util::ZONE = parse_zone('UTC');
	local $ENV{TZ} = $ENV{TZ};
	set_tz('Etc/GMT+3');
	is(calc('hour(t)', { t => '2026-11-06T23:30:00+01:00' }), 22, 'hour is UTC');
	is(calc('hour(t)', { t => '1794007800' }), 23, 'epoch read on the UTC clock');
	is(calc('span(t, "1d")', { t => '2026-11-06T23:30:00-05:00' }), '2026-11-07', 'bucket day moves');
	{
		local $Database::BI::Util::ZONE;
		is(calc('span(t, "1d")', { t => '2026-11-06T23:30:00-05:00' }), '2026-11-06', 'no zone: as written');
	}
	set_tz(undef);
};

subtest 'time range today is the zone\'s' => sub {
	plan skip_all => 'no tzset on Windows' unless $CAN_SET_TZ;
	require Database::BI::Controller::Dashboard;
	my $preset = { day => 0 };
	local $ENV{TZ} = $ENV{TZ};
	set_tz('Etc/GMT+3');
	my $now = 1_794_018_600;	# 2026-11-07 02:30 UTC, 2026-11-06 23:30 at -03:00
	my @server = Database::BI::Controller::Dashboard::_time_range_bounds($preset, $now);
	local $Database::BI::Util::ZONE = parse_zone('UTC');
	my @utc = Database::BI::Controller::Dashboard::_time_range_bounds($preset, $now);
	is($server[0], '2026-11-06', 'server clock');
	is($utc[0], '2026-11-07', 'UTC clock');
	set_tz(undef);
};

subtest 'filter and startup' => sub {
	my $dir = Mojo::File::tempdir(CLEANUP => 1);
	$dir->child('ev.csv')->spew("id,at\n1,2026-11-06T23:30:00Z\n2,2026-11-07T03:00:00Z\n3,2026-11-07T10:00:00Z\n");
	my $t = Test::Mojo->new('Database::BI', { data_dir => "$dir", time_zone => '-05:00', model_dir => Mojo::File::tempdir(CLEANUP => 1)->to_string });
	$t->get_ok('/export?l=table:ev&format=json&f=at:eq:2026-11-06')->status_is(200);
	my $rows = $t->tx->res->json;
	is(scalar @$rows, 2, 'the two evenings of the 6th at -05:00, not the morning of the 7th');
	throws_ok { Test::Mojo->new('Database::BI', { time_zone => 'Mars' }) } qr/time_zone: 'Mars'/, 'bad setting stops the start';
};

done_testing();
