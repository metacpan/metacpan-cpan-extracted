#!perl -T
use strict;
use warnings;
use Test::More;

use Conf::Libconfig qw(:all);

my $conf = Conf::Libconfig->new;
my $ver = $conf->getversion();

if ($ver < 1.8) {
    plan skip_all => "libconfig $ver is too old for options test (need >= 1.8)";
} else {
    plan tests => 12;
}

# Test set_options / get_options
is($conf->set_options(CONFIG_OPTION_FSYNC | CONFIG_OPTION_ALLOW_OVERRIDES),
   1, "set_options - status ok");
is($conf->get_options() & CONFIG_OPTION_FSYNC, CONFIG_OPTION_FSYNC,
   "get_options - FSYNC bit set");
is($conf->get_options() & CONFIG_OPTION_ALLOW_OVERRIDES, CONFIG_OPTION_ALLOW_OVERRIDES,
   "get_options - ALLOW_OVERRIDES bit set");

# Test set_option / get_option (single option)
is($conf->set_option(CONFIG_OPTION_SEMICOLON_SEPARATORS, 1),
   1, "set_option - enable semicolon separators");
is($conf->get_option(CONFIG_OPTION_SEMICOLON_SEPARATORS), 1,
   "get_option - semicolon separators enabled");
is($conf->set_option(CONFIG_OPTION_SEMICOLON_SEPARATORS, 0),
   1, "set_option - disable semicolon separators");
is($conf->get_option(CONFIG_OPTION_SEMICOLON_SEPARATORS), 0,
   "get_option - semicolon separators disabled");

# Test set_auto_convert / get_auto_convert
$conf->set_auto_convert(1);
is($conf->get_auto_convert(), 1,
   "get_auto_convert - enabled");
$conf->set_auto_convert(0);
is($conf->get_auto_convert(), 0,
   "get_auto_convert - disabled");

# Test set_tab_width / get_tab_width
$conf->set_tab_width(8);
is($conf->get_tab_width(), 8,
   "tab_width - set and get");

# Test set_float_precision / get_float_precision
$conf->set_float_precision(4);
is($conf->get_float_precision(), 4,
   "float_precision - set and get");

# Test clear
$conf->clear();
pass("clear - completed");

done_testing();