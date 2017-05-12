# -*- perl -*-

# t/003_get.t - Makes sure that we can retrieve values using get.

use Test::More tests => 27;
use Config::ApacheExtended;

my $conf = Config::ApacheExtended->new(
	source		=> "t/parse.conf",
	ignore_case	=> 0,
);


ok($conf);												# test 1
ok($conf->parse);										# test 2

my $noval = $conf->get('NoVal');
my @bar = $conf->get('Bar');
my $bar = $conf->get('Bar');
my $smulti = $conf->get('SingleValMultiLine');
my @mmulti = $conf->get('MultilineTest');
my $mmulti = $conf->get('MultilineTest');
my $hereto = $conf->get('HeretoTest');
my $foo = $conf->get('Foo');
my $foobar = $conf->get('FooBar');
my @keys = $conf->get();
my $foocs = $conf->get('foo');
my $qt1 = $conf->get('QuoteTest1');
my $qt2 = $conf->get('QuoteTest2');

ok($noval);												# test 3
is($noval,1);											# test 4

ok(@bar);												# test 5
ok($bar);												# test 6
is(scalar(@bar),2);										# test 7
is(ref($bar), 'ARRAY');									# test 8
is($bar[0], 'baz');										# test 9
is($bar[1], 'bang');									# test 10

ok($smulti);											# test 11
is($smulti,'Single value across lines');				# test 12

ok(@mmulti);											# test 13
ok($mmulti);											# test 14
is(scalar(@mmulti), 3);									# test 15
is(ref($mmulti), 'ARRAY');								# test 16
is($mmulti[0], 'Multi');								# test 17
is($mmulti[1], 'values');								# test 18
is($mmulti[2], 'across lines');							# test 19

ok($hereto);											# test 20
is($hereto,
	"These lines are inserted\n" .
	"verbatim into HeretoTest\n" .
	"variable expansion to come.\n"
);														# test 21

ok($foo);												# test 22
is($foo, 'bar');										# test 23

ok(!$foobar);											# test 24

# tests 26-27
ok(@keys);												# test 25
cmp_ok(scalar(@keys), '>', 0);							# test 26

ok(!$foocs);											# test 27

#is($qt1, 'Single Quotes');								# test 28
#is($qt2, 'Double Quotes');								# test 29
