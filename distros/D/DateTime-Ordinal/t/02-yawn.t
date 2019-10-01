use Test::More;
use DateTime::Ordinal;

sub yawn {
	my ($meth, $data, $expected, $expected_ordinal) = @_;
	my %default_date = (
		year       => 2000,
		month      => 1,
		day        => 1,
		hour       => 1,
		minute     => 1,
		second     => 1,
		nanosecond => 500000000,
		time_zone => '+00:00'
	);
	%default_date = (%default_date, %{$data});
	my $dt = DateTime::Ordinal->new(%default_date);
	is ($dt->$meth(), $expected, "cardinal: $expected");
	is ($dt->$meth(1), $expected_ordinal, "ordinal: $expected_ordinal");
}

for my $test (
	[1, '1st'],
	[2, '2nd'],
	[3, '3rd'],
	[4, '4th']
) {
	yawn('month', {month => $test->[0]}, @{$test});
	yawn('mon', {month => $test->[0]}, @{$test});
	yawn('month_0', {month => $test->[0] + 1}, @{$test});
	yawn('mon_0', {month => $test->[0] + 1}, @{$test});
	yawn('day_of_month', {day => $test->[0]}, @{$test});
	yawn('day', {day => $test->[0]}, @{$test});
	yawn('mday', {day => $test->[0]}, @{$test});
	yawn('day_of_month_0', {day => $test->[0] + 1}, @{$test});
	yawn('day_0', {day => $test->[0] + 1}, @{$test});
	yawn('mday_0', {day => $test->[0] + 1}, @{$test});
	yawn('day_of_week', {day => $test->[0] + 2}, @{$test});
	yawn('wday', {day => $test->[0] + 2}, @{$test});
	yawn('dow', {day => $test->[0] + 2}, @{$test});
 	yawn('day_of_week_0', {day => $test->[0] + 3}, @{$test});
	yawn('wday_0', {day => $test->[0] + 3}, @{$test});
	yawn('dow_0', {day => $test->[0] + 3}, @{$test});
	# hmmm
	yawn('local_day_of_week', {day => $test->[0] + 1}, @{$test});
	yawn('day_of_quarter', {day => $test->[0]}, @{$test});
	yawn('doq', {day => $test->[0]}, @{$test});
 	yawn('day_of_quarter_0', {day => $test->[0] + 1}, @{$test});
	yawn('doq_0', {day => $test->[0] + 1}, @{$test});
	yawn('day_of_year', {day => $test->[0]}, @{$test});
	yawn('day_of_year_0', {day => $test->[0] + 1}, @{$test});
	yawn('hour', {hour => $test->[0]}, @{$test});
	yawn('hour_1', {hour => $test->[0]}, @{$test});
	yawn('hour_12', {hour => $test->[0]}, @{$test});
	yawn('hour_12_0', {hour => $test->[0]}, @{$test});
	yawn('minute', {minute => $test->[0]}, @{$test});
	yawn('min', {minute => $test->[0]}, @{$test});
	yawn('second', {second => $test->[0]}, @{$test});
	yawn('sec', {second => $test->[0]}, @{$test});
	yawn('nanosecond', { nanosecond => $test->[0] }, @{$test});
	yawn('millisecond', { nanosecond => $test->[0] * 1000000 }, @{$test});
	yawn('microsecond', { nanosecond => $test->[0] * 1000 }, @{$test});
	yawn('week', { day => $test->[0] * 7 }, @{$test});
	yawn('week_year', { day => $test->[0] * 7 }, @{$test});
	#  ^^ yawn('week_number', { day => $test->[0] * 7 }, @{$test});
	yawn('week_of_month', { day => $test->[0] * 7 }, @{$test});
}

yawn('leap_seconds', {}, '22', '22nd');

for my $test (
	[1, 1, '1st'],
	[8, 2, '2nd'],
	[15, 3, '3rd'],
	[22, 4, '4th']
) {
	yawn('weekday_of_month', {day => $test->[0]}, $test->[1], $test->[2]);	
}


for my $test (
	[1, 1, '1st'],
	[4, 2, '2nd'],
	[7, 3, '3rd'],
	[10, 4, '4th']
) {
	yawn('quarter', {month => $test->[0]}, $test->[1], $test->[2]);	
	my $month = $test->[0] + 3;
	$month = $month > 12 ? 1 : $month;
	yawn('quarter_0', {month => $month}, $test->[1], $test->[2]);	
}

done_testing();
