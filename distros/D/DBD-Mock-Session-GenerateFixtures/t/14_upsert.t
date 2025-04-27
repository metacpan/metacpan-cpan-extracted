use strict;
use warnings;

use Test2::V0;

use lib qw(lib t);

use MyDatabase qw(db_handle build_tests_db populate_test_db);

use DBD::Mock::Session::GenerateFixtures;

use feature 'say';


note 'running do';

subtest 'upsert generate mock data' => sub {
	my $dbh = db_handle('test.db');

	build_tests_db($dbh);
	populate_test_db($dbh);

	my $obj = DBD::Mock::Session::GenerateFixtures->new({dbh => $dbh});
	$dbh = $obj->get_dbh();

	my $sql_license = <<"SQL";
INSERT INTO LICENSES (NAME, ALLOWS_COMMERCIAL) VALUES ( ?, ? )
SQL

	chomp $sql_license;
	my $r = $dbh->do($sql_license, undef, 'test_license', 'no');
	is($r, 1, 'one row inserted is ok');

	my $update_sql = 'UPDATE LICENSES SET ALLOWS_COMMERCIAL = ? WHERE ID > ?';
	$r = $dbh->do($update_sql, undef, 'yes', '3');
	is($r, 2, 'update works ok');

	$r = $dbh->do($update_sql, undef, 'yes', '100');

	is($r, '0E0', 'now rows updated');

	my $delete_sql = 'DELETE FROM LICENSES WHERE ID = ?';
	my $sth        = $dbh->prepare($delete_sql);
	$sth->execute(3);

	is($sth->rows(), 1, 'delete with prepare and execute is ok');

	$obj->restore_all();
	$dbh->disconnect();
};

subtest 'upsert use mock data' => sub {
	my $obj_2 = DBD::Mock::Session::GenerateFixtures->new({file => 't/db_fixtures/14_upsert.t.json'});
	my $dbh_2 = $obj_2->get_dbh();

	my $sql_license = <<"SQL";
INSERT INTO LICENSES (NAME, ALLOWS_COMMERCIAL) VALUES ( ?, ? )
SQL

	chomp $sql_license;
	is($dbh_2->do($sql_license, undef, 'test_license', 'no'), 1, 'one row inserted is ok');


	my $update_sql = 'UPDATE LICENSES SET ALLOWS_COMMERCIAL = ? WHERE ID > ?';
	my $r          = $dbh_2->do($update_sql, undef, 'yes', '3');

	is($r, 2, 'update works ok');

	$r = $dbh_2->do($update_sql, undef, 'yes', '100');
	is($r, '0E0', 'now rows updated');

	my $delete_sql = 'DELETE FROM LICENSES WHERE ID = ?';
	my $sth        = $dbh_2->prepare($delete_sql);
	$sth->execute(3);

	is($sth->rows(), 1, 'delete with prepare and execute is ok');

	$dbh_2->disconnect();
};

done_testing();
