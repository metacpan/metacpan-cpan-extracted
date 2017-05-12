use strict;
use warnings FATAL => 'all';

use Test::More tests => 44;
use Test::TempDatabase;
use File::Slurp;
use Apache::SWIT::Test::ModuleTester;
use Apache::SWIT::Test::Utils;
use Digest::MD5;
use ExtUtils::Manifest qw(maniread);

Apache::SWIT::Test::ModuleTester::Drop_Root();

sub dist_md5 {
	my $ctx = Digest::MD5->new;
	my $mf = maniread();
	eval { $ctx->add(read_file($_)) } for sort keys %$mf;
	return $ctx->hexdigest;
}

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
chdir $mt->root_dir;
$mt->make_swit_project;
ok(-f 'LICENSE');
ok(-f 'lib/TTT/DB/Schema.pm');

my $md5 = dist_md5();
my $res = `./scripts/swit_app.pl add_ht_page TTT::SomePage`;
is($?, 0) or ASTU_Wait();
unlike($res, qr/mkdir/);
ok(-f 'lib/TTT/SomePage.pm');
ok(-f 'backups/add_ht_page_TTT__SomePage.patch');

$res = `make dist`;
is($?, 0);
like($res, qr/SomePage/);
ok(-f "TTT-0.01.tar.gz") or ASTU_Wait($mt->root_dir);

$res = `patch -p0 -R < backups/add_ht_page_TTT__SomePage.patch`;
like($res, qr/SomePage/);
ok(! -f 'lib/TTT/SomePage.pm');
is(dist_md5(), $md5);

ok(-f 'lib/TTT/UI/Index.pm');
$res = `./scripts/swit_app.pl mv lib/TTT/UI/Index.pm lib/TTT/UI/First.pm 2>&1`;
is($?, 0) or diag($res);
ok(! -f 'lib/TTT/UI/Index.pm');
ok(-f 'lib/TTT/UI/First.pm');

my $pfile = 'backups/mv_lib_TTT_UI_Index_pm_lib_TTT_UI_First_pm.patch';
ok(-f $pfile);

$res = `patch -p0 -R < $pfile`;
like($res, qr/Index/);
ok(-f 'lib/TTT/UI/Index.pm');
ok(! -f 'lib/TTT/UI/First.pm');
is(dist_md5(), $md5);

$mt->insert_into_schema_pm('$dbh->do("create table the_table (
	id serial primary key, col1 text, col2 integer)");');

$res = `./scripts/swit_app.pl scaffold the_table 2>&1`;
is($?, 0);
ok(-f 'lib/TTT/DB/TheTable.pm');
ok(-f 'lib/TTT/UI/TheTable/List.pm');

$md5 = dist_md5();
my $swmv = "./scripts/swit_app.pl mv"; 
$res = `$swmv lib/TTT/UI/TheTable lib/TTT/UI/TheTable/T 2>&1`;
isnt($?, 0) or diag($res);
like($res, qr/Rolled back/);
is(dist_md5(), $md5) or diag($res);
is_deeply([ glob("../*") ], [ '../TTT' ]);

$res = `./scripts/swit_app.pl add_ht_page TheTable 2>&1`;
is($?, 0) or diag($res);
isnt(-f 'lib/TTT/UI/TheTable.pm', undef) or ASTU_Wait($mt->root_dir);
ok(-f 'templates/thetable.tt');

append_file('lib/TTT/UI/TheTable.pm', "# bind('TTT::UI::TheTable')\n");
append_file('lib/TTT/UI/TheTable.pm', "# ok_ht_thetable_r\n");
append_file('lib/TTT/UI/TheTable.pm', "# standalone: TTT::UI::TheTable\n");
append_file('lib/TTT/UI/TheTable.pm', "# TTT::UI::TheTableA\n");

$res = `$swmv lib/TTT/UI/TheTable.pm lib/TTT/UI/TheTable/D.pm 2>&1`;
is($?, 0) or diag($res);
isnt(-f 'templates/thetable/d.tt', undef);
isnt(-f 'lib/TTT/UI/TheTable/D.pm', undef);

my $dpm = read_file('lib/TTT/UI/TheTable/D.pm');
like($dpm, qr/TheTable::D;/) or exit 1;
unlike($dpm, qr/TheTable::D::Root;/) or exit 1;
like($dpm, qr/bind\('TTT::UI::TheTable::D'\)/) or exit 1;
like($dpm, qr/ok_ht_thetable_d_r/) or exit 1;
like($dpm, qr/standalone: TTT::UI::TheTable::D/) or exit 1;
like($dpm, qr/TheTableA/);

my $cfyaml = read_file('conf/swit.yaml');
like($cfyaml, qr/TheTable::D\n/) or exit 1;
unlike($cfyaml, qr#d/list#) or exit 1;

my $t011 = read_file("t/dual/011_the_table.t");
like($t011, qr/ht_thetable_list_r/) or exit 1;

$res = `make test_apache 2>&1`;
is($?, 0) or ASTU_Wait($res . read_file('t/logs/error_log'));

chdir '/';
