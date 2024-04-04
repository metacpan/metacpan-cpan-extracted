use strict;
use warnings;

use DateTime;
use DateTime::Format::PDF;
use English;
use Error::Pure::Utils qw(clean);
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = DateTime::Format::PDF->new;
my $dt = DateTime->new(
	'day' => 23,
	'month' => 1,
	'year' => 2024,
	'time_zone' => '+0130',
	'hour' => 10,
	'minute' => 11,
	'second' => 12,
);
my $ret = $obj->format_datetime($dt);
is($ret, "D:20240123101112+0130", 'Format PDF datetime.');

# Test.
$obj = DateTime::Format::PDF->new;
eval {
	$obj->format_datetime('foo');
};
is($EVAL_ERROR, "Bad DateTime object.\n",
	"Bad DateTime object (foo).");
clean();

# Test.
$obj = DateTime::Format::PDF->new;
eval {
	$obj->format_datetime(Test::MockObject->new);
};
is($EVAL_ERROR, "Bad DateTime object.\n",
	"Bad DateTime object (bad object).");
clean();

# Test.
$obj = DateTime::Format::PDF->new;
eval {
	$obj->format_datetime;
};
is($EVAL_ERROR, "Bad DateTime object.\n",
	"Bad DateTime object (undef).");
clean();
