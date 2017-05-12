#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More;
plan skip_all => 'Test::More version is too lower!' if $Test::More::VERSION < 0.90;

use Test::Deep;
use Conf::Libconfig;

my $cfg1 = 't/1_foo.cfg';
my $cfg2 = 't/2_foo.cfg';
my $cfg3 = 't/3_foo.cfg';
my $includedir_cfg = 't/include_dir.cfg';

my $foo1 = new Conf::Libconfig;
plan skip_all => 'libconfig version is too lower!' if ($foo1->getversion() < 1.4);
my $foo2 = new Conf::Libconfig;
my $foo3 = new Conf::Libconfig;
my $foo4 = new Conf::Libconfig;
my $foo5 = new Conf::Libconfig;

my $foopath = '/home/cnangel/works/libconfig';

ok($foo1->new(), 'new - status ok');
ok($foo1->read_string("key = \"value\";"), 'read string - status ok');

if (-e $foopath) {
	$foo5->set_include_dir($foopath);
	my $dir = $foo5->get_include_dir();
	ok($dir eq $foopath, "set and get include dir - status ok");
}

ok($foo1->write_file($cfg1), 'write file - status ok');

ok($foo2->read_string(qq~includedir: { ab: { abkey = \"test!\"; }; maybe = TRUE; num = 12345L; 
			\@include "t/1_foo.cfg"
			pack = ([true, false], [0x2, 0x3, 4], 5, \"6\", 7); };~), 'read string - status ok');

ok($foo2->write_file($cfg2), 'write file - status ok');

ok($foo4->read_file($includedir_cfg), 'read @include file - status ok');

cmp_deeply(
	my $fooref = $foo4->fetch_hashref('.'),
	{
 		'include_dir' => {
                    'hahaha' => 'happy!',
                    'includedir' => {
                                      'ab' => {
                                                'abkey' => 'test!'
                                              },
                                      'maybe' => 1,
                                      'num' => '12345',
                                      'pack' => [
                                                  [
                                                    1,
                                                    0
                                                  ],
                                                  [
                                                    2,
                                                    3,
                                                    4
                                                  ],
                                                  5,
                                                  '6',
                                                  7
                                                ],
                                      'key' => 'value'
                                    },
                    'key' => 'value'
                  }
	},
	"fetch scalar into hash reference - status ok",
);

ok($foo3->new(), 'new - status ok');
ok($foo3->add_hash('', 'new_include_dir', {}), 'add hash - status ok');
ok($foo3->add_scalar('new_include_dir', 'spec_2', 1), 'add scalar - status ok');
TODO: {
#ok($foo3->add_hash('new_include_dir', 'ma', $fooref), 'add hash - status ok');
ok(1);
}
ok($foo3->write_file($cfg3), 'write file - status ok');

unlink($cfg1);
unlink($cfg2);
unlink($cfg3);

done_testing();
