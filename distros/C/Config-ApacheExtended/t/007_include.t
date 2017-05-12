# -*- perl -*-

# t/007_include.t - Tests the include feature

use Test::More tests => 11;
use Config::ApacheExtended;

my $conf = Config::ApacheExtended->new(
	source			=> "t/include.conf",
	expand_vars		=> 1,
	inherit_vals	=> 1,
	honor_include	=> 1
);


ok($conf);													# test 1

my $parse =$conf->parse;
ok($parse);													# test 2

my $inctest = $conf->get( 'IncludeTest' );
my $simple = $conf->get('SimpleDir');
my $block = $conf->block( SomeInclude => 'inctest' );

ok($block);													# test 3

my $dira = $block->get( 'DirA' );
my $dirb = $block->get( 'DirB' );

ok($inctest);												# test 4
is($inctest,'inc');											# test 5

ok($simple);												# test 6
is($simple,'simple');										# test 7
ok($dira);													# test 8
is($dira, 'config file A');									# test 9
ok($dirb);													# test 10
is($dirb,'config file B');									# test 11
