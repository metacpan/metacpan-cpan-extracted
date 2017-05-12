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
	$schema->resultset('User')->search( { Name => 'Array Test' } )->delete_all;

	$schema->txn_do(
		sub {
			$user_01 = $schema->resultset('User')->create(
				{   
					Name => 'Array Test',
					Email => 'arraytest@sample.com',
					PasswordSalt => 'sheeju',
					PasswordHash => 'sheeju',
					Status => 'Active',
					UserType => ['Guest', 'Internal']
				}
			);
		},
		{   
			Description => "adding new user: Array Test with Array UserType",
			UserId => 1, 
		},
	);

	ok($user_01->name eq 'Array Test', 'Inserted Array Test');
	my $log = $schema->resultset('Log')->search({Table => 'User', TableId => $user_01->id})->first;
	ok($log->table_action eq 'INSERT', 'INSERT Confirmed');
	isa_ok( $user_01->user_type, 'ARRAY' );
	ok( eq_array($user_01->user_type, ['Guest', 'Internal']), 'UserType are Guest & Internal' );

	done_testing();
}
1;
