use strict;
use warnings FATAL => 'all';

use Test::More tests => 12;
use Test::TempDatabase;
use File::Slurp;
use Apache::SWIT::Test::Utils;
use Apache::SWIT::Maker::Conversions;
use Apache::SWIT::Maker::Manifest;
use YAML;

Apache::SWIT::Test::ModuleTester::Drop_Root();

BEGIN { use_ok('Apache::SWIT::Test::ModuleTester'); }

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
chdir $mt->root_dir;
$mt->make_swit_project;
ok(-f 'LICENSE');

$mt->replace_in_file('lib/' . $mt->module_dir . "/Session.pm", '1', <<'ENDM');
sub access_handler {
	my ($class, $r) = @_;
	my $res = $class->SUPER::access_handler($r);
	return ($r->pnotes('SWITSession')->get_deny && $r->uri !~ qr/index/)
			? Apache2::Const::FORBIDDEN() : $res;
}

__PACKAGE__->add_var($ENV{KOOKOO_VAR});

1;
ENDM

$mt->replace_in_file('lib/TTT/UI/Index.pm', "return \\\"", <<'ENDM');
Apache2::Request->new($r->pnotes('SWITSession')->request)->param('sss');
$r->pnotes('SWITSession')->set_deny(1);
return "
ENDM

append_file('lib/TTT/UI/Index.pm', <<'ENDS');
__PACKAGE__->ht_make_root_class->ht_add_widget(::HTV."::DropDown", "dd"
		, default_value => []);
TTT::UI::Index::Root->ht_add_widget(::HTV."::PasswordBox", "pb");
TTT::UI::Index::Root->ht_add_widget(::HTV."::CheckBox", $ENV{KOOKOO_VAR}
		, default_value => [ 1 ]);
ENDS

$mt->replace_in_file('t/dual/001_load.t', '=> 11', '=> 17');
append_file('t/dual/001_load.t', <<'ENDM');
is($ENV{KOOKOO_VAR}, 'deny');
$t->ok_ht_index_r(make_url => 1, ht => { first => '' });
is($t->session->request->uri, '/ttt/index/r');
$t->ht_index_u(ht => {});

use Apache::SWIT::Test::Utils;
$ENV{ASTU_WAIT} = 0;
ASTU_Wait("hoo");

$t->ok_get('www/main.css', 403);
$t->with_or_without_mech_do(1, sub {
	ok(glob('t/logs/kids_are_clean.*'));
});

# check fake Apache2::Request: new simply passes stuff through
# useful for Session funcs: they may need to create new one.
is(Apache2::Request->new(26), 26);
ENDM

my $tree = YAML::LoadFile('conf/swit.yaml');
push @{ $tree->{generators} }, 'TTT::Gen';
$tree->{env_vars}->{KOOKOO_VAR} = "deny";
YAML::DumpFile('conf/swit.yaml', $tree);

swmani_write_file("lib/" . conv_class_to_file("TTT::Gen")
		, conv_module_contents("TTT::Gen", <<'ENDM'));
use base 'Apache::SWIT::Maker::GeneratorBase';
use File::Slurp;

sub httpd_conf_start {
        my ($self, $res) = @_;
	append_file('blib/conf/do_swit_startups.pl', "# dss comment\n");
	return "$res\n# httpd comment\n";
}
ENDM

my $res = `perl Makefile.PL && make test_dual 2>&1`;
is($?, 0) or ASTU_Wait($res);
like($res, qr/success/) or ASTU_Wait();
like(read_file('blib/conf/httpd.conf'), qr/httpd comment/);
like(read_file('blib/conf/do_swit_startups.pl'), qr/dss comment/);
is_deeply([ glob('t/logs/kids_are_clean.*') ], []);

# check that we have Dumper output in direct testing
append_file('t/dual/001_load.t', <<'ENDM');
$t->ok_ht_index_r(make_url => 1, ht => { first => 'momo' });
ENDM

$res = `make test_direct 2>&1`;
isnt($?, 0) or ASTU_Wait($res);
like($res, qr/VAR1.*first/ms);
like($res, qr/Failed at.*001_load.t line 47.*001_load.t line 47/ms);

$res = `make test_apache 2>&1`;
isnt($?, 0) or ASTU_Wait($res);
unlike($res, qr/VAR1 = /ms);

chdir '/';
