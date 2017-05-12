#!perl

use Test::More qw(no_plan); #tests => 1;
use Test::Exception;
use DBIx::Changeset::Record;


BEGIN {
	use_ok( 'DBIx::Changeset::History' );
}

diag( "Testing DBIx::Changeset::History $DBIx::Changeset::History::VERSION, Perl $], $^X" );

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

	throws_ok(sub{$rec = DBIx::Changeset::History->new();},'DBIx::Changeset::Exception::ObjectCreateException','Thrown correct object create exception');
	
	lives_ok(sub{$rec = DBIx::Changeset::History->new({history_db_dsn => $db_dsn.$db, history_db_user => $user, history_db_password => $pass});},'can create history object');
	isa_ok($rec, 'DBIx::Changeset::History');
	can_ok($rec, qw(records current_index init_history_table retrieve_all retrieve next add_history_record total reset));

	if ( $db_env eq 'MYSQL' ) {
		### drop the changeset history table
		diag(sprintf("Dropping existing changeset_history table from db: %s \n", $db));
		eval { $rec->dbh->do('DROP TABLE IF EXISTS `changeset_history`;'); };
	} if ( $db_env eq 'PG' ) {
		### drop the changeset history table
		diag(sprintf("Dropping existing changeset_history table from db: %s \n", $db));
		eval { $rec->dbh->do('DROP TABLE changeset_history;'); };
	}


	### right test an init of the history table
	lives_ok(sub { $rec->init_history_table(); }, 'Can init the history_db');

	### create some entries
	my $record = DBIx::Changeset::Record->new('disk', { changeset_location => './t/data', uri => '20020505_blank_valid.sql' } );
	my $record2 = DBIx::Changeset::Record->new('disk', { changeset_location => './t/data', uri => '20010505_1.sql' } );
	my $hrec;
	lives_ok(sub { $hrec = $rec->add_history_record($record); }, 'Created a 1st HistoryRecord');
	lives_ok(sub { $hrec = $rec->add_history_record($record2); }, 'Created a 2nd HistoryRecord');

	### test retrieve_all
	lives_ok(sub { $rec->retrieve_all(); }, 'Can retrieve all');
	
	### test total
	my $total = $rec->total;
	is($total,2,'Correct total');

	### test next
	my $next = $rec->next();
	isa_ok($next, 'DBIx::Changeset::HistoryRecord', 'Next returns a DBIx::Changeset::HistoryRecord');
	
	### test reset goes back to begining
	$rec->reset();
	is($rec->current_index, undef, 'reset goes back to begining');
}
}
