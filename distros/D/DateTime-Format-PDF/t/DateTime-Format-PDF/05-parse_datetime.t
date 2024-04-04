use strict;
use warnings;

use DateTime::Format::PDF;
use English;
use Test::More 'tests' => 99;
use Test::NoWarnings;

# Test.
my $obj = DateTime::Format::PDF->new;
my $ret = $obj->parse_datetime("D:20020911000000+01'00'");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 9, 'Parse month (9).');
is($ret->day, 11, 'Parse day (11).');
is($ret->hour, 0, 'Parse hour (0).');
is($ret->minute, 0, 'Parse minute (0).');
is($ret->time_zone->{'name'}, '+0100', 'Parse time zone (+0100).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:2002");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 1, 'Parse month (1).');
is($ret->day, 1, 'Parse day (1).');
is($ret->hour, 0, 'Parse hour (0).');
is($ret->minute, 0, 'Parse minute (0).');
is($ret->second, 0, 'Parse second (0).');
is($ret->time_zone->{'name'}, 'floating', 'Parse time zone (floating).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:200203");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 3, 'Parse month (3).');
is($ret->day, 1, 'Parse day (1).');
is($ret->hour, 0, 'Parse hour (0).');
is($ret->minute, 0, 'Parse minute (0).');
is($ret->second, 0, 'Parse second (0).');
is($ret->time_zone->{'name'}, 'floating', 'Parse time zone (floating).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:20020312");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 3, 'Parse month (3).');
is($ret->day, 12, 'Parse day (12).');
is($ret->hour, 0, 'Parse hour (0).');
is($ret->minute, 0, 'Parse minute (0).');
is($ret->second, 0, 'Parse second (0).');
is($ret->time_zone->{'name'}, 'floating', 'Parse time zone (floating).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:2002031211");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 3, 'Parse month (3).');
is($ret->day, 12, 'Parse day (12).');
is($ret->hour, 11, 'Parse hour (11).');
is($ret->minute, 0, 'Parse minute (0).');
is($ret->second, 0, 'Parse second (0).');
is($ret->time_zone->{'name'}, 'floating', 'Parse time zone (floating).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:200203121110");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 3, 'Parse month (3).');
is($ret->day, 12, 'Parse day (12).');
is($ret->hour, 11, 'Parse hour (11).');
is($ret->minute, 10, 'Parse minute (10).');
is($ret->second, 0, 'Parse second (0).');
is($ret->time_zone->{'name'}, 'floating', 'Parse time zone (floating).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:20020312111055");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 3, 'Parse month (3).');
is($ret->day, 12, 'Parse day (12).');
is($ret->hour, 11, 'Parse hour (11).');
is($ret->minute, 10, 'Parse minute (10).');
is($ret->second, 55, 'Parse second (55).');
is($ret->time_zone->{'name'}, 'floating', 'Parse time zone (floating).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:20020312111055Z");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 3, 'Parse month (3).');
is($ret->day, 12, 'Parse day (12).');
is($ret->hour, 11, 'Parse hour (11).');
is($ret->minute, 10, 'Parse minute (10).');
is($ret->second, 55, 'Parse second (55).');
is($ret->time_zone->{'name'}, 'UTC', 'Parse time zone (UTC).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:20020312111055+0130");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 3, 'Parse month (3).');
is($ret->day, 12, 'Parse day (12).');
is($ret->hour, 11, 'Parse hour (11).');
is($ret->minute, 10, 'Parse minute (10).');
is($ret->second, 55, 'Parse second (55).');
is($ret->time_zone->{'name'}, '+0130', 'Parse time zone (+0130).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:20020312111055+01'30");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 3, 'Parse month (3).');
is($ret->day, 12, 'Parse day (12).');
is($ret->hour, 11, 'Parse hour (11).');
is($ret->minute, 10, 'Parse minute (10).');
is($ret->second, 55, 'Parse second (55).');
is($ret->time_zone->{'name'}, '+0130', 'Parse time zone (+0130).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:20020312111055-02'30'");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 3, 'Parse month (3).');
is($ret->day, 12, 'Parse day (12).');
is($ret->hour, 11, 'Parse hour (11).');
is($ret->minute, 10, 'Parse minute (10).');
is($ret->second, 55, 'Parse second (55).');
is($ret->time_zone->{'name'}, '-0230', 'Parse time zone (-0230).');

# Test.
$obj = DateTime::Format::PDF->new;
$ret = $obj->parse_datetime("D:20020312111055-0230'");
isa_ok($ret, 'DateTime');
is($ret->year, 2002, 'Parse year (2002).');
is($ret->month, 3, 'Parse month (3).');
is($ret->day, 12, 'Parse day (12).');
is($ret->hour, 11, 'Parse hour (11).');
is($ret->minute, 10, 'Parse minute (10).');
is($ret->second, 55, 'Parse second (55).');
is($ret->time_zone->{'name'}, '-0230', 'Parse time zone (-0230).');

# Test.
$obj = DateTime::Format::PDF->new;
eval {
	$obj->parse_datetime("D:200203foo12111055-0230'");
};
like($EVAL_ERROR, qr{^Invalid date format: D:200203foo12111055-0230},
	"Invalid date format (D:200203foo12111055-0230').");

# Test.
$obj = DateTime::Format::PDF->new;
eval {
	$obj->parse_datetime("D:200");
};
like($EVAL_ERROR, qr{^Invalid date format: D:200},
	"Invalid date format (D:200').");

# Test.
$obj = DateTime::Format::PDF->new;
eval {
	$obj->parse_datetime("D:20000");
};
like($EVAL_ERROR, qr{^Invalid date format: D:20000},
	"Invalid date format (D:20000').");
