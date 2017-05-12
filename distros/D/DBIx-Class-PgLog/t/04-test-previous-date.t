#/usr/bin/env perl

# Developed by Sheeju Alex
# Licensed under terms of GNU General Public License.
# All rights reserved.
#
# Changelog:
# 2014-08-18 - created

use Try::Tiny;
use Data::Dumper;
use Test::More;
use DateTime;

use lib qw( lib t/lib );
use DBIx::Class::PgLog;
use PgLogTest::Schema;

#database - pg_log_test
my $database = $ENV{PG_NAME} || '';
#user - sheeju
my $user     = $ENV{PG_USER} || '';
#password - sheeju
my $password = $ENV{PG_PASS} || '';

if( !$database || !$user ) {
	plan skip_all => 'You need to set the PG_NAME, PG_USER and PG_PASS environment variables';
} else {

	my $schema = PgLogTest::Schema->connect( 
		"DBI:Pg:dbname=".$database,
		$user, $password, 
		{ RaiseError => 1, PrintError => 1, 'quote_char' => '"', 'quote_field_names' => '0', 'name_sep' => '.' } 
	) || die("cant connect");


	my $user_01;
	my $dt = DateTime->new( year => 2010, month => 12, day => 25 );
	$dt_epoch = $dt->epoch();
	$schema->resultset('User')->search( { Name => 'Date Test' } )->delete_all;

	$schema->txn_do(
		sub {
			$user_01 = $schema->resultset('User')->create(
				{   
					Name => 'Date Test',
					Email => 'datetest@sample.com',
					PasswordSalt => 'sheeju',
					PasswordHash => 'sheeju',
					Status => 'Active',
				}
			);
		},
		{   
			Description => "adding new user: Date Test",
			UserId => 1,
			Epoch => $dt_epoch	
		},
	);

	ok($user_01->name eq 'Date Test', 'Inserted Date Test');
	my $log = $schema->resultset('Log')->search({Table => 'User', TableId => $user_01->id})->first;
	ok($log->table_action eq 'INSERT', 'INSERT Confirmed');
	ok($log->epoch == $dt_epoch, 'Previous Epoch is added' );
	my $log_dt = DateTime->from_epoch( epoch => $log->epoch );
	ok($dt->dmy == $log_dt->dmy, 'Same Date: '.$dt->dmy);

	done_testing();
}
1;
