#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

BEGIN {
   use_ok("App");
}

use strict;

my ($conf, $config, $file, $dir, $w);
#$App::trace_subs = 1;

$dir = ".";
$dir = "t" if (! -f "app.pl");

########################################################
# conf()
########################################################
$conf = do "$dir/app.pl";
$config = App->conf("conf_file" => "$dir/app.pl");
ok(defined $config, "constructor ok");
isa_ok($config, "App::Conf", "right class");
is_deeply({ %$config }, $conf, "config to depth");

########################################################
# use()
########################################################
eval {
   App->use("App::Nonexistent");
};
ok($@, "use(001) class does not exist");

eval {
   $w = App::CallDispatcher->new("w");
};
ok($@, "use(002) known class not used before");

App->use("App::CallDispatcher");
ok(1, "use(002) class never used before");
App->use("App::CallDispatcher");
ok(1, "use(003) class used before");
$w = App::CallDispatcher->new("w");
ok(1, "use(004) can use class after");
ok(defined $w, "constructor ok");
isa_ok($w, "App::CallDispatcher", "right class");

exit 0;

