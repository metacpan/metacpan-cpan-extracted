#!perl -w

use DBI qw(:sql_types);
use Mac::DtfSQL qw(:all);
use strict;


my $curdir = `pwd`;
chomp $curdir;
$curdir =~ s/:$//; # get rid of the trailing colon, if any
my $db_name = $curdir . ':SampleDB.dtf';

die "The sample database 'SampleDB.dtf' doesn't exist in the current directory" unless (-e $db_name);

print "Sample: [Database: $db_name]\n";
print "        UPDATE some prices in the articles table. \n";
print "        Demonstrates handling of fields that hold decimal values (here defined as DECIMAL(6,2)).\n";
print "        After we have SELECT'ed some records, the prices will be converted to decimal objects,\n";
print "        incremented by 10% and then UPDATE'd. Finally, we test the commit and rollback \n";
print "        methods while updating another article.\n\n";

my $dsn = "dbi:DtfSQLmac:$db_name"; # DBI data source name (DSN)

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

$dbh->{AutoCommit} = 1; # set auto-commit to true

if($dbh->{AutoCommit}) {
	print "AutoCommit: auto-commit is ON.\n";
} else {
	print "AutoCommit: auto-commit is OFF.\n";
}

my $statement = qq{	
					SELECT a.id, a.name, a.price 
					FROM articles a 
					WHERE (a.name LIKE '%Sir%') OR (a.name LIKE '%Chef%')
				  };
				  
print "Executing ...\n $statement\n";

my $sth = $dbh->prepare($statement);
$sth->execute();

my $num_fields = $sth->{NUM_OF_FIELDS}; # this should be 3

my ($articleid, $article, $price, $new_price);
# bind Perl variable to columns
$sth->bind_columns(\$articleid, \$article, \$price);

my $price_dec = Mac::DtfSQL->new_decimal;
my $newprice_dec = Mac::DtfSQL->new_decimal;
my $dec_100 = Mac::DtfSQL->new_decimal;
my $dec_percent = Mac::DtfSQL->new_decimal;

$dec_100->from_string(100.0000); # scale 4
$dec_percent->from_string(10.0000);

my $row_ary_ref;
while ( $row_ary_ref = $sth->fetch() ) {
    if (! ($num_fields == scalar(@$row_ary_ref)) ) {
        print "Row size returned by fetch doesn't match NUM_OF_FIELDS\n";
        last;
	}
	print "					", $articleid, ", ", $article, ", ", $price, ", ";
	$price_dec->from_string($price); 	# scale is 2
	$price_dec->set_scale(4); 		 	# scale is now 4, this avoids rounding errors
	$newprice_dec->assign($price_dec); 	# $newprice_dec = $price_dec
	$newprice_dec->div($dec_100); 		# $newprice_dec =  $newprice_dec / 100.0000
	$newprice_dec->mul($dec_percent); 	# $newprice_dec =  $newprice_dec * 10.0000 (percent)
	$newprice_dec->add($price_dec); 	# $newprice_dec = $newprice_dec + $price_dec
	$newprice_dec->set_scale(2); 		# back to scale 2
	print "  new price: ", $newprice_dec->as_string, "\n";
	
	# now update record

	print "					UPDATE articles SET price = ", $newprice_dec->as_string, " WHERE id = ", $articleid, "\n\n";
	my $upd_sth = $dbh->prepare("UPDATE articles SET price = ? WHERE id = ?");
	$upd_sth->bind_param(1, $newprice_dec->as_string, SQL_INTEGER);  # placeholders are numbered from 1
	$upd_sth->bind_param(2, $articleid, SQL_INTEGER); 
	$upd_sth->execute;
		
}

$sth->finish(); # sth is already finished (after fetching all rows), but try again
my $rows = $sth->rows();
print "Rows after the statement handle has been finished: $rows\n\n";


print "\nExecuting SELECT again ...\n $statement\n";

$sth = $dbh->prepare($statement);
$sth->execute();

print "\nResult table using dump_results ...\n\n";

$sth->dump_results();
$rows = $sth->rows();
print "Row count as reported by the rows method = $rows\n\n";


print "\nDisplay some meta-data regarding this result table/statement handle ... \n\n";

print "NUM_OF_PARAMS (placeholders) = ", $sth->{NUM_OF_PARAMS}, " (should be 0)\n\n";

print "NUM_OF_FIELDS (columns) = ", $sth->{NUM_OF_FIELDS}, " (should be 3)\n\n";

print "NAME of columns (should be id, name, price):\n";
my $ary_ref = $sth->{NAME};
print join(', ', @{$ary_ref}) , "\n\n";

print "NAME_lc of columns lowercase (should be id, name, price):\n";
$ary_ref = $sth->{NAME_lc};
print join(', ', @{$ary_ref}) , "\n\n";

print "NAME_uc of columns uppercase (should be ID, NAME, PRICE):\n";
$ary_ref = $sth->{NAME_uc};
print join(', ', @{$ary_ref}) , "\n\n";

print "dtf_table -- Name of corresponding tables (should be articles, articles, articles):\n";
$ary_ref = $sth->{dtf_table};
print join(', ', @{$ary_ref}) , "\n\n";

print "TYPE -- column DBI SQL type numbers (should be 4, 12, 3):\n";
$ary_ref = $sth->{TYPE};
print join(', ', @{$ary_ref}) , "\n\n";


print "PRECISION -- column's precision (should be 10, 255, 6):\n";
$ary_ref = $sth->{PRECISION};
print join(', ', @{$ary_ref}) , "\n\n";

print "SCALE -- column's scale (should be undef, undef, 2):\n";
$ary_ref = $sth->{SCALE};
my $count = scalar(@{$ary_ref});
for (my $i=0;  $i<$count-1; $i++) {
	defined($ary_ref->[$i]) ? print "$ary_ref->[$i], " : print "undef, ";
}
print "$ary_ref->[$count-1]\n\n";

print "NULLABLE -- nullable info (should be 0,1,1 - NOT NULL, NULL, NULL):\n";
$ary_ref = $sth->{NULLABLE};
print join(', ', @{$ary_ref}) , "\n\n";


 

print "\n\n+++ Now we test the commit/rollback methods ...\n\n"; 
 
$dbh->{AutoCommit} = 0; # set auto-commit to false

if($dbh->{AutoCommit}) {
	print "AutoCommit: auto-commit is ON.\n\n";
} else {
	print "AutoCommit: auto-commit is OFF.\n\n";
}

print "SELECT a record ...\n";
print "    SELECT a.id, a.name, a.price FROM articles a WHERE id = 36\n\n";

$sth = $dbh->prepare( qq{ SELECT a.id, a.name, a.price FROM articles a WHERE id = 36} );
$sth->execute();
# bind Perl variable to columns
my $oldprice;
$sth->bind_columns(\$articleid, \$article, \$oldprice);
$sth->fetch();
$sth->finish();
print "id $articleid, name $article, (old) price $oldprice\n";


my $newprice = $oldprice + 10;

print "UPDATE this record ...\n";
print "    UPDATE articles SET price = $newprice WHERE id = 36\n";

$sth = $dbh->prepare( qq{ UPDATE articles SET price = $newprice WHERE id = 36} );
$rows = $sth->execute();
print "... rows affected $rows\n\n";

print "SELECT this updated record ...\n";
print "    SELECT * FROM articles WHERE id = 36\n\n";

$sth = $dbh->prepare( qq{ SELECT * FROM articles WHERE id = 36} );
$sth->execute();
$sth->dump_results();

print "\nROLLBACK and SELECT again ...\n";
print "    ROLLBACK\n";
print "    SELECT * FROM articles WHERE id = 36\n\n";
$dbh->rollback();
$sth = $dbh->prepare( qq{ SELECT a.id, a.name, a.price FROM articles a WHERE id = 36} );
$sth->execute();
# bind Perl variable to columns
$sth->bind_columns(\$articleid, \$article, \$price);
$sth->fetch();
$sth->finish();
print "id $articleid, name $article, price $price\n";

if ($price == $oldprice) { # decimal can be handled as number
	print "rollback ok.\n\n";
} else {
	print "rollback not ok.\n\n";
}

print "\nUPDATE again and now COMMIT ...\n";
print "    UPDATE articles SET price = 40.99 WHERE id = 36\n";
print "    COMMIT\n";
$sth = $dbh->prepare( qq{ UPDATE articles SET price = 40.99 WHERE id = 36} );
$sth->execute();
$rows = $sth->rows();
$dbh->commit();
print "... rows affected $rows\n\n";

print "SELECT this record again...\n";
print "    SELECT * FROM articles WHERE id = 36\n\n";

$sth = $dbh->prepare( qq{ SELECT a.id, a.name, a.price FROM articles a WHERE id = 36} );
$sth->execute();
# bind Perl variable to columns
$sth->bind_columns(\$articleid, \$article, \$price);
$sth->fetch();
$sth->finish();
print "id $articleid, name $article, price $price\n";

if ($price eq '40.99') { # decimal can be handled as string
	print "commit ok.\n\n";
} else {
	print "commit not ok.\n\n";
}

print "\nCheers :).\n";

#
# disconnect
#

$dbh->disconnect;

1;
