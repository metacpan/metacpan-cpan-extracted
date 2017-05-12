#!perl -w

use DBI qw(:sql_types) ;
use strict;

my $curdir = `pwd`;
chomp $curdir;
$curdir =~ s/:$//; # get rid of the trailing colon, if any
my $db_name = $curdir . ':SampleDB.dtf';

die "The sample database 'SampleDB.dtf' doesn't exist in the current directory" unless (-e $db_name);

print "Sample: [Database: $db_name]\n";
print "        Demonstration of a {prepare, bind_param, execute, fetch} - cycle (statements with placeholder).\n";
print "        We will insert some new records into the db (a new order, to be precise). \n\n";

my $dsn = "dbi:DtfSQLmac:$db_name";

#
# connect
#
print "connecting ...";
my $dbh = DBI->connect(
						$dsn, 
						'dtfadm', 
						'dtfadm', 
						{PrintError => 1, RaiseError => 1, AutoCommit => 0} 					
					  ) || die "Can't connect to database: " . DBI->errstr; 
print " ok.\n\n";


# First, we delete the order with orderid #5503 in table torder, which may exist from a  
# previous run of this script. Due to the faulty dtF/SQL implementation of (automatic) 
# cascaded delete, we have to delete all records with id #5503 in torder's dependent 
# table ordered_articles (its FOREIGN KEY orderid has a reference set to the PRIMARY KEY 
# orderid of table torder) by hand, before we can delete record id #5503 in parent table torder. 
 

my $rowcount;
my $orderid = 5503;
my $statement = qq{ DELETE FROM ordered_articles WHERE orderid = $orderid 
				  };
$rowcount = $dbh->do($statement) ;
if ($rowcount > 0) {
	print 	"DELETE FROM ordered_articles WHERE orderid = $orderid\n",
			"Deleted $rowcount record(s) from previous run.\n\n";
}

$statement = qq{ DELETE FROM torder WHERE orderid = $orderid 
			   };
$rowcount = $dbh->do($statement) ;
$dbh->commit;
if ($rowcount > 0) {
	print 	"DELETE FROM torder WHERE orderid = $orderid\n",
			"Deleted $rowcount record(s) from previous run.\n\n";
}

$dbh->{PrintError} = 0; # turn off additional error warnings

#
# Insert order in table torder
#

my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
my $orderdate = (1900 + $year) . "-" . ($mon + 1) .  "-" . $mday;

 
# do not quote the placeholder even if it represents a string
$statement = qq{ INSERT INTO torder VALUES ($orderid, 25, ?, 0) };
my $sth = $dbh->prepare($statement);
$sth->bind_param( 1, $orderdate, {TYPE => SQL_VARCHAR} ); # placeholder count starts with 1
print "INSERT INTO torder VALUES ($orderid, 25, '$orderdate', 0)\n";
$rowcount = $sth->execute;
$dbh->commit;
print "Ok, $rowcount record(s) affected in table torder. \n\n";

#
# Insert ordered articles in table ordered_articles
#

my $statement2 = qq{ INSERT INTO ordered_articles VALUES (?, ?, ?)  };
my @order_ary = ( [29, 3], [30, 1], [25, 5] , [36, 2]); # some fine products Made in Germany :)
my $sth_2 = $dbh->prepare($statement2);
my $rows_aff = 0;
foreach my $order (@order_ary) {	
	$sth_2->bind_param( 1, $orderid, SQL_INTEGER );
	$sth_2->bind_param( 2, $order->[0], SQL_INTEGER );	
	$sth_2->bind_param( 3, $order->[1], SQL_INTEGER );
	my $c = $sth_2->execute;
	print "INSERT INTO ordered_articles VALUES ($orderid, $order->[0], $order->[1])\n";
	$rows_aff += $c;
	$dbh->commit;
}#foreach
print "Ok, $rows_aff record(s) affected in table ordered_articles. \n\n";
		

#
# disconnect
#

$dbh->disconnect;
print "Thanks for your order :).\n";

1;