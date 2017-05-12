#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More;
plan skip_all => 'Test::More version is too lower!' if $Test::More::VERSION < 0.90;

use Conf::Libconfig;

my $cfgfile = "./t/test.cfg";
my $cfgfile_2 = "./t/spec.cfg";
my $difftime = 3;

my ($settings, $setting_item, $test1, $test2, $test3, $test4, $test5, $test6, $test7, $test8);
my @items;

my $time = time();

while (1) {
	my $conf = Conf::Libconfig->new;
	ok($conf->read_file($cfgfile), "read file - status ok");
	my $conf_2 = new Conf::Libconfig;
	ok($conf_2->read_file($cfgfile_2), "read file - status ok");
	$test1 = $conf->lookup_value("application.test-comment");
	$test2 = $conf->lookup_value("application.test-long-string");
	$test3 = $conf->lookup_value("application.test-escaped-string");
	$test4 = $conf->lookup_value("application.window.title");
	$settings = $conf->setting_lookup("application.group1.states");
    push @items, $settings->get_item($_) for 0 .. $settings->length - 1;
	undef @items;
	$test5 = $settings->get_type();
	$test6 = $conf->fetch_array("application.group1.my_array");
	$test7 = $conf->fetch_hashref("application.group1"),

	$test8 = $conf_2->fetch_hashref("me.mar");
	# Destructor
	eval { $conf->delete() };
	ok(($@ ? 0 : 1), "destructor - status ok");

	eval { $conf_2->delete() };
	ok(($@ ? 0 : 1), "destructor - status ok");

	last if (time() - $time > $difftime); 
}

done_testing();
