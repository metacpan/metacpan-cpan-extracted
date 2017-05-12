#!perl -T

use Test::More tests => 2;

use DateTime::Duration;

BEGIN {
	use_ok( 'DateTime::Format::Duration::DurationString' );
}

is(DateTime::Format::Duration::DurationString->new()->parse('1d 1d')->to_seconds,DateTime::Format::Duration::DurationString::DAY*2,'2 Days parsed');
