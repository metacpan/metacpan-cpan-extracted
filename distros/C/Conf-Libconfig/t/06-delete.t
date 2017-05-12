#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 10;
use Test::Deep;

use Conf::Libconfig;

my $cfgfile = "./t/spec.cfg";
my $newcfgfile = "./t/newtest.cfg";
my $foo = Conf::Libconfig->new;
ok($foo->read_file($cfgfile), "read file - status ok");

ok($foo->delete_node("me.mar.check"), "delete node - status ok");
ok($foo->delete_node("me.mar.family"), "delete node - status ok");
ok($foo->delete_node("me.mar.many"), "delete node - status ok");
ok($foo->delete_node("me.mar.check1.m"), "delete node - status ok");

ok($foo->delete_node_key("me.mar.check1", "ggg"), "delete node key - status ok");
ok($foo->delete_node_key("me.mar.family1.[4]", "y"), "delete node key - status ok");
ok($foo->delete_node_elem("me.mar.family1", 2), "delete node element - status ok");

ok($foo->write_file($newcfgfile), "write file - status ok");
unlink($newcfgfile);

# Destructor
eval { $foo->delete() };
ok(($@ ? 0 : 1), "destructor - status ok");

