use strict;
use warnings;

use Test::More tests => 55;
use Data::Dumper;

use lib("t");

BEGIN {
	# fall back to eq_or_diff if we don't have Test::Differences
	if (!eval q{ use Test::Differences; 1 }) {
		*eq_or_diff = \&is_deeply;
	}
}

use_ok('Apache::Voodoo::Constants')                 || BAIL_OUT($@);
use_ok('Apache::Voodoo::Application::ConfigParser') || BAIL_OUT($@);

my $c = Apache::Voodoo::Constants->new('test_data::MyConfig');

my $loc = $INC{'Apache/Voodoo/Constants.pm'};
$loc =~ s/(blib\/)?lib\/Apache\/Voodoo\/Constants.pm//;

$c->{'PREFIX'}       = $loc;
$c->{'INSTALL_PATH'} = $loc."t/";
eval {
	Apache::Voodoo::Application::ConfigParser->new();
};
ok($@ =~ /ID is a required parameter/, "ID is a required param");

my $cp;
eval {
	$cp = Apache::Voodoo::Application::ConfigParser->new('app_blank');
};
ok(!$@,'ID alone works');

is(ref($cp->{'constants'}),'Apache::Voodoo::Constants','No constants object creates one');

eval {
	$cp = Apache::Voodoo::Application::ConfigParser->new('app_blank',$c);
};
ok(!$@,'ID and constants object works');

$cp->parse;
foreach (
	['id',    'app_blank'],
	['old_ns', 0]
	) {

	is($cp->{$_->[0]}, $_->[1],"default value for $_->[0] set correctly");
}
foreach (
	['id',             'app_blank'],
	['base_package',   'app_blank'],
	['session_timeout', 900 ],
	['upload_size_max', 5*1024*1024],
	['cookie_name',     'APP_BLANK_SID'],
	['https_cookies',   0,],
	['logout_target',   '/index'],
	['devel_mode',      0],
	['dynamic_loading', 0],
	['halt_on_errors',  1]
	) {

	is($cp->{config}->{$_->[0]}, $_->[1],"default value for $_->[0] set correctly");
}

eq_or_diff($cp->{config}->{template_opts}, {}, "default value for template_opts set correctly");
foreach (
	['dbs',           []],
	['models',        {}],
	['views',         {}],
	['includes',      {}],
	['controllers',   {}],
	['template_conf', {default => {}}],
	){
	eq_or_diff($cp->{$_->[0]}, $_->[1], "default value for $_->[0] set correctly");
}

$cp = Apache::Voodoo::Application::ConfigParser->new('app_oldstyle');
$cp->parse;

foreach (
	['id',    'app_oldstyle'],
	['old_ns', 1]
	) {

	is($cp->{$_->[0]}, $_->[1],"$_->[0] set correctly");
}
foreach (
	['id',             'app_oldstyle'],
	['base_package',   'app_newstyle'],
	['session_timeout', 0 ],
	['upload_size_max', 10],
	['cookie_name',     'bar_sid'],
	['https_cookies',   1,],
	['logout_target',   '/logout/target'],
	['devel_mode',      0],
	['dynamic_loading', 1],
	['halt_on_errors',  0]
	) {

	is($cp->{config}->{$_->[0]}, $_->[1],"$_->[0] set correctly");
}

eq_or_diff($cp->{config}->{template_opts}, {}, "default value for template_opts set correctly");
foreach (
	['dbs',[
		[
			'dbi:mysql:database=test;host=localhost','root','root_password',
			{HandleError => sub { "DUMMY" }, PrintError => 0, RaiseError => 0 }
		]
	]],
	['models',        {}],
	['views',         {}],
	['includes',      {skeleton    => undef}],
	['controllers',   {test_module => undef}],
	['template_conf', {default => {pre_include => 'skeleton'}}]
	){
	eq_or_diff($cp->{$_->[0]}, $_->[1], "$_->[0] set correctly");
}

$cp = Apache::Voodoo::Application::ConfigParser->new('app_newstyle');
$cp->parse;

foreach (
	['id',    'app_newstyle'],
	['old_ns', 0]
	) {

	is($cp->{$_->[0]}, $_->[1],"$_->[0] set correctly");
}
foreach (
	['devel_mode',      1],
	['dynamic_loading', 1],
	['halt_on_errors',  0],
	['test_passthrough','works']
	) {

	is($cp->{config}->{$_->[0]}, $_->[1],"$_->[0] set correctly");
}

eq_or_diff($cp->{config}->{template_opts}, {}, "default value for template_opts set correctly");
foreach (
	['dbs',[
		[
			'dbi:mysql:database=test;host=localhost','root','root_password',
			{HandleError => sub { "DUMMY" }, PrintError => 0, RaiseError => 0 }
		],
		[
			'dbi:mysql:database=test2;host=localhost','username','password',
			{HandleError => sub { "DUMMY" }, PrintError => 0, RaiseError => 0, key => 'value' }
		]
	]],
	['models',        {'a::model'      => undef}],
	['views',         {'a::view'       => undef}],
	['controllers',   {'a::controller' => undef}],
	){
	eq_or_diff($cp->{$_->[0]}, $_->[1], "$_->[0] set correctly");
}
