#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 10;

use Test::Warn;
use Test::Exception;

use Conf::Libconfig;

my $cfgfile = "./t/spec.cfg";
my $newcfgfile = "./t/newspec.cfg";
my $foo = Conf::Libconfig->new;
ok($foo->read_file($cfgfile), "read file - status ok");

#ok($foo->add_scalar("me.mar", "key", {"value"}), "add scalar - status ok");
#ok($foo->modify_scalar("no.nodes", "value"), "modify scalar - status ok");

warning_is { $foo->add_scalar("no.nodes", "key", "value") } 
	"[WARN] Settings is null in set_scalarvalue!", "check path is null - status ok";
warning_is { $foo->modify_scalar("no.nodes", "value") }
    "[WARN] Path is null!", "check path is null - status ok";
warning_is { $foo->add_array("no.nodes", "key", ["value1", "value2"]) }
    "[WARN] Settings is null in set_arrayvalue!", "check path is null - status ok";
warning_is { $foo->add_list("no.nodes", "key", ["value1", "value2"]) }
    "[WARN] Settings is null in set_arrayvalue!", "check path is null - status ok";
warning_is { $foo->add_hash("no.nodes", "key", {"value1", "value2"}) }
    "[WARN] Settings is null in set_hashvalue!", "check path is null - status ok";

#throws_ok { $foo->add_scalar("me.mar", "key", { "value1", "value2" }) }
	#qr/have not this type/, "check value is not right - status ok";

throws_ok { $foo->delete_node("no.nodes") }
	qr/Not the node of path/, "check path is null - status ok";
throws_ok { $foo->delete_node_key("no.nodes", "key") }
	qr/Not the node of path/, "check path is null - status ok";
throws_ok { $foo->delete_node_elem("no.nodes", 0) }
	qr/Not the node of path/, "check path is null - status ok";

ok($foo->write_file($newcfgfile), "write file - status ok");

unlink($newcfgfile);

