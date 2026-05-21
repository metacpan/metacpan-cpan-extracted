#!perl -T
use strict;
use warnings;
use Test::More;

use Conf::Libconfig qw(:all);

my $conf = Conf::Libconfig->new;
my $ver = $conf->getversion();

if ($ver < 1.8) {
    plan skip_all => "libconfig $ver is too old for format test (need >= 1.8)";
} else {
    plan tests => 12;
}

# Test set_default_format / get_default_format
$conf->set_default_format(CONFIG_FORMAT_HEX);
is($conf->get_default_format(), CONFIG_FORMAT_HEX,
   "default_format - HEX");
$conf->set_default_format(CONFIG_FORMAT_BIN);
is($conf->get_default_format(), CONFIG_FORMAT_BIN,
   "default_format - BIN");
$conf->set_default_format(CONFIG_FORMAT_OCT);
is($conf->get_default_format(), CONFIG_FORMAT_OCT,
   "default_format - OCT");
$conf->set_default_format(CONFIG_FORMAT_DEFAULT);
is($conf->get_default_format(), CONFIG_FORMAT_DEFAULT,
   "default_format - DEFAULT");

# Create a config with an integer value to test setting format
is($conf->set_value("test_int", 255), 0, "set int value - status ok");

my $setting = $conf->setting_lookup("test_int");
isa_ok($setting, 'Conf::Libconfig::Settings');

# Test set_format / get_format on setting
ok($setting->set_format(CONFIG_FORMAT_HEX), "setting set_format HEX");
is($setting->get_format(), CONFIG_FORMAT_HEX, "setting get_format HEX");

ok($setting->set_format(CONFIG_FORMAT_BIN), "setting set_format BIN");
is($setting->get_format(), CONFIG_FORMAT_BIN, "setting get_format BIN");

ok($setting->set_format(CONFIG_FORMAT_DEFAULT), "setting set_format DEFAULT");
is($setting->get_format(), CONFIG_FORMAT_DEFAULT, "setting get_format DEFAULT");

done_testing();