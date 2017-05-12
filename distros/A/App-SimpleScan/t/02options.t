use Test::More tests=>8;

BEGIN {
  use_ok(qw(App::SimpleScan));
}

my $app = new App::SimpleScan;
ok $app->{Options}, "Options properly parsed";

my $foo;
$app->install_options(foo=>\$foo);
can_ok $app, qw(foo);
isa_ok $app->{Options}, "HASH", "hash there now";
ok $app->{Options}->{'foo'}, "foo's there";
is $app->{Options}->{'foo'}, \$foo, "proper thing there";

@ARGV = qw(--foo);
$app->parse_command_line();
is ${$app->foo}, 1, "set value";
is $foo, 1, "got into our variable";
