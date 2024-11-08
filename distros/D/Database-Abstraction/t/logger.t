#!perl -w

# Try running this one with TEST_VERBOSE=1 and see what happens

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 16;

use_ok('MyLogger');
use_ok('Database::test1');
use_ok('Database::test2');

my $test1 = new_ok('Database::test1' => [{ directory => "$Bin/../data", logger => new_ok('MyLogger') }]);

cmp_ok($test1->number('two'), '==', 2, 'CSV AUTOLOAD works found');
is($test1->number('four'), undef, 'CSV AUTOLOAD works not found');

my $res = $test1->selectall_hashref(entry => 'one');
$res = $test1->selectall_hashref(number => 1);

my $test2 = new_ok('Database::test2' => [ directory => "$Bin/../data" ]);
cmp_ok($test2->set_logger(new_ok('MyLogger')), 'eq', $test2, 'set_logger returns self');

cmp_ok($test2->number('third'), 'eq', '3rd', 'PSV AUTOLOAD works found');
is($test2->number('four'), undef, 'PSV AUTOLOAD works not found');

# set_logger with a valid logger
{
	my $logger = new_ok('MyLogger');
	my $result = $test2->set_logger(logger => $logger);
	is($result, $test2, 'set_logger returns $self when logger is set');
	is($test2->{'logger'}, $logger, 'Logger is set correctly');
}

# set_logger without a logger argument, should croak
{
	eval {
		$test2->set_logger();
	};
	like($@, qr/Usage: /, 'set_logger dies with correct error message if logger is missing');
}

