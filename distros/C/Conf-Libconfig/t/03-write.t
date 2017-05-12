#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 3;

use Conf::Libconfig;

my $cfgfile = "./t/spec.cfg";
my $writecfgfile = "./t/newtest.cfg";
my $foo = Conf::Libconfig->new;
ok($foo->read_file($cfgfile), "read file - status ok");
open my $fp, '>', $writecfgfile or die "Can't write the file: $!";
eval { $foo->write($fp) };
ok(($@ ? 0 : 1), "write buffer - status ok");
close($fp);
unlink $writecfgfile;

is(
	$foo->write_file($writecfgfile),
	1,
	"write file - status ok",
);
unlink $writecfgfile;

