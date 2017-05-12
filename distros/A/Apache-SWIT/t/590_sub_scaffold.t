use strict;
use warnings FATAL => 'all';

use Test::More tests => 24;
use Test::TempDatabase;
use File::Slurp;
use Apache::SWIT::Test::Utils;
Apache::SWIT::Test::ModuleTester::Drop_Root();

BEGIN { use_ok('Apache::SWIT::Test::ModuleTester');
	use_ok('Apache::SWIT::Subsystem::Maker');
};

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
my $td = $mt->root_dir;
chdir $td;
$mt->run_modulemaker_and_chdir;
ok(-f 'LICENSE');

Apache::SWIT::Subsystem::Maker->new->write_initial_files();
is(-f './lib/TTT/DB/Connection.pm', undef);
is(-f './t/T/TTT/DB/Connection.pm', undef);

$mt->insert_into_schema_pm('$dbh->do("create table the_table (
	id serial primary key, col1 text, col2 integer)");
$dbh->do("create table one_col_table (id serial primary key, ocol text)");
');

my $res = `./scripts/swit_app.pl add_db_class one_col_table 2>&1`;
is($?, 0) or ASTU_Wait($res);
ok(-f 'lib/TTT/DB/OneColTable.pm');
unlike(read_file('lib/TTT/DB/OneColTable.pm'), qr/swit_startup/);
unlike(read_file('conf/swit.yaml'), qr/OneColTable/);

write_file('t/234_one_col.t', <<'ENDT');
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;
use T::TempDB;
BEGIN { use_ok('TTT::DB::OneColTable'); }

my $t = TTT::DB::OneColTable->create({ ocol => 'AAA' });
is($t->id, 1);
is_deeply([ TTT::DB::OneColTable->retrieve_all ], [ $t ]);
ENDT

$res = `perl Makefile.PL && make 2>&1`;
is($?, 0) or diag($res);
is(-f 'blib/lib/TTT/PageClasses.pm', undef);

$res = `make test_ TEST_FILES=t/234_one_col.t 2>&1`;
is($?, 0) or diag($res);

$res = `./scripts/swit_app.pl scaffold the_table 2>&1`;
is($?, 0) or ASTU_Wait($res);

$res = `make realclean && perl Makefile.PL && make 2>&1`;
is($?, 0) or ASTU_Wait($res);

is(-f 'blib/lib/TTT/PageClasses.pm', undef);
unlike(read_file('t/dual/011_the_table.t'), qr/Form/);

$res = `make test_direct APACHE_TEST_FILES=t/dual/011_the_table.t 2>&1`;
is($?, 0) or ASTU_Wait($res);
unlike($res, qr/Failed/) or ASTU_Wait($td);
like($res, qr/success/) or ASTU_Wait($td);
unlike($res, qr/make_tested/);
unlike($res, qr/Please use/);

$res = `make test_apache APACHE_TEST_FILES=t/dual/011_the_table.t 2>&1`;
is($?, 0);
unlike($res, qr/Failed/) or ASTU_Wait($td);
like($res, qr/success/);

chdir '/';
