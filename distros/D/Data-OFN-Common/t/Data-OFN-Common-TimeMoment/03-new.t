use strict;
use warnings;

use Data::OFN::Common::TimeMoment;
use DateTime;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 15;
use Test::NoWarnings;

# Test.
my $obj = Data::OFN::Common::TimeMoment->new(
	'date' => DateTime->new(
		'day' => 26,
		'month' => 7,
		'year' => 2023,
	),
);
isa_ok($obj, 'Data::OFN::Common::TimeMoment');

# Test.
$obj = Data::OFN::Common::TimeMoment->new(
	'date_and_time' => DateTime->new(
		'day' => 26,
		'month' => 7,
		'year' => 2023,
		'hour' => 12,
		'minute' => 13,
		'second' => 0,
	),
);
isa_ok($obj, 'Data::OFN::Common::TimeMoment');

# Test.
$obj = Data::OFN::Common::TimeMoment->new(
	'date_and_time' => DateTime->new(
		'day' => 26,
		'month' => 7,
		'year' => 2023,
		'hour' => 0,
		'minute' => 13,
		'second' => 0,
	),
);
isa_ok($obj, 'Data::OFN::Common::TimeMoment');

# Test.
$obj = Data::OFN::Common::TimeMoment->new(
	'date_and_time' => DateTime->new(
		'day' => 26,
		'month' => 7,
		'year' => 2023,
		'hour' => 0,
		'minute' => 0,
		'second' => 1,
	),
);
isa_ok($obj, 'Data::OFN::Common::TimeMoment');

# Test.
$obj = Data::OFN::Common::TimeMoment->new(
	'flag_unspecified' => 1,
);
isa_ok($obj, 'Data::OFN::Common::TimeMoment');

# Test.
eval {
	Data::OFN::Common::TimeMoment->new(
		'date' => DateTime->new(
			'day' => 26,
			'month' => 7,
			'year' => 2023,
		),
		'date_and_time' => DateTime->new(
			'day' => 26,
			'month' => 7,
			'year' => 2023,
			'hour' => 12,
			'minute' => 13,
			'second' => 0,
		),
	);
};
is($EVAL_ERROR, "Parameters 'date' and 'date_and_time' could not be defined together.\n",
	"Parameters 'date' and 'date_and_time' could not be defined together.");
clean();

# Test.
eval {
	Data::OFN::Common::TimeMoment->new(
		'date' => DateTime->new(
			'day' => 26,
			'month' => 7,
			'year' => 2023,
			'hour' => 12,
		),
	);
};
is($EVAL_ERROR, "Parameter 'date' must have a hour value of zero.\n",
	"Parameter 'date' must have a hour value of zero.");
clean();

# Test.
eval {
	Data::OFN::Common::TimeMoment->new(
		'date' => DateTime->new(
			'day' => 26,
			'month' => 7,
			'year' => 2023,
			'minute' => 12,
		),
	);
};
is($EVAL_ERROR, "Parameter 'date' must have a minute value of zero.\n",
	"Parameter 'date' must have a minute value of zero.");
clean();

# Test.
eval {
	Data::OFN::Common::TimeMoment->new(
		'date' => DateTime->new(
			'day' => 26,
			'month' => 7,
			'year' => 2023,
			'second' => 12,
		),
	);
};
is($EVAL_ERROR, "Parameter 'date' must have a second value of zero.\n",
	"Parameter 'date' must have a second value of zero.");
clean();

# Test.
eval {
	Data::OFN::Common::TimeMoment->new(
		'date_and_time' => DateTime->new(
			'day' => 26,
			'month' => 7,
			'year' => 2023,
		),
	);
};
is($EVAL_ERROR, "Parameter 'date_and_time' should be a 'date' parameter.\n",
	"Parameter 'date_and_time' should be a 'date' parameter.");
clean();

# Test.
eval {
	Data::OFN::Common::TimeMoment->new(
		'flag_unspecified' => 0,
	);
};
is($EVAL_ERROR, "Parameter 'flag_unspecified' disabled needs to be with 'date' or 'date_and_time' parameters.\n",
	"Parameter 'flag_unspecified' disabled needs to be with 'date' or 'date_and_time' parameters (explicit flag_unspecified = 0).");
clean();

# Test.
eval {
	Data::OFN::Common::TimeMoment->new;
};
is($EVAL_ERROR, "Parameter 'flag_unspecified' disabled needs to be with 'date' or 'date_and_time' parameters.\n",
	"Parameter 'flag_unspecified' disabled needs to be with 'date' or 'date_and_time' parameters (no parameters).");
clean();

# Test.
eval {
	Data::OFN::Common::TimeMoment->new(
		'date' => DateTime->new(
			'day' => 26,
			'month' => 7,
			'year' => 2023,
		),
		'flag_unspecified' => 1,
	);
};
is($EVAL_ERROR, "Parmaeter 'date' and 'flag_unspecified' could not be defined together.\n",
	"Parmaeter 'date' and 'flag_unspecified' could not be defined together.");
clean();

# Test.
eval {
	Data::OFN::Common::TimeMoment->new(
		'date_and_time' => DateTime->new(
			'day' => 26,
			'month' => 7,
			'year' => 2023,
			'hour' => 12,
			'minute' => 13,
			'second' => 0,
		),
		'flag_unspecified' => 1,
	);
};
is($EVAL_ERROR, "Parmaeter 'date_and_time' and 'flag_unspecified' could not be defined together.\n",
	"Parmaeter 'date_and_time' and 'flag_unspecified' could not be defined together.");
clean();
