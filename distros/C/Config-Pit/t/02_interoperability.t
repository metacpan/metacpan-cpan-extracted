use strict;
use warnings;

use Test::More;
use File::Temp;
use Path::Class;

if (`ruby --version` =~ /^ruby/) {
	plan tests => 3;
} else {
	plan skip_all => "ruby required";
}

use Config::Pit;

use Data::Dumper;
sub p($) { warn Dumper shift }

my $dir = File::Temp->newdir();
$Config::Pit::directory    = dir($dir->dirname);
$Config::Pit::config_file  = $Config::Pit::directory->file("pit.yaml");
$Config::Pit::verbose      = 0;

my $config;

$config = Config::Pit::set("test", data => {
		"foo" => "0100",
});
is($config->{foo}, "0100", "string like octal number (set returned value)");

$config = Config::Pit::get("test");
is($config->{foo}, "0100", "string like octal number (get returned value)");

my $profile = $Config::Pit::directory->file("default.yaml");

my $ruby_res = `ruby -ryaml -e 'print YAML.load(File.read(%($profile)))["test"]["foo"]'`;
is($ruby_res, "0100", "ruby yaml");

1;
