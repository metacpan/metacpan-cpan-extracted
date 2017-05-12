#!perl -T
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 5;

use Conf::Libconfig;

my $cfgfile1 = "./t/test.cfg";
my $cfgfile2 = "./t/spec.cfg";
my $foo1 = new Conf::Libconfig;
my $foo2 = new Conf::Libconfig;

ok($foo1->read_file($cfgfile1), "read file - status ok");

is(
    $foo1->lookup_value("misc.enabled"),
    0,
    "bool test - status ok",
);

ok($foo2->read_file($cfgfile2), "read file - status ok");

is(
    $foo1->lookup_value("misc.port"),
    5000,
    "int test - status ok",
);

is(
    $foo2->lookup_value("me.mar.check1.x"),
    32,
    "hex test - status ok",
);
