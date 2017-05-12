#!perl -T

use Test::More tests => 9;

use DateTime::Duration;

BEGIN {
	use_ok( 'DateTime::Format::Duration::DurationString' );
}

is(DateTime::Format::Duration::DurationString->new()->parse('1')->to_seconds,DateTime::Format::Duration::DurationString::HOUR,'Hour default');
is(DateTime::Format::Duration::DurationString->new()->parse('1h')->to_seconds,DateTime::Format::Duration::DurationString::HOUR,'Hour parsed');
is(DateTime::Format::Duration::DurationString->new()->parse('1d')->to_seconds,DateTime::Format::Duration::DurationString::DAY,'Day parsed');
is(DateTime::Format::Duration::DurationString->new()->parse('1s')->to_seconds,DateTime::Format::Duration::DurationString::SECOND,'Second parsed');
is(DateTime::Format::Duration::DurationString->new()->parse('1m')->to_seconds,DateTime::Format::Duration::DurationString::MINUTE,'Minute parsed');
is(DateTime::Format::Duration::DurationString->new()->parse('1w')->to_seconds,DateTime::Format::Duration::DurationString::WEEK,'Week parsed');
is(DateTime::Format::Duration::DurationString->new()->parse('1d 1s')->to_seconds,DateTime::Format::Duration::DurationString::DAY+1,'Complex parsed');


isa_ok(DateTime::Format::Duration::DurationString->new()->parse('1d')->to_duration,'DateTime::Duration','Duration conversion okay');
