#!perl -T
use strict;
use warnings;
use Test::More;

use Conf::Libconfig;

my $conf = Conf::Libconfig->new;
my $ver = $conf->getversion();
if ($ver < 1.8) {
    plan skip_all => "libconfig $ver is too old for setting-adv test (need >= 1.8)";
}

my $cfgfile = "./t/test.cfg";
ok($conf->read_file($cfgfile), "read file - status ok");

my $setting = $conf->setting_lookup("application.group1");
isa_ok($setting, 'Conf::Libconfig::Settings');

# is_group / is_array / is_list / is_number / is_scalar / is_aggregate
ok($setting->is_group(), "is_group - status ok");
ok(!$setting->is_array(), "!is_array - status ok");
ok(!$setting->is_list(), "!is_list - status ok");
ok(!$setting->is_number(), "!is_number (group) - status ok");
ok(!$setting->is_scalar(), "!is_scalar (group) - status ok");
ok($setting->is_aggregate(), "is_aggregate (group) - status ok");

# name
is($setting->name(), "group1", "name - status ok");

# is_root / parent
ok(!$setting->is_root(), "!is_root - status ok");
my $parent = $setting->parent();
isa_ok($parent, 'Conf::Libconfig::Settings');
ok($parent->is_group(), "parent is_group - status ok");

# index
my $idx = $setting->index();
cmp_ok($idx, '>=', 0, "index non-negative");

# source_line / source_file
my $line = $setting->source_line();
cmp_ok($line, '>', 0, "source_line positive");
my $file = $setting->source_file();
like($file, qr/test\.cfg$/, "source_file matches");

# lookup from setting
my $child = $setting->lookup("states");
isa_ok($child, 'Conf::Libconfig::Settings');
ok($child->is_array(), "child is_array - status ok");

# lookup_int / lookup_float / lookup_bool / lookup_string from setting
is($setting->lookup_int("x"), 5, "setting lookup_int - status ok");
is($setting->lookup_int("y"), 10, "setting lookup_int y - status ok");
is($setting->lookup_bool("flag"), 1, "setting lookup_bool - status ok");

# Test is_number on an int setting
my $int_setting = $setting->lookup("x");
ok($int_setting->is_number(), "is_number (int) - status ok");
ok($int_setting->is_scalar(), "is_scalar (int) - status ok");

# Test is_array on array setting
my $arr_setting = $setting->lookup("my_array");
ok($arr_setting->is_array(), "is_array (array) - status ok");

# Test setting_lookup on a setting with a deeper path
my $window = $conf->setting_lookup("application.window");
isa_ok($window, 'Conf::Libconfig::Settings');
is($window->name(), "window", "setting_lookup deep path - status ok");

# get_elem
my $elem0 = $arr_setting->get_elem(0);
isa_ok($elem0, 'Conf::Libconfig::Settings', "get_elem returns Settings");
is($elem0->name(), undef, "array element has no name");

# setting set_hook / get_hook
$arr_setting->set_hook(42);
my $hook = $arr_setting->get_hook();
cmp_ok($hook, '==', 42, "setting set_hook/get_hook round-trip");

done_testing();