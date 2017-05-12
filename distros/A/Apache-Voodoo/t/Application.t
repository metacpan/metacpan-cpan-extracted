use strict;
use warnings;

use lib("t");

use File::Copy;

use Test::More tests => 27;
use Data::Dumper;

BEGIN {
	# fall back to eq_or_diff if we don't have Test::Differences
	if (!eval q{ use Test::Differences; 1 }) {
		*eq_or_diff = \&is_deeply;
	}
}

use_ok('Apache::Voodoo::Constants')   || BAIL_OUT($@);
use_ok('Apache::Voodoo::Application') || BAIL_OUT($@);

my $path = $INC{'Apache/Voodoo/Constants.pm'};
$path =~ s:(blib/)?lib/Apache/Voodoo/Constants.pm:t:;

my $constants = Apache::Voodoo::Constants->new('test_data::MyConfig');
$constants->{INSTALL_PATH} = $path;

my $app;
eval {
	$app = Apache::Voodoo::Application->new();
};
ok($@ =~ /ID is a required parameter/, "ID is a required param") || diag $@;

eval {
	$app = Apache::Voodoo::Application->new('app_blank');
};
ok(!$@,'ID alone works') || diag($@);

eval {
	$app = Apache::Voodoo::Application->new('app_oldstyle',$constants);
};
ok(!$@,'ID and constants object works') || diag($@);

isa_ok($app->{'controllers'}->{'test_module'},            "Apache::Voodoo::Loader::Dynamic");
isa_ok($app->{'controllers'}->{'test_module'}->{'object'},"app_newstyle::test_module");

isa_ok($app->{'controllers'}->{'skeleton'},            "Apache::Voodoo::Loader::Dynamic");
isa_ok($app->{'controllers'}->{'skeleton'}->{'object'},"app_newstyle::skeleton");


#
# make sure the .pms are the original ones.
#
$path .= "/app_newstyle";
copy("$path/C/a/controller.pm.orig","$path/C/a/controller.pm") || die "can't reset controller.pm: $!";
copy("$path/M/a/model.pm.orig",     "$path/M/a/model.pm")      || die "can't reset model.pm: $!";
copy("$path/V/a/view.pm.orig",      "$path/V/a/view.pm")       || die "can't reset view.pm: $!";

eval {
	$app = Apache::Voodoo::Application->new('app_newstyle',$constants);
};
ok(!$@,'New style config works') || diag($@);

#
# check the controllers
#
isa_ok($app->{'controllers'}->{'a/controller'},            "Apache::Voodoo::Loader::Dynamic");
isa_ok($app->{'controllers'}->{'a/controller'}->{'object'},"app_newstyle::C::a::controller");

eq_or_diff($app->{'controllers'}->{'a/controller'}->handle,{a_controller => 'a controller'},'controller output ok');

ok(!$app->{'controllers'}->{'a/controller'}->can("foo"),"original controller doesn't have a foo method");

sleep(1); # so we can be sure the mtime is different on the copied file.
copy("$path/C/a/controller.pm.new","$path/C/a/controller.pm") || die "can't reset controller.pm: $!";

eq_or_diff($app->{'controllers'}->{'a/controller'}->handle,{a_controller => 'a new controller'},'updated controller output ok');
my $ok = ok($app->{'controllers'}->{'a/controller'}->can("foo"),'updated controller has a foo method');
SKIP: {
	skip "controller didn't reload correctly",1 unless $ok;
	eq_or_diff($app->{'controllers'}->{'a/controller'}->foo,'foo','updated controller foo() output');
}

sleep(1); # so we can be sure the mtime is different on the copied file.
copy("$path/C/a/controller.pm.orig","$path/C/a/controller.pm") || die "can't reset controller.pm: $!";

eq_or_diff($app->{'controllers'}->{'a/controller'}->handle,{a_controller => 'a controller'},'original controller output ok');

#
# check the models
#
isa_ok($app->{'models'}->{'a::model'},            "Apache::Voodoo::Loader::Dynamic");
isa_ok($app->{'models'}->{'a::model'}->{'object'},"app_newstyle::M::a::model");

eq_or_diff($app->{'models'}->{'a::model'}->get_foo,"foo",'model output ok');

sleep(1); # so we can be sure the mtime is different on the copied file.
copy("$path/M/a/model.pm.new","$path/M/a/model.pm") || die "can't reset model.pm: $!";

eq_or_diff($app->{'models'}->{'a::model'}->get_foo,"FOO!",'updated model output ok');
eq_or_diff($app->{'models'}->{'a::model'}->get_bar,"bar", 'updated model get_bar() works');

sleep(1); # so we can be sure the mtime is different on the copied file.
copy("$path/M/a/model.pm.orig","$path/M/a/model.pm") || die "can't reset model.pm: $!";
eq_or_diff($app->{'models'}->{'a::model'}->get_foo,"foo",'original model output ok');

#
# check the views
#
isa_ok($app->{'views'}->{'a::view'},            "Apache::Voodoo::Loader::Dynamic");
isa_ok($app->{'views'}->{'a::view'}->{'object'},"app_newstyle::V::a::view");
isa_ok($app->{'views'}->{'a::view'}->{'object'},"Apache::Voodoo::View");

