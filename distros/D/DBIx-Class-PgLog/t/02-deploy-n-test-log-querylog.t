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
use DBIx::Class::QueryLog;
use DBIx::Class::QueryLog::Analyzer;

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

	my $ql = DBIx::Class::QueryLog->new;
	$schema->storage->debugobj($ql);
	$schema->storage->debug(1);

	my $pgl_schema;

# deploy the audit log schema if it's not installed
	try {
		$pgl_schema = $schema->pg_log_schema;
		my $logsets = $pgl_schema->resultset('PgLogLogSet')->all;
		print Dumper($logsets);
	}
	catch {
		$pgl_schema->deploy;
	};

	my $user_01;

	$schema->resultset('User')->search( { Name => 'JohnSample' } )->delete_all;

	$schema->txn_do(
		sub {
			$user_01 = $schema->resultset('User')->create(
				{   
					Name => 'JohnSample',
					Email => 'jsample@sample.com',
					PasswordSalt => 'sheeju',
					PasswordHash => 'sheeju',
					Status => 'Active',
				}
			);
		},
		{   
			Description => "adding new user: JohnSample with No Role",
			UserId => 1, 
		},
	);

	ok($user_01->name eq 'JohnSample', 'Inserted JohnSample');
	my $log = $schema->resultset('Log')->search({Table => 'User', TableId => $user_01->id})->first;
	ok($log->table_action eq 'INSERT', 'INSERT Confirmed');


	$schema->txn_do(
		sub {
			$user_01->update({Email => 'sheeju@exceleron.com'});
		},
		{   
			Description => "Updating User JohnSample",
			UserId => 1, 
		},
	);

	ok($user_01->email eq 'sheeju@exceleron.com', 'Email Updated to sheeju@exceleron.com');
	$log = $schema->resultset('Log')->search({Table => 'User', TableId => $user_01->id, TableAction => 'UPDATE'})->first;
	ok($log->table_action eq 'UPDATE', 'UPDATE Confirmed');


	$schema->txn_do(
		sub {
			$user_01->delete;
		},
		{   
			Description => "Deleteing User JohnSample",
			UserId => 1, 
		},
	);

	$log = $schema->resultset('Log')->search({Table => 'User', TableId => $user_01->id, TableAction => 'DELETE'})->first;
	ok($log->table_action eq 'DELETE', 'DELETE Confirmed');

	my $user;

	$schema->txn_do(
		sub {
			$user = $schema->resultset('User')->search( { Email => 'jeremy@purepwnage.com' } )->first;
			$user->delete if($user);

			$user = $schema->resultset('User')->create(
				{   Name  => "TehPnwerer",
					Email => 'jeremy@purepwnage.com',
					PasswordSalt => 'sheeju',
					PasswordHash => 'sheeju',
					Status => 'Active',
				}
			);
		},
		{ 
			Description => "adding new user: TehPwnerer -- no admin Role", 
			UserId => 1, 
		},
	);

	ok($user->name eq 'TehPnwerer', 'Inserted TehPnwerer');
	$log = $schema->resultset('Log')->search({Table => 'User', TableId => $user->id})->first;
	ok($log->table_action eq 'INSERT', 'INSERT Confirmed');

	my $role;
	my $user_role;

	$schema->txn_do(
		sub {
			$user = $schema->resultset('User')->search( { Email => 'admin@test.com' } )->first;
			if($user) {
				$schema->resultset('UserRole')->search( { UserId => $user->id } )->delete_all;
				$user->delete;
			}
			$user = $schema->resultset('User')->create(
				{   Name  => "Admin User",
					Email => 'admin@test.com',
					PasswordSalt => 'sheeju',
					PasswordHash => 'sheeju',
					Status => 'Active',
				}
			);
			$role = $schema->resultset('Role')->search( { Name => "Admin" } )->first;
			$user_role = $schema->resultset('UserRole')->create(
				{   
					UserId => $user->id, 
					RoleId => $role->id, 
				}
			);

		},
		{ 
			Description => "Multi Action User -- With Admin Role", 
			UserId => 1, 
		},
	);

	ok($user->name eq 'Admin User', 'Inserted Admin User');
	$log = $schema->resultset('Log')->search({Table => 'User', TableId => $user->id})->first;
	ok($log->table_action eq 'INSERT', 'INSERT Confirmed');
	ok($role->name eq 'Admin', 'Role is Admin');
	ok($user_role->role_id == $role->id, 'User Role Created');

	$user = $schema->resultset('User')->search( { Email => 'nolog@test.com' } )->first;
	$user->delete if($user);
	$user = $schema->resultset('User')->create(
		{   
			Name  => "NonLogsetUser",
			Email => 'nolog@test.com',
			PasswordSalt => 'sheeju',
			PasswordHash => 'sheeju',
			Status => 'Active',
		}
	);

	ok($user->name eq 'NonLogsetUser', 'Inserted NonLogsetUser');

	my $ana = DBIx::Class::QueryLog::Analyzer->new({ querylog => $ql });
	my @queries = $ana->get_sorted_queries;
	print Dumper(\@queries);
	my $totqueries = $ana->get_totaled_queries;
	print Dumper($totqueries);
	done_testing();
}
1;
