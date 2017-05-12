#!/usr/bin/perl -w

require './CBAuthCDBI.pm';

# 
# The first time we run the script, create the database.
# 
unless ( -f '/tmp/htpasswd.sqlite' ) {
	require DBI;
	my $db = DBI->connect('DBI:SQLite:dbname=/tmp/htpasswd.sqlite','','')
		or die "Unable to connect to database";
	$db->do("
		create table auth_user ( 
			user_id  varchar(32), 
			password varchar(32),
			email    varchar(99),
			name     varchar(99)
		)
	") or die "Unable to create user table";
	$db->do("
		create table auth_group ( 
			group_id    varchar(32), 
			description varchar(99)
		)
	");
	$db->do("
		create table auth_group_members ( 
			group_id    varchar(32), 
			user_id     varchar(32)
		)
	");
}#END


my $app = CGI::Builder::Auth::Example::CBAuthCDBI->new();
$app->process();
