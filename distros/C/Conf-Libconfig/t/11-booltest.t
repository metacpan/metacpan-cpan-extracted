#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 14;
use Test::Deep;

use Conf::Libconfig;

my $cfg1 = 't/1_foo.cfg';
my $cfg2 = 't/2_foo.cfg';
my %fooplc = ();

my $foo = new Conf::Libconfig;
my $specfoo = new Conf::Libconfig;

ok($foo->new(), 'new - status ok');
ok($foo->add_hash('', 'plc', \%fooplc), 'add hash - status ok');
ok($foo->add_boolscalar('plc', 'transparent', 0), 'add bool scalar - status ok');
ok($foo->add_boolscalar('plc', 'polling', 1), 'add bool scalar - status ok');
ok($foo->write_file($cfg1), 'write file - status ok');

# Check hash method
cmp_deeply(
	my $fooref = $foo->fetch_hashref("plc"),
	{
		'polling' => 1,
		'transparent' => 0
	},
	"fetch scalar into hash reference - status ok",
);

ok($specfoo->new(), 'new - status ok');
ok($specfoo->getversion(), 'getversion - status ok');
my $libconfig_version = $specfoo->getversion();
if ($libconfig_version > 1.4) {
	ok($specfoo->read_string("new:{key = \"value\";};"), 'read string - status ok');
} else {
	is($libconfig_version < 1.4, 1, 'check libconfig version lower 1.4');
}
ok($specfoo->add_hash('', 'plcs', \%fooplc), 'add hash - status ok');
ok($specfoo->add_boolscalar('plcs', 'spec_1', 0), 'add bool scalar - status ok');
ok($specfoo->add_scalar('plcs', 'spec_2', 1), 'add scalar - status ok');
ok($specfoo->add_boolhash('plcs', 'ma', $fooref), 'add hash - status ok');
ok($specfoo->write_file($cfg2), 'write file - status ok');

unlink($cfg1);
unlink($cfg2);

