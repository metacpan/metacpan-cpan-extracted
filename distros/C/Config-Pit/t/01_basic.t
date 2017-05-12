use strict;
use warnings;

use Test::More tests => 17;
use File::Temp;
use Path::Class;
use YAML::Syck;

use Config::Pit;

use Data::Dumper;
sub p($) { warn Dumper shift }

my $dir = File::Temp->newdir();
$Config::Pit::directory    = dir($dir->dirname);
$Config::Pit::config_file  = $Config::Pit::directory->file("pit.yaml");
$Config::Pit::verbose      = 0;

my ($config, $p);

$config = Config::Pit::get("test");
is(ref($config), "HASH", "get returned value");
is(ref($config->{foo}), "");

$config = Config::Pit::set("test", data => {
		"foo" => "bar",
		"bar" => "baz",
});
is($config->{foo}, "bar", "set returned value");
is($config->{bar}, "baz", "set returned value");

$config = Config::Pit::get("test");
is($config->{foo}, "bar", "get returned value (after set)");
is($config->{bar}, "baz", "get returned value (after set)");

$config = pit_get("test");
is($config->{foo}, "bar", "get returned value (exported sub)");
is($config->{bar}, "baz", "get returned value (exported sub)");

$p = Config::Pit::switch("profile");
is($p, "default", "switch profile");
$config = pit_get("test");
is($config->{foo}, undef, "switch profile get value");
is($config->{bar}, undef, "switch profile get value");

$p = Config::Pit::switch();
is($p, "profile", "switch profile");
$config = pit_get("test");
is($config->{foo}, "bar", "switch profile get value");
is($config->{bar}, "baz", "switch profile get value");

# EDITOR
#
Config::Pit::set("test", data => {});
$ENV{EDITOR} = "";
Config::Pit::set("test");
is(ref($config), "HASH", "set with unset EDITOR");

my $suffix = $^O =~ /Win32/ ? '.bat' : '.pl'; 
sub temppath {
	return file(File::Temp->new()->filename . $suffix)
}

my $exe = temppath();
my $tst = temppath();

my $fh = $exe->open("w", 0700) or die "open failed.";
print $fh file("t/editor/exe$suffix")->slurp;
undef $fh;
chmod 0700, $exe;

$ENV{EDITOR}    = $exe;
$ENV{TEST_FILE} = $tst;
#system $exe, "Changes";
#p $tst->slurp;

my $data = {
	foo => "0101",
	bar => "0202",
};

Config::Pit::set("test", data => $data);
Config::Pit::set("test");

my $result = LoadFile($tst);

is($result->{foo}, $data->{foo}, "editor test");
is($result->{bar}, $data->{bar}, "editor test");



