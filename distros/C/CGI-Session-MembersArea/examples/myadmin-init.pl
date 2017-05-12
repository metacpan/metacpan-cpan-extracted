#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Digest::MD5;

# -----------------------------------------------

sub create_sessions_table
{
	my($dbh)		= @_;
	my($table_name)	= 'sessions';
	my($sql)		=<<SQL;
create table $table_name (
id char(32) not null unique,
a_session text not null
);
SQL
	$dbh -> do("drop table if exists $table_name");
	$dbh -> do($sql);

	print "Created table: $table_name. \n";

}	# End of create_sessions_table.

# -----------------------------------------------

sub create_user_table
{
	my($dbh)		= @_;
	my($table_name)	= 'user';
	my($sql)		=<<SQL;
create table $table_name (
user_id int not null auto_increment primary key,
user_full_name varchar(255) not null,
user_full_name_key varchar(255) not null,
user_password varchar(255) not null,
user_resource_name varchar(255),
user_resource_username varchar(255),
user_resource_password varchar(255)
);
SQL

	$dbh -> do("drop table if exists $table_name");
	$dbh -> do($sql);

	print "Created table: $table_name. \n";

}	# End of create_user_table.

# -----------------------------------------------

sub populate_user_table
{
	my($dbh)				= @_;
	my($sth)				= $dbh -> prepare('insert into user (user_full_name, user_full_name_key, user_password, user_resource_name, user_resource_username, user_resource_password) values (?, ?, ?, ?, ?, ?)');
	my($input_file_name)	= 'myadmin-init.txt';

	open(INX, $input_file_name) || throw Error::Simple("Can't open $input_file_name): $!");
	my(@line) = <INX>;
	close INX;
	chomp(@line);

	my(@data, $md5);

	for (@line)
	{
		next if (/^\s*$/ || /^\s*#/);

		# Columns, separated by tabs
		# 0 Myadmin Username
		# 1 Myadmin Password
		# 2 Database name
		# 3 Database username
		# 4 Database password

		@data	= split(/\t/, $_);
		$md5	= Digest::MD5 -> new();

		$md5 -> add($data[1]);

		$sth -> execute($data[0], lc $data[0], $md5 -> hexdigest(), $data[2], $data[3], $data[4]);
	}

	$sth -> finish();

	print "Populated table: user_name. \n";

}	# End of populate_user_table.

# -----------------------------------------------

my($db)		= 'myadmin';
my($dbh)	= DBI -> connect
(
	"dbi:mysql:$db", 'root', 'pass',
	{
		AutoCommit			=> 1,
		PrintError			=> 0,
		RaiseError			=> 1,
		ShowErrorStatement	=> 1,
	}
);

print "Connected to database: $db. \n";

create_sessions_table($dbh);
create_user_table($dbh);
populate_user_table($dbh);
