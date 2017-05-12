#!perl -T
use strict;
use warnings;
use bigint;
use Data::Dumper;
use Test::More tests => 5;

use Conf::Libconfig;

my $cfgfile1 = "./t/00-load.t";
my $cfgfile2 = "./t/test.cfg";
my $cfgfile3 = "./t/spec.cfg";
my $foo1 = Conf::Libconfig->new;
my $foo2 = Conf::Libconfig->new;
ok(!$foo1->read_file($cfgfile1), "read file - status ok");
ok($foo2->read_file($cfgfile2), "read file - status ok");

is(
    $foo2->lookup_value("misc.enabled"),
    0,
    "bool test - status ok",
);

ok($foo2->read_file($cfgfile3), "read file - status ok");

is(
    $foo2->lookup_value("me.mar.check1.x"),
    32,
    "hex test - status ok",
);
