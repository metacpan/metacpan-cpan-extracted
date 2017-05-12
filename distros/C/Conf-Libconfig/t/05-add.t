#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 16;
use Test::Deep;

use Conf::Libconfig;

my $cfgfile = "./t/spec.cfg";
my $newcfgfile = "./t/newspec.cfg";
my $foo = Conf::Libconfig->new;
ok($foo->read_file($cfgfile), "read file - status ok");

my $key = "node1";
my $boolkey = "b";
my $floatkey = "floatkey";
my $longkey = "longkey";
my $binarykey = "binarykey";
my @arr = (1, 2, 3);
my @list = ("abc", 456, 0x888);
my %hash = ("online", "玄幻小说", "story", "杀魂逆天");

# scalar test
ok($foo->add("me.mar", $binarykey, "0b0"), "add bool scalar - status ok");
ok($foo->add_boolscalar("me.mar", $boolkey, 1), "add bool scalar - status ok");
ok($foo->add_scalar("me.mar", $floatkey, 5.5), "add float scalar - status ok");
ok($foo->add_scalar("me.mar", $longkey, 21111111113333), "add long scalar - status ok");
ok($foo->add_scalar("me.mar", $key, "hello, world"), "add string scalar - status ok");
ok($foo->modify_scalar("me.mar.float", "float string"), "modify scalar - status ok");
# array test
$key = "node2";
ok($foo->add_array("me.arr", $key,  \@arr), "add array into array - status ok");
ok($foo->add_array("me.mar", $key,  \@arr), "add array into hash - status ok");
# list test, like add_array
$key = "node3";
ok($foo->add_list("me.mar.family1", $key, \@list), "add list into list - status ok");
ok($foo->add_list("me.mar.check2", $key, \@list), "add list into hash - status ok");

# hash test
$key = "node4";
ok($foo->add_hash("books", $key, \%hash), "add hash into list - status ok");
ok($foo->add_hash("me.mar.check1", $key, \%hash), "add hash into hash - status ok");

TODO: {
local $TODO = 'add hard hash methods do not work yet';

undef %hash;
%hash = ( "app", { "a", "b", "c", "d" }  );
$key = "node5";
#ok($foo->add_hash("me.mar.check1", $key, \%hash), "add hard hash - status ok");
ok(1);
}

{
# Instead of adding hard hash using add_hash, try generic add..
undef %hash;
%hash = ( "app", { "a", "b", "c", "d" }  );
$key = "node5";
ok($foo->add("me.mar.check1", $key, \%hash), "add hard hash using generic add - status ok");
}

ok($foo->write_file($newcfgfile), "write file - status ok");
unlink($newcfgfile);
