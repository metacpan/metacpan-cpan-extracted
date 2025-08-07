#!perl -wT

use strict;
use FindBin qw($Bin);

use lib 't/lib';
use Test::Most tests => 8;

BEGIN {
	use_ok('Database::Abstraction', 'directory' => "$Bin/../data");
	# use_ok('Database::Abstraction', { 'directory' => "$Bin/../data" });
	use_ok('Database::test1');
	use_ok('Database::test2');
}

my $defaults = Database::Abstraction::init();
cmp_ok($defaults->{'directory'}, 'eq', "$Bin/../data");

my $test1 = new_ok('Database::test1');
my $test2 = new_ok('Database::test2');

cmp_ok($test1->number('two'), '==', 2, 'CSV AUTOLOAD works');
cmp_ok($test2->number('third'), 'eq', '3rd', 'PSV AUTOLOAD works');
