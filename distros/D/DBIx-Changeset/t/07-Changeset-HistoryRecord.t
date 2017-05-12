#!perl

use Test::More qw(no_plan);
use Test::Exception;
use Shell (sqlite3);
use File::Spec;
use Data::Dumper;
use DBIx::Changeset::Record;
use DBI;
use DBIx::Changeset::History;

BEGIN {
	use_ok( 'DBIx::Changeset::HistoryRecord' );
}

diag( "Testing DBIx::Changeset::HistoryRecord $DBIx::Changeset::HistoryRecord::VERSION, Perl $], $^X" );

&test_db_type('DBD::SQLite', 'dbi:SQLite:dbname=', 'SQLITE');
&test_db_type('DBD::mysql', 'dbi:mysql:dbname=', 'MYSQL');
&test_db_type('DBD::Pg', 'dbi:Pg:dbname=', 'PG');

sub test_db_type {
	my ($db_module, $db_dsn, $db_env) = @_;

SKIP: {
	skip 'Set $ENV{'.$db_env.'_TEST} to a true value to run all tests through '.$db_module.'. DBD_'.$db_env.'_DBNAME, DBD_'.$db_env.'_USER and DBD_'.$db_env.'_PASSWD can be used to change the defult db of test', 1 unless defined $ENV{$db_env.'_TEST'};
	
	skip "Couldn't load $db_module", unless eval "require $db_module";

	my $test_db = 'test';

	if ( $db_env eq 'SQLITE' ) {
		$test_db = File::Spec->catfile('t', 'test.db');
		if ( -e $test_db ) {
			diag('Dropping existing sqlite test db');
			unlink $test_db;
		}
	} 

	my $rec;
	my $db   = $ENV{'DBD_'.$db_env.'_DBNAME'} || $test_db;
	my $user = $ENV{'DBD_'.$db_env.'_USER'}   || '';
	my $pass = $ENV{'DBD_'.$db_env.'_PASSWD'} || '';


	my $hrec;
	lives_ok(sub{$hrec = DBIx::Changeset::History->new({history_db_dsn => $db_dsn.$db, history_db_user => $user, history_db_password => $pass});},'can create history object');
	if ( $db_env eq 'MYSQL' ) {
		### drop the changeset history table
		diag(sprintf("Dropping existing changeset_history table from db: %s \n", $db));
		eval { $hrec->dbh->do('DROP TABLE IF EXISTS `changeset_history`;'); };
	} if ( $db_env eq 'PG' ) {
		### drop the changeset history table
		diag(sprintf("Dropping existing changeset_history table from db: %s \n", $db));
		eval { $hrec->dbh->do('DROP TABLE changeset_history;'); };
	}
	lives_ok(sub { $hrec->init_history_table(); }, 'Can init the history_db');


	throws_ok(sub{$rec = DBIx::Changeset::HistoryRecord->new();},'DBIx::Changeset::Exception::ObjectCreateException','Thrown correct object create exception');

	lives_ok(sub{$rec = DBIx::Changeset::HistoryRecord->new({history_db_dsn => $db_dsn.$db, history_db_user => $user, history_db_password => $pass});},'can create record object');
	isa_ok($rec, 'DBIx::Changeset::HistoryRecord');
	can_ok($rec, qw(id filename md5 forced_b skipped_b modify_ts create_ts dbh));

	### test write
	# invalid (no args)
	throws_ok(sub { $rec->write(); }, 'DBIx::Changeset::Exception::WriteHistoryRecordException','Throws write exception');
	throws_ok(sub { $rec->write(); }, qr/No DBIx::Changeset::Record object provided/,'Correct Write exception message');
	# valid
	my $record = DBIx::Changeset::Record->new('disk', { changeset_location => './t/data', uri => '20020505_blank_valid.sql' } );
	lives_ok(sub { $rec->write($record); }, 'Can Call write');
	## check record is there in table
	my $sth = $hrec->dbh->prepare("select * from changeset_history where id = ?");
	$sth->execute($record->id);
	my $row = $sth->fetchrow_hashref;
	is($row->{'id'}, $record->id, 'Record has HistoryRecord Entry');
	
	### test read
	# invalid (no args)
	throws_ok(sub { $rec->read(); }, 'DBIx::Changeset::Exception::ReadHistoryRecordException','Throws read exception on no args');
	throws_ok(sub { $rec->read(); }, qr/uid/,'Read Exception has expected message');
	# invalid (incorrect id)
	throws_ok(sub { $rec->read('878782758'); }, 'DBIx::Changeset::Exception::ReadHistoryRecordException','Throws read exception on invalid uid');

	## valid
	lives_ok(sub { $rec->read('32323232323'); }, 'Can call read with valid args');
	is($rec->id,'32323232323','Got correct record');
	is($rec->filename,File::Spec->catfile($record->changeset_location,$record->uri),'Correct Filename');
	## check the md5
	is($rec->md5,'dae960c64dc9a7a8cd9ec3f4efc7d02e','Correct MD5');

	# Write an updated changeset
	my $record2 = DBIx::Changeset::Record->new('disk', { changeset_location => './t/data/updated', uri => '20020505_blank_valid.sql' } );
	lives_ok(sub { $rec->write($record2); }, 'Can call write on used tag with different md5');

	## valid
	lives_ok(sub { $rec->read('32323232323'); }, 'Can call read on updated changeset with valid args');
	is($rec->filename,File::Spec->catfile($record2->changeset_location,$record2->uri),'Correct updated Filename');
	is($rec->md5,'9da53844b11d1cdb4d331a62841fd5b1','Correct updated MD5');
}

}
