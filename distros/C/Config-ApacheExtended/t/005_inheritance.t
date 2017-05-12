# -*- perl -*-

# t/005_inheritance.t - Tests the inheritance features.

use Test::More tests => 5;
use Config::ApacheExtended;
my $conf = Config::ApacheExtended->new(
	source			=> "t/parse.conf",
	inherit_vals	=> 1
);


ok($conf);												# test 1
ok($conf->parse);										# test 2

my $foobar = $conf->block(FooBar => 'baz test');
my $foo = $foobar->get('foo');

ok($foobar);											# test 3
ok($foo);												# test 4
is($foo, 'bar');										# test 5
