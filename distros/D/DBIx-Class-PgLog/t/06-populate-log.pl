#/usr/bin/env perl

# Developed by Sheeju Alex
# Licensed under terms of GNU General Public License.
# All rights reserved.
#
# Changelog:
# 2014-08-18 - created

use Try::Tiny;

use lib '../lib';
use DBIx::Class::PgLog;
use lib 'lib';
use PgLogTest::Schema;
use Data::Dumper;
use Test::More;
use DBIx::Class::QueryLog;
use DBIx::Class::QueryLog::Analyzer;

my $schema = PgLogTest::Schema->connect( "DBI:Pg:dbname=pg_log_test",
    "sheeju", "sheeju", { RaiseError => 1, PrintError => 1, 'quote_char' => '"', 'quote_field_names' => '0', 'name_sep' => '.' } ) || die("cant connect");

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

$pgl_schema->test();

$schema->resultset('User')->search( { Name => {-like => 'JohnSample%'} } )->delete;

my $user_01;

use Time::HiRes qw(time);

my $data = [
	{   
		Name => 'JohnSample1',
		Email => 'jsample1@sample.com',
		PasswordSalt => 'sheeju',
		PasswordHash => 'sheeju',
		Status => 'Active',
	},
	{   
		Name => 'JohnSample2',
		Email => 'jsample2@sample.com',
		PasswordSalt => 'sheeju',
		PasswordHash => 'sheeju',
		Status => 'Active',
	},
	{   
		Name => 'JohnSample3',
		Email => 'jsample3@sample.com',
		PasswordSalt => 'sheeju',
		PasswordHash => 'sheeju',
		Status => 'Active',
	},
	{   
		Name => 'JohnSample4',
		Email => 'jsample4@sample.com',
		PasswordSalt => 'sheeju',
		PasswordHash => 'sheeju',
		Status => 'Active',
	},
];

my $log_data;
$log_data->{Table} = 'User';
$log_data->{TableAction} = 'INSERT';
$log_data->{Epoch} = time;
$log_data->{Columns} = scalar($data)>1?[keys $data->[0]]:[];

$schema->txn_do(
	sub {
		$schema->resultset('User')->populate($data);
		my $dbh = $schema->storage->dbh;
		my $last_id_ref = $dbh->selectcol_arrayref('select last_value from "User_Id_seq"');
		print Dumper($last_id_ref);
		my $last_insert_id = $last_id_ref->[0];
		my $first_insert_id = $last_insert_id - scalar(@$data);
		my @log_data_set;
		my $start = time;
		foreach my $vals (@$data) {
			$log_data->{NewValues} = [map {$vals->{$_}} @{$log_data->{Columns}}];
			$log_data->{TableId} = $first_insert_id;
			push (@log_data_set, $log_data);
			$first_insert_id++;
		}
		my $end = time;
		print Dumper(\@log_data_set);
		print "time taken: ".($end - $start)."\n";
	},
	{   
		Description => "adding new user: Array Test with Array UserType",
		UserId => 1, 
	},
);

done_testing();
1;
