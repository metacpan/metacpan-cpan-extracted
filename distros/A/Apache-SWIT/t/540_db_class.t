use strict;
use warnings FATAL => 'all';

use Test::More tests => 12;
use Test::TempDatabase;
use File::Slurp;
Apache::SWIT::Test::ModuleTester::Drop_Root();

BEGIN { use_ok('Apache::SWIT::Test::ModuleTester'); }

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
chdir $mt->root_dir;
$mt->make_swit_project;
ok(-f 'LICENSE');
ok(-f 'lib/TTT/DB/Schema.pm');

$mt->insert_into_schema_pm('\$dbh->do("create table the_table ('
	. 'id serial primary key, a text)")');

my $res = `./scripts/swit_app.pl add_db_class the_table`;
ok(-f 'lib/TTT/DB/TheTable.pm');
is($?, 0) or diag($res);

write_file('t/234_the_table.t', <<'ENDT');
use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;
use T::TempDB;
BEGIN { use_ok('Apache::SWIT::DB::Connection');
	use_ok('TTT::DB::TheTable');
}

my $t = TTT::DB::TheTable->create({ a => 'AAA' });
is($t->id, 1);
is_deeply([ TTT::DB::TheTable->retrieve_all ], [ $t ]);
ENDT

$res = `perl Makefile.PL && make test_ TEST_FILES=t/234_the_table.t 2>&1`;
unlike($res, qr/Failed/);
like($res, qr/success/);

append_file('t/conf/schema.sql', "insert into the_table (a) values ('b')");
write_file('t/234_the_table.t', <<'ENDT');
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;
use T::TempDB;
BEGIN { use_ok('Apache::SWIT::DB::Connection');
	use_ok('TTT::DB::TheTable');
}

is(scalar(TTT::DB::TheTable->retrieve_all), 1);
ENDT

$res = `make test_ TEST_FILES=t/234_the_table.t 2>&1`;
unlike($res, qr/Failed/);
like($res, qr/success/);

isnt(-f 't/conf/schema.sql', undef);
`make realclean && perl Makefile.PL`;
is(-f 't/conf/schema.sql', undef);
my @lines = `make distcheck 2>&1 | grep MANIFEST`;
is(@lines, 2) or diag(join("", @lines)); # backups, test are 2 lines only

chdir '/'

