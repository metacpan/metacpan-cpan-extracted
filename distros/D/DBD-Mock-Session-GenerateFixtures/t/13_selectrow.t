use strict;
use warnings;

use Test2::V0;

use lib qw(lib t);

use MyDatabase qw(db_handle build_tests_db populate_test_db);
use DBD::Mock::Session::GenerateFixtures;

use feature 'say';


my $sql = <<"SQL";
SELECT * FROM media_types WHERE id IN(?,?) ORDER BY id DESC
SQL

my $expected          = [2, 'audio'];
my $expected_hash_ref = {
	id         => 2,
	media_type => 'audio'
};
chomp $sql;

subtest 'selectrow generate mock data' => sub {
	note 'running selectrow_array';

	my $dbh = db_handle('test.db');

	build_tests_db($dbh);
	populate_test_db($dbh);

	my $obj = DBD::Mock::Session::GenerateFixtures->new({dbh => $dbh});

	$dbh = $obj->get_dbh();

	my $sth = $dbh->prepare($sql);
	my @got = $dbh->selectrow_array($sth, undef, (2, 1));
	is(\@got, $expected, 'selectrow_array with sth is ok');

	@got = $dbh->selectrow_array($sql, undef, (2, 1));
	is(\@got, $expected, 'selectrow_array with sql is ok');

	@got = $dbh->selectrow_array($sql, undef, (12, 13));
	is(\@got, [], 'selectrow_array without sql an no rows found is ok');

	note 'running selectrow_arrayref';
	my $got = $dbh->selectrow_arrayref($sth, undef, (2, 1));

	is($got, $expected, 'selectrow_arrayref with sth is ok');

	$got = $dbh->selectrow_arrayref($sql, undef, (2, 1));
	is($got, $expected, 'selectrow_arrayref with sql prepare is ok');

	$got = $dbh->selectrow_arrayref($sql, undef, (12, 13));
	is($got, undef, 'selectrow_arrayref without sql an no rows found is ok');

	note 'running selectrow_hashref';
	$got = $dbh->selectrow_hashref($sth, undef, (2, 1));
	is($got, $expected_hash_ref, 'selectrow_hashref with sth prepare is ok');

	$got = $dbh->selectrow_hashref($sql, undef, (2, 1));
	is($got, $expected_hash_ref, 'selectrow_hashref with sql prepare is ok');

	$got = $dbh->selectrow_hashref($sql, undef, (13, 12));
	is($got, undef, 'selectrow_hashref with sql an no rows found is ok');

	$dbh->disconnect();
};

subtest 'selectrow use mock data' => sub {
	my $obj = DBD::Mock::Session::GenerateFixtures->new({file => './t/db_fixtures/13_selectrow.t.json'});
	my $dbh = $obj->get_dbh();

	my $sth = $dbh->prepare($sql);
	my @got = $dbh->selectrow_array($sth, undef, (2, 1));

	is(\@got, $expected, 'selectrow_array with sth is ok');

	@got = $dbh->selectrow_array($sql, undef, (2, 1));
	is(\@got, $expected, 'selectrow_array with sql is ok');

	@got = $dbh->selectrow_array($sql, undef, (12, 13));
	is(\@got, [], 'selectrow_array with sql no rows found is ok');

	note 'running selectrow_arrayref';

	my $got = $dbh->selectrow_arrayref($sth, undef, (2, 1));
	is($got, $expected, 'selectrow_arrayref sth prepare is ok');

	$got = $dbh->selectrow_arrayref($sql, undef, (2, 1));
	is($got, $expected, 'selectrow_arrayref with sql prepare is ok');

	$got = $dbh->selectrow_arrayref($sql, undef, (12, 13));
	is($got, undef, 'selectrow_arrayref with sql an no rows found is ok');

	note 'running selectrow_hashref';

	$got = $dbh->selectrow_hashref($sth, undef, (2, 1));
	is($got, $expected_hash_ref, 'selectrow_hashref with sth is ok');

	$got = $dbh->selectrow_hashref($sql, undef, (2, 1));
	is($got, $expected_hash_ref, 'selectrow_hashref with sql is ok');

	$got = $dbh->selectrow_hashref($sql, undef, (13, 12));
	is($got, undef, 'selectrow_hashref with sql an no rows found is ok');
};

done_testing();