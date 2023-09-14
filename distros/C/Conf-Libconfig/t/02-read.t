#!perl -T
use strict;
use warnings;
use bigint;
use Data::Dumper;
use Test::More tests => 26;

use Conf::Libconfig;

my $cfgfile1 = "./t/00-load.t";
my $cfgfile2 = "./t/test.cfg";
my $foo1 = Conf::Libconfig->new;
my $foo2 = Conf::Libconfig->new;
ok(!$foo1->read_file($cfgfile1), "read file - status ok");
ok($foo2->read_file($cfgfile2), "read file - status ok");

is($foo2->value("application.group1.flag"),
	1,
	"value for boolean - status ok",
);

is($foo2->value("application.group1.y"),
	10,
	"value for integer - status ok",
);

is($foo2->value("application.ff"),
	1e6,
	"value for E - status ok",
);

is($foo2->value("application.group1.z"),
	20,
	"value for integer64 - status ok",
);

is($foo2->value("application.group1.bigint"),
	-9223372036854775806,
	"value for integer64 - status ok",
);

is($foo2->value("application.c"),
	"7.01",
	"value for float - status ok",
);

is($foo2->value("application.test-comment"),
	"/* hello\n \"there\"*/",
	"value for string - status ok",
);

is_deeply($foo2->value("application.group1.my_array"),
	[10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
	"value for int array - status ok",
);

is_deeply($foo2->value("application.group1.states"),
	["CT", "CA", "TX", "NV", "FL"],
	"value for string array - status ok",
);

is_deeply($foo2->value("binary"),
	[0xAA, 0xBB, 0xCC],
	"value for binary array - status ok",
);

is_deeply($foo2->value("list"),
	[
		["abc", 123, 1],
		"1.234",
		[],
		[1, 2, 3],
		{
			a => [1,2,1]
		}
	],
	"value for list - status ok",
);

is_deeply($foo2->value("misc"),
	{
		"port"=>5000,
		"pi"=>"3.14159265",
		"enabled"=>0,
		"mask"=>-1430532899,
		"unicode"=>"STARGΛ̊TE SG-1",
		"bigint"=>9223372036854775807,
		"bighex"=>1234605616436508552,
	},
	"value for list - status ok",
);

is($foo2->lookup_string("application.test-comment"),
	"/* hello\n \"there\"*/",
	"libconfig_lookup_string - status ok",
);

is(
    $foo2->lookup_value("misc.enabled"),
    0,
    "bool test - status ok",
);

is(
    $foo2->lookup_value("application.a"),
    5,
    "int test - status ok",
);

is(
    $foo2->lookup_value("misc.bigint"),
    9223372036854775807,
    "bigint test - status ok",
);

is(
    $foo2->lookup_value("application.ff"),
    1E6,
    "float test - status ok",
);

is(
    $foo2->lookup_value("application.test-comment"),
    "/* hello\n \"there\"*/",
    "string test - status ok",
);

my $settings = $foo2->setting_lookup("application.group1.states");
isa_ok($settings, 'Conf::Libconfig::Settings');

is(
    $settings->length,
    5,
    "setting length - status ok",
);

{
    my @items;
    push @items, $settings->get_item($_) for 0 .. $settings->length - 1;
    is_deeply(
        \@items,
        [qw(CT CA TX NV FL)],
        "item test",
    );
}

is_deeply($foo2->value("conffile_option"),
	["F", "conffile"],
	"conffile_option value - status ok",
);

is_deeply($foo2->fetch_array("includes"),
	[],
	"includes value - status ok",
);

is_deeply($foo2->value("includes"),
	"",
	"includes value - status ok",
);
