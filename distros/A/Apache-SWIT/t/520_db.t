use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;
use Test::TempDatabase;
use File::Slurp;
use Apache::SWIT::Maker::Conversions;
use Apache::SWIT::Maker::Manifest;
use Apache::SWIT::Test::Utils;

BEGIN { use_ok('Apache::SWIT::Test::ModuleTester'); }

Apache::SWIT::Test::ModuleTester::Drop_Root();

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
chdir $mt->root_dir;
$mt->make_swit_project;
ok(-f 'LICENSE');
ok(-f 'lib/TTT/DB/Schema.pm');
ok(-f 't/T/TempDB.pm');

swmani_write_file("lib/" . conv_class_to_file("TTT::DB::C")
		, conv_module_contents("TTT::DB::C", <<ENDM));
use base 'Apache::SWIT::DB::Base';
__PACKAGE__->table('ttt_table');
__PACKAGE__->sequence('ttt_table_id_seq');
__PACKAGE__->columns(Essential => qw(id a));

__PACKAGE__->db_Main->do('select * from ttt_table');
ENDM

$mt->replace_in_file('t/dual/001_load.t', '=> 11', '=> 14');
$mt->replace_in_file('t/dual/001_load.t', '\};', 
	"\n\tuse_ok('Apache::SWIT::DB::Connection'); };");
$mt->insert_into_schema_pm('\$dbh->do("create table ttt_table ('
	. 'id serial primary key, a text)")');
$mt->replace_in_file('t/dual/001_load.t', "\\};\\\n", <<ENDM);
};
Apache::SWIT::DB::Connection->instance->db_handle->do(
		"insert into ttt_table (a) values ('aaa')");
ENDM

$mt->replace_in_file('t/dual/001_load.t', "''", <<ENDM);
'aaa'
ENDM

append_file('t/dual/001_load.t', <<ENDM);
isa_ok(\$t->session, 'TTT::Session');
is(\$Class::DBI::Weaken_Is_Available, 0);
ENDM

$mt->replace_in_file('t/010_db.t', '=> 1', '=> 10');
append_file('t/010_db.t', <<'ENDM');
use TTT::DB::C;
use Apache::SWIT::Maker::Conversions;

BEGIN { use_ok('T::Test'); }

my $t = T::Test->new;
$t->reset_db;

my $a = TTT::DB::C->create({ a => 'ccc' });
isnt($a, undef);
ok(TTT::DB::C->search(a => 'ccc'));
conv_silent_system("psql -d $ENV{APACHE_SWIT_DB_NAME} < t/conf/schema.sql");

my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
$dbh->{CachedKids} = {};

ok(!TTT::DB::C->search(a => 'ccc'));
my $b = TTT::DB::C->create({ a => 'ccc' });
isnt($b, undef);
is($a->id, $b->id);

chdir('/');
$t->reset_db;
ok(!TTT::DB::C->search(a => 'ccc'));
$b = TTT::DB::C->create({ a => 'ccc' });
isnt($b, undef);
is($a->id, $b->id);
ENDM

$mt->replace_in_file('lib/TTT/UI/Index.pm', "return \\\$", <<ENDM);
use Apache::SWIT::DB::Connection;
my \$arr = Apache::SWIT::DB::Connection->instance->db_handle
		->selectcol_arrayref("select a from ttt_table");
\$root->first(\$arr->[0]);
use TTT::DB::C;
TTT::DB::C->create({ a => 'bbb' });
return \$
ENDM

my $tres = join('', `perl Makefile.PL && make disttest 2>&1`);
like($tres, qr/success/);
unlike($tres, qr/Fail/); # or readline(\*STDIN);
is_deeply([ `psql -l |grep ttt_test_db` ], []) or diag($tres);

# check that reset_db does nothing when running one file 
write_file('t/dual/701_rdb.t', <<'ENDM');
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
use Apache::SWIT::Test::Utils;

BEGIN { use_ok('T::Test'); }

my $t = T::Test->new;
my $ef = -M (ASTU_Module_Dir() . '/t/logs/error_log') if $t->mech;
$t->reset_db;
$t->with_or_without_mech_do(1, sub {
	is(-M (ASTU_Module_Dir() . '/t/logs/error_log'), $ef);
});
ENDM

$tres = join('', `make test_apache APACHE_TEST_FILES=t/dual/701_rdb.t 2>&1`);
like($tres, qr/success/);

# see that we confess when no submit is given
write_file('templates/index.tt', <<'ENDM');
<html>
<body>
[% form %]
<input type="text" name="first" />
</form>
</body>
</html>
ENDM

write_file('t/dual/801_subm.t', <<'ENDM');
use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;
use Apache::SWIT::Test::Utils;

BEGIN { use_ok('T::Test'); }

my $t = T::Test->new;
$t->ok_ht_index_r(make_url => 1, ht => {});
eval { $t->ht_index_u(ht => { first => 'a' }); };
$t->with_or_without_mech_do(1, sub {
	like($@, qr/submit/);
});
eval { $t->ht_index_u(ht => { first => 'a' }, no_submit_check => 1); };
is($@, "");
ENDM

$tres = join('', `make test_dual APACHE_TEST_FILES=t/dual/801_subm.t 2>&1`);
like($tres, qr/success/);
unlike($tres, qr/Fail/) or ASTU_Wait;
unlike($tres, qr/submit_form/);

chdir '/'
