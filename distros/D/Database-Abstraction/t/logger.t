#!perl -w

# Try running this one with TEST_VERBOSE=1 and see what happens

use strict;
use FindBin qw($Bin);

use File::Temp;
use Test::Most tests => 34;

use lib 't/lib';

use_ok('MyLogger');
use_ok('Database::test1');
use_ok('Database::test2');
use_ok('Database::test4');

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
	is($test2->{'logger'}, $logger, 'sets the logger correctly');
	# can_ok($test2->{'logger'}, 'debug', 'trace', 'warn', 'notice');
}

# set_logger without a logger argument, should croak
{
	eval {
		$test2->set_logger();
	};
	like($@, qr/Usage: /, 'set_logger dies with correct error message if logger is missing');
}

# set_logger with subroutine ref
{
	my $code_called;
	my $logger = sub {
		unlike($_[0]->{'line'}, qr/\D/, 'Line numbers are valid');
		diag($_[0]->{'level'}, '> ', @{$_[0]->{'message'}}) if($ENV{'TEST_VERBOSE'});
		$code_called++;
		# ::diag(Data::Dumper->new([\@_])->Dump());
	};
	my $test4 = new_ok('Database::test4' => [{ directory => "$Bin/../data" }] );
	$test4->set_logger($logger);
	$test4->{'logger'}->level('debug');
	ok(!defined($test4->ordinal(cardinal => 'four')), 'CSV AUTOLOAD works');
	cmp_ok($code_called, '==', 8, 'Setting the logger as a ref to code works');
}

# set_logger with file
{
	my $test1 = new_ok('Database::test1' => [ directory => "$Bin/../data" ] );

	# Create temporary files for testing
	my $file = File::Temp->new();
	my $filename = $file->filename();

	$test1->set_logger($filename);
	$test1->{'logger'}->level('debug');

	# Get some data
	cmp_ok($test1->number('two'), '==', 2, 'CSV AUTOLOAD works');

	# Verify the contents of the file
	open(my $fin, '<', $filename) or die "$filename: Cannot open file: $!";
	my $content = do { local $/; <$fin> };
	close($fin);

	# Test contents of the file
	like($content, qr/^DEBUG> /sm, 'File contains some debugging');
	like($content, qr/^TRACE> /sm, 'File contains some tracing');
	unlike($content, qr/^FOO> /sm, 'Sanity check for the regex, that it is actually searching for something');

	diag($content) if($ENV{'TEST_VERBOSE'});
}

# set_logger with array
subtest 'Logger with Array' => sub {
	my @messages;

	my $test1 = new_ok('Database::test1' => [{ directory => "$Bin/../data", logger => \@messages }] );
	$test1->{'logger'}->level('debug');

	cmp_ok($test1->entry(number => 2), 'eq', 'two', 'CSV AUTOLOAD works');
	diag(Data::Dumper->new([\@messages])->Dump()) if($ENV{'TEST_VERBOSE'});

	is_deeply($messages[0], {
			'level' => 'trace',
			'message' => 'Database::test1: _open test1'
		}
	);
}
