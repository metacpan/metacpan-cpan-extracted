#/usr/bin/env perl

# Developed by Sheeju Alex
# Licensed under terms of GNU General Public License.
# All rights reserved.
#
# Changelog:
# 2014-08-18 - created

# delete-> deletes all at once
# delete_all-> deletes one by one

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

my $user_01;

$schema->txn_do(
	sub {
		$schema->resultset('User')->search( { Name => {-like => 'JohnSample%'} } )->delete;
		my $dbh = $schema->storage->dbh;
		#my $rv = $dbh->last_insert_id(undef, 'public', 'User', undef);
		#my $rv = $dbh->do('select last_value from "User_Id_seq"');
		#print "LID: ".$rv."\n";
		my $ary_ref = $dbh->selectcol_arrayref('select last_value from "User_Id_seq"');
		print Dumper($ary_ref);
	},
	{   
		Description => "delete",
		UserId => 1, 
	},
);

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

$schema->txn_do(
	sub {
		$schema->resultset('User')->populate($data);
		#foreach (@$data) {
		#	$schema->resultset('User')->create($_);
		#}
		my $dbh = $schema->storage->dbh;
		my $ary_ref = $dbh->selectcol_arrayref('select last_value from "User_Id_seq"');
		print Dumper($ary_ref);

	},
	{   
		Description => "adding new user: Array Test with Array UserType",
		UserId => 1, 
	},
);

done_testing();
1;
