# -*- perl -*-

# t/004_get.t - Makes sure that we can retrieve blocks using block.

use Test::More tests => 12;
use Config::ApacheExtended;

my $conf = Config::ApacheExtended->new(source => "t/parse.conf");

ok($conf);													# test 1
ok($conf->parse);											# test 2

my @blocks = $conf->block();
my @foobars = $conf->block('FooBar');
my $foobar = $conf->block(FooBar => 'baz test');
my $bang = $foobar->get('bang');

ok(@blocks);												# test 3
is(scalar(@blocks), 1);										# test 4
like($blocks[0], qr/foobar/i);								# test 5

ok(@foobars);												# test 6
is(scalar(@foobars), 1);									# test 7
like($foobars[0]->[1], qr/baz test/i);						# test 8

ok($foobar);												# test 9
isa_ok($foobar, 'Config::ApacheExtended');					# test 10

ok($bang);													# test 11
is($bang, 'eek');											# test 12
