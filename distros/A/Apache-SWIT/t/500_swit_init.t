use strict;
use warnings FATAL => 'all';

use Test::More tests => 67;
use File::Temp qw(tempdir);
use Data::Dumper;
use File::Path qw(rmtree);
use Test::TempDatabase;
use Apache::SWIT::Test::ModuleTester;
use Apache::SWIT::Test::Utils;
use File::Slurp;

BEGIN { use_ok('Apache::SWIT::Maker'); }

delete $ENV{TEST_FILES};
delete $ENV{MAKEFLAGS};
delete $ENV{MAKEOVERRIDES};

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
chdir $mt->root_dir;
$mt->make_swit_project;
ok(-f 'LICENSE');

my $swit_str = read_file('conf/swit.yaml');
like($swit_str, qr/TTT/);
like($swit_str, qr/\/ttt/);
like($swit_str, qr/TTT::Session/);
ok(-f "conf/httpd.conf.in");
ok(-f "lib/TTT/Session.pm");

`./scripts/swit_app.pl add_test t/dual/newdir/987_test.t`;
ok(-f 't/dual/newdir/987_test.t');

$mt->replace_in_file('t/dual/001_load.t', '=> 11', '=> 12');
append_file('t/dual/001_load.t', <<'ENDM');
use Apache::SWIT::Test::Utils;
$t->with_or_without_mech_do(1, sub {
	unlike(ASTU_Read_Error_Log(), qr/\[debug\]/);
});
ENDM

sub check_db_is_clean {
	my @files = glob("/tmp/db_is_clean.ttt_test_db*.$<");
	my $res;
	if ($<) {
		$res = ok(scalar(@files));
		unlink($_) for @files;
	} else {
		$res = ok(!scalar(@files));
	}
	$res or ASTU_Wait;
}

check_db_is_clean();

my @tmp_contents = glob('/tmp/*');
`perl Makefile.PL`;
my $tres = join('', `make test 2>&1`);
like($tres, qr/All tests successful/) or ASTU_Wait;
like($tres, qr/t\/dual\/001_load/);
like($tres, qr/started\n.*dual/) or ASTU_Wait($mt->root_dir);
like($tres, qr/Files=2/);
unlike($tres, qr/Error/) or ASTU_Wait;
unlike($tres, qr/Please use/);
like($tres, qr/987_test/);
ok(-d 't/logs');
ok(-f 'blib/conf/httpd.conf');
check_db_is_clean();
is_deeply([ glob("/tmp/*") ], \@tmp_contents);

sub check_psql {
	$> ? is_deeply([ `psql -l | grep ttt_test_db` ], []) : ok 1;
}
check_psql() or ASTU_Wait($tres);

#diag($td);
#readline(\*STDIN);
like(read_file('t/logs/access_log'), qr/ttt\/index.*200/);

# Check that we run configuration only once
$tres = join('', `make 2>&1`);
is($?, 0) or ASTU_Wait($tres);
unlike($tres, qr/configuration/);

# But now config should be regenerated
system("sleep 1 && touch t/conf/extra.conf.in") and die;
$tres = join('', `make 2>&1`);
like($tres, qr/configuration/) or ASTU_Wait(read_file('Makefile'));

# make test_ doesn't run apache
$tres = join('', `make test_ 2>&1`);
unlike($tres, qr/started/);

# make test_direct doesn't run neither apache nor other tests
$tres = join('', `make test_direct 2>&1`);
unlike($tres, qr/started/);
unlike($tres, qr/t\/001_load/);
like($tres, qr/dual/);

`./scripts/swit_app.pl add_page First::Page`;
like(read_file('conf/swit.yaml'), qr/TTT::UI::First::Page/);

ok(-f "templates/first/page.tt");
ok(-f "lib/TTT/UI/First/Page.pm");

open(my $fh, ">>conf/httpd.conf.in");
print $fh "# Custom\n";
close $fh;

my $ht_conf = read_file('conf/httpd.conf.in');
unlike($ht_conf, qr/TTT::Session/);
unlike($ht_conf, qr/SessionClass/);

`make 2>&1`;
$ht_conf = read_file('blib/conf/httpd.conf');
like($ht_conf, qr/Location \/ttt\/first\/page/);
like($ht_conf, qr/Custom/);
like($ht_conf, qr/TTT::Session/);

my $mani = read_file('MANIFEST');
like($mani, qr/TTT\/UI\/First\/Page\.pm/);
like($mani, qr/templates\/first\/page\.tt/);
like($mani, qr/conf\/httpd\.conf\.in/);
like($mani, qr/direct_test/);

$tres = join('', `make dist 2>&1`);
like($tres, qr/apache_test/);
like($tres, qr/dual/);
like($tres, qr/extra/);

`make realclean`;
ok(! -f 't/T/Test.pm');
ok(! -d 't/htdocs');
ok(! -d 't/logs');
ok(! -f 'blib/conf/httpd.conf');
is(-f 't/conf/schema.sql', undef);
is_deeply([ glob('t/conf/*') ], [ 't/conf/extra.conf.in' ]);

undef $Apache::SWIT::Maker::Config::_instance;
Apache::SWIT::Maker->remove_page('First::Page');
unlike(read_file('conf/swit.yaml'), qr/TTT::UI::First::Page/);
$mani = read_file('MANIFEST');
unlike($mani, qr/TTT\/UI\/First\/Page\.pm/);
unlike($mani, qr/templates\/first\/page\.tt/);
ok(! -f "templates/first/page.tt");
ok(! -f "lib/TTT/UI/First/Page.pm");

Apache::SWIT::Maker->new->add_ht_page('First::Page');
like(read_file('conf/swit.yaml'), qr/TTT::UI::First::Page/);
unlike(read_file('lib/TTT/UI/First/Page.pm'), qr/sub ht_root_class/);
like(read_file('lib/TTT/UI/First/Page.pm'), qr/sub swit_startup/);

{
	use Package::Alias 'Apache2::Const::OK' => sub { 200; }
		, 'Apache2::Const::REDIRECT' => sub { 302; };
}

use_ok('HTML::Tested', qw(HT HTV));
push @INC, 'lib';

use_ok('TTT::UI::First::Page');
is($@, '') or ASTU_Wait($mt->root_dir);

my $at = read_file('t/apache_test.pl');
open($fh, ">t/apache_test.pl");
print $fh "use HTML::Tested::Value::Marked;\n";
print $fh "use HTML::Tested::Value::Form;\n";
print $fh "use HTML::Tested qw(HT HTV);\nuse TTT::UI::First::Page;\n$at";
close $fh;

check_psql();
`perl Makefile.PL`;
$tres = join('', `make test_apache 2>&1`);
like($tres, qr/All tests successful/) or ASTU_Wait;
unlike($tres, qr/Fail/) or ASTU_Wait;
check_psql();

$tres = join('', `make disttest 2>&1`);
unlike($tres, qr/Fail/);
check_psql();

chdir '/';
rmtree('/tmp/ttt_sessions');
