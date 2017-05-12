# -*- perl -*-

# t/008_validate.t - Tests the validation feature

use Test::More "no_plan";
use Config::ApacheExtended;
my $conf = Config::ApacheExtended->new(
	source				=> "t/validate_good.conf",
	valid_directives	=> [qw(TestDir GoodDir)],
	valid_blocks		=> [qw(TestBlock GoodBlock)],
);


ok($conf);													# test 1

my $parse = $conf->parse;

use Data::Dumper;
ok($parse, "Check Parse Results");							# test 2

my $testdir = $conf->get('TestDir');

ok($testdir);												# test 3
is($testdir,'test');										# test 4

$conf = undef;
$conf = Config::ApacheExtended->new(
	source				=> "t/validate_bad.conf",
	valid_directives	=> [qw(TestDir GoodDir)],
	valid_blocks		=> [qw(TestBlock GoodBlock)],
);

ok($conf);													# test 5

$parse = $conf->parse();
ok(!$parse);												# test 6

