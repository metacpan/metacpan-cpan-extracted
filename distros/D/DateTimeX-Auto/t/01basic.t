use Test::More tests => 9;
use DateTimeX::Auto ':auto';

is(ref('2000-01-01'), 'DateTime', 'yyyy-mm-dd');

is(ref('2000-01-01T12:00:00'), 'DateTime', 'yyyy-mm-ddThh:mm:ss');

{
	no DateTimeX::Auto;
	DateTimeX::Auto->import('d');
	
	local @_ = ();
	
	is(ref(&d), 'DateTime', '&d works with no argument.');
	
	is(d('2000-01-01T12:00:00.1234567891') , '2000-01-01T12:00:00.1234567890',
		'Precision past nanoseconds supported');
	
	is(d('2010-01-01Z') , '2010-01-01Z',
		'Trailing Z allowed on dates.');
	
	is(d('2010-01-01T12:00:00Z') , '2010-01-01T12:00:00Z',
		'Trailing Z allowed on datetimes.');
	
	is(d('2010-01-01T12:00:00.123456Z') , '2010-01-01T12:00:00.123456Z',
		'Trailing Z allowed on fractional datetimes.');

	ok(d('2010-01-01')->time_zone->is_floating,
		'Default timezone is floating.');
		
	ok(d('2010-01-01Z')->time_zone->is_utc,
		'Trailing Z forces UTC.');
}
