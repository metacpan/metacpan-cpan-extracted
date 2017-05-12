use strict;
use warnings FATAL => 'all';

use Test::More tests => 35;
use Test::TempDatabase;
use File::Slurp;
use Apache::SWIT::Test::Utils;
Apache::SWIT::Test::ModuleTester::Drop_Root();

BEGIN { use_ok('Apache::SWIT::Test::ModuleTester');
	use_ok('Apache::SWIT::Maker::Conversions');
}

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT' });
chdir $mt->root_dir;
$mt->make_swit_project;
ok(-f 'LICENSE');
ok(-f 'lib/TTT/DB/Schema.pm');

$mt->insert_into_schema_pm('$dbh->do("create table the_table (
	id serial primary key, col1 text, col2 integer)");
$dbh->do("create table one_col_table (id serial primary key, ocol text)");
');

my @res = `./scripts/swit_app.pl scaffold the_table 2>&1`;
is(@res, 0) or diag(join('', @res));
ok(-f 'lib/TTT/DB/TheTable.pm');
ok(-f 'lib/TTT/UI/TheTable/List.pm');
ok(-f 'lib/TTT/UI/TheTable/Form.pm');
ok(-f 'lib/TTT/UI/TheTable/Info.pm');
ok(-f 't/dual/011_the_table.t');
append_file('conf/startup.pl', "\nuse TTT::DB::TheTable;\n");

my $form_tt = read_file('templates/thetable/form.tt');
like($form_tt, qr/Col1:/);
like($form_tt, qr/Col2:/);
like($form_tt, qr/Edit TheTable/);

my $tstr = read_file('t/dual/011_the_table.t');
unlike($tstr, qr/first/);
unlike($tstr, qr/\bid/);
like($tstr, qr/col1/);

my $make = "perl Makefile.PL && make";
my $res = `$make test_direct APACHE_TEST_FILES=t/dual/011_the_table.t 2>&1`;
unlike($res, qr/Failed/); # or readline(\*STDIN);
like($res, qr/success/);
unlike($res, qr/make_tested/);
unlike($res, qr/Please use/);

$res = `make test_apache APACHE_TEST_FILES=t/dual/011_the_table.t 2>&1`;
unlike($res, qr/Failed/);
like($res, qr/success/);

# HTML::Form input readonly warning on hidden
unlike($res, qr/readonly/);

my $mf = read_file('MANIFEST');
is(conv_next_dual_test($mf), '021');

@res = `./scripts/swit_app.pl scaffold one_col_table 2>&1`;
is(@res, 0) or diag(join('', @res));
ok(-f 'lib/TTT/DB/OneColTable.pm');
isnt(-f 't/dual/021_one_col_table.t', undef) or do {
	diag($mt->root_dir);
	# readline(\*STDIN);
};

$res = `$make test_direct APACHE_TEST_FILES=t/dual/021_one_col_table.t 2>&1`;
unlike($res, qr/Failed/) or do {
	diag(read_file('t/dual/021_one_col_table.t'));
};
like($res, qr/success/);

# check that we cope in db in inconsistent state
$tstr =~ s/(\$t->ok_ht_thetable_info_r)/die;$1/;
write_file('t/dual/002_the_table_error.t', $tstr);
$res = `make test_direct 2>&1`;
isnt($?, 0) or ASTU_Wait($res);
like($res, qr/011_the_table.+ok/) or ASTU_Wait;

append_file('t/dual/011_the_table.t', <<'ENDS');
$t->reset_db;
$t->ht_thetable_form_r(make_url => 1, ht => { col1 => '', col2 => '' });
$t->ht_thetable_form_u(ht => { col1 => '99', col2 => '99' });
ENDS

$res = `make test_apache 2>&1`;
isnt($?, 0) or ASTU_Wait($res);

my $elog = read_file('t/logs/error_log');
like($res, qr/011_the_table.+ok/);
unlike($elog, qr/ERROR/);
unlike($elog, qr/SIGHUP/);

chdir '/';
