#!perl -w

use DBI;
use strict;

my $curdir = `pwd`;
chomp $curdir;
$curdir =~ s/:$//; # get rid of the trailing colon, if any
my $db_name = $curdir . ':SampleDB.dtf';

die "The sample database 'SampleDB.dtf' doesn't exist in the current directory" unless (-e $db_name);

print "Sample: [Database: $db_name]\n";
print "        Demonstration of a {prepare, execute, fetch} - cycle with column binding of Perl variables.\n";
print "        As a result, we will print a order form for each client who hasn't payed the bill yet. \n\n";

my $dsn = "dbi:DtfSQLmac:$db_name";

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

my $statement = qq{ SELECT 	o.orderid, o.clientid, o.orderdate, c.firstname, c.lastname, c.street, c.city  
					FROM 	torder o, clients c 
					WHERE 	(paid = 0)
					AND		(c.id = o.clientid)};
my $sth_1 = $dbh->prepare($statement);
my $rowcount = $sth_1->execute;
print "Ok, $rowcount record(s) affected. \n\n";

my ($orderid, $clientid, $orderdate, $firstname, $lastname, $street, $city);
# bind Perl variable to columns
$sth_1->bind_columns(\$orderid, \$clientid, \$orderdate, \$firstname, \$lastname, \$street, \$city); 

while( $sth_1->fetch() ) {
	print 	"\n+++\n\n";
	print 	"$firstname $lastname\n" ,
			"$street\n",
			"$city\n",
			"\n",
			"ORDER <$orderid> on $orderdate:\n\n"; 
	printf("%6.6s   %-25.25s   %-25.25s   %6.6s   %8.8s\n" , "AMOUNT", "ARTICLE", "PACKAGE", "PRICE", "TOTAL");

	my $statement2 = qq{ SELECT a.name, a.package, oa.amount, a.price, (oa.amount * a.price) AS total
						 FROM  	ordered_articles oa, articles a  
						 WHERE 	(oa.orderid = $orderid)
						 AND 	(oa.articleid = a.id) 
					};
	my $sth_2 = $dbh->prepare($statement2);
	$sth_2->execute;
	my ($name, $package, $amount, $price, $total);
	# bind Perl variable to columns
	$sth_2->bind_columns(\$name, \$package, \$amount, \$price, \$total);  
	my $sum = 0;
	while( $sth_2->fetch() ) {
		printf("%6.6s   %-25.25s   %-25.25s   %6.2f   %8.2f\n" , $amount, $name, $package, $price, $total );
		$sum += $total;
	}#while 
	printf("%82.82s\n" , "========");
	printf("%82.2f\n" , $sum);
}#while

#
# disconnect
#

$dbh->disconnect;

1;

