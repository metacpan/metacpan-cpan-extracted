#!perl -w

use DBI;
use strict;

my $colName_ref;
my $colTable_ref;
my $colCount;
my $i;
my $str;

my $curdir = `pwd`;
chomp $curdir;
$curdir =~ s/:$//; # get rid of the trailing colon, if any
my $db_name = $curdir . ':SampleDB.dtf';

die "The sample database 'SampleDB.dtf' doesn't exist in the current directory" unless (-e $db_name);

print "Sample: [Database: $db_name]\n";
print "        (a) Display some metadata\n";
print "        (b) Execute a simple SELECT statement and display the results in a table\n\n";


my $dsn = "dbi:DtfSQLmac:$db_name;dtf_commit_on_disconnect=1"; # DBI data source name (DSN)

#
# connect
#
print "connecting ...";
my $dbh = DBI->connect(	$dsn, 
						'dtfadm', 
						'dtfadm', 
						{RaiseError => 1, AutoCommit => 0} 
					  ) || die "Can't connect to database: " . DBI->errstr; 
print " ok.\n\n";

if ( $dbh->{AutoCommit} ) {
	print "AutoCommit is ON. \n\n";
} else {
	print "AutoCommit is OFF. \n\n";
}

print "The database contains the following usertables:\n\n";

my @usertables = $dbh->tables;
foreach my $tab (@usertables) {
	print "    ", $tab, "\n";
}
print "\n";

print "Displaying column metadata for table \"articles\" ...\n\n";

my %resulthash = $dbh->func('articles', 'table_col_info'); # $h->func(@func_arguments, $func_name);

my @meta_columns = ('col_Name',  'col_DBI_Type', 'col_Type_Str',  'col_Position', 'col_Nullable', 'col_Comment');
foreach my $colid (@meta_columns) {
	printf (" %-13.13s ", $colid);
}
print "\n";

foreach my  $colname (keys %resulthash) {
	printf (" %-13.13s ", $colname);
	foreach my $col ( @{ $resulthash{$colname} }  ) {
		printf (" %-13.13s ", $col);
	}
	print "\n";
}
print "\n\n";

my $statement = "SELECT * FROM articles WHERE id > 30";
print "Executing \"$statement\" ...\n\n";

my $sth = $dbh->prepare($statement);


if (my $rowcount = $sth->execute) {
	print "Ok, retrieved $rowcount records.\n\n";
	
	$colName_ref = $sth->{NAME};
	$colTable_ref = $sth->{dtf_table};
	$colCount = @{$colName_ref};

	for (my $i = 0; $i < $colCount - 1; $i++) {
		$str = $colTable_ref->[$i] . "." . $colName_ref->[$i];
		printf(" %-17.17s |" ,$str);
	}
	$str = $colTable_ref->[$colCount-1] . "." . $colName_ref->[$colCount-1];
	printf(" %-17.17s\n" , $str);
	for (my $i = 0; $i < $colCount - 1; $i++) {
		print("-------------------+");
	}
	print "--------------------\n";
	while (my @row_ary  = $sth->fetchrow_array) { # fetch row as array
		for ($i = 0; $i < $colCount-1; $i++) {
	  		printf " %-17.17s |", $row_ary[$i];
		}#for
		printf " %-17.17s\n", $row_ary[$colCount-1];
	}
} else {
	print "ERROR: execute failed.\n"
}

print "\nDisplay some meta-data regarding this result table/statement handle ... \n\n";

print "NUM_OF_PARAMS (placeholders) = ", $sth->{NUM_OF_PARAMS}, " (should be 0)\n\n";

print "NUM_OF_FIELDS (columns) = ", $sth->{NUM_OF_FIELDS}, " (should be 4)\n\n";

print "NAME of columns (should be id, name, package, price):\n";
my $ary_ref = $sth->{NAME};
print join(', ', @{$ary_ref}) , "\n\n";

print "NAME_lc of columns lowercase (should be id, name, package, price):\n";
$ary_ref = $sth->{NAME_lc};
print join(', ', @{$ary_ref}) , "\n\n";

print "NAME_uc of columns uppercase (should be ID, NAME, PACKAGE, PRICE):\n";
$ary_ref = $sth->{NAME_uc};
print join(', ', @{$ary_ref}) , "\n\n";

print "dtf_table -- Name of corresponding tables (should be articles, articles, articles, articles):\n";
$ary_ref = $sth->{dtf_table};
print join(', ', @{$ary_ref}) , "\n\n";

print "TYPE -- column DBI SQL type numbers (should be 4, 12, 12, 3):\n";
$ary_ref = $sth->{TYPE};
print join(', ', @{$ary_ref}) , "\n\n";


print "PRECISION -- column's precision (should be 10, 255, 255, 6):\n";
$ary_ref = $sth->{PRECISION};
print join(', ', @{$ary_ref}) , "\n\n";

print "SCALE -- column's scale (should be undef, undef, undef, 2):\n";
$ary_ref = $sth->{SCALE};
my $count = scalar(@{$ary_ref});
for (my $i=0;  $i<$count-1; $i++) {
	defined($ary_ref->[$i]) ? print "$ary_ref->[$i], " : print "undef, ";
}
print "$ary_ref->[$count-1]\n\n";

print "NULLABLE -- nullable info (should be 0, 1, 1, 1 - NOT NULL, NULL, NULL, NULL):\n";
$ary_ref = $sth->{NULLABLE};
print join(', ', @{$ary_ref}) , "\n\n";


 
#
# disconnect
#

$dbh->disconnect;

1;
