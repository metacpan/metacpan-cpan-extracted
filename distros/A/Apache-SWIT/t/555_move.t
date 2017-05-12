use strict;
use warnings FATAL => 'all';

use Test::More tests => 46;
use Test::TempDatabase;
use File::Slurp;
use Apache::SWIT::Test::ModuleTester;
use Apache::SWIT::Maker::Conversions;
use Apache::SWIT::Test::Utils;
use ExtUtils::Manifest;

Apache::SWIT::Test::ModuleTester::Drop_Root();

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
chdir $mt->root_dir;
$mt->make_swit_project;
ok(-f 'LICENSE');
ok(-f 'lib/TTT/DB/Schema.pm');

$mt->insert_into_schema_pm('$dbh->do("create table the_table (
	id serial primary key, col1 text, col2 integer)");');

my $res = `./scripts/swit_app.pl scaffold the_table 2>&1`;
is($?, 0);
ok(-f 'lib/TTT/DB/TheTable.pm');
ok(-f 'lib/TTT/UI/TheTable/List.pm');
ok(-f 'lib/TTT/UI/TheTable/Form.pm');
ok(-f 'lib/TTT/UI/TheTable/Info.pm');
ok(-f 't/dual/011_the_table.t');

$res = `./scripts/swit_app.pl 2>&1`;
isnt($?, 0) or diag($res);
like($res, qr/\bmv\b/);
like($res, qr/\bscaffold\b.*generates/);
like($res, qr/\brun_server\b/);

my $hlp_res = `./scripts/swit_app.pl help 2>&1`;
isnt($?, 0);
is($hlp_res, $res);

$res = `./scripts/swit_app.pl mv lib/TTT/UI/TheTable lib/TTT/UI/The/Table 2>&1`;
is($?, 0) or diag($res);

# We can leave the directory for manual cleanup later
ok(-d 'lib/TTT/UI/TheTable');
ok(! -f 'lib/TTT/UI/TheTable/List.pm');
ok(-f 'lib/TTT/DB/TheTable.pm');
ok(-f 'lib/TTT/UI/The/Table/List.pm');
ok(-f 'lib/TTT/UI/The/Table/Form.pm');
ok(-f 'lib/TTT/UI/The/Table/Info.pm');
ok(-f 't/dual/011_the_table.t');

my $mf = ExtUtils::Manifest::maniread();
ok(exists $mf->{'lib/TTT/UI/The/Table/List.pm'});
ok(! exists $mf->{'lib/TTT/UI/TheTable/List.pm'});
is_deeply([ grep { m#UI/TheTable# } keys %$mf ], []);

my $ttab = read_file('t/dual/011_the_table.t');
unlike($ttab, qr/UI::TheTable/);
unlike($ttab, qr/The::Table/);
unlike($ttab, qr/_thetable_/);
like($ttab, qr/_the_table_/);

my $cfile = read_file("conf/swit.yaml");
unlike($cfile, qr#thetable/list:#);
like($cfile, qr#the/table/list:#);

ok(-f "templates/the/table/info.tt");
ok(! -f "templates/thetable/info.tt");

$res = `perl Makefile.PL && make test_direct 2>&1`;
is($?, 0) or ASTU_Wait($res);
like($res, qr/success/);

$res = `make test_apache 2>&1`;
is($?, 0);
like($res, qr/success/);

my $swmv = "./scripts/swit_app.pl mv";
$res = `$swmv lib/TTT/DB/TheTable.pm lib/TTT/DB/The/Table.pm 2>&1`;
is($?, 0) or diag($res);
ok(! -f 'lib/TTT/DB/TheTable.pm');
ok(-f 'lib/TTT/DB/The/Table.pm');

$res = `make test_direct 2>&1`;
is($?, 0);
like($res, qr/success/);

$res = `./scripts/swit_app.pl scaffold the_table 2>&1`;
is($?, 0);
ok(-f 'lib/TTT/DB/TheTable.pm');

$res = `make test_direct 2>&1`;
is($?, 0);
like($res, qr/success/);

chdir('/');
