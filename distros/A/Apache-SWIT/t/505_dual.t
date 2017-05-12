use strict;
use warnings FATAL => 'all';

use Test::More tests => 28;
use File::Slurp;
use Test::TempDatabase;
use Cwd;
use YAML;
use Apache::SWIT::Test::Utils;
use HTML::Tested::Seal;
use Data::Dumper;

BEGIN { use_ok('Apache::SWIT::Test::ModuleTester'); }

my $cwd = getcwd;

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
my $td = $mt->root_dir;
chdir $td;
$mt->run_modulemaker_and_chdir;

is(system("$cwd/scripts/swit_init"), 0);
isnt(-f "conf/swit.yaml", undef);
isnt(-f "conf/seal.key", undef) or ASTU_Wait;
unlike(read_file("lib/TTT/UI/Index.pm"), qr/sub ht_root_class/);

`./scripts/swit_app.pl add_page Red`;
is($?, 0);
$mt->replace_in_file("lib/TTT/UI/Red.pm", "swit_render {", <<'ENDS');
swit_render {
	return [ INTERNAL => "../index/r?first=$ENV{APACHE_SWIT_SERVER_URL}" ];
ENDS

write_file('t/dual/030_load.t', <<'ENDS');
use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;
use File::Slurp;

BEGIN { use_ok('T::Test'); };

my $t = T::Test->new;
$t->with_or_without_mech_do(2, sub {
	ok 1;
	write_file("A", "");
	is($ENV{APACHE_SWIT_SERVER_URL}, 'http://'
		. Apache::TestRequest::hostport() . "/");
}, 2, sub {
	ok 1;
	write_file("D", "");
	is($ENV{APACHE_SWIT_SERVER_URL}, 'direct.test');
});
$t->ok_ht_index_r(make_url => 1, ht => { first => '' });
$t->content_like(qr/hrum/);
$t->red_r(make_url => 1);
$t->content_like(qr/hrum/);
$t->with_or_without_mech_do(2, sub {
	like($t->mech->uri, qr#red/r#);
	my $hp = Apache::TestRequest::hostport();
	like($t->mech->content, qr#http://$hp/#);
});
$t->aga_html_r(make_url => 1);
$t->content_like(qr/hrum/);
ENDS
append_file('MANIFEST', "\nt/dual/030_load.t\n");

like(read_file("lib/TTT/UI/Index.pm"), qr/sub swit_startup/);
$mt->replace_in_file("lib/TTT/UI/Index.pm", 'sub swit_startup {', <<ENDS);
use File::Slurp;
sub swit_startup {
	append_file("$td/swit_startup_test", sprintf("\%d \%s \%s\n"
			, \$\$, \$0, (caller)[1]));
ENDS
append_file('templates/index.tt', '[% INCLUDE templates/inc.tt %]');
write_file('templates/inc.tt', "hrum\nhrum\n");
append_file('MANIFEST', "\ntemplates/inc.tt\n");

my $res = `./scripts/swit_app.pl add_class SC`;
is($?, 0);
$mt->replace_in_file("lib/TTT/SC.pm", "1;", <<ENDS);
use File::Slurp;
sub swit_startup {
	append_file("$td/startup_classes_test", \$_[0]);
}
1;
ENDS

system("touch $td/startup_classes_test && chmod a+rw $td/startup_classes_test");
system("chmod a+rxw $td");
my $tree = YAML::LoadFile('conf/swit.yaml');
isnt($tree, undef);
$tree->{startup_classes} = [ 'TTT::SC' ];

$tree->{pages}->{"aga.html"} = { class => 'TTT::UI::Red'
			, handler => 'swit_render_handler' };
YAML::DumpFile('conf/swit.yaml', $tree);

$res = `perl Makefile.PL && APACHE_SWIT_PROFILE=1 make test_dual 2>&1`;
like($res, qr/030_load/);
like($res, qr/success/) or ASTU_Wait();

my $elog = 't/logs/error_log';
unlike($res, qr/Fail/) or ASTU_Wait(-f $elog ? read_file($elog) : "");
unlike($res, qr/010_db/);
isnt(-f "A", undef) or ASTU_Wait($res . (-f $elog ? read_file($elog) : ""));
isnt(-f "D", undef);

my $alog = read_file('t/logs/access_log');
like($alog, qr/Mechanize/) or ASTU_Wait;
unlike($alog, qr/- - /) or ASTU_Wait;

my ($ch_pid, $cookie, $in, $out) =
	($alog =~ /Mechanize.*"\s+(\d+) (\w+) (\d+) (\d+)/);
ok($ch_pid) or ASTU_Wait($alog);
unlike($ch_pid, qr/127/);

ok($cookie) or ASTU_Wait;
my $seal = HTML::Tested::Seal->instance(read_file('blib/conf/seal.key'));
ok($seal->decrypt($cookie)) or ASTU_Wait($alog);

cmp_ok($out, '>', $in) or ASTU_Wait;

my @profs = glob("t/logs/nytprof*");
is(@profs, 2) or ASTU_Wait(Dumper(\@profs) . $td);

my $sws = read_file("$td/swit_startup_test");
like($sws, qr/do_swit_startups\.pl/);
unlike($sws, qr/httpd\.conf/);

my $sct = read_file("$td/startup_classes_test");
like($sws, qr/do_swit_startups\.pl/);
unlike($sws, qr/httpd\.conf/);

append_file("t/010_db.t", "\ndie;\n");
$res = `make test_ 2>&1`;
isnt($?, 0);

chdir '/';
