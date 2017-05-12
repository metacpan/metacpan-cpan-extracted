# -*- perl -*-

# t/006_expandvars.t - Tests the variable expansion feature

use Test::More tests => 19;
use Config::ApacheExtended;
use English;
my $conf = Config::ApacheExtended->new(
	source			=> "t/expandvars.conf",
	expand_vars		=> 1,
	inherit_vals	=> 1,
);


ok($conf);														# test 1
ok($conf->parse);												# test 2

my $foo = $conf->get('Foo');
my $thisfoo = $conf->get('ThisFoo');
my @bar = $conf->get( 'Bar' );
my $block = $conf->block( FooBar => 'baz test' );
my @boom = $block->get('Boom');
my $blat = $block->get('Blat');
my $idxtest = $conf->get('SomeIdxTest');
my $arstrtest = $conf->get('ArrayStringTest');
my $cstr = join($LIST_SEPARATOR, @bar);

ok($foo);														# test 3
is($foo, 'bar');												# test 4
ok($thisfoo);													# test 5
is($thisfoo,$foo);												# test 6


ok($block);														# test 7
ok(@bar);														# test 8
is(scalar(@bar), 2);											# test 9
ok(@boom);														# test 10
is(scalar(@boom), scalar(@bar));								# test 11
is($boom[0], $bar[0]);											# test 12
is($boom[1], $bar[1]);											# test 13
ok($blat);														# test 14
is($blat, $bar[0]);												# test 15

ok($idxtest);													# test 16
is($idxtest, $bar[1]);											# test 17

ok($arstrtest);													# test 18
is($arstrtest, "Batman, $cstr, Joker.");						# test 19
