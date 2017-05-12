#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

BEGIN {
   use_ok("App");
   use_ok("App::Conf::File");
}

my ($conf, $config, $file, $dir);
#$App::trace_subs = 1;

$dir = ".";
$dir = "t" if (! -f "app.pl");
$conf = do "$dir/app.pl";
$config = App->conf(conf => $conf);

ok(defined $config, "constructor ok");
isa_ok($config, "App::Conf", "right class");
is_deeply($conf, { %$config }, "config to depth");

foreach $file qw(app.pl app.xml app.ini app.properties) {
    $config = App::Conf::File->new( conf_file => "$dir/$file" );
    ok(defined $config, "$file: constructor ok");
    isa_ok($config, "App::Conf", "$file: right class");
    is_deeply($conf, { %$config }, "$file: conf to depth");
}

exit 0;

