#!perl -T
use strict;
use warnings;
use Test::More;

use Conf::Libconfig;

my $conf = Conf::Libconfig->new;
my $ver = $conf->getversion();
if ($ver < 1.8) {
    plan skip_all => "libconfig $ver is too old for safe getters test (need >= 1.8)";
} else {
    plan tests => 9;
}

my $cfgfile = "./t/test.cfg";
ok($conf->read_file($cfgfile), "read file - status ok");

my $setting = $conf->setting_lookup("application.a");
isa_ok($setting, 'Conf::Libconfig::Settings');

# get_int_safe on int should work
is($setting->get_int_safe(), 5, "get_int_safe - correct type");

# get_bool_safe on int returns 0 (type mismatch)
is($setting->get_bool_safe(), 0, "get_bool_safe - int returns 0 (not bool)");

# get_string_safe on string
my $str_setting = $conf->setting_lookup("application.test-comment");
isa_ok($str_setting, 'Conf::Libconfig::Settings');
my $str_val = $str_setting->get_string_safe();
ok(defined($str_val), "get_string_safe - defined");
like($str_val, qr/hello/, "get_string_safe - contains expected text");

# get_int_safe on string returns 0 (type mismatch)
is($str_setting->get_int_safe(), 0, "get_int_safe - string returns 0");

# get_int64_safe on int
my $int64_val = $setting->get_int64_safe();
ok(defined($int64_val), "get_int64_safe - defined for int");

done_testing();