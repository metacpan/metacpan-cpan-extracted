use strict;
use warnings FATAL => 'all';

use Test::More tests => 22;

use File::Slurp;
use Apache::SWIT::Test::ModuleTester;
use Apache::SWIT::Test::Utils;
use Apache::SWIT::Maker::Manifest;
use Apache::SWIT::Maker::Conversions;
use Data::Dumper;
use Carp;
use Test::TempDatabase;

Test::TempDatabase->become_postgres_user;

my $mt = Apache::SWIT::Test::ModuleTester->new({ 
		root_class => 'Apache::SWIT::Security' 
});
$mt->run_make_install;
is(-f $mt->install_dir . "/T/Apache/SWIT/Security/Role/Container.pm", undef);
is(-f $mt->install_dir . "/T/Apache/SWIT/Security/Role/Manager.pm", undef);

my $if = read_file($mt->install_dir
		. '/Apache/SWIT/Security/InstallationContent.pm');
unlike($if, qr/020_secparams/) or ASTU_Wait;

my $rdir = $mt->root_dir;
chdir $mt->root_dir;

$mt->make_swit_project(root_class => 'MU');
$mt->install_subsystem('TheSub');

is(-f 'conf/security.yaml', undef);
unlike(read_file('MANIFEST'), qr/security.yaml/);

$mt->install_subsystem_schema;
$mt->install_session_base;

swmani_write_file('lib/MU/Us.pm', conv_module_contents("MU::Us", <<ENDS));
use base 'Apache::SWIT::Security::DB::User';
use File::Slurp;

append_file('$rdir/us.txt', "used\\n");

sub role_ids {
	append_file('$rdir/us.txt', "role_ids\\n");
	return shift()->SUPER::role_ids(\@_);
}
ENDS

swmani_write_file('lib/MU/Lo.pm', conv_module_contents("MU::Lo", <<ENDS));
use base 'Apache::SWIT::Security::UI::Login';
use File::Slurp;

append_file('$rdir/us.txt', "mu_login\\n");

package MU::Lo::Root;
use base 'HTML::Tested';
ENDS

append_file('lib/MU/Session.pm', <<ENDS);
use File::Slurp;
sub authorize {
	append_file('$rdir/us.txt', "authorize\\n");
	return shift()->SUPER::authorize(\@_);
}
ENDS

my $tree = YAML::LoadFile('conf/swit.yaml');
$tree->{env_vars}->{AS_SECURITY_USER_CLASS} = 'MU::Us';
$tree->{pages}->{"thesub/login"}->{class} = 'MU::Lo';
$tree->{capabilities} = { a_cap => [ '+admin' ], b_cap => [ '-all' ] };

my $ts = $tree->{startup_classes};
is_deeply($ts, [ 'Apache::SWIT::Security::Session' ]) or ASTU_Wait(Dumper($ts));
YAML::DumpFile('conf/swit.yaml', $tree);

append_file('templates/index.tt', <<'ENDS');
[% IF request.pnotes('SWITSession').is_capable('a_cap') %]
a_cap is ok
[% END %]
[% IF request.pnotes('SWITSession').is_capable('b_cap') %]
b_cap is ok
[% END %]
ENDS

my $res = join('', `perl Makefile.PL && make 2>&1`);
unlike($res, qr/Stop/);
isnt(-f 'blib/lib/MU/TheSub/Role/Container.pm', undef) or ASTU_Wait($res);
unlike(read_file('MANIFEST'), qr/Container/);

my $inde =  <<'ENDS';
use warnings FATAL => 'all';
use strict;
use Test::More tests => 21;
use Apache::SWIT::Security::Test qw(Find_Open_URLs Is_URL_Secure);
use Apache::SWIT::Test::Utils;
use Data::Dumper;
use File::Slurp;

BEGIN { use_ok("T::Test"); }

T::Test->new->reset_db;
my $t = T::Test->new;
my $ef = ASTU_Read_Error_Log() if $t->mech;
my @urls = Find_Open_URLs($t, haha => 'hihi');
is_deeply(\@urls, [ qw(/mu/index/r /mu/index/u
	/mu/thesub/login/r /mu/thesub/login/u
	/mu/thesub/result/r) ]) or diag(Dumper(\@urls));
is($t->session->request->param('haha'), 'hihi');
$t->with_or_without_mech_do(2, sub {
	is(ASTU_Read_Error_Log(), $ef);
	my $al = ASTU_Read_Access_Log();
	like($al, qr/haha=hihi/);
});

ok(Is_URL_Secure($t, '/mu/thesub/userform/r'));
ok(Is_URL_Secure($t, 'thesub/userform/r'));

# check that root location is set anyhow
$t->session->request->uri(undef);
ok(Is_URL_Secure($t, 'thesub/userform/r', HT_SEALED_moo => 'qqqq'
			, foo => 'ffff'));
is(HTML::Tested::Seal->instance->decrypt($t->session->request->param('moo'))
	, 'qqqq');
is($t->session->request->param('foo'), 'ffff');
ok(!Is_URL_Secure($t, 'thesub/login/u'));
is($t->session->request->param('foo'), undef);

$t->with_or_without_mech_do(4, sub {
	is(ASTU_Read_Error_Log(), $ef);
	my $al = ASTU_Read_Access_Log();
	like($al, qr/ffff/);
	like($al, qr/moo=/);
	unlike($al, qr/qqqq/);
});

$t->ok_ht_thesub_login_r(make_url => 1);
$t->ht_thesub_login_u(ht => { username => 'admin', password => 'password' });
$t->ok_ht_index_r(make_url => 1);
$t->with_or_without_mech_do(2, sub {
	like($t->mech->content, qr/a_cap is ok/);
	unlike($t->mech->content, qr/b_cap is ok/);
});
my @u2 = Find_Open_URLs($t);
cmp_ok(@u2, '>', @urls);
ENDS

my $ou = 't/dual/thesub/500_open_urls.t';
write_file($ou, $inde);

$res = join('', `make test 2>&1`);
is($?, 0);
unlike($res, qr/Error/) or ASTU_Wait;
like($res, qr/success/);

my $ust = read_file("$rdir/us.txt");
like($ust, qr/used/);
like($ust, qr/role_ids/);
like($ust, qr/mu_login/);
like($ust, qr/authorize/);

$tree->{pages}->{'index'}->{entry_points}->{r}->{permissions} = [ "+all" ];
push @{ $tree->{rule_permissions} }, [ ".*index/u", "+all" ];
YAML::DumpFile('conf/swit.yaml', $tree);

write_file($ou, $inde);

$res = join('', `make test_dual APACHE_TEST_FILES=$ou 2>&1`);
is($?, 0) or ASTU_Wait($res);

chdir('blib/lib') or ASTU_Wait;
ok(require('../../t/T/TempDB.pm'));
isnt(require('MU/TheSub/Role/Container.pm'), undef) or ASTU_Wait($mt->root_dir);
isnt(require('MU/TheSub/Role/Manager.pm'), undef) or ASTU_Wait($mt->root_dir);
is(MU::TheSub::Role::Container->create->find_role_by_id(1)->name, 'admin');

# allow access for login for all
is(MU::TheSub::Role::Manager->create->access_control('/mu/thesub/login/r')
	, undef);

chdir '/';

