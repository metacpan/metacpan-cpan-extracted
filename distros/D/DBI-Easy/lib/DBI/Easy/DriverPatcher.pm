package DBI::Easy;

use strict;

BEGIN {
	unless (defined &DBD::SQLite::db::serial_column_type) {
		*DBD::SQLite::db::serial_column_type = \&_sqlite_serial_column_type;
	}

	unless (defined &DBD::mysql::db::serial_column_type) {
		*DBD::mysql::db::serial_column_type = \&_mysql_serial_column_type;
	}

	unless (defined &DBD::Pg::db::serial_column_type) {
		*DBD::Pg::db::serial_column_type = \&_pg_serial_column_type;
	}
	
}

sub _sqlite_serial_column_type {
	return 'autoincrement';
}

sub _mysql_serial_column_type {
	return 'auto_increment';
}

sub _pg_serial_column_type {
	return 'serial';
}

1;