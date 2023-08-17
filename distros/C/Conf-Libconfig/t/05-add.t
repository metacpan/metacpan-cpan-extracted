#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 42;
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
my @arr_str = ("1", "2", "3");
my @list = ("abc", 456, 0x888);
my %hash = ("online", "玄幻小说", "story", "杀魂逆天");
my $reference = { "key" => "value", "hello" => "world" };

# set value test
## is($foo->set_value("", $reference),
## 	0,
## 	"set empty key - set value status ok"
## );
## is($foo->value(""),
## 	{},
## 	"get empty key - get value status ok"
## );
is($foo->set_boolean_value("abc.boolean1", 0b00),
	0,
	"set boolean1 value - status ok"
);
is($foo->value("abc.boolean1"),
	0,
	"get boolean1 value - status ok"
);
is($foo->set_boolean_value("abc.boolean2", "tRuE"),
	0,
	"set boolean2 value - status ok"
);
is($foo->value("abc.boolean2"),
	1,
	"get boolean2 value - status ok"
);

is($foo->set_value("abc.int", 0b1),
	0,
	"set boolean value - status ok"
);
is($foo->value("abc.int"),
	1,
	"get boolean value - status ok"
);
is($foo->set_value("abc.bigint", 17223372036854775807),
	0,
	"set integer value - status ok"
);
is($foo->value("abc.bigint"),
	-1223372036854775809,
	"get integer value - status ok"
);
is($foo->set_value("abc.int", 100),
	0,
	"set integer value - status ok"
);
is($foo->value("abc.int"),
	100,
	"get integer value - status ok"
);

is($foo->set_value("abc.float", 100.00012),
	0,
	"set float value - status ok"
);
is($foo->value("abc.float"),
	"100.00012",
	"get float value - status ok"
);

is($foo->set_value("abc.floatv2", 1234e-2),
	0,
	"set float e value - status ok"
);
is($foo->value("abc.floatv2"),
	1234e-2,
	"get float e value - status ok"
);

is($foo->set_value("abc.string_example", "hello, world"),
	0,
	"set float e value - status ok"
);
is($foo->value("abc.string_example"),
	"hello, world",
	"get float e value - status ok"
);

is($foo->set_value("abc.array_ref", ["1","2","3"]),
	0,
	"set array ref string value - status ok"
);
is_deeply($foo->value("abc.array_ref"),
	["1","2","3"],
	"get array ref string value - status ok"
);

is($foo->set_value("abc.array_ref", [1,2,3,4]),
	0,
	"set array ref integer value - status ok"
);
is_deeply($foo->value("abc.array_ref"),
	[1,2,3,4],
	"get array ref integer value - status ok"
);

is($foo->set_value("abc.array_ref", [1.2,3.4]),
	0,
	"set array ref float value - status ok"
);
is_deeply($foo->value("abc.array_ref"),
	["1.2","3.4"],
	"get array ref float value - status ok"
);

is($foo->set_value("abc.hash_ref", { key => "value", num => 1, float => 3.14, bignum => 17223372036854775807, arr => [1,2,3], obj => { "k" => "v"} }),
	0,
	"set hash ref value - status ok"
);
is_deeply($foo->value("abc.hash_ref"),
	{key => "value", num => 1, float => 3.14, bignum => -1223372036854775809, arr => [1,2,3], obj=>{"k"=>"v"}},
	"get hash ref value - status ok"
);

is($foo->set_value("abc.list_ref", [1.2,"hello", 4, [1,2,["group",2,["a","b","c"]]], {k1=>1, k2=>3.56, k3=>"hello"}]),
	0,
	"set list ref value - status ok"
);
is_deeply($foo->value("abc.list_ref"),
	[1.2,"hello", 4, [1,2,["group",2,["a","b","c"]]], {k1=>1, k2=>3.56, k3=>"hello"}],
	"get list ref value - status ok"
);


# scalar test
ok($foo->add("me.mar", $binarykey, "0b0"), "add bool scalar - status ok");
ok($foo->add_boolscalar("me.mar", $boolkey, 1), "add bool scalar - status ok");
ok($foo->add_scalar("me.mar", $floatkey, 5.5), "add float scalar - status ok");
ok($foo->add_scalar("me.mar", $longkey, 21111111113333), "add long scalar - status ok");
ok($foo->add_scalar("me.mar", $key, "hello, world"), "add string scalar - status ok");
ok($foo->modify_scalar("me.mar.float", "float string"), "modify scalar - status ok");
# array test
$key = "node2";
ok($foo->add_array("me.arr", $key,  \@arr_str), "add array into array - status ok");
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
