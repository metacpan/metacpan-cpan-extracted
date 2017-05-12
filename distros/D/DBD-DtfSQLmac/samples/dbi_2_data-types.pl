#!perl -w

use DBI qw(:sql_types);
use strict;

my $curdir = `pwd`;
chomp $curdir;
$curdir =~ s/:$//; # get rid of the trailing colon, if any
my $db_name = $curdir . ':SampleDB.dtf';

die "The sample database 'SampleDB.dtf' doesn't exist in the current directory" unless (-e $db_name);

print "Sample: [Database: $db_name]\n";
print "        We will display some data type information for the DtfSQLmac driver. For details, \n";
print "        see the type_info (and type_info_all) method description in the DBI documentation.\n\n";


my $dsn = "dbi:DtfSQLmac:$db_name";

#
# connect
#
print "We need a database handle to display the type info: \n\n";
print "connecting ...";
my $dbh = DBI->connect(	$dsn, 
						'dtfadm', 
						'dtfadm', 
						{RaiseError => 1, AutoCommit => 0} 
					  ) || die "Can't connect to database: " . DBI->errstr; 
print " ok.\n\n\n";					


my @dtf_supported_types = ( qw/
	SQL_TINYINT
	SQL_SMALLINT
	SQL_INTEGER  
	SQL_DOUBLE
	SQL_DECIMAL
	SQL_CHAR
	SQL_VARCHAR
	SQL_DATE
	SQL_TIME
	SQL_TIMESTAMP
/);

my %type_hash = ( 
	'SQL_TINYINT'	=> 	SQL_TINYINT,
	'SQL_SMALLINT'	=>  SQL_SMALLINT,
	'SQL_INTEGER'	=>  SQL_INTEGER,  
	'SQL_DOUBLE'	=>  SQL_DOUBLE,
	'SQL_DECIMAL'	=>  SQL_DECIMAL,
	'SQL_CHAR'		=>  SQL_CHAR,
	'SQL_VARCHAR'	=>  SQL_VARCHAR,
	'SQL_DATE'		=>  SQL_DATE,
	'SQL_TIME'		=>  SQL_TIME,
	'SQL_TIMESTAMP'	=>  SQL_TIMESTAMP,
);


my $type;

print "The DtfSQLmac driver supports the following DBI SQL type constants:\n\n";
foreach $type (@dtf_supported_types) {
	print "    $type \n"; 
}
print "\n\n";

foreach $type (@dtf_supported_types) {
	print "type_info for the $type type and its variants: \n\n"; 
	# get a list of hash references describing the DBI SQL type and its variants
	my @type_info = $dbh->type_info( $type_hash{$type} ); 
	printf("%-12.12s | %4.4s | %3.3s | %3.3s | %16.16s | %3.3s | %4.4s | %4.4s | %5.5s | %5.5s | %4.4s | %5.5s | %6.6s | %6.6s | %4.4s\n",  
	       'TYPE_NAME', 'SIZE', 'PRE', 'SUF', 'CREATE_PARAMS', 'NUL' , 'CASE' , 'SEAR', 'UNSIG', 
		   'SCALE', 'AUTO', 'L_TYP', 'MIN_SC', 'MAX_SC', 'RADI');		
	printf("-------------+------+-----+-----+------------------+-----+------+------+-------+-------+------+-------+--------+--------+------\n");
	foreach my $typehash_ref (@type_info) {
		printf("%-12.12s | %4.4s | %3.3s | %3.3s | %16.16s | %3.3s | %4.4s | %4.4s | %5.5s | %5.5s | %4.4s | %5.5s | %6.6s | %6.6s | %4.4s\n", 
				(defined( $typehash_ref->{TYPE_NAME} ) ? $typehash_ref->{TYPE_NAME} : 'n/a'),
				(defined( $typehash_ref->{COLUMN_SIZE} ) ? $typehash_ref->{COLUMN_SIZE} : 'n/a'),
				(defined( $typehash_ref->{LITERAL_PREFIX} ) ? $typehash_ref->{LITERAL_PREFIX} : 'n/a'),
				(defined( $typehash_ref->{LITERAL_SUFFIX} ) ? $typehash_ref->{LITERAL_SUFFIX} : 'n/a'),
				(defined( $typehash_ref->{CREATE_PARAMS} ) ? $typehash_ref->{CREATE_PARAMS} : 'n/a'),
				(defined( $typehash_ref->{NULLABLE} ) ? $typehash_ref->{NULLABLE} : 'n/a'),
				(defined( $typehash_ref->{CASE_SENSITIVE} ) ? $typehash_ref->{CASE_SENSITIVE} : 'n/a'),
				(defined( $typehash_ref->{SEARCHABLE} ) ? $typehash_ref->{SEARCHABLE} : 'n/a'),
				(defined( $typehash_ref->{UNSIGNED_ATTRIBUTE} ) ? $typehash_ref->{UNSIGNED_ATTRIBUTE} : 'n/a'),
				(defined( $typehash_ref->{FIXED_PREC_SCALE} ) ? $typehash_ref->{FIXED_PREC_SCALE} : 'n/a'),
				(defined( $typehash_ref->{AUTO_UNIQUE_VALUE} ) ? $typehash_ref->{AUTO_UNIQUE_VALUE} : 'n/a'),
				(defined( $typehash_ref->{LOCAL_TYPE_NAME} ) ? $typehash_ref->{LOCAL_TYPE_NAME} : 'n/a'),
				(defined( $typehash_ref->{MINIMUM_SCALE} ) ? $typehash_ref->{MINIMUM_SCALE} : 'n/a'),
				(defined( $typehash_ref->{MAXIMUM_SCALE} ) ? $typehash_ref->{MAXIMUM_SCALE} : 'n/a'),
				(defined( $typehash_ref->{NUM_PREC_RADIX} ) ? $typehash_ref->{NUM_PREC_RADIX} : 'n/a')
			  );
	}
	print "\n\n\n\n";
}


#
# disconnect
#

$dbh->disconnect;

1;