#! perl -w

use DBI 1.08;

@typearray = (

qw/ SQL_ALL_TYPES
	SQL_CHAR SQL_NUMERIC SQL_DECIMAL SQL_INTEGER SQL_SMALLINT
	SQL_FLOAT SQL_REAL SQL_DOUBLE SQL_VARCHAR
	SQL_DATE SQL_TIME SQL_TIMESTAMP
	SQL_LONGVARCHAR SQL_BINARY SQL_VARBINARY SQL_LONGVARBINARY
	SQL_BIGINT SQL_TINYINT
/ );

foreach $type (@typearray) {
	$call = 'DBI::' . $type;
	if (! defined( &$call ) ) {
		print "$type not defined in DBI $DBI::VERSION\n";
	} else { 
		print $type, " = ", &$call ,"\n";
	}
}
