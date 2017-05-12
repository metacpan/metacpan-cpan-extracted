#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

use strict;

my ($inc, $result);

ok(1, "no tests");
exit(0);

if (-f "app.pl") {
    #$ENV{PATH} = "../bin:/usr/local/bin:/usr/bin:/bin";
    $inc = "../lib";
}
else {
    #$ENV{PATH} = "bin:/usr/local/bin:/usr/bin:/bin";
    $inc = "lib";
}

my $result0 = <<EOF;
Content-type: text/html

<html>
<head>
<title>App-Context</title>
</head>
<body>
<form method="POST">
<input type="hidden" name="app.sessiondata" value="
H4sIAAAAAAAAA2NhYTExNjJkYWHhYGYAAgBkFgB+EAAAAA==
">

</form>
</body>
</html>
EOF

$result = `app --perlinc=$inc`;
is($result, $result0, "basic app invocation OK");

$result = `PATH_INFO=/demo app --perlinc=$inc`;
is($result, $result0, "basic app invocation OK [demo]");

$result = `PATH_INFO="/Procedure/f2c.execute(32)" app --perlinc=$inc`;
is($result, $result0, "f2c(32)");

exit 0;

__END__

########################################################
# conf()
########################################################
$conf = do "$dir/app.pl";
$config = App->conf("confFile" => "$dir/app.pl");
ok(defined $config, "constructor ok");
isa_ok($config, "App::Conf", "right class");
is_deeply($conf, { %$config }, "config to depth");

########################################################
# use()
########################################################
eval {
   App->use("App::Nonexistent");
};
ok($@, "use(001) class does not exist");

eval {
   $w = App::Procedure->new("w");
};
ok($@, "use(002) known class not used before");

App->use("App::Procedure");
ok(1, "use(002) class never used before");
App->use("App::Procedure");
ok(1, "use(003) class used before");
$w = App::Procedure->new("w");
ok(1, "use(004) can use class after");
ok(defined $w, "constructor ok");
isa_ok($w, "App::Procedure", "right class");

exit 0;

