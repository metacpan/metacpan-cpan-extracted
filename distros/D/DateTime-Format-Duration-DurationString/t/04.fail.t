#!perl -T

use Test::More tests => 3;

use DateTime::Duration;

BEGIN {
	use_ok( 'DateTime::Format::Duration::DurationString' );
}


eval { DateTime::Format::Duration::DurationString->new()->parse('1 d') };
like($@, qr/not wellformed/, 'Right error');
eval { DateTime::Format::Duration::DurationString->new()->parse('1y') };
like($@, qr/unknown type/, 'Right error');
