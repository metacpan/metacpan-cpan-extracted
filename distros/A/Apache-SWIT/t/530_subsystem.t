use strict;
use warnings FATAL => 'all';

use Test::More tests => 51;
use File::Temp qw(tempdir);
use Data::Dumper;
use Test::TempDatabase;
use YAML;
use File::Slurp;
use Apache::SWIT::Maker::Conversions;
use Apache::SWIT::Maker::Manifest;
use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);

use Apache::SWIT::Test::Utils;
use HTML::Tested::Value::Form;
use HTML::Tested::Value::Marked;

BEGIN { use_ok('Apache::SWIT::Subsystem::Maker');
	use_ok('Apache::SWIT::Test::ModuleTester');
	use_ok('Apache::SWIT::Test::Apache');
}

my $dn = abs_path("blib/lib");
my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
my $td = $mt->root_dir;
chdir $td;
$mt->run_modulemaker_and_chdir;
ok(-f 'LICENSE');

my $tttpm = read_file('lib/TTT.pm');
Apache::SWIT::Subsystem::Maker->new->write_initial_files();
is(-f './lib/TTT/DB/Connection.pm', undef);
is(-f './t/T/TTT/DB/Connection.pm', undef);
isnt(-f './t/001_load.t', undef);
is(-f 'lib/TTT/DB/Base.pm', undef);
is(read_file('lib/TTT.pm'), $tttpm);
like(read_file('Makefile.PL'),
	       	qr/Apache::SWIT::Subsystem::Makefile/);

swmani_write_file("lib/" . conv_class_to_file("TTT::DB::Random")
		, conv_module_contents("TTT::DB::Random", <<ENDF));
sub number { return 494; }
ENDF

$mt->replace_in_file('lib/' . $mt->module_dir . "/Session.pm", '1', <<ENDM);
sub swit_startup {
	my \$class = shift;
	\$class->add_var('username');
	\$class->add_var('t_ttt');
}

1;
ENDM

write_file("t/555_test.t", <<'ENDT');
use Test::More tests => 5;
BEGIN { use_ok('T::Test');
	use_ok('TTT::DB::Random');
}
is(TTT::DB::Random->number, 494);
is(TTT::Session->cookie_name, 'ttt');
can_ok(TTT::Session, 'get_t_ttt');
ENDT

my $tree = Apache::SWIT::Maker::Config->instance;
$tree->{pages}->{"index"}->{entry_points}->{r}->{foo} = 'boo';
$tree->save;

undef $Apache::SWIT::Maker::Config::_instance;
$tree = Apache::SWIT::Maker::Config->instance;
my $ind = $tree->{pages}->{"index"};
is($ind->{entry_points}->{r}->{foo}, 'boo');

my $res = join('', `perl Makefile.PL && make 2>&1`);
is($?, 0) or diag($res);

my $ht_conf = read_file('blib/conf/httpd.conf');
like($ht_conf, qr/TTT::UI::Index/);
unlike($ht_conf, qr/T::TTT::UI::Index/);
unlike($ht_conf, qr/T::TTT::Session/);
like($ht_conf, qr/TTT::Session/);

my $ind_str = read_file('lib/TTT/UI/Index.pm');
unlike($ind_str, qr/\.tt/);
unlike($ind_str, qr/ht_root.+Root/);

my $m_str = read_file('MANIFEST');
unlike($m_str, qr/Test\.pm/);
unlike($m_str, qr/PageClasses\.pm/);

$res = join('', `make test 2>&1`);
unlike($res, qr/Error/) or ASTU_Wait($td);
like($res, qr/success/);
like($res, qr/localhost/);
like($res, qr/950_install/);
unlike($res, qr/Please use/);

append_file('conf/startup.pl', '`touch $INC[0]/../../touched`; 1;' . "\n");
sleep 1;
system("echo ### >> conf/startup.pl");
sleep 1;
system("touch conf/startup.pl");
sleep 1;
$res = join('', `make test_apache 2>&1`);
like($res, qr/success/) or ASTU_Wait($res);

my $mf = read_file('Makefile');
like(read_file('blib/conf/startup.pl'), qr/touch/) or ASTU_Wait($mf . $res);
ok(-f 'touched');

ok(-f 't/dual/001_load.t');

append_file('t/dual/001_load.t', <<ENDS);
# \$t->ok_ht_userlist_r(make_url => 1, ht => {
# 		user_list => [ { ht_id => 1, name => 'admin' } ] });
# \$t->ok_ht_userform_r(make_url => 1, ht => {
#		                        username => '', password => '', });
# HT_SEALED_ht_id => '1', name => 'admin', _role_name => 'admin'
ENDS

my $m_str2 = read_file('MANIFEST');
is($m_str2, $m_str);

$res = `make`;
is($?, 0) or ASTU_Wait;

$res = $mt->run_make_install;
is(-d "$td/inst/share/ttt", undef) or do {
#	diag($res);
#	diag("$td");
#readline(\*STDIN);
};

isnt(-d "$td/inst/share/perl", undef) or do {
##	diag($res);
#	diag("$td");
#readline(\*STDIN);
};

ok(-f $mt->install_dir . "/TTT.pm");
my $inst_path = $mt->install_dir . "/TTT";
ok(-f "$inst_path/Maker.pm");
my $idir = abs_path($mt->install_dir);

chdir $td;
$mt->make_swit_project(root_class => 'MU');
$mt->install_subsystem('TheSub');

ok(require 'TTT/Maker.pm');

eval "use lib 'lib'";
is(-f 'lib/MU/TheSub.pm', undef);
use_ok('HTML::Tested', qw(HT HTV));

isnt(-f "t/dual/thesub/001_load.t", undef) or ASTU_Wait($td);
my $s001 = read_file("t/dual/thesub/001_load.t");
like($s001, qr/ht_id/) or ASTU_Wait($mf);
like($s001, qr/HT_SEALED_ht_id/);

undef $Apache::SWIT::Maker::Config::_instance;
$tree = Apache::SWIT::Maker::Config->instance;
$ind = $tree->{pages}->{"thesub/index"};
isnt($ind, undef) or diag(Dumper($tree));
is($ind->{entry_points}->{r}->{template}, 'templates/thesub/index.tt');
is($ind->{entry_points}->{r}->{foo}, 'boo')
	 or diag(Dumper($tree));
is($ind->{class}, 'TTT::UI::Index');
is(read_file('templates/thesub/index.tt'), 
		read_file('templates/index.tt'));

symlink("$td/TTT/blib/lib/TTT", "blib/lib/TTT");
`perl Makefile.PL && make 2>&1`;
like(read_file('t/T/Test.pm'), qr/\bthesub\/index/);
$mt->replace_in_file('t/dual/001_load.t', '=> 11', '=> 12');
symlink("$td/TTT/blib/lib/TTT", "blib/lib/TTT") or die "# Unable to symlink";
append_file('t/dual/001_load.t', <<ENDT);
\$t->ok_ht_thesub_index_r(make_url => 1, ht => { first => '' });
ENDT
$ENV{PERL5LIB} = "$idir\:$dn";
if (!$<) {
	for (my $d = $idir; $d ne '/tmp'; $d = dirname($d)) {
		system("chmod a+rx $d") and die;
	}
}
$res = join('', `echo \$PERL5LIB && make test 2>&1`);
unlike($res, qr/Error/) or ASTU_Wait($td);
like($res, qr/thesub\/001/);

chdir "$td/TTT";
$mt->insert_into_schema_pm('\$dbh->do("create table ttt_table (a text)")');
$mt->replace_in_file('lib/TTT/UI/Index.pm', "return \\\$", <<ENDM);
my \$arr = Apache::SWIT::DB::Connection->instance->db_handle
			->selectcol_arrayref("select a from ttt_table");
\$r->pnotes('SWITSession')->set_username(\$arr);
return \$
ENDM

$mt->replace_in_file('t/dual/001_load.t', '=> 11', '=> 14');
append_file('t/dual/001_load.t', <<ENDT);
can_ok(\$t->session, 'get_username');
\$t->ok_ht_index_r(make_url => 1, ht => { first => '' });
\$t->ht_index_u(ht => {});
\$t->ok_ht_index_r(ht => { first => '' });
ENDT

$mt->replace_in_file('t/950_install.t', "TheSub'\\);", <<ENDM);
TheSub');
\$mt->install_subsystem_schema;
\$mt->install_session_base;
ENDM

$res = join('', `make test 2>&1`);
unlike($res, qr/Error/) or ASTU_Wait($td);

$mt->replace_in_file('t/dual/001_load.t', '=> 14', '=> 15');
append_file('t/dual/001_load.t', <<ENDT);
can_ok(\$t->session, 'get_t_ttt');
ENDT
$res = join('', `make test_ TEST_FILES=t/950_install.t 2>&1`);
unlike($res, qr/Error/) or ASTU_Wait($td);

chdir '/';
